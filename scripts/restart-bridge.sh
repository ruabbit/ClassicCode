#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

BRIDGE_HOST=${BRIDGE_HOST:-0.0.0.0}
BRIDGE_PORT=${BRIDGE_PORT:-17392}
BRIDGE_WORKSPACE=${BRIDGE_WORKSPACE:-$PWD}
BRIDGE_LABEL=${BRIDGE_LABEL:-io.ruabbit.ClassicCodeBridge}
BRIDGE_LOG=${BRIDGE_LOG:-/tmp/classiccode-bridge-$BRIDGE_PORT.log}
BRIDGE_PLIST=${BRIDGE_PLIST:-/tmp/$BRIDGE_LABEL.plist}
CLASSICCODE_ENABLE_TASKS=${CLASSICCODE_ENABLE_TASKS:-1}
CLASSICCODE_CODEX=${CLASSICCODE_CODEX:-$(command -v codex)}
BRIDGE_PATH=${BRIDGE_PATH:-/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin}

cat > "$BRIDGE_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$BRIDGE_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$PWD/Sources/Bridge/ClassicCodeCodexBridge.py</string>
    <string>--host</string>
    <string>$BRIDGE_HOST</string>
    <string>--port</string>
    <string>$BRIDGE_PORT</string>
    <string>--workspace</string>
    <string>$BRIDGE_WORKSPACE</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>CLASSICCODE_ENABLE_TASKS</key>
    <string>$CLASSICCODE_ENABLE_TASKS</string>
    <key>CLASSICCODE_CODEX</key>
    <string>$CLASSICCODE_CODEX</string>
    <key>PATH</key>
    <string>$BRIDGE_PATH</string>
  </dict>
  <key>KeepAlive</key>
  <true/>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$BRIDGE_LOG</string>
  <key>StandardErrorPath</key>
  <string>$BRIDGE_LOG</string>
</dict>
</plist>
EOF

DOMAIN="gui/$(id -u)"
launchctl bootout "$DOMAIN/$BRIDGE_LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "$DOMAIN" "$BRIDGE_PLIST"
launchctl kickstart -k "$DOMAIN/$BRIDGE_LABEL"
sleep 1
launchctl print "$DOMAIN/$BRIDGE_LABEL" | sed -n '1,40p'
