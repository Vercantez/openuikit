#!/bin/bash
# Native differential and structural gate for the bounded Foundation text/error
# facade. Every invocation rebuilds pinned FoundationEssentials and every module
# into a new physical root; no prior build output or module cache is consumed.
set -euo pipefail

[ "$(uname -s)" = Darwin ] || {
    echo "test_foundation_guest_text_host: macOS host required" >&2
    exit 2
}

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
SF=${SF:-$ROOT/scratch/swift-foundation}
SC=${SC:-$ROOT/scratch/swift-collections}
TARGET=arm64-apple-macos15.0
PINNED=$ROOT/full/foundation/pinned_inputs.pl
GOLDEN=$ROOT/full/foundation/tests/foundation-guest-text-apple-2026-08-30.txt
COMPAT_GOLDEN=$ROOT/full/foundation/tests/foundation-guest-compatibility-apple-2026-08-30.txt
STRUCTURED_GOLDEN=$ROOT/full/foundation/tests/foundation-guest-structured-data-apple-2026-08-30.txt
EXPECTED_GOLDEN_SHA=da4a06b171c7474c8f3eec6febec9f217dffe47c28feaa42bb8346ddaab5f980
EXPECTED_COMPAT_GOLDEN_SHA=07a1d25c7707614ae7cf8b18d847f7da2fd008e4c3879ded01830085985611ac
EXPECTED_STRUCTURED_GOLDEN_SHA=5ceca8b4b92d4fe59ecee2751bb0996cc20b453309f6a9d75105e7517ac8d46e
EXPECTED_SOURCE_DIGEST=3847eb3bbda3ab15731de53349db5599f98a4faa20db8ce8ce717106b6e36810

FOUNDATION_SOURCES=(
    "$ROOT/full/foundation/CharacterSet.swift"
    "$ROOT/full/foundation/String+CharacterSet.swift"
    "$ROOT/full/foundation/String+FoundationCompatibility.swift"
    "$ROOT/full/foundation/Scanner.swift"
    "$ROOT/full/foundation/Error+LocalizedDescription.swift"
)
ATTESTED_SOURCES=(
    full/foundation/CharacterSet.swift
    full/foundation/String+CharacterSet.swift
    full/foundation/String+FoundationCompatibility.swift
    full/foundation/Bundle+Localization.swift
    full/foundation/Scanner.swift
    full/foundation/Error+LocalizedDescription.swift
    full/foundation/NSError.swift
    full/foundation/NSNumber.swift
    full/foundation/JSONSerialization.swift
    full/foundation/NSRegularExpression.swift
    full/appshim/FoundationOpenUIKitValueAliases.swift
    full/foundation/tests/FoundationGuestTextTestRoot.swift
    full/foundation/tests/FoundationGuestTextUIKit.swift
    full/foundation/tests/FoundationGuestTextUIKitClient.swift
    full/foundation/tests/FoundationGuestTextOracle.swift
    full/foundation/tests/FoundationGuestTextRuntime.swift
    full/foundation/tests/FoundationGuestTextMissingScanner.swift
    full/foundation/tests/FoundationGuestCompatibilityOracle.swift
    full/foundation/tests/FoundationGuestBundleRuntime.swift
    full/foundation/tests/FoundationGuestServicesOpenUIKitStub.swift
    full/foundation/tests/FoundationGuestServicesTestRoot.swift
    full/foundation/tests/FoundationGuestServiceIdentityProbe.swift
    full/foundation/tests/FoundationGuestStructuredDataOracle.swift
    full/foundation/tests/FoundationGuestStructuredDataNegative.swift
    full/foundation/tests/foundation-guest-text-apple-2026-08-30.txt
    full/foundation/tests/foundation-guest-compatibility-apple-2026-08-30.txt
    full/foundation/tests/foundation-guest-structured-data-apple-2026-08-30.txt
)

die() {
    echo "test_foundation_guest_text_host: REFUSING -- $*" >&2
    exit 2
}

