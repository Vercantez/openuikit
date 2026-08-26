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
BUILD="$ROOT/build/abi_probe"
SDK="$ROOT/sdk"

die() { echo "sdk_abi_probe: $*" >&2; exit 1; }
mkdir -p "$BUILD"

if [ "${1:-}" = "--record" ]; then
    [ "$(uname -s)" = "Darwin" ] || die "--record only runs on the macOS oracle"
    command -v xcrun >/dev/null 2>&1 || die "no xcrun"
    APPLE_SDK=$(xcrun --sdk macosx --show-sdk-path) || die "no macOS SDK"
    echo "== oracle: $(xcrun -f clang), $APPLE_SDK"
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
