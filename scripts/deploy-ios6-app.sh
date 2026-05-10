#!/bin/sh
set -eu

BUILD_HOST=${BUILD_HOST:-classiccode-mac109}
REMOTE_DIR=${REMOTE_DIR:-ClassicCode}
IOS_DEVICE_HOST=${IOS_DEVICE_HOST:-classiccode-ipad6-via-local}
REMOTE_BRANCH=${REMOTE_BRANCH:-main}
REPO_URL=${REPO_URL:-https://github.com/ruabbit/ClassicCode.git}
REMOTE_GIT_SSL_NO_VERIFY=${REMOTE_GIT_SSL_NO_VERIFY:-1}

cd "$(dirname "$0")/.."

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
git fetch origin '$REMOTE_BRANCH'
git checkout '$REMOTE_BRANCH' >/dev/null 2>&1 || git checkout -b '$REMOTE_BRANCH'
git reset --hard FETCH_HEAD
make deploy-ios IOS_DEVICE_HOST='$IOS_DEVICE_HOST'
"
