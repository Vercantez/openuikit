#!/bin/bash
# Build the local `os` module (full/foundation/os-module/os.swift) as an
# arm64-apple-macos Swift module + object.  Rationale is in that file's header.
# Runs in swift-macho-spike:noble.
set -euo pipefail
W=${W:-/w}
W=$(cd "$W" && pwd -P)
SYS=${SYS:-$W/scratch/sysroot_fe4}
OUT=${OUT:-$W/scratch/fe4_os}
MC=${MC:-$W/scratch/modcache_fe4}
mkdir -p "$OUT" "$MC"
# One physical spelling: phase2's /w -> $W symlink makes $W/scratch/modcache_fe4
# and /w/scratch/modcache_fe4 the same inode; clang then reports one .pcm as two
# '_DarwinFoundation2' definitions. Prefer a caller-supplied MC (x86 uses
# $W/scratch/modcache_fe4-x86_64).
[ -d "$SYS" ] && SYS=$(realpath -P "$SYS")
OUT=$(realpath -P "$OUT")
MC=$(realpath -P "$MC" 2>/dev/null || readlink -f "$MC")
swiftc -target "${TARGET:-arm64-apple-macos15.0}" -sdk "$SYS" \
    -module-cache-path "$MC" \
    -module-name os -wmo -parse-as-library \
    -runtime-compatibility-version none \
    -emit-module -emit-module-path "$OUT/os.swiftmodule" \
    -c -o "$OUT/os.o" \
    "$W/full/foundation/os-module/os.swift"
echo "== os module built:"
ls -l "$OUT/os.swiftmodule" "$OUT/os.o"
