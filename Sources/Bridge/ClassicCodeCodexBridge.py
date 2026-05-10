#!/usr/bin/env python3
"""
ClassicCode bridge for legacy clients.

This process speaks the existing ClassicCode one-line TCP protocol to old
Apple clients and speaks Codex app-server JSON-RPC over stdio to the local
modern Codex binary.
"""

import argparse
import base64
import json
import os
import select
import socketserver
import subprocess
import sys
import threading
import time


class BridgeError(Exception):
    pass


class CodexAppServerClient:
    def __init__(self, codex_path, workspace):
        self.codex_path = codex_path
        self.workspace = workspace
        self._next_id = 1
        self._lock = threading.Lock()
        self._remote_status = {"status": "unknown", "environmentId": None}
        self._initialize_result = None
        self._stderr_lines = []
        self._process = subprocess.Popen(
            [codex_path, "app-server"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )
        self._stderr_thread = threading.Thread(target=self._read_stderr)
        self._stderr_thread.daemon = True
        self._stderr_thread.start()
        self._initialize()

    def close(self):
        process = self._process
        if process.poll() is None:
            try:
                process.terminate()
                process.wait(timeout=2)
            except Exception:
                process.kill()

    def _read_stderr(self):
        for line in self._process.stderr:
            line = line.rstrip("\n")
            if line:
                self._stderr_lines.append(line)
                del self._stderr_lines[:-20]

    def _send(self, message):
        if self._process.poll() is not None:
            raise BridgeError("codex app-server exited")
        self._process.stdin.write(json.dumps(message, separators=(",", ":")) + "\n")
        self._process.stdin.flush()

    def _read_message(self):
        line = self._process.stdout.readline()
        if line == "":
            if self._process.poll() is not None:
                detail = "; ".join(self._stderr_lines[-3:])
                raise BridgeError("codex app-server exited" + (": " + detail if detail else ""))
            raise BridgeError("codex app-server closed stdout")
        try:
            return json.loads(line)
        except ValueError as exc:
            raise BridgeError("invalid app-server JSON: %s" % exc)

    def _request_locked(self, method, params=None):
        request_id = self._next_id
        self._next_id += 1
        message = {"id": request_id, "method": method}
        if params is not None:
            message["params"] = params
        self._send(message)
        while True:
            response = self._read_message()
            if response.get("method") == "remoteControl/status/changed":
                self._remote_status = response.get("params") or self._remote_status
                continue
            if response.get("id") != request_id:
                continue
            if "error" in response:
                error = response["error"]
                raise BridgeError("%s: %s" % (method, error.get("message", error)))
            return response.get("result")

    def request(self, method, params=None):
        with self._lock:
            return self._request_locked(method, params)

    def _initialize(self):
        params = {
            "clientInfo": {
                "name": "classiccode-bridge",
                "title": "ClassicCode Bridge",
                "version": "0.1",
            },
            "capabilities": None,
        }
        with self._lock:
            self._initialize_result = self._request_locked("initialize", params)
            self._send({"method": "initialized"})
            self._drain_notifications_locked(0.05)

    def _drain_notifications_locked(self, timeout):
        while True:
            ready, _, _ = select.select([self._process.stdout], [], [], timeout)
            if not ready:
                return
            message = self._read_message()
            if message.get("method") == "remoteControl/status/changed":
                self._remote_status = message.get("params") or self._remote_status
            timeout = 0

    def info(self):
        with self._lock:
            self._drain_notifications_locked(0)
            return {
                "bridge": "ClassicCodeCodexBridge",
                "workspace": self.workspace,
                "codexPath": self.codex_path,
                "appServer": self._initialize_result,
                "remoteControl": self._remote_status,
            }


class ClassicCodeRequestHandler(socketserver.StreamRequestHandler):
    def setup(self):
        socketserver.StreamRequestHandler.setup(self)
        self.server.client_lock.acquire()

    def finish(self):
        try:
            socketserver.StreamRequestHandler.finish(self)
        finally:
            self.server.client_lock.release()

    def send_line(self, line):
        self.wfile.write((line + "\n").encode("utf-8"))
        self.wfile.flush()

    def ok(self, payload):
        self.send_line("OK " + json.dumps(payload, separators=(",", ":")))

    def thread_title(self, thread):
        name = thread.get("name")
        if name:
            return name
        preview = thread.get("preview") or ""
        return preview[:80] if preview else thread.get("id", "Conversation")

    def text_from_user_input(self, content):
        pieces = []
        for item in content or []:
            if item.get("type") == "text":
                pieces.append(item.get("text", ""))
            elif item.get("type"):
                pieces.append("[%s]" % item.get("type"))
        return "\n".join([piece for piece in pieces if piece])

    def transcript_text(self, thread):
        lines = []
        lines.append(self.thread_title(thread))
        lines.append("")
        for turn in thread.get("turns", []):
            for item in turn.get("items", []):
                item_type = item.get("type")
                if item_type == "userMessage":
                    lines.append("User")
                    lines.append(self.text_from_user_input(item.get("content")))
                    lines.append("")
                elif item_type == "agentMessage":
                    lines.append("Assistant")
                    lines.append(item.get("text", ""))
                    lines.append("")
                elif item_type == "commandExecution":
                    lines.append("Command")
                    lines.append(item.get("command", ""))
                    output = item.get("aggregatedOutput")
                    if output:
                        lines.append(output)
                    exit_code = item.get("exitCode")
                    if exit_code is not None:
                        lines.append("exit: %s" % exit_code)
                    lines.append("")
                elif item_type == "fileChange":
                    lines.append("File Change")
                    for change in item.get("changes", []):
                        lines.append(change.get("path") or change.get("filePath") or str(change))
                    lines.append("")
                elif item_type in ("reasoning", "plan"):
                    text = item.get("text") or "\n".join(item.get("summary", []))
                    if text:
                        lines.append(item_type.title())
                        lines.append(text)
                        lines.append("")
                elif item_type:
                    lines.append("[%s]" % item_type)
                    lines.append("")
        return "\n".join(lines).strip()

    def handle(self):
        self.send_line("OK ClassicCodeCodexBridge ready")
        while True:
            raw = self.rfile.readline(1024 * 1024)
            if not raw:
                return
            try:
                line = raw.decode("utf-8").strip()
            except UnicodeDecodeError:
                self.send_line("ERR request was not UTF-8")
                continue
            if not line:
                continue
            try:
                if self.dispatch(line):
                    return
            except Exception as exc:
                self.send_line("ERR " + str(exc).replace("\n", " "))

    def dispatch(self, line):
        parts = line.split(" ", 1)
        command = parts[0].upper()
        rest = parts[1] if len(parts) > 1 else ""
        client = self.server.codex_client

        if command == "QUIT":
            self.send_line("OK bye")
            return True
        if command == "HELLO":
            self.send_line("OK ClassicCodeCodexBridge")
            return False
        if command == "PING":
            self.send_line("PONG")
            return False
        if command in ("INFO", "STATUS"):
            self.ok(client.info())
            return False
        if command == "LIST_WORKSPACES":
            limit = int(rest) if rest else 100
            result = client.request("thread/list", {"limit": limit, "useStateDbOnly": False})
            seen = set()
            workspaces = []
            default_workspace = self.server.workspace
            if default_workspace:
                seen.add(default_workspace)
                workspaces.append({"path": default_workspace, "label": os.path.basename(default_workspace) or default_workspace, "current": True})
            for thread in result.get("data", []):
                cwd = thread.get("cwd")
                if not cwd or cwd in seen:
                    continue
                seen.add(cwd)
                workspaces.append({"path": cwd, "label": os.path.basename(cwd) or cwd, "current": cwd == default_workspace})
            self.ok({"workspaces": workspaces})
            return False
        if command == "LIST_SESSIONS":
            tokens = rest.split(" ", 1)
            limit = int(tokens[0]) if tokens and tokens[0] else 20
            params = {"limit": limit, "useStateDbOnly": False}
            if len(tokens) > 1 and tokens[1]:
                params["cwd"] = tokens[1]
            self.ok(client.request("thread/list", params))
            return False
        if command == "GET_TRANSCRIPT":
            if not rest:
                raise BridgeError("GET_TRANSCRIPT requires a thread id")
            result = client.request("thread/read", {"threadId": rest, "includeTurns": True})
            thread = result.get("thread", {})
            result["title"] = self.thread_title(thread)
            result["transcriptText"] = self.transcript_text(thread)
            self.ok(result)
            return False
        if command == "LIST_FILES":
            path = rest or self.server.workspace
            self.ok(client.request("fs/readDirectory", {"path": path}))
            return False
        if command == "READ_FILE":
            if not rest:
                raise BridgeError("READ_FILE requires an absolute path")
            result = client.request("fs/readFile", {"path": rest})
            data = base64.b64decode(result.get("dataBase64", ""))
            limit = 256 * 1024
            truncated = len(data) > limit
            sample = data[:limit]
            try:
                result["text"] = sample.decode("utf-8")
                result["encoding"] = "utf-8"
            except UnicodeDecodeError:
                result["text"] = ""
                result["encoding"] = "binary"
            result["path"] = rest
            result["truncated"] = truncated
            self.ok(result)
            return False
        if command == "START_TASK":
            if os.environ.get("CLASSICCODE_ENABLE_TASKS") != "1":
                raise BridgeError("START_TASK disabled; set CLASSICCODE_ENABLE_TASKS=1")
            workspace = self.server.workspace
            prompt = rest.strip()
            if "\t" in rest:
                workspace, prompt = rest.split("\t", 1)
                workspace = workspace.strip() or self.server.workspace
                prompt = prompt.strip()
            if not prompt:
                raise BridgeError("START_TASK requires a prompt")
            thread_result = client.request("thread/start", {"cwd": workspace})
            thread_id = thread_result["thread"]["id"]
            turn_params = {
                "threadId": thread_id,
                "input": [{"type": "text", "text": prompt, "text_elements": []}],
            }
            turn_result = client.request("turn/start", turn_params)
            self.ok({"thread": thread_result, "turn": turn_result})
            return False
        if command == "CANCEL_TASK":
            tokens = rest.split()
            if len(tokens) != 2:
                raise BridgeError("CANCEL_TASK requires thread id and turn id")
            self.ok(client.request("turn/interrupt", {"threadId": tokens[0], "turnId": tokens[1]}))
            return False
        if command == "TAIL_LOGS":
            if not rest:
                raise BridgeError("TAIL_LOGS requires a thread id")
            self.ok(client.request("thread/read", {"threadId": rest, "includeTurns": True}))
            return False
        if command == "HELP":
            self.send_line("OK HELLO PING INFO STATUS LIST_WORKSPACES LIST_SESSIONS GET_TRANSCRIPT LIST_FILES READ_FILE START_TASK CANCEL_TASK TAIL_LOGS QUIT")
            return False
        self.send_line("ERR unknown command")
        return False


class ClassicCodeBridgeServer(socketserver.ThreadingTCPServer):
    allow_reuse_address = True

    def __init__(self, address, handler, codex_client, workspace):
        socketserver.ThreadingTCPServer.__init__(self, address, handler)
        self.codex_client = codex_client
        self.workspace = workspace
        self.client_lock = threading.Lock()


def main(argv):
    parser = argparse.ArgumentParser(description="ClassicCode Codex app-server bridge")
    parser.add_argument("--host", default=os.environ.get("CLASSICCODE_HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("CLASSICCODE_PORT", "17390")))
    parser.add_argument("--workspace", default=os.environ.get("CLASSICCODE_WORKSPACE", os.getcwd()))
    parser.add_argument("--codex", default=os.environ.get("CLASSICCODE_CODEX", "codex"))
    args = parser.parse_args(argv)

    codex_client = CodexAppServerClient(args.codex, os.path.abspath(args.workspace))
    server = ClassicCodeBridgeServer(
        (args.host, args.port),
        ClassicCodeRequestHandler,
        codex_client,
        os.path.abspath(args.workspace),
    )
    sys.stderr.write(
        "ClassicCodeCodexBridge listening on %s:%d for workspace %s\n"
        % (args.host, args.port, os.path.abspath(args.workspace))
    )
    sys.stderr.flush()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        codex_client.close()


if __name__ == "__main__":
    main(sys.argv[1:])
