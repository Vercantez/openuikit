#!/usr/bin/env bash
# Compile Focus's two Widget SwiftUI sources byte-for-byte unchanged against
# this package's literal SwiftUI product.  All staging and SwiftPM-generated
# Bundle.module support live in a fresh temporary directory.

set -euo pipefail

usage() {
    echo "usage: $0 /path/to/focus-ios/BlockzillaPackage" >&2
    exit 64
}

[[ $# -eq 1 ]] || usage

script_dir=$(cd "$(dirname "$0")" && pwd -P)
open_uikit_root=$(cd "$script_dir/.." && pwd -P)
focus_package_root=$(cd "$1" 2>/dev/null && pwd -P) || usage
focus_sources="$focus_package_root/Sources/Widget"
assets_source="$focus_sources/Assets.swift"
widget_source="$focus_sources/SearchWidgetView.swift"

readonly expected_assets_sha256="efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e"
readonly expected_widget_sha256="721669388a4556e1609f580ed87d6065b63981770e71b0f77db292767b05f6c2"

for source in "$assets_source" "$widget_source"; do
    [[ -f "$source" && ! -L "$source" ]] || {
        echo "error: expected a regular, non-symlink source: $source" >&2
        exit 66
    }
done

sha256_file() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        echo "error: shasum or sha256sum is required" >&2
        exit 69
    fi
}

assets_sha256=$(sha256_file "$assets_source")
widget_sha256=$(sha256_file "$widget_source")
[[ "$assets_sha256" == "$expected_assets_sha256" ]] || {
    echo "error: Assets.swift hash drifted: $assets_sha256" >&2
    exit 65
}
[[ "$widget_sha256" == "$expected_widget_sha256" ]] || {
    echo "error: SearchWidgetView.swift hash drifted: $widget_sha256" >&2
    exit 65
}

focus_repo=$(git -C "$focus_package_root" rev-parse --show-toplevel 2>/dev/null || true)
focus_status_before=""
focus_revision="not-a-git-checkout"
if [[ -n "$focus_repo" ]]; then
    focus_status_before=$(git -C "$focus_repo" status --porcelain=v1 --untracked-files=all)
    focus_revision=$(git -C "$focus_repo" rev-parse HEAD)
fi
open_uikit_status_before=$(git -C "$open_uikit_root" status --porcelain=v1 --untracked-files=all)

probe_root=$(mktemp -d "${TMPDIR:-/tmp}/focus-widget-swiftui.XXXXXX")
cleanup() {
    if [[ "${KEEP_FOCUS_WIDGET_SWIFTUI_PROBE:-0}" == "1" ]]; then
        echo "kept probe directory: $probe_root"
    else
        rm -rf "$probe_root"
    fi
}
trap cleanup EXIT

target_root="$probe_root/Sources/WidgetProbe"
mkdir -p "$target_root/Resources"
cp -p "$assets_source" "$target_root/Assets.swift"
cp -p "$widget_source" "$target_root/SearchWidgetView.swift"
printf '%s\n' "SwiftPM resource accessor compile probe" > "$target_root/Resources/probe.txt"

[[ "$(sha256_file "$target_root/Assets.swift")" == "$assets_sha256" ]]
[[ "$(sha256_file "$target_root/SearchWidgetView.swift")" == "$widget_sha256" ]]

cat > "$probe_root/Package.swift" <<'SWIFT'
// swift-tools-version:5.9
import Foundation
import PackageDescription

guard let openUIKitRoot = ProcessInfo.processInfo.environment["OPENUIKIT_S1_ROOT"] else {
    fatalError("OPENUIKIT_S1_ROOT is required")
}

let package = Package(
    name: "FocusWidgetSwiftUIProbe",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(name: "OpenUIKitUnderTest", path: openUIKitRoot),
    ],
    targets: [
        .target(
            name: "WidgetProbe",
            dependencies: [
                .product(name: "SwiftUI", package: "OpenUIKitUnderTest"),
            ],
            resources: [.copy("Resources")]
        ),
    ]
)
SWIFT

OPENUIKIT_S1_ROOT="$open_uikit_root" \
    swift build --package-path "$probe_root" --target WidgetProbe

module_artifact=$(find "$probe_root/.build" -type f \
    \( -name 'WidgetProbe.swiftmodule' -o -name 'WidgetProbe.swiftinterface' \) \
    -print -quit)
[[ -n "$module_artifact" && -s "$module_artifact" ]] || {
    echo "error: WidgetProbe module artifact was not emitted" >&2
    exit 70
}

if [[ -n "$focus_repo" ]]; then
    focus_status_after=$(git -C "$focus_repo" status --porcelain=v1 --untracked-files=all)
    [[ "$focus_status_after" == "$focus_status_before" ]] || {
        echo "error: Focus checkout changed during the probe" >&2
        exit 73
    }
fi
open_uikit_status_after=$(git -C "$open_uikit_root" status --porcelain=v1 --untracked-files=all)
[[ "$open_uikit_status_after" == "$open_uikit_status_before" ]] || {
    echo "error: OpenUIKit checkout changed during the probe" >&2
    exit 73
}

echo "PASS: unchanged Focus Widget SwiftUI sources compiled"
echo "Focus revision: $focus_revision"
echo "Assets.swift sha256: $assets_sha256"
echo "SearchWidgetView.swift sha256: $widget_sha256"
echo "Generated support: SwiftPM Bundle.module accessor only"
echo "Artifact: $module_artifact"
