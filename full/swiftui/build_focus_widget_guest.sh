#!/usr/bin/env bash
# Build and run Focus's exact Widget/Assets.swift + SearchWidgetView.swift as
# an arm64 Mach-O guest. Run inside swift-macho-spike:noble with /w, /uikit,
# /machorun, and a normalized Focus_Widget.bundle mounted.

set -euo pipefail

W=${W:-/w}
UIKIT=${UIKIT:-/uikit}
MACHORUN=${MACHORUN:-/machorun}
RESOURCE_INPUT=${1:?usage: build_focus_widget_guest.sh <normalized-Focus_Widget.bundle>}
FOCUS_REPO=$W/scratch/ladder-corpus/focus-ios/focus-ios
FOCUS_WIDGET=$FOCUS_REPO/BlockzillaPackage/Sources/Widget
OUT=$W/build/swiftui-guest
FULL=$W/build/full
SYS=$W/scratch/sysroot_full
MRROOT=$W/scratch/mrroot_full
MC=$W/scratch/modcache_swiftui_guest

EXPECTED_FOCUS_COMMIT=a2832521c1daa0c23419c73705ae043ed60c9791
EXPECTED_ASSETS_SHA=efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e
EXPECTED_VIEW_SHA=721669388a4556e1609f580ed87d6065b63981770e71b0f77db292767b05f6c2
EXPECTED_INDEX_SHA=2eb8af32cc6d69161dc35f1536682dcba2dd4db21ea0015cf241701f32468d12
EXPECTED_LOGO_SHA=180d76a144c6e74324283e8bfb72d9d7bb32125fe57769e3403b0ca72b6ef415
EXPECTED_FIRST_SHA=75759bdc8a68e4694bda34486c47e347ab8af010ebb8de7372b0ca443c08186b
EXPECTED_SECOND_SHA=f71bc94e686809660d920da6f7804174097e038302a843c3533da45ceda44af2
EXPECTED_RESOURCE_TREE_SHA=144c49c747d4689d9ca98d353cb5474b311473629383a779d99f1b705969a04d
EXPECTED_RESOURCE_FILE_COUNT=16
EXPECTED_RESOURCE_DIRECTORY_COUNT=7
SUBSTRATE_MANIFEST=$FULL/focus-widget-substrate.sha256
SYSTEM_FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
MEDIUM_FONT=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
EXPECTED_SYSTEM_FONT_SHA=ae7b7855e115a5966d8b1b3f80f254ccc117ec86f9965e202ee2940453837280
EXPECTED_MEDIUM_FONT_SHA=5c1247acef7f2b8522a31742c76d6adcb5569bacc0be7ceaa4dc39dd252ce895

hash_file() { sha256sum "$1" | awk '{print $1}'; }
hash_stream() { sha256sum | awk '{print $1}'; }
require_hash() {
    local file=$1 expected=$2 label=$3 got
    [ -f "$file" ] && [ ! -L "$file" ] || {
        echo "focus_widget_guest: missing regular $label: $file" >&2; exit 2; }
    got=$(hash_file "$file")
    [ "$got" = "$expected" ] || {
        echo "focus_widget_guest: $label drifted: $got" >&2; exit 2; }
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
        for file in \
            "$UIKIT/Sources/SwiftUI/Values.swift" \
            "$UIKIT/Sources/SwiftUI/View.swift" \
            "$UIKIT/Sources/SwiftUI/Hosting.swift" \
            "$W/full/swiftui/FocusWidgetBundle.generated.swift" \
            "$W/full/swiftui/FocusWidgetGuestMain.swift" \
            "$W/full/swiftui/build_focus_widget_guest.sh"; do
            printf '%s\t%s\n' "${file#"$W"/}" "$(hash_file "$file")"
        done
    } | hash_stream
}

