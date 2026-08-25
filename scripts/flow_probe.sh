#!/bin/zsh
# Builds and runs the real-UIKit UICollectionViewFlowLayout geometry probe
# (Mac Catalyst). Prints item/supplementary frames for a battery of flow
# configurations — the measurements OpenUIKit's UICollectionViewFlowLayout is
# fitted to (see docs/KNOWN_GAPS.md "collection view").
set -e
cd "$(dirname "$0")/.."
SDK=$(xcrun --show-sdk-path --sdk macosx)
swiftc -O -target arm64-apple-ios26.1-macabi -sdk "$SDK" \
  -Fsystem "$SDK/System/iOSSupport/System/Library/Frameworks" \
  -I "$SDK/System/iOSSupport/usr/lib/swift" \
  -L "$SDK/System/iOSSupport/usr/lib/swift" \
  Tools/oracle/flowprobe/main.swift -o Tools/oracle/flowprobe/flowprobe
exec Tools/oracle/flowprobe/flowprobe "$@"
