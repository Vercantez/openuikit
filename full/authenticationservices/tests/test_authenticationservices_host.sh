#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
APP=${ICECUBES_APP_ROOT:-/private/tmp/app-wave-20260831/IceCubesApp}
EXPECTED_APP_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_APP_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
CONSUMER=IceCubesApp/App/Tabs/Settings/AddAccountsView.swift
EXPECTED_CONSUMER_SHA256=0908602ad00913566eeac1a8ce8ad4dc3d86041a55cb35b0edcd319c146eef4b
OUTPUT=$(mktemp -d /private/tmp/authenticationservices-host-proof.XXXXXX)
trap 'rm -rf "$OUTPUT"' EXIT

fail() {
    printf 'authenticationservices-host-test: %s\n' "$*" >&2
    exit 1
}

[ -d "$APP/.git" ] || fail "missing pinned IceCubes checkout: $APP"
[ "$(git -C "$APP" rev-parse HEAD)" = "$EXPECTED_APP_COMMIT" ] \
    || fail 'IceCubes commit drifted'
[ "$(git -C "$APP" rev-parse 'HEAD^{tree}')" = "$EXPECTED_APP_TREE" ] \
    || fail 'IceCubes tree drifted'
[ -z "$(git -C "$APP" status --porcelain --untracked-files=all)" ] \
    || fail 'IceCubes checkout is dirty'
[ "$(shasum -a 256 "$APP/$CONSUMER" | awk '{print $1}')" = \
    "$EXPECTED_CONSUMER_SHA256" ] || fail 'untouched consumer drifted'
grep -Fq '@Environment(\.webAuthenticationSession)' "$APP/$CONSUMER"
grep -Fq 'webAuthenticationSession.authenticate(' "$APP/$CONSUMER"
grep -Fq 'callbackURLScheme:' "$APP/$CONSUMER"

# Check the shared public spellings against Apple's installed framework before
# putting the portable modules on the import path.
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -parse-as-library -typecheck \
    "$ROOT/full/authenticationservices/tests/AuthenticationServicesNativeOracle.swift"
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -parse-as-library \
    "$ROOT/full/authenticationservices/tests/AuthenticationServicesNativeOracle.swift" \
    -o "$OUTPUT/AuthenticationServicesNativeOracle"
"$OUTPUT/AuthenticationServicesNativeOracle" | tee "$OUTPUT/native.log"
grep -Fxq \
    'AUTHENTICATIONSERVICES_APPLE_OK environment=web-session async=scheme-callback browser=shared,ephemeral errors=1,2,3' \
    "$OUTPUT/native.log" || fail 'Apple oracle marker is missing'

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -parse-as-library -emit-module -emit-library \
    -module-name AuthenticationServices \
    -emit-module-path "$OUTPUT/AuthenticationServices.swiftmodule" \
    -Xlinker -install_name -Xlinker @rpath/libAuthenticationServices.dylib \
    "$ROOT/full/authenticationservices/AuthenticationServices.swift" \
    -o "$OUTPUT/libAuthenticationServices.dylib"
xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -parse-as-library -emit-module -emit-library -I "$OUTPUT" -L "$OUTPUT" \
    -module-name _AuthenticationServices_SwiftUI \
    -emit-module-path "$OUTPUT/_AuthenticationServices_SwiftUI.swiftmodule" \
    -Xlinker -install_name \
    -Xlinker @rpath/lib_AuthenticationServices_SwiftUI.dylib \
    "$ROOT/full/authenticationservices/AuthenticationServicesSwiftUI.swift" \
    -o "$OUTPUT/lib_AuthenticationServices_SwiftUI.dylib" \
    -lAuthenticationServices
mkdir -p "$OUTPUT/AuthenticationServices.swiftcrossimport"
cp "$ROOT/full/authenticationservices/SwiftUI.swiftoverlay" \
    "$OUTPUT/AuthenticationServices.swiftcrossimport/SwiftUI.swiftoverlay"

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -parse-as-library -I "$OUTPUT" -L "$OUTPUT" \
    "$ROOT/full/authenticationservices/tests/AuthenticationServicesHostRuntime.swift" \
    -o "$OUTPUT/AuthenticationServicesHostRuntime" \
    -l_AuthenticationServices_SwiftUI -lAuthenticationServices
DYLD_LIBRARY_PATH="$OUTPUT${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
    "$OUTPUT/AuthenticationServicesHostRuntime" | tee "$OUTPUT/host.log"
grep -Fxq \
    'AUTHENTICATIONSERVICES_HOST_OK environment=default startup=locked browser=host-driven callback=validated cancellation=once unavailable=fail-closed' \
    "$OUTPUT/host.log" || fail 'host semantic marker is missing'

xcrun swiftc -swift-version 6 -strict-concurrency=complete \
    -parse-as-library -typecheck -Xfrontend -enable-cross-import-overlays \
    -I "$OUTPUT" \
    "$ROOT/full/authenticationservices/tests/IceCubesAuthenticationServicesConsumer.swift"

[ "$(xcrun otool -D "$OUTPUT/libAuthenticationServices.dylib" \
    | grep -Fxc '@rpath/libAuthenticationServices.dylib')" -eq 1 ]
! xcrun otool -L "$OUTPUT/libAuthenticationServices.dylib" \
    | grep -F '/System/Library/Frameworks/AuthenticationServices.framework/' \
    >/dev/null

printf '%s\n' \
    'AUTHENTICATIONSERVICES_HOST_GATE_OK module=AuthenticationServices,_AuthenticationServices_SwiftUI semantics=startup,host-driven,callback,cancel,fail-closed'
printf 'AUTHENTICATIONSERVICES_EXACT_CONSUMER_OK app=%s:%s source=%s:%s\n' \
    "$EXPECTED_APP_COMMIT" "$EXPECTED_APP_TREE" "$CONSUMER" \
    "$EXPECTED_CONSUMER_SHA256"