source_digest() {
    (
        cd "$ROOT"
        for path in "${ATTESTED_SOURCES[@]}"; do
            [ -f "$path" ] || die "missing attested source $path"
            printf '%s\t' "$path"
            shasum -a 256 "$path" | awk '{print $1}'
        done
    ) | shasum -a 256 | awk '{print $1}'
}

require_repo() {
    local repository=$1 expected_commit=$2 expected_tree=$3
    local actual_commit actual_tree
    actual_commit=$(git -C "$repository" rev-parse HEAD^{commit})
    actual_tree=$(git -C "$repository" rev-parse HEAD^{tree})
    [ "$actual_commit" = "$expected_commit" ] || {
        die "$repository commit $actual_commit, expected $expected_commit"
    }
    [ "$actual_tree" = "$expected_tree" ] || {
        die "$repository tree $actual_tree, expected $expected_tree"
    }
    [ -z "$(git -C "$repository" status --porcelain=v1 --untracked-files=all)" ] || {
        die "$repository is dirty"
    }
}

initial_source_digest=$(source_digest)
[ "$initial_source_digest" = "$EXPECTED_SOURCE_DIGEST" ] || {
    die "source digest $initial_source_digest, expected $EXPECTED_SOURCE_DIGEST"
}
[ "$(shasum -a 256 "$GOLDEN" | awk '{print $1}')" = "$EXPECTED_GOLDEN_SHA" ] || {
    die "Apple golden digest changed"
}
[ "$(shasum -a 256 "$COMPAT_GOLDEN" | awk '{print $1}')" = \
    "$EXPECTED_COMPAT_GOLDEN_SHA" ] || die "Apple compatibility golden digest changed"
[ "$(shasum -a 256 "$STRUCTURED_GOLDEN" | awk '{print $1}')" = \
    "$EXPECTED_STRUCTURED_GOLDEN_SHA" ] || die "Apple structured-data golden digest changed"

require_repo \
    "$SF" \
    c6793ef0c19c2cbaeba5a0e52078f129afc7dcfc \
    4651798679b98e27383ca3626434fb128f191486
require_repo \
    "$SC" \
    9bf03ff58ce34478e66aaee630e491823326fd06 \
    5e4de96f40ccf147dab967f38cb7988ecd933c27
perl "$PINNED" verify --swift-foundation "$SF" --swift-collections "$SC"

OUTPUT_PARENT=${TMPDIR:-/private/tmp}
[ -d "$OUTPUT_PARENT" ] || die "temporary parent is not a directory: $OUTPUT_PARENT"
OUT=$(mktemp -d "$OUTPUT_PARENT/foundation-guest-text-host.XXXXXX")
case "$OUT" in
    "$OUTPUT_PARENT"/foundation-guest-text-host.*) ;;
    *) die "mktemp returned unexpected path $OUT" ;;
esac
if [ "${FOUNDATION_GUEST_TEXT_KEEP_OUTPUT:-0}" != 1 ]; then
    trap 'rm -rf "$OUT"' EXIT
fi

FE=$OUT/fe
FOUNDATION=$OUT/foundation
MUTATED=$OUT/mutated
MISSING=$OUT/missing
UIKIT=$OUT/uikit
SERVICES=$OUT/services
STRUCTURED=$OUT/structured
mkdir -p "$FE" "$FOUNDATION" "$MUTATED" "$MISSING" "$UIKIT" "$SERVICES" "$STRUCTURED"

printf 'support-commit\t%s\n' "$(git -C "$ROOT" rev-parse HEAD^{commit})" > "$OUT/input-manifest.txt"
printf 'support-tree\t%s\n' "$(git -C "$ROOT" rev-parse HEAD^{tree})" >> "$OUT/input-manifest.txt"
printf 'foundation-commit\t%s\n' "$(git -C "$SF" rev-parse HEAD^{commit})" >> "$OUT/input-manifest.txt"
printf 'foundation-tree\t%s\n' "$(git -C "$SF" rev-parse HEAD^{tree})" >> "$OUT/input-manifest.txt"
printf 'collections-commit\t%s\n' "$(git -C "$SC" rev-parse HEAD^{commit})" >> "$OUT/input-manifest.txt"
printf 'collections-tree\t%s\n' "$(git -C "$SC" rev-parse HEAD^{tree})" >> "$OUT/input-manifest.txt"
printf 'source-digest\t%s\n' "$initial_source_digest" >> "$OUT/input-manifest.txt"

