#!/bin/bash
# valgrind_guest.sh -- run a Mach-O guest under valgrind's memcheck.
#
#   scripts/valgrind_guest.sh <guest> [args...]
#   VG_ARGS="--leak-check=full" scripts/valgrind_guest.sh <guest>
#
# WHY THIS EXISTS. machorun's own diagnostics report memory corruption where it
# is DETECTED, which for a heap overflow is the eventual free() -- "double free
# or corruption", "corrupted double-linked list", "malloc_consolidate(): invalid
# chunk size". Those name a victim, never the culprit, and they arrive an
# unbounded distance from the write. memcheck reports the WRITE:
#
#     ==422== Invalid write of size 8
#     ==422==    at 0x4891F6C: memset
#     ==422==    by 0x100000657: ??? (in /out/corrupt)
#     ==422==  Address 0x4b3fde0 is 0 bytes after a block of size 32 alloc'd
#
# Guest frames print as `???` because valgrind cannot read Mach-O symbols. The
# ADDRESS is exact, and machorun places images at fixed bases (the executable at
# 0x100000000, dylibs from 0x200000000 upward -- src/map.c), so `addr - base` is
# an image offset you can hand straight to `otool -tv`, exactly the way
# machorun's own crash reporter prints them.
#
# THE ONE THING THAT MAKES THIS NON-OBVIOUS: valgrind 3.22 does not implement
# ARMv8.3-RCpc, and clang emits `ldapr` for acquire-loads when targeting
# arm64-apple-macos, because every Apple core has it. A guest whose images
# contain LDAPR dies with SIGILL before reaching anything interesting.
#
# WHICH IMAGES CONTAIN IT DECIDES WHETHER THIS SCRIPT IS USABLE, and the first
# answer here was WRONG in the most dangerous direction. It was taken with
# `objdump --macho -d libswiftCore.dylib | grep -c ldapr`, which reported 0 --
# and 0 is exactly what a clean library reports. LLVM's objdump cannot decode
# LDAPR for this Mach-O and emits the raw word instead, so the instrument
# failed silently and its failure was indistinguishable from success. The real
# count is 215. scripts/ldapr_scan.py exists because of that: it reads the
# instruction ENCODING and needs no disassembler, and it agrees with
# `otool -tV` on every image measured.
#
# So, measured properly:
#
#     libswiftCore.dylib (prebuilt, CANNOT be recompiled)   215
#     Apple's iOS-simulator libswiftCore                    323
#     libSystem.B.dylib / libobjc.A.dylib / libquartz        19 / 5 / 2
#
# WHAT THAT MEANS FOR YOU:
#
#   * C and Objective-C guests -- the fixture corpus, objc44 -- work. Their
#     images are all ones we compile, so the rebuild below clears them.
#   * SWIFT GUESTS DO NOT WORK with valgrind 3.22, and no rebuild of ours can
#     fix it: the LDAPR is inside a libswiftCore we did not build. This script
#     detects that and says so rather than rebuilding for two minutes and
#     leaving you to interpret a SIGILL.
#
# The way out for Swift is a valgrind that implements LDAPR (support post-dates
# 3.22) or a libswiftCore built without RCpc, which is possible for ours and
# impossible for Apple's. Neither is done here.
#
# THE BUILD IT PRODUCES IS FOR DEBUGGING AND MUST NOT BE STAGED. It is not the
# code we ship: different instructions, different timing. It lives in a scratch
# directory and is deleted with it.
#
# TWO CAVEATS THAT DECIDE WHETHER YOU CAN BELIEVE A RESULT:
#
#   * valgrind changes heap layout, so a nondeterministic corruption may stop
#     reproducing under it. A guest that passes here has told you NOTHING. Work
#     from the ones that still report.
#   * memcheck sees glibc's malloc, which is what our libSystem forwards to. It
#     does NOT see anything a guest allocates from its own pool, so a Swift
#     metadata-allocator overrun inside libswiftCore's static InitialAllocationPool
#     is invisible to it -- that pool is a static array in __DATA, not a heap
#     block. Absence of a memcheck report is not absence of corruption.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${MACHORUN_IMAGE:-machorun-testbed:24.04}"
VG_ARGS="${VG_ARGS:---quiet}"

GUEST="${1:-}"
[ -n "$GUEST" ] || { sed -n '2,6p' "$0"; exit 64; }
shift

command -v docker >/dev/null 2>&1 || { echo "valgrind_guest: docker not installed" >&2; exit 1; }
[ -e "$GUEST" ] || { echo "valgrind_guest: no such guest: $GUEST" >&2; exit 66; }