substrate_artifact_digest() {
    local file
    for file in \
        "$FULL/openuikit.o" \
        "$FULL/opencoregraphics.o" \
        "$FULL/cportableio.o" \
        "$FULL/cstbtruetype.o" \
        "$FULL/hostclock.o" \
        "$FULL/swiftcorepatch.o" \
        "$MRROOT/machorun" \
        "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
        "$MRROOT/darwin/usr/lib/libquartz.dylib" \
        "$MRROOT/darwin/usr/lib/libSystem.B.dylib"; do
        [ -s "$file" ] && [ -f "$file" ] && [ ! -L "$file" ] || {
            echo "focus_widget_guest: missing regular substrate artifact: $file" >&2
            return 2
        }
        printf '%s\t%s\n' "${file#"$W"/}" "$(hash_file "$file")"
    done | hash_stream
}

runtime_fingerprint() {
    {
        printf 'guest\t%s\n' "$(hash_file "$OUT/focus_widget_guest")"
        printf 'resources\t%s\n' "$(tree_digest "$OUT/Focus_Widget.bundle")"
        printf 'system-font\t%s\n' "$(hash_file "$SYSTEM_FONT")"
        printf 'medium-font\t%s\n' "$(hash_file "$MEDIUM_FONT")"
        printf 'staged-system-font\t%s\n' "$(hash_file "$OUT/fonts/DejaVuSans.ttf")"
        printf 'staged-medium-font\t%s\n' "$(hash_file "$OUT/fonts/DejaVuSans-Bold.ttf")"
        find "$MRROOT" -type f \( -name machorun -o -name '*.dylib' \) \
            -print0 | LC_ALL=C sort -z | while IFS= read -r -d '' file; do
                printf '%s\t%s\n' "${file#"$MRROOT"/}" "$(hash_file "$file")"
            done
    } | hash_stream
}

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
    "$UIKIT/Sources/SwiftUI/Values.swift" \
    "$UIKIT/Sources/SwiftUI/View.swift" \
    "$UIKIT/Sources/SwiftUI/Hosting.swift" \
    "$W/full/swiftui/FocusWidgetBundle.generated.swift" \
    "$W/full/swiftui/FocusWidgetGuestMain.swift" \
    "$MACHORUN/build/machorun"; do
    [ -f "$required" ] || { echo "focus_widget_guest: missing $required" >&2; exit 2; }
done
support_before=$(support_digest)

# Rebuild the complete Foundation-hidden substrate from authoritative OpenUIKit
# before adding SwiftUI. The source checkout is mounted read-only at /uikit.
# SKIP_FULL_BUILD=1 exists only to resume after a post-link/proof-gate failure;
# the ordinary reproduction always rebuilds the substrate in this invocation.
if [ "${SKIP_FULL_BUILD:-0}" != 1 ]; then
    bash "$W/full/scripts/build_full.sh"
    substrate_after_build=$(substrate_artifact_digest)
    printf '%s\n' "$substrate_after_build" > "$SUBSTRATE_MANIFEST.tmp"
    mv "$SUBSTRATE_MANIFEST.tmp" "$SUBSTRATE_MANIFEST"
else
    [ -f "$SUBSTRATE_MANIFEST" ] && [ ! -L "$SUBSTRATE_MANIFEST" ] || {
        echo "focus_widget_guest: SKIP_FULL_BUILD has no regular substrate manifest" >&2
        exit 2
    }
    recorded_substrate=$(tr -d '[:space:]' < "$SUBSTRATE_MANIFEST")
    printf '%s\n' "$recorded_substrate" | grep -Eq '^[0-9a-f]{64}$' || {
        echo "focus_widget_guest: malformed substrate manifest" >&2
        exit 2
    }
    current_substrate=$(substrate_artifact_digest)
    [ "$current_substrate" = "$recorded_substrate" ] || {
        echo "focus_widget_guest: SKIP_FULL_BUILD substrate artifacts drifted; rebuild first" >&2
        exit 2
    }
fi

recorded_substrate=$(tr -d '[:space:]' < "$SUBSTRATE_MANIFEST")
[ "$(substrate_artifact_digest)" = "$recorded_substrate" ] || {
    echo "focus_widget_guest: substrate artifact manifest does not match the build" >&2
    exit 2
}

