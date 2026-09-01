#!/usr/bin/env bash
# Advance the exact untouched RevenueCat production target through the AppKit
# boundary. A later first-party diagnostic is an accepted frontier result;
# AppKit import/type failures, subject drift, or package drift are not.

set -euo pipefail
export GIT_OPTIONAL_LOCKS=0

W=${W:-/w}
PACKAGE=${1:?usage: test_revenuecat_appkit_frontier_guest.sh PACKAGE REVENUECAT OUTPUT}
REVENUECAT=${2:?usage: test_revenuecat_appkit_frontier_guest.sh PACKAGE REVENUECAT OUTPUT}
OUTPUT=${3:?usage: test_revenuecat_appkit_frontier_guest.sh PACKAGE REVENUECAT OUTPUT}

EXPECTED_COMMIT=57043e7e0173c48d64e171944ac76a34d2467fa1
EXPECTED_TREE=72a2e1e9b6986fadca9b863d235c4a52aab38fb4
EXCLUDED=Sources/LocalReceiptParsing/ReceiptParser-only-files/PurchasesReceiptParser+Extensions.swift
APPKIT_ID=/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit

die() {
    printf 'revenuecat_appkit_frontier_guest: %s\n' "$*" >&2
    exit 2
}

case "$OUTPUT" in
    /*/revenuecat-appkit-frontier|/*/revenuecat-appkit-frontier-[A-Za-z0-9._-]*) ;;
    *) die "output must be an absolute narrowly named AppKit frontier path: $OUTPUT" ;;
esac
[ ! -e "$OUTPUT" ] || die "output already exists: $OUTPUT"
[ -f "$PACKAGE/PACKAGE_COMPLETE" ] && [ ! -L "$PACKAGE/PACKAGE_COMPLETE" ] \
    || die 'completed core package is missing'
[ -d "$REVENUECAT/.git" ] || die 'RevenueCat checkout is missing'
[ "$(git -C "$REVENUECAT" rev-parse HEAD^{commit})" = "$EXPECTED_COMMIT" ] \
    || die 'RevenueCat commit drifted'
[ "$(git -C "$REVENUECAT" rev-parse HEAD^{tree})" = "$EXPECTED_TREE" ] \
    || die 'RevenueCat tree drifted'
[ -z "$(git -C "$REVENUECAT" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'RevenueCat checkout is not untouched'

python3 -B "$W/full/frameworks/core_package_manifest.py" verify \
    --package-root "$PACKAGE"

framework=$PACKAGE/frameworks/AppKit.framework
framework_binary=$framework/Versions/C/AppKit
runtime_binary=$PACKAGE/guest-root/darwin$APPKIT_ID
[ -f "$framework_binary" ] && [ ! -L "$framework_binary" ] \
    || die 'versioned AppKit framework binary is missing'
[ -f "$runtime_binary" ] && [ ! -L "$runtime_binary" ] \
    || die 'runtime AppKit framework binary is missing'
cmp "$framework_binary" "$runtime_binary" \
    || die 'compile and runtime AppKit framework binaries differ'
[ "$(llvm-otool-18 -D "$framework_binary" | tail -n 1)" = "$APPKIT_ID" ] \
    || die 'AppKit framework install identity drifted'
llvm-otool-18 -hv "$framework_binary" \
    | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64.*[[:space:]]DYLIB' \
    || die 'AppKit framework is not an ARM64 Mach-O dylib'

mkdir -p "$OUTPUT/module-cache"
mapfile -d '' -t compile_arguments < "$PACKAGE/compile-flags.rsp"
mapfile -d '' -t link_arguments < "$PACKAGE/link-inputs.rsp"

pair_count() {
    local first=$1 second=$2 count=0 index
    for index in "${!compile_arguments[@]}"; do
        if [ "${compile_arguments[$index]}" = "$first" ] \
            && [ "${compile_arguments[$((index + 1))]:-}" = "$second" ]; then
            count=$((count + 1))
        fi
    done
    printf '%s\n' "$count"
}
[ "$(pair_count -F frameworks)" -eq 1 ] \
    || die 'compile contract must contain -F frameworks exactly once'
framework_pair_count=0
for index in "${!link_arguments[@]}"; do
    if [ "${link_arguments[$index]}" = -framework ] \
        && [ "${link_arguments[$((index + 1))]:-}" = AppKit ]; then
        framework_pair_count=$((framework_pair_count + 1))
    fi
done
[ "$framework_pair_count" -eq 1 ] \
    || die 'link contract must contain -framework AppKit exactly once'

mapfile -d '' -t tracked_sources < <(
    git -C "$REVENUECAT" ls-files -z -- 'Sources/*.swift' 'Sources/**/*.swift' \
        | LC_ALL=C sort -zu
)
[ "${#tracked_sources[@]}" -eq 531 ] \
    || die "tracked Swift source count ${#tracked_sources[@]}, expected 531"
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

set +e
(
    cd "$PACKAGE"
    swiftc "${compile_arguments[@]}" -swift-version 5 -parse-as-library \
        -module-name RevenueCat -typecheck \
        -module-cache-path "$OUTPUT/module-cache" \
        "${selected_sources[@]}"
) > "$OUTPUT/typecheck.stdout" 2> "$OUTPUT/typecheck.stderr"
status=$?
set -e
printf 'status=%s\n' "$status" > "$OUTPUT/status.txt"
printf 'tracked=531 selected=530 excluded=%s\n' "$EXCLUDED" \
    > "$OUTPUT/source-count.txt"

if grep -Fq "no such module 'AppKit'" "$OUTPUT/typecheck.stderr"; then
    die 'full RevenueCat typecheck remains stuck on the AppKit import'
fi
if grep -Eq 'cannot find (type |)\x27?(NSApplication|NSAlert|NSWindow|NSWorkspace|NSFont|NSFontManager|NSColor)\x27? in scope|has no member .*(NSApplication|NSAlert|NSWindow|NSWorkspace|NSFont|NSFontManager|NSColor)' \
    "$OUTPUT/typecheck.stderr"; then
    die 'full RevenueCat typecheck found an incomplete AppKit surface'
fi

if [ "$status" -eq 0 ]; then
    printf 'complete\n' > "$OUTPUT/NEXT_FRONTIER.txt"
    result=complete
else
    awk '/error:/{ print; exit }' "$OUTPUT/typecheck.stderr" \
        > "$OUTPUT/NEXT_FRONTIER.txt"
    [ -s "$OUTPUT/NEXT_FRONTIER.txt" ] \
        || die 'failed typecheck did not report a compiler error'
    result=advanced
fi

{
    printf 'format\trevenuecat-appkit-frontier-proof-v1\n'
    printf 'repository\tcommit=%s\ttree=%s\n' "$EXPECTED_COMMIT" "$EXPECTED_TREE"
    printf 'sources\ttracked=531\tselected=530\n'
    printf 'appkit\tidentity=%s\tsha256=%s\n' "$APPKIT_ID" \
        "$(sha256sum "$framework_binary" | awk '{print $1}')"
    printf 'typecheck\tstatus=%s\tresult=%s\tstderr-sha256=%s\n' \
        "$status" "$result" \
        "$(sha256sum "$OUTPUT/typecheck.stderr" | awk '{print $1}')"
} > "$OUTPUT/PROOF_COMPLETE"

printf 'REVENUECAT_APPKIT_FRONTIER_OK commit=%s sources=530 result=%s\n' \
    "$EXPECTED_COMMIT" "$result"
