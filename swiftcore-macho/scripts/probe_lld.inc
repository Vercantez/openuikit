# probe_lld.inc -- sourced. Locate Ubuntu ld.lld / ld64.lld for Darwin-target
# links on a Linux host.
#
# Swift 6.2.4's CMake picks GNU gold when GoldVersion >= 2.36
# (CMakeLists.txt:1079-1089). AddSwiftStdlib.cmake then emits
# -fuse-ld=${SWIFT_USE_LINKER}. Swift's clang driver rejects the name
# `gold` ("invalid linker name in argument '-fuse-ld=gold'") even when
# /usr/bin/ld.gold exists (Ubuntu 24.04 package: binutils). That wall is
# not confined to libswiftCore.so: every overlay ninja target depends on
# it. Configure with -DSWIFT_USE_LINKER=lld and point -B at a directory
# that actually contains ld64.lld (Ubuntu llvm-18), because the swift.org
# toolchain's own lld refuses platform macOS.

if [ -n "${SWIFTCORE_PROBE_LLD_INC:-}" ]; then
    return 0 2>/dev/null || exit 0
fi
SWIFTCORE_PROBE_LLD_INC=1

# probe_lld
# Sets LLD_BIN (directory), LD_LLD, LD64_LLD. Exit 2 with CANNOT_LINKER_LLD
# if neither ld.lld nor ld64.lld is usable.
probe_lld() {
    local d cand
    LLD_BIN=${LLD_BIN:-}
    LD_LLD=${LD_LLD:-}
    LD64_LLD=${LD64_LLD:-}

    # Prefer Ubuntu llvm-18 over ${TC}/bin: the swift.org lld refuses macOS.
    for d in \
        ${LLD_BIN:+$LLD_BIN} \
        /usr/lib/llvm-18/bin \
        /usr/bin \
        ${TC:+$TC/bin}
    do
        [ -n "$d" ] || continue
        [ -d "$d" ] || continue
        if [ -z "$LD64_LLD" ]; then
            for cand in "$d/ld64.lld" "$d/ld64.lld-18"; do
                if [ -x "$cand" ]; then
                    LD64_LLD=$cand
                    LLD_BIN=$d
                    break
                fi
            done
        fi
        if [ -z "$LD_LLD" ] && [ -x "$d/ld.lld" ]; then
            LD_LLD=$d/ld.lld
            LLD_BIN=${LLD_BIN:-$d}
        fi
        if [ -n "$LD_LLD" ] && [ -n "$LD64_LLD" ]; then
            break
        fi
    done

    if [ -z "$LD_LLD" ]; then
        LD_LLD=$(command -v ld.lld 2>/dev/null || true)
    fi
    if [ -z "$LD64_LLD" ]; then
        LD64_LLD=$(command -v ld64.lld 2>/dev/null || true)
    fi
    if [ -z "$LLD_BIN" ] && [ -n "$LD64_LLD" ]; then
        LLD_BIN=$(cd "$(dirname "$LD64_LLD")" && pwd)
    fi
    if [ -z "$LLD_BIN" ] && [ -n "$LD_LLD" ]; then
        LLD_BIN=$(cd "$(dirname "$LD_LLD")" && pwd)
    fi

    if [ -z "$LD_LLD" ] && [ -z "$LD64_LLD" ]; then
        echo "CANNOT_LINKER_LLD reason=no-ld.lld need=ld.lld-or-ld64.lld hint=/usr/lib/llvm-18/bin (Ubuntu 24.04: lld / llvm-18). binutils ld.gold is present on this distro but Swift's clang rejects -fuse-ld=gold." >&2
        return 2
    fi
    if [ -z "$LD_LLD" ] && [ -n "$LD64_LLD" ]; then
        # Darwin driver wants ld64.lld; the ELF name is still `lld`.
        if [ -x "$LLD_BIN/ld.lld" ]; then
            LD_LLD=$LLD_BIN/ld.lld
        else
            LD_LLD=$LD64_LLD
        fi
    fi
    return 0
}
