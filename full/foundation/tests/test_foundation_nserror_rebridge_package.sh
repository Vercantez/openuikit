#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
PACKAGE=${PACKAGE:-/opt/openuikit/core-cold/packages/core-guest-r23-44bd5af-20260901}
EXPECTED_PACKAGE_COMPLETE_SHA256=${EXPECTED_PACKAGE_COMPLETE_SHA256:-312288bda28a2fa923b75806c2aabbaaae2723cbf3d7e8f460f29605ac0f5ea3}
SWIFTC=${SWIFTC:-swiftc}
LD=${LD:-ld64.lld-18}
PROBE_SOURCE=${PROBE_SOURCE:-$ROOT/full/foundation/tests/FoundationGuestNSErrorRebridgeRuntime.swift}
PROBE_MODULE=${PROBE_MODULE:-FoundationGuestNSErrorRebridgeRuntime}
EXPECTED_RUNTIME_OUTPUT=${EXPECTED_RUNTIME_OUTPUT:-FOUNDATION_NSERROR_REBRIDGE_OK existing=identity typed=custom-user-info plain=domain-code}
PROOF=$(mktemp -d /tmp/foundation-nserror-rebridge.XXXXXX)
cleanup() {
    rm -rf "$PROOF"
}
trap cleanup EXIT

test -f "$PACKAGE/PACKAGE_COMPLETE"
actual_package_hash=$(sha256sum "$PACKAGE/PACKAGE_COMPLETE" | awk '{print $1}')
test "$actual_package_hash" = "$EXPECTED_PACKAGE_COMPLETE_SHA256"

mapfile -d '' -t compile_arguments < "$PACKAGE/compile-flags.rsp"
mapfile -d '' -t link_arguments < "$PACKAGE/link-inputs.rsp"

(
    cd "$PACKAGE"
    "$SWIFTC" "${compile_arguments[@]}" -parse-as-library \
        -module-name "$PROBE_MODULE" -emit-object \
        "$PROBE_SOURCE" \
        -o "$PROOF/runtime.o"
    "$LD" -dead_strip -ignore_auto_link \
        -exported_symbol __mh_execute_header \
        -rpath @loader_path/../lib \
        -rpath "$PACKAGE/lib" \
        -o "$PROOF/FoundationGuestNSErrorRebridgeRuntime" \
        "$PROOF/runtime.o" "${link_arguments[@]}"
)

runtime_output=$(
    cd "$PACKAGE"
    host_root=$PACKAGE/guest-root/host
    LD_LIBRARY_PATH="$host_root${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$host_root/libOpenDispatchHost.so:$host_root/libOpenFoundationInternationalizationHost.so:$host_root/libOpenURLTransportHost.so:$host_root/libOpenRelativeTimeHost.so${LD_PRELOAD:+:$LD_PRELOAD}" \
        guest-root/machorun "$PROOF/FoundationGuestNSErrorRebridgeRuntime"
)
test "$runtime_output" = "$EXPECTED_RUNTIME_OUTPUT"
printf '%s\n' "$runtime_output"
printf 'FOUNDATION_NSERROR_REBRIDGE_PACKAGE_OK package=%s\n' \
    "$actual_package_hash"
