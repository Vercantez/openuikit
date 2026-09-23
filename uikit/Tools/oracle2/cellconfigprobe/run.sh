#!/bin/zsh
# Builds CellConfigProbe.app and records it on a throwaway iPhone 16 / iOS 26.1
# device into transcript-ios26.1.txt.   zsh run.sh [WORKDIR]
set -eu
HERE=${0:A:h}
WORK=${1:-${TMPDIR:-/tmp}/cellconfigprobe}
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
APP=$WORK/CellConfigProbe.app
rm -rf "$APP"; mkdir -p "$APP"
swiftc -parse-as-library -module-name CellConfigProbe -target arm64-apple-ios26.1-simulator -sdk "$SDK" \
  "$HERE/main.swift" -o "$APP/CellConfigProbe"
cat > "$APP/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>org.openuikit.cellconfigprobe</string>
<key>CFBundleExecutable</key><string>CellConfigProbe</string>
<key>CFBundleName</key><string>CellConfigProbe</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>UILaunchScreen</key><dict/>
</dict></plist>
EOF
codesign -s - "$APP" 2>/dev/null || true
source "${HERE:h}/sim_lock.zsh"
sim_lock_acquire
DEV=$(xcrun simctl create "iPhone 16-cellconfigprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; sim_lock_release' EXIT
xcrun simctl boot "$DEV"
xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl install "$DEV" "$APP"
{
  echo "# CellConfigProbe, iPhone 16 simulator, iOS 26.1 (23B86), simctl launch --console, $(date -u +%F)"
  timeout 60 xcrun simctl launch --console "$DEV" org.openuikit.cellconfigprobe 2>&1 | grep -E "^(EV|FACT|DONE)"
} > "$HERE/transcript-ios26.1.txt"
cat "$HERE/transcript-ios26.1.txt"