SWIFTC=(
    xcrun swiftc -target "$TARGET" -whole-module-optimization
    -module-cache-path "$OUT/module-cache"
)
CSHIM_INCLUDE=$SF/Sources/_FoundationCShims/include
CSHIM_FLAGS=(
    -Xcc -fmodule-map-file="$CSHIM_INCLUDE/module.modulemap"
    -Xcc -I"$CSHIM_INCLUDE"
)

build_collection() {
    local module=$1 group=$2 expected_count=$3
    local sources=()
    while IFS= read -r path; do
        [ -n "$path" ] && sources+=("$path")
    done < <(
        perl "$PINNED" list \
            --repository swift-collections --repo "$SC" --group "$group"
    )
    [ "${#sources[@]}" -eq "$expected_count" ] || {
        die "$module source count ${#sources[@]}, expected $expected_count"
    }
    "${SWIFTC[@]}" -parse-as-library -module-name "$module" -I "$FE" \
        -emit-module -emit-module-path "$FE/$module.swiftmodule" \
        -emit-object -o "$FE/$module.o" "${sources[@]}"
}

build_collection InternalCollectionsUtilities collections-internal-utilities 18
build_collection OrderedCollections collections-ordered 61
build_collection _RopeModule collections-rope 76

c_sources=()
while IFS= read -r path; do
    [ -n "$path" ] && c_sources+=("$path")
done < <(
    perl "$PINNED" list \
        --repository swift-foundation --repo "$SF" --group foundation-c-sources
)
[ "${#c_sources[@]}" -eq 3 ] || die "expected three Foundation C-shim sources"
for path in "${c_sources[@]}"; do
    name=$(basename "$path" .c)
    xcrun clang -target "$TARGET" -O2 -I "$CSHIM_INCLUDE" \
        -c "$path" -o "$FE/$name.o"
done

AVAIL='macOS 15, iOS 18, tvOS 18, watchOS 11'
FEATURES=()
for feature in \
    VariadicGenerics LifetimeDependence AddressableTypes AllowUnsafeAttribute \
    BuiltinModule AccessLevelOnImport StrictConcurrency; do
    FEATURES+=(-enable-experimental-feature "$feature")
done
for version in 6.0.2 6.1 6.2; do
    FEATURES+=(
        -enable-experimental-feature \
        "AvailabilityMacro=FoundationPreview $version:$AVAIL"
    )
done
for feature in InferSendableFromCaptures MemberImportVisibility; do
    FEATURES+=(-enable-upcoming-feature "$feature")
done

fe_sources=()
while IFS= read -r path; do
    [ -n "$path" ] && fe_sources+=("$path")
done < <(
    perl "$PINNED" list \
        --repository swift-foundation --repo "$SF" --group foundation-swift
)
[ "${#fe_sources[@]}" -eq 202 ] || die "expected 202 FoundationEssentials sources"
"${SWIFTC[@]}" -parse-as-library -module-name FoundationEssentials \
    -package-name SwiftFoundation -I "$FE" "${CSHIM_FLAGS[@]}" \
    "${FEATURES[@]}" \
    -emit-module -emit-module-path "$FE/FoundationEssentials.swiftmodule" \
    -emit-object -o "$FE/FoundationEssentials.o" "${fe_sources[@]}"

LINK_OBJECTS=(
    "$FE/FoundationEssentials.o"
    "$FE/InternalCollectionsUtilities.o"
    "$FE/OrderedCollections.o"
    "$FE/_RopeModule.o"
    "$FE/platform_shims.o"
    "$FE/string_shims.o"
    "$FE/uuid.o"
)

