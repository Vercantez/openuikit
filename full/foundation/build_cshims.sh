#!/bin/bash
# build_cshims.sh -- swift-foundation's OWN _FoundationCShims, for Darwin.
#
# WHY THIS EXISTS: the module was resolving on its own, and from the wrong
# place.  `-Rmodule-loading` says
#
#   loaded module '_FoundationCShims'; source:
#     '/usr/lib/swift/_FoundationCShims/module.modulemap'
#
# -- the LINUX TOOLCHAIN's copy, inside the container.  Not the sysroot
# (which has no _FoundationCShims at all, and neither does Xcode's macOS SDK)
# and not the branch being ported.  A Darwin cross-compile was silently
# reaching into the host toolchain's Swift resource directory for a C module.
#
# Measured before deciding it mattered: the toolchain's 13 headers are
# BYTE-IDENTICAL to release/6.2.2's, because Swift 6.2.4's Linux Foundation is
# built from this branch.  So nothing is wrong today -- and nothing would have
# told us on the day the two versions diverge, which is the whole hazard.
# CMakeLists.txt says how upstream wires it (`-Xcc -fmodule-map-file=...`), so
# that is what is done here.
#
# It also has to be COMPILED: platform_shims.c, string_shims.c and uuid.c
# define _platform_shims_*, which FoundationEssentials calls.  Headers alone
# would compile and then fail at the link.
set -euo pipefail
W=${W:-/w}
SF=${SF:-$W/scratch/swift-foundation}
SYS=${SYS:-$W/scratch/sysroot_fe4}
OUT=${OUT:-$W/scratch/fe4_cshims}
TARGET=${TARGET:-arm64-apple-macos15.0}
mkdir -p "$OUT"
for c in platform_shims string_shims uuid; do
    clang-18 -target "$TARGET" -isysroot "$SYS" -O2 \
        -I "$SF/Sources/_FoundationCShims/include" \
        -c -o "$OUT/$c.o" "$SF/Sources/_FoundationCShims/$c.c"
done
echo "== _FoundationCShims: $(ls "$OUT"/*.o | wc -l | tr -d ' ') objects"
ls -l "$OUT"
