#!/bin/bash
# Build the local `os` module (full/foundation/os-module/os.swift) as an
# arm64-apple-macos Swift module + object.  Rationale is in that file's header.
# Runs in swift-macho-spike:noble.
set -euo pipefail
W=${W:-/w}
SYS=${SYS:-$W/scratch/sysroot_fe4}
OUT=${OUT:-$W/scratch/fe4_os}
mkdir -p "$OUT"
swiftc -target "${TARGET:-arm64-apple-macos15.0}" -sdk "$SYS" \
    -module-cache-path "$W/scratch/modcache_fe4" \
    -module-name os -wmo -parse-as-library \
    -runtime-compatibility-version none \
    -emit-module -emit-module-path "$OUT/os.swiftmodule" \
    -c -o "$OUT/os.o" \
    "$W/full/foundation/os-module/os.swift"
echo "== os module built:"
ls -l "$OUT/os.swiftmodule" "$OUT/os.o"
