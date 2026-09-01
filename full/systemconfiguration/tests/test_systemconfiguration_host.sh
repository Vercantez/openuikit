#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
PROOF=$(mktemp -d /private/tmp/systemconfiguration-host.XXXXXX)
cleanup() {
    /usr/bin/trash "$PROOF" 2>/dev/null || true
}
trap cleanup EXIT

FRAMEWORK=$PROOF/SystemConfiguration.framework
mkdir -p "$FRAMEWORK/Headers" "$FRAMEWORK/Modules"
cp "$ROOT"/full/systemconfiguration/include/*.h "$FRAMEWORK/Headers/"
cp "$ROOT/full/systemconfiguration/include/module.modulemap" \
    "$FRAMEWORK/Modules/module.modulemap"

xcrun clang -dynamiclib -fno-objc-arc -std=gnu11 -O2 \
    -fvisibility=hidden -Wall -Wextra -Werror \
    -I "$ROOT/full/systemconfiguration/include" \
    "$ROOT/full/systemconfiguration/SystemConfiguration.m" \
    -install_name '@rpath/SystemConfiguration.framework/SystemConfiguration' \
    -framework Foundation -o "$FRAMEWORK/SystemConfiguration"

xcrun nm -gU "$FRAMEWORK/SystemConfiguration" \
    | awk '{ print $3 }' | LC_ALL=C sort -u > "$PROOF/exports.txt"
cmp "$PROOF/exports.txt" \
    "$ROOT/full/systemconfiguration/tests/systemconfiguration-expected.exports"

xcrun clang -fno-objc-arc -std=gnu11 -O2 -Wall -Wextra -Werror \
    -F "$PROOF" \
    "$ROOT/full/systemconfiguration/tests/SystemConfigurationGuestRuntime.m" \
    -framework SystemConfiguration -framework Foundation \
    -Wl,-rpath,"$PROOF" -o "$PROOF/SystemConfigurationGuestRuntime"
"$PROOF/SystemConfigurationGuestRuntime" | tee "$PROOF/runtime.log"
grep -Fxq \
    'SYSTEMCONFIGURATION_GUEST_OK reachability=unknown,host-driven,loopback flags=wifi,cellular,offline callbacks=dispatch,runloop,coalesced,cooperative context=balanced' \
    "$PROOF/runtime.log"

xcrun swiftc -parse-as-library \
    "$ROOT/full/systemconfiguration/tests/SystemConfigurationInterfaceOracle.swift" \
    -o "$PROOF/SystemConfigurationInterfaceApple"
"$PROOF/SystemConfigurationInterfaceApple" > "$PROOF/interface-apple.txt"
cmp "$PROOF/interface-apple.txt" \
    "$ROOT/full/systemconfiguration/tests/systemconfiguration-interface-apple-2026-09-01.txt"

xcrun swiftc -parse-as-library -F "$PROOF" \
    "$ROOT/full/systemconfiguration/tests/SystemConfigurationInterfaceOracle.swift" \
    -Xlinker -rpath -Xlinker "$PROOF" \
    -o "$PROOF/SystemConfigurationInterfacePortable"
"$PROOF/SystemConfigurationInterfacePortable" > "$PROOF/interface-portable.txt"
cmp "$PROOF/interface-portable.txt" "$PROOF/interface-apple.txt"

IPHONEOS_SDK=$(xcrun --sdk iphoneos --show-sdk-path)
xcrun swiftc -target arm64-apple-ios18.0 -sdk "$IPHONEOS_SDK" \
    -parse-as-library -typecheck \
    "$ROOT/full/systemconfiguration/tests/FirefoxReachabilityConsumer.swift"
xcrun swiftc -parse-as-library -typecheck -F "$PROOF" \
    "$ROOT/full/systemconfiguration/tests/FirefoxReachabilityConsumer.swift"

CORPUS_ROOT=${SYSTEMCONFIGURATION_CORPUS_ROOT:-/private/tmp/systemconfiguration-corpus-20260901}
exact=absent
if [ -d "$CORPUS_ROOT/firefox/.git" ]; then
    FIREFOX=$CORPUS_ROOT/firefox
    [ "$(git -C "$FIREFOX" rev-parse HEAD)" = \
        b0799c34c313be9e832b749794f91277a9ce57eb ]
    [ "$(git -C "$FIREFOX" rev-parse HEAD^{tree})" = \
        181202302b9c3990fe56dd3fef1f050e1056c79a ]
    [ -z "$(git -C "$FIREFOX" status --porcelain)" ]
    FIREFOX_CONSTANTS=$FIREFOX/BrowserKit/Sources/Common/Constants/NotificationConstants.swift
    FIREFOX_REACHABILITY=$FIREFOX/BrowserKit/Sources/Shared/Deferred/Reachability.swift
    [ "$(shasum -a 256 "$FIREFOX_CONSTANTS" | awk '{ print $1 }')" = \
        d70b687e091161d8dc8410d1d8182dc003fcf4d33d1247c5c62092feada4e7ca ]
    [ "$(shasum -a 256 "$FIREFOX_REACHABILITY" | awk '{ print $1 }')" = \
        8184c2661754e901ac2239dae54b84b22e62dfb2867c885cca3e2501bc589614 ]
    xcrun swiftc -parse-as-library -typecheck -F "$PROOF" \
        "$FIREFOX_CONSTANTS" "$FIREFOX_REACHABILITY"
    exact=firefox-untouched
fi

if [ -d "$CORPUS_ROOT/vlc/.git" ]; then
    VLC=$CORPUS_ROOT/vlc
    [ "$(git -C "$VLC" rev-parse HEAD)" = \
        12cd503e3b12e00f0bc36ef568d2edf985c7d473 ]
    [ "$(git -C "$VLC" rev-parse HEAD^{tree})" = \
        c4e6620b24c3530ff883e77549f6fa881c4a9636 ]
    [ -z "$(git -C "$VLC" status --porcelain)" ]
    VLC_REACHABILITY=$VLC/Sources/Helpers/Network/Reachability.h
    [ "$(shasum -a 256 "$VLC_REACHABILITY" | awk '{ print $1 }')" = \
        45153117d41c9bbdee5c22039a588d1f02f5a3620a38d0cd7da2c31f11fab2c1 ]
    xcrun clang -fsyntax-only -fobjc-arc -F "$PROOF" \
        -x objective-c-header "$VLC_REACHABILITY"
    exact=$exact,vlc-untouched
fi

printf 'SYSTEMCONFIGURATION_HOST_GATE_OK interface=apple-exact exports=16 corpus=%s\n' \
    "$exact"
