#!/usr/bin/env bash
# Package the local SwiftUI/OpenUIKit implementation as Darwin Mach-O dylibs
# (host triple from full/scripts/guest_arch.inc), link Focus's exact
# Widget/Assets.swift + SearchWidgetView.swift against those dylibs, and run
# the guest. x86_64 output lives beside the arm64 tree
# (build/swiftui-guest-x86_64). Defaults to the in-repo uikit/ and machorun/
# subtrees. External UIKIT=/path or MACHORUN=/path remain overrides.

set -euo pipefail

W=${W:-$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)}
# shellcheck source=../../scripts/vendor_tree.sh
. "$W/scripts/vendor_tree.sh"
# shellcheck disable=SC1091
. "$(cd "$(dirname "$0")" && pwd)/../scripts/guest_arch.inc"
UIKIT=${UIKIT:-$W/uikit}
MACHORUN=${MACHORUN:-$W/machorun}
RESOURCE_INPUT=${1:?usage: build_focus_widget_guest.sh <normalized-Focus_Widget.bundle>}
FOCUS_REPO=$W/scratch/ladder-corpus/focus-ios/focus-ios
FOCUS_WIDGET=$FOCUS_REPO/BlockzillaPackage/Sources/Widget
OUT=$W/build/swiftui-guest${FULL_OUT_SUFFIX}
PACKAGE=$OUT/package
AUDIT=$OUT/audit
FULL=$W/build/full${FULL_OUT_SUFFIX}
SYS=$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}
MRROOT=$W/scratch/mrroot_full${FULL_OUT_SUFFIX}
MC=$W/scratch/modcache_swiftui_guest${FULL_OUT_SUFFIX}
SWIFT_FOUNDATION=$W/scratch/swift-foundation
FE_OUT=$FULL/foundation/essentials
FE_COLLECTIONS=$FULL/foundation/collections
FE_OS=$FULL/foundation/os
FE_CSHIMS=$FULL/foundation/cshims
SWIFTUI_SOURCE_DIR=$UIKIT/Sources/SwiftUI
SYMBOLS_SOURCE_DIR=$UIKIT/Sources/Symbols
OPENCOMBINE_ROOT=${OPENCOMBINE_ROOT:-$W/scratch/opencombine-core-durable-20260828-r2}
OPENCOMBINE_ARTIFACTS=${OPENCOMBINE_ARTIFACTS:-$OPENCOMBINE_ROOT/export${FULL_OUT_SUFFIX}/artifacts}
OPENCOMBINE_SOURCE=$OPENCOMBINE_ROOT/source
OPENCOMBINE_HELPERS=$OPENCOMBINE_SOURCE/Sources/COpenCombineHelpers
PREPARE_TOOL=$W/scripts/env/prepare.py
LEDGER_TOOL=$W/scripts/env/ledger.py

