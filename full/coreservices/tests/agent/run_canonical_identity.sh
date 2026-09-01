#!/usr/bin/env bash
# Build staged Foundation/CoreFoundation identities, then CoreServices, and
# prove CoreServices CF parameter/result types are those canonical identities.
# This is not an integration-compatible fallback dylib.
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

# Staged CoreFoundation identities from the canonical Foundation compatibility
# source. CFString/CFURL/CFDictionary are String/URL/[String:Any].
swiftc -warnings-as-errors -parse-as-library \
    -module-name CoreFoundation \
    -emit-module -emit-module-path "$STAGE/CoreFoundation.swiftmodule" \
    -emit-library -o "$STAGE/libCoreFoundation.dylib" \
    "$ROOT/full/foundation/CoreFoundationCompatibility.swift"

# CoreServices production sources against system Foundation (same identities).
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

# Identity probe: Foundation + CoreFoundation + CoreServices.
swiftc -warnings-as-errors \
    -I "$STAGE" \
    "$FRAMEWORK/tests/agent/CoreServicesIdentityProbe.swift" \
    "$STAGE/libCoreServices.dylib" \
    "$STAGE/libCoreFoundation.dylib" \
    -o "$STAGE/identity-probe"

probe_output=$(LD_LIBRARY_PATH="$STAGE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$STAGE/identity-probe")
printf '%s\n' "$probe_output" | grep -Fqx -- 'CORESERVICES_CF_IDENTITY_OK' \
    || die 'identity probe did not emit CORESERVICES_CF_IDENTITY_OK'

# C ABI audit: Swift overlay must not emit _UTType*/_kUT* C exports.
nm_out=$(nm -D "$STAGE/libCoreServices.dylib" 2>/dev/null || nm "$STAGE/libCoreServices.dylib")
readelf_out=$(readelf -Ws "$STAGE/libCoreServices.dylib" 2>/dev/null || true)
printf '%s\n' "$nm_out" "$readelf_out" | grep -E '(^|[^[:alnum:]])(_UTType|_kUT)' \
    && die 'libCoreServices.dylib emitted _UTType*/_kUT* C ABI symbols'

python3 -B "$ROOT/full/framework-fanout/validate_seed.py" \
    --framework "$FRAMEWORK" --phase deliverable

printf '%s\n' "$probe_output"
printf 'CORESERVICES_C_ABI_NOT_EMITTED\n'
printf 'CORESERVICES_IDENTITY_HOST_OK\n'
