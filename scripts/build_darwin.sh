#!/bin/sh
# Build our Darwin userland as real Mach-O dylibs -- on Linux.
#
# Verified 2026-08-25 and re-verified by every run of this script: Ubuntu's
# clang emits Mach-O objects for -target arm64-apple-macos11, and Ubuntu's
# ld64.lld-18 links dylibs that macOS's own otool/file/nm accept. Swift's
# BUNDLED lld is patched to refuse macOS linking -- use the distro one.
#
# Output tree mirrors Darwin's, because that is exactly what the loader's
# prefix map expects: /usr/lib/libSystem.B.dylib -> darwin/usr/lib/...
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/darwin/usr/lib"
OBJ="$ROOT/build/darwin-obj"

CLANG="${DARWIN_CLANG:-clang}"
LD64="${LD64:-ld64.lld}"
TARGET="${DARWIN_TARGET:-arm64-apple-macos11}"

command -v "$CLANG" >/dev/null 2>&1 || { echo "build_darwin: no $CLANG" >&2; exit 1; }
command -v "$LD64"  >/dev/null 2>&1 || {
    if command -v ld64.lld-18 >/dev/null 2>&1; then LD64=ld64.lld-18; else
        echo "build_darwin: no ld64.lld (apt-get install lld-18)" >&2; exit 1; fi; }

mkdir -p "$OUT" "$OBJ"

# -nostdinc: there is no macOS SDK here, and glibc's headers are not
# compilable for a Darwin target. darwin/src/dsys.h declares everything.
# -std=gnu11: the errno bracket in dsys.h is a statement expression.
CFLAGS="-target $TARGET -nostdinc -std=gnu11 -fno-stack-protector -fno-builtin -fPIC -O1 -Wall -Wno-unused-function"

echo "== darwin: $CLANG $CFLAGS"

# libsystem.c  process state, the printf family, malloc/str*, exit, pthread
# posix.c      errno / O_* / struct stat translation and the file surface
# mach.c       the Mach APIs, on Linux primitives
LIBSYSTEM_OBJ=""
for f in libsystem posix mach; do
    $CLANG $CFLAGS -c "$ROOT/darwin/src/$f.c" -o "$OBJ/$f.o"
    LIBSYSTEM_OBJ="$LIBSYSTEM_OBJ $OBJ/$f.o"
done

# -undefined dynamic_lookup makes every glibc reference a flat-lookup bind,
# which machorun resolves through dlsym for images out of this tree.
$LD64 -dylib -arch arm64 -platform_version macos 11.0 11.0 \
      -install_name /usr/lib/libSystem.B.dylib \
      -undefined dynamic_lookup \
      -o "$OUT/libSystem.B.dylib" $LIBSYSTEM_OBJ

echo "   -> $OUT/libSystem.B.dylib"

$CLANG $CFLAGS -c "$ROOT/darwin/src/libcxx.c" -o "$OBJ/libcxx.o"
$LD64 -dylib -arch arm64 -platform_version macos 11.0 11.0 \
      -install_name /usr/lib/libc++.1.dylib \
      -undefined dynamic_lookup \
      -o "$OUT/libc++.1.dylib" "$OBJ/libcxx.o"

echo "   -> $OUT/libc++.1.dylib"
