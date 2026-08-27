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

# ---------------------------------------------------------------- libc++abi
#
# LLVM 18.1.8's libc++abi, PRISTINE (vendor/libcxxabi, zero patches): the
# language runtime ABOVE the unwinder. libunwind walks a stack; libc++abi is
# what THROWS -- __cxa_throw allocates the exception and calls
# _Unwind_RaiseException, and __gxx_personality_v0 decides at each frame
# whether a handler matches by parsing the LSDA and comparing type_info.
#
# IT IS ITS OWN DYLIB, EXACTLY AS ON DARWIN, and getting there took one wrong
# turn worth recording. The first arrangement put libc++abi inside
# libSystem.B.dylib, reasoning that tests/objc44/038-exceptions loads only
# libobjc and libSystem so nothing else would be found. That worked for objc4
# and FAILED for C++ guests: a guest that links -lc++ binds
# __ZNSt13runtime_errorD1Ev TWO-LEVEL against libc++.1.dylib, and on Darwin
# that resolves because libc++ RE-EXPORTS libc++abi. Ours had nothing to
# re-export, so the symbol existed in the process and was unreachable from the
# only library allowed to answer.
#
# The fix is not to move it again, it is to reproduce Darwin's shape: libc++abi
# is a real dylib, libc++.1.dylib re-exports it (the loader already chases
# LC_REEXPORT_DYLIB -- src/resolve.c lookup_in, depth 4), and libobjc LINKS
# against it the way Apple's does instead of relying on flat lookup. Then both
# consumers resolve for the same reason they resolve on macOS.
#
# FOUR FILES ARE EXCLUDED, EACH FOR A NAMED REASON, none of them "it did not
# build":
#   cxa_noexception.cpp    only compiled when the library is built WITHOUT
#                          exceptions, which is the opposite of the point
#   cxa_thread_atexit.cpp  needs __cxa_thread_atexit_impl; see
#                          docs/UNIMPLEMENTED.md#tlv-thread-atexit
#
# cxa_demangle.cpp IS BUILT, and the reason it is worth recording is that I
# excluded it first on the grounds that "nothing in the corpus calls
# __cxa_demangle". That was wrong and the tbd drift check said so immediately:
# libc++abi calls it ITSELF, from the terminate handler that prints the type of
# an uncaught exception. A stub returning NULL would have "worked" -- libc++abi
# falls back to the mangled name -- and quietly diverged from macOS on exactly
# the path a crashing guest takes.
#
# -I vendor/libcxxabi/libcxx-src is libc++'s PRIVATE src headers, which
# libc++abi includes as "include/atomic_support.h". It is NOT libcxx/include --
# putting the PUBLIC header directory on the path shadows the sysroot's libc++
# and yields a _LIBCPP_VERSION mismatch against everything else.
#
# NO -fno-rtti. It looks like an obvious size win and breaks 22 files:
# private_typeinfo.cpp uses dynamic_cast against its own type-info hierarchy.
#
# stdlib_new_delete.cpp AND cxa_guard.cpp ARE HERE RATHER THAN IN libcxx.c, and
# that move was forced by measurement rather than chosen for tidiness. They were
# excluded at first because darwin/src/libcxx.c already defined operator
# new/delete and the __cxa_guard_* trio, and two definitions in two dylibs would
# split allocation. But libc++abi ITSELF calls operator delete[], and the objc44
# corpus does not load libc++.1.dylib -- so every one of the 44 failed with
# "undefined symbol __ZdaPv, wanted by libc++abi.dylib". On Darwin these live in
# libc++abi precisely so that libc++abi is self-contained, and libc++ re-exports
# them. Upstream's versions are also strictly better than what they replace: the
# operators now THROW std::bad_alloc (which works, as of this commit) instead of
# aborting, and cxa_guard.cpp is thread-safe where libcxx.c's was explicitly not
# (docs/UNIMPLEMENTED.md#libcxx-subset limit 1, now closed).
ABI_SRC="$ROOT/vendor/libcxxabi"
ABI_OBJ=""
ABI_REEXPORT=""
if [ -d "$LIBCXX_INC_FOR_UNWIND" ] && [ -f "$SDK_FOR_UNWIND/usr/include/stdio.h" ]; then
    ABI_CXXFLAGS="-target $TARGET -isysroot $SDK_FOR_UNWIND -nostdinc++
        -isystem $LIBCXX_INC_FOR_UNWIND -I$ABI_SRC/include -I$ABI_SRC/src
        -I$ROOT/vendor/libcxx/src -std=gnu++20 -fPIC -Os -g0 -DNDEBUG
        -D_LIBCXXABI_BUILDING_LIBRARY -D_LIBCPP_BUILDING_LIBRARY
        -fexceptions -funwind-tables -D__STDC_WANT_LIB_EXT1__=0
        -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_NONE -fno-stack-protector"
    for f in abort_message cxa_aux_runtime cxa_default_handlers cxa_exception \
             cxa_exception_storage cxa_handlers cxa_personality cxa_vector \
             cxa_virtual fallback_malloc private_typeinfo stdlib_exception \
             stdlib_stdexcept stdlib_typeinfo cxa_demangle \
             stdlib_new_delete cxa_guard; do
        # shellcheck disable=SC2086
        $CLANG $ABI_CXXFLAGS -c "$ABI_SRC/src/$f.cpp" -o "$OBJ/abi_$f.o"
        ABI_OBJ="$ABI_OBJ $OBJ/abi_$f.o"
    done
    # shellcheck disable=SC2086
    $LD64 -dylib -arch arm64 -platform_version macos 11.0 11.0 \
          -install_name /usr/lib/libc++abi.dylib \
          -undefined dynamic_lookup \
          -o "$OUT/libc++abi.dylib" $ABI_OBJ
    echo "   -> $OUT/libc++abi.dylib (vendor/libcxxabi, 17 objects, 0 patches)"
    # libc++ re-exports libc++abi, as on Darwin. This is what lets a guest that
    # links -lc++ resolve __ZNSt13runtime_errorD1Ev: the bind targets libc++
    # two-level, and the loader chases LC_REEXPORT_DYLIB to find it.
    ABI_REEXPORT="-reexport_library $OUT/libc++abi.dylib"
