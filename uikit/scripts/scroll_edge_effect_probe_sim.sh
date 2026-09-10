#!/bin/bash
# Run from uikit/: scripts/scroll_edge_effect_probe_sim.sh /tmp/output
# UIScrollEdgeEffect on a private iPhone 16 / iOS 26.1: default edge effects
# under navigation bar / tab bar / toolbar for UIScrollView, UITableView and
# UICollectionView, engagement thresholds, .soft/.hard profiles, isHidden,
# and the relation to UIScrollEdgeElementContainerInteraction. Output:
# edgeeffect.json + screen-<phase>.png render-server screenshots.
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: scroll_edge_effect_probe_sim.sh /tmp/output}
mkdir -p "$out/ScrollEdgeEffectProbe.app"
app="$out/ScrollEdgeEffectProbe.app"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.0-simulator -sdk "$sdk" Tools/oracle2/scrolledgeeffectprobe/main.swift -o "$app/probe"
python3 - "$app/Info.plist" <<'PY'
import plistlib,sys
plistlib.dump({'CFBundleIdentifier':'com.openuikit.scrolledgeeffectprobe','CFBundleExecutable':'probe','CFBundleName':'ScrollEdgeEffectProbe','CFBundleDevelopmentRegion':'en','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1,2],'UILaunchScreen':{}},open(sys.argv[1],'wb'))
PY
name="OpenUIKit-ScrollEdgeEffect${SIM_DEVICE_SUFFIX:--uikit-scroll-edge-effect}"
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-26-1);fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
trap 'xcrun simctl terminate "$device" com.openuikit.scrolledgeeffectprobe >/dev/null 2>&1 || true; xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" com.openuikit.scrolledgeeffectprobe data)
rm -f "$container"/Documents/*.marker "$container"/Documents/*.ack "$container/Documents/edgeeffect.json" "$container/Documents/phases.txt"
xcrun simctl launch "$device" com.openuikit.scrolledgeeffectprobe
wait_file() { for _ in $(seq 1 300); do [ -f "$1" ] && return 0; sleep 0.2; done; echo "timeout waiting for $1" >&2; return 1; }
wait_file "$container/Documents/phases.txt"
while read -r phase; do
  [ -z "$phase" ] && continue
  wait_file "$container/Documents/$phase.marker"
  xcrun simctl io "$device" screenshot "$out/screen-$phase.png" >/dev/null
  touch "$container/Documents/$phase.ack"
done < "$container/Documents/phases.txt"
wait_file "$container/Documents/done.marker"
cp "$container/Documents/edgeeffect.json" "$container/Documents/phases.txt" "$out/"
echo "Measured iOS 26.1 scroll edge effects: $out/edgeeffect.json"
