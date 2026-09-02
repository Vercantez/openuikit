#!/bin/zsh
# Builds SimProbe — the iOS Simulator scroll-physics oracle app — into
# Tools/oracle2/SimProbe.app. Run it end-to-end with scripts/scroll_probe_sim.sh.
set -e
cd "$(dirname "$0")/.."
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/SimProbe.app
mkdir -p "$APP"
swiftc -O -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/simprobe/main.swift Tools/oracle2/scrollshared.swift \
  -o "$APP/simprobe"
cp Tools/oracle2/SimProbe-Info.plist "$APP/Info.plist"
echo "built $APP"