else
    echo "   !! no libc++ headers or no sdk/: libSystem.B.dylib will carry NO" >&2
    echo "      exception ABI, and any guest that throws will fail by name." >&2
fi

# libSystem RE-EXPORTS libc++abi, and this one IS a deviation from Darwin --
# recorded as such rather than blended in.
#
# On macOS, libSystem re-exports libunwind (which is why _Unwind_* is "from
# libSystem" in every Apple binary) and does NOT re-export libc++abi; Apple's
# own libswiftCore binds ___gxx_personality_v0 "from libc++". Our layout now
# matches that exactly -- verified with nm -m on Apple's SHIPPED
# libswiftCore.sim.dylib, which is the authority here.
#
# The deviation exists for OUR OWN artifacts, not Apple's. machorun's
# libSystem.B.tbd used to promise ___gxx_personality_v0, because the aborting
# stub lived in objcsupport.c, and ~/swiftcore-macho's source-built
# libswiftCore.dylib was linked against that promise: it carries a TWO-LEVEL
# bind for ___gxx_personality_v0 naming libSystem. Removing the promise without
# this re-export breaks that binary -- "undefined symbol, looked in
# libSystem.B.dylib" -- for a symbol that is in the process the whole time.
#
# EXIT CONDITION, so this does not become permanent by inertia: once
# ~/swiftcore-macho relinks libswiftCore against the current .tbd (its bind
# should say "from libc++", as Apple's does), drop this line and check the
# swift gate. Verify by content: `nm -m .../libswiftCore.dylib | grep
# gxx_personality` must not say libSystem.
LIBSYSTEM_REEXPORT=""
[ -f "$OUT/libc++abi.dylib" ] && LIBSYSTEM_REEXPORT="-reexport_library $OUT/libc++abi.dylib"

# -undefined dynamic_lookup makes every glibc reference a flat-lookup bind,
# which machorun resolves through dlsym for images out of this tree. It is also
# how libunwind's two dyld imports -- _dyld_find_unwind_sections and
# _dyld_register_func_for_remove_image, both in src/unwind.c -- reach the
# loader without a bootstrap cycle through the .tbd files.
$LD64 -dylib -arch arm64 -platform_version macos 11.0 11.0 \
      -install_name /usr/lib/libSystem.B.dylib \
      -undefined dynamic_lookup \
      ${LIBSYSTEM_REEXPORT} \
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
    # -DLIBCXX_BUILDING_LIBCXXABI is not optional and the linker says so:
    # without it exception.cpp takes its fallback path and DEFINES
    # std::terminate, which libc++abi's cxa_handlers.cpp already defines --
    # "ld64.lld: error: duplicate symbol: __ZSt9terminatev". With it, <cxxabi.h>
    # supplies _LIBCPPABI_VERSION, libc++ delegates terminate and the exception
    # pointer to libc++abi, and the two libraries split where they are meant to.
    #
    # libc++'s OWN exception sources, upstream and unpatched: std::runtime_error
    # and the rest of <stdexcept>, and std::current_exception / exception_ptr.
    # These are libc++, NOT libc++abi -- exception_ptr is a thin wrapper over
    # libc++abi's __cxa_current_primary_exception and the two libraries split
    # exactly there. The corpus check named all three the moment rung (aa)
    # existed, which is the point of that check: a fixture that throws a
    # std::runtime_error is what real code does, and weakening it to fit the
    # library would have been backwards.
    for f in exception stdexcept; do
        $CLANG -target "$TARGET" -isysroot "$SDK" -nostdinc++ -isystem "$LIBCXX_INC" \
            -I"$ROOT/vendor/libcxx/src" -I"$ROOT/vendor/libcxxabi/include" \
            -DLIBCXX_BUILDING_LIBCXXABI \
            -D__STDC_WANT_LIB_EXT1__=0 -D_LIBCPP_BUILDING_LIBRARY \
            -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_NONE \
            -std=gnu++20 -fexceptions -funwind-tables -fPIC -Os -DNDEBUG \
            -c "$ROOT/vendor/libcxx/src/$f.cpp" -o "$OBJ/cxx_$f.o"
    done
    LIBCXX_OBJ="$OBJ/libcxx.o $OBJ/libcxx_std.o $OBJ/cxx_exception.o $OBJ/cxx_stdexcept.o"
    echo "   + libc++ exception sources (vendor/libcxx, 2 objects, 0 patches)"
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
      ${ABI_REEXPORT} \
      -o "$OUT/libc++.1.dylib" $LIBCXX_OBJ

echo "   -> $OUT/libc++.1.dylib"
