#!/bin/bash
# Build a real C++ runtime as Darwin Mach-O arm64, on Linux: libc++abi,
# the libc++ sources machorun's 83-symbol stub omits, and libunwind.
#
#   scripts/build_cxxruntime.sh [llvm-source-dir] [outdir]
#
# Task #48. ICU is the first genuine C++ consumer on this stack and needs 31
# symbols machorun's libc++.1.dylib does not have -- 14 C++ ABI
# (__cxa_pure_virtual, __dynamic_cast, the __cxxabiv1 type_info vtables, ...)
# and 17 libc++ std:: (mutex, condition_variable, locale, ios_base,
# istream/ostream). Exceptions then pull in 6 _Unwind_* on top.
#
# NOTHING HERE IS A STUB THAT RETURNS. These are upstream LLVM sources compiled
# for our target, so __cxa_pure_virtual aborts like it should and std::mutex
# really locks. A pure-virtual call that returns would convert a loud, correct
# crash into silent undefined behaviour, and a mutex that does not lock produces
# a library that works until it is used concurrently.
#
# Version MUST match the libc++ headers we compile against: the sysroot carries
# LLVM 18.1 headers (_LIBCPP_VERSION 180100), so the sources are llvmorg-18.1.8.
# A mismatch here is an ABI mismatch, not a compile error.
set -euo pipefail
L=${1:-/priv/llvm}
OUT=${2:-/root/work/cxx}
SDK=${SDK:-$HOME/work/sdk/MacOSX.sdk}
TRIPLE=arm64-apple-macos13.0
SHIM=$OUT/shim

mkdir -p "$OUT"/{obj,uobj,log} "$SHIM"

# ---------------------------------------------------------------------- shims
# libcxxabi's own cxxabi.h uses uint64_t (the 64-bit __cxa_guard ABI) and its
# sources use stderr, without including <stdint.h> or <stdio.h> -- upstream
# relies on its CMake build providing them.
cat > "$SHIM/cxxshim.h" <<'EOF'
#ifndef _CXXSHIM_H
#define _CXXSHIM_H
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#endif
EOF

# locale.cpp only. Same gap ICU's putil.cpp hits.
cat > "$SHIM/langinfo.h" <<'EOF'
#ifndef _CXXSHIM_LANGINFO_H
#define _CXXSHIM_LANGINFO_H
typedef int nl_item;
#define CODESET 14
#ifdef __cplusplus
extern "C" {
#endif
char *nl_langinfo(nl_item);
#ifdef __cplusplus
}
#endif
#endif
EOF

# DO NOT add a div_t/ldiv_t/lldiv_t shim here. The sysroot HAS them, in
# <_stdlib.h> rather than <stdlib.h>. An earlier version of this script
# declared them after grepping the wrong header, which then collided with the
# real ones and broke all 19 libcxxabi files -- a self-inflicted bug fixing a
# symptom that was itself self-inflicted (see below).

# CRITICAL: do NOT put $L/libcxx/include on the include path. Those headers are
# #include_next wrappers meant to sit in front of a platform libc++; ahead of
# our sysroot they break the chain and every TU fails with "unknown type name
# 'ldiv_t'" from inside libc++'s own <stdlib.h>. The sysroot already carries
# LLVM 18.1 libc++ headers at usr/include/c++/v1, which is what to compile
# against. Only libcxx/src (internal implementation headers) belongs here.
CXXABI_FLAGS=(
  -target "$TRIPLE" -isysroot "$SDK" -std=c++20 -Os
  -D_LIBCXXABI_BUILDING_LIBRARY -D_LIBCPP_BUILDING_LIBRARY
  -D_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS
  -I"$L/libcxxabi/include" -I"$L/libcxxabi/src" -I"$L/libcxx/src"
  -include "$SHIM/cxxshim.h"
)
CXX_FLAGS=(
  -target "$TRIPLE" -isysroot "$SDK" -std=c++20 -Os
  -D_LIBCPP_BUILDING_LIBRARY -D_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS
  -DLIBCXX_BUILDING_LIBCXXABI
  -I"$L/libcxxabi/include" -I"$L/libcxx/src"
  -idirafter "$SHIM" -include "$SHIM/cxxshim.h"
)
UNWIND_FLAGS=(
  -target "$TRIPLE" -isysroot "$SDK" -Os
  -D_LIBUNWIND_IS_NATIVE_ONLY
  -I"$L/libunwind/include" -I"$L/libunwind/src"
  -funwind-tables -fno-exceptions -fno-rtti
)

