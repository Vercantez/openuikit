#!/bin/zsh
# Renders scene JSONs with REAL iOS UIKit in the headless iOS Simulator
# (SimScene app — Tools/oracle2/simscene). Needed for chrome the Mac Catalyst
# oracles cannot produce (currently: "modal" pageSheet scenes — Catalyst
# bridges those into AppKit sheet windows whose chrome UIKit cannot capture).
#
#   scripts/render_sim_scenes.sh <outdir> <scene.json>...
#
# Scene size must equal the device portrait size (iPhone 16: 393 x 852).
# The simulator runs headless; the device ("OpenUIKit-Chrome", iPhone 16)
# is created once and shut down after.
set -e
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: render_sim_scenes.sh <outdir> <scene.json>...}
shift
(( $# > 0 )) || { echo "no scenes given"; exit 1 }
mkdir -p "$OUTDIR"

# Build the app.
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/SimScene.app
mkdir -p "$APP"
swiftc -O -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/simscene/main.swift Tools/oracle/SceneKit.swift \
  -o "$APP/simscene"
cp Tools/oracle2/SimScene-Info.plist "$APP/Info.plist"
echo "built $APP"

# SIM_DEVICE=2x selects a 2x device (iPhone SE 3rd generation, 375 x 667):
# the honest oracle for scale-2 scenes — a 3x device captured at 2x
# resamples every view edge (measured 2026-09-04: label backgrounds off by
# 2-4/255 along their frame edges). Window/modal scenes need the iPhone 16.
if [[ "${SIM_DEVICE:-}" == "2x" ]]; then
  DEVNAME="OpenUIKit-2x"
  DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation"
else
  DEVNAME="OpenUIKit-Chrome"
  DEVTYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-16"
fi
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
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.simscene data)
rm -rf "$CONTAINER/Documents/scenes" "$CONTAINER/Documents/out"
mkdir -p "$CONTAINER/Documents/scenes"
cp "$@" "$CONTAINER/Documents/scenes/"
xcrun simctl launch --console-pty "$UDID" com.openuikit.simscene || true

if [[ ! -f "$CONTAINER/Documents/out/DONE" ]]; then
  echo "ERROR: renderer did not complete (no DONE marker)"
  xcrun simctl shutdown "$UDID" || true
  exit 1
fi
STATUS=$(cat "$CONTAINER/Documents/out/DONE")
cp "$CONTAINER"/Documents/out/*.png "$CONTAINER"/Documents/out/*.layout.json "$OUTDIR"/ 2>/dev/null || true
xcrun simctl shutdown "$UDID" || true
if [[ "$STATUS" != "ok" ]]; then
  echo "ERROR: $STATUS"
  exit 1
fi
echo "sim-rendered $# scene(s) into $OUTDIR"
