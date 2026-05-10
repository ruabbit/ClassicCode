#!/bin/sh
set -eu

BUILD_HOST=${BUILD_HOST:-classiccode-mac109}
REMOTE_DIR=${REMOTE_DIR:-ClassicCode}
IOS_DEVICE_HOST=${IOS_DEVICE_HOST:-classiccode-ipad6-via-local}

cd "$(dirname "$0")/.."

rsync -az --delete \
  --exclude .git \
  --exclude build \
  ./ "$BUILD_HOST:$REMOTE_DIR/"

ssh "$BUILD_HOST" "cd '$REMOTE_DIR' && make deploy-ios IOS_DEVICE_HOST='$IOS_DEVICE_HOST'"