# Package the complete authoritative SwiftUI source directory.  Keeping a
# hand-maintained three-file list made the reusable package silently omit new
# first-party runtime files (for example State.swift) even though View.swift
# had begun to depend on them.
SWIFTUI_SOURCES=("$SWIFTUI_SOURCE_DIR"/*.swift)
[ "${#SWIFTUI_SOURCES[@]}" -gt 0 ] || {
    echo "focus_widget_guest: SwiftUI source inventory is empty" >&2; exit 2; }
invalid_swiftui_source=$(find "$SWIFTUI_SOURCE_DIR" -mindepth 1 -maxdepth 1 \
    \( ! -type f -o ! -name '*.swift' \) -print -quit)
[ -z "$invalid_swiftui_source" ] || {
    echo "focus_widget_guest: unsupported SwiftUI source node: $invalid_swiftui_source" >&2
    exit 2
}
for swiftui_source in "${SWIFTUI_SOURCES[@]}"; do
    [ -f "$swiftui_source" ] && [ ! -L "$swiftui_source" ] || {
        echo "focus_widget_guest: SwiftUI source is not a regular non-symlink file: $swiftui_source" >&2
        exit 2
    }
done

EXPECTED_SYMBOLS_SWIFT_COUNT=1
SYMBOLS_SOURCES=("$SYMBOLS_SOURCE_DIR"/*.swift)
[ "${#SYMBOLS_SOURCES[@]}" -eq "$EXPECTED_SYMBOLS_SWIFT_COUNT" ] || {
    echo "focus_widget_guest: Symbols source count ${#SYMBOLS_SOURCES[@]}, expected $EXPECTED_SYMBOLS_SWIFT_COUNT" >&2
    exit 2
}
invalid_symbols_source=$(find "$SYMBOLS_SOURCE_DIR" -mindepth 1 -maxdepth 1 \
    \( ! -type f -o ! -name '*.swift' \) -print -quit)
[ -z "$invalid_symbols_source" ] || {
    echo "focus_widget_guest: unsupported Symbols source node: $invalid_symbols_source" >&2
    exit 2
}
for symbols_source in "${SYMBOLS_SOURCES[@]}"; do
    [ -f "$symbols_source" ] && [ ! -L "$symbols_source" ] || {
        echo "focus_widget_guest: Symbols source is not a regular non-symlink file: $symbols_source" >&2
        exit 2
    }
done

EXPECTED_FOCUS_COMMIT=a2832521c1daa0c23419c73705ae043ed60c9791
EXPECTED_UIKIT_TREE=$EXPECTED_INREPO_UIKIT_TREE
EXPECTED_ASSETS_SHA=efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e
EXPECTED_VIEW_SHA=721669388a4556e1609f580ed87d6065b63981770e71b0f77db292767b05f6c2
EXPECTED_INDEX_SHA=2eb8af32cc6d69161dc35f1536682dcba2dd4db21ea0015cf241701f32468d12
EXPECTED_LOGO_SHA=180d76a144c6e74324283e8bfb72d9d7bb32125fe57769e3403b0ca72b6ef415
EXPECTED_FIRST_SHA=75759bdc8a68e4694bda34486c47e347ab8af010ebb8de7372b0ca443c08186b
EXPECTED_SECOND_SHA=f71bc94e686809660d920da6f7804174097e038302a843c3533da45ceda44af2
EXPECTED_RESOURCE_TREE_SHA=144c49c747d4689d9ca98d353cb5474b311473629383a779d99f1b705969a04d
EXPECTED_RESOURCE_FILE_COUNT=16
EXPECTED_RESOURCE_DIRECTORY_COUNT=7
EXPECTED_PACKAGE_FILE_COUNT=101
EXPECTED_PACKAGE_DIRECTORY_COUNT=12
BUILD_INPUT_MANIFEST=$FULL/focus-widget-build-inputs.manifest
RUNTIME_CLOSURE_MANIFEST=$FULL/focus-widget-runtime-closure.manifest
ATTEST=$W/full/swiftui/focus_widget_guest_attest.pl
SYSTEM_FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
MEDIUM_FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
EXPECTED_SYSTEM_FONT_SHA=ae7b7855e115a5966d8b1b3f80f254ccc117ec86f9965e202ee2940453837280
EXPECTED_MEDIUM_FONT_SHA=5c1247acef7f2b8522a31742c76d6adcb5569bacc0be7ceaa4dc39dd252ce895
EXPECTED_OPENCOMBINE_RESULT_SHA=c6fe4fa173f27fad0e30d1931c5ffead0aa267d55730a5885c1142bc7502b104
EXPECTED_OPENCOMBINE_OBJECT_SHA=96558e7d31c10c4bc769e9774977b74c58dc6ee83cfbd4fca8bf17229424a914
EXPECTED_OPENCOMBINE_MODULE_SHA=674d4d049d09b074b303822a88fcdc2c1d12c1e3cca9c9414ca30a74ee2c9de0
EXPECTED_OPENCOMBINE_DOC_SHA=a5a2757d33ccb621d26aea0f8ca417cf8ba748660faf1cf37eba53c5833975bc
EXPECTED_OPENCOMBINE_HELPER_SHA=73dbadeff3f6cebb9f5c57e09380e3166b65e68f0b0427d97d6a8ffdce693693
EXPECTED_OPENCOMBINE_HEADER_SHA=eb2afa8d9b46891a47ac39e43a4f94d727120acdbc0644934296c4c4ca62e935
EXPECTED_OPENCOMBINE_MODULEMAP_SHA=d34fdd050111a8cbf5ced89a129088fcfeb2964eea76ad518fafe044966572d1
EXPECTED_OPENCOMBINE_PATCH_SHA=875cd931e95c5442775e1042a412517ab7475be0489b1a81f824a54f6872c79b
EXPECTED_OPENCOMBINE_PATCHED_HELPER_SHA=d9fbefcdba66d892d9064c46b21b6084af217ddec1d604bcaf27b160de66083b
EXPECTED_COMBINE_SHIM_SHA=828b05c3a47296fb7b0b9ed5a6ca1a45a5da46e245441c21028335f60511799f

die() {
    echo "focus_widget_guest: $*" >&2
    exit 2
}

[ -f "$PREPARE_TOOL" ] && [ ! -L "$PREPARE_TOOL" ] \
    || die "env prepare tool is missing or linked: $PREPARE_TOOL"
[ -f "$LEDGER_TOOL" ] && [ ! -L "$LEDGER_TOOL" ] \
    || die "env ledger tool is missing or linked: $LEDGER_TOOL"

hash_file() { python3 "$LEDGER_TOOL" --style focus-widget hash-file "$1"; }
hash_stream() { sha256sum | awk '{print $1}'; }
require_hash() {
    python3 "$LEDGER_TOOL" --style focus-widget require-hash "$1" "$2" "$3" || exit $?
}

tree_digest() {
    local root=$1
    (
        cd "$root"
        find . -type f -print0 | LC_ALL=C sort -z | \
            while IFS= read -r -d '' file; do
                printf '%s\0%s\0' "${file#./}" "$(hash_file "$file")"
            done
    ) | hash_stream
}

support_digest() {
    {
        for file in "${SWIFTUI_SOURCES[@]}" \
            "${SYMBOLS_SOURCES[@]}" \
            "$W/full/swiftui/FocusWidgetBundle.generated.swift" \
            "$W/full/swiftui/FocusWidgetGuestMain.swift" \
            "$W/full/swiftui/focus_widget_guest_attest.pl" \
            "$W/full/oracle-opencombine/Combine.swift" \
            "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch" \
            "$W/full/scripts/build_full.sh" \
            "$W/full/swiftui/build_focus_widget_guest.sh"; do
            printf '%s\t%s\n' "${file#"$W"/}" "$(hash_file "$file")"
        done
    } | hash_stream
}

generate_build_input_inventory() {
    perl "$ATTEST" inventory \
        --w "$W" --uikit "$UIKIT" --full "$FULL" --sysroot "$SYS" \
        --opencombine-root "$OPENCOMBINE_ROOT" \
        --opencombine-artifacts "$OPENCOMBINE_ARTIFACTS"
}

assert_build_input_inventory() {
    local current
    current=$(mktemp "$FULL/.focus-widget-build-inputs.current.XXXXXX")
    generate_build_input_inventory > "$current" || {
        rm -f "$current"
        echo "focus_widget_guest: could not enumerate complete build inputs" >&2
        return 2
    }
    if ! cmp -s "$BUILD_INPUT_MANIFEST" "$current"; then
        echo "focus_widget_guest: complete build-input inventory drifted; ordinary rebuild required" >&2
        diff -u "$BUILD_INPUT_MANIFEST" "$current" >&2 || true
        rm -f "$current"
        return 2
    fi
    rm -f "$current"
}

generate_runtime_closure() {
    perl "$ATTEST" closure --otool llvm-otool-18 \
        --executable "$OUT/focus_widget_guest" \
        --package "$PACKAGE" --guest-root "$MRROOT"
}

assert_runtime_closure() {
    local current
    current=$(mktemp "$FULL/.focus-widget-runtime-closure.current.XXXXXX")
    generate_runtime_closure > "$current" || {
        rm -f "$current"
        echo "focus_widget_guest: could not resolve complete Mach-O runtime closure" >&2
        return 2
    }
    if ! cmp -s "$RUNTIME_CLOSURE_MANIFEST" "$current"; then
        echo "focus_widget_guest: recursive Mach-O runtime closure drifted" >&2
        diff -u "$RUNTIME_CLOSURE_MANIFEST" "$current" >&2 || true
        rm -f "$current"
        return 2
    fi
    rm -f "$current"
}

runtime_fingerprint() {
    {
        printf 'guest\t%s\n' "$(hash_file "$OUT/focus_widget_guest")"
        printf 'libSwiftUI\t%s\n' "$(hash_file "$PACKAGE/libSwiftUI.dylib")"
        printf 'libOpenUIKit\t%s\n' "$(hash_file "$PACKAGE/libOpenUIKit.dylib")"
        printf 'libFoundationEssentials\t%s\n' \
            "$(hash_file "$PACKAGE/libFoundationEssentials.dylib")"
        printf 'libOpenCoreGraphics\t%s\n' \
            "$(hash_file "$PACKAGE/libOpenCoreGraphics.dylib")"
        printf 'libCombine\t%s\n' "$(hash_file "$PACKAGE/libCombine.dylib")"
        printf 'libOpenCombine\t%s\n' "$(hash_file "$PACKAGE/libOpenCombine.dylib")"
        printf 'libSymbols\t%s\n' "$(hash_file "$PACKAGE/libSymbols.dylib")"
        printf 'SwiftUI-module\t%s\n' "$(hash_file "$PACKAGE/SwiftUI.swiftmodule")"
        printf 'Combine-module\t%s\n' "$(hash_file "$PACKAGE/Combine.swiftmodule")"
        printf 'OpenCombine-module\t%s\n' "$(hash_file "$PACKAGE/OpenCombine.swiftmodule")"
        printf 'Symbols-module\t%s\n' "$(hash_file "$PACKAGE/Symbols.swiftmodule")"
        printf 'package-tree\t%s\n' "$(tree_digest "$PACKAGE")"
        printf 'build-input-manifest\t%s\n' "$(hash_file "$BUILD_INPUT_MANIFEST")"
        printf 'runtime-closure-manifest\t%s\n' "$(hash_file "$RUNTIME_CLOSURE_MANIFEST")"
        printf 'resources\t%s\n' "$(tree_digest "$OUT/Focus_Widget.bundle")"
        printf 'system-font\t%s\n' "$(hash_file "$SYSTEM_FONT")"
        printf 'medium-font\t%s\n' "$(hash_file "$MEDIUM_FONT")"
        printf 'staged-system-font\t%s\n' "$(hash_file "$OUT/fonts/DejaVuSans.ttf")"
        printf 'staged-medium-font\t%s\n' "$(hash_file "$OUT/fonts/DejaVuSans-Bold.ttf")"
    } | hash_stream
}

# Materialize the verify tree from env/contract.json first. Not --strict:
# leftover unsatisfied rows still fail with this script's original wording
# (the 14 measured sequential refusals). Denominators print as
# ENV_PREPARE_SUMMARY. The only artifacts.sha256 field that includes this
# file's own bytes is SwiftUI-build-support-subject.
python3 "$PREPARE_TOOL" --contract "$W/env/contract.json" --root "$W" \
    --gate focus-widget || exit $?

assert_vendor_tree "$W" uikit "$UIKIT" "$EXPECTED_UIKIT_TREE" OpenUIKit
assert_vendor_tree "$W" machorun "$MACHORUN" "$EXPECTED_INREPO_MACHORUN_TREE" machorun
if vendor_is_inrepo "$W" uikit "$UIKIT"; then
    echo "focus_widget_guest: attested OpenUIKit source=HEAD:uikit tree=$EXPECTED_UIKIT_TREE"
else
    echo "focus_widget_guest: attested OpenUIKit source=checkout tree=$EXPECTED_UIKIT_TREE"
fi
if vendor_is_inrepo "$W" machorun "$MACHORUN"; then
    echo "focus_widget_guest: attested machorun source=HEAD:machorun tree=$EXPECTED_INREPO_MACHORUN_TREE"
else
    echo "focus_widget_guest: attested machorun source=checkout tree=$EXPECTED_INREPO_MACHORUN_TREE"
fi
[ "$(git -C "$FOCUS_REPO" rev-parse HEAD)" = "$EXPECTED_FOCUS_COMMIT" ] || {
    echo "focus_widget_guest: Focus revision is not pinned $EXPECTED_FOCUS_COMMIT" >&2; exit 2; }
focus_status_before=$(git -C "$FOCUS_REPO" status --porcelain=v1 --untracked-files=all)
[ -z "$focus_status_before" ] || {
    echo "focus_widget_guest: Focus checkout is not clean" >&2; exit 2; }
require_hash "$FOCUS_WIDGET/Assets.swift" "$EXPECTED_ASSETS_SHA" Assets.swift
require_hash "$FOCUS_WIDGET/SearchWidgetView.swift" "$EXPECTED_VIEW_SHA" SearchWidgetView.swift
require_hash "$RESOURCE_INPUT/resource-index.json" "$EXPECTED_INDEX_SHA" resource-index.json
require_hash "$RESOURCE_INPUT/icon_logo.png" "$EXPECTED_LOGO_SHA" icon_logo.png
require_hash "$RESOURCE_INPUT/Media.xcassets/GradientFirst.colorset/Contents.json" \
    "$EXPECTED_FIRST_SHA" GradientFirst.colorset
require_hash "$RESOURCE_INPUT/Media.xcassets/GradientSecond.colorset/Contents.json" \
    "$EXPECTED_SECOND_SHA" GradientSecond.colorset
require_hash "$SYSTEM_FONT" "$EXPECTED_SYSTEM_FONT_SHA" DejaVuSans.ttf
require_hash "$MEDIUM_FONT" "$EXPECTED_MEDIUM_FONT_SHA" DejaVuSans-Bold.ttf
require_hash "$OPENCOMBINE_ROOT/export/RESULT.txt" \
    "$EXPECTED_OPENCOMBINE_RESULT_SHA" OpenCombine-RESULT.txt
# Object/module SHAs pin the arm64 durable OpenCombine tree. Source hashes
# above/below still apply on every arch. On x86_64 the durable .o cannot be
# linked; refuse until OpenCombine is rebuilt for $TARGET beside the arm64
# artifacts. Do not rewrite the arm64 SHA to make an x86 run pass.
if [ "$ARCH" = arm64 ]; then
    require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" \
        "$EXPECTED_OPENCOMBINE_OBJECT_SHA" OpenCombine.o
    require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftmodule" \
        "$EXPECTED_OPENCOMBINE_MODULE_SHA" OpenCombine.swiftmodule
    require_hash "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftdoc" \
        "$EXPECTED_OPENCOMBINE_DOC_SHA" OpenCombine.swiftdoc
else
    if ! llvm-otool-18 -hv "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" 2>/dev/null \
        | grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}"; then
        echo "focus_widget_guest: NEEDS_X86_OPENCOMBINE: OpenCombine.o is not $ARCH" >&2
        echo "  arm64 durable SHA $EXPECTED_OPENCOMBINE_OBJECT_SHA still stands;" >&2
        echo "  rebuild OpenCombine for $TARGET beside that tree" >&2
        exit 2
    fi
fi
require_hash "$OPENCOMBINE_HELPERS/COpenCombineHelpers.cpp" \
    "$EXPECTED_OPENCOMBINE_HELPER_SHA" COpenCombineHelpers.cpp
require_hash "$OPENCOMBINE_HELPERS/include/COpenCombineHelpers.h" \
    "$EXPECTED_OPENCOMBINE_HEADER_SHA" COpenCombineHelpers.h
require_hash "$OPENCOMBINE_HELPERS/include/module.modulemap" \
    "$EXPECTED_OPENCOMBINE_MODULEMAP_SHA" COpenCombineHelpers-modulemap
require_hash "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch" \
    "$EXPECTED_OPENCOMBINE_PATCH_SHA" COpenCombineHelpers-patch
require_hash "$W/full/oracle-opencombine/Combine.swift" \
    "$EXPECTED_COMBINE_SHIM_SHA" Combine-shim

[ -d "$RESOURCE_INPUT" ] && [ ! -L "$RESOURCE_INPUT" ] || {
    echo "focus_widget_guest: resource input is not a real directory" >&2; exit 2; }
invalid_resource=$(find "$RESOURCE_INPUT" -mindepth 1 ! -type d ! -type f -print -quit)
[ -z "$invalid_resource" ] || {
    echo "focus_widget_guest: normalized bundle has a symlink/non-regular node: $invalid_resource" >&2
    exit 2
}
resource_file_count=$(find "$RESOURCE_INPUT" -type f | wc -l | tr -d '[:space:]')
[ "$resource_file_count" = "$EXPECTED_RESOURCE_FILE_COUNT" ] || {
    echo "focus_widget_guest: normalized bundle has $resource_file_count files, expected $EXPECTED_RESOURCE_FILE_COUNT" >&2
    exit 2
}
resource_directory_count=$(find "$RESOURCE_INPUT" -mindepth 1 -type d | wc -l | tr -d '[:space:]')
[ "$resource_directory_count" = "$EXPECTED_RESOURCE_DIRECTORY_COUNT" ] || {
    echo "focus_widget_guest: normalized bundle has $resource_directory_count directories, expected $EXPECTED_RESOURCE_DIRECTORY_COUNT" >&2
    exit 2
}
for directory in \
    Media.xcassets \
    Media.xcassets/GradientFirst.colorset \
    Media.xcassets/GradientSecond.colorset \
    images images/icon_logo symbols symbols/magnifyingglass; do
    [ -d "$RESOURCE_INPUT/$directory" ] && [ ! -L "$RESOURCE_INPUT/$directory" ] || {
        echo "focus_widget_guest: normalized bundle directory is missing: $directory" >&2
        exit 2
    }
done
resource_input_before=$(tree_digest "$RESOURCE_INPUT")
[ "$resource_input_before" = "$EXPECTED_RESOURCE_TREE_SHA" ] || {
    echo "focus_widget_guest: complete normalized bundle tree drifted: $resource_input_before" >&2
    exit 2
}

for required in \
    "${SWIFTUI_SOURCES[@]}" \
    "${SYMBOLS_SOURCES[@]}" \
    "$W/full/swiftui/FocusWidgetBundle.generated.swift" \
    "$W/full/swiftui/FocusWidgetGuestMain.swift" \
    "$ATTEST" \
    "$MACHORUN/build/machorun"; do
    [ -f "$required" ] || { echo "focus_widget_guest: missing $required" >&2; exit 2; }
done
support_before=$(support_digest)

# Rebuild the complete Foundation-hidden substrate from authoritative OpenUIKit
# before adding SwiftUI. The source checkout is mounted read-only at /uikit.
# SKIP_FULL_BUILD=1 exists only to resume after a post-link/proof-gate failure;
# the ordinary reproduction always rebuilds the substrate in this invocation.
skip_full_build=${SKIP_FULL_BUILD:-0}
if [ "$skip_full_build" != 1 ]; then
    bash "$W/full/scripts/build_full.sh"
    build_input_recording=$(mktemp "$FULL/.focus-widget-build-inputs.recording.XXXXXX")
    generate_build_input_inventory > "$build_input_recording"
    mv "$build_input_recording" "$BUILD_INPUT_MANIFEST"
else
    [ -f "$BUILD_INPUT_MANIFEST" ] && [ ! -L "$BUILD_INPUT_MANIFEST" ] || {
        echo "focus_widget_guest: SKIP_FULL_BUILD has no regular complete build-input manifest" >&2
        exit 2
    }
fi

assert_build_input_inventory
build_input_manifest_sha=$(hash_file "$BUILD_INPUT_MANIFEST")
build_input_node_count=$(grep -c '^node'"$(printf '\t')" "$BUILD_INPUT_MANIFEST")
[ "$build_input_node_count" -gt 900 ] || {
    echo "focus_widget_guest: complete build-input inventory is vacuous ($build_input_node_count nodes)" >&2
    exit 2
}

recorded_full_subject=$(tr -d '[:space:]' < "$FULL/uihelpers-subject.sha256")
current_full_subject=$(bash "$W/full/scripts/uihelpers_subject.sh" "$W" "$UIKIT")
[ "$recorded_full_subject" = "$current_full_subject" ] || {
    echo "focus_widget_guest: OpenUIKit substrate sources changed after build_full" >&2
    exit 2
}

rm -rf "$OUT"
rm -rf "$MC"
mkdir -p "$OUT/fonts" "$PACKAGE" "$AUDIT" "$MC" \
    "$PACKAGE/include/CPortableIO" \
    "$PACKAGE/include/CSTBTrueType" \
    "$PACKAGE/include/CHostClock" \
    "$PACKAGE/include/COpenCombineHelpers" \
    "$PACKAGE/include/CQuartz" \
    "$PACKAGE/include/_FoundationCShims" \
    "$PACKAGE/modules/FoundationEssentials" \
    "$PACKAGE/modules/Collections" \
    "$PACKAGE/modules/os"
cp -a "$RESOURCE_INPUT" "$OUT/Focus_Widget.bundle"
cp "$SYSTEM_FONT" "$OUT/fonts/DejaVuSans.ttf"
cp "$MEDIUM_FONT" "$OUT/fonts/DejaVuSans-Bold.ttf"
# FocusWidgetGuestMain.swift opens the docker-era guest-visible path
# /w/build/swiftui-guest/fonts regardless of FULL_OUT_SUFFIX. Stage fonts
# there (and under $W/build/swiftui-guest/fonts for a /w -> $W symlink)
# without touching arm64 Mach-O outputs.
HARNESS_FONT_DIR=$W/build/swiftui-guest/fonts
mkdir -p "$HARNESS_FONT_DIR"
[ "$OUT/fonts/DejaVuSans.ttf" -ef "$HARNESS_FONT_DIR/DejaVuSans.ttf" ] || cp -f "$OUT/fonts/DejaVuSans.ttf" "$HARNESS_FONT_DIR/"
[ "$OUT/fonts/DejaVuSans-Bold.ttf" -ef "$HARNESS_FONT_DIR/DejaVuSans-Bold.ttf" ] || cp -f "$OUT/fonts/DejaVuSans-Bold.ttf" "$HARNESS_FONT_DIR/"
if [ -d /w/build ] || mkdir -p /w/build/swiftui-guest/fonts 2>/dev/null; then
    mkdir -p /w/build/swiftui-guest/fonts
    [ "$OUT/fonts/DejaVuSans.ttf" -ef "/w/build/swiftui-guest/fonts/DejaVuSans.ttf" ] || cp -f "$OUT/fonts/DejaVuSans.ttf" "/w/build/swiftui-guest/fonts/"
    [ "$OUT/fonts/DejaVuSans-Bold.ttf" -ef "/w/build/swiftui-guest/fonts/DejaVuSans-Bold.ttf" ] || cp -f "$OUT/fonts/DejaVuSans-Bold.ttf" "/w/build/swiftui-guest/fonts/"
fi
for module in OpenUIKit OpenCoreGraphics; do
    for extension in swiftmodule swiftdoc swiftsourceinfo abi.json; do
        cp "$FULL/$module.$extension" "$PACKAGE/$module.$extension"
    done
done
cp -a "$FULL/inc/CPortableIO/." "$PACKAGE/include/CPortableIO/"
cp -a "$FULL/inc/CSTBTrueType/." "$PACKAGE/include/CSTBTrueType/"
cp -a "$W/full/hostclock/include/." "$PACKAGE/include/CHostClock/"
cp -a "$UIKIT/Sources/CQuartz/include/." "$PACKAGE/include/CQuartz/"
cp -a "$SWIFT_FOUNDATION/Sources/_FoundationCShims/include/." \
    "$PACKAGE/include/_FoundationCShims/"
for extension in swiftmodule swiftdoc swiftsourceinfo abi.json; do
    cp "$FE_OUT/FoundationEssentials.$extension" \
        "$PACKAGE/modules/FoundationEssentials/"
    cp "$FE_OS/os.$extension" "$PACKAGE/modules/os/"
    for module in InternalCollectionsUtilities OrderedCollections _RopeModule; do
        cp "$FE_COLLECTIONS/$module.$extension" "$PACKAGE/modules/Collections/"
    done
done
cp "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftmodule" \
    "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftdoc" "$PACKAGE/"
cp "$OPENCOMBINE_HELPERS/include/COpenCombineHelpers.h" \
    "$OPENCOMBINE_HELPERS/include/module.modulemap" \
    "$PACKAGE/include/COpenCombineHelpers/"
[ "$(tree_digest "$OUT/Focus_Widget.bundle")" = "$EXPECTED_RESOURCE_TREE_SHA" ] || {
    echo "focus_widget_guest: normalized bundle changed while staging" >&2; exit 2; }
require_hash "$OUT/fonts/DejaVuSans.ttf" "$EXPECTED_SYSTEM_FONT_SHA" staged-DejaVuSans.ttf
require_hash "$OUT/fonts/DejaVuSans-Bold.ttf" "$EXPECTED_MEDIUM_FONT_SHA" staged-DejaVuSans-Bold.ttf

SWIFTC=(swiftc -target "$TARGET" -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -wmo
        -Xfrontend -disable-implicit-string-processing-module-import
        -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch "$ARCH" -platform_version macos 15.0 15.0
    -syslibroot "$SYS" -rpath /usr/lib/swift)
CINC=(-Xcc -I"$FULL/inc/CPortableIO" -Xcc -I"$FULL/inc/CSTBTrueType"
      -Xcc -I"$W/full/hostclock/include"
      -Xcc -I"$UIKIT/Sources/CQuartz/include")
PACKAGE_CINC=(-Xcc -I"$PACKAGE/include/CPortableIO"
              -Xcc -I"$PACKAGE/include/CSTBTrueType"
              -Xcc -I"$PACKAGE/include/CHostClock"
              -Xcc -I"$PACKAGE/include/COpenCombineHelpers"
              -Xcc -I"$PACKAGE/include/CQuartz")
FE_FLAGS=(-I "$PACKAGE/modules/FoundationEssentials"
          -I "$PACKAGE/modules/Collections" -I "$PACKAGE/modules/os"
          -Xcc -fmodule-map-file="$PACKAGE/include/_FoundationCShims/module.modulemap"
          -Xcc -I"$PACKAGE/include/_FoundationCShims")
FE_OBJECTS=(
    "$FE_OUT/FoundationEssentials.o"
    "$FE_COLLECTIONS/InternalCollectionsUtilities.o"
    "$FE_COLLECTIONS/OrderedCollections.o"
    "$FE_COLLECTIONS/_RopeModule.o"
    "$FE_OS/os.o"
    "$FE_CSHIMS/platform_shims.o"
    "$FE_CSHIMS/string_shims.o"
    "$FE_CSHIMS/uuid.o"
    "$FE_OUT/fm_unimplemented.o"
    "$FE_OUT/uuid_compat.o"
)

# Repeat build_full's exact visibility contract at the SwiftUI boundary:
# Foundation stays hidden while the canonical FoundationEssentials module is
# present.  The checked-in guard replaced the obsolete generated output in
# d830e8e and is part of the complete resume inventory below.
"${SWIFTC[@]}" "${CINC[@]}" "${FE_FLAGS[@]}" -typecheck \
    -module-name SwiftUIFoundationVisibility \
    "$W/full/foundation/foundationessentials_import_guard.swift"

# A cold cache must build the SDK's textual Swift module before recursively
# importing the pinned binary OpenCombine module's _Concurrency dependency.
swiftc -target "$TARGET" -sdk "$SYS" \
    -module-cache-path "$MC" -parse-stdlib -typecheck -e 'import Swift'

echo "== package source-built OpenCombine core as a sibling dylib"
cp "$OPENCOMBINE_HELPERS/COpenCombineHelpers.cpp" \
    "$OUT/COpenCombineHelpers.original.cpp"
cp "$OPENCOMBINE_HELPERS/COpenCombineHelpers.cpp" \
    "$OUT/COpenCombineHelpers.cpp"
patch --batch --forward --fuzz=0 "$OUT/COpenCombineHelpers.cpp" \
    "$W/full/oracle-opencombine/patches/COpenCombineHelpers-pthread-recursive.patch"
require_hash "$OUT/COpenCombineHelpers.cpp" \
    "$EXPECTED_OPENCOMBINE_PATCHED_HELPER_SHA" patched-COpenCombineHelpers.cpp
clang++-18 -target "$TARGET" -isysroot "$SYS" \
    -stdlib=libc++ -std=c++17 -O2 -I "$PACKAGE/include/COpenCombineHelpers" \
    -c "$OUT/COpenCombineHelpers.cpp" -o "$OUT/copencombinehelpers.o"
"${LD[@]}" -dylib -install_name @rpath/libOpenCombine.dylib \
    -rpath @loader_path -ignore_auto_link -dead_strip \
    -map "$AUDIT/libOpenCombine.link-map" \
    -o "$PACKAGE/libOpenCombine.dylib" \
    "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" "$OUT/copencombinehelpers.o" \
    "$SYS/usr/lib/swift/libswift_Concurrency.tbd" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$MRROOT/darwin/usr/lib/libc++abi.dylib" \
    "$SYS/usr/lib/libSystem.tbd" "$MRROOT/darwin/usr/lib/libSystem.real.dylib" \
    "$SYS/usr/lib/libobjc.tbd"

echo "== package literal Combine re-export shim as a sibling dylib"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" \
    -module-name Combine -emit-module -emit-module-path "$PACKAGE/Combine.swiftmodule" \
    -emit-object -o "$OUT/combine.o" \
    "$W/full/oracle-opencombine/Combine.swift"
"${LD[@]}" -dylib -install_name @rpath/libCombine.dylib \
    -rpath @loader_path -ignore_auto_link -dead_strip \
    -reexport_library "$PACKAGE/libOpenCombine.dylib" \
    -map "$AUDIT/libCombine.link-map" \
    -o "$PACKAGE/libCombine.dylib" "$OUT/combine.o" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" "$SYS/usr/lib/libSystem.tbd"

echo "== compile the first-party Symbols value model while Foundation is hidden"
"${SWIFTC[@]}" -parse-as-library \
    -I "$PACKAGE" \
    -module-name Symbols -module-link-name Symbols \
    -emit-module -emit-module-path "$PACKAGE/Symbols.swiftmodule" \
    -emit-object -o "$OUT/symbols.o" \
    "${SYMBOLS_SOURCES[@]}"
"${LD[@]}" -dylib -install_name @rpath/libSymbols.dylib \
    -rpath @loader_path -ignore_auto_link -dead_strip \
    -map "$AUDIT/libSymbols.link-map" \
    -o "$PACKAGE/libSymbols.dylib" "$OUT/symbols.o" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    "$SYS/usr/lib/libSystem.tbd"
symbols_apple_load_count=$(llvm-otool-18 -L "$PACKAGE/libSymbols.dylib" \
    | awk '$1 ~ /^\/System\/Library\/Frameworks\/Symbols\.framework\// { count++ } \
        END { print count + 0 }')
[ "$symbols_apple_load_count" -eq 0 ] \
    || die "libSymbols Apple Symbols load count $symbols_apple_load_count, expected 0"

echo "== SwiftUI (complete authoritative sources; Foundation hidden)"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" \
    -module-name SwiftUI -emit-module -emit-module-path "$PACKAGE/SwiftUI.swiftmodule" \
    -emit-object -o "$OUT/swiftui.o" \
    "${SWIFTUI_SOURCES[@]}"

echo "== FocusWidget (two pinned app sources direct from clean checkout)"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -I "$OUT" \
    -module-name FocusWidget \
    -emit-module -emit-module-path "$OUT/FocusWidget.swiftmodule" \
    -emit-object -o "$OUT/focuswidget.o" \
    "$FOCUS_WIDGET/Assets.swift" \
    "$FOCUS_WIDGET/SearchWidgetView.swift" \
    "$W/full/swiftui/FocusWidgetBundle.generated.swift"

echo "== guest harness (project-owned, separate from Focus sources)"
"${SWIFTC[@]}" -parse-as-library "${PACKAGE_CINC[@]}" "${FE_FLAGS[@]}" \
    -I "$PACKAGE" -I "$OUT" \
    -module-name FocusWidgetGuest -emit-object -o "$OUT/guest-main.o" \
    "$W/full/swiftui/FocusWidgetGuestMain.swift"

echo "== package FoundationEssentials and OpenCoreGraphics dependencies"
"${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libFoundationEssentials.dylib -rpath @loader_path \
    -L"$MRROOT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -map "$AUDIT/libFoundationEssentials.link-map" \
    -o "$PACKAGE/libFoundationEssentials.dylib" \
    "${FE_OBJECTS[@]}" "$FULL/swiftcorepatch.o"
"${LD[@]}" -dylib -dead_strip \
    -install_name @rpath/libOpenCoreGraphics.dylib -rpath @loader_path \
    -L"$MRROOT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -map "$AUDIT/libOpenCoreGraphics.link-map" \
    -o "$PACKAGE/libOpenCoreGraphics.dylib" "$FULL/opencoregraphics.o"

echo "== package OpenUIKit as SwiftUI's UI framework dependency"
"${LD[@]}" -dylib -install_name @rpath/libOpenUIKit.dylib -rpath @loader_path \
    -L"$PACKAGE" -lFoundationEssentials -lOpenCoreGraphics \
    -L"$MRROOT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -map "$AUDIT/libOpenUIKit.link-map" -o "$PACKAGE/libOpenUIKit.dylib" \
    "$FULL/openuikit.o" \
    "$FULL/cportableio.o" "$FULL/cstbtruetype.o" "$FULL/hostclock.o" \
    "$FULL/swiftcorepatch.o"

echo "== package reusable libSwiftUI.dylib"
"${LD[@]}" -dylib -install_name @rpath/libSwiftUI.dylib -rpath @loader_path \
    -L"$PACKAGE" -lOpenUIKit -lOpenCoreGraphics -lCombine -lOpenCombine -lSymbols -lFoundationEssentials \
    -L"$MRROOT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -map "$AUDIT/libSwiftUI.link-map" \
    -o "$PACKAGE/libSwiftUI.dylib" "$OUT/swiftui.o"

echo "== link Mach-O against packaged dylibs (no framework objects)"
"${LD[@]}" -exported_symbol __mh_execute_header \
    -rpath @loader_path/package \
    -L"$PACKAGE" -lSwiftUI -lOpenUIKit -lFoundationEssentials \
    -lOpenCoreGraphics -lSymbols \
    -L"$MRROOT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -map "$AUDIT/focus_widget_guest.link-map" -o "$OUT/focus_widget_guest" \
    "$OUT/guest-main.o" "$OUT/focuswidget.o"

llvm-otool-18 -hv "$PACKAGE/libOpenUIKit.dylib" | \
    grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}.*[[:space:]]DYLIB" || {
    echo "focus_widget_guest: libOpenUIKit is not a $ARCH Mach-O dylib" >&2; exit 2; }
llvm-otool-18 -hv "$PACKAGE/libFoundationEssentials.dylib" | \
    grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}.*[[:space:]]DYLIB" || {
    echo "focus_widget_guest: libFoundationEssentials is not a $ARCH Mach-O dylib" >&2; exit 2; }
llvm-otool-18 -hv "$PACKAGE/libOpenCoreGraphics.dylib" | \
    grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}.*[[:space:]]DYLIB" || {
    echo "focus_widget_guest: libOpenCoreGraphics is not a $ARCH Mach-O dylib" >&2; exit 2; }
llvm-otool-18 -hv "$PACKAGE/libSwiftUI.dylib" | \
    grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}.*[[:space:]]DYLIB" || {
    echo "focus_widget_guest: libSwiftUI is not a $ARCH Mach-O dylib" >&2; exit 2; }
llvm-otool-18 -hv "$PACKAGE/libCombine.dylib" | \
    grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}.*[[:space:]]DYLIB" || {
    echo "focus_widget_guest: libCombine is not a $ARCH Mach-O dylib" >&2; exit 2; }
llvm-otool-18 -hv "$PACKAGE/libOpenCombine.dylib" | \
    grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}.*[[:space:]]DYLIB" || {
    echo "focus_widget_guest: libOpenCombine is not a $ARCH Mach-O dylib" >&2; exit 2; }
llvm-otool-18 -hv "$PACKAGE/libSymbols.dylib" | \
    grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}.*[[:space:]]DYLIB" || {
    echo "focus_widget_guest: libSymbols is not a $ARCH Mach-O dylib" >&2; exit 2; }
llvm-otool-18 -hv "$OUT/focus_widget_guest" | \
    grep -Eq "MH_MAGIC_64[[:space:]]+${OTOOL_CPU}.*[[:space:]]EXECUTE" || {
    echo "focus_widget_guest: link output is not $ARCH Mach-O" >&2; exit 2; }

# Close the compile/link bracket before any package byte is compared with its
# build/full origin.  Those origins are therefore an attested cache, not a
# self-selected cache that the package can merely agree with.
assert_build_input_inventory

load_paths() {
    llvm-otool-18 -L "$1" | tail -n +2 | \
        sed -E 's/^[[:space:]]*//; s/[[:space:]]+\(compatibility version.*$//'
}
rpaths() {
    llvm-otool-18 -l "$1" | awk '
        $1 == "cmd" && $2 == "LC_RPATH" { getline; getline; print $2 }
    '
}
assert_exact_text() {
    local label=$1 got=$2 expected=$3
    [ "$got" = "$expected" ] || {
        echo "focus_widget_guest: $label changed" >&2
        diff -u <(printf '%s\n' "$expected") <(printf '%s\n' "$got") >&2 || true
        exit 2
    }
}
link_map_inputs() {
    awk '
        /^# Object files:/ { in_inputs = 1; next }
        /^# Sections:/ { in_inputs = 0 }
        in_inputs { sub(/^\[[^]]+\][[:space:]]+/, ""); print }
    ' "$1"
}

