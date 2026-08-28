#!/bin/bash
# run_resolution_oracle.sh -- build the fixture into a simulator .app, run it on
# one device per scale/idiom, and collect the results.
#
#     ./run_resolution_oracle.sh <fixture-dir> <fresh-out-dir>
#
# The fixture comes from `build_fixture.py`.  Devices are chosen to cover the
# axes the vehicle CAN express:
#
#     iPhone SE (3rd generation)   scale 2, idiom phone
#     iPhone 16 Pro                scale 3, idiom phone
#     iPad Pro 11-inch (M4)        scale 2, idiom pad
#
# 1x is unreachable -- no 1x simulator device exists -- and is recorded rather
# than quietly missing.
set -uo pipefail
FIX=${1:?usage: run_resolution_oracle.sh <fixture-dir> <fresh-out-dir>}
OUT=${2:?usage: run_resolution_oracle.sh <fixture-dir> <fresh-out-dir>}
HERE=$(cd "$(dirname "$0")" && pwd)
BUNDLE_ID=com.openuikit.resolutionprobe

if [ -e "$OUT" ] && [ -n "$(ls -A "$OUT" 2>/dev/null)" ]; then
    echo "REFUSING: $OUT is not empty -- point me at a fresh directory" >&2; exit 2
fi
mkdir -p "$OUT"

SDK=$(xcrun --show-sdk-path --sdk iphonesimulator)
APP="$OUT/ResolutionProbe.app"
mkdir -p "$APP"

echo "== compiling the fixture catalogs with actool"
actool --compile "$APP" --platform iphonesimulator --minimum-deployment-target 17.0 \
    --target-device iphone --target-device ipad \
    --output-partial-info-plist "$OUT/part.plist" --output-format human-readable-text \
    "$FIX/Fixture.xcassets" "$FIX/CollideA.xcassets" "$FIX/CollideB.xcassets" >/dev/null || {
        echo "actool failed" >&2; exit 3; }
[ -f "$APP/Assets.car" ] || { echo "actool produced no Assets.car" >&2; exit 3; }

cp "$FIX/grid.json" "$APP/grid.json"
cp -R "$FIX/Candidates" "$APP/Candidates"

echo "== building the probe"
xcrun swiftc -O -target arm64-apple-ios17.0-simulator -sdk "$SDK" \
    "$HERE/ResolutionProbe/main.swift" -o "$APP/resolutionprobe" || exit 3

python3 - "$APP/Info.plist" <<'PY'
import plistlib, sys
plistlib.dump({
    "CFBundleExecutable": "resolutionprobe",
    "CFBundleIdentifier": "com.openuikit.resolutionprobe",
    "CFBundleName": "ResolutionProbe",
    "CFBundlePackageType": "APPL",
    "CFBundleShortVersionString": "1.0",
    "CFBundleVersion": "1",
    "CFBundleSupportedPlatforms": ["iPhoneSimulator"],
    "MinimumOSVersion": "17.0",
    "UIDeviceFamily": [1, 2],
    "UILaunchScreen": {},
}, open(sys.argv[1], "wb"))
PY

run_on() {
    local label=$1 udid=$2
    echo "== $label ($udid)"
    if ! xcrun simctl list devices | grep -q "$udid.*Booted"; then
        xcrun simctl boot "$udid" >/dev/null 2>&1
        xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1
    fi
    xcrun simctl install "$udid" "$APP" >/dev/null || { echo "   install failed"; return 1; }
    local c
    c=$(xcrun simctl get_app_container "$udid" $BUNDLE_ID data 2>/dev/null) || {
        echo "   no container"; return 1; }
    rm -f "$c"/Documents/*.json "$c"/Documents/PROBE_FAILED
    xcrun simctl launch --console-pty "$udid" $BUNDLE_ID 2>&1 | sed 's/^/   /'
    if [ -f "$c/Documents/PROBE_FAILED" ]; then
        echo "   PROBE FAILED: $(cat "$c/Documents/PROBE_FAILED")"; return 1
    fi
    # CHECK THE ARTIFACT, NOT THE EXIT STATUS: simctl launch returns 0 for an
    # app that started and did nothing.
    local n
    n=$(ls "$c"/Documents/*.json 2>/dev/null | wc -l | tr -d ' ')
    if [ "$n" = "0" ]; then echo "   no results file written"; return 1; fi
    cp "$c"/Documents/*.json "$OUT"/
    return 0
}

fails=0
run_on "iPhone SE 3rd gen (expect 2x, phone)" 00952FB6-2259-484C-BBF0-2A66FC09D5B4 || fails=$((fails+1))
run_on "iPhone 16 Pro (expect 3x, phone)"     143EDAB8-6580-44DE-84A6-A51B4E7E3A9C || fails=$((fails+1))
run_on "iPad Pro 11-inch M4 (expect 2x, pad)" 926F9B24-9855-4F4C-8894-2D18455347AC || fails=$((fails+1))

echo ""
echo "== collected:"
for f in "$OUT"/resolution_*.json; do
    [ -f "$f" ] || continue
    python3 - "$f" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print("   %-40s scale %s idiom %-6s results %4d undecidable %d"
      % (sys.argv[1].split("/")[-1], d["device_scale"], d["device_idiom"],
         len(d["results"]), len(d["undecidable"])))
PY
done
scales=$(ls "$OUT"/resolution_*.json 2>/dev/null | sed 's/.*resolution_\([0-9]*\)x.*/\1/' | sort -u | tr '\n' ' ')
echo "   device scales covered: ${scales:-none}   (1x is unreachable: no 1x simulator device)"
[ "$fails" -eq 0 ] || { echo "$fails device run(s) failed"; exit 1; }
