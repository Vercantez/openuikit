#!/usr/bin/env bash
# Audit CoreServices Swift overlay identities without a test-owned
# CoreFoundation lookalike. Exact Unmanaged Copy/Create signatures are a
# central Foundation/CoreFoundation blocker (CFString == String, no CFArray).
set -euo pipefail

die() {
    printf 'CORESERVICES_IDENTITY_GATE_REFUSING: %s\n' "$*" >&2
    exit 1
}

ROOT=$(git -C "$(dirname -- "${BASH_SOURCE[0]}")" rev-parse --show-toplevel) \
    || die 'identity script is not inside a Git worktree'
FRAMEWORK="$ROOT/full/coreservices"
STAGE=$(mktemp -d "${TMPDIR:-/tmp}/coreservices-identity.XXXXXX")
cleanup() {
    rm -rf -- "$STAGE"
}
trap cleanup EXIT HUP INT TERM

command -v swiftc >/dev/null 2>&1 || die 'swiftc is unavailable'
command -v python3 >/dev/null 2>&1 || die 'python3 is unavailable'
command -v nm >/dev/null 2>&1 || die 'nm is unavailable'
command -v readelf >/dev/null 2>&1 || die 'readelf is unavailable'

mapfile -t SOURCES < "$FRAMEWORK/coreservices_guest_sources.txt"
SOURCE_PATHS=()
for relative in "${SOURCES[@]}"; do
    SOURCE_PATHS+=("$ROOT/$relative")
done

swiftc -warnings-as-errors -parse-as-library -emit-library -emit-module \
    -module-name CoreServices \
    -emit-module-path "$STAGE/CoreServices.swiftmodule" \
    -o "$STAGE/libCoreServices.dylib" \
    "${SOURCE_PATHS[@]}"

swiftc -warnings-as-errors \
    -I "$STAGE" \
    "$FRAMEWORK/tests/agent/CoreServicesIdentityProbe.swift" \
    "$STAGE/libCoreServices.dylib" \
    -o "$STAGE/identity-probe"

probe_output=$(LD_LIBRARY_PATH="$STAGE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$STAGE/identity-probe")
printf '%s\n' "$probe_output" | grep -Fqx -- 'CORESERVICES_CF_IDENTITY_OK' \
    || die 'identity probe did not emit CORESERVICES_CF_IDENTITY_OK'
printf '%s\n' "$probe_output" | grep -Fqx -- 'CORESERVICES_UNMANAGED_SURFACE_BLOCKED' \
    || die 'identity probe did not report the Unmanaged surface blocker'

expect_negative_compile() {
    local source=$1
    local label=$2
    local log=$STAGE/negative-${label}.log
    if swiftc -warnings-as-errors -I "$STAGE" \
        "$source" "$STAGE/libCoreServices.dylib" \
        -o "$STAGE/negative-${label}" >"$log" 2>&1
    then
        die "negative compile ${label} unexpectedly succeeded"
    fi
    grep -E 'UTTypeCopy|UTTypeCreate' "$log" >/dev/null \
        || die "negative compile ${label} did not mention Copy/Create names"
}

expect_negative_compile \
    "$FRAMEWORK/tests/agent/CoreServicesUnmanagedSignatureNegative.swift" \
    unmanaged
expect_negative_compile \
    "$FRAMEWORK/tests/agent/CoreServicesDirectOptionalNegative.swift" \
    optional

# C ABI audit: Swift overlay must not emit _UTType*/_kUT* C exports.
# Absence is not implementation of the C ABI.
nm_out=$(nm -D "$STAGE/libCoreServices.dylib" 2>/dev/null || nm "$STAGE/libCoreServices.dylib")
readelf_out=$(readelf -Ws "$STAGE/libCoreServices.dylib" 2>/dev/null || true)
printf '%s\n' "$nm_out" "$readelf_out" | grep -E '(^|[^[:alnum:]])(_UTType|_kUT)' \
    && die 'libCoreServices.dylib emitted _UTType*/_kUT* C ABI symbols'

python3 -B "$ROOT/full/framework-fanout/validate_seed.py" \
    --framework "$FRAMEWORK" --phase deliverable

printf '%s\n' "$probe_output"
printf 'CORESERVICES_C_ABI_NOT_EMITTED\n'
printf 'CORESERVICES_IDENTITY_HOST_OK\n'
