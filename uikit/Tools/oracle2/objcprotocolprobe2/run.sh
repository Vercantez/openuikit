#!/bin/zsh
# objcprotocolprobe2 — the Apple side of Tests/ObjCProtocols2Tests.
# Builds scenario/OUKProtocols2Scenario.m (the file OpenUIKit's fixture target
# compiles) with main.m into an iOS 26.1 simulator app, installs it on a
# throwaway iPhone 16, launches it, and copies Documents/transcript.txt to
# transcript-ios26.1.txt. Takes /tmp/conformance_sim.lock; the device is
# shut down and deleted.
set -eu
cd "$(dirname "$0")"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-/tmp/objcprotocolprobe2}
APP="$OUT/ProtocolProbe2.app"
BID=com.openuikit.objcprotocolprobe2
rm -rf "$APP"; mkdir -p "$APP"
xcrun --sdk iphonesimulator clang -fobjc-arc -fmodules -Wno-deprecated-declarations \
  -target arm64-apple-ios26.1-simulator -isysroot "$SDK" -Iscenario/include \
  main.m scenario/OUKProtocols2Scenario.m -framework UIKit -framework Foundation -o "$APP/protocolprobe2"
cat > "$APP/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>protocolprobe2</string>
<key>CFBundleIdentifier</key><string>$BID</string>
<key>CFBundleName</key><string>ProtocolProbe2</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleSupportedPlatforms</key><array><string>iPhoneSimulator</string></array>
<key>MinimumOSVersion</key><string>26.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer></array>
<key>UILaunchScreen</key><dict/>
</dict></plist>
PLIST
SIM_LOCK=/tmp/conformance_sim.lock
while ! mkdir "$SIM_LOCK" 2>/dev/null; do
  holder=$(cat "$SIM_LOCK/pid" 2>/dev/null || true)
  if [[ -n "$holder" ]] && ! kill -0 "$holder" 2>/dev/null; then rm -rf "$SIM_LOCK"; continue; fi
  echo "objcprotocolprobe2: waiting for $SIM_LOCK (pid ${holder:-?})" >&2
  sleep 15
done
echo $$ > "$SIM_LOCK/pid"
DEV=""
cleanup() {
  if [[ -n "$DEV" ]]; then
    xcrun simctl shutdown "$DEV" >/dev/null 2>&1 || true
    xcrun simctl delete "$DEV" >/dev/null 2>&1 || true
  fi
  rm -rf "$SIM_LOCK"
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT TERM HUP
DEV=$(xcrun simctl create "iPhone 16-objcprotocolprobe2" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl install "$DEV" "$APP"
timeout 90 xcrun simctl launch --console-pty "$DEV" "$BID" > "$OUT/console.txt" 2>&1 || true
sleep 3
CONTAINER=$(xcrun simctl get_app_container "$DEV" "$BID" data)
cp "$CONTAINER/Documents/transcript.txt" transcript-ios26.1.txt
cat transcript-ios26.1.txt
