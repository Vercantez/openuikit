#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
PACKAGE=${PACKAGE:-/opt/openuikit/core-cold/packages/core-guest-r23-44bd5af-20260901}
EXPECTED_PACKAGE_COMPLETE_SHA256=${EXPECTED_PACKAGE_COMPLETE_SHA256:-312288bda28a2fa923b75806c2aabbaaae2723cbf3d7e8f460f29605ac0f5ea3}
TARGET=arm64-apple-macos15.0
PROOF=$(mktemp -d /tmp/foundation-objc-headers.XXXXXX)
cleanup() {
    rm -rf "$PROOF"
}
trap cleanup EXIT

test -f "$PACKAGE/PACKAGE_COMPLETE"
actual_package_hash=$(sha256sum "$PACKAGE/PACKAGE_COMPLETE" | awk '{print $1}')
test "$actual_package_hash" = "$EXPECTED_PACKAGE_COMPLETE_SHA256"

run_guest() {
    local executable=$1
    (
        cd "$PACKAGE"
        local host_root=$PACKAGE/guest-root/host
        LD_LIBRARY_PATH="$host_root${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        LD_PRELOAD="$host_root/libOpenDispatchHost.so:$host_root/libOpenFoundationInternationalizationHost.so:$host_root/libOpenURLTransportHost.so:$host_root/libOpenRelativeTimeHost.so${LD_PRELOAD:+:$LD_PRELOAD}" \
            guest-root/machorun "$executable"
    )
}

mkdir -p "$PROOF/include" \
    "$PROOF/frameworks/SystemConfiguration.framework/Headers" \
    "$PROOF/frameworks/SystemConfiguration.framework/Modules" \
    "$PROOF/probe"
while IFS= read -r header; do
    test -n "$header" || continue
    mkdir -p "$(dirname "$PROOF/include/$header")"
    cp "$ROOT/full/foundation/include/$header" \
        "$PROOF/include/$header"
done < "$ROOT/full/foundation/foundation_objc_headers.txt"
mkdir -p "$PROOF/include/arpa"
cp "$ROOT/full/sdk-gaps/usr/include/arpa/inet.h" \
    "$PROOF/include/arpa/inet.h"
for header in OpenSystemConfiguration.h SCNetwork.h SCNetworkReachability.h \
    SystemConfiguration.h; do
    cp "$ROOT/full/systemconfiguration/include/$header" \
        "$PROOF/frameworks/SystemConfiguration.framework/Headers/$header"
done
cp "$ROOT/full/systemconfiguration/include/module.modulemap" \
    "$PROOF/frameworks/SystemConfiguration.framework/Modules/module.modulemap"

clang-18 -target "$TARGET" -isysroot "$PACKAGE/sdk" -x objective-c \
    -fno-objc-arc -std=gnu11 -O2 -Wall -Wextra -Werror \
    -I "$PROOF/include" \
    -c "$ROOT/full/foundation/tests/FoundationObjCNSObjectHeaderProbe.m" \
    -o "$PROOF/foundation-objc-header-probe.o"
ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
    -syslibroot "$PACKAGE/sdk" -dead_strip -e _main \
    -o "$PROOF/probe/FoundationObjCNSObjectHeaderProbe" \
    "$PROOF/foundation-objc-header-probe.o" \
    -L "$PACKAGE/sdk/usr/lib" -lSystem -lobjc

header_runtime_output=$(run_guest "$PROOF/probe/FoundationObjCNSObjectHeaderProbe")
test "$header_runtime_output" = \
    'FOUNDATION_OBJC_NSOBJECT_HEADER_OK protocols=copying,coding,secure-coding runtime=objc-root'
printf '%s\n' "$header_runtime_output"

clang-18 -target "$TARGET" -isysroot "$PACKAGE/sdk" -x objective-c \
    -fno-objc-arc -std=gnu11 -O2 -fvisibility=hidden \
    -Wall -Wextra -Werror -I "$PROOF/include" \
    -I "$ROOT/full/systemconfiguration/include" \
    -c "$ROOT/full/systemconfiguration/SystemConfiguration.m" \
    -o "$PROOF/systemconfiguration.o"
ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
    -syslibroot "$PACKAGE/sdk" -dylib -dead_strip \
    -install_name @rpath/SystemConfiguration.framework/SystemConfiguration \
    -o "$PROOF/frameworks/SystemConfiguration.framework/SystemConfiguration" \
    "$PROOF/systemconfiguration.o" \
    -L "$PACKAGE/sdk/usr/lib" -lSystem -lobjc

llvm-nm-18 --defined-only --extern-only --just-symbol-name \
    "$PROOF/frameworks/SystemConfiguration.framework/SystemConfiguration" \
    | LC_ALL=C sort -u > "$PROOF/systemconfiguration-exports.txt"
cmp "$ROOT/full/systemconfiguration/tests/systemconfiguration-expected.exports" \
    "$PROOF/systemconfiguration-exports.txt"

clang-18 -target "$TARGET" -isysroot "$PACKAGE/sdk" -x objective-c \
    -fno-objc-arc -std=gnu11 -O2 -Wall -Wextra -Werror \
    -I "$PROOF/include" -F "$PROOF/frameworks" \
    -c "$ROOT/full/systemconfiguration/tests/SystemConfigurationGuestRuntime.m" \
    -o "$PROOF/systemconfiguration-runtime.o"
ld64.lld-18 -arch arm64 -platform_version macos 15.0 15.0 \
    -syslibroot "$PACKAGE/sdk" -dead_strip -e _main \
    -rpath @loader_path/../frameworks \
    -o "$PROOF/probe/SystemConfigurationGuestRuntime" \
    "$PROOF/systemconfiguration-runtime.o" \
    "$PROOF/frameworks/SystemConfiguration.framework/SystemConfiguration" \
    -L "$PACKAGE/sdk/usr/lib" -lSystem -lobjc

systemconfiguration_output=$(run_guest "$PROOF/probe/SystemConfigurationGuestRuntime")
test "$systemconfiguration_output" = \
    'SYSTEMCONFIGURATION_GUEST_OK reachability=unknown,host-driven,loopback flags=wifi,cellular,offline callbacks=dispatch,runloop,coalesced,cooperative context=balanced'
printf '%s\n' "$systemconfiguration_output"
printf 'FOUNDATION_OBJC_HEADERS_EC2_OK headers=4 sdk-forwarders=1 consumer=SystemConfiguration.m package=%s\n' \
    "$actual_package_hash"
