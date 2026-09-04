#!/usr/bin/env bash
# Stamp-keyed x86 loader + darwin userland + objc4 + quartz, then park leftover
# arm64 dylibs so gen_tbd CHECK 4 is honest. Call this after prepare.py (which
# CANNOT-builds the loader on x86_64 when the binary is missing) and before
# `machorun/scripts/build.sh tbd`.
#
#   bash scripts/x86/ensure_machorun.sh [--layout-only] [tree]
#
# The committed layout (prepare.py / x86_cycle products) is:
#   machorun/build/machorun     host ELF loader (gitignored via build/)
#   machorun/darwin/usr/lib/*   x86 Darwin dylibs (gitignored via darwin/usr/)
# A loader at the subtree root (machorun/machorun) is untracked: .gitignore
# does not cover it, and every attestation gate refuses
# `focus_widget_guest: machorun subtree is dirty: ?? machorun/machorun`.
#
# Prints stamp reused=1 / rebuilt reason= lines to stderr. Exit 0 only when
# the loader is an x86-64 ELF PIE, libSystem.B.dylib is X86_64 Mach-O, and
# `git status --short machorun` is empty.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.inc
. "$HERE/common.inc"

LAYOUT_ONLY=0
if [ "${1:-}" = "--layout-only" ]; then
    LAYOUT_ONLY=1
    shift
fi

W=${1:-${W:-}}
if [ -z "$W" ]; then
    W=$(cd "$HERE/../.." && pwd -P)
fi
W=$(cd "$W" && pwd -P)
export W
export CC="${CC:-clang-18}"
export DARWIN_CLANG="${DARWIN_CLANG:-clang-18}"

MACHORUN=${MACHORUN:-$W/machorun}

# Move a loader that landed at the subtree root into build/, then delete any
# leftover untracked binary / stamp sidecar. Attestation greps
# `git status --short machorun`; build/ is ignored, machorun/machorun is not.
ensure_machorun_normalize_loader() {
    local bin=$MACHORUN/build/machorun
    local stray=$MACHORUN/machorun
    mkdir -p "$MACHORUN/build"
    # Overlay build_stdlib.sh `ln -sfn "$MACHORUN" "$W/machorun"` with W=$TREE
    # nests a directory-symlink at machorun/machorun (~44 bytes). -f is false
    # for a symlink-to-dir, so the regular-file move below never saw it.
    if [ -L "$stray" ]; then
        echo "ensure_machorun: removing nested symlink $stray" >&2
        rm -f "$stray"
    elif [ -f "$stray" ]; then
        if [ ! -x "$bin" ]; then
            echo "ensure_machorun: moving stray loader $stray -> $bin" >&2
            mv -f "$stray" "$bin"
        else
            echo "ensure_machorun: removing stray loader $stray (kept $bin)" >&2
            rm -f "$stray"
        fi
    fi
    rm -f "$MACHORUN/machorun.inputs-sha256" "$MACHORUN/a.out"
}

# prepare.py / x86_cycle products live under gitignored paths. Anything else
# under machorun/ (the subtree-root ELF in particular) fails the next MAIN
# cycle at focus_widget_guest.
ensure_machorun_assert_vendor_clean() {
    local status
    if [ ! -x "$MACHORUN/build/machorun" ]; then
        echo "ensure_machorun: committed layout missing $MACHORUN/build/machorun" >&2
        return 1
    fi
    if [ -e "$MACHORUN/machorun" ]; then
        echo "ensure_machorun: stray loader at subtree root: $MACHORUN/machorun" >&2
        return 1
    fi
    if ! git -C "$W" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "ensure_machorun: $W is not a git work tree" >&2
        return 1
    fi
    status=$(git -C "$W" status --short --untracked-files=all -- machorun)
    if [ -n "$status" ]; then
        echo "ensure_machorun: machorun subtree is dirty: $status" >&2
        return 1
    fi
    return 0
}

if [ "$LAYOUT_ONLY" = 1 ]; then
    [ -d "$MACHORUN" ] || {
        echo "ensure_machorun: $MACHORUN is not a directory" >&2
        exit 2
    }
    ensure_machorun_normalize_loader
    ensure_machorun_assert_vendor_clean
    echo "ensure_machorun: layout-only ok loader=$MACHORUN/build/machorun" >&2
    exit 0
fi

# shellcheck disable=SC1091
. "$W/full/scripts/guest_arch.inc"

[ -f "$MACHORUN/scripts/build.sh" ] || {
    echo "ensure_machorun: $W is not an openuikit tree" >&2
    exit 2
}

# Committed build.sh sets BUILD=$ROOT/build and -o $BUILD/machorun. A parent
# BUILD= at the subtree (or treating BUILD as the output file) is what left
# ?? machorun/machorun on the box. Force the directory form and run with cwd
# inside the vendor tree so relative stamp paths cannot escape it.
ensure_machorun_run_build() {
    local what=$1
    (
        cd "$MACHORUN"
        env -u BUILD BUILD="$MACHORUN/build" sh ./scripts/build.sh "$what"
    )
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
        ensure_machorun_normalize_loader
        return 0
    fi
    stamp_rebuild_reason "$bin" "$key"
    echo "== cold-build loader (CC=$CC)" >&2
    ensure_machorun_run_build loader
    ensure_machorun_normalize_loader
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
    ensure_machorun_run_build darwin
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
ensure_machorun_normalize_loader

if ! phase2_is_elf_x86_loader "$MACHORUN/build/machorun"; then
    echo "ensure_machorun: CANNOT_BUILD_LOADER no x86-64 ELF PIE at $MACHORUN/build/machorun" >&2
    exit 2
fi
if ! stamp_expected_kind "$MACHORUN/darwin/usr/lib/libSystem.B.dylib"; then
    echo "ensure_machorun: CANNOT_BUILD_DARWIN libSystem.B.dylib is not X86_64 Mach-O" >&2
    exit 2
fi
ensure_machorun_assert_vendor_clean
echo "ensure_machorun: ok loader=$(file -b "$MACHORUN/build/machorun") darwin=$(phase2_macho_cpu "$MACHORUN/darwin/usr/lib/libSystem.B.dylib")" >&2
exit 0
