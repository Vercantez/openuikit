#!/bin/zsh
# Runs the iOS Simulator ALERT oracle (AlertProbe) end-to-end: builds the app,
# boots (or reuses) a headless simulator, installs + launches the probe, waits
# for completion, and copies the measurement JSONs + window snapshots to
# <outdir>.
#
#   scripts/alert_probe_sim.sh <outdir>
#
# Same pattern as scripts/sheet_probe_sim.sh. Measures the iOS UIAlertController
# chrome: platter geometry/corner radius, title & message typography, button
# heights, separator hairlines, destructive/cancel styling, dimming alpha, and
# the flat-colour equivalent of the blur (three known base colours).
# See Tools/oracle2/alertprobe/main.swift.
set -e
setopt null_glob
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: alert_probe_sim.sh <outdir>}
mkdir -p "$OUTDIR"

SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP=Tools/oracle2/AlertProbe.app
mkdir -p "$APP"
swiftc -O -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/alertprobe/main.swift \
  -o "$APP/alertprobe"
cp Tools/oracle2/AlertProbe-Info.plist "$APP/Info.plist"
echo "built $APP"

DEVNAME="OpenUIKit-Chrome"
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
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.alertprobe data)
rm -f "$CONTAINER"/Documents/*.json "$CONTAINER"/Documents/*.png \
      "$CONTAINER"/Documents/*.log "$CONTAINER"/Documents/DONE "$CONTAINER"/Documents/configs.txt

# ONE configuration per launch. A dismissed alert's views outlive the dismissal
# far enough that the next alert stacks on top of it in the same process (the
# dumped view count grew monotonically), and swapping the window's root view
# controller does not evict them — the presentation is a SIBLING of the root in
# the window. A fresh process per configuration is the only reliable isolation.
xcrun simctl launch --console-pty "$UDID" com.openuikit.alertprobe list >/dev/null || true
CONFIGS=$(cat "$CONTAINER/Documents/configs.txt")
echo "configurations: $CONFIGS"
for name in ${=CONFIGS}; do
  echo "  probing $name ..."
  xcrun simctl launch --console-pty "$UDID" com.openuikit.alertprobe "$name" >/dev/null || true
done

cp "$CONTAINER"/Documents/*.json "$OUTDIR"/ 2>/dev/null || echo "WARNING: no measurement JSONs found"
cp "$CONTAINER"/Documents/*.png "$OUTDIR"/ 2>/dev/null || true
cp "$CONTAINER"/Documents/*.log "$OUTDIR"/ 2>/dev/null || true
ls "$OUTDIR" | wc -l

xcrun simctl shutdown "$UDID" || true
echo "measurements in $OUTDIR"
