#!/usr/bin/env bash
# Fail-closed compile-and-runtime proof for Mozilla Focus's complete Licenses
# target. The two Swift inputs and two plist resources are copied byte-for-byte
# from the pinned checkout. SwiftPM's resource accessor and the separately
# named runtime probe are generated build support, never app-source overlays.

set -euo pipefail
umask 077

usage() {
    echo "usage: $0 /path/to/focus-ios/BlockzillaPackage" >&2
    echo "       macOS also verifies swift:6.2-noble unless FOCUS_LICENSES_SKIP_LINUX=1" >&2
    exit 64
}

fail() {
    echo "error: $*" >&2
    exit 1
}

[[ $# -eq 1 ]] || usage

script_dir=$(cd "$(dirname "$0")" && pwd -P)
open_uikit_root=$(cd "$script_dir/.." && pwd -P)
focus_package_root=$(cd "$1" 2>/dev/null && pwd -P) || usage
focus_repo=$(git -c safe.directory='*' -C "$focus_package_root" \
    rev-parse --show-toplevel 2>/dev/null) \
    || fail "BlockzillaPackage must be inside the pinned Focus checkout"
focus_repo=$(cd "$focus_repo" && pwd -P)
case "$focus_package_root" in
    "$focus_repo"/*) focus_package_relative=${focus_package_root#"$focus_repo"/} ;;
    *) fail "BlockzillaPackage escaped the Focus checkout" ;;
esac

readonly expected_focus_revision="a2832521c1daa0c23419c73705ae043ed60c9791"
focus_revision=$(git -c safe.directory='*' -C "$focus_repo" rev-parse HEAD)
[[ "$focus_revision" == "$expected_focus_revision" ]] \
    || fail "expected Focus $expected_focus_revision, found $focus_revision"

focus_status_before=$(git -c safe.directory='*' -C "$focus_repo" \
    status --porcelain=v1 --untracked-files=all)
[[ -z "$focus_status_before" ]] || {
    printf '%s\n' "$focus_status_before" >&2
    fail "Focus checkout must be clean"
}
open_uikit_status_before=$(git -c safe.directory='*' -C "$open_uikit_root" \
    status --porcelain=v1 --untracked-files=all)

sha256_file() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        fail "shasum or sha256sum is required"
    fi
}

readonly licenses_root="$focus_package_root/Sources/Licenses"
relative_inputs=(
    "LicenseList.swift"
    "LicenseListView.swift"
    "focus-ios.plist"
    "license-list.plist"
)
expected_sha256=(
    "6f3d90217325a02ddf5178c0018c511846fb21e3e6dac73986e02cbd7f004825"
    "0a12bcaf8132a4b07f66dcdc7865537de9b0f5d2e4b0bf6601165ee060582a86"
    "63812032c2b82d2eb8269ed63458192e2783a3274919bf751b7ec6c09791376d"
    "560a8535f642e0f42ea9a4b155491256d4405e57dcca3f1565509ad6bf10f1d8"
)

actual_inputs=()
while IFS= read -r input; do
    actual_inputs+=("${input#"$licenses_root"/}")
done < <(find "$licenses_root" \( -type f -o -type l \) -print | LC_ALL=C sort)
[[ ${#actual_inputs[@]} -eq 4 ]] \
    || fail "expected exactly four Licenses inputs, found ${#actual_inputs[@]}"
for index in "${!relative_inputs[@]}"; do
    [[ "${actual_inputs[$index]}" == "${relative_inputs[$index]}" ]] \
        || fail "Licenses inventory drift at item $index"
    input="$licenses_root/${relative_inputs[$index]}"
    [[ -f "$input" && ! -L "$input" ]] \
        || fail "expected regular non-symlink Licenses input: $input"
    actual_hash=$(sha256_file "$input")
    [[ "$actual_hash" == "${expected_sha256[$index]}" ]] \
        || fail "Licenses hash drift: ${relative_inputs[$index]} ($actual_hash)"
done

probe_root=$(mktemp -d "${TMPDIR:-/tmp}/focus-licenses-swiftui.XXXXXX")
probe_root=$(cd "$probe_root" && pwd -P)
cleanup() {
    if [[ "${KEEP_FOCUS_LICENSES_SWIFTUI_PROBE:-0}" == "1" ]]; then
        echo "kept probe directory: $probe_root"
    else
        rm -rf "$probe_root"
    fi
}
trap cleanup EXIT

target_root="$probe_root/Sources/LicensesExact"
runtime_root="$probe_root/Sources/LicensesRuntime"
mkdir -p "$target_root" "$runtime_root"
for index in "${!relative_inputs[@]}"; do
    relative=${relative_inputs[$index]}
    cp -p "$licenses_root/$relative" "$target_root/$relative"
    [[ "$(sha256_file "$target_root/$relative")" == "${expected_sha256[$index]}" ]] \
        || fail "copy changed bytes: $relative"
done

cat > "$probe_root/Package.swift" <<'SWIFT'
// swift-tools-version:5.9
import Foundation
import PackageDescription

guard let root = ProcessInfo.processInfo.environment["OPENUIKIT_LICENSES_ROOT"] else {
    fatalError("OPENUIKIT_LICENSES_ROOT is required")
}

let package = Package(
    name: "FocusLicensesSwiftUIProof",
    platforms: [.macOS(.v11)],
    dependencies: [.package(name: "OpenUIKitUnderTest", path: root)],
    targets: [
        .target(
            name: "LicensesExact",
            dependencies: [
                .product(name: "UIKit", package: "OpenUIKitUnderTest"),
                .product(name: "SwiftUI", package: "OpenUIKitUnderTest"),
            ],
            resources: [
                .copy("focus-ios.plist"),
                .copy("license-list.plist"),
            ],
            swiftSettings: [.unsafeFlags(["-warnings-as-errors"])]
        ),
        .executableTarget(
            name: "LicensesRuntime",
            dependencies: [
                "LicensesExact",
                .product(name: "UIKit", package: "OpenUIKitUnderTest"),
                .product(name: "SwiftUI", package: "OpenUIKitUnderTest"),
            ],
            swiftSettings: [.unsafeFlags(["-warnings-as-errors"])]
        ),
    ]
)
SWIFT

cat > "$runtime_root/main.swift" <<'SWIFT'
// Generated runtime proof. This is not Mozilla Focus app source.
import LicensesExact
import SwiftUI
import UIKit

@MainActor
private func descendants(_ root: UIView) -> [UIView] {
    root.subviews.flatMap { [$0] + descendants($0) }
}

@main
struct LicensesRuntime {
    @MainActor
    static func main() {
        let controller = UIHostingController(rootView: LicenseListView())
        let host = controller.view!
        host.frame = CGRect(x: 0, y: 0, width: 320, height: 176)
        host.layoutIfNeeded()
        let rows = descendants(host).compactMap { $0 as? UIControl }.filter {
            $0.accessibilityIdentifier == "SwiftUI.NavigationLink"
        }
        precondition(rows.count == 8, "expected 8 decoded license rows, got \(rows.count)")
        precondition(
            rows.map(\.frame.origin.y) == [0, 44, 88, 132, 176, 220, 264, 308],
            "license row order/geometry drifted"
        )
        print("LICENSES_RUNTIME_OK rows=\(rows.count)")
    }
}
SWIFT

export OPENUIKIT_LICENSES_ROOT="$open_uikit_root"
echo "==> exact Licenses release module"
swift build -c release --package-path "$probe_root" --target LicensesExact \
    > "$probe_root/LicensesExact.log" 2>&1 || {
        cat "$probe_root/LicensesExact.log" >&2
        fail "exact Licenses release module emission failed"
    }

source_manifest=$(find "$probe_root/.build" -type f \
    -path '*/LicensesExact.build/sources' -print -quit)
[[ -n "$source_manifest" && -s "$source_manifest" ]] \
    || fail "LicensesExact compiler source manifest is missing"
[[ "$(wc -l < "$source_manifest" | tr -d ' ')" == "3" ]] \
    || fail "expected two exact sources plus one generated resource accessor"
for relative in LicenseList.swift LicenseListView.swift; do
    grep -Fqx "$target_root/$relative" "$source_manifest" \
        || fail "exact app source missing from compiler manifest: $relative"
done
generated_accessor=$(find "$probe_root/.build" -type f \
    -path '*/LicensesExact.build/DerivedSources/resource_bundle_accessor.swift' \
    -print -quit)
[[ -n "$generated_accessor" && -s "$generated_accessor" ]] \
    || fail "SwiftPM resource accessor was not generated"
generated_accessor=$(cd "$(dirname "$generated_accessor")" && pwd -P)/$(basename "$generated_accessor")
grep -Fqx "$generated_accessor" "$source_manifest" \
    || fail "generated resource accessor missing from compiler manifest"

module_artifact=$(find "$probe_root/.build" -type f \
    -path '*/release/Modules/LicensesExact.swiftmodule' -print -quit)
[[ -n "$module_artifact" && -s "$module_artifact" ]] \
    || fail "LicensesExact release module was not emitted"

echo "==> exact Licenses runtime/resource decode"
swift build -c release --package-path "$probe_root" --product LicensesRuntime \
    > "$probe_root/LicensesRuntime.log" 2>&1 || {
        cat "$probe_root/LicensesRuntime.log" >&2
        fail "Licenses runtime build failed"
    }
runtime_binary=$(find "$probe_root/.build" -type f \
    -path '*/release/LicensesRuntime' -print -quit)
[[ -n "$runtime_binary" && -s "$runtime_binary" ]] \
    || fail "Licenses runtime executable was not emitted"
runtime_output=$($runtime_binary)
[[ "$runtime_output" == "LICENSES_RUNTIME_OK rows=8" ]] \
    || fail "unexpected Licenses runtime output: $runtime_output"

for index in "${!relative_inputs[@]}"; do
    relative=${relative_inputs[$index]}
    [[ "$(sha256_file "$target_root/$relative")" == "${expected_sha256[$index]}" ]] \
        || fail "copied exact input changed during build: $relative"
done
[[ -z "$(git -c safe.directory='*' -C "$focus_repo" \
    status --porcelain=v1 --untracked-files=all)" ]] \
    || fail "Focus checkout changed during proof"
open_uikit_status_after=$(git -c safe.directory='*' -C "$open_uikit_root" \
    status --porcelain=v1 --untracked-files=all)
[[ "$open_uikit_status_after" == "$open_uikit_status_before" ]] \
    || fail "OpenUIKit checkout changed during proof"

echo "PASS: two exact Focus Licenses sources emitted and decoded 8 resource rows"
echo "Focus revision: $focus_revision"
echo "Generated support: SwiftPM resource accessor + isolated runtime probe"
echo "Artifact: $module_artifact"

if [[ "$(uname -s)" == "Darwin" \
   && "${FOCUS_LICENSES_SKIP_LINUX:-0}" != "1" ]]; then
    command -v docker >/dev/null 2>&1 || fail "Docker is required for Linux verification"
    docker info >/dev/null 2>&1 || fail "Docker daemon is not available"
    image=${SWIFT_LINUX_IMAGE:-swift:6.2-noble}
    echo "==> stock Linux exact-source runtime ($image)"
    docker run --rm \
        -v "$open_uikit_root:/src:ro" \
        -v "$focus_repo:/focus:ro" \
        "$image" \
        bash /src/scripts/prove_focus_licenses_swiftui.sh \
            "/focus/$focus_package_relative"
    echo "PORTABILITY VERIFIED: exact Focus Licenses target on macOS + stock Linux"
fi
