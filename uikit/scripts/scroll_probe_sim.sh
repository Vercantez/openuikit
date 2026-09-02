#!/bin/zsh
# Runs the iOS Simulator scroll-physics oracle (SimProbe) end-to-end:
# builds the app, boots (or reuses) a simulator, installs + launches the
# probe, waits for completion, and copies the golden trace JSONs to <outdir>.
#
#   scripts/scroll_probe_sim.sh <outdir>
#
# The simulator runs HEADLESS (no Simulator.app window is opened); the
# device is created once (name "OpenUIKit-ScrollProbe") and shut down after.
set -e
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: scroll_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"

./scripts/build_simprobe.sh

DEVNAME="OpenUIKit-ScrollProbe"
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

xcrun simctl install "$UDID" Tools/oracle2/SimProbe.app
echo "launching probe (takes ~60-90s of scripted gestures)..."
xcrun simctl launch --console-pty "$UDID" com.openuikit.simprobe || true

CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.simprobe data)
cp "$CONTAINER"/Documents/*.json "$OUTDIR"/ 2>/dev/null || echo "WARNING: no trace JSONs found"
cp "$CONTAINER"/Documents/probe.log "$OUTDIR"/ 2>/dev/null || true
ls -l "$OUTDIR"

xcrun simctl shutdown "$UDID" || true
echo "traces in $OUTDIR"
