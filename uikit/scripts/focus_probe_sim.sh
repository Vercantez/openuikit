#!/bin/bash
# Firefox Focus first browser screen, upstream a2832521, Apple UIKit oracle.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:?usage: focus_probe_sim.sh OUT [CORPUS] [WORK]}
CORPUS=${2:-$HOME/openuikit/scratch/ladder-corpus/focus-ios}
WORK=${3:-/tmp/focus-golden-oracle}
: "${SIM_DEVICE_SUFFIX:?set a private SIM_DEVICE_SUFFIX}"
mkdir -p "$WORK" "$OUT"
WORK=$(cd "$WORK" && pwd -P)
OUT=$(cd "$OUT" && pwd -P)
python3 Tools/focusoracle/prepare.py "$CORPUS" "$WORK"
BUILD=(-project "$WORK/focus-ios/Blockzilla.xcodeproj" -scheme Focus -configuration FocusDebug
    -sdk iphonesimulator -destination 'generic/platform=iOS Simulator'
    -derivedDataPath "$WORK/DerivedData" CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES)
xcodebuild "${BUILD[@]}" build > "$WORK/xcodebuild.log" 2>&1
xcodebuild "${BUILD[@]}" -showBuildSettings -json > "$WORK/build-settings.json" 2> "$WORK/build-settings.log"
NAME="OpenUIKit-FocusOracle${SIM_DEVICE_SUFFIX}"
RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-26-1
UDID=$(xcrun simctl list devices -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next((v["udid"] for v in d["devices"].get(sys.argv[2],[]) if v["name"]==sys.argv[1]),""))' "$NAME" "$RUNTIME")
if [[ -z "$UDID" ]]; then
    UDID=$(xcrun simctl create "$NAME" com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation "$RUNTIME")
fi
STATE=$(xcrun simctl list devices -j | python3 -c 'import json,sys; print(next(v["state"] for a in json.load(sys.stdin)["devices"].values() for v in a if v["udid"]==sys.argv[1]))' "$UDID")
if [[ "$STATE" != Booted ]]; then xcrun simctl boot "$UDID"; fi
xcrun simctl bootstatus "$UDID" -b > "$WORK/boot.log" 2>&1
xcrun simctl ui "$UDID" appearance light
# Same keyboard onboarding flags as conformance_probe_sim.sh. Only our device.
for KEY in DidShowContinuousPathIntroduction KeyboardDidShowProductivityTutorial DidShowGestureKeyboardIntroduction UIKeyboardDidShowInternationalInfoIntroduction; do
    xcrun simctl spawn "$UDID" defaults write com.apple.keyboard.preferences "$KEY" -bool YES
done
xcrun simctl uninstall "$UDID" org.mozilla.ios.Focus >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$WORK/DerivedData/Build/Products/FocusDebug-iphonesimulator/Firefox Focus.app"
xcrun simctl launch "$UDID" org.mozilla.ios.Focus
CONTAINER=$(xcrun simctl get_app_container "$UDID" org.mozilla.ios.Focus data)
for ((i=0;i<60;i++)); do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
[[ -f "$CONTAINER/Documents/DONE" ]] || { echo 'Capture did not finish' >&2; exit 1; }
# Keep all samples as raw evidence, then validate before selecting the golden.
mkdir -p "$WORK/samples"
cp "$CONTAINER/Documents/"*.png "$CONTAINER/Documents/"*.json "$WORK/samples/"
xcrun simctl io "$UDID" screenshot "$WORK/framebuffer.png" >/dev/null 2>&1
python3 Tools/focusoracle/collect.py "$WORK" "$WORK/samples" "$OUT" "$UDID"
