#!/bin/bash
# Firefox Focus URL-bar EDITING state on the iOS 26.1 simulator (iPhone SE
# 3rd gen, 2x): which unsatisfiable constraint UIKit breaks, the resulting
# frames, and a screenshot per state. Same prepared Xcode project as
# focus_probe_sim.sh (unmodified upstream sources); only the observation
# harness differs (Tools/focusoracle/FocusEditOracle.swift).
#   focus_edit_probe_sim.sh OUT [CORPUS] [WORK]
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:?usage: focus_edit_probe_sim.sh OUT [CORPUS] [WORK]}
CORPUS=${2:-$HOME/openuikit/scratch/ladder-corpus/focus-ios}
WORK=${3:-/tmp/focus-edit-oracle}
: "${SIM_DEVICE_SUFFIX:?set a private SIM_DEVICE_SUFFIX}"
mkdir -p "$WORK" "$OUT"
WORK=$(cd "$WORK" && pwd -P)
OUT=$(cd "$OUT" && pwd -P)
python3 Tools/focusoracle/prepare.py "$CORPUS" "$WORK"
cp Tools/focusoracle/FocusEditOracle.swift "$WORK/focus-ios/FocusOracle.swift"
BUILD=(-project "$WORK/focus-ios/Blockzilla.xcodeproj" -scheme Focus -configuration FocusDebug
    -sdk iphonesimulator -destination 'generic/platform=iOS Simulator'
    -derivedDataPath "$WORK/DerivedData" CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES)
xcodebuild "${BUILD[@]}" build > "$WORK/xcodebuild.log" 2>&1 || { tail -30 "$WORK/xcodebuild.log"; exit 1; }
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
for KEY in DidShowContinuousPathIntroduction KeyboardDidShowProductivityTutorial DidShowGestureKeyboardIntroduction UIKeyboardDidShowInternationalInfoIntroduction; do
    xcrun simctl spawn "$UDID" defaults write com.apple.keyboard.preferences "$KEY" -bool YES
done
xcrun simctl uninstall "$UDID" org.mozilla.ios.Focus >/dev/null 2>&1 || true
xcrun simctl install "$UDID" "$WORK/DerivedData/Build/Products/FocusDebug-iphonesimulator/Firefox Focus.app"
CONTAINER=$(xcrun simctl get_app_container "$UDID" org.mozilla.ios.Focus data)
rm -f "$CONTAINER/Documents/"* 2>/dev/null || true
# --console-pty: UIKit's "Unable to simultaneously satisfy constraints" text.
( xcrun simctl launch --console-pty "$UDID" org.mozilla.ios.Focus > "$OUT/console.log" 2>&1 & echo $! > "$WORK/console.pid" )
for ((i=0;i<60;i++)); do [[ -f "$CONTAINER/Documents/DONE" ]] && break; sleep 1; done
kill "$(cat "$WORK/console.pid")" 2>/dev/null || true
xcrun simctl terminate "$UDID" org.mozilla.ios.Focus >/dev/null 2>&1 || true
[[ -f "$CONTAINER/Documents/DONE" ]] || { echo 'Capture did not finish' >&2; exit 1; }
cp "$CONTAINER/Documents/"focus_edit.* "$OUT/"
echo "focus_edit.* and console.log in $OUT"
