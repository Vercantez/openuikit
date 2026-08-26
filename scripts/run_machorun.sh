#!/bin/bash
# run_machorun.sh -- run the Linux-built Mach-O artifacts under machorun.
#
# scratch/mrroot is a COPY of ~/machorun/darwin plus ~/machorun/build/machorun:
# this repository reads ~/machorun and never writes into it. MACHORUN_ROOT
# points the loader at the copy.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
MACHORUN=${MACHORUN:-$HOME/machorun}
MRROOT="$ROOT/scratch/mrroot"

[ -x "$MACHORUN/build/machorun" ] || { echo "no $MACHORUN/build/machorun -- build it there first" >&2; exit 1; }
rm -rf "$MRROOT"; mkdir -p "$MRROOT/darwin/usr/lib"
cp "$MACHORUN"/darwin/usr/lib/*.dylib "$MRROOT/darwin/usr/lib/"
cp "$MACHORUN/build/machorun" "$MRROOT/machorun"

for t in "$@"; do
    echo "---- $t"
    docker run --rm -v "$ROOT:/w" -w /w/build/linux \
        -e MACHORUN_ROOT=/w/scratch/mrroot swift-macho-spike:noble \
        /w/scratch/mrroot/machorun "./$t"
    echo "   exit=$?"
done
