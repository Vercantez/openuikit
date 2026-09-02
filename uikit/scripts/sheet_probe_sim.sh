#!/bin/zsh
# Runs the iOS Simulator MODAL SHEET oracle (SheetProbe) end-to-end: builds
# the app, boots (or reuses) a headless simulator, installs + launches the
# probe, waits for completion, and copies the measurement JSONs to <outdir>.
#
#   scripts/sheet_probe_sim.sh <outdir>
#
# Same pattern as scripts/scroll_probe_sim.sh (which measures scroll
# physics); this one measures the interactive pageSheet — static geometry
# and grabber, drag tracking, dim alpha vs. progress, dismissal thresholds
# and detent snapping. See Tools/oracle2/sheetprobe/main.swift.
set -e
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: sheet_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"

SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/SheetProbe.app
mkdir -p "$APP"
swiftc -O -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/sheetprobe/main.swift Tools/oracle2/scrollshared.swift \
  -o "$APP/sheetprobe"
cp Tools/oracle2/SheetProbe-Info.plist "$APP/Info.plist"
echo "built $APP"

DEVNAME="OpenUIKit-SheetProbe"
DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
RUNTIME=$(xcrun simctl list runtimes | grep -o 'com.apple.CoreSimulator.SimRuntime.iOS-26[0-9-]*' | tail -1)
UDID=$(xcrun simctl list devices | grep "$DEVNAME" | grep -o '[0-9A-F-]\{36\}' | head -1)
if [[ -z "$UDID" ]]; then
  UDID=$(xcrun simctl create "$DEVNAME" "$DEVTYPE" "$RUNTIME")
  echo "created simulator $UDID"
fi
STATE=$(xcrun simctl list devices | grep "$UDID" | grep -o '(Booted)' || true)
if [[ -z "$STATE" ]]; then
  echo "booting simulator $UDID ..."
  xcrun simctl boot "$UDID"
  xcrun simctl bootstatus "$UDID"
fi

xcrun simctl install "$UDID" "$APP"
echo "launching probe (~60s of scripted sheet gestures)..."
xcrun simctl launch --console-pty "$UDID" com.openuikit.sheetprobe || true

CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.sheetprobe data)
cp "$CONTAINER"/Documents/*.json "$OUTDIR"/ 2>/dev/null || echo "WARNING: no measurement JSONs found"
cp "$CONTAINER"/Documents/probe.log "$OUTDIR"/ 2>/dev/null || true
ls -l "$OUTDIR"

xcrun simctl shutdown "$UDID" || true
echo "measurements in $OUTDIR"
