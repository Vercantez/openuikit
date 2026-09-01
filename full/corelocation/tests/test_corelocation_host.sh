#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
PROOF=$(mktemp -d /private/tmp/corelocation-host.XXXXXX)
cleanup() {
    /usr/bin/trash "$PROOF" 2>/dev/null || true
}
trap cleanup EXIT

FRAMEWORK=$PROOF/CoreLocation.framework
MODULE=$FRAMEWORK/Modules/CoreLocation.swiftmodule
mkdir -p "$FRAMEWORK/Headers" "$MODULE"
cp "$ROOT/full/corelocation/include/CoreLocation.h" \
    "$FRAMEWORK/Headers/CoreLocation.h"
cp "$ROOT/full/corelocation/include/module.modulemap" \
    "$FRAMEWORK/Modules/module.modulemap"

xcrun clang -fobjc-arc -O2 -Wall -Wextra -Werror \
    -I "$ROOT/full/corelocation/include" \
    -c "$ROOT/full/corelocation/CoreLocationObjC.m" \
    -o "$PROOF/CoreLocationObjC.o"
xcrun swiftc -parse-as-library -emit-library -emit-module \
    -enable-library-evolution -module-name CoreLocation \
    "$ROOT/full/corelocation/CoreLocation.swift" \
    "$PROOF/CoreLocationObjC.o" \
    -emit-module-path "$MODULE/arm64-apple-macos.swiftmodule" \
    -emit-module-interface-path "$MODULE/arm64-apple-macos.swiftinterface" \
    -Xlinker -install_name \
    -Xlinker '@rpath/CoreLocation.framework/CoreLocation' \
    -o "$FRAMEWORK/CoreLocation"

file "$FRAMEWORK/CoreLocation" \
    | grep -Fq 'Mach-O 64-bit dynamically linked shared library arm64'
[ "$(xcrun otool -D "$FRAMEWORK/CoreLocation" | tail -n 1)" = \
    '@rpath/CoreLocation.framework/CoreLocation' ]
xcrun nm -gU "$FRAMEWORK/CoreLocation" \
    | awk '{ print $3 }' | LC_ALL=C sort -u \
    | grep -E '^_(CLLocationCoordinate2D|CLLocationDistanceMax|kCL|OBJC_(CLASS|METACLASS)_\$_CL)' \
    > "$PROOF/boundary-exports.txt"
cmp "$PROOF/boundary-exports.txt" \
    "$ROOT/full/corelocation/tests/corelocation-boundary-expected.exports"
[ "$(xcrun nm -gU "$FRAMEWORK/CoreLocation" \
    | awk '{ print $3 }' | LC_ALL=C sort -u | wc -l | tr -d ' ')" = 676 ]

xcrun swiftc -parse-as-library \
    "$ROOT/full/corelocation/tests/CoreLocationInterfaceOracle.swift" \
    -o "$PROOF/CoreLocationInterfaceApple"
"$PROOF/CoreLocationInterfaceApple" > "$PROOF/interface-apple.txt"
cmp "$PROOF/interface-apple.txt" \
    "$ROOT/full/corelocation/tests/corelocation-interface-apple-xcode-26.1.txt"
xcrun swiftc -parse-as-library -F "$PROOF" \
    "$ROOT/full/corelocation/tests/CoreLocationInterfaceOracle.swift" \
    -Xlinker -rpath -Xlinker "$PROOF" \
    -o "$PROOF/CoreLocationInterfacePortable"
"$PROOF/CoreLocationInterfacePortable" > "$PROOF/interface-portable.txt"
cmp "$PROOF/interface-portable.txt" "$PROOF/interface-apple.txt"

xcrun swiftc -parse-as-library -F "$PROOF" \
    "$ROOT/full/corelocation/tests/CoreLocationGuestRuntime.swift" \
    -Xlinker -rpath -Xlinker "$PROOF" \
    -o "$PROOF/CoreLocationGuestRuntime"
"$PROOF/CoreLocationGuestRuntime" | tee "$PROOF/runtime.txt"
grep -Fxq \
    'CORELOCATION_GUEST_OK geometry=coordinate,distance,region authorization=fail-closed,host-driven delivery=location,heading,region,deterministic geocoder=fail-closed,host-driven' \
    "$PROOF/runtime.txt"

xcrun clang -fobjc-arc -O2 -Wall -Wextra -Werror -F "$PROOF" \
    -c "$ROOT/full/corelocation/tests/CoreLocationMixedConsumer.m" \
    -o "$PROOF/CoreLocationMixedConsumer.o"
xcrun swiftc -parse-as-library -F "$PROOF" \
    "$ROOT/full/corelocation/tests/CoreLocationMixedConsumer.swift" \
    "$PROOF/CoreLocationMixedConsumer.o" \
    -Xlinker -rpath -Xlinker "$PROOF" \
    -o "$PROOF/CoreLocationMixedConsumer"
