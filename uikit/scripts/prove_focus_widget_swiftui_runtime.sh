#!/usr/bin/env bash
# Build and run Focus's exact SearchWidgetView through OpenUIKit's SwiftUI.
#
# Inputs are the pinned BlockzillaPackage checkout and the reviewed normalized
# Focus_Widget.bundle.  App source is copied byte-for-byte into a private
# SwiftPM executable target.  SwiftPM alone generates Bundle.module.

set -euo pipefail
umask 077

usage() {
    echo "usage: $0 /path/to/BlockzillaPackage /path/to/Focus_Widget.bundle NEW_OUTPUT.png" >&2
    echo "       OPENUIKIT_FONT_DIR may name a directory containing SFNS*.ttf" >&2
    exit 64
}

fail() {
    echo "error: $*" >&2
    exit 1
}

[[ $# -eq 3 ]] || usage

script_dir=$(cd "$(dirname "$0")" && pwd -P)
open_uikit_root=$(cd "$script_dir/.." && pwd -P)
focus_package_root=$(cd "$1" 2>/dev/null && pwd -P) || usage
normalized_bundle=$(cd "$2" 2>/dev/null && pwd -P) || usage
[[ "$(basename "$normalized_bundle")" == "Focus_Widget.bundle" ]] \
    || fail "normalized resource argument must be named Focus_Widget.bundle"
[[ -d "$normalized_bundle" && ! -L "$2" ]] \
    || fail "normalized resource argument must be a real, non-symlink directory"

output_argument=$3
output_leaf=${output_argument##*/}
[[ -n "$output_leaf" && "$output_leaf" != "." && "$output_leaf" != ".." ]] \
    || fail "invalid output path"
if [[ "$output_argument" == */* ]]; then
    output_parent_input=${output_argument%/*}
    [[ -n "$output_parent_input" ]] || output_parent_input="/"
else
    output_parent_input="."
fi
output_parent=$(cd "$output_parent_input" 2>/dev/null && pwd -P) \
    || fail "output parent does not exist"
output_path="$output_parent/$output_leaf"
[[ ! -e "$output_path" && ! -L "$output_path" ]] \
    || fail "output must not already exist: $output_path"

assets_source="$focus_package_root/Sources/Widget/Assets.swift"
widget_source="$focus_package_root/Sources/Widget/SearchWidgetView.swift"
harness_source="$open_uikit_root/Tools/FocusWidgetRuntimeProbe/RuntimeMain.swift"
for source in "$assets_source" "$widget_source" "$harness_source"; do
    [[ -f "$source" && ! -L "$source" ]] \
        || fail "expected regular, non-symlink source: $source"
done

readonly expected_focus_revision="a2832521c1daa0c23419c73705ae043ed60c9791"
readonly expected_assets_sha256="efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e"
readonly expected_widget_sha256="721669388a4556e1609f580ed87d6065b63981770e71b0f77db292767b05f6c2"
readonly expected_png_sha256="cbf3484a6e13d18c2666b67d0efb80878db37bf846591441b6951cfd9c51e1c6"

sha256_file() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        fail "shasum or sha256sum is required"
    fi
}

file_size() {
    wc -c < "$1" | tr -d '[:space:]'
}

expected_bundle_files() {
    cat <<'EOF'
0fd49ba3c3585c709678e0046a821c3c60685ec7063720d30d3a3448be3a208b 63 Media.xcassets/Contents.json
75759bdc8a68e4694bda34486c47e347ab8af010ebb8de7372b0ca443c08186b 692 Media.xcassets/GradientFirst.colorset/Contents.json
f71bc94e686809660d920da6f7804174097e038302a843c3533da45ceda44af2 692 Media.xcassets/GradientSecond.colorset/Contents.json
180d76a144c6e74324283e8bfb72d9d7bb32125fe57769e3403b0ca72b6ef415 19130 icon_logo.png
5acd6ff3214009dd583d37fead8eaada34d69049cb14202d18103c2d5f84dd7f 52496 icon_logo@2x.png
cc0a1e50c01c13fd3315fbd14a89ebb521bedf9ebc21bf511c73e2e6c4305942 91082 icon_logo@3x.png
ac28495c9ca12a541302d9a1ab9b7a2e19aa765c6e9f03cf0e55169fb5bd983e 2409 icon_magnifying_glass.png
9077434adde7ac6ccb49842aa8cd76257e40e35db739592aa9c059a01f1cc33c 9345 icon_magnifying_glass@2x.png
b670deab128d1f3ae181f985448b8f423081f5c6c673a910e581087cffbbb066 20889 icon_magnifying_glass@3x.png
180d76a144c6e74324283e8bfb72d9d7bb32125fe57769e3403b0ca72b6ef415 19130 images/icon_logo/default@1x.png
5acd6ff3214009dd583d37fead8eaada34d69049cb14202d18103c2d5f84dd7f 52496 images/icon_logo/default@2x.png
cc0a1e50c01c13fd3315fbd14a89ebb521bedf9ebc21bf511c73e2e6c4305942 91082 images/icon_logo/default@3x.png
2eb8af32cc6d69161dc35f1536682dcba2dd4db21ea0015cf241701f32468d12 9621 resource-index.json
ac28495c9ca12a541302d9a1ab9b7a2e19aa765c6e9f03cf0e55169fb5bd983e 2409 symbols/magnifyingglass/default@1x.png
9077434adde7ac6ccb49842aa8cd76257e40e35db739592aa9c059a01f1cc33c 9345 symbols/magnifyingglass/default@2x.png
b670deab128d1f3ae181f985448b8f423081f5c6c673a910e581087cffbbb066 20889 symbols/magnifyingglass/default@3x.png
EOF
}

validate_bundle_inventory() {
    local root=$1
    local count=0
    local entry relative
    while IFS= read -r -d '' entry; do
        relative=${entry#"$root"/}
        case "$relative" in
            Media.xcassets|Media.xcassets/GradientFirst.colorset|Media.xcassets/GradientSecond.colorset|\
            images|images/icon_logo|symbols|symbols/magnifyingglass)
                [[ -d "$entry" && ! -L "$entry" ]] \
                    || fail "invalid directory in normalized bundle: $relative"
                ;;
            Media.xcassets/Contents.json|\
            Media.xcassets/GradientFirst.colorset/Contents.json|\
            Media.xcassets/GradientSecond.colorset/Contents.json|\
            icon_logo.png|icon_logo@2x.png|icon_logo@3x.png|\
            icon_magnifying_glass.png|icon_magnifying_glass@2x.png|icon_magnifying_glass@3x.png|\
            images/icon_logo/default@1x.png|images/icon_logo/default@2x.png|images/icon_logo/default@3x.png|\
            resource-index.json|\
            symbols/magnifyingglass/default@1x.png|symbols/magnifyingglass/default@2x.png|symbols/magnifyingglass/default@3x.png)
                [[ -f "$entry" && ! -L "$entry" ]] \
                    || fail "invalid file in normalized bundle: $relative"
                ;;
            *) fail "unexpected normalized bundle entry: $relative" ;;
        esac
        count=$((count + 1))
    done < <(find "$root" -mindepth 1 -print0)
    [[ $count -eq 23 ]] || fail "normalized bundle inventory count drifted: $count"

    local expected_sha expected_size relative_path actual_sha actual_size
    while read -r expected_sha expected_size relative_path; do
        [[ -n "$relative_path" ]] || continue
        [[ -f "$root/$relative_path" && ! -L "$root/$relative_path" ]] \
            || fail "normalized bundle file is missing: $relative_path"
        actual_sha=$(sha256_file "$root/$relative_path")
        actual_size=$(file_size "$root/$relative_path")
        [[ "$actual_sha" == "$expected_sha" && "$actual_size" == "$expected_size" ]] \
            || fail "normalized bundle file drifted: $relative_path"
    done < <(expected_bundle_files)
}

validate_bundle_inventory "$normalized_bundle"

assets_sha256=$(sha256_file "$assets_source")
widget_sha256=$(sha256_file "$widget_source")
[[ "$assets_sha256" == "$expected_assets_sha256" ]] \
    || fail "Assets.swift hash drifted: $assets_sha256"
[[ "$widget_sha256" == "$expected_widget_sha256" ]] \
    || fail "SearchWidgetView.swift hash drifted: $widget_sha256"

probe_root=$(mktemp -d "${TMPDIR:-/tmp}/focus-widget-swiftui-runtime.XXXXXX")
[[ -d "$probe_root" && "$probe_root" == *focus-widget-swiftui-runtime.* ]] \
    || fail "could not create a private proof root"
chmod 0700 "$probe_root"
cleanup() {
    if [[ "${KEEP_FOCUS_WIDGET_SWIFTUI_RUNTIME_PROBE:-0}" == "1" ]]; then
        echo "kept probe directory: $probe_root"
    else
        rm -rf "$probe_root"
    fi
}
trap cleanup EXIT
mkdir -p "$probe_root/home" "$probe_root/Sources/FocusWidgetRuntimeProbe/Resources"

git_executable=$(command -v git) || fail "git is required"
git_home="$probe_root/home/git"
mkdir -p "$git_home"
git_clean() {
    env -i \
        HOME="$git_home" \
        PATH="$(dirname "$git_executable"):/usr/bin:/bin" \
        LC_ALL=C \
        GIT_CONFIG_NOSYSTEM=1 \
        GIT_CONFIG_GLOBAL=/dev/null \
        "$git_executable" "$@"
}

focus_repo=$(git_clean -C "$focus_package_root" rev-parse --show-toplevel 2>/dev/null) \
    || fail "BlockzillaPackage must be inside the pinned Focus Git checkout"
focus_revision=$(git_clean -C "$focus_repo" rev-parse HEAD)
[[ "$focus_revision" == "$expected_focus_revision" ]] \
    || fail "Focus revision drifted: $focus_revision"
focus_status_before=$(git_clean -C "$focus_repo" status --porcelain=v1 --untracked-files=all)
[[ -z "$focus_status_before" ]] || fail "Focus checkout has tracked or ordinary untracked changes"
focus_prefix=$(git_clean -C "$focus_package_root" rev-parse --show-prefix)
for entry in "Assets.swift:$assets_source" "SearchWidgetView.swift:$widget_source"; do
    name=${entry%%:*}
    source=${entry#*:}
    git_path="${focus_prefix}Sources/Widget/$name"
    [[ "$(git_clean -C "$focus_repo" ls-files -v -- "$git_path")" == "H $git_path" ]] \
        || fail "$git_path has a non-normal Git index flag"
    [[ "$(git_clean -C "$focus_repo" rev-parse "HEAD:$git_path")" == \
       "$(git_clean -C "$focus_repo" hash-object "$source")" ]] \
        || fail "$git_path does not match its pinned Git blob"
done

open_uikit_revision=$(git_clean -C "$open_uikit_root" rev-parse HEAD)
open_uikit_status_before=$(git_clean -C "$open_uikit_root" status --porcelain=v1 --untracked-files=all)
[[ -z "$open_uikit_status_before" ]] \
    || fail "OpenUIKit checkout has tracked or untracked changes"

font_dir=${OPENUIKIT_FONT_DIR:-/System/Library/Fonts}
font_dir=$(cd "$font_dir" 2>/dev/null && pwd -P) \
    || fail "OPENUIKIT_FONT_DIR does not exist: $font_dir"
for font in SFNS.ttf SFNSMono.ttf SFNSItalic.ttf; do
    [[ -f "$font_dir/$font" && ! -L "$font_dir/$font" ]] \
        || fail "deterministic font is missing or symlinked: $font_dir/$font"
done

target_root="$probe_root/Sources/FocusWidgetRuntimeProbe"
cp -p "$assets_source" "$target_root/Assets.swift"
cp -p "$widget_source" "$target_root/SearchWidgetView.swift"
cp -p "$harness_source" "$target_root/RuntimeMain.swift"
for top_level in Media.xcassets icon_logo.png icon_logo@2x.png icon_logo@3x.png \
    icon_magnifying_glass.png icon_magnifying_glass@2x.png icon_magnifying_glass@3x.png \
    images resource-index.json symbols; do
    cp -Rp "$normalized_bundle/$top_level" "$target_root/Resources/$top_level"
done
[[ "$(sha256_file "$target_root/Assets.swift")" == "$assets_sha256" ]] \
    || fail "staged Assets.swift changed"
[[ "$(sha256_file "$target_root/SearchWidgetView.swift")" == "$widget_sha256" ]] \
    || fail "staged SearchWidgetView.swift changed"
validate_bundle_inventory "$target_root/Resources"

cat > "$probe_root/Package.swift" <<'SWIFT'
// swift-tools-version:5.9
import Foundation
import PackageDescription

guard let openUIKitRoot = ProcessInfo.processInfo.environment["OPENUIKIT_S1_ROOT"] else {
    fatalError("OPENUIKIT_S1_ROOT is required")
}

let package = Package(
    name: "FocusWidgetSwiftUIRuntimeProbe",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(name: "OpenUIKitUnderTest", path: openUIKitRoot),
    ],
    targets: [
        .executableTarget(
            name: "FocusWidgetRuntimeProbe",
            dependencies: [
                .product(name: "SwiftUI", package: "OpenUIKitUnderTest"),
                .product(name: "OpenUIKit", package: "OpenUIKitUnderTest"),
            ],
            resources: [
                .copy("Resources/Media.xcassets"),
                .copy("Resources/icon_logo.png"),
                .copy("Resources/icon_logo@2x.png"),
                .copy("Resources/icon_logo@3x.png"),
                .copy("Resources/icon_magnifying_glass.png"),
                .copy("Resources/icon_magnifying_glass@2x.png"),
                .copy("Resources/icon_magnifying_glass@3x.png"),
                .copy("Resources/images"),
                .copy("Resources/resource-index.json"),
                .copy("Resources/symbols"),
            ]
        ),
    ]
)
SWIFT

mkdir -p "$probe_root/home/swift"
echo "==> building exact-source Focus widget runtime probe"
HOME="$probe_root/home/swift" OPENUIKIT_S1_ROOT="$open_uikit_root" \
    swift build --package-path "$probe_root" -c release --product FocusWidgetRuntimeProbe

bin_path=$(HOME="$probe_root/home/swift" OPENUIKIT_S1_ROOT="$open_uikit_root" \
    swift build --package-path "$probe_root" -c release --show-bin-path)
accessor="$bin_path/FocusWidgetRuntimeProbe.build/DerivedSources/resource_bundle_accessor.swift"
[[ -f "$accessor" && ! -L "$accessor" && -s "$accessor" ]] \
    || fail "SwiftPM did not generate the probe target's Bundle.module accessor"
grep -q 'static let module' "$accessor" || fail "generated accessor has no Bundle.module"

probe_executable="$bin_path/FocusWidgetRuntimeProbe"
[[ -x "$probe_executable" ]] || fail "runtime probe executable was not emitted"

nm "$probe_executable" > "$probe_root/native-symbols.txt"
grep -Eq '^[[:xdigit:]]+[[:space:]]+[BbDdRrSsTtVvWw][[:space:]]+_?\$s7SwiftUI' \
    "$probe_root/native-symbols.txt" \
    || fail "native executable does not define the local SwiftUI implementation"
grep -Eq '^[[:xdigit:]]+[[:space:]]+[BbDdRrSsTtVvWw][[:space:]]+_?.*FocusWidgetRuntimeProbe.*SearchB4View' \
    "$probe_root/native-symbols.txt" \
    || fail "native executable does not define the exact SearchWidgetView"
case "$(uname -s)" in
    Darwin)
        binary_format=$(file "$probe_executable")
        [[ "$binary_format" == *"Mach-O"*"executable"* ]] \
            || fail "host proof did not emit a native Mach-O executable"
        otool -L "$probe_executable" > "$probe_root/dynamic-linkage.txt"
        ;;
    Linux)
        readelf -h "$probe_executable" > "$probe_root/elf-header.txt"
        grep -q '^ELF Header:' "$probe_root/elf-header.txt" \
            || fail "Linux proof did not emit a native ELF executable"
        grep -Eq 'Type:.*(EXEC|Position-Independent Executable)' "$probe_root/elf-header.txt" \
            || fail "Linux ELF artifact is not executable"
        binary_format="ELF $(uname -m) executable (readelf-attested)"
        ldd "$probe_executable" > "$probe_root/dynamic-linkage.txt"
        ;;
    *) fail "unsupported native proof platform: $(uname -s)" ;;
esac
if grep -Eq '(^|/)(lib)?(SwiftUI|SwiftUICore|OpenUIKit)(\.|/)|(SwiftUI|SwiftUICore|OpenUIKit)\.framework' \
    "$probe_root/dynamic-linkage.txt"; then
    fail "SwiftUI/SwiftUICore/OpenUIKit unexpectedly appears as a dynamic dependency"
fi

built_bundle=$(find "$bin_path" -maxdepth 1 -type d \
    \( -name 'FocusWidgetSwiftUIRuntimeProbe_FocusWidgetRuntimeProbe.bundle' \
       -o -name 'FocusWidgetSwiftUIRuntimeProbe_FocusWidgetRuntimeProbe.resources' \) \
    -print -quit)
[[ -n "$built_bundle" ]] || fail "SwiftPM resource bundle was not emitted"
validate_bundle_inventory "$built_bundle"

probe_png="$probe_root/focus-widget.png"
echo "==> running exact SearchWidgetView through UIHostingController"
(cd "$open_uikit_root" && "$probe_executable" \
    "$probe_png" "$open_uikit_root/Sources/OpenUIKit/Resources" "$font_dir") \
    | tee "$probe_root/runtime.log"
[[ -f "$probe_png" && ! -L "$probe_png" ]] || fail "runtime did not emit a PNG"
png_sha256=$(sha256_file "$probe_png")
png_size=$(file_size "$probe_png")
if [[ -n "$expected_png_sha256" ]]; then
    [[ "$png_sha256" == "$expected_png_sha256" ]] \
        || fail "rendered PNG bytes drifted: $png_sha256"
fi

[[ "$(sha256_file "$assets_source")" == "$assets_sha256" ]] \
    || fail "Focus Assets.swift changed during the proof"
[[ "$(sha256_file "$widget_source")" == "$widget_sha256" ]] \
    || fail "Focus SearchWidgetView.swift changed during the proof"
focus_status_after=$(git_clean -C "$focus_repo" status --porcelain=v1 --untracked-files=all)
[[ "$focus_status_after" == "$focus_status_before" ]] \
    || fail "Focus checkout changed during the proof"
open_uikit_status_after=$(git_clean -C "$open_uikit_root" status --porcelain=v1 --untracked-files=all)
[[ "$open_uikit_status_after" == "$open_uikit_status_before" ]] \
    || fail "OpenUIKit checkout changed during the proof"
validate_bundle_inventory "$normalized_bundle"

cp -p "$probe_png" "$output_path"
[[ "$(sha256_file "$output_path")" == "$png_sha256" ]] \
    || fail "published PNG changed while copying"

echo "PASS: exact unchanged Focus widget rendered to deterministic PNG"
echo "platform: $(uname -s)/$(uname -m)"
echo "native executable: $binary_format"
echo "SwiftUI/SwiftUICore/OpenUIKit linkage: local static SwiftPM objects (no dynamic dependency)"
swift --version | sed 's/^/toolchain: /'
echo "OpenUIKit revision: $open_uikit_revision"
echo "Focus revision: $focus_revision"
echo "Assets.swift sha256: $assets_sha256"
echo "SearchWidgetView.swift sha256: $widget_sha256"
echo "normalized Focus_Widget.bundle manifest sha256: 79504d26d5d8adb91e4706df005a8d79f588bcc7642b806fef89c045f2fed625"
echo "generated support: $accessor"
echo "PNG: $output_path"
echo "PNG bytes: $png_size"
echo "PNG sha256: $png_sha256"
