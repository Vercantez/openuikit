#!/bin/bash
# Isolated iOS 26.1 runtime measurement for the UIInputView family.
set -euo pipefail
cd "$(dirname "$0")/.."
OUTDIR=${1:?usage: inputview_probe_sim.sh /tmp/output}
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP="$OUTDIR/InputViewBlockingProbe.app"
SIM_NAME="OpenUIKit-EditMenu${SIM_DEVICE_SUFFIX:--uikit-blocking-types-editmenu}"
mkdir -p "$APP"
swiftc -O -swift-version 5 -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/inputviewprobe/main.swift -o "$APP/inputviewblockingprobe"
cat > "$APP/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>inputviewblockingprobe</string>
<key>CFBundleIdentifier</key><string>com.openuikit.inputviewblockingprobe</string>
<key>CFBundleName</key><string>InputViewBlockingProbe</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleSupportedPlatforms</key><array><string>iPhoneSimulator</string></array>
<key>MinimumOSVersion</key><string>26.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer></array>
<key>UILaunchScreen</key><dict/>
</dict></plist>
PLIST
UDID=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; n=sys.argv[1]; print(next((d["udid"] for ds in json.load(sys.stdin)["devices"].values() for d in ds if d["name"] == n), ""))' "$SIM_NAME")
if [ -z "$UDID" ]; then
  UDID=$(xcrun simctl create "$SIM_NAME" com.apple.CoreSimulator.SimDeviceType.iPhone-16 com.apple.CoreSimulator.SimRuntime.iOS-26-1)
fi
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.inputviewblockingprobe data)
rm -f "$CONTAINER/Documents/inputview.json"
xcrun simctl launch --console-pty "$UDID" com.openuikit.inputviewblockingprobe
cp "$CONTAINER/Documents/inputview.json" "$OUTDIR/inputview.json"
printf 'Measurement: %s/inputview.json\n' "$OUTDIR"
