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
CFLAGS="-isysroot $SDK -target arm64-apple-macos13 -O0 -g0
        -fno-objc-arc -fobjc-exceptions
        -Wno-objc-root-class -Wno-unused-function -Wno-deprecated-declarations
        -I$REPO/tests"

BIN="$OUT/$NAME"
if ! clang $CFLAGS "$TEST" -o "$BIN" -lobjc 2> "$OUT/$NAME.cc.log"; then
    echo "run_macos.sh: compile failed for $NAME" >&2
    cat "$OUT/$NAME.cc.log" >&2
    exit 1
fi

# Fixed environment: several objc4 knobs (OBJC_PRINT_*, OBJC_DEBUG_*) would
# inject nondeterministic text, and DYLD_* would change image order.
env -u DYLD_INSERT_LIBRARIES -u DYLD_LIBRARY_PATH -u OBJC_DEBUG_POOL_ALLOCATION \
    OBJC_PRINT_LOAD_METHODS=NO OBJC_PRINT_INITIALIZE_METHODS=NO \
    MallocNanoZone=0 \
    "$BIN"
rc=$?
if [ $rc -ne 0 ]; then
    echo "run_macos.sh: $NAME exited $rc" >&2
    exit 2
fi
exit 0
