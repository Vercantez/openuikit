# guest_arch.inc -- Darwin-target and Linux-host arch for the stdlib cross-build.
# Sourced, not executed. The arm64 path is the recorded Graviton recipe; x86_64
# is the same recipe with these variables swapped. Do not hardcode either.
#
# SWIFTCORE_DARWIN_ARCH  Darwin slice: arm64 | x86_64
# SWIFT_HOST_VARIANT_ARCH  Linux host (CMake): aarch64 | x86_64
#
# Default Darwin slice follows the host so `configure.sh` on Graviton still
# produces arm64 and this x86_64 Linux VM produces x86_64. Override with
# SWIFTCORE_DARWIN_ARCH=arm64 on an x86 host to reproduce the original path.

if [ -n "${SWIFTCORE_GUEST_ARCH_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
SWIFTCORE_GUEST_ARCH_INC=1

_sc_host=$(uname -m)
case "$_sc_host" in
    x86_64)
        SWIFT_HOST_VARIANT_ARCH=${SWIFT_HOST_VARIANT_ARCH:-x86_64}
        SWIFT_HOST_TRIPLE=${SWIFT_HOST_TRIPLE:-x86_64-unknown-linux-gnu}
        _sc_darwin_default=x86_64
        ;;
    aarch64|arm64)
        SWIFT_HOST_VARIANT_ARCH=${SWIFT_HOST_VARIANT_ARCH:-aarch64}
        SWIFT_HOST_TRIPLE=${SWIFT_HOST_TRIPLE:-aarch64-unknown-linux-gnu}
        _sc_darwin_default=arm64
        ;;
    *)
        echo "guest_arch: unsupported Linux host $_sc_host" >&2
        exit 1
        ;;
esac

SWIFTCORE_DARWIN_ARCH=${SWIFTCORE_DARWIN_ARCH:-$_sc_darwin_default}
case "$SWIFTCORE_DARWIN_ARCH" in
    arm64)
        SWIFTCORE_MACHO_CPU=ARM64
        SWIFTCORE_CLANG_TARGET=${SWIFTCORE_CLANG_TARGET:-arm64-apple-macosx13.0}
        SWIFTCORE_SWIFTC_TARGET=${SWIFTCORE_SWIFTC_TARGET:-arm64-apple-macos15.0}
        SWIFTCORE_MODULE_TRIPLE=arm64-apple-macos
        SWIFTCORE_NINJA_CORE=swiftCore-macosx-arm64
        SWIFTCORE_NINJA_CONCURRENCY=swift_Concurrency-macosx-arm64
        SWIFTCORE_STDLIB_DIR=macosx/arm64
        TBD_TARGET=arm64-macos
        ;;
    x86_64)
        SWIFTCORE_MACHO_CPU=X86_64
        SWIFTCORE_CLANG_TARGET=${SWIFTCORE_CLANG_TARGET:-x86_64-apple-macosx13.0}
        SWIFTCORE_SWIFTC_TARGET=${SWIFTCORE_SWIFTC_TARGET:-x86_64-apple-macos15.0}
        SWIFTCORE_MODULE_TRIPLE=x86_64-apple-macos
        SWIFTCORE_NINJA_CORE=swiftCore-macosx-x86_64
        SWIFTCORE_NINJA_CONCURRENCY=swift_Concurrency-macosx-x86_64
        SWIFTCORE_STDLIB_DIR=macosx/x86_64
        TBD_TARGET=x86_64-macos
        ;;
    *)
        echo "guest_arch: SWIFTCORE_DARWIN_ARCH must be arm64 or x86_64 (got $SWIFTCORE_DARWIN_ARCH)" >&2
        exit 1
        ;;
esac

# Toolchain prefix (directory that contains bin/swiftc). Honor SWIFT_TOOLCHAIN
# first — the operator x86 host keeps Swift 6.2.4 at /opt/swift, not the
# Graviton path /opt/swift624. Then TC, then well-known prefixes, then
# `command -v swiftc`.
_sc_tc_from() {
    local root=$1
    if [ -x "$root/bin/swiftc" ]; then
        printf '%s\n' "$root"
        return 0
    fi
    if [ -x "$root/usr/bin/swiftc" ]; then
        printf '%s\n' "$root/usr"
        return 0
    fi
    return 1
}
if [ -n "${SWIFT_TOOLCHAIN:-}" ]; then
    TC=$(_sc_tc_from "$SWIFT_TOOLCHAIN") || {
        echo "guest_arch: SWIFT_TOOLCHAIN=$SWIFT_TOOLCHAIN has no bin/swiftc" >&2
        exit 1
    }
elif [ -z "${TC:-}" ]; then
    TC=""
    for _sc_cand in /opt/swift624/usr /opt/swift624 /opt/swift/usr /opt/swift /usr; do
        if TC=$(_sc_tc_from "$_sc_cand"); then
            break
        fi
        TC=""
    done
    if [ -z "$TC" ]; then
        _sc_swiftc=$(command -v swiftc 2>/dev/null || true)
        if [ -n "$_sc_swiftc" ]; then
            TC=$(cd "$(dirname "$_sc_swiftc")/.." && pwd)
        fi
    fi
    if [ -z "$TC" ] || [ ! -x "$TC/bin/swiftc" ]; then
        echo "guest_arch: no swiftc (set SWIFT_TOOLCHAIN or TC, or put swiftc on PATH)" >&2
        exit 1
    fi
fi
unset -f _sc_tc_from
unset _sc_cand _sc_swiftc

# Pinned by BUILD_LOG.md and full/observation/UPSTREAM.md. Tag is a label;
# the commit is the pin. Sibling tags are the same label on each repo;
# ls-remote of swift-6.2.4-RELEASE on 2026-09-03.
SWIFT_PIN_TAG=swift-6.2.4-RELEASE
SWIFT_PIN_COMMIT=ee343b46aef81c3ac7c5d7960cb35a41a88c5a9b
STRING_PROCESSING_PIN_COMMIT=91177e6225c63e885872b83d48e254b1270fa15a
LIBDISPATCH_PIN_COMMIT=2df91f94651f2d924d7506c9d14685929386d779
STRING_PROCESSING_REPO=https://github.com/swiftlang/swift-experimental-string-processing.git
LIBDISPATCH_REPO=https://github.com/swiftlang/swift-corelibs-libdispatch.git
