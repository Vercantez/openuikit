#!/usr/bin/env bash
# Compare Apple's native CGFloat contract with the Foundation-hidden ARM64
# Mach-O implementation, then execute that guest through machorun on Linux.

set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
SUPPORT=${SWIFT_MACHO_LINUX:-"$REPO/../swift-macho-linux"}
IMAGE=${SWIFT_MACHO_IMAGE:-swift-macho-spike:noble}
PROBE=$REPO/Tools/cgfloatprobe/main.swift
PORTABLE=$REPO/Sources/OpenCoreGraphics/PortableCGFloat.swift
SYSROOT=$SUPPORT/scratch/sysroot_fe4
GUEST_ROOT=$SUPPORT/scratch/mrroot_full
SWIFTCORE_PATCH=$SUPPORT/build/full/swiftcorepatch.o

fail() {
    echo "prove_portable_cgfloat: $*" >&2
    exit 2
}

command -v xcrun >/dev/null || fail "xcrun is required for the native oracle"
command -v docker >/dev/null || fail "Docker is required for the Linux-hosted guest"
docker info >/dev/null 2>&1 || fail "Docker daemon is unavailable"
[ -f "$PROBE" ] || fail "missing probe source: $PROBE"
[ -f "$PORTABLE" ] || fail "missing portable CGFloat source: $PORTABLE"
[ -d "$SYSROOT/usr/include" ] || fail "missing target15 sysroot: $SYSROOT"
[ -x "$GUEST_ROOT/machorun" ] || fail "missing machorun guest root: $GUEST_ROOT"
[ -f "$GUEST_ROOT/darwin/usr/lib/libswiftcompat.dylib" ] \
    || fail "missing staged Swift compatibility runtime"
[ -f "$GUEST_ROOT/darwin/usr/lib/libSystem.B.dylib" ] \
    || fail "missing staged libSystem umbrella"
[ -f "$SWIFTCORE_PATCH" ] || fail "missing full-build Swift runtime patch object"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/openuikit-cgfloat.XXXXXX")
trap 'rm -rf -- "$WORK"' EXIT

echo "== native Apple CGFloat oracle"
xcrun swiftc "$PROBE" -o "$WORK/native-cgfloat-probe"
"$WORK/native-cgfloat-probe"

echo "== Foundation-hidden ARM64 Mach-O CGFloat guest"
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