GUEST_ABS="$(cd "$(dirname "$GUEST")" && pwd)/$(basename "$GUEST")"
GUEST_DIR="$(dirname "$GUEST_ABS")"

# The tree goes in read-only and is copied to container-local storage: the
# rebuild must not touch the caller's darwin/usr/lib, and high-exec-rate work
# over the macOS bind mount is unreliable anyway (docs/FIXTURES.md).
docker run --rm -i --platform linux/arm64 \
    -v "$ROOT:/src:ro" -v "$GUEST_DIR:/guest:ro" \
    "$IMAGE" bash -s -- "$(basename "$GUEST_ABS")" "$VG_ARGS" "$@" <<'INNER'
set -u
guest="$1"; shift
vgargs="$1"; shift

mkdir -p /local && cp -a /src/. /local/ && cd /local

if ! command -v valgrind >/dev/null 2>&1; then
    echo "== installing valgrind (first run only)"
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq valgrind >/dev/null 2>&1 || {
        echo "valgrind_guest: could not install valgrind (no network?)" >&2; exit 1; }
fi

# -rcpc off, so valgrind can emulate every instruction we emit. See the header.
echo "== rebuilding darwin/ without ARMv8.3-RCpc (debug build, scratch tree)"
sed -i 's|CFLAGS="-target $TARGET|CFLAGS="-target $TARGET -Xclang -target-feature -Xclang -rcpc|' \
    scripts/build_darwin.sh
for s in build_darwin.sh build_objc4.sh build_quartz.sh; do
    [ -f "scripts/$s" ] || continue
    case "$s" in
      build_objc4.sh|build_quartz.sh)
        sed -i 's|-target \$TARGET|-target $TARGET -Xclang -target-feature -Xclang -rcpc|g' "scripts/$s" ;;
    esac
done
sh scripts/build_darwin.sh >/tmp/vgbuild.log 2>&1 || { echo "darwin build failed:"; tail -20 /tmp/vgbuild.log; exit 1; }
[ -f darwin/usr/lib/libobjc.A.dylib ] && bash scripts/build_objc4.sh >>/tmp/vgbuild.log 2>&1
[ -f darwin/usr/lib/libquartz.dylib ] && bash scripts/build_quartz.sh >>/tmp/vgbuild.log 2>&1

# Verified with the ENCODING SCANNER, not a disassembler. The check this
# replaces used `objdump | grep -c ldapr`, which cannot see LDAPR at all and so
# reported success whether or not the rebuild had worked.
echo "== ldapr audit of every image this guest can load"
python3 scripts/ldapr_scan.py darwin/usr/lib/*.dylib darwin/usr/lib/swift/*.dylib 2>/dev/null

ours=$(python3 scripts/ldapr_scan.py --quiet darwin/usr/lib/libSystem.B.dylib \
        darwin/usr/lib/libobjc.A.dylib darwin/usr/lib/libquartz.dylib 2>/dev/null)
if [ "${ours:-1}" != "0" ]; then
    echo "valgrind_guest: our own dylibs still contain $ours LDAPR sites, so the" >&2
    echo "   -rcpc rebuild did not take. Check scripts/build_darwin.sh." >&2
    exit 1
fi

foreign=$(python3 scripts/ldapr_scan.py --quiet darwin/usr/lib/swift/libswiftCore.dylib 2>/dev/null || true)
if [ -n "$foreign" ] && [ "$foreign" != "0" ]; then
    echo
    echo "valgrind_guest: STOPPING. libswiftCore.dylib contains $foreign LDAPR" >&2
    echo "   instructions and we did not build it, so it cannot be rebuilt without" >&2
    echo "   RCpc. valgrind 3.22 does not implement LDAPR, so a guest that loads it" >&2
    echo "   will die with SIGILL somewhere inside the Swift runtime -- which looks" >&2
    echo "   like a crash in your program and is not one." >&2
    echo "   C and Objective-C guests are fine; this is Swift-only." >&2
    echo "   Fixes: a valgrind newer than 3.22, or a libswiftCore built -rcpc." >&2
    exit 2
fi

echo "== valgrind $vgargs machorun $guest"
echo "----------------------------------------------------------------------"
# shellcheck disable=SC2086
valgrind $vgargs /local/build/machorun "/guest/$guest" "$@"
rc=$?
echo "----------------------------------------------------------------------"
echo "guest exit: $rc"
echo "Guest frames print as ???. Subtract the image base to get an offset:"
echo "  executable 0x100000000, dylibs from 0x200000000 (src/map.c), then"
echo "  otool -tv <image> and find the offset."
INNER
