#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
WORK=$(mktemp -d "${TMPDIR:-/private/tmp}/foundation-guest-services.XXXXXX")
SUITE="com.openfoundation.services.$$"
PREFS="/private/tmp/open-foundation-userdefaults-$SUITE.json"
MUTATED_SUITE="com.openfoundation.services.rename-failure.$$"
MUTATED_PREFS="/private/tmp/open-foundation-userdefaults-$MUTATED_SUITE.json"

cleanup() {
    if [ -e "$PREFS" ]; then
        if command -v trash >/dev/null 2>&1; then trash "$PREFS"; else rm -f -- "$PREFS"; fi
    fi
    if [ -e "$MUTATED_PREFS" ]; then
        if command -v trash >/dev/null 2>&1; then trash "$MUTATED_PREFS"; else rm -f -- "$MUTATED_PREFS"; fi
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

# The persistence gate must reject a failed atomic publication rather than
# reporting success after merely writing an unpublished temporary file.
sed '0,/return Darwin.rename(from, to)/{s/return Darwin.rename(from, to)/return -1/}' \
    "$ROOT/full/foundation/UserDefaults.swift" > "$WORK/UserDefaults.mutated.swift"
"${SWIFTC[@]}" -D FOUNDATION_GUEST_SERVICES_HOST -parse-as-library -wmo \
    -module-name MutatedDefaultsFoundationGuestServices \
    -emit-module -emit-module-path "$WORK/MutatedDefaultsFoundationGuestServices.swiftmodule" \
    -emit-object -o "$WORK/MutatedDefaultsFoundationGuestServices.o" \
    "$ROOT/full/foundation/DateFormatter.swift" "$WORK/UserDefaults.mutated.swift"
sed 's/import FoundationGuestServices/import MutatedDefaultsFoundationGuestServices/; s/FoundationGuestServices\.UserDefaults/MutatedDefaultsFoundationGuestServices.UserDefaults/g' \
    "$ROOT/full/foundation/tests/FoundationGuestUserDefaultsRuntime.swift" \
    > "$WORK/FoundationGuestUserDefaultsRuntime.mutated.swift"
"${SWIFTC[@]}" -I "$WORK" \
    "$WORK/FoundationGuestUserDefaultsRuntime.mutated.swift" \
    "$WORK/MutatedDefaultsFoundationGuestServices.o" -o "$WORK/defaults-mutated"
if "$WORK/defaults-mutated" write "$MUTATED_SUITE" \
    > "$WORK/defaults-mutated.log" 2>&1; then
    echo "foundation guest services: failed rename reported persistence success" >&2
    exit 2
fi
grep -F "FAIL: write synchronize" "$WORK/defaults-mutated.log" >/dev/null || {
    echo "foundation guest services: failed rename did not reach persistence assertion" >&2
    exit 2
}
[ ! -e "$MUTATED_PREFS" ] || {
    echo "foundation guest services: failed rename published destination" >&2
    exit 2
}

symbols=$(nm "$WORK/runtime" 2>/dev/null | grep -c 'FoundationGuestServices.*DateFormatter' || true)
[ "$symbols" -gt 5 ] || {
    echo "foundation guest services: formatter symbols missing from runtime" >&2
    exit 2
}

printf 'FOUNDATION_GUEST_SERVICES_HOST_OK date_rows=93 userdefaults=4 mutation=2\n'
