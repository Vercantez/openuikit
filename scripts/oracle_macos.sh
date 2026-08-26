#!/bin/bash
# Capture the differential baselines ON macOS, against Apple's real Foundation.
#
#   scripts/oracle_macos.sh            # run natively on the Mac, NOT in Docker
#
# Writes tests/baselines/*.txt. These are the oracle: they must come from a real
# macOS run. Regenerating them from the Linux side would make every test
# tautological.
#
# Both tests are real differentials: t1_objc.m picks up Apple's
# Foundation/CoreFoundation here via __has_include, and t2_bridge.swift is
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

for f in "$OUT"/t1_objc.txt "$OUT"/t2_bridge.txt; do
  echo "--- $f ---"; cat "$f"
done
