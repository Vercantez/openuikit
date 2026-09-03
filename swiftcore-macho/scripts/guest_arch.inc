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

# Stock swift.org 6.2.4: /opt/swift624 on the Graviton box, /usr on the
# swift:6.2-noble image this VM boots from.
if [ -z "${TC:-}" ]; then
    if [ -x /opt/swift624/usr/bin/swiftc ]; then
        TC=/opt/swift624/usr
    elif [ -x /usr/bin/swiftc ]; then
        TC=/usr
    else
        echo "guest_arch: no swiftc at /opt/swift624/usr/bin or /usr/bin" >&2
        exit 1
    fi
fi

# Pinned by BUILD_LOG.md and full/observation/UPSTREAM.md. Tag is a label;
# the commit is the pin.
SWIFT_PIN_TAG=swift-6.2.4-RELEASE
SWIFT_PIN_COMMIT=ee343b46aef81c3ac7c5d7960cb35a41a88c5a9b
