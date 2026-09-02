#!/bin/bash
# probe_difftest.sh -- grade tests/png_probe.swift DIFFERENTIALLY.
#
# The nine expected values are NOT written down anywhere. They are produced by
# building the same source with Apple's toolchain and running it natively on
# macOS; the Linux/machorun run must reproduce that output byte for byte. A
# hardcoded table would silently bless a wrong answer the day the stdlib changes
# what, say, ArraySlice.count returns -- this cannot.
#
#   ./scripts/probe_difftest.sh            # macOS oracle + machorun, compare
#   ORACLE=path ./scripts/probe_difftest.sh   # reuse a previously captured oracle
#
# Needs: macOS host with Xcode (for the oracle), Docker with
# swift-macho-spike:noble (for the Linux build + machorun run).
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SLICE=${SLICE:-$HOME/swift-macho-linux}          # read-only: build scripts + guest root
WORK=${WORK:-$(mktemp -d)}
ORACLE=${ORACLE:-$WORK/oracle.txt}

die() { echo "probe_difftest: $*" >&2; exit 1; }

# ---- 1. the oracle: Apple toolchain, native macOS ----------------------------
if [ ! -s "$ORACLE" ]; then
    [ "$(uname -s)" = Darwin ] || die "no oracle and not on macOS -- capture one there first"
    command -v swiftc >/dev/null || die "swiftc not found (need Xcode for the oracle)"
    echo "== oracle: building with Apple's toolchain"
    swiftc -target arm64-apple-macos13.0 -parse-as-library -wmo -emit-object \
        -o "$WORK/probe.o" "$ROOT/tests/png_probe.swift" || die "oracle compile failed"
    clang -target arm64-apple-macos13.0 -o "$WORK/probe_macos" \
        "$ROOT/tests/png_probe_main.c" "$WORK/probe.o" || die "oracle link failed"
    "$WORK/probe_macos" >"$ORACLE" 2>&1
    ostat=$?
    echo "exit=$ostat" >>"$ORACLE"
    [ $ostat -eq 0 ] || die "oracle itself failed (exit $ostat) -- fix the probe, not the loader"
fi
echo "== oracle output"; sed 's/^/   /' "$ORACLE"

# ---- 2. the subject: Linux-built Mach-O under machorun -----------------------
[ -d "$SLICE" ] || die "need $SLICE for the Linux build scripts and guest root"
cp "$ROOT/tests/png_probe.swift" "$ROOT/tests/png_probe_main.c" "$SLICE/slice/probe/" || die "cannot stage probe"
echo "== linux: building Mach-O and running under machorun"
docker run --rm -v "$SLICE:/w" -w /w swift-macho-spike:noble \
    bash scripts/build_pngprobe.sh >/dev/null 2>&1 || die "linux build failed"
docker run --rm -v "$SLICE:/w" -w /w/build/slice -e MACHORUN_ROOT=/w/scratch/mrroot \
    swift-macho-spike:noble /w/scratch/mrroot/machorun ./png_probe >"$WORK/linux.txt" 2>&1
lstat=$?
echo "exit=$lstat" >>"$WORK/linux.txt"

# ---- 3. the verdict ----------------------------------------------------------
if diff -u "$ORACLE" "$WORK/linux.txt" >"$WORK/diff.txt"; then
    echo "== PASS -- machorun output is byte-identical to native macOS"
    exit 0
fi
echo "== FAIL -- machorun diverges from the macOS oracle"
sed 's/^/   /' "$WORK/diff.txt"
exit 1