"$PROOF/CoreLocationMixedConsumer" | tee "$PROOF/mixed.txt"
grep -Fxq \
    'CORELOCATION_MIXED_ABI_OK c=coordinate,constants,objc swift=module,class identity=one-dylib' \
    "$PROOF/mixed.txt"

CORPUS_ROOT=${CORELOCATION_CORPUS_ROOT:-/Users/miguelsalinas/swift-macho-linux/scratch/ladder-corpus}
HOME_ASSISTANT=$CORPUS_ROOT/home-assistant-ios
WIKIPEDIA=$CORPUS_ROOT/wikipedia-ios
FIREFOX=$CORPUS_ROOT/firefox-ios
for repository in "$HOME_ASSISTANT" "$WIKIPEDIA" "$FIREFOX"; do
    [ -d "$repository/.git" ]
    [ -z "$(git -C "$repository" status --porcelain)" ]
done
[ "$(git -C "$HOME_ASSISTANT" rev-parse HEAD)" = \
    2ada5ddd5449b520cc03267f06e82e9c6c3d7b45 ]
[ "$(git -C "$HOME_ASSISTANT" rev-parse HEAD^{tree})" = \
    5f69e2421c295ea3fd55c1ea73dd2a377b03a843 ]
[ "$(git -C "$WIKIPEDIA" rev-parse HEAD)" = \
    2f334df620ba1e5aa36d24d9d9dccdf3aa935d4b ]
[ "$(git -C "$WIKIPEDIA" rev-parse HEAD^{tree})" = \
    5d32702b6cc9145a7388eec2d35d0373fe3c3f2e ]
[ "$(git -C "$FIREFOX" rev-parse HEAD)" = \
    b0799c34c313be9e832b749794f91277a9ce57eb ]
[ "$(git -C "$FIREFOX" rev-parse HEAD^{tree})" = \
    181202302b9c3990fe56dd3fef1f050e1056c79a ]

HA_EXTENSIONS=$HOME_ASSISTANT/Sources/Shared/Common/Extensions/CLLocation+Extensions.swift
HA_SANITIZE=$HOME_ASSISTANT/Sources/Shared/Location/CLLocation+Sanitize.swift
WIKI_MOCK=$WIKIPEDIA/WikipediaUnitTests/MockCLLocationManager.swift
[ "$(shasum -a 256 "$HA_EXTENSIONS" | awk '{ print $1 }')" = \
    b6e857097995ee19cd74e1f72813a009193dbcb5786647c5900a70ae97b5a395 ]
[ "$(shasum -a 256 "$HA_SANITIZE" | awk '{ print $1 }')" = \
    54aa7bb08050fbc913bb1b9681f1532788f9cc9bd23bbe0ffa72999d3a15513b ]
[ "$(shasum -a 256 "$WIKI_MOCK" | awk '{ print $1 }')" = \
    27a0781f2a8791817bb9d3ea28c97159f542198a049f8e9ccc1d783505dbde57 ]

IPHONEOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
for source in "$HA_EXTENSIONS" "$HA_SANITIZE" "$WIKI_MOCK"; do
    xcrun swiftc -target arm64-apple-ios18.0 -sdk "$IPHONEOS_SDK" \
        -parse-as-library -typecheck "$source"
    xcrun swiftc -parse-as-library -typecheck -F "$PROOF" "$source"
done

while IFS=$'\t' read -r kind repository relative expected_hash; do
    [ "$kind" = objc ] || continue
    [ "$repository" = wikipedia-ios ] || continue
    source=$WIKIPEDIA/$relative
    [ "$(shasum -a 256 "$source" | awk '{ print $1 }')" = "$expected_hash" ]
    xcrun clang -target arm64-apple-ios18.0 -isysroot "$IPHONEOS_SDK" \
        -fsyntax-only -fobjc-arc -Wall -Wextra -Werror \
        -x objective-c-header "$source"
    xcrun clang -fsyntax-only -fobjc-arc -Wall -Wextra -Werror \
        -F "$PROOF" -x objective-c-header "$source"
done < "$ROOT/full/corelocation/tests/corelocation-corpus-2026-09-01.tsv"

if rg -l '(^|[@[:space:]])(import|@import)[[:space:]]+CoreLocation|<CoreLocation/' \
    "$FIREFOX" --glob '*.{swift,h,m,mm}' > "$PROOF/firefox-imports.txt"; then
    [ ! -s "$PROOF/firefox-imports.txt" ]
fi

printf 'CORELOCATION_HOST_GATE_OK interface=apple-exact boundary-exports=37 total-exports=676 corpus=home-assistant-untouched,wikipedia-untouched,firefox-absent\n'
