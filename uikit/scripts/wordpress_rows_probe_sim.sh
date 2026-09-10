#!/bin/bash
# Run from uikit/: PHASE=textitem|popover KIND=iphone|ipad scripts/wordpress_rows_probe_sim.sh /tmp/output
# Measures the WordPress-iOS §9.6 rows: UITextItem (link / tag / attachment
# taps and long presses through UITextViewDelegate, iPhone 16) and
# UIPopoverPresentationControllerSourceItem (popover placement per source
# item kind on iPad A16, adaptation on iPhone 16).
# Output: $out/wordpressrows-$PHASE-$KIND.json.
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: wordpress_rows_probe_sim.sh /tmp/output}
PHASE=${PHASE:-textitem}
KIND=${KIND:-iphone}
mkdir -p "$out/WordPressRowsProbe.app"
app="$out/WordPressRowsProbe.app"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator swiftc -suppress-warnings -target arm64-apple-ios26.0-simulator -sdk "$sdk" Tools/oracle2/wordpressrowsprobe/main.swift -o "$app/probe"
python3 - "$app/Info.plist" <<'PY'
import plistlib,sys
plistlib.dump({'CFBundleIdentifier':'com.openuikit.wordpressrowsprobe','CFBundleExecutable':'probe','CFBundleName':'WordPressRowsProbe','CFBundleDevelopmentRegion':'en','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1,2],'UILaunchScreen':{},
  'CFBundleURLTypes':[{'CFBundleURLName':'com.openuikit.wordpressrowsprobe','CFBundleURLSchemes':['wpprobe']}]},open(sys.argv[1],'wb'))
PY
if [[ "$KIND" == ipad ]]; then
  TYPE=com.apple.CoreSimulator.SimDeviceType.iPad-A16
else
  TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-16
fi
name="OpenUIKit-WPRows-${KIND}${SIM_DEVICE_SUFFIX:--wordpress-rows}"
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" "$TYPE" com.apple.CoreSimulator.SimRuntime.iOS-26-1);fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
trap 'xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" com.openuikit.wordpressrowsprobe data)
rm -f "$container/Documents/wordpressrows-$PHASE.json"
SIMCTL_CHILD_PROBE_PHASE=$PHASE xcrun simctl launch --console-pty "$device" com.openuikit.wordpressrowsprobe "$PHASE" > "$out/console-$PHASE-$KIND.txt" 2>&1 || true
cp "$container/Documents/wordpressrows-$PHASE.json" "$out/wordpressrows-$PHASE-$KIND.json"
echo "Measured iOS 26.1 state: $out/wordpressrows-$PHASE-$KIND.json"
