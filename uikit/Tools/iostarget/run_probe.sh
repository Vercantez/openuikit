#!/bin/zsh
# run_probe.sh — the iOS-target route, smallest real case, on the Mac host.
# docs/agent_reports/ios-target-route.md.
#
#  1. Curates the iPhoneSimulator SDK (Tools/ingest/ios_target_sdk.py).
#  2. The probe package does NOT build for the macOS triple: its #if !os(iOS)
#     #error and its zero-argument @IBAction are the checks.
#  3. It builds for arm64-apple-ios26.1-simulator against the curated SDK.
#  4. The executable (OpenUIKit as UIKit, no Apple UIKit linked) runs on a
#     throwaway iOS 26.1 simulator; its Objective-C UIView-subclass trace must
#     equal Tools/oracle2/objcsubclassprobe/transcript-ios26.1.txt, which the
#     same .m produced against Apple's UIKit.
# Prints IOS_TARGET_PROBE_VERIFIED.
set -eu
HERE=${0:A:h}
UIKIT=${HERE:h:h}
WORK=${WORK:-${TMPDIR:-/tmp}/iostarget-probe}
mkdir -p "$WORK"
SDK=$(python3 "$UIKIT/Tools/ingest/ios_target_sdk.py" --out "$WORK/sdk")
echo "curated SDK: $SDK"

if swift build --package-path "$HERE/probe" --scratch-path "$WORK/mac" > "$WORK/mac.log" 2>&1; then
    echo "FAIL: the probe built for the macOS triple" >&2; exit 1
fi
grep -q 'IOSTargetProbe must be compiled for an iOS triple' "$WORK/mac.log"
grep -q '@IBAction methods must have 1 argument' "$WORK/mac.log"
echo "macOS triple: rejected (#error os(iOS), @IBAction arity) as expected"

swift build --package-path "$HERE/probe" --scratch-path "$WORK/ios" \
    --triple arm64-apple-ios26.1-simulator --sdk "$SDK" > "$WORK/ios.log" 2>&1 \
    || { tail -30 "$WORK/ios.log"; exit 1; }
EXE=$WORK/ios/arm64-apple-ios-simulator/debug/IOSTargetProbe
otool -l "$EXE" | grep -A3 LC_BUILD_VERSION | grep -q 'platform 7'
if otool -L "$EXE" | grep -q 'UIKit\|SwiftUI\|AppKit'; then
    echo "FAIL: an Apple UI framework is linked" >&2; otool -L "$EXE"; exit 1
fi
echo "iOS triple: built, platform 7, no Apple UIKit/SwiftUI/AppKit linked"
rm -f "$HERE/probe/Package.resolved"

DEV=$(xcrun simctl create "iPhone 16-iostarget-probe" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1' EXIT
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl spawn "$DEV" "$EXE" > "$WORK/probe.txt"
head -1 "$WORK/probe.txt"
grep -qx 'IOS_TARGET_PROBE_OK' "$WORK/probe.txt"
diff <(tail -n +2 "$UIKIT/Tools/oracle2/objcsubclassprobe/transcript-ios26.1.txt") \
     <(sed -e 1d -e '/^IOS_TARGET_PROBE_OK$/d' "$WORK/probe.txt")
echo "IOS_TARGET_PROBE_VERIFIED trace=$(($(wc -l < "$WORK/probe.txt") - 2)) lines identical to iOS 26.1 UIKit"
