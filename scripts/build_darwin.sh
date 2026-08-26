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
# ctype.c      Apple's rune table (a DATA ABI), setlocale, getopt, time
# math.c       libm -- on Darwin there is no -lm, libSystem re-exports it
LIBSYSTEM_OBJ=""
for f in libsystem posix mach ctype objcsupport math; do
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

# libcxx_std.cpp is the one file in darwin/src that is NOT -nostdinc: it exists
# precisely to emit LLVM 18 libc++'s own out-of-line code from LLVM 18 libc++'s
# own headers (explicit instantiation definitions), so it must see them. Same
# three -D flags as scripts/build_objc4.sh, and for the same measured reasons
# recorded in that script's header; -isysroot sdk/ for the C library beneath.
LIBCXX_INC="${LIBCXX_INC:-/usr/lib/llvm-18/include/c++/v1}"
SDK="${OBJC4_SDK:-$ROOT/sdk}"
if [ -d "$LIBCXX_INC" ] && [ -f "$SDK/usr/include/stdio.h" ]; then
    $CLANG -target "$TARGET" -isysroot "$SDK" -nostdinc++ -isystem "$LIBCXX_INC" \
        -D__STDC_WANT_LIB_EXT1__=0 \
        -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_NONE \
        -D'_LIBCPP_VERBOSE_ABORT(...)=__builtin_trap()' \
        -std=gnu++17 -fno-exceptions -fno-rtti -fPIC -Os -DNDEBUG \
        -c "$ROOT/darwin/src/libcxx_std.cpp" -o "$OBJ/libcxx_std.o"
    LIBCXX_OBJ="$OBJ/libcxx.o $OBJ/libcxx_std.o"
else
    echo "   !! no libc++ headers at $LIBCXX_INC or no SDK at $SDK:" >&2
    echo "      libc++.1.dylib will carry ONLY operator new/delete and the guard" >&2
    echo "      trio, and any C++ guest that touches std::string will fail to" >&2
    echo "      link. apt-get install libc++-18-dev (harness/Dockerfile has it)." >&2
    LIBCXX_OBJ="$OBJ/libcxx.o"
fi

$LD64 -dylib -arch arm64 -platform_version macos 11.0 11.0 \
      -install_name /usr/lib/libc++.1.dylib \
      -undefined dynamic_lookup \
      -o "$OUT/libc++.1.dylib" $LIBCXX_OBJ

echo "   -> $OUT/libc++.1.dylib"
