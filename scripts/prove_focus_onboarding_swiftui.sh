#!/usr/bin/env bash
# Fail-closed proof for Mozilla Focus's complete, exact 21-source Onboarding
# target at the pinned corpus revision. App and SnapKit sources are copied
# byte-for-byte into a private SwiftPM package; all extra compiler inputs are
# separately named generated build support and checked in source manifests.

set -euo pipefail
umask 077

usage() {
    echo "usage: $0 /path/to/focus-ios/BlockzillaPackage /path/to/SnapKit" >&2
    echo "       macOS also verifies stock Linux unless FOCUS_ONBOARDING_SKIP_LINUX=1" >&2
    exit 64
}

fail() {
    echo "error: $*" >&2
    exit 1
}

[[ $# -eq 2 ]] || usage

script_dir=$(cd "$(dirname "$0")" && pwd -P)
open_uikit_root=$(cd "$script_dir/.." && pwd -P)
focus_package_root=$(cd "$1" 2>/dev/null && pwd -P) || usage
snapkit_root=$(cd "$2" 2>/dev/null && pwd -P) || usage
focus_repo=$(git -c safe.directory='*' -C "$focus_package_root" \
    rev-parse --show-toplevel 2>/dev/null) \
    || fail "BlockzillaPackage must be inside the pinned Focus checkout"
snapkit_repo=$(git -c safe.directory='*' -C "$snapkit_root" \
    rev-parse --show-toplevel 2>/dev/null) \
    || fail "SnapKit must be inside its pinned checkout"
focus_repo=$(cd "$focus_repo" && pwd -P)
snapkit_repo=$(cd "$snapkit_repo" && pwd -P)

case "$focus_package_root" in
    "$focus_repo"/*) focus_package_relative=${focus_package_root#"$focus_repo"/} ;;
    *) fail "BlockzillaPackage escaped the Focus checkout" ;;
esac
case "$snapkit_root" in
    "$snapkit_repo") snapkit_relative="." ;;
    "$snapkit_repo"/*) snapkit_relative=${snapkit_root#"$snapkit_repo"/} ;;
    *) fail "SnapKit path escaped its checkout" ;;
esac

readonly expected_focus_revision="a2832521c1daa0c23419c73705ae043ed60c9791"
readonly expected_snapkit_revision="e74fe2a978d1216c3602b129447c7301573cc2d8"
readonly expected_snapkit_debugging_sha256="6af70d54a6e6fb112d87f8adb93caead0bc2afc472e4bbb04347bf591be3b3e3"

focus_revision=$(git -c safe.directory='*' -C "$focus_repo" rev-parse HEAD)
snapkit_revision=$(git -c safe.directory='*' -C "$snapkit_repo" rev-parse HEAD)
[[ "$focus_revision" == "$expected_focus_revision" ]] \
    || fail "expected Focus $expected_focus_revision, found $focus_revision"
[[ "$snapkit_revision" == "$expected_snapkit_revision" ]] \
    || fail "expected SnapKit $expected_snapkit_revision, found $snapkit_revision"

focus_status_before=$(git -c safe.directory='*' -C "$focus_repo" \
    status --porcelain=v1 --untracked-files=all)
snapkit_status_before=$(git -c safe.directory='*' -C "$snapkit_repo" \
    status --porcelain=v1 --untracked-files=all)
[[ -z "$focus_status_before" ]] || {
    printf '%s\n' "$focus_status_before" >&2
    fail "Focus checkout must be clean"
}
[[ -z "$snapkit_status_before" ]] || {
    printf '%s\n' "$snapkit_status_before" >&2
    fail "SnapKit checkout must be clean"
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

onboarding_relative_sources=(
    "DesignSystem/Color+AppColors.swift"
    "DesignSystem/Font+AppFonts.swift"
    "DesignSystem/Image+AppImages.swift"
    "Handler/Action.swift"
    "Handler/OnboardingEventsHandlerV1.swift"
    "Handler/OnboardingEventsHandlerV2.swift"
    "Handler/OnboardingEventsHandling.swift"
    "Handler/OnboardingVersion.swift"
    "Handler/ToolTipRoute.swift"
    "OnboardingViewController.swift"
    "PortraitHostingController.swift"
    "Preview Files/OnboardingPreview.swift"
    "SwiftUI Onboarding/CardBannerView.swift"
    "SwiftUI Onboarding/DefaultBrowserOnboardingView.swift"
    "SwiftUI Onboarding/GetStartedOnboardingView.swift"
    "SwiftUI Onboarding/OnboardingView.swift"
    "SwiftUI Onboarding/OnboardingViewModel.swift"
    "SwiftUI Onboarding/ShowMeHowOnboardingView.swift"
    "Tooltip/TooltipTableViewCell.swift"
    "Tooltip/TooltipView.swift"
    "Tooltip/TooltipViewController.swift"
)
onboarding_expected_sha256=(
    "d64850a384db3bfc2961cad6f7b1d9d3522f081fa19709462c11f41893615e81"
    "845f9756402af21481e34275d2cc294d602fa4df5d90e69548ea37c8e47a3300"
    "d6731252dc45289bc513b17cf1b4ba78e7c56b399e1b6a5942c8d1352b35ae54"
    "f2a097668ce7af1b2841160888b0742fa854ff79cadb4ebb1143ed99f0a9d452"
    "1decab96dad2babe549d70985c3ce682ed08a7934eae86757ebfc108b176ff5e"
    "e71c56ec07fc0eaa7e603c63506dc49494c327abe6ae61ff34fe970cf82de3f7"
    "960587095cf787af822e1e532e1e2d15839fce7b7c9934d8f1cd142a28ca8b9e"
    "cefb37cb3082c6046b1da8afd1dc34180ce25027ab7446b829dcd07d4c66c4b3"
    "3110384c6a2be26b6250fe12f6c589b177e8a9b49380c8497f31aae6c6ae71f4"
    "3f9b569bf251378ae0cf4f52acfd06f67411403a2bbd86fca4f7f025887ef2ad"
    "efd238b2b4b3481a7a6f0f1fd63f6d458d43731e70c9cc172a8a15aa9271dd77"
    "449dcbfb79b4a4f1b4ba856c59f172d20e93bce63e55c944cdfd2a2951213a5b"
    "f74fe3774be86ed3ea54bb7c36b89db115eb3da72736c3366aba5b11a700c5aa"
    "0eebbfa3d4736fdd1e4caadd4c1806618cc18f85f54523b37898037c8ff800c6"
    "ef92bd5b89c44805b3177189ad5b3d3ad88be16f8d5e1f3307faf4c6500a87ef"
    "65cb54ccf6bc12863b8b1b026a825f826d850a71157f961c992ed6d6220b7952"
    "ae5c6d4c49d0a81fd1e7552051658c5bb116dd6b7f0d212044c3d1e33b3c24ff"
    "2ff75ad07ee409f05a61f7fe036e27b34a25142ccd464bbfc63642c35efe5291"
    "48220f0a4d2b409a19cf45819bc58561adf45fb436d264cec2de6c3936db6173"
    "7835e504e1062dc0ddfefcec5b4efaf8fae2d41fbe165653d7edf1d0a7ebf0ae"
    "0e2fa127a2584d178e893714faa4606c4f11469271617c2a10acf30038604c7a"
)

designsystem_relative_sources=(
    "Bundle+CurrentBundle.swift"
    "Preview Files/AppColorsView.swift"
    "Preview Files/AppFontsView.swift"
    "Preview Files/AppImagesView.swift"
    "UIColor+AppColors.swift"
    "UIFont+AppFonts.swift"
    "UIImage+AppImages.swift"
)
designsystem_expected_sha256=(
    "725315f04ecbbe4bdeceb73bdf07550e2c3f38307696d0fa7035600e018ca3af"
    "0bcfbf1b672fdd82d305a8fd0fbbc319e59285b43b7aa7d4566cf445e5ecd2f1"
    "99da3374150876e5212adc7f9baca7f1cd4c62afea40919a64ac31a700e7e00a"
    "59f55ca617ce706cb7abe85b3d44f192261fb8690ba05b8eab4fde02f1664508"
    "4078f76f180d37f6d560dd63d59ef161302a73b7f416933533663700c314224f"
    "ac4895febb0ad6c588ada61420b0b271afb33092d76e1dbed828ee8b337c83e6"
    "ba5720a57aa90406b95a66ea62433557b666c1558d59781018de050585797734"
)

widget_relative_sources=("Assets.swift" "SearchWidgetView.swift")
widget_expected_sha256=(
    "efac8d1c98b562374e54eea7540b4201523db670a6353eff8f0a0273d294526e"
    "721669388a4556e1609f580ed87d6065b63981770e71b0f77db292767b05f6c2"
)

onboarding_sources="$focus_package_root/Sources/Onboarding"
designsystem_sources="$focus_package_root/Sources/DesignSystem"
widget_sources="$focus_package_root/Sources/Widget"
snapkit_sources="$snapkit_root/Sources"
[[ -d "$onboarding_sources" && -d "$designsystem_sources" \
   && -d "$widget_sources" && -d "$snapkit_sources" ]] \
    || fail "one or more expected source roots are missing"

# Inventory is exact, not merely a count: an added, removed, renamed, or
# symlinked Onboarding Swift input fails before any compiler is invoked.
actual_onboarding_sources=()
while IFS= read -r source; do
    actual_onboarding_sources+=("${source#"$onboarding_sources"/}")
done < <(find "$onboarding_sources" \( -type f -o -type l \) -name '*.swift' -print \
    | LC_ALL=C sort)
[[ ${#actual_onboarding_sources[@]} -eq 21 ]] \
    || fail "expected exactly 21 Onboarding Swift sources, found ${#actual_onboarding_sources[@]}"
for index in "${!onboarding_relative_sources[@]}"; do
    [[ "${actual_onboarding_sources[$index]}" == "${onboarding_relative_sources[$index]}" ]] \
        || fail "Onboarding inventory drift at item $index"
    source="$onboarding_sources/${onboarding_relative_sources[$index]}"
    [[ -f "$source" && ! -L "$source" ]] \
        || fail "expected regular non-symlink Onboarding source: $source"
    actual_hash=$(sha256_file "$source")
    [[ "$actual_hash" == "${onboarding_expected_sha256[$index]}" ]] \
        || fail "Onboarding hash drift: ${onboarding_relative_sources[$index]} ($actual_hash)"
done

for index in "${!designsystem_relative_sources[@]}"; do
    source="$designsystem_sources/${designsystem_relative_sources[$index]}"
    [[ -f "$source" && ! -L "$source" ]] \
        || fail "expected DesignSystem source: $source"
    [[ "$(sha256_file "$source")" == "${designsystem_expected_sha256[$index]}" ]] \
        || fail "DesignSystem hash drift: ${designsystem_relative_sources[$index]}"
done
for index in "${!widget_relative_sources[@]}"; do
    source="$widget_sources/${widget_relative_sources[$index]}"
    [[ -f "$source" && ! -L "$source" ]] || fail "expected Widget source: $source"
    [[ "$(sha256_file "$source")" == "${widget_expected_sha256[$index]}" ]] \
        || fail "Widget hash drift: ${widget_relative_sources[$index]}"
done

snapkit_relative_sources=()
while IFS= read -r source; do
    snapkit_relative_sources+=("${source#"$snapkit_sources"/}")
done < <(find "$snapkit_sources" \( -type f -o -type l \) -name '*.swift' -print \
    | LC_ALL=C sort)
[[ ${#snapkit_relative_sources[@]} -eq 37 ]] \
    || fail "expected 37 pinned SnapKit Swift sources, found ${#snapkit_relative_sources[@]}"
[[ -f "$snapkit_sources/Debugging.swift" && ! -L "$snapkit_sources/Debugging.swift" ]] \
    || fail "SnapKit Debugging.swift exclusion is missing or symlinked"
[[ "$(sha256_file "$snapkit_sources/Debugging.swift")" \
    == "$expected_snapkit_debugging_sha256" ]] \
    || fail "excluded SnapKit Debugging.swift hash drifted"

probe_root=$(mktemp -d "${TMPDIR:-/tmp}/focus-onboarding-swiftui.XXXXXX")
probe_root=$(cd "$probe_root" && pwd -P)
cleanup() {
    if [[ "${KEEP_FOCUS_ONBOARDING_SWIFTUI_PROBE:-0}" == "1" ]]; then
        echo "kept probe directory: $probe_root"
    else
        rm -rf "$probe_root"
    fi
}
trap cleanup EXIT

onboarding_target="$probe_root/Sources/Onboarding"
designsystem_target="$probe_root/Sources/DesignSystem"
widget_target="$probe_root/Sources/Widget"
snapkit_target="$probe_root/Sources/SnapKit"
mkdir -p "$onboarding_target/Resources" "$designsystem_target/Resources" \
    "$widget_target/Resources" "$snapkit_target"

copy_verified_sources() {
    source_root=$1
    target_root=$2
    shift 2
    for relative in "$@"; do
        mkdir -p "$target_root/$(dirname "$relative")"
        cp -p "$source_root/$relative" "$target_root/$relative"
        [[ "$(sha256_file "$source_root/$relative")" \
            == "$(sha256_file "$target_root/$relative")" ]] \
            || fail "copy changed bytes: $relative"
    done
}

copy_verified_sources "$onboarding_sources" "$onboarding_target" \
    "${onboarding_relative_sources[@]}"
copy_verified_sources "$designsystem_sources" "$designsystem_target" \
    "${designsystem_relative_sources[@]}"
copy_verified_sources "$widget_sources" "$widget_target" \
    "${widget_relative_sources[@]}"
copy_verified_sources "$snapkit_sources" "$snapkit_target" \
    "${snapkit_relative_sources[@]}"

printf '%s\n' "SwiftPM Bundle.module accessor trigger" \
    > "$onboarding_target/Resources/probe.txt"
printf '%s\n' "SwiftPM Bundle.module accessor trigger" \
    > "$designsystem_target/Resources/probe.txt"
printf '%s\n' "SwiftPM Bundle.module accessor trigger" \
    > "$widget_target/Resources/probe.txt"

cat > "$onboarding_target/Onboarding.generated.swift" <<'SWIFT'
// Generated target support. This is not Mozilla Focus app source.
@_exported import Combine
#if os(Linux)
@_exported import ObjectiveC
#if OPENUIKIT_MANUAL_LINUX_EMISSION
import Foundation
extension Foundation.Bundle {
    static let module = Foundation.Bundle.main
}
#endif
#endif
SWIFT

cat > "$snapkit_target/SnapKit.generated.swift" <<'SWIFT'
// Generated Linux target support. This is not upstream SnapKit source.
#if os(Linux)
import Foundation

enum objc_AssociationPolicy {
    case OBJC_ASSOCIATION_COPY_NONATOMIC
    case OBJC_ASSOCIATION_RETAIN_NONATOMIC
}

private final class GeneratedAssociationEntry {
    weak var object: AnyObject?
    var values: [UInt: Any] = [:]

    init(object: AnyObject) {
        self.object = object
    }
}

private final class GeneratedAssociationStore: @unchecked Sendable {
    static let shared = GeneratedAssociationStore()
    let lock = NSLock()
    var entries: [ObjectIdentifier: GeneratedAssociationEntry] = [:]
}

func objc_getAssociatedObject(_ object: Any, _ key: UnsafeRawPointer) -> Any? {
    let object = object as AnyObject
    let identity = ObjectIdentifier(object)
    let key = UInt(bitPattern: key)
    let store = GeneratedAssociationStore.shared
    store.lock.lock()
    defer { store.lock.unlock() }
    guard let entry = store.entries[identity], entry.object === object else {
        store.entries.removeValue(forKey: identity)
        return nil
    }
    return entry.values[key]
}

func objc_setAssociatedObject(
    _ object: Any,
    _ key: UnsafeRawPointer,
    _ value: Any?,
    _ policy: objc_AssociationPolicy
) {
    _ = policy
    let object = object as AnyObject
    let identity = ObjectIdentifier(object)
    let key = UInt(bitPattern: key)
    let store = GeneratedAssociationStore.shared
    store.lock.lock()
    defer { store.lock.unlock() }
    let entry: GeneratedAssociationEntry
    if let existing = store.entries[identity], existing.object === object {
        entry = existing
    } else {
        entry = GeneratedAssociationEntry(object: object)
        store.entries[identity] = entry
    }
    entry.values[key] = value
}
#endif
SWIFT

if [[ "$(uname -s)" == "Linux" ]]; then
    mkdir -p "$probe_root/Sources/ObjectiveC"
    cat > "$probe_root/Sources/ObjectiveC/ObjectiveC.swift" <<'SWIFT'
// Generated Linux compile-support module. This is not app or SnapKit source.
@_exported import OpenUIKit
SWIFT
fi

cat > "$probe_root/Package.swift" <<'SWIFT'
// swift-tools-version:5.9
import Foundation
import PackageDescription

guard let root = ProcessInfo.processInfo.environment["OPENUIKIT_S2_ROOT"] else {
    fatalError("OPENUIKIT_S2_ROOT is required")
}

#if os(Linux)
let objectiveCTargets: [Target] = [
    .target(
        name: "ObjectiveC",
        dependencies: [.product(name: "OpenUIKit", package: "OpenUIKitUnderTest")],
        swiftSettings: [.unsafeFlags(["-warnings-as-errors"])]
    ),
]
let objectiveCDependencies: [Target.Dependency] = ["ObjectiveC"]
let onboardingInteropFlags = ["-Xfrontend", "-enable-objc-interop"]
#else
let objectiveCTargets: [Target] = []
let objectiveCDependencies: [Target.Dependency] = []
let onboardingInteropFlags: [String] = []
#endif

let package = Package(
    name: "FocusOnboardingSwiftUIProbe",
    platforms: [.macOS(.v11)],
    dependencies: [.package(name: "OpenUIKitUnderTest", path: root)],
    targets: [
        .target(
            name: "SnapKit",
            dependencies: [.product(name: "UIKit", package: "OpenUIKitUnderTest")],
            exclude: ["Debugging.swift"],
            swiftSettings: [.unsafeFlags(["-warnings-as-errors"])]
        ),
        .target(
            name: "DesignSystem",
            dependencies: [
                .product(name: "UIKit", package: "OpenUIKitUnderTest"),
                .product(name: "SwiftUI", package: "OpenUIKitUnderTest"),
            ],
            resources: [.copy("Resources")],
            swiftSettings: [.unsafeFlags(["-warnings-as-errors"])]
        ),
        .target(
            name: "Widget",
            dependencies: [.product(name: "SwiftUI", package: "OpenUIKitUnderTest")],
            resources: [.copy("Resources")],
            swiftSettings: [.unsafeFlags(["-warnings-as-errors"])]
        ),
        .target(
            name: "Onboarding",
            dependencies: [
                "SnapKit",
                "DesignSystem",
                "Widget",
                .product(name: "UIKit", package: "OpenUIKitUnderTest"),
                .product(name: "SwiftUI", package: "OpenUIKitUnderTest"),
            ] + objectiveCDependencies,
            resources: [.copy("Resources")],
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"] + onboardingInteropFlags),
            ]
        ),
    ] + objectiveCTargets
)
SWIFT

find_manifest() {
    target=$1
    manifest=$(find "$probe_root/.build" -type f -path "*/$target.build/sources" \
        -print -quit)
    [[ -n "$manifest" && -s "$manifest" ]] \
        || fail "$target compiler-input manifest was not emitted"
    printf '%s\n' "$manifest"
}

require_manifest_source() {
    manifest=$1
    source=$2
    if ! grep -Fqx "$source" "$manifest" \
        && ! grep -Fqx "'$source'" "$manifest"; then
        fail "compiler-input manifest omitted or rewrote: $source"
    fi
}

validate_dependency_manifests() {
    designsystem_manifest=$(find_manifest DesignSystem)
    widget_manifest=$(find_manifest Widget)
    snapkit_manifest=$(find_manifest SnapKit)

    [[ "$(wc -l < "$designsystem_manifest" | tr -d ' ')" == "8" ]] \
        || fail "DesignSystem manifest must contain 7 exact + 1 generated source"
    [[ "$(wc -l < "$widget_manifest" | tr -d ' ')" == "3" ]] \
        || fail "Widget manifest must contain 2 exact + 1 generated source"
    [[ "$(wc -l < "$snapkit_manifest" | tr -d ' ')" == "37" ]] \
        || fail "SnapKit manifest must contain 36 exact + 1 generated source"

    for relative in "${designsystem_relative_sources[@]}"; do
        require_manifest_source "$designsystem_manifest" "$designsystem_target/$relative"
    done
    for relative in "${widget_relative_sources[@]}"; do
        require_manifest_source "$widget_manifest" "$widget_target/$relative"
    done
    for relative in "${snapkit_relative_sources[@]}"; do
        if [[ "$relative" == "Debugging.swift" ]]; then
            if grep -Fqx "$snapkit_target/$relative" "$snapkit_manifest"; then
                fail "the one declared SnapKit exclusion reached the compiler"
            fi
        else
            require_manifest_source "$snapkit_manifest" "$snapkit_target/$relative"
        fi
    done
    require_manifest_source "$snapkit_manifest" "$snapkit_target/SnapKit.generated.swift"

    for target in DesignSystem Widget; do
        accessor=$(find "$probe_root/.build" -type f \
            -path "*/$target.build/DerivedSources/resource_bundle_accessor.swift" \
            -print -quit)
        [[ -n "$accessor" && -s "$accessor" ]] \
            || fail "$target SwiftPM resource accessor was not generated"
        if [[ "$target" == "DesignSystem" ]]; then
            require_manifest_source "$designsystem_manifest" "$accessor"
        else
            require_manifest_source "$widget_manifest" "$accessor"
        fi
    done
}

verify_source_bytes_after_build() {
    for index in "${!onboarding_relative_sources[@]}"; do
        relative=${onboarding_relative_sources[$index]}
        [[ "$(sha256_file "$onboarding_target/$relative")" \
            == "${onboarding_expected_sha256[$index]}" ]] \
            || fail "probe changed exact Onboarding bytes: $relative"
    done
    [[ "$(sha256_file "$snapkit_target/Debugging.swift")" \
        == "$expected_snapkit_debugging_sha256" ]] \
        || fail "probe changed excluded SnapKit Debugging.swift bytes"
}

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "==> macOS release exact-source Onboarding emission"
    OPENUIKIT_S2_ROOT="$open_uikit_root" \
        swift build -v -c release --package-path "$probe_root" --target Onboarding \
        > "$probe_root/macos-release.log" 2>&1 || {
            cat "$probe_root/macos-release.log" >&2
            fail "macOS exact-source release emission failed"
        }

    onboarding_manifest=$(find_manifest Onboarding)
    [[ "$(wc -l < "$onboarding_manifest" | tr -d ' ')" == "23" ]] \
        || fail "Onboarding manifest must contain 21 exact + 2 generated sources"
    for relative in "${onboarding_relative_sources[@]}"; do
        require_manifest_source "$onboarding_manifest" "$onboarding_target/$relative"
    done
    require_manifest_source "$onboarding_manifest" \
        "$onboarding_target/Onboarding.generated.swift"
    onboarding_accessor=$(find "$probe_root/.build" -type f \
        -path '*/Onboarding.build/DerivedSources/resource_bundle_accessor.swift' \
        -print -quit)
    [[ -n "$onboarding_accessor" && -s "$onboarding_accessor" ]] \
        || fail "Onboarding SwiftPM resource accessor was not generated"
    require_manifest_source "$onboarding_manifest" "$onboarding_accessor"

    validate_dependency_manifests
    module_artifact=$(find "$probe_root/.build" -type f \
        -path '*/release/Modules/Onboarding.swiftmodule' -print -quit)
    [[ -n "$module_artifact" && -s "$module_artifact" ]] \
        || fail "macOS release Onboarding module was not emitted"
    grep -Eq -- '-warnings-as-errors .*module-name Onboarding|module-name Onboarding .*warnings-as-errors' \
        "$probe_root/macos-release.log" \
        || fail "macOS compiler invocation did not contain -warnings-as-errors"
    verify_source_bytes_after_build

    echo "PASS macOS: exact 21-source Onboarding release target emitted"
    echo "Artifact: $module_artifact"
else
    echo "==> stock Linux release dependencies + exact-source module emission"
    export OPENUIKIT_S2_ROOT="$open_uikit_root"
    for target in SnapKit DesignSystem Widget ObjectiveC; do
        swift build -v -c release --package-path "$probe_root" --target "$target" \
            > "$probe_root/linux-$target-release.log" 2>&1 || {
                cat "$probe_root/linux-$target-release.log" >&2
                fail "Linux release dependency emission failed: $target"
            }
    done
    validate_dependency_manifests

    objectivec_manifest=$(find_manifest ObjectiveC)
    [[ "$(wc -l < "$objectivec_manifest" | tr -d ' ')" == "1" ]] \
        || fail "ObjectiveC compile-support manifest must contain exactly one generated source"
    require_manifest_source "$objectivec_manifest" \
        "$probe_root/Sources/ObjectiveC/ObjectiveC.swift"

    release_path=$(dirname "$(find "$probe_root/.build" \
        -path '*/release/Modules' -type d -print -quit)")
    [[ -d "$release_path/Modules" ]] || fail "Linux release module directory is missing"
    opencombine_helpers=$(find "$probe_root/.build/checkouts/OpenCombine" \
        -path '*/COpenCombineHelpers/include/module.modulemap' -type f -print -quit)
    [[ -n "$opencombine_helpers" ]] || fail "pinned OpenCombine helper module map is missing"
    opencombine_include=$(dirname "$opencombine_helpers")

    linux_source_manifest="$probe_root/linux-Onboarding.sources"
    : > "$linux_source_manifest"
    linux_sources=()
    for relative in "${onboarding_relative_sources[@]}"; do
        source="$onboarding_target/$relative"
        linux_sources+=("$source")
        printf '%s\n' "$source" >> "$linux_source_manifest"
    done
    linux_sources+=("$onboarding_target/Onboarding.generated.swift")
    printf '%s\n' "$onboarding_target/Onboarding.generated.swift" \
        >> "$linux_source_manifest"
    [[ "$(wc -l < "$linux_source_manifest" | tr -d ' ')" == "22" ]] \
        || fail "Linux manifest must contain 21 exact + 1 generated source"

    mkdir -p "$probe_root/Artifacts"
    linux_module="$probe_root/Artifacts/Onboarding.swiftmodule"
    swiftc -emit-module -parse-as-library -module-name Onboarding \
        -swift-version 5 -O -warnings-as-errors \
        -Xfrontend -enable-objc-interop \
        -D OPENUIKIT_MANUAL_LINUX_EMISSION \
        -I "$release_path/Modules" \
        -Xcc -fmodule-map-file="$open_uikit_root/Sources/CQuartz/include/module.modulemap" \
        -Xcc -I -Xcc "$open_uikit_root/Sources/CQuartz/include" \
        -Xcc -fmodule-map-file="$release_path/CPortableIO.build/module.modulemap" \
        -Xcc -I -Xcc "$open_uikit_root/Sources/CPortableIO/include" \
        -Xcc -fmodule-map-file="$release_path/CSTBTrueType.build/module.modulemap" \
        -Xcc -I -Xcc "$open_uikit_root/Sources/CSTBTrueType/include" \
        -Xcc -fmodule-map-file="$opencombine_helpers" \
        -Xcc -I -Xcc "$opencombine_include" \
        "${linux_sources[@]}" -o "$linux_module" \
        > "$probe_root/linux-Onboarding-release.log" 2>&1 || {
            cat "$probe_root/linux-Onboarding-release.log" >&2
            fail "stock Linux exact-source release module emission failed"
        }
    [[ -s "$linux_module" ]] || fail "Linux Onboarding module was not emitted"
    verify_source_bytes_after_build

    echo "PASS Linux: exact 21-source Onboarding release module emitted"
    echo "Artifact: $linux_module"
    echo "Limit: module-only because stock Linux IRGen crashes on @objc metadata; no runtime claim"
fi

[[ -z "$(git -c safe.directory='*' -C "$focus_repo" \
    status --porcelain=v1 --untracked-files=all)" ]] \
    || fail "Focus checkout changed during proof"
[[ -z "$(git -c safe.directory='*' -C "$snapkit_repo" \
    status --porcelain=v1 --untracked-files=all)" ]] \
    || fail "SnapKit checkout changed during proof"
open_uikit_status_after=$(git -c safe.directory='*' -C "$open_uikit_root" \
    status --porcelain=v1 --untracked-files=all)
[[ "$open_uikit_status_after" == "$open_uikit_status_before" ]] \
    || fail "OpenUIKit checkout changed during proof"

echo "Focus revision: $focus_revision"
echo "SnapKit revision: $snapkit_revision"
echo "Exact Onboarding sources: 21 (all inventory + sha256 checked)"
echo "SnapKit exclusion: Debugging.swift sha256 $expected_snapkit_debugging_sha256"

if [[ "$(uname -s)" == "Darwin" \
   && "${FOCUS_ONBOARDING_SKIP_LINUX:-0}" != "1" ]]; then
    command -v docker >/dev/null 2>&1 || fail "Docker is required for stock Linux verification"
    docker info >/dev/null 2>&1 || fail "Docker daemon is not available"
    image=${SWIFT_LINUX_IMAGE:-swift:6.2-noble}
    echo "==> stock Linux verification ($image)"
    docker run --rm \
        -v "$open_uikit_root:/src:ro" \
        -v "$focus_repo:/focus:ro" \
        -v "$snapkit_repo:/snapkit:ro" \
        "$image" \
        bash /src/scripts/prove_focus_onboarding_swiftui.sh \
            "/focus/$focus_package_relative" "/snapkit/$snapkit_relative"
    echo "PORTABILITY VERIFIED: macOS release target + stock Linux release module"
fi
