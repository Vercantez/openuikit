#!/bin/bash
# Capture the differential baselines ON macOS, against Apple's real Foundation.
#
#   scripts/oracle_macos.sh            # run natively on the Mac, NOT in Docker
#
# Writes tests/baselines/*.txt. These are the oracle: they must come from a real
# macOS run. Regenerating them from the Linux side would make every test
# tautological.
#
# Every test is a real differential: t1_objc.m picks up Apple's
# Foundation/CoreFoundation here via __has_include, while the Swift probes are
# ordinary Foundation API, so the same sources run on both sides.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=tests/baselines
mkdir -p "$OUT"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "macOS $(sw_vers -productVersion) $(uname -m)"

xcrun --sdk macosx clang -fno-objc-arc -Os -target arm64-apple-macos13.0 \
  -framework Foundation -framework CoreFoundation \
  tests/t1_objc.m -o "$TMP/t1_objc"
"$TMP/t1_objc" > "$OUT/t1_objc.txt"

xcrun --sdk macosx swiftc -O -target arm64-apple-macos13.0 \
  tests/t2_bridge.swift -o "$TMP/t2_bridge"
"$TMP/t2_bridge" > "$OUT/t2_bridge.txt"

T22_APP="$TMP/FocusBundleProbe.app"
mkdir -p "$T22_APP"
cp tests/fixtures/t22/Info.plist "$T22_APP/Info.plist"
cp tests/fixtures/t22/launch_probe.txt "$T22_APP/launch_probe.txt"
xcrun --sdk macosx swiftc -O -target arm64-apple-macos13.0 \
  tests/t22_bundle_resource.swift -o "$T22_APP/FocusBundleProbe"
"$T22_APP/FocusBundleProbe" > "$OUT/t22_bundle_resource.txt"

for f in "$OUT"/t1_objc.txt "$OUT"/t2_bridge.txt \
         "$OUT"/t22_bundle_resource.txt; do
  echo "--- $f ---"; cat "$f"
done
