#!/bin/bash
# Build ~/quartz as a Mach-O /usr/lib/libquartz.dylib -- on Linux.
#
# The same experiment as scripts/build_objc4.sh, run on a different subject.
# objc4 is Apple's own Mach-O source and needed 4 patches; quartz was written
# portable, with no Apple dependency, so the prediction was "very few". The
# measured answer is in patches-quartz/ and in docs/QUARTZ_MACHO.md.
#
#   SOURCES    vendor/quartz -- a PRISTINE copy of ~/quartz's include/, src/ and
#              third_party/, staged by scripts/vendor_quartz.sh, checksummed in
#              vendor/quartz/CHECKSUMS.sha256. Patches from patches-quartz/ are
#              applied to a COPY at build/quartz-macho-src, so the vendored tree
#              stays byte-identical to upstream and `how many patches` stays a
#              number you can count rather than a diff you have to read.
#
#   SDK        sdk/ -- ours. No Xcode, no Apple headers.
#
#   C++        quartz is C++17. sdk/ has no usr/include/c++/v1 on purpose
#              (docs/SDK_SURVEY.md §2.5), so the headers are stock LLVM 18's,
#              with the same three -D flags scripts/build_objc4.sh carries and
#              for the same measured reasons -- read that script's header, it is
#              the authority on why each one is there.
#
#   -fno-exceptions -fno-rtti
#              NOT a performance choice and NOT copied from objc4 out of habit.
#              machorun has no unwinder over Apple's compact __TEXT,__unwind_info
#              (docs/UNIMPLEMENTED.md#unwind-compact, the #2 ranked blocker), so
#              an exception thrown in a guest cannot be delivered -- it is the
#              same wall that fails tests/objc44/038 and /044. Measured on this
#              tree: building quartz WITH exceptions leaves 10 further undefined
#              symbols (std::logic_error/length_error/out_of_range/
#              bad_array_new_length ctors, dtors, vtables and typeinfos, plus
#              __cxa_free_exception) that only libc++abi defines, and every one
#              of them is reachable only from a throw that could not be caught
#              anyway. quartz itself contains no `throw`, `try` or `catch`
#              (grep says so); the throw sites are libc++'s own bounds and
#              allocation checks. With -fno-exceptions those become
#              _LIBCPP_VERBOSE_ABORT, i.e. a loud abort. Loud abort over silent
#              stub, which is the house rule.
#
#              THE MACOS ORACLE IS BUILT WITH THE SAME TWO FLAGS
#              (tests/build_fixtures.sh), so the pixel comparison is not
#              secretly comparing two different C++ dialects.
#
#   -Os -g0    matches build_objc4.sh. NOT -ffast-math, NOT -ffp-contract=off:
#              the floating point mode has to be clang's default on both sides
#              or the pixel diff measures the flags instead of the loader.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SDK="${QUARTZ_SDK:-${OBJC4_SDK:-$ROOT/sdk}}"
LIBCXX_INC="${LIBCXX_INC:-/usr/lib/llvm-18/include/c++/v1}"
VENDOR="$ROOT/vendor/quartz"
SRC="$ROOT/build/quartz-macho-src"
OBJ="$ROOT/build/quartz-macho-obj"
OUT="$ROOT/darwin/usr/lib"
TARGET="${DARWIN_TARGET:-arm64-apple-macos11}"

CLANG="${DARWIN_CLANG:-clang}"
LD64="${LD64:-ld64.lld-18}"
command -v "$LD64" >/dev/null 2>&1 || {
    if command -v ld64.lld >/dev/null 2>&1; then LD64=ld64.lld; else
        echo "build_quartz: no ld64.lld-18 (apt-get install lld-18)" >&2; exit 1; fi; }

[ -d "$VENDOR/src" ] || {
    echo "build_quartz: no vendor/quartz -- stage it: scripts/vendor_quartz.sh" >&2; exit 1; }
[ -f "$SDK/usr/include/stdio.h" ] || {
    echo "build_quartz: $SDK has no usr/include/stdio.h (scripts/sdk_stage.sh)" >&2; exit 1; }
[ -d "$LIBCXX_INC" ] || {
    echo "build_quartz: no libc++ headers at $LIBCXX_INC" >&2
    echo "              apt-get install libc++-18-dev (harness/Dockerfile has it)." >&2
    exit 1; }

# ---------------------------------------------------------------- source copy
rm -rf "$SRC"
mkdir -p "$SRC"
cp -R "$VENDOR/include" "$VENDOR/src" "$VENDOR/third_party" "$SRC/"

