#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
WORK=$(mktemp -d "${TMPDIR:-/private/tmp}/foundation-contract-host.XXXXXX")

cleanup() {
    find "$WORK" -depth -delete
}
trap cleanup EXIT

xcrun swiftc -swift-version 6 -warnings-as-errors \
    "$ROOT/full/foundation/tests/FoundationCanonicalContractsOracle.swift" \
    -o "$WORK/oracle"

"$WORK/oracle" | tee "$WORK/oracle.txt"
grep -Fx \
    'FOUNDATION_CANONICAL_ORACLE_OK predicate=constant,block dictionary=copy,removeAll nscopying=nil-zone coder=keyed stream=memory,buffer corefoundation=uuid,time reference=array,data' \
    "$WORK/oracle.txt" >/dev/null

printf '%s\n' \
    'FOUNDATION_CANONICAL_HOST_TEST_OK oracle=xcode-26.1 signatures=exact behavior=predicate,dictionary,nscopying,coder,stream,cfuuid,array,data'