build_foundation() {
    local destination=$1 character_set_source=$2
    shift 2
    "${SWIFTC[@]}" -parse-as-library -module-name Foundation \
        -I "$FE" "${CSHIM_FLAGS[@]}" \
        -emit-module -emit-module-path "$destination/Foundation.swiftmodule" \
        -emit-object -o "$destination/Foundation.o" \
        "$ROOT/full/foundation/tests/FoundationGuestTextTestRoot.swift" \
        "$character_set_source" \
        "$ROOT/full/foundation/String+CharacterSet.swift" \
        "$ROOT/full/foundation/String+FoundationCompatibility.swift" \
        "$@"
}

build_foundation \
    "$FOUNDATION" "$ROOT/full/foundation/CharacterSet.swift" \
    "$ROOT/full/foundation/Scanner.swift" \
    "$ROOT/full/foundation/NSError.swift" \
    "$ROOT/full/foundation/Error+LocalizedDescription.swift"

xcrun swiftc -target "$TARGET" \
    -module-cache-path "$OUT/apple-module-cache" \
    "$ROOT/full/foundation/tests/FoundationGuestTextOracle.swift" \
    -o "$OUT/apple-oracle"
"$OUT/apple-oracle" > "$OUT/apple-output.txt"
cmp "$GOLDEN" "$OUT/apple-output.txt" || die "Apple oracle drifted from golden"
otool -L "$OUT/apple-oracle" | \
    grep -q '/System/Library/Frameworks/Foundation.framework/' || {
        die "Apple oracle did not load Apple Foundation"
    }

xcrun swiftc -target "$TARGET" \
    -module-cache-path "$OUT/apple-compat-module-cache" \
    "$ROOT/full/foundation/tests/FoundationGuestCompatibilityOracle.swift" \
    -o "$OUT/apple-compat-oracle"
"$OUT/apple-compat-oracle" > "$OUT/apple-compat-output.txt"
cmp "$COMPAT_GOLDEN" "$OUT/apple-compat-output.txt" \
    || die "Apple compatibility oracle drifted from golden"

xcrun swiftc -target "$TARGET" \
    -module-cache-path "$OUT/port-module-cache" \
    -I "$FOUNDATION" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestTextOracle.swift" \
    "$FOUNDATION/Foundation.o" "${LINK_OBJECTS[@]}" \
    -o "$OUT/port-oracle"
"$OUT/port-oracle" > "$OUT/port-output.txt"
cmp "$GOLDEN" "$OUT/port-output.txt" || die "portable output differs from Apple golden"

xcrun swiftc -target "$TARGET" \
    -module-cache-path "$OUT/port-compat-module-cache" \
    -I "$FOUNDATION" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestCompatibilityOracle.swift" \
    "$FOUNDATION/Foundation.o" "${LINK_OBJECTS[@]}" \
    -o "$OUT/port-compat-oracle"
"$OUT/port-compat-oracle" > "$OUT/port-compat-output.txt"
cmp "$COMPAT_GOLDEN" "$OUT/port-compat-output.txt" \
    || die "portable compatibility output differs from Apple golden"

xcrun swiftc -target "$TARGET" -parse-as-library \
    -module-cache-path "$OUT/runtime-module-cache" \
    -I "$FOUNDATION" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestTextRuntime.swift" \
    "$FOUNDATION/Foundation.o" "${LINK_OBJECTS[@]}" \
    -o "$OUT/runtime"
runtime_output=$("$OUT/runtime")
[ "$runtime_output" = \
    'FOUNDATION_GUEST_TEXT_RUNTIME_OK characters=26 trimming=unicode scanner=hex error=descriptive compatibility=focus' \
] || die "unexpected runtime marker: $runtime_output"

"${SWIFTC[@]}" -parse-as-library -module-name OpenUIKit \
    -I "$FE" "${CSHIM_FLAGS[@]}" \
    -emit-module -emit-module-path "$SERVICES/OpenUIKit.swiftmodule" \
    -emit-object -o "$SERVICES/OpenUIKit.o" \
    "$ROOT/full/foundation/tests/FoundationGuestServicesOpenUIKitStub.swift"
