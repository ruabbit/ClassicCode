#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

SOURCE=${SOURCE:-Resources/AppIcon/AppIcon-1024.png}
IOS_DIR=${IOS_DIR:-Resources/iOS/Icons}
MAC_ICONSET=${MAC_ICONSET:-Resources/macOS/ClassicCode.iconset}
MAC_ICNS=${MAC_ICNS:-Resources/macOS/ClassicCode.icns}

if [ ! -f "$SOURCE" ]; then
  echo "Missing source icon: $SOURCE" >&2
  exit 1
fi

mkdir -p "$IOS_DIR" "$MAC_ICONSET"

generate_png() {
  output=$1
  size=$2
  sips -z "$size" "$size" "$SOURCE" --out "$output" >/dev/null
}

generate_png "$IOS_DIR/Icon.png" 57
generate_png "$IOS_DIR/Icon@2x.png" 114
generate_png "$IOS_DIR/Icon-72.png" 72
generate_png "$IOS_DIR/Icon-72@2x.png" 144
generate_png "$IOS_DIR/Icon-Small.png" 29
generate_png "$IOS_DIR/Icon-Small@2x.png" 58
generate_png "$IOS_DIR/Icon-Small-50.png" 50
generate_png "$IOS_DIR/Icon-Small-50@2x.png" 100
generate_png "$IOS_DIR/iTunesArtwork" 512
generate_png "$IOS_DIR/iTunesArtwork@2x" 1024

generate_png "$MAC_ICONSET/icon_16x16.png" 16
generate_png "$MAC_ICONSET/icon_16x16@2x.png" 32
generate_png "$MAC_ICONSET/icon_32x32.png" 32
generate_png "$MAC_ICONSET/icon_32x32@2x.png" 64
generate_png "$MAC_ICONSET/icon_128x128.png" 128
generate_png "$MAC_ICONSET/icon_128x128@2x.png" 256
generate_png "$MAC_ICONSET/icon_256x256.png" 256
generate_png "$MAC_ICONSET/icon_256x256@2x.png" 512
generate_png "$MAC_ICONSET/icon_512x512.png" 512
generate_png "$MAC_ICONSET/icon_512x512@2x.png" 1024

iconutil -c icns "$MAC_ICONSET" -o "$MAC_ICNS"
