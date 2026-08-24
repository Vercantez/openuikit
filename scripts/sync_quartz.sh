#!/bin/sh
# Vendor the quartz library (portable Quartz 2D + CoreAnimation, QZ* C API)
# into Sources/CQuartz/ in SPM C++ target layout:
#
#   Sources/CQuartz/include/quartz/*.h   public headers (publicHeadersPath)
#   Sources/CQuartz/*.cpp, *.hpp         implementation + internal headers
#   Sources/CQuartz/stb_*.h              third-party single-header deps
#
# Idempotent: rsync --delete keeps the vendored copy an exact mirror of
# upstream, so re-running after upstream changes is safe.
#
# Usage: scripts/sync_quartz.sh [path-to-quartz-checkout]   (default ~/quartz)

set -eu

QUARTZ="${1:-$HOME/quartz}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$REPO/Sources/CQuartz"

if [ ! -f "$QUARTZ/include/quartz/quartz.h" ]; then
    echo "error: quartz checkout not found at $QUARTZ" >&2
    exit 1
fi

mkdir -p "$DEST/include/quartz"

# Public headers (exact mirror).
rsync -a --delete "$QUARTZ/include/quartz/" "$DEST/include/quartz/"

# Implementation: .cpp + internal .hpp at the target root. The filter
# protects include/ and the stb headers from --delete while still removing
# stale .cpp/.hpp files that upstream deleted.
rsync -a --delete \
      --include='*.cpp' --include='*.hpp' --exclude='*' \
      "$QUARTZ/src/" "$DEST/"

# Third-party single-header libraries the implementation includes.
for h in stb_image.h stb_image_write.h stb_truetype.h; do
    rsync -a "$QUARTZ/third_party/$h" "$DEST/$h"
done

echo "synced quartz -> $DEST"
