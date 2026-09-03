# full/dispatch/swift_linux_lib.inc -- resolve the Linux Swift runtime dir.
# Sourced, not executed. Shared by full/dispatch/build_host_bridge.sh and
# scripts/x86/common.inc so the search order cannot drift:
#   SWIFT_TOOLCHAIN/{usr/,}lib/swift/linux
#   /opt/swift624/usr/lib/swift/linux
#   /opt/swift/usr/lib/swift/linux
#   swiftc-on-PATH ../lib/swift/linux
#   /usr/lib/swift/linux
#
# Closed host-runtime set is the same list full/scripts/build_full.sh stages
# from scratch/mrroot[-x86_64]/host/. libdispatch.so and libBlocksRuntime.so
# are toolchain copies. The four Open* names are project-built ELF helpers
# (not toolchain copies, never arm64 ELF). Do not add names here without an
# ABI decision in build_full.sh.

if [ -n "${OPENUIKIT_SWIFT_LINUX_LIB_INC:-}" ]; then
    return 0 2>/dev/null || true
fi
OPENUIKIT_SWIFT_LINUX_LIB_INC=1

openuikit_host_runtime_toolchain_files() {
    printf '%s\n' \
        libdispatch.so \
        libBlocksRuntime.so
}

openuikit_host_runtime_built_files() {
    printf '%s\n' \
        libOpenDispatchHost.so \
        libOpenFoundationInternationalizationHost.so \
        libOpenURLTransportHost.so \
        libOpenRelativeTimeHost.so
}

openuikit_host_runtime_files() {
    openuikit_host_runtime_toolchain_files
    openuikit_host_runtime_built_files
}

# Print the directory that contains libdispatch.so for the host Swift runtime.
openuikit_resolve_swift_linux_lib() {
    local _swift_linux_lib=/usr/lib/swift/linux
    local _cand _swiftc_dir
    if [ -n "${SWIFT_TOOLCHAIN:-}" ] && [ -d "$SWIFT_TOOLCHAIN/usr/lib/swift/linux" ]; then
        _swift_linux_lib=$SWIFT_TOOLCHAIN/usr/lib/swift/linux
    elif [ -n "${SWIFT_TOOLCHAIN:-}" ] && [ -d "$SWIFT_TOOLCHAIN/lib/swift/linux" ]; then
        _swift_linux_lib=$SWIFT_TOOLCHAIN/lib/swift/linux
    elif [ ! -f "$_swift_linux_lib/libdispatch.so" ]; then
        # Same order as full/scripts/guest_arch.inc: the pinned EC2 prefixes,
        # then whatever swiftc is on PATH (SSM sessions carry a minimal PATH,
        # so the prefixes must come first).
        for _cand in /opt/swift624/usr /opt/swift/usr; do
            if [ -f "$_cand/lib/swift/linux/libdispatch.so" ]; then
                _swift_linux_lib=$_cand/lib/swift/linux
                break
            fi
        done
        if [ ! -f "$_swift_linux_lib/libdispatch.so" ] && command -v swiftc >/dev/null 2>&1; then
            _swiftc_dir=$(cd "$(dirname "$(command -v swiftc)")" && pwd -P)
            if [ -f "$_swiftc_dir/../lib/swift/linux/libdispatch.so" ]; then
                _swift_linux_lib=$(cd "$_swiftc_dir/../lib/swift/linux" && pwd -P)
            fi
        fi
    fi
    printf '%s\n' "$_swift_linux_lib"
}
