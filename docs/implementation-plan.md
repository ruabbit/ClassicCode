# ClassicCode Implementation Plan

## Goal

Build a legacy Apple client for Codex-style remote control:

- iOS 6 client running on jailbroken iPad mini 1.
- OS X 10.6-compatible client/host-side components where needed.
- OS X 10.9 build machine used as the verified old-toolchain build host.
- Backend direction: Codex remote-control, not a custom long-term task runner.

The current `ClassicCodeHost` is a temporary compatibility and transport shim. It exists to prove old SDK builds, socket behavior, app deployment, and UI integration on iOS 6. It should not become the product backend unless a later decision explicitly changes that.

## Backend Boundary

### Source of Truth

The intended backend is `codex remote-control`.

ClassicCode should eventually talk to a Codex-facing remote-control surface that owns:

- session lifecycle,
- model/task execution,
- workspace context,
- command approval state,
- transcript/history,
- diff and file-change metadata,
- run logs and exit state.

### ClassicCode Responsibility

ClassicCode should own the legacy client experience and the minimum bridge required for old platforms:

- connection profiles,
- connection status,
- workspace/session navigation,
- transcript display,
- code/file/log browsing,
- task controls exposed by the Codex backend,
- compatibility transport for iOS 6 and OS X 10.6-era APIs.

### Temporary Host Shim

`Sources/Host/ClassicCodeHost.m` currently provides a line-oriented demo protocol:

```text
HELLO
PING
INFO
HELP
QUIT
```

Use it only for:

- build verification,
- deploy verification,
- network and tunnel testing,
- UI integration smoke tests.

Do not extend it into a parallel Codex clone unless needed as an adapter to `codex remote-control`.

## Product Model

### Connections

Connections are settings, not primary homepage content.

Connection profiles should live under Settings and contain:

- display name,
- host,
- port or tunnel profile,
- workspace default,
- optional authentication metadata,
- last successful check time,
- diagnostic result.

The home screen should show only connection state:

- disconnected,
- connecting,
- connected,
- running,
- error.

### Information Layout

Code, transcripts, logs, sessions, and file trees are high-density information views. The primary workbench should use a master-detail layout:

- left pane: navigation/object list,
- right pane: selected content.

On iPad landscape this should be a persistent split view. On narrow/portrait layouts it can collapse into a navigation stack, but the information model remains master-detail.

Avoid a vertical stack where the user loses navigation context while reading code or transcript content.

## Milestones

### Milestone 1: UI Shell Rework

Purpose: fix the interaction model before expanding backend behavior.

Deliverables:

- Move connection editing out of the home screen.
- Add a Settings screen for connection profiles.
- Store connection settings in `NSUserDefaults`.
- Home screen shows status only and gives access to Settings and Workbench.
- Add an iPad-oriented split-view Workbench.
- Left pane starts with:
  - Overview
  - Sessions
  - Files
  - Logs
  - Tasks
- Right pane displays the selected object.
- Keep `HELLO`/`PING`/`INFO` as internal diagnostics, not as the main user workflow.

Verification:

- `scripts/build-on-10.9.sh`
- `scripts/deploy-ios6-app.sh`
- Launchable app bundle at `/Applications/ClassicCodeClient.app`
- Manual UI check on iPad when practical.

### Milestone 2: Codex Remote-Control Adapter Boundary

Purpose: define the bridge between the legacy app and Codex remote-control.

Deliverables:

- Define a transport-neutral adapter interface in shared code.
- Keep current line protocol behind a diagnostic adapter.
- Add placeholder operations that map to Codex concepts:
  - list workspaces,
  - list sessions,
  - get session transcript,
  - list files,
  - read file,
  - start task,
  - cancel task,
  - tail logs.
- Document which operations require real Codex remote-control support.

Verification:

- Adapter compiles on iOS 6 and OS X 10.6 targets.
- Diagnostic adapter still passes existing host smoke tests.
- UI consumes adapter state instead of direct socket commands.

### Milestone 3: Real Backend Integration

Purpose: connect the app to the real Codex remote-control surface once its local API is confirmed.

Confirmed local protocol facts:

- `codex app-server` supports a `stdio://` transport with newline-delimited JSON objects.
- Messages use JSON-RPC-like objects without a required `jsonrpc` field:
  - request: `{"id":1,"method":"thread/list","params":{...}}`
  - response: `{"id":1,"result":{...}}`
  - notification: `{"method":"remoteControl/status/changed","params":{...}}`
