#!/bin/sh
set -eu

BUILD_HOST=${BUILD_HOST:-classiccode-mac109}
REMOTE_ICON_DIR=${REMOTE_ICON_DIR:-/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources}
WORK_DIR=${WORK_DIR:-/tmp/classiccode-osx-file-icons}
OUTPUT_DIR=${OUTPUT_DIR:-Resources/iOS/FileIcons}

cd "$(dirname "$0")/.."

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$OUTPUT_DIR"

scp "$BUILD_HOST:$REMOTE_ICON_DIR/GenericFolderIcon.icns" "$WORK_DIR/"
scp "$BUILD_HOST:$REMOTE_ICON_DIR/GenericDocumentIcon.icns" "$WORK_DIR/"
scp "$BUILD_HOST:$REMOTE_ICON_DIR/GenericApplicationIcon.icns" "$WORK_DIR/"
scp "$BUILD_HOST:$REMOTE_ICON_DIR/ExecutableBinaryIcon.icns" "$WORK_DIR/"

generate_icon() {
  source_name=$1
  output_name=$2
  sips -s format png "$WORK_DIR/$source_name.icns" --out "$OUTPUT_DIR/$output_name-raw.png" >/dev/null
  sips -z 64 64 "$OUTPUT_DIR/$output_name-raw.png" --out "$OUTPUT_DIR/$output_name.png" >/dev/null
  sips -z 32 32 "$OUTPUT_DIR/$output_name-raw.png" --out "$OUTPUT_DIR/$output_name-small.png" >/dev/null
  rm "$OUTPUT_DIR/$output_name-raw.png"
}

generate_icon GenericFolderIcon folder
generate_icon GenericDocumentIcon document
generate_icon GenericApplicationIcon application
generate_icon ExecutableBinaryIcon executable
