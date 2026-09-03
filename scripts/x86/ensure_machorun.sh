#!/usr/bin/env bash
# Stamp-keyed x86 loader + darwin userland + objc4 + quartz, then park leftover
# arm64 dylibs so gen_tbd CHECK 4 is honest. Call this after prepare.py (which
# CANNOT-builds the loader on x86_64 when the binary is missing) and before
# `machorun/scripts/build.sh tbd`.
#
#   bash scripts/x86/ensure_machorun.sh [tree]
#
# Prints stamp reused=1 / rebuilt reason= lines to stderr. Exit 0 only when
# the loader is an x86-64 ELF PIE and libSystem.B.dylib is X86_64 Mach-O.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.inc
. "$HERE/common.inc"

W=${1:-${W:-}}
if [ -z "$W" ]; then
    W=$(cd "$HERE/../.." && pwd -P)
fi
W=$(cd "$W" && pwd -P)
export W
export CC="${CC:-clang-18}"
export DARWIN_CLANG="${DARWIN_CLANG:-clang-18}"

# shellcheck disable=SC1091
. "$W/full/scripts/guest_arch.inc"

MACHORUN=${MACHORUN:-$W/machorun}
[ -f "$MACHORUN/scripts/build.sh" ] || {
    echo "ensure_machorun: $W is not an openuikit tree" >&2
    exit 2
}

ensure_machorun_key() {
    local product=$1
    shift
    local tree
    tree=$(phase2_git "$W" rev-parse HEAD:machorun 2>/dev/null | tr -d '[:space:]') || tree=missing
    stamp_key "$product" "$tree" "$@"
}

ensure_loader() {
    local bin=$MACHORUN/build/machorun
    local key
    key=$(ensure_machorun_key "$bin" loader)
    if stamp_reuse "$bin" "$key"; then
        return 0
    fi
    stamp_rebuild_reason "$bin" "$key"
    echo "== cold-build loader (CC=$CC)" >&2
    sh "$MACHORUN/scripts/build.sh" loader
    if phase2_is_elf_x86_loader "$bin"; then
        stamp_write "$bin" "$key"
        return 0
    fi
    echo "ensure_machorun: CANNOT_BUILD_LOADER host=$(uname -m) product=$bin file=$(file -b "$bin" 2>/dev/null || echo missing)" >&2
    return 1
}

ensure_darwin() {
    local dylib=$MACHORUN/darwin/usr/lib/libSystem.B.dylib
    local key
    key=$(ensure_machorun_key "$dylib" darwin)
    if stamp_reuse "$dylib" "$key"; then
        return 0
    fi
    stamp_rebuild_reason "$dylib" "$key"
    echo "== cold-build darwin userland (x86_64-apple-macos)" >&2
    sh "$MACHORUN/scripts/build.sh" darwin
    if stamp_expected_kind "$dylib"; then
        stamp_write "$dylib" "$key"
        return 0
    fi
    echo "ensure_machorun: CANNOT_BUILD_DARWIN $(file -b "$dylib" 2>/dev/null || echo missing)" >&2
    return 1
}

ensure_objc4() {
    local dylib=$MACHORUN/darwin/usr/lib/libobjc.A.dylib
    local key
    key=$(ensure_machorun_key "$dylib" objc4)
    if stamp_reuse "$dylib" "$key"; then
        return 0
    fi
    stamp_rebuild_reason "$dylib" "$key"
    echo "== cold-build objc4" >&2
    bash "$MACHORUN/scripts/build_objc4.sh"
    if stamp_expected_kind "$dylib"; then
        stamp_write "$dylib" "$key"
        return 0
    fi
    echo "ensure_machorun: CANNOT_BUILD_LIBOBJC_X86 $(file -b "$dylib" 2>/dev/null || echo missing)" >&2
    return 1
}

ensure_quartz() {
    local dylib=$MACHORUN/darwin/usr/lib/libquartz.dylib
    local key
    key=$(ensure_machorun_key "$dylib" quartz)
    if stamp_reuse "$dylib" "$key"; then
        return 0
    fi
    stamp_rebuild_reason "$dylib" "$key"
    echo "== cold-build quartz" >&2
    bash "$MACHORUN/scripts/build_quartz.sh"
    if stamp_expected_kind "$dylib"; then
        stamp_write "$dylib" "$key"
        return 0
    fi
    echo "ensure_machorun: CANNOT_BUILD_QUARTZ_X86 $(file -b "$dylib" 2>/dev/null || echo missing)" >&2
    return 1
}

ensure_loader
ensure_darwin
ensure_objc4
ensure_quartz
phase2_park_arm64_darwin_dylibs "$MACHORUN/darwin/usr/lib"

if ! phase2_is_elf_x86_loader "$MACHORUN/build/machorun"; then
    echo "ensure_machorun: CANNOT_BUILD_LOADER no x86-64 ELF PIE at $MACHORUN/build/machorun" >&2
    exit 2
fi
if ! stamp_expected_kind "$MACHORUN/darwin/usr/lib/libSystem.B.dylib"; then
    echo "ensure_machorun: CANNOT_BUILD_DARWIN libSystem.B.dylib is not X86_64 Mach-O" >&2
    exit 2
fi
echo "ensure_machorun: ok loader=$(file -b "$MACHORUN/build/machorun") darwin=$(phase2_macho_cpu "$MACHORUN/darwin/usr/lib/libSystem.B.dylib")" >&2
exit 0
