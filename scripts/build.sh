#!/bin/sh
# Build machorun: the ELF loader, and (on Linux) our Mach-O Darwin userland.
#
#   scripts/build.sh              loader + darwin/*.dylib + the .tbd stubs
#   scripts/build.sh loader       just the loader
#   scripts/build.sh darwin       just darwin/usr/lib/*.dylib
#   scripts/build.sh objc4        just darwin/usr/lib/libobjc.A.dylib
#   scripts/build.sh tbd          just sdk/usr/lib/*.tbd, from what is built
#   scripts/build.sh everything   all of the above, in order
#
# The loader is a Linux/aarch64 ELF PIE. PIE is not optional: a non-PIE aarch64
# ELF links at 0x400000, which is inside the guest's __PAGEZERO.
#
# XCODE IS NO LONGER A BUILD INPUT. objc4 compiles against sdk/ -- our own
# header-only, .tbd-only SDK, assembled by scripts/sdk_stage.sh from Apple's
# open-source releases plus 19 clean-room headers of ours. sdk/PROVENANCE.md is
# the accounting; docs/SDK_SURVEY.md is the measurement that preceded it.
#
# `all` deliberately stops short of objc4: 32 Objective-C++ TUs is about a
# minute, and harness/run_linux.sh invokes this script on every difftest run.
# Ask for it by name, or use `everything`.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD="$ROOT/build"
WHAT="${1:-all}"

CC="${CC:-cc}"
CFLAGS="${CFLAGS:--O1 -g -std=gnu11 -Wall -Wextra -Wno-unused-parameter -fPIE}"
LDFLAGS="${LDFLAGS:--pie -rdynamic}"

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
        "$ROOT"/src/main.c \
        $LDFLAGS -ldl -lpthread -lm
    echo "   -> $BUILD/machorun"
}

# The .tbd stubs are a projection of darwin/usr/lib/*.dylib, so they are
# regenerated whenever those change and never committed. gen_tbd.sh also fails
# loudly if darwin/loader-exports.txt has drifted or if the corpus references a
# symbol no stub exports -- that check is the reason to run it here rather than
# by hand.
build_tbd() {
    bash "$ROOT/scripts/gen_tbd.sh"
}

not_linux() {
    echo "== $1: skipped (needs clang -target arm64-apple-macos11 + ld64.lld-18 on Linux)"
}

case "$WHAT" in
    loader) build_loader ;;
    darwin) sh "$ROOT/scripts/build_darwin.sh" ;;
    objc4)  bash "$ROOT/scripts/build_objc4.sh" ;;
    tbd)    build_tbd ;;
    all)
        build_loader
        if [ "$(uname -s)" = "Linux" ]; then
            sh "$ROOT/scripts/build_darwin.sh"
            build_tbd
        else
            not_linux "darwin/"
        fi
        ;;
    everything)
        build_loader
        if [ "$(uname -s)" = "Linux" ]; then
            sh "$ROOT/scripts/build_darwin.sh"
            bash "$ROOT/scripts/build_objc4.sh"
            build_tbd
        else
            not_linux "darwin/ and objc4"
        fi
        ;;
    *) echo "usage: build.sh [loader|darwin|objc4|tbd|all|everything]" >&2; exit 64 ;;
esac
