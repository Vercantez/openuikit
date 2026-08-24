#!/bin/zsh
# Builds oracle v2 — the real-window (drawHierarchy) Mac Catalyst APP —
# into Tools/oracle2/Oracle2.app. Invoke it via Tools/oracle2/run.sh.
set -e
cd "$(dirname "$0")/.."
SDK=$(xcrun --show-sdk-path --sdk macosx)
APP=Tools/oracle2/Oracle2.app
mkdir -p "$APP/Contents/MacOS"
swiftc -O -target arm64-apple-ios26.1-macabi -sdk "$SDK" \
  -Fsystem "$SDK/System/iOSSupport/System/Library/Frameworks" \
  -I "$SDK/System/iOSSupport/usr/lib/swift" \
  -L "$SDK/System/iOSSupport/usr/lib/swift" \
  Tools/oracle2/main.swift Tools/oracle/SceneKit.swift \
  -o "$APP/Contents/MacOS/oracle2"
cp Tools/oracle2/Info.plist "$APP/Contents/Info.plist"
echo "built $APP"