"${SWIFTC[@]}" -parse-as-library -module-name Foundation \
    -I "$SERVICES" -I "$FE" "${CSHIM_FLAGS[@]}" \
    -emit-module -emit-module-path "$SERVICES/Foundation.swiftmodule" \
    -emit-object -o "$SERVICES/Foundation.o" \
    "$ROOT/full/foundation/tests/FoundationGuestServicesTestRoot.swift" \
    "$ROOT/full/appshim/FoundationOpenUIKitServiceAliases.swift" \
    "$ROOT/full/foundation/CharacterSet.swift" \
    "$ROOT/full/foundation/String+CharacterSet.swift" \
    "$ROOT/full/foundation/String+FoundationCompatibility.swift" \
    "$ROOT/full/foundation/Bundle+Localization.swift"
xcrun swiftc -target "$TARGET" -typecheck \
    -module-cache-path "$OUT/service-identity-module-cache" \
    -I "$SERVICES" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestServiceIdentityProbe.swift"

SERVICE_LINK_OBJECTS=(
    "$SERVICES/Foundation.o"
    "$SERVICES/OpenUIKit.o"
    "${LINK_OBJECTS[@]}"
)
xcrun swiftc -target "$TARGET" -parse-as-library -D FOUNDATION_GUEST_PORT \
    -module-cache-path "$OUT/service-runtime-module-cache" \
    -I "$SERVICES" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestBundleRuntime.swift" \
    "${SERVICE_LINK_OBJECTS[@]}" -o "$OUT/service-runtime"
mkdir "$OUT/service-fixture"
service_output=$("$OUT/service-runtime" "$OUT/service-fixture")
[ "$service_output" = \
    'FOUNDATION_GUEST_BUNDLE_RUNTIME_OK plist=xml localization=en malformed-entity=rejected' \
] || die "unexpected Foundation guest service marker: $service_output"

# The structured-data/error/regex facade is a distinct module build so its
# native differential cannot be accidentally satisfied by Darwin Foundation.
"${SWIFTC[@]}" -parse-as-library -module-name Foundation \
    -I "$SERVICES" -I "$FE" "${CSHIM_FLAGS[@]}" \
    -emit-module -emit-module-path "$STRUCTURED/Foundation.swiftmodule" \
    -emit-object -o "$STRUCTURED/Foundation.o" \
    "$ROOT/full/foundation/tests/FoundationGuestTextTestRoot.swift" \
    "$ROOT/full/appshim/FoundationOpenUIKitServiceAliases.swift" \
    "$ROOT/full/appshim/FoundationOpenUIKitValueAliases.swift" \
    "$ROOT/full/foundation/CharacterSet.swift" \
    "$ROOT/full/foundation/String+CharacterSet.swift" \
    "$ROOT/full/foundation/String+FoundationCompatibility.swift" \
    "$ROOT/full/foundation/Bundle+Localization.swift" \
    "$ROOT/full/foundation/Scanner.swift" \
    "$ROOT/full/foundation/NSError.swift" \
    "$ROOT/full/foundation/NSNumber.swift" \
    "$ROOT/full/foundation/Error+LocalizedDescription.swift" \
    "$ROOT/full/foundation/DateFormatter.swift" \
    "$ROOT/full/foundation/UserDefaults.swift" \
    "$ROOT/full/foundation/JSONSerialization.swift" \
    "$ROOT/full/foundation/NSRegularExpression.swift"

xcrun swiftc -target "$TARGET" \
    -module-cache-path "$OUT/apple-structured-module-cache" \
    "$ROOT/full/foundation/tests/FoundationGuestStructuredDataOracle.swift" \
    -o "$OUT/apple-structured-oracle"
"$OUT/apple-structured-oracle" > "$OUT/apple-structured-output.txt"
cmp "$STRUCTURED_GOLDEN" "$OUT/apple-structured-output.txt" \
    || die "Apple structured-data oracle drifted from golden"
