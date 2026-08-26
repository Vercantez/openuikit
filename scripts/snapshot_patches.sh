#!/bin/bash
# Capture the working tree's edits to the pristine swift checkout as a patch.
# The vendored source stays a clean git checkout of swift-6.2.4-RELEASE; this is
# the only record of what we changed.
set -euo pipefail
SRC=${SRC:-$HOME/work/swift}
OUT=${OUT:-$HOME/work/patches}
mkdir -p "$OUT"
cd "$SRC"
git diff > "$OUT/swift-6.2.4-darwin-on-linux.patch"
git --no-pager diff --stat
echo "written: $OUT/swift-6.2.4-darwin-on-linux.patch"
