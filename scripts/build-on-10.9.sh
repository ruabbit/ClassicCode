#!/bin/sh
set -eu

BUILD_HOST=${BUILD_HOST:-classiccode-mac109}
REMOTE_DIR=${REMOTE_DIR:-ClassicCode}

cd "$(dirname "$0")/.."

rsync -az --delete \
  --exclude .git \
  --exclude build \
  ./ "$BUILD_HOST:$REMOTE_DIR/"

ssh "$BUILD_HOST" "cd '$REMOTE_DIR' && make clean all"
