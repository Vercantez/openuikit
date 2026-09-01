#!/usr/bin/env bash
# Build the exact untouched RevenueCat Package.swift library target as a WMO
# ARM64 Mach-O dylib, link an external public-API consumer, audit both load
# closures, and cold-run it. This stage refuses to run until the 530-source
# frontier has completed with status zero.

set -euo pipefail
export GIT_OPTIONAL_LOCKS=0

W=${W:-/w}
PACKAGE=${1:?usage: test_revenuecat_library_product_guest.sh PACKAGE REVENUECAT FRONTIER_PROOF OUTPUT}
REVENUECAT=${2:?usage: test_revenuecat_library_product_guest.sh PACKAGE REVENUECAT FRONTIER_PROOF OUTPUT}
FRONTIER_PROOF=${3:?usage: test_revenuecat_library_product_guest.sh PACKAGE REVENUECAT FRONTIER_PROOF OUTPUT}
OUTPUT=${4:?usage: test_revenuecat_library_product_guest.sh PACKAGE REVENUECAT FRONTIER_PROOF OUTPUT}

EXPECTED_COMMIT=57043e7e0173c48d64e171944ac76a34d2467fa1
EXPECTED_TREE=72a2e1e9b6986fadca9b863d235c4a52aab38fb4
EXPECTED_SOURCE_CENSUS_SHA=74b74c5b1c4d0acd99cd0535e20dfeb0a8db751f6bf01ddb3d69ecae18a9291e
EXCLUDED=Sources/LocalReceiptParsing/ReceiptParser-only-files/PurchasesReceiptParser+Extensions.swift
REVENUECAT_ID=@rpath/libRevenueCat.dylib
APPKIT_ID=/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit
IOKIT_ID=/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit

die() {
    printf 'revenuecat_library_product_guest: %s\n' "$*" >&2
    exit 2
}

case "$FRONTIER_PROOF" in
    /*/revenuecat-appkit-frontier|/*/revenuecat-appkit-frontier-[A-Za-z0-9._-]*) ;;
    *) die "frontier proof has the wrong narrow path: $FRONTIER_PROOF" ;;
esac
case "$OUTPUT" in
    /*/revenuecat-library-proof|/*/revenuecat-library-proof-[A-Za-z0-9._-]*) ;;
    *) die "output has the wrong narrow path: $OUTPUT" ;;
esac
[ ! -e "$OUTPUT" ] || die "output already exists: $OUTPUT"
[ -f "$PACKAGE/PACKAGE_COMPLETE" ] && [ ! -L "$PACKAGE/PACKAGE_COMPLETE" ] \
    || die 'completed core package is missing'
[ -f "$FRONTIER_PROOF/PROOF_COMPLETE" ] \
    && [ ! -L "$FRONTIER_PROOF/PROOF_COMPLETE" ] \
    || die 'completed AppKit frontier proof is missing'
[ -f "$FRONTIER_PROOF/status.txt" ] && [ ! -L "$FRONTIER_PROOF/status.txt" ] \
    || die 'AppKit frontier status is missing'
grep -Fxq 'status=0' "$FRONTIER_PROOF/status.txt" \
    || die '530-source frontier did not complete successfully'
grep -Eq $'^typecheck\tstatus=0\tresult=complete\tstderr-sha256=[0-9a-f]{64}$' \
    "$FRONTIER_PROOF/PROOF_COMPLETE" \
    || die '530-source frontier completion record is not complete'
grep -Fxq $'repository\tcommit=57043e7e0173c48d64e171944ac76a34d2467fa1\ttree=72a2e1e9b6986fadca9b863d235c4a52aab38fb4' \
    "$FRONTIER_PROOF/PROOF_COMPLETE" \
    || die '530-source frontier repository identity drifted'
grep -Fxq $'sources\ttracked=531\tselected=530' \
    "$FRONTIER_PROOF/PROOF_COMPLETE" \
    || die '530-source frontier source census drifted'

[ -d "$REVENUECAT/.git" ] || die 'RevenueCat checkout is missing'
[ "$(git -C "$REVENUECAT" rev-parse HEAD^{commit})" = "$EXPECTED_COMMIT" ] \
    || die 'RevenueCat commit drifted'
[ "$(git -C "$REVENUECAT" rev-parse HEAD^{tree})" = "$EXPECTED_TREE" ] \
    || die 'RevenueCat tree drifted'