echo "==> libc++abi"
n=0
for f in "$L"/libcxxabi/src/*.cpp; do
  b=$(basename "$f" .cpp)
  clang++ "${CXXABI_FLAGS[@]}" -c "$f" -o "$OUT/obj/abi_$b.o" 2>"$OUT/log/abi_$b.err" && n=$((n+1)) || \
    echo "  FAIL $b: $(grep -m1 error: "$OUT/log/abi_$b.err" | sed 's/.*error: //' | cut -c1-60)"
done
echo "  $n / $(ls "$L"/libcxxabi/src/*.cpp | wc -l)"

echo "==> libc++"
# tz.cpp is EXCLUDED deliberately: it is C++20 <chrono>'s IANA time-zone
# database support and refuses to build without a tzdb path. Nothing on this
# stack uses std::chrono::tzdb -- ICU carries its own tz data -- so excluding
# it is a scope decision, not a workaround. Revisit if std::chrono::zoned_time
# ever appears.
n=0; t=0
for f in "$L"/libcxx/src/*.cpp; do
  b=$(basename "$f" .cpp)
  [ "$b" = "tz" ] && continue
  t=$((t+1))
  clang++ "${CXX_FLAGS[@]}" -c "$f" -o "$OUT/obj/cxx_$b.o" 2>"$OUT/log/cxx_$b.err" && n=$((n+1)) || \
    echo "  FAIL $b: $(grep -m1 error: "$OUT/log/cxx_$b.err" | sed 's/.*error: //' | cut -c1-60)"
done
echo "  $n / $t  (tz.cpp excluded by design)"

echo "==> libunwind"
n=0
for f in "$L"/libunwind/src/libunwind.cpp "$L"/libunwind/src/Unwind-EHABI.cpp \
         "$L"/libunwind/src/UnwindLevel1.c "$L"/libunwind/src/UnwindLevel1-gcc-ext.c \
         "$L"/libunwind/src/Unwind-sjlj.c \
         "$L"/libunwind/src/UnwindRegistersRestore.S "$L"/libunwind/src/UnwindRegistersSave.S; do
  [ -f "$f" ] || continue
  b=$(basename "$f"); b=${b%.*}
  case "$f" in
    *.cpp) CC=(clang++ "${UNWIND_FLAGS[@]}" -std=c++11 -D_LIBUNWIND_DISABLE_VISIBILITY_ANNOTATIONS) ;;
    *)     CC=(clang   "${UNWIND_FLAGS[@]}") ;;
  esac
  "${CC[@]}" -c "$f" -o "$OUT/uobj/uw_$b.o" 2>"$OUT/log/uw_$b.err" && n=$((n+1)) || \
    echo "  FAIL $b: $(grep -m1 error: "$OUT/log/uw_$b.err" | sed 's/.*error: //' | cut -c1-60)"
done
echo "  $n objects"

llvm-ar-18 rcs "$OUT/libc++abi_full.a" "$OUT/obj"/*.o
llvm-ar-18 rcs "$OUT/libunwind.a"      "$OUT/uobj"/*.o
ls -la "$OUT/libc++abi_full.a" "$OUT/libunwind.a"
echo "C++ ABI symbols: $(llvm-nm-18 --defined-only --extern-only "$OUT/libc++abi_full.a" 2>/dev/null | grep -cE ' ___cxa_|_ZTVN10__cxxabiv')"
echo "unwind symbols:  $(llvm-nm-18 --defined-only --extern-only "$OUT/libunwind.a" 2>/dev/null | grep -c '__Unwind_')"
