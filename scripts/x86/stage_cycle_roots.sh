#!/usr/bin/env bash
# Cycle "roots" stage: the same trees phase2.sh stages, so a VM that skips
# phase2 at install still has mrroot-x86_64 + mrroot_full-x86_64.
#
#   bash scripts/x86/stage_cycle_roots.sh [tree]
#
# BASE (scratch/mrroot-x86_64): ELF loader + x86 darwin + libswiftCore +
#   host runtime + loud-abort Foundation/CF + libswiftcompat + twelve overlays.
# RUN (scratch/mrroot_full-x86_64): loader + darwin + libswiftCore + overlays +
#   EMPTY Foundation placeholders (not loud-abort stubs — those clash with
#   malloc zones when run_ud_guest.sh loads them as CoreFoundation).
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
SYS=${SYS:-$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}}
BASE_MRROOT=${BASE_MRROOT:-$W/scratch/mrroot${FULL_OUT_SUFFIX}}
FE_MRROOT=${FE_MRROOT:-$W/scratch/mrroot_fe${FULL_OUT_SUFFIX}}
MRROOT=${MRROOT:-$W/scratch/mrroot_full${FULL_OUT_SUFFIX}}
artifacts=$W/swiftcore-macho/artifacts
x86_core=$artifacts/swift-macosx/x86_64/libswiftCore.dylib

[ -f "$MACHORUN/scripts/build.sh" ] || {
    echo "stage_cycle_roots: $W is not an openuikit tree" >&2
    exit 2
}

echo "== base mrroot $BASE_MRROOT"
phase2_stage_x86_base_mrroot \
    "$BASE_MRROOT" \
    "$MACHORUN/build/machorun" \
    "$MACHORUN/darwin" \
    "$x86_core"
if [ ! -x "$BASE_MRROOT/machorun" ] || ! phase2_is_elf_x86_loader "$BASE_MRROOT/machorun"; then
    echo "stage_cycle_roots: CANNOT_STAGE_MRROOT_LOADER no x86 ELF loader at $BASE_MRROOT/machorun" >&2
    exit 2
fi
if [ ! -f "$BASE_MRROOT/darwin/usr/lib/swift/libswiftCore.dylib" ] \
    || ! phase2_is_x86_macho "$BASE_MRROOT/darwin/usr/lib/swift/libswiftCore.dylib"; then
    echo "stage_cycle_roots: CANNOT_BUILD_LIBSWIFTCORE_X86 missing x86 libswiftCore in $BASE_MRROOT" >&2
    exit 2
fi

echo "== host runtime $BASE_MRROOT/host"
host_report=$(phase2_stage_x86_host_runtime "$BASE_MRROOT" "$W" || true)
case "$host_report" in
    OK) echo "  host runtime OK" >&2 ;;
    *)
        echo "stage_cycle_roots: CANNOT_X86_HOST_RUNTIME $host_report" >&2
        exit 2
        ;;
esac

echo "== FE overlay root $FE_MRROOT"
overlay_report=$(phase2_stage_x86_fe_overlays "$FE_MRROOT" || true)
case "$overlay_report" in
    OK) echo "  FE overlays OK" >&2 ;;
    *)
        echo "stage_cycle_roots: CANNOT_X86_OVERLAYS_NOT_BUILT $overlay_report" >&2
        exit 2
        ;;
esac

echo "== BASE layout (loud-abort stubs + libswiftcompat + overlays)"
layout_report=$(phase2_stage_x86_mrroot_layout \
    "$BASE_MRROOT" "$FE_MRROOT" "$W" "$SYS" "$MACHORUN/build/machorun" || true)
case "$layout_report" in
    OK) echo "  layout OK" >&2 ;;
    *)
        echo "stage_cycle_roots: CANNOT_X86_MRROOT_LAYOUT $layout_report" >&2
        exit 2
        ;;
esac

echo "== run root $MRROOT"
rm -rf "$MRROOT"
mkdir -p "$MRROOT/darwin/usr/lib/swift"
cp -f "$MACHORUN/build/machorun" "$MRROOT/machorun"
chmod a+x "$MRROOT/machorun"
if [ -d "$MACHORUN/darwin/usr/lib" ]; then
    while IFS= read -r -d '' d; do
        rel=${d#"$MACHORUN/darwin/usr/lib/"}
        if phase2_is_x86_macho "$d"; then
            mkdir -p "$MRROOT/darwin/usr/lib/$(dirname "$rel")"
            cp -a "$d" "$MRROOT/darwin/usr/lib/$rel"
        fi
    done < <(find "$MACHORUN/darwin/usr/lib" -type f -name '*.dylib' -print0)
fi
cp -f "$x86_core" "$MRROOT/darwin/usr/lib/swift/libswiftCore.dylib"
if [ -d "$BASE_MRROOT/host" ]; then
    mkdir -p "$MRROOT/host"
    cp -a "$BASE_MRROOT/host/." "$MRROOT/host/"
fi

overlay_full=$(phase2_stage_x86_run_root_overlays "$MRROOT" || true)
printf '%s\n' "$overlay_full"
if printf '%s\n' "$overlay_full" | grep -q '^CANNOT_STAGE_CACHE_EXTRACT'; then
    echo "stage_cycle_roots: CANNOT_STAGE_CACHE_EXTRACT in run root" >&2
    exit 2
fi

echo "== EMPTY Foundation placeholders into $MRROOT (not loud-abort stubs)"
if ! phase2_stage_x86_foundation_placeholders "$MRROOT" "$W" "$SYS"; then
    echo "stage_cycle_roots: CANNOT_STAGE_FOUNDATION_PLACEHOLDERS $MRROOT" >&2
    exit 2
fi

if ! phase2_is_elf_x86_loader "$MRROOT/machorun" \
    || ! phase2_is_x86_macho "$MRROOT/darwin/usr/lib/swift/libswiftCore.dylib"; then
    echo "stage_cycle_roots: CANNOT_STAGE_MRROOT copy failed to produce x86 loader+libswiftCore" >&2
    exit 2
fi
echo "stage_cycle_roots: ok base=$BASE_MRROOT run=$MRROOT" >&2
exit 0
