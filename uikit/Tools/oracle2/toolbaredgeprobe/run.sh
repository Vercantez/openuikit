#!/bin/zsh
# Builds ToolbarEdgeProbe.app, records it on a throwaway iPhone 16 / iOS 26.1
# device into transcript-ios26.1.txt and copies the three window captures to
# OUT (default: WORKDIR/captures).   zsh run.sh [WORKDIR]
set -eu
HERE=${0:A:h}
WORK=${1:-${TMPDIR:-/tmp}/toolbaredgeprobe}
OUT=$WORK/captures
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
APP=$WORK/ToolbarEdgeProbe.app
rm -rf "$APP" "$OUT"; mkdir -p "$APP" "$OUT"
swiftc -parse-as-library -module-name ToolbarEdgeProbe -target arm64-apple-ios26.1-simulator -sdk "$SDK" \
  "$HERE/main.swift" -o "$APP/ToolbarEdgeProbe" 2>/dev/null
cat > "$APP/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>org.openuikit.toolbaredgeprobe</string>
<key>CFBundleExecutable</key><string>ToolbarEdgeProbe</string>
<key>CFBundleName</key><string>ToolbarEdgeProbe</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>UILaunchScreen</key><dict/>
</dict></plist>
EOF
codesign -s - "$APP" 2>/dev/null || true
source "${HERE:h}/sim_lock.zsh"
sim_lock_acquire
DEV=$(xcrun simctl create "iPhone 16-toolbaredgeprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; sim_lock_release' EXIT
xcrun simctl boot "$DEV"
xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl install "$DEV" "$APP"
DATA=$(xcrun simctl get_app_container "$DEV" org.openuikit.toolbaredgeprobe data)
{
  echo "# ToolbarEdgeProbe, iPhone 16 simulator, iOS 26.1 (23B86), simctl launch --console, $(date -u +%F)"
  for b in white gray black white; do
    echo "# BACKDROP=$b"
    SIMCTL_CHILD_BACKDROP=$b timeout 60 xcrun simctl launch --console "$DEV" org.openuikit.toolbaredgeprobe 2>&1 | grep -E "^(FACT|DONE)"
    xcrun simctl terminate "$DEV" org.openuikit.toolbaredgeprobe >/dev/null 2>&1 || true
    # the second white run checks the capture is stable
    if [ -e "$OUT/edge-$b.png" ]; then cp "$DATA/Documents/edge-$b.png" "$OUT/edge-$b-again.png"
    else cp "$DATA/Documents/edge-$b.png" "$OUT/edge-$b.png"; fi
  done
} > "$HERE/transcript-ios26.1.txt"
cat "$HERE/transcript-ios26.1.txt"
ls -la "$OUT"
