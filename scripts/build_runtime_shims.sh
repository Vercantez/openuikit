#!/bin/bash

# build_runtime_shims.sh -- builds the three runtime shims that let machorun
# host the iOS-simulator Swift runtime. The arm64 Docker lane runs INSIDE
# swift-macho-spike:noble. The x86 phase2 lane calls STUBS_ONLY=1 with
# TARGET=x86_64-apple-macos15.0 against scratch/sysroot_fe4-x86_64 so the
# loud-abort stubs are ELF-host Mach-O x86_64, never a copy of arm64 stubs.
#
#   Foundation.stub / CoreFoundation.stub  (fckstub.c)
#       the 8 error/String-bridging symbols libswiftCore imports from those two
#       frameworks, as loud-abort stubs -- never reached on a drawing path.

# This script READS a guest root it does not build. A copy read long after it was
# made is indistinguishable from a fresh one -- four such roots were found still
# carrying a malloc_type bug fixed upstream weeks earlier. Refuse rather than
# silently test the past. MRROOT_REFRESH=1 to update instead.
# STUBS_ONLY=1 skips the arm64 scratch/mrroot freshness pin and the umbrellas
# (build_full.sh rebuilds those from machorun); it still compiles fckstub.c.
if [ "${STUBS_ONLY:-0}" != 1 ]; then
    "$(dirname "${BASH_SOURCE[0]}")/require_fresh_root.sh" scratch/mrroot || exit 1
fi
#
#   libc++.1.dylib UMBRELLA  (cxxpatch.cpp + reexport of machorun's libc++)
#       the 5 libc++ symbols the sim libswiftCore needs that machorun's curated
#       libc++ lacks: __libcpp_verbose_abort, __cxa_demangle, __gxx_personality_v0,
#       thread::hardware_concurrency, operator+(const char*, string).
#
#   libSystem.B.dylib UMBRELLA  (syspatch.c + libsystem_math_compat.c +
#                                reexport of machorun's libSystem)
#       The sim Swift dylib closure plus C99 nan/remquo that CGFloat tgmath uses:
#       compiler-rt 128-bit divide, dispatch_once_f, getsectiondata, malloc_type_*,
#       the strtod_l family, real pthread stack bounds, the reserved-key TLS the
#       Swift runtime claims (key 100), the correct-enum _dyld_lookup_section_info,
#       and dyld shared-cache SPIs stubbed to "no preoptimized data" (the truth).
#
# The umbrellas rename machorun's real dylib to *.real.dylib (a distinct install
# name) and LC_REEXPORT_DYLIB it, because machorun searches a bound image's
# reexport deps but cannot chase per-symbol trie reexports.
set -euo pipefail
ROOT=${ROOT:-${W:-/w}}
SYS=${SYS:-$ROOT/scratch/sysroot}
OUT=${OUT:-$ROOT/build/linux}
TARGET=${TARGET:-arm64-apple-macos11}
case "$TARGET" in
    x86_64-*) ARCH=x86_64 ;;
    *) ARCH=arm64 ;;
esac
MINOS=${MINOS:-11.0}
LINK_SDK_VERSION=${LINK_SDK_VERSION:-$MINOS}
MRLIB=$ROOT/scratch/mrroot/darwin/usr/lib   # source of machorun's real dylibs
LIBCXX_INC=${LIBCXX_INC:-/usr/lib/llvm-18/include/c++/v1}
mkdir -p "$OUT"

CC=(clang-18 -target "$TARGET" -isysroot "$SYS")
LD=(ld64.lld-18 -arch "$ARCH" -platform_version macos "$MINOS" "$LINK_SDK_VERSION" -syslibroot "$SYS")

# ---- Foundation / CoreFoundation stubs
"${CC[@]}" -O1 -c -o "$OUT/fckstub.o" "$ROOT/spike/fckstub.c"
stub_syslib=(-L/usr/lib -lSystem)
if [ "${STUBS_ONLY:-0}" = 1 ]; then
    # x86 FE sysroot vends libSystem.B.tbd (no libSystem.tbd). Same install
    # name as the arm64 recipe; -undefined dynamic_lookup matches this file's
    # umbrella line.
    stub_syslib=(-L/usr/lib -lSystem.B -undefined dynamic_lookup)
fi
"${LD[@]}" -dylib -install_name /System/Library/Frameworks/Foundation.framework/Foundation \
    "${stub_syslib[@]}" -o "$OUT/Foundation.stub.dylib" "$OUT/fckstub.o"
"${LD[@]}" -dylib -install_name /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation \
    "${stub_syslib[@]}" -o "$OUT/CoreFoundation.stub.dylib" "$OUT/fckstub.o"

if [ "${STUBS_ONLY:-0}" = 1 ]; then
    echo "built loud-abort stubs into $OUT (STUBS_ONLY=1, skipped umbrellas):"
    ls -l "$OUT"/Foundation.stub.dylib "$OUT"/CoreFoundation.stub.dylib
    exit 0
fi

# machorun's real dylibs, copied into scratch/real by the macOS driver before
# this runs (Docker cannot reach ~/machorun; the repo mount is all it sees).
REAL_LIBSYSTEM="$ROOT/scratch/real/libSystem.B.dylib"
REAL_LIBCXX="$ROOT/scratch/real/libc++.1.dylib"
[ -f "$REAL_LIBSYSTEM" ] || { echo "need $REAL_LIBSYSTEM -- copy machorun/darwin/usr/lib/libSystem.B.dylib there first"; exit 1; }
[ -f "$REAL_LIBCXX" ]    || { echo "need $REAL_LIBCXX -- copy machorun/darwin/usr/lib/libc++.1.dylib there first"; exit 1; }

# ---- libc++ umbrella
cp "$REAL_LIBCXX" "$OUT/libc++.real.dylib"
llvm-install-name-tool-18 -id /usr/lib/libc++.real.dylib "$OUT/libc++.real.dylib"
"${CC[@]}" -nostdinc++ -isystem "$LIBCXX_INC" -std=c++17 -O1 -fno-exceptions \
    -c -o "$OUT/cxxpatch.o" "$ROOT/spike/cxxpatch.cpp"
"${LD[@]}" -dylib -install_name /usr/lib/libc++.1.dylib \
    -o "$OUT/libc++.1.umbrella.dylib" "$OUT/cxxpatch.o" \
    -L/usr/lib -lSystem -reexport_library "$OUT/libc++.real.dylib"

# ---- libSystem umbrella
cp "$REAL_LIBSYSTEM" "$OUT/libSystem.real.dylib"
llvm-install-name-tool-18 -id /usr/lib/libSystem.real.dylib "$OUT/libSystem.real.dylib"
"${CC[@]}" -O1 -c -o "$OUT/syspatch.o" "$ROOT/spike/syspatch.c"
"${CC[@]}" -O1 -c -o "$OUT/mathpatch.o" \
    "$ROOT/full/shims/libsystem_math_compat.c"
"${LD[@]}" -dylib -install_name /usr/lib/libSystem.B.dylib -undefined dynamic_lookup \
    -o "$OUT/libSystem.B.umbrella.dylib" "$OUT/syspatch.o" "$OUT/mathpatch.o" \
    -reexport_library "$OUT/libSystem.real.dylib"

echo "built shims into $OUT:"
ls -l "$OUT"/*.stub.dylib "$OUT"/libc++.*.dylib "$OUT"/libSystem.*.dylib
