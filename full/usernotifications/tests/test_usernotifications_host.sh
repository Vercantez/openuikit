#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
APP=${1:-/private/tmp/app-wave-20260831/IceCubesApp}
EXPECTED_APP_COMMIT=b2db3033fbf67a97b54d25d6dac2df8a029b26b1
EXPECTED_APP_TREE=acecd527919ebd0c868f752b0ac73a2b45fdfcf5
EXPECTED_CONSUMER_SHA256=7435ee6fd9689fcfd6257968ed1facc0c26bbcbbcb5db6c4b05c51476da78176
CONSUMER=Packages/Env/Sources/Env/PushNotificationsService.swift
OUTPUT=$(mktemp -d /private/tmp/usernotifications-host-proof.XXXXXX)
trap 'rm -rf "$OUTPUT"' EXIT

[ -d "$APP/.git" ] || { printf 'missing app checkout: %s\n' "$APP" >&2; exit 2; }
[ -z "$(git -C "$APP" status --short)" ] \
    || { printf 'app checkout is not untouched\n' >&2; exit 2; }
[ "$(git -C "$APP" rev-parse HEAD^{commit})" = "$EXPECTED_APP_COMMIT" ]
[ "$(git -C "$APP" rev-parse HEAD^{tree})" = "$EXPECTED_APP_TREE" ]
[ "$(shasum -a 256 "$APP/$CONSUMER" | awk '{print $1}')" = \
    "$EXPECTED_CONSUMER_SHA256" ]

for token in \
    'extension UNNotification: @unchecked @retroactive Sendable' \
    'extension UNNotificationResponse: @unchecked @retroactive Sendable' \
    'extension UNUserNotificationCenter: @unchecked @retroactive Sendable' \
    'UNUserNotificationCenter.current().delegate = self' \
    'requestAuthorization(options: [.alert, .sound, .badge])' \
    'didReceive response: UNNotificationResponse' \
    'async -> UNNotificationPresentationOptions' \
    'return [.banner, .sound]'; do
    grep -Fq "$token" "$APP/$CONSUMER" \
        || { printf 'consumer token missing: %s\n' "$token" >&2; exit 2; }
done

# Compile the shared surface against Apple's installed module before placing
# the portable module on the import path.
xcrun swiftc -swift-version 6 -typecheck \
    "$ROOT/full/usernotifications/tests/UserNotificationsNativeOracle.swift"

xcrun swiftc -parse-as-library -emit-library -emit-module \
    -module-name UserNotifications \
    -emit-module-path "$OUTPUT/UserNotifications.swiftmodule" \
    -Xlinker -install_name -Xlinker @rpath/libUserNotifications.dylib \
    "$ROOT/full/usernotifications/UserNotifications.swift" \
    -o "$OUTPUT/libUserNotifications.dylib"

xcrun swiftc -parse-as-library -I "$OUTPUT" -L "$OUTPUT" \
    -lUserNotifications \
    "$ROOT/full/usernotifications/tests/UserNotificationsHostRuntime.swift" \
    -o "$OUTPUT/UserNotificationsHostRuntime"

xcrun swiftc -swift-version 6 -strict-concurrency=complete -typecheck \
    -I "$OUTPUT" \
    "$ROOT/full/usernotifications/tests/UserNotificationsNativeOracle.swift"

xcrun swiftc -swift-version 6 -strict-concurrency=complete -typecheck \
    -I "$OUTPUT" \
    "$ROOT/full/usernotifications/tests/IceCubesConsumerCompile.swift"

DYLD_LIBRARY_PATH="$OUTPUT" "$OUTPUT/UserNotificationsHostRuntime" \
    | grep -Fxq \
    'USERNOTIFICATIONS_HOST_OK authorization=fail-closed scheduling=volatile delegate=async response=delivered badge=validated'

[ "$(xcrun otool -D "$OUTPUT/libUserNotifications.dylib" \
    | grep -Fxc '@rpath/libUserNotifications.dylib')" -eq 1 ]
! xcrun otool -L "$OUTPUT/libUserNotifications.dylib" \
    | grep -F '/System/Library/Frameworks/UserNotifications.framework/' >/dev/null

printf 'USERNOTIFICATIONS_HOST_GATE_OK module=UserNotifications dylib=standalone semantics=fail-closed,volatile\n'
printf 'USERNOTIFICATIONS_SWIFT6_CONSUMER_OK retroactive=3 delegate=async options=exact\n'
printf 'USERNOTIFICATIONS_EXACT_CONSUMER_OK app=%s:%s source=%s:%s\n' \
    "$EXPECTED_APP_COMMIT" "$EXPECTED_APP_TREE" "$CONSUMER" \
    "$EXPECTED_CONSUMER_SHA256"