invalid_package=$(find "$PACKAGE" -mindepth 1 ! -type d ! -type f -print -quit)
[ -z "$invalid_package" ] || {
    echo "focus_widget_guest: package has a symlink/non-regular node: $invalid_package" >&2
    exit 2
}
package_file_count=$(find "$PACKAGE" -type f | wc -l | tr -d '[:space:]')
[ "$package_file_count" = "$EXPECTED_PACKAGE_FILE_COUNT" ] || {
    echo "focus_widget_guest: package has $package_file_count files, expected $EXPECTED_PACKAGE_FILE_COUNT" >&2
    exit 2
}
package_directory_count=$(find "$PACKAGE" -mindepth 1 -type d | wc -l | tr -d '[:space:]')
[ "$package_directory_count" = "$EXPECTED_PACKAGE_DIRECTORY_COUNT" ] || {
    echo "focus_widget_guest: package has $package_directory_count directories, expected $EXPECTED_PACKAGE_DIRECTORY_COUNT" >&2
    exit 2
}
expected_package_names=$(printf '%s\n' \
    Combine.abi.json \
    Combine.swiftdoc \
    Combine.swiftmodule \
    Combine.swiftsourceinfo \
    OpenCombine.swiftdoc \
    OpenCombine.swiftmodule \
    OpenCoreGraphics.abi.json \
    OpenCoreGraphics.swiftdoc \
    OpenCoreGraphics.swiftmodule \
    OpenCoreGraphics.swiftsourceinfo \
    OpenUIKit.abi.json \
    OpenUIKit.swiftdoc \
    OpenUIKit.swiftmodule \
    OpenUIKit.swiftsourceinfo \
    SwiftUI.abi.json \
    SwiftUI.swiftdoc \
    SwiftUI.swiftmodule \
    SwiftUI.swiftsourceinfo \
    Symbols.abi.json \
    Symbols.swiftdoc \
    Symbols.swiftmodule \
    Symbols.swiftsourceinfo \
    libCombine.dylib \
    libFoundationEssentials.dylib \
    libOpenCombine.dylib \
    libOpenCoreGraphics.dylib \
    libOpenUIKit.dylib \
    libSwiftUI.dylib \
    libSymbols.dylib)