otool -L "$OUT/apple-structured-oracle" | \
    grep -q '/System/Library/Frameworks/Foundation.framework/' || {
        die "Apple structured-data oracle did not load Apple Foundation"
    }

STRUCTURED_LINK_OBJECTS=(
    "$STRUCTURED/Foundation.o"
    "$SERVICES/OpenUIKit.o"
    "${LINK_OBJECTS[@]}"
)
xcrun swiftc -target "$TARGET" \
    -module-cache-path "$OUT/port-structured-module-cache" \
    -I "$STRUCTURED" -I "$SERVICES" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestStructuredDataOracle.swift" \
    "${STRUCTURED_LINK_OBJECTS[@]}" -o "$OUT/port-structured-oracle"
"$OUT/port-structured-oracle" > "$OUT/port-structured-output.txt"
cmp "$STRUCTURED_GOLDEN" "$OUT/port-structured-output.txt" \
    || die "portable structured-data output differs from Apple golden"

xcrun swiftc -target "$TARGET" -parse-as-library \
    -module-cache-path "$OUT/port-structured-negative-module-cache" \
    -I "$STRUCTURED" -I "$SERVICES" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestStructuredDataNegative.swift" \
    "${STRUCTURED_LINK_OBJECTS[@]}" -o "$OUT/port-structured-negative"
structured_negative_output=$("$OUT/port-structured-negative")
[ "$structured_negative_output" = \
    'FOUNDATION_GUEST_STRUCTURED_NEGATIVE_OK regex-options=3 json-nonfinite=1' \
] || die "unexpected structured negative marker: $structured_negative_output"

xcrun swiftc -target "$TARGET" -parse-as-library \
    -module-cache-path "$OUT/apple-service-module-cache" \
    "$ROOT/full/foundation/tests/FoundationGuestBundleRuntime.swift" \
    -o "$OUT/apple-service-runtime"
mkdir "$OUT/apple-service-fixture"
apple_service_output=$("$OUT/apple-service-runtime" "$OUT/apple-service-fixture")
[ "$apple_service_output" = \
    'FOUNDATION_GUEST_BUNDLE_APPLE_OK plist=xml localization=en' \
] || die "unexpected Apple bundle marker: $apple_service_output"

"${SWIFTC[@]}" -parse-as-library -module-name UIKit \
    -I "$FOUNDATION" -I "$FE" "${CSHIM_FLAGS[@]}" \
    -emit-module -emit-module-path "$UIKIT/UIKit.swiftmodule" \
    -emit-object -o "$UIKIT/UIKit.o" \
    "$ROOT/full/foundation/tests/FoundationGuestTextUIKit.swift"
xcrun swiftc -target "$TARGET" -parse-as-library \
    -module-cache-path "$OUT/uikit-client-module-cache" \
    -I "$UIKIT" -I "$FOUNDATION" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestTextUIKitClient.swift" \
    "$UIKIT/UIKit.o" "$FOUNDATION/Foundation.o" "${LINK_OBJECTS[@]}" \
    -o "$OUT/uikit-client"
uikit_output=$("$OUT/uikit-client")
[ "$uikit_output" = 'FOUNDATION_GUEST_TEXT_UIKIT_REEXPORT_OK' ] || {
    die "unexpected UIKit-only marker: $uikit_output"
}

for binary in "$OUT/port-oracle" "$OUT/port-compat-oracle" "$OUT/runtime" \
    "$OUT/uikit-client" "$OUT/service-runtime" "$OUT/port-structured-oracle" \
    "$OUT/port-structured-negative"; do
    if otool -L "$binary" | grep -Eq \
        '/System/Library/Frameworks/(Foundation|CoreFoundation)\.framework/'; then
        die "portable binary loads Apple Foundation/CoreFoundation: $binary"
    fi
done

xcrun nm -gU "$STRUCTURED/Foundation.o" | \
    xcrun swift-demangle > "$OUT/structured-foundation-symbols.txt"
