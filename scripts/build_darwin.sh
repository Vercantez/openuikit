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
LIBCXX_INC_FOR_UNWIND="${LIBCXX_INC:-/usr/lib/llvm-18/include/c++/v1}"
SDK_FOR_UNWIND="${OBJC4_SDK:-$ROOT/sdk}"

LIBSYSTEM_OBJ=""
for f in libsystem posix mach ctype objcsupport math; do
    $CLANG $CFLAGS -c "$ROOT/darwin/src/$f.c" -o "$OBJ/$f.o"
    LIBSYSTEM_OBJ="$LIBSYSTEM_OBJ $OBJ/$f.o"
done

# ---------------------------------------------------------------- libunwind
#
# LLVM 18.1.8's libunwind, PRISTINE (vendor/libunwind, zero patches), compiled
# INTO libSystem.B.dylib rather than as a separate dylib. That is not a
# shortcut, it is the Darwin arrangement: on macOS libunwind.dylib is a
# sub-library of the libSystem umbrella and libSystem re-exports it, so a guest
# that links -lSystem already expects to find _Unwind_* there. Building it
# separately would need re-export chasing, which the loader does not implement.
#
# It compiles UNPATCHED against machorun's own sdk/ -- the whole file set built
# clean on the first attempt, which is worth stating because it is unusual and
# because it means the compact-unwind reader here is byte-for-byte the one
# Apple's toolchain ships rather than an approximation of it.
#
# THE FOUR EXCLUDED FILES ARE OTHER ARCHITECTURES' UNWINDERS, not gaps:
# Unwind-EHABI (ARM32), Unwind-seh (Windows), Unwind-sjlj (setjmp/longjmp
# unwinding), Unwind-wasm and Unwind_AIXExtras. None can be reached on
# arm64-apple-macos.
#
# NOT -nostdinc, unlike the rest of darwin/src: libunwind is upstream code that
# includes <stdint.h>, <inttypes.h> and <mach-o/compact_unwind_encoding.h>, so
# it needs real headers. sdk/ supplies them, same as build_quartz.sh.
UNWIND_SRC="$ROOT/vendor/libunwind"
UNWIND_CFLAGS="-target $TARGET -isysroot $SDK_FOR_UNWIND -I$UNWIND_SRC/include -I$UNWIND_SRC/src -fPIC -Os -g0 -DNDEBUG -fno-stack-protector"
UNWIND_OBJ=""
if [ -d "$LIBCXX_INC_FOR_UNWIND" ] && [ -f "$SDK_FOR_UNWIND/usr/include/stdio.h" ]; then
    $CLANG $UNWIND_CFLAGS -std=gnu++17 -nostdinc++ -isystem "$LIBCXX_INC_FOR_UNWIND" \
        -fno-exceptions -fno-rtti \
        -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_NONE \
        -c "$UNWIND_SRC/src/libunwind.cpp" -o "$OBJ/unw_libunwind.o"
    for f in UnwindLevel1 UnwindLevel1-gcc-ext; do
        $CLANG $UNWIND_CFLAGS -c "$UNWIND_SRC/src/$f.c" -o "$OBJ/unw_$f.o"
        UNWIND_OBJ="$UNWIND_OBJ $OBJ/unw_$f.o"
    done
    for f in UnwindRegistersRestore UnwindRegistersSave; do
        $CLANG $UNWIND_CFLAGS -c "$UNWIND_SRC/src/$f.S" -o "$OBJ/unw_$f.o"
        UNWIND_OBJ="$UNWIND_OBJ $OBJ/unw_$f.o"
    done
    UNWIND_OBJ="$OBJ/unw_libunwind.o $UNWIND_OBJ"
    echo "   + libunwind (vendor/libunwind, 5 objects, 0 patches)"
else
    echo "   !! no libc++ headers or no sdk/: libSystem.B.dylib will carry NO" >&2
    echo "      unwinder, and any guest that throws will fail by name." >&2
fi

# -undefined dynamic_lookup makes every glibc reference a flat-lookup bind,
# which machorun resolves through dlsym for images out of this tree. It is also
# how libunwind's two dyld imports -- _dyld_find_unwind_sections and
# _dyld_register_func_for_remove_image, both in src/unwind.c -- reach the
# loader without a bootstrap cycle through the .tbd files.
$LD64 -dylib -arch arm64 -platform_version macos 11.0 11.0 \
      -install_name /usr/lib/libSystem.B.dylib \
      -undefined dynamic_lookup \
      -o "$OUT/libSystem.B.dylib" $LIBSYSTEM_OBJ $UNWIND_OBJ

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