actual_package_names=$(find "$PACKAGE" -maxdepth 1 -type f -exec basename {} \; | LC_ALL=C sort)
assert_exact_text "package top-level inventory" "$actual_package_names" "$expected_package_names"
expected_package_directories=$(printf '%s\n' \
    include \
    include/CHostClock \
    include/COpenCombineHelpers \
    include/CPortableIO \
    include/CQuartz \
    include/CQuartz/quartz \
    include/CSTBTrueType \
    include/_FoundationCShims \
    modules \
    modules/Collections \
    modules/FoundationEssentials \
    modules/os)
actual_package_directories=$(find "$PACKAGE" -mindepth 1 -type d | \
    sed "s#^$PACKAGE/##" | LC_ALL=C sort)
assert_exact_text "package directory inventory" \
    "$actual_package_directories" "$expected_package_directories"
expected_fe_module_files=$(printf '%s\n' \
    Collections/InternalCollectionsUtilities.abi.json \
    Collections/InternalCollectionsUtilities.swiftdoc \
    Collections/InternalCollectionsUtilities.swiftmodule \
    Collections/InternalCollectionsUtilities.swiftsourceinfo \
    Collections/OrderedCollections.abi.json \
    Collections/OrderedCollections.swiftdoc \
    Collections/OrderedCollections.swiftmodule \
    Collections/OrderedCollections.swiftsourceinfo \
    Collections/_RopeModule.abi.json \
    Collections/_RopeModule.swiftdoc \
    Collections/_RopeModule.swiftmodule \
    Collections/_RopeModule.swiftsourceinfo \
    FoundationEssentials/FoundationEssentials.abi.json \
    FoundationEssentials/FoundationEssentials.swiftdoc \
    FoundationEssentials/FoundationEssentials.swiftmodule \
    FoundationEssentials/FoundationEssentials.swiftsourceinfo \
    os/os.abi.json \
    os/os.swiftdoc \
    os/os.swiftmodule \
    os/os.swiftsourceinfo)
