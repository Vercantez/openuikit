#!/bin/bash
set -uo pipefail
R="$(cd "$(dirname "$0")" && pwd)"   # this recipe dir (inputs, committed)
G="${EIDOLON_GOLDEN_WORK:?set EIDOLON_GOLDEN_WORK to a scratch dir}"   # outputs
WORK=$G/work/eidolon
xcodebuild \
  -workspace "$WORK/Kiosk.xcworkspace" \
  -scheme Kiosk -configuration Debug -sdk iphonesimulator26.1 \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$G/work/derived" \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  IPHONEOS_DEPLOYMENT_TARGET=12.0 \
  CODE_SIGNING_ALLOWED=NO \
  "$@" build > "$G/logs/xcodebuild.log" 2>&1
rc=$?
echo "xcodebuild exit $rc"
grep -E ' error: |error: |\*\* BUILD' "$G/logs/xcodebuild.log" | sort | uniq -c | sort -rn | head -60
exit $rc
