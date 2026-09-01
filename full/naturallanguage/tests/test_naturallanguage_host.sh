#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
APP=${ICECUBES_APP_ROOT:-/private/tmp/app-wave-20260831/IceCubesApp}
WISHKIT=${ICECUBES_WISHKIT_ROOT:-/private/tmp/wishkit-natural-auth-audit-20260901}
EXPECTED_APP_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_APP_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
EXPECTED_WISHKIT_COMMIT=1adab95b4c45dfe84d5282e4d7d551617800c22c
EXPECTED_WISHKIT_TREE=a253cf55ad1d9f21a890b18b0fe4bbbf6814159d
STATUS_SOURCE=Packages/StatusKit/Sources/StatusKit/LanguageDetection/LanguageDetection.swift
STATUS_SHA=f5d2ed281604303d5e3323b322c0490d1676134d50b2bb350141d9029f9f96f8
WISH_SOURCE=Sources/WishKit/Shared/Utilities/FeedbackLanguage.swift
WISH_SHA=30fe69ffc2d7e02af05fd66efe896d8361a6a8c3704a5af1a0fbe2a5e90f40de
OUTPUT=$(mktemp -d /private/tmp/naturallanguage-host-proof.XXXXXX)
trap 'rm -rf -- "$OUTPUT"' EXIT

fail() {
    printf 'naturallanguage-host-test: %s\n' "$*" >&2
    exit 1
}

[ -d "$APP/.git" ] || fail "missing pinned IceCubes checkout: $APP"
[ "$(git -C "$APP" rev-parse HEAD)" = "$EXPECTED_APP_COMMIT" ] \
    || fail 'IceCubes commit drifted'
[ "$(git -C "$APP" rev-parse 'HEAD^{tree}')" = "$EXPECTED_APP_TREE" ] \
    || fail 'IceCubes tree drifted'
[ -z "$(git -C "$APP" status --porcelain --untracked-files=all)" ] \
    || fail 'IceCubes checkout is dirty'
[ "$(shasum -a 256 "$APP/$STATUS_SOURCE" | awk '{print $1}')" = \
    "$STATUS_SHA" ] || fail 'StatusKit consumer drifted'
[ -d "$WISHKIT/.git" ] || fail "missing pinned WishKit checkout: $WISHKIT"
[ "$(git -C "$WISHKIT" rev-parse HEAD)" = "$EXPECTED_WISHKIT_COMMIT" ] \
    || fail 'WishKit commit drifted'
[ "$(git -C "$WISHKIT" rev-parse 'HEAD^{tree}')" = \
    "$EXPECTED_WISHKIT_TREE" ] || fail 'WishKit tree drifted'
[ -z "$(git -C "$WISHKIT" status --porcelain --untracked-files=all)" ] \
    || fail 'WishKit checkout is dirty'
[ "$(shasum -a 256 "$WISHKIT/$WISH_SOURCE" | awk '{print $1}')" = \
    "$WISH_SHA" ] || fail 'WishKit consumer drifted'

grep -Fq 'languageHypotheses(withMaximum: 1)' "$APP/$STATUS_SOURCE"
grep -Fq 'confidence >= 0.85' "$APP/$STATUS_SOURCE"
grep -Fq 'minimumConfidence = 0.6' "$WISHKIT/$WISH_SOURCE"
grep -Fq 'languageHypotheses(withMaximum: 1)' "$WISHKIT/$WISH_SOURCE"

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -parse-as-library \
    "$ROOT/full/naturallanguage/tests/NaturalLanguageNativeOracle.swift" \
    -o "$OUTPUT/NaturalLanguageNativeOracle"
"$OUTPUT/NaturalLanguageNativeOracle" | tee "$OUTPUT/native.log"
grep -Fq 'NATURALLANGUAGE_APPLE_OK' "$OUTPUT/native.log" \
    || fail 'Apple oracle marker is missing'

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -O -whole-module-optimization \
    -enable-library-evolution -parse-as-library \
    -emit-module -emit-library -module-name NaturalLanguage \
    -emit-module-path "$OUTPUT/NaturalLanguage.swiftmodule" \
    -Xlinker -install_name -Xlinker @rpath/libNaturalLanguage.dylib \
    "$ROOT/full/naturallanguage/NaturalLanguage.swift" \
    -o "$OUTPUT/libNaturalLanguage.dylib"
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -parse-as-library -I "$OUTPUT" -L "$OUTPUT" \
    "$ROOT/full/naturallanguage/tests/NaturalLanguageHostRuntime.swift" \
    -o "$OUTPUT/NaturalLanguageHostRuntime" -lNaturalLanguage
DYLD_LIBRARY_PATH="$OUTPUT${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$OUTPUT/NaturalLanguageHostRuntime" | tee "$OUTPUT/host.log"
grep -Fq 'NATURALLANGUAGE_HOST_OK constants=58' "$OUTPUT/host.log" \
    || fail 'host semantic marker is missing'

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -parse-as-library -I "$OUTPUT" -L "$OUTPUT" \
    "$ROOT/full/naturallanguage/tests/IceCubesNaturalLanguageConsumers.swift" \
    -o "$OUTPUT/IceCubesNaturalLanguageConsumers" -lNaturalLanguage
DYLD_LIBRARY_PATH="$OUTPUT${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$OUTPUT/IceCubesNaturalLanguageConsumers" | tee "$OUTPUT/consumer.log"
grep -Fxq \
    'ICECUBES_NATURALLANGUAGE_CONSUMER_OK statuskit=sha-f5d2ed2 wishkit=sha-30fe69f' \
    "$OUTPUT/consumer.log" || fail 'exact consumer marker is missing'
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -warnings-as-errors -parse-as-library -typecheck -I "$OUTPUT" \
    "$WISHKIT/$WISH_SOURCE"

[ "$(xcrun otool -D "$OUTPUT/libNaturalLanguage.dylib" \
    | grep -Fxc '@rpath/libNaturalLanguage.dylib')" -eq 1 ]
! xcrun otool -L "$OUTPUT/libNaturalLanguage.dylib" \
    | grep -F '/System/Library/Frameworks/NaturalLanguage.framework/' \
    >/dev/null

printf '%s\n' \
    'NATURALLANGUAGE_HOST_GATE_OK module=NaturalLanguage semantics=state,scripts,lexical,confidence,constraints,hints'
printf 'NATURALLANGUAGE_EXACT_CONSUMERS_OK status=%s:%s wishkit=%s:%s\n' \
    "$STATUS_SOURCE" "$STATUS_SHA" "$WISH_SOURCE" "$WISH_SHA"
