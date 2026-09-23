#!/bin/zsh
# NetNewsWire first-screen golden (the Feeds list), in the most stable state
# reachable without admin rights:
#   * a fresh throwaway iPhone 16 / iOS 26.1 device;
#   * the notification permission already answered "Don't Allow": bbseed.py
#     writes the BulletinBoard section a tap on the alert would record, so no
#     alert covers the list;
#   * the widget .appex stripped (it crash-loops on the simulator);
#   * the default feeds after the first refresh has settled (40 s: a refresh
#     still running pulls the list down under the refresh control). Counts and favicons
#     come from the host network: Tools/compare/nnw_feed_masks.py derives
#     masks for exactly those regions from the golden's own layout.
# LayoutDump.dylib (measurement only, reads the view tree) writes the layout
# and the key window's drawHierarchy PNG -- the convention of every other
# real-app golden (system chrome outside the app is not part of it).
#
#   zsh run.sh <NetNewsWire.app built for the simulator, Debug> <outdir>
# Writes <outdir>/realapp_nnw_feeds_light.{png,layout.json,masks.json}.
# Takes the conformance simulator lock and deletes the device afterwards.
set -eu
HERE=${0:A:h}
SRC=${1:?usage: run.sh <NetNewsWire.app> <outdir>}
OUT=${2:?usage: run.sh <NetNewsWire.app> <outdir>}
mkdir -p "$OUT"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/nnwgolden.XXXXXX")
xcrun --sdk iphonesimulator clang -dynamiclib -fobjc-arc -target arm64-apple-ios26.1-simulator \
  -framework UIKit -framework Foundation "$HERE/LayoutDump.m" -o "$WORK/LayoutDump.dylib"
codesign -s - "$WORK/LayoutDump.dylib"
APP="$WORK/NetNewsWire.app"; cp -R "$SRC" "$APP"
rm -rf "$APP/PlugIns"/*Widget*.appex
BID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")
source "${HERE:h}/sim_lock.zsh"
sim_lock_acquire
DEV=$(xcrun simctl create "iPhone 16-nnw-golden" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; sim_lock_release; rm -rf "$WORK"' EXIT
boot() {
  xcrun simctl boot "$DEV"; xcrun simctl bootstatus "$DEV" -b >/dev/null
  xcrun simctl ui "$DEV" appearance light
  xcrun simctl status_bar "$DEV" override --time 9:41 --batteryState charged --batteryLevel 100 \
    --wifiBars 3 --cellularBars 4 --dataNetwork wifi
}
boot                                  # creates the BulletinBoard store
xcrun simctl shutdown "$DEV"
python3 "$HERE/bbseed.py" "$DEV" "$BID" NetNewsWire 1
boot
xcrun simctl install "$DEV" "$APP"
SIMCTL_CHILD_DYLD_INSERT_LIBRARIES="$WORK/LayoutDump.dylib" \
SIMCTL_CHILD_OPENUIKIT_LAYOUTDUMP_PATH="$OUT/realapp_nnw_feeds_light.layout.json" \
SIMCTL_CHILD_OPENUIKIT_WINDOWSHOT_PATH="$OUT/realapp_nnw_feeds_light.png" \
SIMCTL_CHILD_OPENUIKIT_LAYOUTDUMP_DELAY=40 xcrun simctl launch "$DEV" "$BID" >/dev/null
sleep 41
# The graded golden is the app window's own drawing (LayoutDump.m); the
# device screenshot (with the system status bar) is kept for reference.
xcrun simctl io "$DEV" screenshot "$OUT/realapp_nnw_feeds_light.screen.png" >/dev/null
python3 "${HERE:h:h}/compare/nnw_feed_masks.py" "$OUT/realapp_nnw_feeds_light.layout.json" \
  > "$OUT/realapp_nnw_feeds_light.masks.json"
xcrun simctl terminate "$DEV" "$BID"
echo "NNW_GOLDEN_WRITTEN $OUT"
