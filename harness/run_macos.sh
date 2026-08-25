#!/bin/sh
# run_macos.sh -- compile and run one corpus test against the SYSTEM objc4.
#
# This is the oracle side. It must never link anything we wrote; the whole
# point is that the answers come from Apple's shipping runtime.
#
# Usage: harness/run_macos.sh tests/010-category-basic.m
# Prints the test's stdout on stdout, diagnostics on stderr.
# Exit: 0 ran, 1 compile failed, 2 ran but crashed/non-zero, 3 not macOS.

set -u

REPO=$(cd "$(dirname "$0")/.." && pwd)
TEST=${1:?usage: run_macos.sh <test.m>}
case "$TEST" in /*) ;; *) TEST="$REPO/$TEST" ;; esac

if [ "$(uname -s)" != "Darwin" ]; then
    echo "run_macos.sh: not running on Darwin" >&2
    exit 3
fi

NAME=$(basename "$TEST" .m)
OUT=${OBJC4_BUILD_DIR:-$REPO/build/macos}
mkdir -p "$OUT"

SDK=${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path 2>/dev/null)}
if [ -z "$SDK" ] || [ ! -d "$SDK" ]; then
    echo "run_macos.sh: no macOS SDK found (set SDKROOT)" >&2
    exit 3
fi

# -fno-objc-arc: the corpus calls objc_retain/objc_release/objc_storeWeak
#   directly, because those are the runtime entry points under test. ARC
#   codegen would insert its own and obscure what we are measuring.
# -Wno-objc-root-class: TestRoot is a root class on purpose.
# -Wno-unused-function: testsupport.h's helpers are used a few per test.
# -fobjc-exceptions: @try/@catch/@synchronized tests.
# Optimisation is left OFF and fixed: -O changes ARC/msgSend codegen (e.g.
#   objc_retainAutoreleasedReturnValue elision) and that must not vary between
#   the two sides of the diff.
# -fsigned-char: PINNED ON BOTH SIDES, for the same reason as -O0. Plain `char`
#   is signed in the Darwin arm64 ABI and unsigned in the AArch64 Linux ABI
#   (measured: clang predefines __CHAR_UNSIGNED__=1 for aarch64-linux-gnu and
#   not for arm64-apple-macos). That changes @encode(char) from "c" to "C" in
#   every ivar, property and method type string -- a COMPILER difference that
#   would swamp the runtime differences this corpus exists to find. It is a
#   no-op here (Darwin is already signed) and is stated explicitly so the two
#   runners are visibly the same compile. See docs/ABI_DIVERGENCE.md.
CFLAGS="-isysroot $SDK -target arm64-apple-macos13 -O0 -g0
        -fsigned-char
        -fno-objc-arc -fobjc-exceptions
        -Wno-objc-root-class -Wno-unused-function -Wno-deprecated-declarations
        -I$REPO/tests"

BIN="$OUT/$NAME"

# A test may bring a companion image: tests/<name>.lib.m is built as a shared
# library and linked in. That is the only way to exercise anything that
# crosses an image boundary -- cross-image superclasses, categories and +load
# ordering -- which single-file tests cannot reach.
LIBSRC="$REPO/tests/$NAME.lib.m"
EXTRA=""
if [ -f "$LIBSRC" ]; then
    if ! clang $CFLAGS -dynamiclib "$LIBSRC" -o "$OUT/lib$NAME.dylib" \
             -install_name "@rpath/lib$NAME.dylib" -lobjc \
             2> "$OUT/$NAME.cc.log"; then
        echo "run_macos.sh: companion library compile failed for $NAME" >&2
        cat "$OUT/$NAME.cc.log" >&2
        exit 1
    fi
    EXTRA="-L$OUT -l$NAME -Wl,-rpath,@executable_path"
fi

# A second companion convention: tests/<name>.dlopen.m is built as a shared
# library but NOT linked. Its path is handed to the test in
# OBJC4_TEST_DLOPEN_LIB so the test can dlopen it at run time.
DLSRC="$REPO/tests/$NAME.dlopen.m"
DLLIB=""
if [ -f "$DLSRC" ]; then
    DLLIB="$OUT/lib$NAME-dlopen.dylib"
    if ! clang $CFLAGS -dynamiclib "$DLSRC" -o "$DLLIB" \
             -install_name "@rpath/lib$NAME-dlopen.dylib" -lobjc \
             2> "$OUT/$NAME.cc.log"; then
        echo "run_macos.sh: dlopen library compile failed for $NAME" >&2
        cat "$OUT/$NAME.cc.log" >&2
        exit 1
    fi
fi

if ! clang $CFLAGS "$TEST" -o "$BIN" $EXTRA -lobjc 2> "$OUT/$NAME.cc.log"; then
    echo "run_macos.sh: compile failed for $NAME" >&2
    cat "$OUT/$NAME.cc.log" >&2
    exit 1
fi

# Fixed environment: several objc4 knobs (OBJC_PRINT_*, OBJC_DEBUG_*) would
# inject nondeterministic text, and DYLD_* would change image order.
env -u DYLD_INSERT_LIBRARIES -u DYLD_LIBRARY_PATH -u OBJC_DEBUG_POOL_ALLOCATION \
    OBJC_PRINT_LOAD_METHODS=NO OBJC_PRINT_INITIALIZE_METHODS=NO \
    MallocNanoZone=0 \
    OBJC4_TEST_DLOPEN_LIB="$DLLIB" \
    "$BIN"
rc=$?
if [ $rc -ne 0 ]; then
    echo "run_macos.sh: $NAME exited $rc" >&2
    exit 2
fi
exit 0