- Initial handshake:
  - client sends `initialize` with `clientInfo`,
  - server returns `userAgent`, `codexHome`, `platformFamily`, and `platformOs`,
  - client sends `initialized`.
- Useful v2 methods for ClassicCode:
  - `thread/list` for session browsing,
  - `thread/read` with `includeTurns: true` for transcript/log browsing,
  - `fs/readDirectory` for file navigation,
  - `fs/readFile` for file contents as base64,
  - `thread/start` and `turn/start` for task execution,
  - `turn/interrupt` for cancellation when both thread id and turn id are known.

Bridge decision:

- Legacy iOS 6 / OS X 10.6 clients should not speak the full modern app-server transport directly.
- `Sources/Bridge/ClassicCodeCodexBridge.py` runs on a modern Mac, starts `codex app-server`, and exposes the existing one-line TCP protocol plus Codex-oriented commands.
- The iOS client uses a line adapter against that bridge. The old `ClassicCodeHost` remains a diagnostic shim.

Deliverables:

- Inspect the actual Codex remote-control entrypoint and protocol.
- Implement the adapter against that protocol.
- Preserve the diagnostic shim as a fallback.
- Add error states for:
  - backend unavailable,
  - workspace unavailable,
  - auth/session expired,
  - task failed,
  - transport disconnected.

Verification:

- From iPad, connect through the configured bridge.
- List real sessions or workspaces.
- Open a real transcript/log view.
- Trigger a low-risk task or read-only command.

### Milestone 4: Task Execution UX

Purpose: expose backend work without turning the app into a terminal-only UI.

Deliverables:

- Task status summary on Home.
- Task list in Workbench left pane.
- Detail view with:
  - command/task title,
  - state,
  - transcript/log output,
  - exit code,
  - cancel/retry where supported.
- Avoid exposing raw host/port/protocol commands in primary UI.

Verification:

- Build and deploy to iPad.
- Start a backend task.
- Observe state changes and logs.
- Cancel a running task when supported.

### Milestone 5: Code and Transcript Browsing

Purpose: make the app useful for reading and navigating context.

Deliverables:

- Left-pane file/session navigation.
- Right-pane code viewer.
- Right-pane transcript viewer.
- Basic search or jump affordance if feasible on iOS 6.
- Preserve readable typography and stable layout on iPad mini.

Verification:

- Browse a real workspace file list.
- Open code files.
- Open transcripts/logs.
- Confirm layout remains usable in landscape and portrait.

## Current Verified Environment

### Local Repository

```text
/Users/tanmy/Projects/ClassicCode
origin git@github.com:ruabbit/ClassicCode.git
```

Local machine owns commits and pushes to GitHub.

### Build Machine

```text
classiccode-mac109 -> 10.1.100.96
Mac OS X 10.9.5
Xcode 4.6.3
iPhoneOS6.1.sdk
MacOSX10.7.sdk
```

The build machine uses a Git checkout at:

```text
~/ClassicCode
```

It pulls from:

```text
https://github.com/ruabbit/ClassicCode.git
```

`GIT_SSL_NO_VERIFY=true` is currently used by scripts because the OS X 10.9 certificate chain is too old for GitHub HTTPS verification.

### iOS 6 Device

```text
iPad mini 1
iPad2,5
iOS 6.1.3
192.168.8.187
```

The 10.9 build machine reaches the iPad through the local reverse SSH tunnel:

```text
classiccode-ipad6-via-local
```

## Build and Deploy Gates

Before considering a milestone complete:

```sh
scripts/build-on-10.9.sh
scripts/deploy-ios6-app.sh
```

Check target versions on the 10.9 build machine:

```sh
otool -l build/macosx/ClassicCodeHost | egrep -A3 'LC_VERSION_MIN_MACOSX'
otool -l build/iphoneos/ClassicCodeClient.app/ClassicCodeClient | egrep -A3 'LC_VERSION_MIN_IPHONEOS'
```

Expected:

```text
macOS min 10.6, SDK 10.7
iPhoneOS min 6.0, SDK 6.1
```

## Open Decisions

- Exact `codex remote-control` protocol and entrypoint must be confirmed from the real Codex environment before Milestone 3.
- Whether the bridge should run on the 10.9 build machine, the modern Mac, or both.
- Whether iPad-to-backend traffic should use direct TCP, SSH port forwarding, or a small local bridge process.
- How much code browsing should be local cached content versus live backend reads.