[ -z "$(git -C "$REVENUECAT" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'RevenueCat checkout is not untouched'
python3 -B "$W/full/frameworks/core_package_manifest.py" verify \
    --package-root "$PACKAGE"

mkdir -p "$OUTPUT/attestation" "$OUTPUT/lib" "$OUTPUT/module-cache" \
    "$OUTPUT/modules" "$OUTPUT/objects" "$OUTPUT/probe"
mapfile -d '' -t compile_arguments < "$PACKAGE/compile-flags.rsp"
mapfile -d '' -t link_arguments < "$PACKAGE/link-inputs.rsp"
mapfile -d '' -t tracked_sources < <(
    git -C "$REVENUECAT" ls-files -z -- 'Sources/*.swift' 'Sources/**/*.swift' \
        | LC_ALL=C sort -zu
)
[ "${#tracked_sources[@]}" -eq 531 ] \
    || die "tracked Swift source count ${#tracked_sources[@]}, expected 531"
source_census_sha=$(printf '%s\0' "${tracked_sources[@]}" | sha256sum | awk '{print $1}')
[ "$source_census_sha" = "$EXPECTED_SOURCE_CENSUS_SHA" ] \
    || die 'RevenueCat source census hash drifted'
selected_sources=()
excluded_count=0
for relative in "${tracked_sources[@]}"; do
    if [ "$relative" = "$EXCLUDED" ]; then
        excluded_count=$((excluded_count + 1))
    else
        selected_sources+=("$REVENUECAT/$relative")
    fi
done
[ "$excluded_count" -eq 1 ] || die 'receipt-parser-only exclusion count drifted'
[ "${#selected_sources[@]}" -eq 530 ] \
    || die "selected source count ${#selected_sources[@]}, expected 530"

echo '== emit exact WMO RevenueCat module and object'
(
    cd "$PACKAGE"
    swiftc "${compile_arguments[@]}" -swift-version 5 -D SWIFT_PACKAGE \
        -wmo -parse-as-library -module-name RevenueCat \
        -module-link-name RevenueCat \
        -module-cache-path "$OUTPUT/module-cache" \
        -emit-module -emit-module-path "$OUTPUT/modules/RevenueCat.swiftmodule" \
        -emit-object -o "$OUTPUT/objects/RevenueCat.o" \
        "${selected_sources[@]}"
)
for regular in "$OUTPUT/modules/RevenueCat.swiftmodule" \
    "$OUTPUT/objects/RevenueCat.o"; do
    [ -s "$regular" ] && [ ! -L "$regular" ] \
        || die "WMO product artifact is missing, empty, or linked: $regular"
done

echo '== link exact WMO RevenueCat dylib through the canonical package closure'
(
    cd "$PACKAGE"
    ld64.lld-18 -dylib -dead_strip -dead_strip_dylibs -ignore_auto_link \
        -install_name "$REVENUECAT_ID" -rpath "$PACKAGE/lib" \
        -o "$OUTPUT/lib/libRevenueCat.dylib" \
        "$OUTPUT/objects/RevenueCat.o" "${link_arguments[@]}"
)
llvm-otool-18 -hv "$OUTPUT/lib/libRevenueCat.dylib" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'libRevenueCat is not an ARM64 Mach-O dylib'
[ "$(llvm-otool-18 -D "$OUTPUT/lib/libRevenueCat.dylib" | tail -n 1)" = \
    "$REVENUECAT_ID" ] || die 'libRevenueCat install identity drifted'
llvm-nm-18 --undefined-only --extern-only --just-symbol-name \
    "$OUTPUT/lib/libRevenueCat.dylib" | LC_ALL=C sort -u \
    > "$OUTPUT/attestation/revenuecat-imports.txt"
if grep -Fq '_glibc_' "$OUTPUT/attestation/revenuecat-imports.txt"; then
    die 'app-local libRevenueCat acquired a forbidden host ABI import'
fi

echo '== derive the only permitted dylib identities from the verified package'
allowed_loads=$OUTPUT/attestation/package-allowed-load-identities.txt
: > "$allowed_loads"
while IFS=$'\t' read -r record name kind relative _hash _size; do
    [ -n "${relative:-}" ] || continue
    artifact=$PACKAGE/$relative
    [ -f "$artifact" ] && [ ! -L "$artifact" ] || continue
    if llvm-otool-18 -hv "$artifact" 2>/dev/null \
        | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB'; then
        llvm-otool-18 -D "$artifact" 2>/dev/null | tail -n 1 \
            >> "$allowed_loads"
    fi
done < "$PACKAGE/attestation/artifacts.tsv"
printf '%s\n' "$REVENUECAT_ID" >> "$allowed_loads"
LC_ALL=C sort -u "$allowed_loads" -o "$allowed_loads"
[ -s "$allowed_loads" ] || die 'verified package produced no allowed load identities'

audit_loads() {
    local binary=$1 label=$2 output=$3
    llvm-otool-18 -L "$binary" > "$OUTPUT/attestation/$label-loads.txt"
    awk 'NR > 1 { print $1 }' "$OUTPUT/attestation/$label-loads.txt" \
        > "$output"
    [ -s "$output" ] || die "$label has no Mach-O load identities"
    total=$(wc -l < "$output" | tr -d '[:space:]')
    unique=$(LC_ALL=C sort -u "$output" | wc -l | tr -d '[:space:]')
    [ "$total" -eq "$unique" ] || die "$label has duplicate load identities"
    LC_ALL=C sort -u "$output" > "$OUTPUT/attestation/$label-load-identities.sorted"
    comm -23 "$OUTPUT/attestation/$label-load-identities.sorted" \
        "$allowed_loads" > "$OUTPUT/attestation/$label-unpermitted-loads.txt"
    [ ! -s "$OUTPUT/attestation/$label-unpermitted-loads.txt" ] \
        || die "$label loads an identity outside the verified package"
    while IFS= read -r identity; do
        case "$identity" in
            "$APPKIT_ID"|"$IOKIT_ID") ;;
            /System/Library/Frameworks/*)
                die "$label loads an unapproved Apple framework identity: $identity" ;;
        esac
    done < "$output"
    if grep -Fq 'libAppKit.dylib' "$output"; then
        die "$label uses a flat AppKit identity"
    fi
}

library_load_ids=$OUTPUT/attestation/revenuecat-load-identities.txt
audit_loads "$OUTPUT/lib/libRevenueCat.dylib" revenuecat "$library_load_ids"
require_load_once() {
    local identity=$1 label=$2 count
    count=$(awk -v expected="$identity" \
        '$1 == expected { count++ } END { print count + 0 }' "$library_load_ids")
    [ "$count" -eq 1 ] \
        || die "libRevenueCat $label load count $count, expected 1"
}
require_load_once '@rpath/libFoundation.dylib' Foundation
require_load_once '@rpath/libStoreKit.dylib' StoreKit
require_load_once '@rpath/libSwiftUI.dylib' SwiftUI
require_load_once '@rpath/libUIKit.dylib' UIKit
require_load_once "$APPKIT_ID" AppKit
for implementation_identity in \
    "$IOKIT_ID" \
    '@rpath/libAdServices.dylib' \
    '@rpath/libCombine.dylib' \
    '@rpath/libCommonCrypto.dylib' \
    '@rpath/libCompression.dylib' \
    '@rpath/libCoreText.dylib' \
    '@rpath/libCryptoKit.dylib' \
    '@rpath/libOSLog.dylib' \
    '@rpath/libSecurity.dylib' \
    '@rpath/libz.dylib'; do
    implementation_count=$(awk -v expected="$implementation_identity" \
        '$1 == expected { count++ } END { print count + 0 }' "$library_load_ids")
    [ "$implementation_count" -le 1 ] \
        || die "libRevenueCat duplicates implementation load $implementation_identity"
done

echo '== compile and link an external public-API-only RevenueCat consumer'
(
    cd "$PACKAGE"
    swiftc "${compile_arguments[@]}" -swift-version 5 \
        -I "$OUTPUT/modules" -parse-as-library \
        -module-name RevenueCatLibraryRuntime \
        -module-cache-path "$OUTPUT/module-cache" \
        -emit-object -o "$OUTPUT/objects/RevenueCatLibraryRuntime.o" \
        "$W/full/appkit/tests/RevenueCatLibraryRuntime.swift"
    ld64.lld-18 -dead_strip -dead_strip_dylibs -ignore_auto_link \
        -exported_symbol __mh_execute_header \
        -rpath "$OUTPUT/lib" -rpath "$PACKAGE/lib" \
        -needed_library "$OUTPUT/lib/libRevenueCat.dylib" \
        -o "$OUTPUT/probe/RevenueCatLibraryRuntime" \
        "$OUTPUT/objects/RevenueCatLibraryRuntime.o" "${link_arguments[@]}"
)
llvm-otool-18 -hv "$OUTPUT/probe/RevenueCatLibraryRuntime" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]EXECUTE' \
    || die 'RevenueCat public API consumer is not an ARM64 Mach-O executable'
consumer_load_ids=$OUTPUT/attestation/consumer-load-identities.txt
audit_loads "$OUTPUT/probe/RevenueCatLibraryRuntime" consumer "$consumer_load_ids"
consumer_revenuecat_count=$(awk -v expected="$REVENUECAT_ID" \
    '$1 == expected { count++ } END { print count + 0 }' "$consumer_load_ids")
[ "$consumer_revenuecat_count" -eq 1 ] \
    || die "consumer RevenueCat load count $consumer_revenuecat_count, expected 1"

guest_root=$PACKAGE/guest-root
preload=$guest_root/host/libOpenDispatchHost.so:$guest_root/host/libOpenFoundationInternationalizationHost.so:$guest_root/host/libOpenURLTransportHost.so:$guest_root/host/libOpenRelativeTimeHost.so:$guest_root/host/libOpenCompressionHost.so:$guest_root/host/libOpenZlibHost.so
IFS=: read -r -a preload_files <<< "$preload"
for host_helper in "${preload_files[@]}"; do
    [ -f "$host_helper" ] && [ ! -L "$host_helper" ] \
        || die "required host preload is missing or linked: $host_helper"
done
(
    cd "$OUTPUT"
    LD_LIBRARY_PATH="$guest_root/host${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    LD_PRELOAD="$preload${LD_PRELOAD:+:$LD_PRELOAD}" \
        MACHORUN_ROOT="$guest_root" \
        "$guest_root/machorun" ./probe/RevenueCatLibraryRuntime
) > "$OUTPUT/RevenueCatLibraryRuntime.log" \
    2> "$OUTPUT/RevenueCatLibraryRuntime.stderr"
cat "$OUTPUT/RevenueCatLibraryRuntime.log"
grep -Fxq \
    'REVENUECAT_LIBRARY_MACHO_OK api=LogLevel,Store,PeriodType log=INFO stores=12 periods=4' \
    "$OUTPUT/RevenueCatLibraryRuntime.log" \
    || die 'RevenueCat public API cold runtime marker is missing'

{
    printf 'format\trevenuecat-library-product-proof-v1\n'
    printf 'repository\tcommit=%s\ttree=%s\n' "$EXPECTED_COMMIT" "$EXPECTED_TREE"
    printf 'sources\ttracked=531\tselected=530\tcensus-sha256=%s\n' \
        "$source_census_sha"
    printf 'module\tsha256=%s\n' \
        "$(sha256sum "$OUTPUT/modules/RevenueCat.swiftmodule" | awk '{print $1}')"
    printf 'library\tidentity=%s\tsha256=%s\tloads-sha256=%s\timports-sha256=%s\n' \
        "$REVENUECAT_ID" \
        "$(sha256sum "$OUTPUT/lib/libRevenueCat.dylib" | awk '{print $1}')" \
        "$(sha256sum "$library_load_ids" | awk '{print $1}')" \
        "$(sha256sum "$OUTPUT/attestation/revenuecat-imports.txt" | awk '{print $1}')"
    printf 'consumer\tsha256=%s\tloads-sha256=%s\n' \
        "$(sha256sum "$OUTPUT/probe/RevenueCatLibraryRuntime" | awk '{print $1}')" \
        "$(sha256sum "$consumer_load_ids" | awk '{print $1}')"
    printf 'cold-runtime\tsha256=%s\n' \
        "$(sha256sum "$OUTPUT/RevenueCatLibraryRuntime.log" | awk '{print $1}')"
} > "$OUTPUT/PROOF_COMPLETE"
printf 'REVENUECAT_LIBRARY_PRODUCT_OK commit=%s sources=530 wmo=1 consumer=public-api runtime=cold\n' \
    "$EXPECTED_COMMIT"