for symbol in \
    'Foundation.NSError.init(domain:' \
    'Foundation._convertErrorToNSError' \
    'Foundation.NSNumber.__allocating_init<A where A: Swift.BinaryInteger>(value:' \
    'Foundation.JSONSerialization.jsonObject' \
    'Foundation.JSONSerialization.data' \
    'Foundation.NSRegularExpression.matches' \
    'Foundation.NSRegularExpression.stringByReplacingMatches' \
    'Foundation.NSTextCheckingResult.range(at:'; do
    grep -Fq "$symbol" "$OUT/structured-foundation-symbols.txt" || {
        die "missing structured-data public symbol $symbol"
    }
done

xcrun nm -gU "$FOUNDATION/Foundation.o" | \
    xcrun swift-demangle > "$OUT/foundation-symbols.txt"
for symbol in \
    'Foundation.CharacterSet.init(charactersIn:' \
    'Foundation.Scanner.scanHexInt64' \
    'Swift.String.trimmingCharacters(in: Foundation.CharacterSet)' \
    'Swift.String.addingPercentEncoding(withAllowedCharacters:' \
    'Swift.String.range(of:' \
    'Foundation.NSMutableCharacterSet' \
    'Swift.Error.localizedDescription.getter'; do
    grep -Fq "$symbol" "$OUT/foundation-symbols.txt" || {
        die "missing public symbol $symbol"
    }
done

# Adversarial compile: the facade manifest must not silently fall back to the
# SDK's Foundation Scanner when Scanner.swift is omitted.
build_foundation \
    "$MISSING" "$ROOT/full/foundation/CharacterSet.swift" \
    "$ROOT/full/foundation/NSError.swift" \
    "$ROOT/full/foundation/Error+LocalizedDescription.swift"
if xcrun swiftc -target "$TARGET" -typecheck \
    -module-cache-path "$OUT/missing-module-cache" \
    -I "$MISSING" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestTextMissingScanner.swift" \
    > "$OUT/missing.stdout" 2> "$OUT/missing.stderr"; then
    die "missing-Scanner adversarial compile unexpectedly succeeded"
fi
grep -Fq "cannot find 'Scanner' in scope" "$OUT/missing.stderr" || {
    die "missing-Scanner adversarial compile failed for the wrong reason"
}

# Adversarial behavior: removing Darwin's compatibility U+200B member must
# produce a real oracle mismatch.
sed 's/, 0x200B//' "$ROOT/full/foundation/CharacterSet.swift" \
    > "$MUTATED/CharacterSet.swift"
build_foundation \
    "$MUTATED" "$MUTATED/CharacterSet.swift" \
    "$ROOT/full/foundation/Scanner.swift" \
    "$ROOT/full/foundation/NSError.swift" \
    "$ROOT/full/foundation/Error+LocalizedDescription.swift"
xcrun swiftc -target "$TARGET" \
    -module-cache-path "$OUT/mutated-module-cache" \
    -I "$MUTATED" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestTextOracle.swift" \
    "$MUTATED/Foundation.o" "${LINK_OBJECTS[@]}" \
    -o "$MUTATED/oracle"
"$MUTATED/oracle" > "$MUTATED/output.txt"
if cmp -s "$GOLDEN" "$MUTATED/output.txt"; then
    die "U+200B mutation did not perturb the oracle"
fi

final_source_digest=$(source_digest)
[ "$final_source_digest" = "$initial_source_digest" ] || {
    die "attested sources changed while the gate ran"
}

printf '%s\n' \
    "FOUNDATION_GUEST_TEXT_HOST_OK rows=86 characters=26 "\
"runtime=2 identity=8 structured=77 structured-negatives=4 uikit-reexport=1 adversarial=4 sha256=$initial_source_digest"
if [ "${FOUNDATION_GUEST_TEXT_KEEP_OUTPUT:-0}" = 1 ]; then
    printf 'output-root\t%s\n' "$OUT"
fi
