#!/bin/bash
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)

# This script READS a guest root it does not build. A copy read long after it was
# made is indistinguishable from a fresh one -- four such roots were found still
# carrying a malloc_type bug fixed upstream weeks earlier. Refuse rather than
# silently test the past. MRROOT_REFRESH=1 to update instead.
"$(dirname "${BASH_SOURCE[0]}")/require_fresh_root.sh" scratch/mrroot || exit 1

IMG=swift-macho-spike:noble
docker run --rm -v "$ROOT:/w" -w /w/build/slice -e MACHORUN_ROOT=/w/scratch/mrroot "$IMG" \
    /w/scratch/mrroot/machorun ./slice_main /w/build/slice/boxes_basic_linux.png