actual_fe_module_files=$(find "$PACKAGE/modules" -type f | \
    sed "s#^$PACKAGE/modules/##" | LC_ALL=C sort)
assert_exact_text "FoundationEssentials module inventory" \
    "$actual_fe_module_files" "$expected_fe_module_files"
for module in OpenUIKit OpenCoreGraphics; do
    for extension in swiftmodule swiftdoc swiftsourceinfo abi.json; do
        cmp -s "$FULL/$module.$extension" "$PACKAGE/$module.$extension" || {
            echo "focus_widget_guest: packaged $module.$extension differs from build_full" >&2
            exit 2
        }
    done
done
for extension in swiftmodule swiftdoc swiftsourceinfo abi.json; do
    cmp -s "$FE_OUT/FoundationEssentials.$extension" \
        "$PACKAGE/modules/FoundationEssentials/FoundationEssentials.$extension" || {
        echo "focus_widget_guest: packaged FoundationEssentials.$extension drifted" >&2
        exit 2
    }
    cmp -s "$FE_OS/os.$extension" "$PACKAGE/modules/os/os.$extension" || {
        echo "focus_widget_guest: packaged os.$extension drifted" >&2; exit 2; }
    for module in InternalCollectionsUtilities OrderedCollections _RopeModule; do
        cmp -s "$FE_COLLECTIONS/$module.$extension" \
            "$PACKAGE/modules/Collections/$module.$extension" || {
            echo "focus_widget_guest: packaged $module.$extension drifted" >&2
            exit 2
        }
    done
done
[ "$(tree_digest "$PACKAGE/include/CPortableIO")" = \
    "$(tree_digest "$FULL/inc/CPortableIO")" ] || {
    echo "focus_widget_guest: packaged CPortableIO headers drifted" >&2; exit 2; }
[ "$(tree_digest "$PACKAGE/include/CSTBTrueType")" = \
    "$(tree_digest "$FULL/inc/CSTBTrueType")" ] || {
    echo "focus_widget_guest: packaged CSTBTrueType headers drifted" >&2; exit 2; }
[ "$(tree_digest "$PACKAGE/include/CHostClock")" = \
    "$(tree_digest "$W/full/hostclock/include")" ] || {
    echo "focus_widget_guest: packaged CHostClock headers drifted" >&2; exit 2; }
[ "$(tree_digest "$PACKAGE/include/CQuartz")" = \
    "$(tree_digest "$UIKIT/Sources/CQuartz/include")" ] || {
    echo "focus_widget_guest: packaged CQuartz headers drifted" >&2; exit 2; }
[ "$(tree_digest "$PACKAGE/include/_FoundationCShims")" = \
    "$(tree_digest "$SWIFT_FOUNDATION/Sources/_FoundationCShims/include")" ] || {
    echo "focus_widget_guest: packaged Foundation C shim headers drifted" >&2; exit 2; }
[ "$(tree_digest "$PACKAGE/include/COpenCombineHelpers")" = \
    "$(tree_digest "$OPENCOMBINE_HELPERS/include")" ] || {
    echo "focus_widget_guest: packaged COpenCombineHelpers headers drifted" >&2; exit 2; }
cmp -s "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftmodule" \
    "$PACKAGE/OpenCombine.swiftmodule" || {
    echo "focus_widget_guest: packaged OpenCombine.swiftmodule drifted" >&2; exit 2; }
cmp -s "$OPENCOMBINE_ARTIFACTS/OpenCombine.swiftdoc" \
    "$PACKAGE/OpenCombine.swiftdoc" || {
    echo "focus_widget_guest: packaged OpenCombine.swiftdoc drifted" >&2; exit 2; }
package_tree_before=$(tree_digest "$PACKAGE")

assert_exact_text "libOpenCombine LC_ID_DYLIB" \
    "$(llvm-otool-18 -D "$PACKAGE/libOpenCombine.dylib" | tail -n 1)" \
    '@rpath/libOpenCombine.dylib'
assert_exact_text "libCombine LC_ID_DYLIB" \
    "$(llvm-otool-18 -D "$PACKAGE/libCombine.dylib" | tail -n 1)" \
    '@rpath/libCombine.dylib'
assert_exact_text "libOpenUIKit LC_ID_DYLIB" \
    "$(llvm-otool-18 -D "$PACKAGE/libOpenUIKit.dylib" | tail -n 1)" \
    '@rpath/libOpenUIKit.dylib'
assert_exact_text "libFoundationEssentials LC_ID_DYLIB" \
    "$(llvm-otool-18 -D "$PACKAGE/libFoundationEssentials.dylib" | tail -n 1)" \
    '@rpath/libFoundationEssentials.dylib'
assert_exact_text "libOpenCoreGraphics LC_ID_DYLIB" \
    "$(llvm-otool-18 -D "$PACKAGE/libOpenCoreGraphics.dylib" | tail -n 1)" \
    '@rpath/libOpenCoreGraphics.dylib'
assert_exact_text "libSwiftUI LC_ID_DYLIB" \
    "$(llvm-otool-18 -D "$PACKAGE/libSwiftUI.dylib" | tail -n 1)" \
    '@rpath/libSwiftUI.dylib'
assert_exact_text "libSymbols LC_ID_DYLIB" \
    "$(llvm-otool-18 -D "$PACKAGE/libSymbols.dylib" | tail -n 1)" \
    '@rpath/libSymbols.dylib'
assert_exact_text "libOpenUIKit LC_RPATH set" \
    "$(rpaths "$PACKAGE/libOpenUIKit.dylib")" \
    "$(printf '%s\n' /usr/lib/swift @loader_path)"
assert_exact_text "libFoundationEssentials LC_RPATH set" \
    "$(rpaths "$PACKAGE/libFoundationEssentials.dylib")" \
    "$(printf '%s\n' /usr/lib/swift @loader_path)"
assert_exact_text "libOpenCoreGraphics LC_RPATH set" \
    "$(rpaths "$PACKAGE/libOpenCoreGraphics.dylib")" \
    "$(printf '%s\n' /usr/lib/swift @loader_path)"
assert_exact_text "libSwiftUI LC_RPATH set" \
    "$(rpaths "$PACKAGE/libSwiftUI.dylib")" \
    "$(printf '%s\n' /usr/lib/swift @loader_path)"
assert_exact_text "libOpenCombine LC_RPATH set" \
    "$(rpaths "$PACKAGE/libOpenCombine.dylib")" \
    "$(printf '%s\n' /usr/lib/swift @loader_path)"
assert_exact_text "libCombine LC_RPATH set" \
    "$(rpaths "$PACKAGE/libCombine.dylib")" \
    "$(printf '%s\n' /usr/lib/swift @loader_path)"
assert_exact_text "libSymbols LC_RPATH set" \
    "$(rpaths "$PACKAGE/libSymbols.dylib")" \
    "$(printf '%s\n' /usr/lib/swift @loader_path)"
assert_exact_text "guest LC_RPATH set" \
    "$(rpaths "$OUT/focus_widget_guest")" \
    "$(printf '%s\n' /usr/lib/swift @loader_path/package)"

expected_openuikit_loads=$(printf '%s\n' \
    @rpath/libOpenUIKit.dylib \
    @rpath/libFoundationEssentials.dylib \
    @rpath/libOpenCoreGraphics.dylib \
    /usr/lib/swift/libswiftCore.dylib \
    /usr/lib/libswiftcompat.dylib \
    /usr/lib/libSystem.B.dylib \
    /usr/lib/libobjc.A.dylib \
    /usr/lib/libquartz.dylib \
    /usr/lib/swift/libswift_Concurrency.dylib \
    /usr/lib/swift/libswiftObjectiveC.dylib \
    /usr/lib/swift/libswift_errno.dylib)
expected_foundationessentials_loads=$(printf '%s\n' \
    @rpath/libFoundationEssentials.dylib \
    /usr/lib/swift/libswiftCore.dylib \
    /usr/lib/libswiftcompat.dylib \
    /usr/lib/libSystem.B.dylib \
    /usr/lib/swift/libswiftDarwin.dylib \
    /usr/lib/swift/libswift_StringProcessing.dylib \
    /usr/lib/swift/libswiftSynchronization.dylib \
    /usr/lib/libobjc.A.dylib \
    /usr/lib/swift/libswift_errno.dylib)
expected_opencoregraphics_loads=$(printf '%s\n' \
    @rpath/libOpenCoreGraphics.dylib \
    /usr/lib/swift/libswiftCore.dylib \
    /usr/lib/libswiftcompat.dylib \
    /usr/lib/libSystem.B.dylib \
    /usr/lib/libquartz.dylib \
    /usr/lib/libobjc.A.dylib)
expected_swiftui_loads=$(printf '%s\n' \
    @rpath/libSwiftUI.dylib \
    @rpath/libOpenUIKit.dylib \
    @rpath/libOpenCoreGraphics.dylib \
    @rpath/libCombine.dylib \
    @rpath/libOpenCombine.dylib \
    @rpath/libSymbols.dylib \
    @rpath/libFoundationEssentials.dylib \
    /usr/lib/swift/libswiftCore.dylib \
    /usr/lib/libswiftcompat.dylib \
    /usr/lib/libSystem.B.dylib \
    /usr/lib/libobjc.A.dylib \
    /usr/lib/libquartz.dylib \
    /usr/lib/swift/libswift_Concurrency.dylib \
    /usr/lib/swift/libswiftObjectiveC.dylib \
    /usr/lib/swift/libswiftObservation.dylib)
expected_opencombine_loads=$(printf '%s\n' \
    @rpath/libOpenCombine.dylib \
    /usr/lib/swift/libswift_Concurrency.dylib \
    /usr/lib/swift/libswiftCore.dylib \
    /usr/lib/libc++abi.dylib \
    /usr/lib/libSystem.B.dylib \
    /usr/lib/libSystem.real.dylib \
    /usr/lib/libobjc.A.dylib)
expected_combine_loads=$(printf '%s\n' \
    @rpath/libCombine.dylib \
    @rpath/libOpenCombine.dylib \
    @rpath/libOpenCombine.dylib \
    /usr/lib/swift/libswiftCore.dylib \
    /usr/lib/libSystem.B.dylib)
expected_symbols_loads=$(printf '%s\n' \
    @rpath/libSymbols.dylib \
    /usr/lib/swift/libswiftCore.dylib \
    /usr/lib/libswiftcompat.dylib \
    /usr/lib/libSystem.B.dylib)
expected_guest_loads=$(printf '%s\n' \
    @rpath/libSwiftUI.dylib \
    @rpath/libOpenUIKit.dylib \
    @rpath/libFoundationEssentials.dylib \
    @rpath/libOpenCoreGraphics.dylib \
    @rpath/libSymbols.dylib \
    /usr/lib/swift/libswiftCore.dylib \
    /usr/lib/libswiftcompat.dylib \
    /usr/lib/libSystem.B.dylib \
    /usr/lib/libobjc.A.dylib \
    /usr/lib/libquartz.dylib \
    /usr/lib/swift/libswiftObjectiveC.dylib)
assert_exact_text "libOpenUIKit dylib loads" \
    "$(load_paths "$PACKAGE/libOpenUIKit.dylib")" "$expected_openuikit_loads"
assert_exact_text "libFoundationEssentials dylib loads" \
    "$(load_paths "$PACKAGE/libFoundationEssentials.dylib")" \
    "$expected_foundationessentials_loads"
