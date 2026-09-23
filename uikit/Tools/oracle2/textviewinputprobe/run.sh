#!/bin/zsh
# textviewinputprobe — Apple side of TextViewTextInputTests / RxRowsTests.
# Compiles the shared scenarios (Tests/OpenUIKitTests/*Scenario.swift) with
# -D OUK_ORACLE into an iOS 26.1 simulator app, installs it on a throwaway
# iPhone 16, launches it, copies Documents/transcript.txt to
# transcript-ios26.1.txt. Every step has a timeout; the device is deleted.
set -eu
cd "$(dirname "$0")"
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-/tmp/textviewinputprobe}
APP="$OUT/TextViewInputProbe.app"
BID=com.openuikit.textviewinputprobe
rm -rf "$APP"; mkdir -p "$APP"
T=../../../Tests/OpenUIKitTests
xcrun swiftc -swift-version 5 -D OUK_ORACLE -target arm64-apple-ios26.1-simulator -sdk "$SDK" \
  main.swift $T/TextViewTextInputScenario.swift $T/RxRowsScenario.swift -o "$APP/textviewinputprobe"
cat > "$APP/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>textviewinputprobe</string>
<key>CFBundleIdentifier</key><string>$BID</string>
<key>CFBundleName</key><string>TextViewInputProbe</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleSupportedPlatforms</key><array><string>iPhoneSimulator</string></array>
<key>MinimumOSVersion</key><string>26.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer></array>
<key>UILaunchScreen</key><dict/>
</dict></plist>
PLIST
# Serialize simulator work across agents (same lock protocol as
# scripts/conformance_probe_sim.sh): mkdir lock + pid, stale pids reclaimed.
SIM_LOCK=/tmp/conformance_sim.lock
while ! mkdir "$SIM_LOCK" 2>/dev/null; do
  holder=$(cat "$SIM_LOCK/pid" 2>/dev/null || true)
  if [[ -n "$holder" ]] && ! kill -0 "$holder" 2>/dev/null; then rm -rf "$SIM_LOCK"; continue; fi
  echo "textviewinputprobe: waiting for $SIM_LOCK (pid ${holder:-?})" >&2
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
DEV=$(xcrun simctl create "iPhone 16-textviewinputprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl install "$DEV" "$APP"
timeout 90 xcrun simctl launch --console-pty "$DEV" "$BID" > "$OUT/console.txt" 2>&1 || true
CONTAINER=$(xcrun simctl get_app_container "$DEV" "$BID" data)
cp "$CONTAINER/Documents/transcript.txt" transcript-ios26.1.txt
echo "## crashes (one launch each)" >> transcript-ios26.1.txt
for c in setEnabled7 setEnabled-1 isEnabled7 isEnabled-1; do
  timeout 60 xcrun simctl launch --console-pty "$DEV" "$BID" "--crash=$c" > "$OUT/crash-$c.txt" 2>&1 || true
  R=$(grep -m1 -E "Terminating app|NO CRASH" "$OUT/crash-$c.txt" | sed -E 's/0x[0-9a-f]+/0x…/g' || true)
  echo "crash $c: ${R:-no output}" >> transcript-ios26.1.txt
done
xcrun simctl shutdown "$DEV" >/dev/null 2>&1 || true
cat transcript-ios26.1.txt
