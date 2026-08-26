#!/bin/sh
# Build machorun: the ELF loader, and (on Linux) our Mach-O Darwin userland.
#
#   scripts/build.sh              build everything that can be built here
#   scripts/build.sh loader       just the loader
#   scripts/build.sh darwin       just darwin/usr/lib/*.dylib
#
# The loader is a Linux/aarch64 ELF PIE. PIE is not optional: a non-PIE aarch64
# ELF links at 0x400000, which is inside the guest's __PAGEZERO.
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
        "$ROOT"/src/crash.c \
        "$ROOT"/src/main.c \
        $LDFLAGS -ldl -lpthread -lm
    echo "   -> $BUILD/machorun"
}

case "$WHAT" in
    loader) build_loader ;;
    darwin) sh "$ROOT/scripts/build_darwin.sh" ;;
    all)
        build_loader
        if [ "$(uname -s)" = "Linux" ]; then
            sh "$ROOT/scripts/build_darwin.sh"
        else
            echo "== darwin/: skipped (needs clang -target arm64-apple-macos11 + ld64.lld-18 on Linux)"
        fi
        ;;
    *) echo "usage: build.sh [loader|darwin|all]" >&2; exit 64 ;;
esac