assert_exact_text "libOpenCoreGraphics dylib loads" \
    "$(load_paths "$PACKAGE/libOpenCoreGraphics.dylib")" \
    "$expected_opencoregraphics_loads"
assert_exact_text "libSwiftUI dylib loads" \
    "$(load_paths "$PACKAGE/libSwiftUI.dylib")" "$expected_swiftui_loads"
assert_exact_text "libOpenCombine dylib loads" \
    "$(load_paths "$PACKAGE/libOpenCombine.dylib")" "$expected_opencombine_loads"
assert_exact_text "libCombine dylib loads" \
    "$(load_paths "$PACKAGE/libCombine.dylib")" "$expected_combine_loads"
assert_exact_text "libSymbols dylib loads" \
    "$(load_paths "$PACKAGE/libSymbols.dylib")" "$expected_symbols_loads"
assert_exact_text "guest dylib loads" \
    "$(load_paths "$OUT/focus_widget_guest")" "$expected_guest_loads"

for binary in \
    "$PACKAGE/libOpenCombine.dylib" \
    "$PACKAGE/libCombine.dylib" \
    "$PACKAGE/libFoundationEssentials.dylib" \
    "$PACKAGE/libOpenCoreGraphics.dylib" \
    "$PACKAGE/libOpenUIKit.dylib" \
    "$PACKAGE/libSwiftUI.dylib" \
    "$PACKAGE/libSymbols.dylib" \
    "$OUT/focus_widget_guest"; do
    llvm-otool-18 -l "$binary" > "$AUDIT/$(basename "$binary").load-commands"
    if load_paths "$binary" | grep -Eq \
        'Foundation\.framework|SwiftUI\.framework|SwiftUICore\.framework|/usr/lib/swift/lib(SwiftUI|SwiftUICore|Foundation)\.dylib|@rpath/lib(SwiftUICore|Foundation)\.dylib'; then
        echo "focus_widget_guest: an Apple Foundation/SwiftUI/SwiftUICore load leaked into $(basename "$binary")" >&2
        exit 2
    fi
done

llvm-nm-18 -gj --defined-only "$PACKAGE/libOpenUIKit.dylib" \
    > "$AUDIT/libOpenUIKit.defined"
llvm-nm-18 -gj --defined-only "$PACKAGE/libOpenCoreGraphics.dylib" \
    > "$AUDIT/libOpenCoreGraphics.defined"
llvm-nm-18 -gj --defined-only "$PACKAGE/libSwiftUI.dylib" \
    > "$AUDIT/libSwiftUI.defined"
llvm-nm-18 -gj --defined-only "$OUT/focus_widget_guest" \
    > "$AUDIT/focus_widget_guest.defined"
llvm-nm-18 -u "$PACKAGE/libOpenUIKit.dylib" \
    > "$AUDIT/libOpenUIKit.undefined"
llvm-nm-18 -u "$PACKAGE/libOpenCoreGraphics.dylib" \
    > "$AUDIT/libOpenCoreGraphics.undefined"
llvm-nm-18 -u "$PACKAGE/libSwiftUI.dylib" \
    > "$AUDIT/libSwiftUI.undefined"
llvm-nm-18 -u "$OUT/focus_widget_guest" \
    > "$AUDIT/focus_widget_guest.undefined"
llvm-objdump-18 --macho --bind "$PACKAGE/libOpenUIKit.dylib" \
    > "$AUDIT/libOpenUIKit.bind"
llvm-objdump-18 --macho --bind "$PACKAGE/libOpenCoreGraphics.dylib" \
    > "$AUDIT/libOpenCoreGraphics.bind"
llvm-objdump-18 --macho --bind "$PACKAGE/libSwiftUI.dylib" \
    > "$AUDIT/libSwiftUI.bind"
llvm-objdump-18 --macho --bind "$OUT/focus_widget_guest" \
    > "$AUDIT/focus_widget_guest.bind"

# Universal, non-vacuous two-level provider gate. Every symbol owned by
# SwiftUI, OpenUIKit, OpenCoreGraphics, or FoundationEssentials is classified,
# including associated type descriptors, conformances, and extensions whose
# mangling does not begin with its declaring module. Unknown framework-bearing
# manglings fail closed.
# Every import is matched to every bind-table row and the exact defining
# sibling; every definition is checked for reverse ownership.
perl "$ATTEST" providers --nm llvm-nm-18 --objdump llvm-objdump-18 \
    --demangle swift-demangle \
    --openuikit "$PACKAGE/libOpenUIKit.dylib" \
    --opencoregraphics "$PACKAGE/libOpenCoreGraphics.dylib" \
    --swiftui "$PACKAGE/libSwiftUI.dylib" \
    --foundationessentials "$PACKAGE/libFoundationEssentials.dylib" \
    --combine "$PACKAGE/libCombine.dylib" \
    --opencombine "$PACKAGE/libOpenCombine.dylib" \
    --executable "$OUT/focus_widget_guest" \
    > "$AUDIT/framework-providers.tsv"
grep -Fqx $'import\texecutable\tSwiftUI\tlibSwiftUI\t_$sxSg7SwiftUI9_OpenViewA2bCRzlMc' \
    "$AUDIT/framework-providers.tsv" || {
    echo "focus_widget_guest: non-prefix SwiftUI conformance import escaped provider audit" >&2
    exit 2
}
grep -Fqx $'definition\tlibSwiftUI\tSwiftUI\t_$s4Body7SwiftUI9_OpenViewPTl' \
    "$AUDIT/framework-providers.tsv" || {
    echo "focus_widget_guest: non-prefix SwiftUI associated-type definition escaped ownership audit" >&2
    exit 2
}
grep -Fqx $'definition\tlibOpenUIKit\tOpenUIKit\t_$s10ObjectiveC8SelectorV9OpenUIKitE10actionNameSSvg' \
    "$AUDIT/framework-providers.tsv" || {
    echo "focus_widget_guest: non-prefix OpenUIKit extension definition escaped ownership audit" >&2
    exit 2
}
grep -Fqx $'definition\tlibOpenUIKit\tOpenUIKit\t_OBJC_CLASS_$__TtC9OpenUIKit11UITextRange' \
    "$AUDIT/framework-providers.tsv" || {
    echo "focus_widget_guest: canonical Swift ObjC class escaped ownership audit" >&2
    exit 2
}
foreign_extension='_$s16OpenCoreGraphics6CGRectV0A5UIKitE5inset2byAcD12UIEdgeInsetsV_tF'
grep -Fqx $'definition\tlibOpenUIKit\tOpenUIKit\t'"$foreign_extension" \
    "$AUDIT/framework-providers.tsv" || {
    echo "focus_widget_guest: foreign-type extension escaped definition ownership audit" >&2
    exit 2
}
grep -Fqx $'import\tlibSwiftUI\tOpenUIKit\tlibOpenUIKit\t'"$foreign_extension" \
    "$AUDIT/framework-providers.tsv" || {
    echo "focus_widget_guest: foreign-type extension escaped provider audit" >&2
    exit 2
}
# Swift 6 lowers CALayer's MainActor-isolated deinit through
# `pthread_main_np`. The deliberately narrow sysroot TBD does not advertise
# that compatibility entry point; the project-owned libSystem umbrella does,
# and is already the image behind the exact /usr/lib/libSystem.B.dylib load.
# Keep the physical provider explicit in the link-input allowlist.
expected_openuikit_inputs=$(printf '%s\n' \
    'linker synthesized' \
    "$PACKAGE/libFoundationEssentials.dylib" \
    "$PACKAGE/libOpenCoreGraphics.dylib" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$SYS/usr/lib/libSystem.tbd" \
    "$SYS/usr/lib/libobjc.tbd" \
    "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    "$FULL/openuikit.o" \
    "$FULL/cportableio.o" \
    "$FULL/cstbtruetype.o" \
    "$FULL/hostclock.o" \
    "$FULL/swiftcorepatch.o" \
    "$SYS/usr/lib/swift/libswift_Concurrency.tbd" \
    "$SYS/usr/lib/swift/libswiftObjectiveC.tbd")
expected_foundationessentials_inputs=$(printf '%s\n' \
    'linker synthesized' \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    "$SYS/usr/lib/libSystem.tbd" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    "$FE_OUT/FoundationEssentials.o" \
    "$FE_COLLECTIONS/InternalCollectionsUtilities.o" \
    "$FE_COLLECTIONS/OrderedCollections.o" \
    "$FE_COLLECTIONS/_RopeModule.o" \
    "$FE_OS/os.o" \
    "$FE_CSHIMS/platform_shims.o" \
    "$FE_CSHIMS/string_shims.o" \
    "$FE_CSHIMS/uuid.o" \
    "$FE_OUT/fm_unimplemented.o" \
    "$FE_OUT/uuid_compat.o" \
    "$FULL/swiftcorepatch.o" \
    "$SYS/usr/lib/swift/libswiftDarwin.tbd" \
    "$SYS/usr/lib/swift/libswift_StringProcessing.tbd" \
    "$SYS/usr/lib/swift/libswiftSynchronization.tbd" \
    "$SYS/usr/lib/libobjc.tbd")
# libSystem.B.dylib (mrroot) resolves _remquo and _nan for
# OpenCoreGraphics/PortableCGFloat.swift's CGFloat remquo(_:_:) / nan(_:)
# wrappers: the sysroot libSystem.tbd re-exports libsystem_m, but the sysroot
# carries no usr/lib/system/*.tbd to follow, so lld binds the real image --
# the same image the loader maps for /usr/lib/libSystem.B.dylib.
expected_opencoregraphics_inputs=$(printf '%s\n' \
    'linker synthesized' \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$SYS/usr/lib/libSystem.tbd" \
    "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    "$FULL/opencoregraphics.o" \
    "$SYS/usr/lib/libobjc.tbd")
