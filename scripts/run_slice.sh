#!/bin/bash
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
IMG=swift-macho-spike:noble
docker run --rm -v "$ROOT:/w" -w /w/build/slice -e MACHORUN_ROOT=/w/scratch/mrroot "$IMG" \
    /w/scratch/mrroot/machorun ./slice_main /w/build/slice/boxes_basic_linux.png
