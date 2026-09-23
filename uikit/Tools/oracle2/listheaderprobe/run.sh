#!/bin/zsh
# Builds ListHeaderProbe.app and records it on a throwaway iPhone 16 / iOS 26.1
# device into transcript-ios26.1.txt.   zsh run.sh [WORKDIR]
set -eu
HERE=${0:A:h}
WORK=${1:-${TMPDIR:-/tmp}/listheaderprobe}
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
APP=$WORK/ListHeaderProbe.app
rm -rf "$APP"; mkdir -p "$APP"
swiftc -parse-as-library -module-name ListHeaderProbe -target arm64-apple-ios26.1-simulator -sdk "$SDK" \
  "$HERE/main.swift" -o "$APP/ListHeaderProbe"
cp "${HERE:h:h:h}/fixtures/nibsymbol/SymbolView.nib" "$APP/"
cat > "$APP/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>org.openuikit.listheaderprobe</string>
<key>CFBundleExecutable</key><string>ListHeaderProbe</string>
<key>CFBundleName</key><string>ListHeaderProbe</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>UILaunchScreen</key><dict/>
</dict></plist>
EOF
codesign -s - "$APP" 2>/dev/null || true
source "${HERE:h}/sim_lock.zsh"
sim_lock_acquire
DEV=$(xcrun simctl create "iPhone 16-listheaderprobe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; sim_lock_release' EXIT
xcrun simctl boot "$DEV"
xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl install "$DEV" "$APP"
{
  echo "# ListHeaderProbe, iPhone 16 simulator, iOS 26.1 (23B86), simctl launch --console, $(date -u +%F)"
  # twice: rows with only a .listGroupedCell() background, then rows that also
  # set the cell's own backgroundColor (NetNewsWire's FeedCell nib does)
  for bg in 0 1; do
    echo "# CELL_BG=$bg"
    SIMCTL_CHILD_CELL_BG=$bg timeout 60 xcrun simctl launch --console "$DEV" org.openuikit.listheaderprobe 2>&1 | grep -E "^(EV|FACT|DONE)"
    xcrun simctl terminate "$DEV" org.openuikit.listheaderprobe >/dev/null 2>&1 || true
  done
  # ten rows a section: the lower rows run under the home-indicator safe
  # area; their safe-area insets (NetNewsWire's FeedCell pins its labels to
  # the content view's safe-area guide)
  echo "# ROWS=10"
  SIMCTL_CHILD_ROWS=10 timeout 60 xcrun simctl launch --console "$DEV" org.openuikit.listheaderprobe 2>&1 | grep -E "^(FACT safe|DONE)"
} > "$HERE/transcript-ios26.1.txt"
cat "$HERE/transcript-ios26.1.txt"