recorded_full_subject=$(tr -d '[:space:]' < "$FULL/uihelpers-subject.sha256")
current_full_subject=$(bash "$W/full/scripts/uihelpers_subject.sh" "$W" "$UIKIT")
[ "$recorded_full_subject" = "$current_full_subject" ] || {
    echo "focus_widget_guest: OpenUIKit substrate sources changed after build_full" >&2
    exit 2
}

rm -rf "$OUT"
mkdir -p "$OUT/fonts" "$MC"
cp -a "$RESOURCE_INPUT" "$OUT/Focus_Widget.bundle"
cp "$SYSTEM_FONT" "$OUT/fonts/DejaVuSans.ttf"
cp "$MEDIUM_FONT" "$OUT/fonts/DejaVuSans-Bold.ttf"
[ "$(tree_digest "$OUT/Focus_Widget.bundle")" = "$EXPECTED_RESOURCE_TREE_SHA" ] || {
    echo "focus_widget_guest: normalized bundle changed while staging" >&2; exit 2; }
require_hash "$OUT/fonts/DejaVuSans.ttf" "$EXPECTED_SYSTEM_FONT_SHA" staged-DejaVuSans.ttf
require_hash "$OUT/fonts/DejaVuSans-Bold.ttf" "$EXPECTED_MEDIUM_FONT_SHA" staged-DejaVuSans-Bold.ttf

SWIFTC=(swiftc -target arm64-apple-macos13.0 -sdk "$SYS" -module-cache-path "$MC"
        -runtime-compatibility-version none -wmo
        -Xfrontend -disable-implicit-string-processing-module-import
        -Xfrontend -disable-objc-attr-requires-foundation-module)
LD=(ld64.lld-18 -arch arm64 -platform_version macos 13.0 13.0
    -syslibroot "$SYS" -rpath /usr/lib/swift)
CINC=(-Xcc -I"$FULL/inc/CPortableIO" -Xcc -I"$FULL/inc/CSTBTrueType"
      -Xcc -I"$W/full/hostclock/include"
      -Xcc -I"$UIKIT/Sources/CQuartz/include")

# Repeat build_full's Foundation-invisibility gate at the SwiftUI boundary.
"${SWIFTC[@]}" "${CINC[@]}" -typecheck -module-name SwiftUINoFoundation \
    "$FULL/guard_no_foundation.swift"

echo "== SwiftUI S1 (authoritative OpenUIKit sources; Foundation hidden)"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" -I "$FULL" \
    -module-name SwiftUI -emit-module -emit-module-path "$OUT/SwiftUI.swiftmodule" \
    -emit-object -o "$OUT/swiftui.o" \
    "$UIKIT/Sources/SwiftUI/Values.swift" \
    "$UIKIT/Sources/SwiftUI/View.swift" \
    "$UIKIT/Sources/SwiftUI/Hosting.swift"

echo "== FocusWidget (two pinned app sources direct from clean checkout)"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" -I "$FULL" -I "$OUT" \
    -module-name FocusWidget \
    -emit-module -emit-module-path "$OUT/FocusWidget.swiftmodule" \
    -emit-object -o "$OUT/focuswidget.o" \
    "$FOCUS_WIDGET/Assets.swift" \
    "$FOCUS_WIDGET/SearchWidgetView.swift" \
    "$W/full/swiftui/FocusWidgetBundle.generated.swift"

echo "== guest harness (project-owned, separate from Focus sources)"
"${SWIFTC[@]}" -parse-as-library "${CINC[@]}" -I "$FULL" -I "$OUT" \
    -module-name FocusWidgetGuest -emit-object -o "$OUT/guest-main.o" \
    "$W/full/swiftui/FocusWidgetGuestMain.swift"

echo "== link arm64 Mach-O"
"${LD[@]}" -exported_symbol __mh_execute_header -rpath @loader_path \
    -L"$MRROOT/darwin/usr/lib" \
    -L/usr/lib/swift -lswiftCore "$MRROOT/darwin/usr/lib/libswiftcompat.dylib" \
    -L/usr/lib -lSystem -lobjc "$MRROOT/darwin/usr/lib/libquartz.dylib" \
    "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    -o "$OUT/focus_widget_guest" \
    "$OUT/guest-main.o" "$OUT/focuswidget.o" "$OUT/swiftui.o" \
    "$FULL/openuikit.o" "$FULL/opencoregraphics.o" \
    "$FULL/cportableio.o" "$FULL/cstbtruetype.o" "$FULL/hostclock.o" \
    "$FULL/swiftcorepatch.o"

