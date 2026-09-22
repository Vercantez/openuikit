#!/bin/bash
# Run from uikit/: scripts/nib_runtime_probe_sim.sh /tmp/output
# The storyboard/NIB runtime oracle on a private iPhone 16 / iOS 26.1
# simulator. Loads the CARRIED compiled artefacts (the same bytes the port
# test loads): fixtures/nibruntime/NibRuntimeProbe.storyboardc and the
# Eidolon archives under fixtures/realapp/eidolon/nibs.
# Output: $out/nibruntime.json, $out/eidolonnibs.json.
set -euo pipefail
cd "$(dirname "$0")/.."
out=${1:?usage: nib_runtime_probe_sim.sh /tmp/output}
app="$out/NibRuntimeProbe.app"
rm -rf "$app"
mkdir -p "$app/eidolon/Auction" "$app/eidolon/Fulfillment" "$app/eidolon/xib"
cp -R fixtures/nibruntime/NibRuntimeProbe.storyboardc "$app/"
cp fixtures/nibruntime/ProbeXibView.nib "$app/"
cp fixtures/realapp/eidolon/nibs/Auction.storyboardc/*.nib "$app/eidolon/Auction/"
cp fixtures/realapp/eidolon/nibs/Fulfillment.storyboardc/*.nib "$app/eidolon/Fulfillment/"
cp fixtures/realapp/eidolon/nibs/KeypadView.nib "$app/eidolon/xib/"
sdk=$(xcrun --sdk iphonesimulator --show-sdk-path)
xcrun --sdk iphonesimulator clang -target arm64-apple-ios26.0-simulator -isysroot "$sdk" \
  -fobjc-arc -c Tools/oracle2/nibruntimeprobe/OUKTry.m -o "$out/OUKTry.o"
xcrun --sdk iphonesimulator swiftc -swift-version 5 -module-name NibRuntimeTests \
  -target arm64-apple-ios26.0-simulator -sdk "$sdk" \
  -import-objc-header Tools/oracle2/nibruntimeprobe/OUKTry.h "$out/OUKTry.o" \
  Tools/oracle2/nibruntimeprobe/main.swift \
  Tests/NibRuntimeTests/NibRuntimeScenario.swift \
  Tests/NibRuntimeTests/EidolonNibScenario.swift \
  -o "$app/probe"
python3 - "$app/Info.plist" <<'PY'
import plistlib,sys
plistlib.dump({'CFBundleIdentifier':'com.openuikit.nibruntimeprobe','CFBundleExecutable':'probe','CFBundleName':'NibRuntimeProbe','CFBundleDevelopmentRegion':'en','CFBundlePackageType':'APPL','LSRequiresIPhoneOS':True,'UIDeviceFamily':[1,2],'UILaunchScreen':{}},open(sys.argv[1],'wb'))
PY
name="OpenUIKit-NibRuntime${SIM_DEVICE_SUFFIX:--nib-runtime}"
device=$(xcrun simctl list devices -j | python3 -c 'import sys,json;print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"]==sys.argv[1]),""))' "$name")
if [ -z "$device" ]; then device=$(xcrun simctl create "$name" com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-26-1); fi
xcrun simctl boot "$device" 2>/dev/null || true
xcrun simctl bootstatus "$device" -b
trap 'xcrun simctl shutdown "$device" >/dev/null 2>&1 || true' EXIT
xcrun simctl install "$device" "$app"
container=$(xcrun simctl get_app_container "$device" com.openuikit.nibruntimeprobe data)
rm -f "$container/Documents/nibruntime.json" "$container/Documents/nibruntime2.json" "$container/Documents/eidolonnibs.json"
xcrun simctl launch --console-pty "$device" com.openuikit.nibruntimeprobe > "$out/console.log" 2>&1 || true
cp "$container/Documents/nibruntime.json" "$out/nibruntime.json"
cp "$container/Documents/nibruntime2.json" "$out/nibruntime2.json"
cp "$container/Documents/eidolonnibs.json" "$out/eidolonnibs.json"
echo "Measured iOS 26.1 storyboard runtime: $out/nibruntime.json $out/eidolonnibs.json"
