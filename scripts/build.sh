#!/bin/sh
# Build machorun: the ELF loader, and (on Linux) our Mach-O Darwin userland.
#
#   scripts/build.sh              loader + darwin/*.dylib + the .tbd stubs
#   scripts/build.sh loader       just the loader
#   scripts/build.sh darwin       just darwin/usr/lib/*.dylib
#   scripts/build.sh objc4        just darwin/usr/lib/libobjc.A.dylib
#   scripts/build.sh quartz       just darwin/usr/lib/libquartz.dylib
#   scripts/build.sh tbd          just sdk/usr/lib/*.tbd, from what is built
#   scripts/build.sh everything   all of the above, in order
#
# WHERE THE LOADER ITSELF LINKS, which is load-bearing twice over.
#
# The loader is a Linux/aarch64 ELF linked NON-PIE at MR_LOADER_BASE (1 TiB).
# Both halves of that matter, and both obvious alternatives are wrong:
#
#   * plain non-PIE is wrong. An aarch64 ELF defaults to 0x400000, which is
#     inside the guest's __PAGEZERO reservation [0x10000, 0x100000000).
#   * PIE is also wrong, which is the part that is easy to miss. Linux places a
#     PIE at 2*TASK_SIZE/3 -- 0xaaaa_xxxx_xxxx, ABOVE 2^47 -- and glibc's main
#     arena is brk, which starts just past the image and inherits that address.
#     libswiftCore has the 47-bit isa mask compiled into it, so every class the
#     Swift or ObjC runtime allocates from that heap decodes to an unmapped
#     address. Measured: a guest instantiating 900 generic classes died with
#     SIGSEGV at 0x2aaab6c04ea8, which is a main-arena address with bit 47 cut.
#     src/map.c has the full account; src/main.c re-checks the result at
#     startup, so a build that loses this flag stops instead of corrupting.
#
# 1 TiB clears __PAGEZERO and a 4 GiB executable at 0x100000000 below it, leaves
# the image arena (8 GiB upward, src/map.c) ~1 TiB to grow into before it could
# meet the loader, and leaves brk ~127 TiB before it reaches 2^47. An arena
# probe that did collide is mapped MAP_FIXED_NOREPLACE and steps past it.
#
# --no-as-needed around -lm is not optional either, and the reason is not
# obvious. The loader resolves every _glibc_<name> bind with
# dlsym(RTLD_DEFAULT, name) (src/resolve.c), and RTLD_DEFAULT searches the
# GLOBAL SCOPE -- i.e. only libraries actually loaded into this process. The
# loader's own C code calls nothing in libm, so Ubuntu's default --as-needed
# drops libm.so.6 from DT_NEEDED, the global scope has no libm in it, and the
# first guest that calls sin() dies with
#     machorun: undefined symbol '_glibc_sin'  wanted by libSystem.B.dylib
# Measured 2026-08-26 with tests/bin/15_quartz. Forcing the DT_NEEDED entry is
# what makes libSystem's libm forwarders (darwin/src/math.c) resolvable.
#
# XCODE IS NO LONGER A BUILD INPUT. objc4 compiles against sdk/ -- our own
# header-only, .tbd-only SDK, assembled by scripts/sdk_stage.sh from Apple's
# open-source releases plus 19 clean-room headers of ours. sdk/PROVENANCE.md is
# the accounting; docs/SDK_SURVEY.md is the measurement that preceded it.
#
# `all` deliberately stops short of objc4 AND quartz: 32 Objective-C++ TUs plus
# 37 C++ ones is about two minutes, and harness/run_linux.sh invokes this script
# on every difftest run. Ask for them by name, or use `everything`.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD="$ROOT/build"
WHAT="${1:-all}"

CC="${CC:-cc}"
# Keep this in step with the MR_ISA_LIMIT check in src/main.c: the loader must
# land above the guest's __PAGEZERO and below 2^47, and brk grows up from here.
MR_LOADER_BASE="${MR_LOADER_BASE:-0x10000000000}"
CFLAGS="${CFLAGS:--O1 -g -std=gnu11 -Wall -Wextra -Wno-unused-parameter}"
LDFLAGS="${LDFLAGS:--no-pie -rdynamic -Wl,-Ttext-segment=$MR_LOADER_BASE}"

mkdir -p "$BUILD"

