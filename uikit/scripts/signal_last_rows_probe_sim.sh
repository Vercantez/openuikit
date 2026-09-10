#!/bin/bash
# Run from uikit/: scripts/signal_last_rows_probe_sim.sh /tmp/output [ipad]
# Measures Signal-iOS's last four blocking UIKit rows on a private iPhone 16
# (or iPad (A16) with the second argument) / iOS 26.1: UITab + the tabs API,
# UINavigationBarDelegate on a standalone and a controller-managed bar,
# NSIndexPath conveniences, UICornerConfiguration layer state and pixels.
# Output: signal-last-rows.json, screen-corners1.png, screen-corners2.png.
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: signal_last_rows_probe_sim.sh /tmp/output [ipad]}
family=${2:-iphone}
mkdir -p "$out/SignalLastRowsProbe.app"
app="$out/SignalLastRowsProbe.app"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.0-simulator -sdk "$sdk" Tools/oracle2/signallastrowsprobe/main.swift -o "$app/probe"
python3 - "$app/Info.plist" <<'PY'
import plistlib,sys
plistlib.dump({'CFBundleIdentifier':'com.openuikit.signallastrowsprobe','CFBundleExecutable':'probe','CFBundleName':'SignalLastRowsProbe','CFBundleDevelopmentRegion':'en','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1,2],'UILaunchScreen':{}},open(sys.argv[1],'wb'))
PY
if [ "$family" = ipad ]; then
  name="OpenUIKit-iPad-A16${SIM_DEVICE_SUFFIX:--uikit-signal-last-rows}"
  devtype=com.apple.CoreSimulator.SimDeviceType.iPad-A16
else
  name="OpenUIKit-Signal-last-rows${SIM_DEVICE_SUFFIX:--uikit-signal-last-rows}"
  devtype=com.apple.CoreSimulator.SimDeviceType.iPhone-16
fi
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" "$devtype" com.apple.CoreSimulator.SimRuntime.iOS-26-1);fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
trap 'xcrun simctl terminate "$device" com.openuikit.signallastrowsprobe >/dev/null 2>&1 || true; xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" com.openuikit.signallastrowsprobe data)
rm -f "$container"/Documents/*.marker "$container"/Documents/*.ack "$container/Documents/signal-last-rows.json"
xcrun simctl launch "$device" com.openuikit.signallastrowsprobe
wait_marker() { for _ in $(seq 1 600); do [ -f "$container/Documents/$1.marker" ] && return 0; sleep 0.2; done; echo "timeout waiting for $1" >&2; return 1; }
for phase in corners1 corners2; do
  wait_marker "$phase"
  xcrun simctl io "$device" screenshot "$out/screen-$phase.png" >/dev/null
  touch "$container/Documents/$phase.ack"
done
wait_marker done
cp "$container/Documents/signal-last-rows.json" "$out/"
echo "Measured iOS 26.1 state: $out/signal-last-rows.json"
