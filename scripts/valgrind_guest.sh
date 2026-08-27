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
# arm64-apple-macos, because every Apple core has it. A stock build therefore
# dies with SIGILL inside libSystem before the guest gets anywhere. Measured:
#
#     libswiftCore.dylib (prebuilt, cannot be recompiled)    0 ldapr sites
#     libSystem.B.dylib                                     14
#     libobjc.A.dylib                                        5
#     libquartz.dylib                                        2
#
# Every one is in something we compile, which is the only reason this works at
# all -- had the prebuilt Swift runtime used it, there would be no route here
# short of patching binaries. So this script rebuilds our dylibs with RCpc
# turned off, into a COPY of the tree, and runs the guest against those.
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

left=$(objdump -d --no-show-raw-insn darwin/usr/lib/libSystem.B.dylib 2>/dev/null | grep -c '\bldapr\b')
echo "== ldapr sites remaining in libSystem: ${left:-unknown} (must be 0)"
if [ "${left:-1}" != "0" ]; then
    echo "valgrind_guest: RCpc is still being emitted; valgrind will SIGILL." >&2
    echo "   The -Xclang -target-feature trick did not take -- check scripts/build_darwin.sh." >&2
    exit 1
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
