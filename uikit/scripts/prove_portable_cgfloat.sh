#!/usr/bin/env bash
# Compare Apple's native CGFloat contract with the Foundation-hidden ARM64
# Mach-O implementation, then execute that guest through machorun on Linux.

set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
SUPPORT=${SWIFT_MACHO_LINUX:-"$REPO/../swift-macho-linux"}
if [ ! -d "$SUPPORT/scratch" ]; then
    SUPPORT=$(git -C "$REPO" rev-parse --show-toplevel)
fi
IMAGE=${SWIFT_MACHO_IMAGE:-swift-macho-spike:noble}
PROBE=$REPO/Tools/cgfloatprobe/main.swift
PORTABLE=$REPO/Sources/OpenCoreGraphics/PortableCGFloat.swift
SYSROOT=$SUPPORT/scratch/sysroot_fe4
GUEST_ROOT=$SUPPORT/scratch/mrroot_full
SWIFTCORE_PATCH=$SUPPORT/build/full/swiftcorepatch.o
REPO_ROOT=$(git -C "$REPO" rev-parse --show-toplevel)

fail() {
    echo "prove_portable_cgfloat: $*" >&2
    exit 2
}

[ -f "$PROBE" ] || fail "missing probe source: $PROBE"
[ -f "$PORTABLE" ] || fail "missing portable CGFloat source: $PORTABLE"
[ -d "$SYSROOT/usr/include" ] || fail "missing target15 sysroot: $SYSROOT"
[ -f "$GUEST_ROOT/darwin/usr/lib/libswiftcompat.dylib" ] \
    || fail "missing staged Swift compatibility runtime"
[ -f "$GUEST_ROOT/darwin/usr/lib/libSystem.B.dylib" ] \
    || fail "missing staged libSystem umbrella"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/openuikit-cgfloat.XXXXXX")
trap 'rm -rf -- "$WORK"' EXIT

echo "== native Apple CGFloat oracle"
if [ "$(uname -s)" = Darwin ] && command -v xcrun >/dev/null; then
    xcrun swiftc "$PROBE" -o "$WORK/native-cgfloat-probe"
    "$WORK/native-cgfloat-probe"
else
    echo "CURSOR_ENV_MACOS_ORACLE_LOCAL_ONLY host=$(uname -s)"
fi

echo "== Foundation-hidden ARM64 Mach-O CGFloat guest"
run_guest_compile() {
    local uikit=$1 support=$2 out=$3
    local sys=$support/scratch/sysroot_fe4
    local root=$support/scratch/mrroot_full
    mkdir -p "$out/module-cache"
    swiftc -target arm64-apple-macos15.0 -sdk "$sys" \
        -module-cache-path "$out/module-cache" \
        -runtime-compatibility-version none -wmo \
        -Xfrontend -disable-implicit-string-processing-module-import \
        -Xfrontend -disable-objc-attr-requires-foundation-module \
        -module-name PortableCGFloatRuntime \
        -emit-object -o "$out/probe.o" \
        "$uikit/Sources/OpenCoreGraphics/PortableCGFloat.swift" \
        "$uikit/Tools/cgfloatprobe/main.swift"
    ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
        -syslibroot "$sys" -dead_strip -exported_symbol __mh_execute_header \
        -rpath /usr/lib/swift -rpath @loader_path \
        -L"$root/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
        "$root/darwin/usr/lib/libswiftcompat.dylib" \
        -L/usr/lib -lSystem "$root/darwin/usr/lib/libSystem.B.dylib" \
        -o "$out/portable-cgfloat-probe" \
        "$out/probe.o" "$support/build/full/swiftcorepatch.o"
    file "$out/portable-cgfloat-probe"
}

if command -v docker >/dev/null && docker info >/dev/null 2>&1; then
    [ -x "$GUEST_ROOT/machorun" ] || fail "missing machorun guest root: $GUEST_ROOT"
    [ -f "$SWIFTCORE_PATCH" ] || fail "missing full-build Swift runtime patch object"
    docker run --rm \
        -v "$REPO:/uikit:ro" \
        -v "$SUPPORT:/w:ro" \
        -w /tmp \
        "$IMAGE" \
        bash -lc '
set -euo pipefail
OUT=/tmp/openuikit-cgfloat
SYS=/w/scratch/sysroot_fe4
ROOT=/w/scratch/mrroot_full
mkdir -p "$OUT/module-cache"
swiftc -target arm64-apple-macos15.0 -sdk "$SYS" \
    -module-cache-path "$OUT/module-cache" \
    -runtime-compatibility-version none -wmo \
    -Xfrontend -disable-implicit-string-processing-module-import \
    -Xfrontend -disable-objc-attr-requires-foundation-module \
    -module-name PortableCGFloatRuntime \
    -emit-object -o "$OUT/probe.o" \
    /uikit/Sources/OpenCoreGraphics/PortableCGFloat.swift \
    /uikit/Tools/cgfloatprobe/main.swift
ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
    -syslibroot "$SYS" -dead_strip -exported_symbol __mh_execute_header \
    -rpath /usr/lib/swift -rpath @loader_path \
    -L"$ROOT/darwin/usr/lib" -L/usr/lib/swift -lswiftCore \
    "$ROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem "$ROOT/darwin/usr/lib/libSystem.B.dylib" \
    -o "$OUT/portable-cgfloat-probe" \
    "$OUT/probe.o" /w/build/full/swiftcorepatch.o
file "$OUT/portable-cgfloat-probe"
MACHORUN_ROOT="$ROOT" "$ROOT/machorun" "$OUT/portable-cgfloat-probe"
'
elif bash "$REPO_ROOT/.cursor/attest-cursor-env.sh"; then
    echo "CURSOR_ENV_TOOLCHAIN_ATTESTED compiling CGFloat guest in-VM (docker pinned the same swift:6.2-noble toolchain)"
    if [ -f "$SWIFTCORE_PATCH" ]; then
        run_guest_compile "$REPO" "$SUPPORT" "$WORK"
    else
        echo "prove_portable_cgfloat: compile skipped -- missing $SWIFTCORE_PATCH (full/scripts/build_full.sh product)" >&2
    fi
    bash "$REPO_ROOT/.cursor/refuse-arm64-execution.sh" || exit $?
else
    fail "Docker is required for the Linux-hosted guest, and CURSOR_ENV attestation failed"
fi