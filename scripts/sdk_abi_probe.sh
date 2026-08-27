#!/bin/bash
# sdk_abi_probe.sh -- prove sdk/ agrees with Apple's SDK about the ABI, and
# prove a guest can be built end to end on Linux against sdk/ alone.
#
#   scripts/sdk_abi_probe.sh --record   ON macOS ONLY: rebuild the baseline
#   scripts/sdk_abi_probe.sh            ON LINUX:      build ours and diff
#
# sdk/tests/abi_probe.c prints numbers rather than behaviour -- struct sizes and
# field offsets, errno and O_* values, and the first bytes of the
# _DefaultRuneLocale table our <ctype.h> inlines a lookup into. Two builds of
# the same source must produce byte-identical output:
#
#   macOS   Apple clang, Apple's MacOSX.sdk, run natively         -> the oracle
#   Linux   clang-18, -isysroot sdk/, linked by ld64.lld-18
#           against sdk/usr/lib/*.tbd, run under build/machorun   -> the answer
#
# THE ORACLE RULE, same as everywhere else in this repo: the Linux side never
# writes sdk/tests/abi_probe.expected.txt. A mismatch is a failure to report,
# not a number to update.
#
# This is also the end-to-end proof that the .tbd half of the SDK works: the
# Linux build sees no Apple header and no Apple library, only sdk/.
#
# One driver quirk that will otherwise cost a day (docs/SDK_SURVEY.md §4.4):
# clang's Darwin driver on a Linux host does NOT synthesise -arch or
# -platform_version for ld64.lld, so the link is done as a separate step with
# both spelled out.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC="$ROOT/sdk/tests/abi_probe.c"
EXPECTED="$ROOT/sdk/tests/abi_probe.expected.txt"
TARGET_OS_SRC="$ROOT/sdk/tests/target_os_probe.c"
MATH_DECL_SRC="$ROOT/sdk/tests/math_decl_probe.c"
QOS_SRC="$ROOT/sdk/tests/qos_probe.c"
BUILD="$ROOT/build/abi_probe"
SDK="$ROOT/sdk"

die() { echo "sdk_abi_probe: $*" >&2; exit 1; }
mkdir -p "$BUILD"

# sdk/tests/target_os_probe.c is compile-only: there is no output to diff, it
# either builds or it does not. It lives here rather than in its own script
# because it needs exactly what this file already arranges -- a clang aimed at
# a Darwin target -- and because it makes the same kind of claim: that sdk/
# agrees with Apple's SDK about something a compiler decides.
#
# It is invoked on both sides, and the two sides ask different questions. On
# macOS it compiles against APPLE's SDK, so a value we assert that Apple
# disagrees with fails the build there; the four macros that are corelibs'
# rather than Apple's are passed on the command line, as corelibs passes them.
# On Linux it compiles against sdk/, where the question is whether our own
# header defines them at all -- which is how CoreFoundation found this gap.
target_os_probe() { # target_os_probe <clang> <sysroot> [extra flags...]
    tp_clang="$1"; tp_sysroot="$2"; shift 2
    "$tp_clang" -target arm64-apple-macos11 -isysroot "$tp_sysroot" \
        -Wundef-prefix=TARGET_OS -Werror -fsyntax-only "$@" "$TARGET_OS_SRC" \
        || die "TARGET_OS_* probe failed against $tp_sysroot -- see the header of ${TARGET_OS_SRC#$ROOT/}"
    echo "   TARGET_OS_* probe ok against ${tp_sysroot#$ROOT/}"
}

# sdk/tests/math_decl_probe.c, same shape and same reason: a header can declare
# a name WRONG without declaring anything invalid. math.h generated its float
# forms by pasting a macro parameter against itself, so all 42 were named
# `coscos` rather than `cosf` and the header still compiled clean. The only
# check that finds that is a compile of the real names, which is what this is.
math_decl_probe() { # math_decl_probe <clang> <sysroot>
    md_clang="$1"; md_sysroot="$2"
    "$md_clang" -target arm64-apple-macos11 -isysroot "$md_sysroot" \
        -Werror=implicit-function-declaration -fsyntax-only "$MATH_DECL_SRC" \
        || die "math declaration probe failed against $md_sysroot -- see the header of ${MATH_DECL_SRC#$ROOT/}"
    echo "   math decl probe ok against ${md_sysroot#$ROOT/}"
}

# sdk/tests/qos_probe.c is the ONE probe that runs on the Linux side only, and
# the asymmetry is the point rather than an oversight: pthread/qos_private.h,
# sys/qos_private.h and pthread/priority_private.h are Apple-PRIVATE and absent
# from the macOS SDK, so there is no oracle to compile it against. It
# compensates by checking the private headers against the PUBLIC qos.h they
# extend, by asserting the cross-project invariant between xnu's encoding and
# libpthread's values, and by pinning the constants a porter would otherwise
# invent. See its header for why the mask in particular is dangerous to guess.
qos_probe() { # qos_probe <clang> <sysroot>
    q_clang="$1"; q_sysroot="$2"
    "$q_clang" -target arm64-apple-macos11 -isysroot "$q_sysroot" \
        -Werror -fsyntax-only "$QOS_SRC" \
        || die "QoS private-header probe failed -- see the header of ${QOS_SRC#$ROOT/}"
    echo "   QoS private probe ok against ${q_sysroot#$ROOT/}"
}

