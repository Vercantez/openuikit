#!/bin/zsh
# Build and run the real-iOS UIPasteboard direct-access oracle.
# Usage: scripts/pasteboard_probe_sim.sh <outdir>
set -e
cd "$(dirname "$0")/.."

OUTDIR=${1:?usage: pasteboard_probe_sim.sh <outdir>}
SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP="$OUTDIR/PasteboardProbe.app"
UDID=${PASTEBOARD_SIMULATOR_UDID:-booted}

mkdir -p "$OUTDIR" "$APP"
xcrun --sdk iphonesimulator swiftc \
  -O -target arm64-apple-ios26.0-simulator -sdk "$SDK" \
  Tools/oracle2/pasteboardprobe/main.swift -o "$APP/pasteboardprobe"
cp Tools/oracle2/PasteboardProbe-Info.plist "$APP/Info.plist"

xcrun simctl bootstatus "$UDID"
xcrun simctl install "$UDID" "$APP"
CONTAINER=$(xcrun simctl get_app_container "$UDID" com.openuikit.pasteboardprobe data)
rm -f "$CONTAINER/Documents/pasteboard.txt"
xcrun simctl launch --console-pty "$UDID" com.openuikit.pasteboardprobe || true
cp "$CONTAINER/Documents/pasteboard.txt" "$OUTDIR/pasteboard.txt"
echo "measurement in $OUTDIR/pasteboard.txt"
