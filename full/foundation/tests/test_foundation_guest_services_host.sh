#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
WORK=$(mktemp -d "${TMPDIR:-/private/tmp}/foundation-guest-services.XXXXXX")
SUITE="com.openfoundation.services.$$"
PREFS="/private/tmp/open-foundation-userdefaults-$SUITE.json"

cleanup() {
    if [ -e "$PREFS" ]; then
        if command -v trash >/dev/null 2>&1; then trash "$PREFS"; else rm -f -- "$PREFS"; fi
    fi
    if command -v trash >/dev/null 2>&1; then trash "$WORK"; else rm -rf -- "$WORK"; fi
}
trap cleanup EXIT

SWIFTC=(xcrun swiftc)
SOURCES=(
    "$ROOT/full/foundation/DateFormatter.swift"
    "$ROOT/full/foundation/UserDefaults.swift"
)

"${SWIFTC[@]}" -D FOUNDATION_GUEST_SERVICES_HOST -parse-as-library -wmo \
    -module-name FoundationGuestServices \
    -emit-module -emit-module-path "$WORK/FoundationGuestServices.swiftmodule" \
    -emit-object -o "$WORK/FoundationGuestServices.o" "${SOURCES[@]}"
"${SWIFTC[@]}" "$ROOT/full/foundation/tests/FoundationGuestServicesOracle.swift" \
    -o "$WORK/oracle"
"${SWIFTC[@]}" -I "$WORK" \
    "$ROOT/full/foundation/tests/FoundationGuestServicesRuntime.swift" \
    "$WORK/FoundationGuestServices.o" -o "$WORK/runtime"
"${SWIFTC[@]}" -I "$WORK" \
    "$ROOT/full/foundation/tests/FoundationGuestUserDefaultsRuntime.swift" \
    "$WORK/FoundationGuestServices.o" -o "$WORK/defaults"

"$WORK/oracle" > "$WORK/oracle.txt"
"$WORK/runtime" > "$WORK/runtime.txt"
cmp "$WORK/oracle.txt" "$WORK/runtime.txt"
[ "$(wc -l < "$WORK/oracle.txt" | tr -d '[:space:]')" = 93 ]

"$WORK/defaults" semantics "$SUITE"
"$WORK/defaults" write "$SUITE"
"$WORK/defaults" read "$SUITE"
"$WORK/defaults" clean "$SUITE"

# The formatter oracle must detect a plausible localization regression.
sed '0,/"Feb"/{s/"Feb"/"XXX"/}' "$ROOT/full/foundation/DateFormatter.swift" \
    > "$WORK/DateFormatter.mutated.swift"
"${SWIFTC[@]}" -D FOUNDATION_GUEST_SERVICES_HOST -parse-as-library -wmo \
    -module-name MutatedFoundationGuestServices \
    -emit-module -emit-module-path "$WORK/MutatedFoundationGuestServices.swiftmodule" \
    -emit-object -o "$WORK/MutatedFoundationGuestServices.o" \
    "$WORK/DateFormatter.mutated.swift"
sed 's/import FoundationGuestServices/import MutatedFoundationGuestServices/; s/FoundationGuestServices\.DateFormatter/MutatedFoundationGuestServices.DateFormatter/g' \
    "$ROOT/full/foundation/tests/FoundationGuestServicesRuntime.swift" \
    > "$WORK/FoundationGuestServicesRuntime.mutated.swift"
"${SWIFTC[@]}" -I "$WORK" "$WORK/FoundationGuestServicesRuntime.mutated.swift" \
    "$WORK/MutatedFoundationGuestServices.o" -o "$WORK/runtime-mutated"
"$WORK/runtime-mutated" > "$WORK/runtime-mutated.txt"
if cmp -s "$WORK/oracle.txt" "$WORK/runtime-mutated.txt"; then
    echo "foundation guest services: DateFormatter mutation escaped" >&2
    exit 2
fi

symbols=$(nm "$WORK/runtime" 2>/dev/null | grep -c 'FoundationGuestServices.*DateFormatter' || true)
[ "$symbols" -gt 5 ] || {
    echo "foundation guest services: formatter symbols missing from runtime" >&2
    exit 2
}

printf 'FOUNDATION_GUEST_SERVICES_HOST_OK date_rows=93 userdefaults=4 mutation=1\n'
