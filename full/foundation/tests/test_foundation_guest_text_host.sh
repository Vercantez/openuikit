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
EXPECTED_GOLDEN_SHA=da4a06b171c7474c8f3eec6febec9f217dffe47c28feaa42bb8346ddaab5f980
EXPECTED_SOURCE_DIGEST=d3597e27c2fef2959cc14159b3278be0dc65ed504909dc30cb22462f4e5ae6e0

FOUNDATION_SOURCES=(
    "$ROOT/full/foundation/CharacterSet.swift"
    "$ROOT/full/foundation/String+CharacterSet.swift"
    "$ROOT/full/foundation/Scanner.swift"
    "$ROOT/full/foundation/Error+LocalizedDescription.swift"
)
ATTESTED_SOURCES=(
    full/foundation/CharacterSet.swift
    full/foundation/String+CharacterSet.swift
    full/foundation/Scanner.swift
    full/foundation/Error+LocalizedDescription.swift
    full/foundation/tests/FoundationGuestTextTestRoot.swift
    full/foundation/tests/FoundationGuestTextUIKit.swift
    full/foundation/tests/FoundationGuestTextUIKitClient.swift
    full/foundation/tests/FoundationGuestTextOracle.swift
    full/foundation/tests/FoundationGuestTextRuntime.swift
    full/foundation/tests/FoundationGuestTextMissingScanner.swift
    full/foundation/tests/foundation-guest-text-apple-2026-08-30.txt
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
mkdir -p "$FE" "$FOUNDATION" "$MUTATED" "$MISSING" "$UIKIT"

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
        "$@"
}

build_foundation \
    "$FOUNDATION" "$ROOT/full/foundation/CharacterSet.swift" \
    "$ROOT/full/foundation/Scanner.swift" \
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
    -module-cache-path "$OUT/port-module-cache" \
    -I "$FOUNDATION" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestTextOracle.swift" \
    "$FOUNDATION/Foundation.o" "${LINK_OBJECTS[@]}" \
    -o "$OUT/port-oracle"
"$OUT/port-oracle" > "$OUT/port-output.txt"
cmp "$GOLDEN" "$OUT/port-output.txt" || die "portable output differs from Apple golden"

xcrun swiftc -target "$TARGET" -parse-as-library \
    -module-cache-path "$OUT/runtime-module-cache" \
    -I "$FOUNDATION" -I "$FE" "${CSHIM_FLAGS[@]}" \
    "$ROOT/full/foundation/tests/FoundationGuestTextRuntime.swift" \
    "$FOUNDATION/Foundation.o" "${LINK_OBJECTS[@]}" \
    -o "$OUT/runtime"
runtime_output=$("$OUT/runtime")
[ "$runtime_output" = \
    'FOUNDATION_GUEST_TEXT_RUNTIME_OK characters=26 trimming=unicode scanner=hex error=descriptive' \
] || die "unexpected runtime marker: $runtime_output"

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

for binary in "$OUT/port-oracle" "$OUT/runtime" "$OUT/uikit-client"; do
    if otool -L "$binary" | grep -Eq \
        '/System/Library/Frameworks/(Foundation|CoreFoundation)\.framework/'; then
        die "portable binary loads Apple Foundation/CoreFoundation: $binary"
    fi
done

xcrun nm -gU "$FOUNDATION/Foundation.o" | \
    xcrun swift-demangle > "$OUT/foundation-symbols.txt"
for symbol in \
    'Foundation.CharacterSet.init(charactersIn:' \
    'Foundation.Scanner.scanHexInt64' \
    'Swift.String.trimmingCharacters(in: Foundation.CharacterSet)' \
    'Swift.Error.localizedDescription.getter'; do
    grep -Fq "$symbol" "$OUT/foundation-symbols.txt" || {
        die "missing public symbol $symbol"
    }
done

# Adversarial compile: the facade manifest must not silently fall back to the
# SDK's Foundation Scanner when Scanner.swift is omitted.
build_foundation \
    "$MISSING" "$ROOT/full/foundation/CharacterSet.swift" \
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
    "FOUNDATION_GUEST_TEXT_HOST_OK rows=51 characters=26 "\
"runtime=1 uikit-reexport=1 adversarial=2 sha256=$initial_source_digest"
if [ "${FOUNDATION_GUEST_TEXT_KEEP_OUTPUT:-0}" = 1 ]; then
    printf 'output-root\t%s\n' "$OUT"
fi