shopt -s nullglob
PATCHES=("$ROOT/patches-quartz"/*.patch)
shopt -u nullglob
for p in "${PATCHES[@]}"; do
    echo "== patch: $(basename "$p")"
    patch -p1 -d "$SRC" --no-backup-if-mismatch < "$p" >/dev/null
done
echo "== patches applied: ${#PATCHES[@]}"

mkdir -p "$OBJ" "$OUT"

# ---------------------------------------------------------------------- flags
INC="-I$SRC/include -I$SRC/src -I$SRC/third_party"
WARN="-Wall -Wextra -Wno-unused-parameter -Wno-unused-function"
COMMON="-target $TARGET -isysroot $SDK -fPIC -Os -g0 -DNDEBUG"
CXXLIB="-nostdinc++ -isystem $LIBCXX_INC -D__STDC_WANT_LIB_EXT1__=0
        -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_NONE
        -D_LIBCPP_VERBOSE_ABORT(...)=__builtin_trap()"
CXXFLAGS="-std=gnu++17 -fno-exceptions -fno-rtti $COMMON $INC $WARN $CXXLIB"

# ---------------------------------------------------------------------- build
OBJS=()
fail=0
echo "== compiling (target $TARGET, sysroot $SDK)"
for f in "$SRC"/src/*.cpp; do
    o="$OBJ/$(basename "$f" .cpp).o"
    if $CLANG $CXXFLAGS -c "$f" -o "$o" 2> "$o.log"; then
        OBJS+=("$o")
        [ -s "$o.log" ] && echo "   warn $(basename "$f")"
    else
        echo "!! FAIL $(basename "$f")"
        sed -n '1,25p' "$o.log"
        fail=$((fail+1))
    fi
done
echo "== compiled ${#OBJS[@]} objects, $fail failures"
[ "$fail" = 0 ] || { echo "build_quartz: compile stage failed"; exit 1; }

# ----------------------------------------------------------------------- link
# libquartz DECLARES its dependencies, where libSystem and libobjc get away with
# bare -undefined dynamic_lookup. That is not tidiness, it is a bug this build
# already hit: machorun's flat lookup searches LOADED IMAGES, and a dylib nobody
# has a LC_LOAD_DYLIB on never gets loaded. Linked with dynamic_lookup alone,
# libquartz.dylib carries no reference to libc++.1.dylib, so tests/bin/15_quartz
# -- which depends on libquartz and libSystem and nothing else -- died with
#     machorun: undefined symbol '__ZNSt3__112basic_string...6assignEPKc'
#       wanted by: darwin/usr/lib/libquartz.dylib
# even though our libc++.1.dylib exports it. On macOS the same library gets the
# dependency for free because clang++ passes -lc++; here it has to be asked for.
#
# Linking against the DYLIBS rather than sdk/usr/lib/*.tbd is deliberate too:
# the .tbd files are a projection of these same dylibs generated afterwards
# (scripts/gen_tbd.sh), so depending on them here would be a build-order cycle
# and would let a stale .tbd promise a symbol nothing defines.
#
# -undefined dynamic_lookup stays for exactly one symbol -- dyld_stub_binder,
# which the LOADER defines and no dylib does.
DEPS=()
for d in libc++.1 libSystem.B; do
    if [ -f "$OUT/$d.dylib" ]; then DEPS+=("$OUT/$d.dylib"); else
        echo "build_quartz: no $OUT/$d.dylib -- run scripts/build.sh darwin first" >&2
        exit 1
    fi
done

echo "== linking $OUT/libquartz.dylib"
# -syslibroot so ld64 can resolve an install name found INSIDE a dylib on this
# link line. libc++.1.dylib now re-exports /usr/lib/libc++abi.dylib, and without
# the mapping ld64 says "unable to locate re-export with install name" even
# though the file is right there next to it.
$LD64 -dylib -arch arm64 -platform_version macos 11.0 11.0 \
      -syslibroot "$ROOT/darwin" \
      -install_name /usr/lib/libquartz.dylib \
      -undefined dynamic_lookup \
      -o "$OUT/libquartz.dylib" "${OBJS[@]}" "${DEPS[@]}" 2>&1 | sed -n '1,40p'

[ -f "$OUT/libquartz.dylib" ] || { echo "build_quartz: link failed"; exit 1; }
echo "   -> $OUT/libquartz.dylib"
file "$OUT/libquartz.dylib"
