#!/usr/bin/env bash
# Emit Focus's seven DesignSystem Swift sources byte-for-byte unchanged against
# this package's literal UIKit, SwiftUI, and OpenUIKit modules.  The sole extra
# Swift input is SwiftPM's clearly identified Bundle.module resource accessor.

set -euo pipefail

usage() {
    echo "usage: $0 /path/to/focus-ios/BlockzillaPackage" >&2
    exit 64
}

[[ $# -eq 1 ]] || usage

script_dir=$(cd "$(dirname "$0")" && pwd -P)
open_uikit_root=$(cd "$script_dir/.." && pwd -P)
focus_package_root=$(cd "$1" 2>/dev/null && pwd -P) || usage
focus_repo=$(git -C "$focus_package_root" rev-parse --show-toplevel 2>/dev/null) || {
    echo "error: Focus package must be inside its pinned git checkout" >&2
    exit 66
}

readonly expected_focus_revision="a2832521c1daa0c23419c73705ae043ed60c9791"
focus_revision=$(git -C "$focus_repo" rev-parse HEAD)
[[ "$focus_revision" == "$expected_focus_revision" ]] || {
    echo "error: expected Focus $expected_focus_revision, found $focus_revision" >&2
    exit 65
}
focus_status_before=$(git -C "$focus_repo" status --porcelain=v1 --untracked-files=all)
[[ -z "$focus_status_before" ]] || {
    echo "error: Focus checkout must be clean" >&2
    printf '%s\n' "$focus_status_before" >&2
    exit 65
}
open_uikit_status_before=$(git -C "$open_uikit_root" status --porcelain=v1 --untracked-files=all)

relative_sources=(
    "Bundle+CurrentBundle.swift"
    "Preview Files/AppColorsView.swift"
    "Preview Files/AppFontsView.swift"
    "Preview Files/AppImagesView.swift"
    "UIColor+AppColors.swift"
    "UIFont+AppFonts.swift"
    "UIImage+AppImages.swift"
)
expected_sha256=(
    "725315f04ecbbe4bdeceb73bdf07550e2c3f38307696d0fa7035600e018ca3af"
    "0bcfbf1b672fdd82d305a8fd0fbbc319e59285b43b7aa7d4566cf445e5ecd2f1"
    "99da3374150876e5212adc7f9baca7f1cd4c62afea40919a64ac31a700e7e00a"
    "59f55ca617ce706cb7abe85b3d44f192261fb8690ba05b8eab4fde02f1664508"
    "4078f76f180d37f6d560dd63d59ef161302a73b7f416933533663700c314224f"
    "ac4895febb0ad6c588ada61420b0b271afb33092d76e1dbed828ee8b337c83e6"
    "ba5720a57aa90406b95a66ea62433557b666c1558d59781018de050585797734"
)

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

focus_sources="$focus_package_root/Sources/DesignSystem"
for index in "${!relative_sources[@]}"; do
    source="$focus_sources/${relative_sources[$index]}"
    [[ -f "$source" && ! -L "$source" ]] || {
        echo "error: expected regular, non-symlink source: $source" >&2
        exit 66
    }
    actual=$(sha256_file "$source")
    [[ "$actual" == "${expected_sha256[$index]}" ]] || {
        echo "error: ${relative_sources[$index]} hash drifted: $actual" >&2
        exit 65
    }
done

probe_root=$(mktemp -d "${TMPDIR:-/tmp}/focus-designsystem-swiftui.XXXXXX")
cleanup() {
    if [[ "${KEEP_FOCUS_DESIGNSYSTEM_SWIFTUI_PROBE:-0}" == "1" ]]; then
        echo "kept probe directory: $probe_root"
    else
        rm -rf "$probe_root"
    fi
}
trap cleanup EXIT

target_root="$probe_root/Sources/DesignSystemProbe"
mkdir -p "$target_root/Preview Files" "$target_root/Resources"
target_root=$(cd "$target_root" && pwd -P)
for index in "${!relative_sources[@]}"; do
    relative="${relative_sources[$index]}"
    cp -p "$focus_sources/$relative" "$target_root/$relative"
    [[ "$(sha256_file "$target_root/$relative")" == "${expected_sha256[$index]}" ]]
done
printf '%s\n' "SwiftPM-generated Bundle.module accessor trigger" \
    > "$target_root/Resources/probe.txt"

cat > "$probe_root/Package.swift" <<'SWIFT'
// swift-tools-version:5.9
import Foundation
import PackageDescription

guard let root = ProcessInfo.processInfo.environment["OPENUIKIT_S15_ROOT"] else {
    fatalError("OPENUIKIT_S15_ROOT is required")
}

let package = Package(
    name: "FocusDesignSystemSwiftUIProbe",
    platforms: [.macOS(.v11)],
    dependencies: [.package(name: "OpenUIKitUnderTest", path: root)],
    targets: [
        .target(
            name: "DesignSystemProbe",
            dependencies: [
                .product(name: "UIKit", package: "OpenUIKitUnderTest"),
                .product(name: "SwiftUI", package: "OpenUIKitUnderTest"),
            ],
            resources: [.copy("Resources")],
            swiftSettings: [.unsafeFlags(["-warnings-as-errors"])]
        ),
    ]
)
SWIFT

# SwiftPM establishes the dependency graph and generates its normal resource
# accessor. `-warnings-as-errors` is scoped to DesignSystemProbe, so successful
# module emission proves its eight Swift inputs produced neither warnings nor
# errors even if a dependency package prints an unrelated C/manifest warning.
OPENUIKIT_S15_ROOT="$open_uikit_root" \
    swift build --package-path "$probe_root" --target DesignSystemProbe \
    > "$probe_root/swiftpm.log" 2>&1 || {
        cat "$probe_root/swiftpm.log" >&2
        exit 70
    }

generated_accessor=$(find "$probe_root/.build" -type f \
    -path '*/DesignSystemProbe.build/DerivedSources/resource_bundle_accessor.swift' \
    -print -quit)
[[ -n "$generated_accessor" && -s "$generated_accessor" ]] || {
    echo "error: SwiftPM Bundle.module accessor was not generated" >&2
    exit 70
}
generated_accessor=$(cd "$(dirname "$generated_accessor")" && pwd -P)/$(basename "$generated_accessor")

module_artifact=$(find "$probe_root/.build" -type f \
    -path '*/Modules/DesignSystemProbe.swiftmodule' -print -quit)
[[ -n "$module_artifact" && -s "$module_artifact" ]] || {
    echo "error: exact-source module artifact was not emitted" >&2
    exit 70
}

source_manifest=$(find "$probe_root/.build" -type f \
    -path '*/DesignSystemProbe.build/sources' -print -quit)
[[ -n "$source_manifest" && -s "$source_manifest" ]] || {
    echo "error: DesignSystemProbe input manifest was not emitted" >&2
    exit 70
}
[[ "$(wc -l < "$source_manifest" | tr -d ' ')" == "8" ]] || {
    echo "error: expected exactly seven app sources plus one generated accessor" >&2
    cat "$source_manifest" >&2
    exit 70
}
for relative in "${relative_sources[@]}"; do
    grep -Fq "$target_root/$relative" "$source_manifest" || {
        echo "error: exact source missing from compiler input manifest: $relative" >&2
        exit 70
    }
done
grep -Fq "$generated_accessor" "$source_manifest" || {
    echo "error: generated accessor missing from compiler input manifest" >&2
    exit 70
}

[[ -z "$(git -C "$focus_repo" status --porcelain=v1 --untracked-files=all)" ]] || {
    echo "error: Focus checkout changed during proof" >&2
    exit 73
}
open_uikit_status_after=$(git -C "$open_uikit_root" status --porcelain=v1 --untracked-files=all)
[[ "$open_uikit_status_after" == "$open_uikit_status_before" ]] || {
    echo "error: OpenUIKit checkout changed during proof" >&2
    exit 73
}

echo "PASS: seven unchanged Focus DesignSystem Swift sources emitted with zero diagnostics"
echo "Focus revision: $focus_revision"
for index in "${!relative_sources[@]}"; do
    echo "${relative_sources[$index]} sha256: ${expected_sha256[$index]}"
done
echo "Generated support: $generated_accessor (SwiftPM Bundle.module accessor only)"
echo "Artifact: $module_artifact"