llvm-otool-18 -hv "$OUT/focus_widget_guest" | \
    grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' || {
    echo "focus_widget_guest: link output is not arm64 Mach-O" >&2; exit 2; }
load_commands=$(llvm-otool-18 -L "$OUT/focus_widget_guest")
for forbidden in Foundation.framework SwiftUI.framework SwiftUICore.framework libSwiftUI; do
    if printf '%s\n' "$load_commands" | grep -Fq "$forbidden"; then
        echo "focus_widget_guest: forbidden Apple $forbidden load command leaked into guest" >&2
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
runtime_before=$(runtime_fingerprint)

echo "== run arm64 Mach-O under machorun on Linux"
export MACHORUN_ROOT="$MRROOT"
cd "$OUT"
"$MRROOT/machorun" ./focus_widget_guest \
    /w/build/swiftui-guest/Focus_Widget.bundle \
    /w/build/swiftui-guest/focus-search-widget.png | tee guest.log

require_hash "$OUT/Focus_Widget.bundle/resource-index.json" "$EXPECTED_INDEX_SHA" staged-resource-index
[ -s "$OUT/focus-search-widget.png" ] || {
    echo "focus_widget_guest: guest emitted no PNG" >&2; exit 2; }
grep -q '^PASS: exact unchanged Focus SearchWidgetView ran under machorun$' "$OUT/guest.log" || {
    echo "focus_widget_guest: runtime PASS marker missing" >&2; exit 2; }

runtime_after=$(runtime_fingerprint)
support_after=$(support_digest)
resource_input_after=$(tree_digest "$RESOURCE_INPUT")
resource_staged_after=$(tree_digest "$OUT/Focus_Widget.bundle")
current_full_subject_after=$(bash "$W/full/scripts/uihelpers_subject.sh" "$W" "$UIKIT")
[ "$runtime_after" = "$runtime_before" ] || {
    echo "focus_widget_guest: binary, guest root, fonts, or bundle changed during execution" >&2
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
[ -z "$(git -C "$FOCUS_REPO" status --porcelain=v1 --untracked-files=all)" ] || {
    echo "focus_widget_guest: Focus checkout changed during execution" >&2; exit 2; }
require_hash "$FOCUS_WIDGET/Assets.swift" "$EXPECTED_ASSETS_SHA" Assets.swift
require_hash "$FOCUS_WIDGET/SearchWidgetView.swift" "$EXPECTED_VIEW_SHA" SearchWidgetView.swift

{
    printf 'focus_commit\t%s\n' "$EXPECTED_FOCUS_COMMIT"
    printf 'Assets.swift\t%s\n' "$EXPECTED_ASSETS_SHA"
    printf 'SearchWidgetView.swift\t%s\n' "$EXPECTED_VIEW_SHA"
    printf 'Focus_Widget.bundle/tree\t%s\n' "$EXPECTED_RESOURCE_TREE_SHA"
    printf 'SwiftUI-build-support-subject\t%s\n' "$support_before"
    printf 'OpenUIKit-full-subject\t%s\n' "$recorded_full_subject"
    printf 'OpenUIKit-substrate-artifacts\t%s\n' "$recorded_substrate"
    printf 'DejaVuSans.ttf\t%s\n' "$EXPECTED_SYSTEM_FONT_SHA"
    printf 'DejaVuSans-Bold.ttf\t%s\n' "$EXPECTED_MEDIUM_FONT_SHA"
    printf 'focus_widget_guest\t%s\n' "$(hash_file "$OUT/focus_widget_guest")"
    printf 'focus-search-widget.png\t%s\n' "$(hash_file "$OUT/focus-search-widget.png")"
} > "$OUT/artifacts.sha256"

echo "== PASS: unchanged Focus SwiftUI widget built, linked, and ran as a Linux Mach-O guest"
cat "$OUT/artifacts.sha256"
