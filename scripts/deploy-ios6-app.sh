#!/bin/sh
set -eu

BUILD_HOST=${BUILD_HOST:-classiccode-mac109}
REMOTE_DIR=${REMOTE_DIR:-ClassicCode}
IOS_DEVICE_HOST=${IOS_DEVICE_HOST:-classiccode-ipad6-via-local}
REMOTE_BRANCH=${REMOTE_BRANCH:-main}
REPO_URL=${REPO_URL:-}
REMOTE_GIT_SSL_NO_VERIFY=${REMOTE_GIT_SSL_NO_VERIFY:-1}
LOCAL_GIT_PORT=${LOCAL_GIT_PORT:-9418}
LOCAL_GIT_DAEMON_PID=

cleanup() {
  if [ -n "$LOCAL_GIT_DAEMON_PID" ]; then
    kill "$LOCAL_GIT_DAEMON_PID" 2>/dev/null || true
    wait "$LOCAL_GIT_DAEMON_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT HUP INT TERM

cd "$(dirname "$0")/.."

if [ -z "$REPO_URL" ]; then
  LOCAL_GIT_HOST=${LOCAL_GIT_HOST:-$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)}
  if [ -z "$LOCAL_GIT_HOST" ]; then
    echo "Unable to determine local IP address; set REPO_URL or LOCAL_GIT_HOST." >&2
    exit 1
  fi

  REPO_NAME=$(basename "$PWD")
  REPO_URL="git://$LOCAL_GIT_HOST:$LOCAL_GIT_PORT/$REPO_NAME"
  GIT_DAEMON_LOG=${GIT_DAEMON_LOG:-/tmp/classiccode-git-daemon.log}
  git daemon --reuseaddr --base-path="$(dirname "$PWD")" --export-all --listen="$LOCAL_GIT_HOST" --port="$LOCAL_GIT_PORT" >"$GIT_DAEMON_LOG" 2>&1 &
  LOCAL_GIT_DAEMON_PID=$!
  sleep 1

  if ! kill -0 "$LOCAL_GIT_DAEMON_PID" 2>/dev/null; then
    cat "$GIT_DAEMON_LOG" >&2
    exit 1
  fi
fi

ssh "$BUILD_HOST" "
set -eu
if [ '$REMOTE_GIT_SSL_NO_VERIFY' = '1' ]; then
  export GIT_SSL_NO_VERIFY=true
fi
if [ ! -d '$REMOTE_DIR/.git' ]; then
  if [ -e '$REMOTE_DIR' ]; then
    mv '$REMOTE_DIR' '$REMOTE_DIR.rsync-backup-'\"\$(date +%Y%m%d%H%M%S)\"
  fi
  git clone -b '$REMOTE_BRANCH' '$REPO_URL' '$REMOTE_DIR'
fi
cd '$REMOTE_DIR'
git remote set-url origin '$REPO_URL'
git fetch origin '$REMOTE_BRANCH:refs/remotes/origin/$REMOTE_BRANCH'
git checkout '$REMOTE_BRANCH' >/dev/null 2>&1 || git checkout -b '$REMOTE_BRANCH'
git reset --hard 'origin/$REMOTE_BRANCH'
make deploy-ios IOS_DEVICE_HOST='$IOS_DEVICE_HOST'
"