build_loader() {
    echo "== loader: $CC $CFLAGS"
    # shellcheck disable=SC2086
    $CC $CFLAGS -o "$BUILD/machorun" \
        "$ROOT"/src/util.c \
        "$ROOT"/src/image.c \
        "$ROOT"/src/map.c \
        "$ROOT"/src/trie.c \
        "$ROOT"/src/resolve.c \
        "$ROOT"/src/fixups_chained.c \
        "$ROOT"/src/fixups_classic.c \
        "$ROOT"/src/tlv.c \
        "$ROOT"/src/tlv_asm.S \
        "$ROOT"/src/init.c \
        "$ROOT"/src/objc_notify.c \
        "$ROOT"/src/crash.c \
        "$ROOT"/src/unwind.c \
        "$ROOT"/src/main.c \
        $LDFLAGS -ldl -lpthread -Wl,--no-as-needed -lm -Wl,--as-needed
    echo "   -> $BUILD/machorun"
}

# The .tbd stubs are a projection of darwin/usr/lib/*.dylib, so they are
# regenerated whenever those change and never committed. gen_tbd.sh also fails
# loudly if darwin/loader-exports.txt has drifted or if the corpus references a
# symbol no stub exports -- that check is the reason to run it here rather than
# by hand.
build_tbd() {
    # libobjc.A.dylib is not part of `all` (it is a minute of Objective-C++), so
    # on a tree that has never run `build.sh objc4` there is nothing to project
    # a libobjc.tbd from. Say so and carry on rather than failing the build --
    # harness/run_linux.sh calls this script on every difftest run, and a
    # difftest that cannot start because a .tbd is missing helps nobody.
    #
    # libquartz.dylib is in the same position for the same reason (37 C++ TUs),
    # and there is a sharper edge on it: tests/bin/15_quartz imports 34 _QZ*
    # symbols, so gen_tbd.sh's CHECK 3 -- "every symbol the corpus references is
    # exported by some stub" -- would fail hard on a tree where libquartz simply
    # has not been built yet. That is a build-order artefact, not a missing
    # symbol, and it must not present itself as one.
    for d in libobjc.A libquartz; do
        if [ ! -f "$ROOT/darwin/usr/lib/$d.dylib" ]; then
            echo "== tbd: skipped -- darwin/usr/lib/$d.dylib is not built."
            echo "        Build everything with 'scripts/build.sh everything',"
            echo "        or just this one and then 'scripts/build.sh tbd'."
            return 0
        fi
    done
    bash "$ROOT/scripts/gen_tbd.sh"
}

# The Linux half of every ABI we forward across, pinned against REAL glibc
# headers. It is compile-only and costs milliseconds, and it is the only check
# in the tree that can see glibc: everything under darwin/src/ is built
# -nostdinc for arm64-apple-macos, so its assertions about Linux layouts are
# assertions about our own hand-written mirrors. Run here, on the Linux branch,
# because it is meaningless anywhere else -- on macOS `cc` would measure Darwin
# and every assertion would fail for the wrong reason.
build_glibc_abi_check() {
    echo "== glibc ABI: pinning the sizes darwin/src/ mirrors by hand"
    if ! $CC -fsyntax-only "$ROOT/sdk/tests/glibc_abi_probe.c"; then
        echo "!! glibc's ABI has moved under us. That file's header table says" >&2
        echo "   which forwarders depend on each number and what breaks." >&2
        return 1
    fi
}

not_linux() {
    echo "== $1: skipped (needs clang -target arm64-apple-macos11 + ld64.lld-18 on Linux)"
}

case "$WHAT" in
    loader) build_loader ;;
    darwin) sh "$ROOT/scripts/build_darwin.sh" ;;
    objc4)  bash "$ROOT/scripts/build_objc4.sh" ;;
    quartz) bash "$ROOT/scripts/build_quartz.sh" ;;
    tbd)    build_tbd ;;
    all)
        build_loader
        if [ "$(uname -s)" = "Linux" ]; then
            build_glibc_abi_check
            sh "$ROOT/scripts/build_darwin.sh"
            build_tbd
        else
            not_linux "darwin/"
        fi
        ;;
    everything)
        build_loader
        if [ "$(uname -s)" = "Linux" ]; then
            build_glibc_abi_check
            sh "$ROOT/scripts/build_darwin.sh"
            bash "$ROOT/scripts/build_objc4.sh"
            bash "$ROOT/scripts/build_quartz.sh"
            build_tbd
        else
            not_linux "darwin/, objc4 and quartz"
        fi
        ;;
    *) echo "usage: build.sh [loader|darwin|objc4|quartz|tbd|all|everything]" >&2; exit 64 ;;
esac
