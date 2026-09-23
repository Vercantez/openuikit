#!/bin/zsh
# Real NetNewsWire (Xcode Debug simulator build, widget stripped, "Don't
# Allow" seeded) with SplitFacts.dylib injected (measurement only); prints the
# SPLITFACT lines. Throwaway iPhone 16 / iOS 26.1 device under the sim lock.
#   zsh splitfacts.sh <NetNewsWire.app>
set -u
HERE=${0:A:h}
SRC=${1:?usage: splitfacts.sh <NetNewsWire.app>}
WORK=$(mktemp -d "${TMPDIR:-/tmp}/splitfacts.XXXXXX")
xcrun --sdk iphonesimulator clang -dynamiclib -fobjc-arc -target arm64-apple-ios26.1-simulator \
  -framework UIKit -framework Foundation "$HERE/SplitFacts.m" -o "$WORK/SplitFacts.dylib"
codesign -s - "$WORK/SplitFacts.dylib"
APP="$WORK/NetNewsWire.app"; cp -R "$SRC" "$APP"; rm -rf "$APP/PlugIns"/*Widget*.appex
BID=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$APP/Info.plist")
source "${HERE:h}/sim_lock.zsh"
sim_lock_acquire
DEV=$(xcrun simctl create "iPhone 16-nnw-split" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; sim_lock_release; rm -rf "$WORK"' EXIT
xcrun simctl boot "$DEV"; xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl shutdown "$DEV"
python3 "$HERE/bbseed.py" "$DEV" "$BID" NetNewsWire 1 >/dev/null
xcrun simctl boot "$DEV"; xcrun simctl bootstatus "$DEV" -b >/dev/null
xcrun simctl install "$DEV" "$APP"
SIMCTL_CHILD_DYLD_INSERT_LIBRARIES="$WORK/SplitFacts.dylib" SIMCTL_CHILD_OPENUIKIT_SPLITFACTS=1 \
SIMCTL_CHILD_OPENUIKIT_SPLITFACTS_DELAY=10 \
  timeout 20 xcrun simctl launch --console-pty "$DEV" "$BID" 2>&1 | grep SPLITFACT
