#!/bin/bash
# Run from uikit/: scripts/signal_edge_probe_sim.sh /tmp/output
# UIScrollEdgeElementContainerInteraction appearance on a private iPhone 16 /
# iOS 26.1, Signal's setup order. Output: edge.json + screen-<phase>.png
# render-server screenshots (the effect is not in drawHierarchy snapshots).
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: signal_edge_probe_sim.sh /tmp/output}
mkdir -p "$out/SignalEdgeProbe.app"
app="$out/SignalEdgeProbe.app"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.0-simulator -sdk "$sdk" Tools/oracle2/signalrowsprobe/edge.swift -o "$app/probe"
python3 - "$app/Info.plist" <<'PY'
import plistlib,sys
plistlib.dump({'CFBundleIdentifier':'com.openuikit.signaledgeprobe','CFBundleExecutable':'probe','CFBundleName':'SignalEdgeProbe','CFBundleDevelopmentRegion':'en','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1,2],'UILaunchScreen':{}},open(sys.argv[1],'wb'))
PY
name="OpenUIKit-Signal-rows${SIM_DEVICE_SUFFIX:--uikit-signal-rows}"
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-26-1);fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
trap 'xcrun simctl terminate "$device" com.openuikit.signaledgeprobe >/dev/null 2>&1 || true; xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" com.openuikit.signaledgeprobe data)
rm -f "$container"/Documents/*.marker "$container"/Documents/*.ack "$container/Documents/edge.json"
xcrun simctl launch "$device" com.openuikit.signaledgeprobe
wait_marker() { for _ in $(seq 1 300); do [ -f "$container/Documents/$1.marker" ] && return 0; sleep 0.2; done; echo "timeout waiting for $1" >&2; return 1; }
for phase in rest under60 under0 under100 bottomUnder bottomRest reattach hard automaticAgain hiddenEdge shownEdge darkContent noContent; do
  wait_marker "$phase"
  xcrun simctl io "$device" screenshot "$out/screen-$phase.png" >/dev/null
  touch "$container/Documents/$phase.ack"
done
wait_marker done
cp "$container/Documents/edge.json" "$out/"
echo "Measured iOS 26.1 edge appearance: $out/edge.json"
