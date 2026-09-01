#!/bin/bash
# Print one portable SHA-256 identifying every source/resource that can affect
# the render_full UIHelpers-surface probe. Paths are normalized before hashing,
# so the Linux build container and the macOS runner compute the same value.
set -euo pipefail

ROOT=${1:?usage: uihelpers_subject.sh <swift-macho-linux-root> <uikit-root> [swift-foundation-root] [swift-collections-root]}
UIKIT=${2:?usage: uihelpers_subject.sh <swift-macho-linux-root> <uikit-root> [swift-foundation-root] [swift-collections-root]}
SWIFT_FOUNDATION=${3:-$ROOT/scratch/swift-foundation}
SWIFT_COLLECTIONS=${4:-$ROOT/scratch/swift-collections}
PINNED_INPUTS_TOOL=$ROOT/full/foundation/pinned_inputs.pl
PINNED_UPSTREAM_STATE=$(perl "$PINNED_INPUTS_TOOL" verify \
    --swift-foundation "$SWIFT_FOUNDATION" \
    --swift-collections "$SWIFT_COLLECTIONS" \
    --digest-only)

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

hash_stream() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    else
        shasum -a 256 | awk '{print $1}'
    fi
}

{
    printf 'upstream/pinned-compile-inputs\t%s\n' "$PINNED_UPSTREAM_STATE"

    find "$UIKIT/Sources/OpenUIKit" \
         "$UIKIT/Sources/OpenCoreGraphics" \
         "$UIKIT/Sources/DeveloperToolsSupport" \
         "$UIKIT/Sources/CQuartz" \
         "$UIKIT/Sources/CPortableIO" \
         "$UIKIT/Sources/CSTBTrueType" \
         "$UIKIT/Sources/UIKitShim" \
         -type f | LC_ALL=C sort | while IFS= read -r file; do
        rel=${file#"$UIKIT"/}
        printf 'uikit/%s\t%s\n' "$rel" "$(hash_file "$file")"
    done

    for rel in Sources/openrender/SceneBuilder.swift \
               Sources/openrender/RealApp.swift; do
        printf 'uikit/%s\t%s\n' "$rel" "$(hash_file "$UIKIT/$rel")"
    done
    find "$UIKIT/Sources/RealAppProbe" -type f | LC_ALL=C sort | \
        while IFS= read -r file; do
            rel=${file#"$UIKIT"/}
            printf 'uikit/%s\t%s\n' "$rel" "$(hash_file "$file")"
        done

    find "$ROOT/full/driver" "$ROOT/full/shims" "$ROOT/full/appshim" \
         "$ROOT/full/hostclock" "$ROOT/full/foundation" \
         -type f | LC_ALL=C sort | while IFS= read -r file; do
        rel=${file#"$ROOT"/}
        printf 'spike/%s\t%s\n' "$rel" "$(hash_file "$file")"
    done

    for rel in full/scripts/build_full.sh full/scripts/uihelpers_subject.sh \
               spike/syspatch.c spike/cxxpatch.cpp scripts/set_id_dylib.pl; do
        printf 'spike/%s\t%s\n' "$rel" "$(hash_file "$ROOT/$rel")"
    done
} | hash_stream
