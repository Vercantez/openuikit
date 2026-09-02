#!/bin/zsh
# Builds the real-UIKit oracle (Mac Catalyst) into Tools/oracle/oracle
set -e
cd "$(dirname "$0")/.."
SDK=$(xcrun --show-sdk-path --sdk macosx)
swiftc -O -target arm64-apple-ios26.1-macabi -sdk "$SDK" \
  -Fsystem "$SDK/System/iOSSupport/System/Library/Frameworks" \
  -I "$SDK/System/iOSSupport/usr/lib/swift" \
  -L "$SDK/System/iOSSupport/usr/lib/swift" \
  Tools/oracle/main.swift Tools/oracle/SceneKit.swift -o Tools/oracle/oracle
echo "built Tools/oracle/oracle"
