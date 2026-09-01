#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
ICECUBES=${ICECUBES_CHECKOUT:-/private/tmp/app-wave-20260831/IceCubesApp}
CONSUMER_RELATIVE=Packages/StatusKit/Sources/StatusKit/LanguageDetection/LanguageDetection.swift
CONSUMER=$ICECUBES/$CONSUMER_RELATIVE
EXPECTED_ICECUBES_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_ICECUBES_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
EXPECTED_CONSUMER_SHA=f5d2ed281604303d5e3323b322c0490d1676134d50b2bb350141d9029f9f96f8
GENERALIZATION=$ROOT/full/naturallanguage/tests/NaturalLanguageGeneralizationOracle.swift
GENERALIZATION_GOLDEN=$ROOT/full/naturallanguage/tests/naturallanguage-generalization-apple-26.1.txt

die() {
    echo "test_naturallanguage_native: $*" >&2
    exit 2
}

for tool in git shasum xcrun; do
    command -v "$tool" >/dev/null || die "missing required tool: $tool"
done
[ -d "$ICECUBES/.git" ] || die "IceCubes checkout is missing: $ICECUBES"
[ "$(git -C "$ICECUBES" rev-parse HEAD^{commit})" = "$EXPECTED_ICECUBES_COMMIT" ] \
    || die 'IceCubes commit drifted'
[ "$(git -C "$ICECUBES" rev-parse HEAD^{tree})" = "$EXPECTED_ICECUBES_TREE" ] \
    || die 'IceCubes tree drifted'
[ -f "$CONSUMER" ] && [ ! -L "$CONSUMER" ] \
    || die 'IceCubes language consumer is missing or linked'
[ "$(shasum -a 256 "$CONSUMER" | awk '{print $1}')" = \
    "$EXPECTED_CONSUMER_SHA" ] || die 'IceCubes language consumer changed'

WORK=$(mktemp -d /private/tmp/naturallanguage-native-proof.XXXXXX)
cleanup() {
    [ ! -d "$WORK" ] || rm -rf -- "$WORK"
}
trap cleanup EXIT HUP INT TERM

echo '== Apple NaturalLanguage 26.1 unchanged-IceCubes oracle'
xcrun swiftc -parse-as-library \
    "$CONSUMER" \
    "$ROOT/full/naturallanguage/tests/NaturalLanguageIceCubesOracle.swift" \
    -o "$WORK/apple-oracle"
"$WORK/apple-oracle" > "$WORK/apple.txt"
cmp "$ROOT/full/naturallanguage/tests/naturallanguage-apple-26.1.txt" \
    "$WORK/apple.txt" || die 'Apple NaturalLanguage transcript drifted'
xcrun swiftc "$GENERALIZATION" -o "$WORK/apple-generalization"
"$WORK/apple-generalization" > "$WORK/apple-generalization.txt"
cmp "$GENERALIZATION_GOLDEN" "$WORK/apple-generalization.txt" \
    || die 'Apple NaturalLanguage generalization transcript drifted'

echo '== portable NaturalLanguage framework and unchanged-IceCubes differential'
xcrun swiftc -parse-as-library -module-name NaturalLanguage \
    -module-link-name NaturalLanguagePortable -emit-library -emit-module \
    -emit-module-path "$WORK/NaturalLanguage.swiftmodule" \
    "$ROOT/full/naturallanguage/NaturalLanguage.swift" \
    -o "$WORK/libNaturalLanguagePortable.dylib"
xcrun swiftc -parse-as-library -I "$WORK" -L "$WORK" \
    -lNaturalLanguagePortable "$CONSUMER" \
    "$ROOT/full/naturallanguage/tests/NaturalLanguageIceCubesOracle.swift" \
    -o "$WORK/portable-oracle"
DYLD_LIBRARY_PATH="$WORK${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$WORK/portable-oracle" > "$WORK/portable.txt"
cmp "$WORK/apple.txt" "$WORK/portable.txt" \
    || die 'portable NaturalLanguage differs from Apple app behavior'
xcrun swiftc -I "$WORK" -L "$WORK" -lNaturalLanguagePortable \
    "$GENERALIZATION" -o "$WORK/portable-generalization"
DYLD_LIBRARY_PATH="$WORK${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$WORK/portable-generalization" > "$WORK/portable-generalization.txt"
cmp "$WORK/apple-generalization.txt" "$WORK/portable-generalization.txt" \
    || die 'portable NaturalLanguage generalization differs from Apple'

echo \
    "NATURALLANGUAGE_NATIVE_DIFFERENTIAL_OK apple=26.1 consumer=IceCubes languages=9 incremental=exact constraints=exact hints=exact low-evidence=nil generalization=29/29"