if [ "${1:-}" = "--record" ]; then
    [ "$(uname -s)" = "Darwin" ] || die "--record only runs on the macOS oracle"
    command -v xcrun >/dev/null 2>&1 || die "no xcrun"
    APPLE_SDK=$(xcrun --sdk macosx --show-sdk-path) || die "no macOS SDK"
    echo "== oracle: $(xcrun -f clang), $APPLE_SDK"
    # Against Apple's own headers, so this is the differential half: every
    # TARGET_OS_* value sdk/local/TargetConditionals.h asserts has to be a
    # value Apple's header produces too.
    target_os_probe "$(xcrun -f clang)" "$APPLE_SDK" \
        -DTARGET_OS_WASI=0 -DTARGET_OS_ANDROID=0 -DTARGET_OS_BSD=0 -DTARGET_OS_CYGWIN=0
    math_decl_probe "$(xcrun -f clang)" "$APPLE_SDK"
    xcrun clang -target arm64-apple-macos11 -isysroot "$APPLE_SDK" -O1 -Wall \
        -o "$BUILD/abi_probe_macos" "$SRC" || die "oracle build failed"
    ( cd "$BUILD" && LC_ALL=C LANG=C TZ=UTC ./abi_probe_macos ) > "$EXPECTED" \
        || die "oracle run failed"
    echo "   recorded $(wc -l < "$EXPECTED") lines -> ${EXPECTED#$ROOT/}"
    exit 0
fi

[ -f "$EXPECTED" ] || die "no baseline; record it on macOS: scripts/sdk_abi_probe.sh --record"
[ "$(uname -s)" = "Linux" ] || die "the answer side runs on Linux (in harness/Dockerfile's image)"
[ -f "$SDK/usr/lib/libSystem.tbd" ] || die "no $SDK/usr/lib/libSystem.tbd -- run scripts/gen_tbd.sh"
[ -x "$ROOT/build/machorun" ] || die "no loader -- scripts/build.sh loader"

CLANG="${DARWIN_CLANG:-clang}"
LD64="${LD64:-ld64.lld-18}"
command -v "$LD64" >/dev/null 2>&1 || LD64=ld64.lld

echo "== ours: $CLANG -isysroot sdk/ , linked against sdk/usr/lib/*.tbd only"
# No -D here on purpose: sdk/ has to supply every TARGET_OS_* by itself, which
# is precisely what it did not do until CoreFoundation tried to compile.
target_os_probe "$CLANG" "$SDK"
math_decl_probe "$CLANG" "$SDK"
qos_probe "$CLANG" "$SDK"
$CLANG -target arm64-apple-macos11 -isysroot "$SDK" -O1 -Wall \
       -c "$SRC" -o "$BUILD/abi_probe.o" || die "compile against sdk/ failed"

$LD64 -arch arm64 -platform_version macos 11.0 11.0 \
      -syslibroot "$SDK" -L/usr/lib -lSystem \
      -o "$BUILD/abi_probe" "$BUILD/abi_probe.o" || die "link against the .tbd failed"

file "$BUILD/abi_probe" | sed 's/^/   /'

( cd "$BUILD" && LC_ALL=C LANG=C TZ=UTC "$ROOT/build/machorun" ./abi_probe ) \
    > "$BUILD/actual.txt" 2> "$BUILD/actual.stderr"
rc=$?

if [ $rc -ne 0 ]; then
    echo "!! the probe exited $rc under machorun" >&2
    sed 's/^/   /' "$BUILD/actual.stderr" >&2
    exit 1
fi

if diff -u "$EXPECTED" "$BUILD/actual.txt" > "$BUILD/diff.txt"; then
    printf '   %d lines, IDENTICAL to the macOS oracle\n' "$(wc -l < "$EXPECTED")"
    echo "   sdk/ and Apple's SDK agree on every size, offset and constant probed,"
    echo "   and a guest built entirely on Linux against sdk/ runs correctly."
    exit 0
fi

echo "!! sdk/ disagrees with Apple's SDK about the ABI:" >&2
sed 's/^/   /' "$BUILD/diff.txt" >&2
echo >&2
echo "   This is a failure to report, not a baseline to regenerate." >&2
echo "   The likeliest cause is a header staged from an upstream revision that" >&2
echo "   does not match, or a per-product #ifdef nobody selected -- see" >&2
echo "   sdk/patches/0002-xnu-platform-macosx.patch for the last one of those." >&2
exit 1
