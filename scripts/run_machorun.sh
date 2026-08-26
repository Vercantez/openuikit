#!/bin/bash
# run_machorun.sh -- run the Linux-built Mach-O artifacts under machorun,
# inside the container. MACHORUN_ROOT points at scratch/mrroot, a copy of
# ~/machorun/darwin (this spike never writes into ~/machorun).
set -uo pipefail
for t in "$@"; do
    echo "---- $t"
    docker run --rm -v "$HOME/swift-macho-linux:/w" -w /w/build/linux \
        -e MACHORUN_ROOT=/w/scratch/mrroot swift-macho-spike:noble \
        /w/scratch/mrroot/machorun "./$t"
    echo "   exit=$?"
done