expected_swiftui_inputs=$(printf '%s\n' \
    'linker synthesized' \
    "$PACKAGE/libOpenUIKit.dylib" \
    "$PACKAGE/libOpenCoreGraphics.dylib" \
    "$PACKAGE/libCombine.dylib" \
    "$PACKAGE/libSymbols.dylib" \
    "$PACKAGE/libFoundationEssentials.dylib" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$SYS/usr/lib/libSystem.tbd" \
    "$SYS/usr/lib/libobjc.tbd" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    "$OUT/swiftui.o" \
    "$SYS/usr/lib/swift/libswift_Concurrency.tbd" \
    "$SYS/usr/lib/swift/libswiftObjectiveC.tbd" \
    "$SYS/usr/lib/swift/libswiftObservation.tbd")
expected_opencombine_inputs=$(printf '%s\n' \
    'linker synthesized' \
    "$OPENCOMBINE_ARTIFACTS/OpenCombine.o" \
    "$OUT/copencombinehelpers.o" \
    "$SYS/usr/lib/swift/libswift_Concurrency.tbd" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$MRROOT/darwin/usr/lib/libc++abi.dylib" \
    "$SYS/usr/lib/libSystem.tbd" \
    "$SYS/usr/lib/libobjc.tbd")
expected_combine_inputs=$(printf '%s\n' \
    'linker synthesized' \
    "$OUT/combine.o" \
    "$SYS/usr/lib/libSystem.tbd")
# libswiftcompat.dylib is on libSymbols' link line and in its load commands,
# but symbols.o binds nothing from it, so lld's map omits it (the map lists
# inputs that contributed symbols, not the command line).
expected_symbols_inputs=$(printf '%s\n' \
    'linker synthesized' \
    "$OUT/symbols.o" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$SYS/usr/lib/libSystem.tbd")
# libSymbols.dylib is a guest load command (expected_guest_loads) but the
# widget binds no Symbols symbol, so it is absent from the guest link map.
expected_guest_inputs=$(printf '%s\n' \
    'linker synthesized' \
    "$PACKAGE/libSwiftUI.dylib" \
    "$PACKAGE/libOpenUIKit.dylib" \
    "$PACKAGE/libFoundationEssentials.dylib" \
    "$PACKAGE/libOpenCoreGraphics.dylib" \
    "$SYS/usr/lib/swift/libswiftCore.tbd" \
    "$SYS/usr/lib/libSystem.tbd" \
    "$SYS/usr/lib/libobjc.tbd" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    "$OUT/guest-main.o" \
    "$OUT/focuswidget.o" \
    "$SYS/usr/lib/swift/libswiftObjectiveC.tbd")
assert_exact_text "libOpenUIKit linker inputs" \
    "$(link_map_inputs "$AUDIT/libOpenUIKit.link-map")" "$expected_openuikit_inputs"
assert_exact_text "libFoundationEssentials linker inputs" \
    "$(link_map_inputs "$AUDIT/libFoundationEssentials.link-map")" \
    "$expected_foundationessentials_inputs"
assert_exact_text "libOpenCoreGraphics linker inputs" \
    "$(link_map_inputs "$AUDIT/libOpenCoreGraphics.link-map")" \
    "$expected_opencoregraphics_inputs"
assert_exact_text "libSwiftUI linker inputs" \
    "$(link_map_inputs "$AUDIT/libSwiftUI.link-map")" "$expected_swiftui_inputs"
assert_exact_text "libOpenCombine linker inputs" \
    "$(link_map_inputs "$AUDIT/libOpenCombine.link-map")" "$expected_opencombine_inputs"
assert_exact_text "libCombine linker inputs" \
    "$(link_map_inputs "$AUDIT/libCombine.link-map")" "$expected_combine_inputs"
assert_exact_text "libSymbols linker inputs" \
    "$(link_map_inputs "$AUDIT/libSymbols.link-map")" "$expected_symbols_inputs"
assert_exact_text "guest linker inputs" \
    "$(link_map_inputs "$AUDIT/focus_widget_guest.link-map")" "$expected_guest_inputs"
for input in openuikit.o cportableio.o cstbtruetype.o \
    hostclock.o swiftcorepatch.o; do
    grep -Fq "$input" "$AUDIT/libOpenUIKit.link-map" || {
        echo "focus_widget_guest: libOpenUIKit link map omitted $input" >&2; exit 2; }
done
grep -Fq 'opencoregraphics.o' "$AUDIT/libOpenCoreGraphics.link-map" || {
    echo "focus_widget_guest: libOpenCoreGraphics link map omitted opencoregraphics.o" >&2
    exit 2
}
for input in FoundationEssentials.o InternalCollectionsUtilities.o \
    OrderedCollections.o _RopeModule.o os.o platform_shims.o string_shims.o \
    uuid.o fm_unimplemented.o uuid_compat.o; do
    grep -Fq "$input" "$AUDIT/libFoundationEssentials.link-map" || {
        echo "focus_widget_guest: libFoundationEssentials link map omitted $input" >&2
        exit 2
    }
done
grep -Fq 'swiftui.o' "$AUDIT/libSwiftUI.link-map" || {
    echo "focus_widget_guest: libSwiftUI link map omitted swiftui.o" >&2; exit 2; }
grep -Fq 'symbols.o' "$AUDIT/libSymbols.link-map" || {
    echo "focus_widget_guest: libSymbols link map omitted symbols.o" >&2; exit 2; }
for forbidden_object in swiftui.o symbols.o openuikit.o opencoregraphics.o \
    cportableio.o cstbtruetype.o hostclock.o swiftcorepatch.o; do
    if grep -Fq "$forbidden_object" "$AUDIT/focus_widget_guest.link-map"; then
        echo "focus_widget_guest: executable link map contains framework object $forbidden_object" >&2
        exit 2
    fi
done

git -C "$FOCUS_REPO" diff --quiet -- "$FOCUS_WIDGET/Assets.swift" \
    "$FOCUS_WIDGET/SearchWidgetView.swift" || {
    echo "focus_widget_guest: Focus sources changed during build" >&2; exit 2; }
[ -z "$(git -C "$FOCUS_REPO" status --porcelain=v1 --untracked-files=all)" ] || {
    echo "focus_widget_guest: Focus checkout changed during build" >&2; exit 2; }
require_hash "$FOCUS_WIDGET/Assets.swift" "$EXPECTED_ASSETS_SHA" Assets.swift
require_hash "$FOCUS_WIDGET/SearchWidgetView.swift" "$EXPECTED_VIEW_SHA" SearchWidgetView.swift
[ "$(support_digest)" = "$support_before" ] || {
    echo "focus_widget_guest: SwiftUI/build-support sources changed during compilation" >&2; exit 2; }
[ "$(tree_digest "$RESOURCE_INPUT")" = "$resource_input_before" ] || {
    echo "focus_widget_guest: normalized resource input changed during compilation" >&2; exit 2; }

# Presence and a stable hash are insufficient for a copied guest root: grade its
# manifest against the currently mounted machorun checkout immediately before
# execution. This runs on both the ordinary rebuild and resume-only paths.
MACHORUN="$MACHORUN" bash "$W/scripts/require_fresh_root.sh" "$MRROOT"

# Resolve the executable's complete transitive Mach-O load graph, including
# re-exports, weak-load declarations, the loader, the root manifest, and the
# extensionless Foundation/CoreFoundation loud-abort substrate stubs. An
# ordinary build records it atomically; a resume may only match that prior
# record. Never overwrite the record from a resume-only invocation.
if [ "$skip_full_build" != 1 ]; then
    runtime_closure_recording=$(mktemp "$FULL/.focus-widget-runtime-closure.recording.XXXXXX")
    generate_runtime_closure > "$runtime_closure_recording"
    mv "$runtime_closure_recording" "$RUNTIME_CLOSURE_MANIFEST"
else
    [ -f "$RUNTIME_CLOSURE_MANIFEST" ] && [ ! -L "$RUNTIME_CLOSURE_MANIFEST" ] || {
        echo "focus_widget_guest: SKIP_FULL_BUILD has no regular runtime-closure manifest" >&2
        exit 2
    }
fi
assert_build_input_inventory
assert_runtime_closure
runtime_closure_manifest_sha=$(hash_file "$RUNTIME_CLOSURE_MANIFEST")
runtime_closure_file_count=$(grep -c '^file'"$(printf '\t')" "$RUNTIME_CLOSURE_MANIFEST")
runtime_closure_edge_count=$(grep -Ec '^(edge|weak-missing)'"$(printf '\t')" "$RUNTIME_CLOSURE_MANIFEST")
[ "$runtime_closure_file_count" -ge 18 ] && [ "$runtime_closure_edge_count" -gt 40 ] || {
    echo "focus_widget_guest: recursive runtime closure is vacuous ($runtime_closure_file_count files, $runtime_closure_edge_count edges)" >&2
    exit 2
}
runtime_before=$(runtime_fingerprint)

echo "== run $ARCH Mach-O under machorun on Linux"
if [ "$ARCH" = arm64 ] && [ "$(uname -m)" != aarch64 ] && [ "$(uname -m)" != arm64 ]; then
    echo "focus_widget_guest: compile/link may proceed on this VM; execution of arm64 guests cannot" >&2
    bash "${W:-$(git rev-parse --show-toplevel)}/.cursor/refuse-arm64-execution.sh" \
        || exit $?
fi
export MACHORUN_ROOT="$MRROOT"
cd "$OUT"
"$MRROOT/machorun" ./focus_widget_guest \
    "$OUT/Focus_Widget.bundle" \
    "$OUT/focus-search-widget.png" | tee guest-first.log
cp "$OUT/focus-search-widget.png" "$OUT/focus-search-widget.first.png"
assert_build_input_inventory
assert_runtime_closure
"$MRROOT/machorun" ./focus_widget_guest \
    "$OUT/Focus_Widget.bundle" \
    "$OUT/focus-search-widget.png" | tee guest-repeat.log
cmp -s "$OUT/focus-search-widget.first.png" "$OUT/focus-search-widget.png" || {
    echo "focus_widget_guest: separate guest processes emitted different PNG bytes" >&2
    exit 2
}
cmp -s "$OUT/guest-first.log" "$OUT/guest-repeat.log" || {
    echo "focus_widget_guest: separate guest processes emitted different proof logs" >&2
    exit 2
}
assert_build_input_inventory
assert_runtime_closure

require_hash "$OUT/Focus_Widget.bundle/resource-index.json" "$EXPECTED_INDEX_SHA" staged-resource-index
[ -s "$OUT/focus-search-widget.png" ] || {
    echo "focus_widget_guest: guest emitted no PNG" >&2; exit 2; }
grep -q '^PASS: exact unchanged Focus SearchWidgetView ran under machorun$' "$OUT/guest-first.log" || {
    echo "focus_widget_guest: runtime PASS marker missing" >&2; exit 2; }

# A missing-library control proves that the executable cannot fall back to
# statically linked SwiftUI symbols or an Apple framework. Keep OpenUIKit in
# place so the discriminator is specifically the absent packaged SwiftUI dylib.
missing_control=$OUT/missing-swiftui-control
mkdir -p "$missing_control/package"
cp "$OUT/focus_widget_guest" "$missing_control/focus_widget_guest"
cp "$PACKAGE/libOpenUIKit.dylib" "$PACKAGE/libCombine.dylib" \
    "$PACKAGE/libOpenCombine.dylib" "$PACKAGE/libFoundationEssentials.dylib" \
    "$PACKAGE/libOpenCoreGraphics.dylib" "$PACKAGE/libSymbols.dylib" \
    "$missing_control/package/"
set +e
(
    cd "$missing_control"
    "$MRROOT/machorun" ./focus_widget_guest \
        "$OUT/Focus_Widget.bundle" \
        "$OUT/missing-control-must-not-exist.png"
) > "$AUDIT/missing-swiftui.stdout" 2> "$AUDIT/missing-swiftui.stderr"
missing_rc=$?
set -e
[ "$missing_rc" -eq 72 ] || {
    echo "focus_widget_guest: missing-libSwiftUI control exited $missing_rc, expected 72" >&2
    sed -n '1,120p' "$AUDIT/missing-swiftui.stdout" >&2
    sed -n '1,120p' "$AUDIT/missing-swiftui.stderr" >&2
    exit 2
}
grep -Fxq "machorun: cannot find dylib '@rpath/libSwiftUI.dylib'" \
    "$AUDIT/missing-swiftui.stderr" || {
    echo "focus_widget_guest: missing-libSwiftUI discriminator changed" >&2; exit 2; }
[ ! -s "$AUDIT/missing-swiftui.stdout" ] || {
    echo "focus_widget_guest: missing-libSwiftUI control unexpectedly entered app main" >&2; exit 2; }
[ ! -e "$OUT/missing-control-must-not-exist.png" ] || {
    echo "focus_widget_guest: missing-libSwiftUI control emitted an artifact" >&2; exit 2; }

# The reciprocal control leaves SwiftUI's other three sibling dylibs present
# but withholds its OpenUIKit implementation. This proves recursive dylib
# loading and rules out an OpenUIKit copy hidden inside either client image.
missing_openuikit=$OUT/missing-openuikit-control
mkdir -p "$missing_openuikit/package"
cp "$OUT/focus_widget_guest" "$missing_openuikit/focus_widget_guest"
cp "$PACKAGE/libSwiftUI.dylib" "$PACKAGE/libCombine.dylib" \
    "$PACKAGE/libOpenCombine.dylib" "$PACKAGE/libFoundationEssentials.dylib" \
    "$PACKAGE/libOpenCoreGraphics.dylib" "$PACKAGE/libSymbols.dylib" \
    "$missing_openuikit/package/"
set +e
(
    cd "$missing_openuikit"
    "$MRROOT/machorun" ./focus_widget_guest \
        "$OUT/Focus_Widget.bundle" \
        "$OUT/missing-openuikit-must-not-exist.png"
) > "$AUDIT/missing-openuikit.stdout" 2> "$AUDIT/missing-openuikit.stderr"
missing_openuikit_rc=$?
set -e
[ "$missing_openuikit_rc" -eq 72 ] || {
    echo "focus_widget_guest: missing-libOpenUIKit control exited $missing_openuikit_rc, expected 72" >&2
    sed -n '1,120p' "$AUDIT/missing-openuikit.stdout" >&2
    sed -n '1,120p' "$AUDIT/missing-openuikit.stderr" >&2
    exit 2
}
grep -Fxq "machorun: cannot find dylib '@rpath/libOpenUIKit.dylib'" \
    "$AUDIT/missing-openuikit.stderr" || {
    echo "focus_widget_guest: missing-libOpenUIKit discriminator changed" >&2; exit 2; }
grep -Fxq '  required by: ./package/libSwiftUI.dylib' \
    "$AUDIT/missing-openuikit.stderr" || {
    echo "focus_widget_guest: missing-libOpenUIKit requester changed" >&2; exit 2; }
[ ! -s "$AUDIT/missing-openuikit.stdout" ] || {
    echo "focus_widget_guest: missing-libOpenUIKit control unexpectedly entered app main" >&2; exit 2; }
[ ! -e "$OUT/missing-openuikit-must-not-exist.png" ] || {
    echo "focus_widget_guest: missing-libOpenUIKit control emitted an artifact" >&2; exit 2; }

run_missing_observation_control() {
    local label=$1 missing_name=$2 requester=$3
    shift 3
    local control=$OUT/missing-$label-control
    local stdout=$AUDIT/missing-$label.stdout
    local stderr=$AUDIT/missing-$label.stderr
    local artifact=$OUT/missing-$label-must-not-exist.png
    mkdir -p "$control/package"
    cp "$OUT/focus_widget_guest" "$control/focus_widget_guest"
    for sibling in "$@"; do
        cp "$PACKAGE/$sibling" "$control/package/$sibling"
    done
    set +e
    (
        cd "$control"
        "$MRROOT/machorun" ./focus_widget_guest \
            "$OUT/Focus_Widget.bundle" "$artifact"
    ) > "$stdout" 2> "$stderr"
    local rc=$?
    set -e
    [ "$rc" -eq 72 ] || {
        echo "focus_widget_guest: missing-$missing_name control exited $rc, expected 72" >&2
        sed -n '1,120p' "$stdout" >&2
        sed -n '1,120p' "$stderr" >&2
        exit 2
    }
    grep -Fxq "machorun: cannot find dylib '@rpath/$missing_name'" "$stderr" || {
        echo "focus_widget_guest: missing-$missing_name discriminator changed" >&2; exit 2; }
    grep -Fxq "  required by: $requester" "$stderr" || {
        echo "focus_widget_guest: missing-$missing_name requester changed" >&2; exit 2; }
    [ ! -s "$stdout" ] || {
        echo "focus_widget_guest: missing-$missing_name control unexpectedly entered app main" >&2
        exit 2
    }
    [ ! -e "$artifact" ] || {
        echo "focus_widget_guest: missing-$missing_name control emitted an artifact" >&2; exit 2; }
}

# Observation is not statically folded into SwiftUI. Its literal Combine shim
# and the one OpenCombine implementation must both be present in the sibling
# package, with the recursive requester identifying the expected edge.
run_missing_observation_control combine libCombine.dylib \
    './package/libSwiftUI.dylib' \
    libSwiftUI.dylib libOpenUIKit.dylib libOpenCombine.dylib \
    libFoundationEssentials.dylib libOpenCoreGraphics.dylib libSymbols.dylib
run_missing_observation_control opencombine libOpenCombine.dylib \
    './package/libCombine.dylib' \
    libSwiftUI.dylib libOpenUIKit.dylib libCombine.dylib \
    libFoundationEssentials.dylib libOpenCoreGraphics.dylib libSymbols.dylib
run_missing_observation_control symbols libSymbols.dylib \
    './package/libSwiftUI.dylib' \
    libSwiftUI.dylib libOpenUIKit.dylib libCombine.dylib libOpenCombine.dylib \
    libFoundationEssentials.dylib libOpenCoreGraphics.dylib

assert_build_input_inventory
assert_runtime_closure
runtime_after=$(runtime_fingerprint)
support_after=$(support_digest)
resource_input_after=$(tree_digest "$RESOURCE_INPUT")
resource_staged_after=$(tree_digest "$OUT/Focus_Widget.bundle")
current_full_subject_after=$(bash "$W/full/scripts/uihelpers_subject.sh" "$W" "$UIKIT")
[ "$runtime_after" = "$runtime_before" ] || {
    echo "focus_widget_guest: binary, framework package, guest root, fonts, or bundle changed during execution" >&2
    exit 2
}
[ "$support_after" = "$support_before" ] || {
    echo "focus_widget_guest: SwiftUI/build-support sources changed during execution" >&2
    exit 2
}
[ "$resource_input_after" = "$EXPECTED_RESOURCE_TREE_SHA" ] && \
    [ "$resource_staged_after" = "$EXPECTED_RESOURCE_TREE_SHA" ] || {
    echo "focus_widget_guest: complete normalized resource tree changed during execution" >&2
    exit 2
}
[ "$current_full_subject_after" = "$recorded_full_subject" ] || {
    echo "focus_widget_guest: authoritative OpenUIKit sources changed during execution" >&2
    exit 2
}
assert_vendor_tree "$W" uikit "$UIKIT" "$EXPECTED_UIKIT_TREE" post-OpenUIKit
assert_vendor_tree "$W" machorun "$MACHORUN" "$EXPECTED_INREPO_MACHORUN_TREE" post-machorun
assert_build_input_inventory
assert_runtime_closure
[ -z "$(git -C "$FOCUS_REPO" status --porcelain=v1 --untracked-files=all)" ] || {
    echo "focus_widget_guest: Focus checkout changed during execution" >&2; exit 2; }
require_hash "$FOCUS_WIDGET/Assets.swift" "$EXPECTED_ASSETS_SHA" Assets.swift
require_hash "$FOCUS_WIDGET/SearchWidgetView.swift" "$EXPECTED_VIEW_SHA" SearchWidgetView.swift

{
    printf 'uikit_tree\t%s\n' "$EXPECTED_UIKIT_TREE"
    printf 'uikit_tree_source\tHEAD:uikit\n'
    printf 'machorun_tree\t%s\n' "$EXPECTED_INREPO_MACHORUN_TREE"
    printf 'machorun_tree_source\tHEAD:machorun\n'
    printf 'focus_commit\t%s\n' "$EXPECTED_FOCUS_COMMIT"
    printf 'Assets.swift\t%s\n' "$EXPECTED_ASSETS_SHA"
    printf 'SearchWidgetView.swift\t%s\n' "$EXPECTED_VIEW_SHA"
    printf 'Focus_Widget.bundle/tree\t%s\n' "$EXPECTED_RESOURCE_TREE_SHA"
    printf 'FocusWidgetBundle.generated.swift\t%s\n' \
        "$(hash_file "$W/full/swiftui/FocusWidgetBundle.generated.swift")"
    printf 'SwiftUI-build-support-subject\t%s\n' "$support_before"
    printf 'OpenUIKit-full-subject\t%s\n' "$recorded_full_subject"
    # These derived-input/package hashes deliberately bracket this run. Some
    # compiler-produced .swiftsourceinfo files encode the absolute checkout
    # root, so they are not cross-directory reproducibility claims.
    printf 'complete-build-inputs/per-run-manifest\t%s\n' "$build_input_manifest_sha"
    printf 'complete-build-inputs/nodes\t%s\n' "$build_input_node_count"
    printf 'recursive-runtime-closure/manifest\t%s\n' "$runtime_closure_manifest_sha"
    printf 'recursive-runtime-closure/files\t%s\n' "$runtime_closure_file_count"
    printf 'recursive-runtime-closure/edges\t%s\n' "$runtime_closure_edge_count"
    printf 'framework-provider-audit\t%s\n' "$(hash_file "$AUDIT/framework-providers.tsv")"
    printf 'DejaVuSans.ttf\t%s\n' "$EXPECTED_SYSTEM_FONT_SHA"
    printf 'DejaVuSans-Bold.ttf\t%s\n' "$EXPECTED_MEDIUM_FONT_SHA"
    printf 'SwiftUI.swiftmodule\t%s\n' "$(hash_file "$PACKAGE/SwiftUI.swiftmodule")"
    printf 'SwiftUI.swiftdoc\t%s\n' "$(hash_file "$PACKAGE/SwiftUI.swiftdoc")"
    printf 'SwiftUI.swiftsourceinfo/per-run\t%s\n' "$(hash_file "$PACKAGE/SwiftUI.swiftsourceinfo")"
    printf 'SwiftUI.abi.json\t%s\n' "$(hash_file "$PACKAGE/SwiftUI.abi.json")"
    printf 'Combine.swiftmodule\t%s\n' "$(hash_file "$PACKAGE/Combine.swiftmodule")"
    printf 'OpenCombine.swiftmodule\t%s\n' "$(hash_file "$PACKAGE/OpenCombine.swiftmodule")"
    printf 'Symbols.swiftmodule\t%s\n' "$(hash_file "$PACKAGE/Symbols.swiftmodule")"
    printf 'OpenUIKit.swiftmodule\t%s\n' "$(hash_file "$PACKAGE/OpenUIKit.swiftmodule")"
    printf 'OpenCoreGraphics.swiftmodule\t%s\n' "$(hash_file "$PACKAGE/OpenCoreGraphics.swiftmodule")"
    printf 'SwiftUI-package/per-run-tree\t%s\n' "$package_tree_before"
    printf 'libSwiftUI.dylib\t%s\n' "$(hash_file "$PACKAGE/libSwiftUI.dylib")"
    printf 'libOpenUIKit.dylib\t%s\n' "$(hash_file "$PACKAGE/libOpenUIKit.dylib")"
    printf 'libFoundationEssentials.dylib\t%s\n' \
        "$(hash_file "$PACKAGE/libFoundationEssentials.dylib")"
    printf 'libOpenCoreGraphics.dylib\t%s\n' \
        "$(hash_file "$PACKAGE/libOpenCoreGraphics.dylib")"
    printf 'libCombine.dylib\t%s\n' "$(hash_file "$PACKAGE/libCombine.dylib")"
    printf 'libOpenCombine.dylib\t%s\n' "$(hash_file "$PACKAGE/libOpenCombine.dylib")"
    printf 'libSymbols.dylib\t%s\n' "$(hash_file "$PACKAGE/libSymbols.dylib")"
    printf 'focus_widget_guest\t%s\n' "$(hash_file "$OUT/focus_widget_guest")"
    printf 'focus-search-widget.png\t%s\n' "$(hash_file "$OUT/focus-search-widget.png")"
} > "$OUT/artifacts.sha256"

echo "== PASS: unchanged Focus widget ran through packaged SwiftUI/OpenUIKit/Combine dylibs as a Linux Mach-O guest"
cat "$OUT/artifacts.sha256"
