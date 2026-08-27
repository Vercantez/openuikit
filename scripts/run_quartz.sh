#!/bin/bash
# run_quartz.sh -- run the Linux-built Swift drawing program under machorun (in
# Docker) and diff its PNG against the macOS oracle byte-for-byte.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)

# This script READS a guest root it does not build. A copy read long after it was
# made is indistinguishable from a fresh one -- four such roots were found still
# carrying a malloc_type bug fixed upstream weeks earlier. Refuse rather than
# silently test the past. MRROOT_REFRESH=1 to update instead.
"$(dirname "${BASH_SOURCE[0]}")/require_fresh_root.sh" scratch/mrroot || exit 1

IMG=swift-macho-spike:noble
LINUX_PNG="$ROOT/build/linux/quartz_swift_linux.png"
MACOS_PNG="$ROOT/build/macos/quartz_swift_macos.png"

echo "== running quartz_main under machorun =="
docker run --rm -v "$ROOT:/w" -w /w/build/linux -e MACHORUN_ROOT=/w/scratch/mrroot "$IMG" \
    /w/scratch/mrroot/machorun ./quartz_main /w/build/linux/quartz_swift_linux.png
rc=$?
echo "   machorun exit=$rc"
[ "$rc" = 0 ] || exit "$rc"

echo "== byte-for-byte diff vs macOS oracle =="
if [ -f "$MACOS_PNG" ]; then
    shasum -a 256 "$MACOS_PNG" "$LINUX_PNG"
    if cmp "$MACOS_PNG" "$LINUX_PNG"; then
        echo "IDENTICAL -- Swift draws under machorun, byte-identical to native macOS"
    else
        echo "DIFFER"; exit 1
    fi
else
    echo "(no macOS oracle yet; run scripts/build_quartz_macos.sh on the Mac)"
    shasum -a 256 "$LINUX_PNG"
fi
