#!/bin/bash
# Run from uikit/: scripts/firefox_last_rows_probe_sim.sh /tmp/output [iphone|ipad] [--edge]
# Measures firefox-ios' last two blocking rows: UIMenuBuilder (when
# buildMenu(with:) runs, which responders get it, the default identifiers,
# what insertChild/insertSibling/replace/remove do) and UICommandAlternate
# (data model + which action fires for a hardware key press carrying an
# alternate's modifier flags). Key presses are injected inside the probe
# through UIKit's physical-keyboard event class (see main.swift: the host
# System Events route delivered nothing on this Mac).
# Output: $out/firefoxlastrows.json.
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: firefox_last_rows_probe_sim.sh /tmp/output [iphone|ipad] [--edge]}
kind=${2:-iphone}
edge=${3:-}
mkdir -p "$out/FirefoxLastRowsProbe.app"
app="$out/FirefoxLastRowsProbe.app"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -target arm64-apple-ios26.0-simulator -sdk "$sdk" Tools/oracle2/firefoxlastrowsprobe/main.swift -o "$app/probe"
python3 - "$app/Info.plist" <<'PY'
import plistlib,sys
plistlib.dump({'CFBundleIdentifier':'com.openuikit.firefoxlastrowsprobe','CFBundleExecutable':'probe','CFBundleName':'FirefoxLastRowsProbe','CFBundleDevelopmentRegion':'en','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1,2],'UILaunchScreen':{}},open(sys.argv[1],'wb'))
PY
case "$kind" in
 iphone) devtype=com.apple.CoreSimulator.SimDeviceType.iPhone-16;;
 ipad) devtype=com.apple.CoreSimulator.SimDeviceType.iPad-A16;;
 *) echo "unknown kind $kind" >&2; exit 2;;
esac
name="OpenUIKit-FirefoxLastRows-$kind${SIM_DEVICE_SUFFIX:--firefox-last-rows}"
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" "$devtype" com.apple.CoreSimulator.SimRuntime.iOS-26-1); fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
trap 'xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" com.openuikit.firefoxlastrowsprobe data)
rm -f "$container/Documents/firefoxlastrows.json" "$container/Documents/phase-"*
# SIM_OPEN_APP=1 points Simulator.app at this device first; that attaches
# the host keyboard, which is the condition the launch-time build depends on.
if [ "${SIM_OPEN_APP:-0}" = 1 ]; then open -a Simulator --args -CurrentDeviceUDID "$device" || true; sleep 3; fi
if [ -z "$edge" ]; then
 xcrun simctl launch --console-pty "$device" com.openuikit.firefoxlastrowsprobe || true
else
 xcrun simctl launch --console-pty "$device" com.openuikit.firefoxlastrowsprobe --edge || true
fi
cp "$container/Documents/firefoxlastrows.json" "$out/firefoxlastrows.json"
echo "Measured iOS 26.1 state: $out/firefoxlastrows.json"
