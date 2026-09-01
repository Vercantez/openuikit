#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
ICECUBES=${ICECUBES_CHECKOUT:-/private/tmp/app-wave-20260831/IceCubesApp}
EXPECTED_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5

die() {
    echo "test_foundationmodels_native: $*" >&2
    exit 2
}

[ -d "$ICECUBES/.git" ] || die 'IceCubes checkout is missing'
[ "$(git -C "$ICECUBES" rev-parse HEAD^{commit})" = "$EXPECTED_COMMIT" ] \
    || die 'IceCubes commit drifted'
[ "$(git -C "$ICECUBES" rev-parse HEAD^{tree})" = "$EXPECTED_TREE" ] \
    || die 'IceCubes tree drifted'
[ -z "$(git -C "$ICECUBES" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'IceCubes checkout is not untouched'

AIPROMPT=$ICECUBES/Packages/StatusKit/Sources/StatusKit/Editor/Components/AIPrompt.swift
EDITORSTORE=$ICECUBES/Packages/StatusKit/Sources/StatusKit/Editor/EditorStore.swift
[ "$(shasum -a 256 "$AIPROMPT" | awk '{print $1}')" = \
    f21a16b2e7422e89410b2b6852e6b6b250c4599c2f4906796748486bdf2cd3fe ] \
    || die 'AIPrompt.swift hash drifted'
[ "$(shasum -a 256 "$EDITORSTORE" | awk '{print $1}')" = \
    ddbebf90c661b1a2e143f7585e578deb2633ab7bdfe28fa74bd8866875151232 ] \
    || die 'EditorStore.swift hash drifted'

TMP=$(mktemp -d /private/tmp/foundationmodels-native-test.XXXXXX)
cleanup() {
    rm -rf -- "$TMP"
}
trap cleanup EXIT HUP INT TERM

echo '== Apple 26.1 runtime oracle'
xcrun swiftc -parse-as-library \
    "$ROOT/full/foundationmodels/tests/FoundationModelsNativeOracle.swift" \
    -o "$TMP/FoundationModelsNativeOracle"
"$TMP/FoundationModelsNativeOracle" > "$TMP/apple.txt"
cmp "$TMP/apple.txt" \
    "$ROOT/full/foundationmodels/tests/foundationmodels-apple-26.1.txt" \
    || die 'Apple 26.1 FoundationModels oracle drifted'

echo '== native portable runtime and compiler plugin'
TOOLCHAIN=$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain
xcrun swiftc -parse-as-library -emit-library \
    -module-name FoundationModelsMacros \
    -I "$TOOLCHAIN/usr/lib/swift/host" \
    -L "$TOOLCHAIN/usr/lib/swift/host" \
    "$ROOT/full/foundationmodels/FoundationModelsMacros.swift" \
    -o "$TMP/libFoundationModelsMacros.dylib"
xcrun swiftc -parse-as-library -module-name FoundationModels \
    -emit-module -emit-module-path "$TMP/FoundationModels.swiftmodule" \
    -emit-library -o "$TMP/libFoundationModels.dylib" \
    "$ROOT/full/foundationmodels/FoundationModels.swift"

xcrun swiftc -parse-as-library -I "$TMP" \
    -load-plugin-library "$TMP/libFoundationModelsMacros.dylib" \
    -typecheck -dump-macro-expansions \
    "$ROOT/full/foundationmodels/tests/IceCubesFoundationModelsConsumer.swift" \
    > "$TMP/portable-macro-expansions.txt" 2>&1
for expansion in \
    'static var generationSchema' \
    'var generatedContent' \
    'struct PartiallyGenerated' \
    'extension Tags: FoundationModels.Generable' \
    'guides: [.count(5)]'; do
    grep -Fq "$expansion" "$TMP/portable-macro-expansions.txt" \
        || die "portable macro expansion is missing: $expansion"
done

xcrun swiftc -parse-as-library -I "$TMP" -L "$TMP" -lFoundationModels \
    -load-plugin-library "$TMP/libFoundationModelsMacros.dylib" \
    "$ROOT/full/foundationmodels/tests/IceCubesFoundationModelsConsumer.swift" \
    -o "$TMP/IceCubesFoundationModelsConsumer"
DYLD_LIBRARY_PATH="$TMP" "$TMP/IceCubesFoundationModelsConsumer" \
    > "$TMP/portable.txt"
head -n 4 "$TMP/portable.txt" > "$TMP/portable-apple-comparable.txt"
cmp "$TMP/portable-apple-comparable.txt" \
    "$ROOT/full/foundationmodels/tests/foundationmodels-apple-26.1.txt" \
    || die 'portable generated-content transcript differs from Apple 26.1'
grep -Fxq \
    'FOUNDATIONMODELS_GUEST_MACHO_OK macro=generable guide=count generated=roundtrip direct=fail-closed stream=fail-closed available=false' \
    "$TMP/portable.txt" || die 'portable native runtime marker is missing'

printf 'FOUNDATIONMODELS_NATIVE_DIFFERENTIAL_OK apple=26.1 macro=Generable,Guide generated-content=exact icecubes=%s service=fail-closed\n' \
    "$EXPECTED_COMMIT"
