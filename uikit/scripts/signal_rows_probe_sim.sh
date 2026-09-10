#!/bin/bash
# Run from uikit/: scripts/signal_rows_probe_sim.sh /tmp/output
# Measures the Signal-iOS blocking rows on a private iPhone 16 / iOS 26.1:
# bounds-change invalidation ordering, UIScrollEdgeElementContainerInteraction
# observables (state + window snapshots + render-server screenshots), and
# UIScreen coordinate spaces. Output: signal-rows.json, *.png.
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: signal_rows_probe_sim.sh /tmp/output}
mkdir -p "$out/SignalRowsProbe.app"
app="$out/SignalRowsProbe.app"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.0-simulator -sdk "$sdk" Tools/oracle2/signalrowsprobe/main.swift -o "$app/probe"
python3 - "$app/Info.plist" <<'PY'
import plistlib,sys
plistlib.dump({'CFBundleIdentifier':'com.openuikit.signalrowsprobe','CFBundleExecutable':'probe','CFBundleName':'SignalRowsProbe','CFBundleDevelopmentRegion':'en','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1,2],'UILaunchScreen':{}},open(sys.argv[1],'wb'))
PY
name="OpenUIKit-Signal-rows${SIM_DEVICE_SUFFIX:--uikit-signal-rows}"
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-26-1);fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
trap 'xcrun simctl terminate "$device" com.openuikit.signalrowsprobe >/dev/null 2>&1 || true; xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" com.openuikit.signalrowsprobe data)
rm -f "$container"/Documents/*.marker "$container"/Documents/*.ack "$container"/Documents/*.png "$container/Documents/signal-rows.json"
xcrun simctl launch "$device" com.openuikit.signalrowsprobe
wait_marker() { for _ in $(seq 1 300); do [ -f "$container/Documents/$1.marker" ] && return 0; sleep 0.2; done; echo "timeout waiting for $1" >&2; return 1; }
for phase in phase1 phase2 phase3 phase4 phase5 phase6 phase7 phase8 phase9 phase10 phase11 phase12 phase13; do
  wait_marker "$phase"
  xcrun simctl io "$device" screenshot "$out/screen-$phase.png" >/dev/null
  touch "$container/Documents/$phase.ack"
done
wait_marker done
cp "$container/Documents/signal-rows.json" "$container"/Documents/*.png "$out/"
echo "Measured iOS 26.1 state: $out/signal-rows.json"
