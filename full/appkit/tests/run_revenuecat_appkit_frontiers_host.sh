#!/usr/bin/env bash
# Host-side sterile replay for the exact untouched RevenueCat production target
# and its three already-frozen runtime consumers. The package, support tree, and
# vendor checkout are mounted read-only; every compiler cache is fresh.

set -euo pipefail
export GIT_OPTIONAL_LOCKS=0

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)
PACKAGE=${1:?usage: run_revenuecat_appkit_frontiers_host.sh PACKAGE NEW_OUTPUT_ROOT}
OUTPUT_ROOT=${2:?usage: run_revenuecat_appkit_frontiers_host.sh PACKAGE NEW_OUTPUT_ROOT}
REVENUECAT=/private/tmp/icecubes-remote-cache-v3-20260831/objects/sha256/a1/a16489e07f95228216b605ae93db42c38ae218f3f0e07bc8efefefd862b27f12/repository
CONTAINER_IMAGE=sha256:138303d276d49b9b3b6aa9ee277dfb30b876e24557f80c07fd5d52044ef2d9d7

EXPECTED_SUPPORT_BASE=36f16f80ea10a2adc037caf908cd3077314c1b06
EXPECTED_REVENUECAT_COMMIT=57043e7e0173c48d64e171944ac76a34d2467fa1
EXPECTED_REVENUECAT_TREE=72a2e1e9b6986fadca9b863d235c4a52aab38fb4
EXPECTED_SOURCE_CENSUS_SHA=74b74c5b1c4d0acd99cd0535e20dfeb0a8db751f6bf01ddb3d69ecae18a9291e
EXPECTED_APPKIT_DRIVER_SHA=ae52748a4c7a6437245d008d80f6acd4305b1704d8ff30ce4a164659099e5728
EXPECTED_RUNTIME_DRIVER_SHA=8c9459746c354819b361682942b3b3614191f2c5e624f2a68fcd72c384d3d0b6
EXPECTED_MANIFEST_TOOL_SHA=26a9bfc26bd4b36aa357437874b608583894d16a2d3a13314e70dccec6947f7a
EXPECTED_LIBRARY_DRIVER_SHA=b568d20291fdeb6db0b9a468d00c40380cc6cbd6eca7e4822bc81c919d02d268
EXPECTED_LIBRARY_CONSUMER_SHA=2b706e20f65f7a9ff3565c5dae70bcdc99e24ebcd418c767c708f86f6259f523

die() {
    printf 'revenuecat_appkit_host: REFUSING -- %s\n' "$*" >&2
    exit 2
}

for tool in basename docker git mktemp mv shasum awk grep; do
    command -v "$tool" >/dev/null 2>&1 || die "required host tool is missing: $tool"
done
case "$PACKAGE" in /*) ;; *) die "package path must be absolute: $PACKAGE" ;; esac
case "$OUTPUT_ROOT" in /*) ;; *) die "output path must be absolute: $OUTPUT_ROOT" ;; esac
output_name=$(basename "$OUTPUT_ROOT")
case "$output_name" in
    revenuecat-appkit-production-proof-*) ;;
    *) die "output has the wrong narrow prefix: $OUTPUT_ROOT" ;;
esac
case "$output_name" in
    *[!A-Za-z0-9._-]*) die "output basename contains unsafe characters: $output_name" ;;
esac
[ -d "$PACKAGE" ] && [ ! -L "$PACKAGE" ] || die 'package is missing or linked'
[ -f "$PACKAGE/PACKAGE_COMPLETE" ] && [ ! -L "$PACKAGE/PACKAGE_COMPLETE" ] \
    || die 'package completion record is missing or linked'
PACKAGE_COMPLETE_SHA_BEFORE=$(shasum -a 256 "$PACKAGE/PACKAGE_COMPLETE" \
    | awk '{print $1}')
[ ! -e "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ] \
    || die "output already exists: $OUTPUT_ROOT"
OUTPUT_PARENT=$(dirname "$OUTPUT_ROOT")
[ -d "$OUTPUT_PARENT" ] && [ ! -L "$OUTPUT_PARENT" ] \
    || die "output parent is missing or linked: $OUTPUT_PARENT"

git -C "$ROOT" merge-base --is-ancestor "$EXPECTED_SUPPORT_BASE" HEAD \
    || die 'support checkout does not descend from the frozen AppKit integration'
[ -z "$(git -C "$ROOT" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'support checkout is not clean'
[ "$(git -C "$REVENUECAT" rev-parse HEAD^{commit})" = \
    "$EXPECTED_REVENUECAT_COMMIT" ] || die 'RevenueCat commit drifted'
[ "$(git -C "$REVENUECAT" rev-parse HEAD^{tree})" = \
    "$EXPECTED_REVENUECAT_TREE" ] || die 'RevenueCat tree drifted'
[ -z "$(git -C "$REVENUECAT" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'RevenueCat checkout is not untouched'

hash_file() {
    shasum -a 256 "$1" | awk '{print $1}'
}
require_hash() {
    local file=$1 expected=$2 label=$3 actual
    [ -f "$file" ] && [ ! -L "$file" ] || die "$label is missing or linked"
    actual=$(hash_file "$file")
    [ "$actual" = "$expected" ] \
        || die "$label hash $actual, expected $expected"
}
require_hash "$ROOT/full/appkit/tests/test_revenuecat_appkit_frontier_guest.sh" \
    "$EXPECTED_APPKIT_DRIVER_SHA" 'AppKit frontier driver'
require_hash "$ROOT/full/adservices/tests/test_revenuecat_frontier_guest.sh" \
    "$EXPECTED_RUNTIME_DRIVER_SHA" 'runtime frontier driver'
require_hash "$ROOT/full/frameworks/core_package_manifest.py" \
    "$EXPECTED_MANIFEST_TOOL_SHA" 'package manifest verifier'
require_hash "$ROOT/full/appkit/tests/test_revenuecat_library_product_guest.sh" \
    "$EXPECTED_LIBRARY_DRIVER_SHA" 'RevenueCat library product driver'
require_hash "$ROOT/full/appkit/tests/RevenueCatLibraryRuntime.swift" \
    "$EXPECTED_LIBRARY_CONSUMER_SHA" 'RevenueCat public API consumer'

source_count=$(git -C "$REVENUECAT" ls-files -z -- \
    'Sources/*.swift' 'Sources/**/*.swift' | LC_ALL=C sort -zu \
    | tr '\0' '\n' | wc -l | tr -d '[:space:]')
source_census_sha=$(git -C "$REVENUECAT" ls-files -z -- \
    'Sources/*.swift' 'Sources/**/*.swift' | LC_ALL=C sort -zu \
    | shasum -a 256 | awk '{print $1}')
[ "$source_count" -eq 531 ] || die "RevenueCat source count is $source_count, expected 531"
[ "$source_census_sha" = "$EXPECTED_SOURCE_CENSUS_SHA" ] \
    || die 'RevenueCat source census hash drifted'

actual_image=$(docker image inspect --format '{{.Id}}' "$CONTAINER_IMAGE" 2>/dev/null) \
    || die "container image is unavailable: $CONTAINER_IMAGE"
[ "$actual_image" = "$CONTAINER_IMAGE" ] || die 'container image identity drifted'
image_platform=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' \
    "$CONTAINER_IMAGE")
[ "$image_platform" = linux/arm64 ] \
    || die "container platform is $image_platform, expected linux/arm64"

RUN_ROOT=$(mktemp -d "$OUTPUT_PARENT/.revenuecat-appkit-run.XXXXXX")
RESULT=$RUN_ROOT/result
RUN_SUCCESS=0
quarantine() {
    status=$?
    trap - EXIT
    if [ "$RUN_SUCCESS" -ne 1 ] && [ -d "$RUN_ROOT" ]; then
        if [ -d "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ]; then
            mv -- "$OUTPUT_ROOT" "$RUN_ROOT/published-output"
        fi
        invalid=${RUN_ROOT}.INVALID-DO-NOT-USE
        [ ! -e "$invalid" ] || die "quarantine path unexpectedly exists: $invalid"
        mv -- "$RUN_ROOT" "$invalid"
        printf 'revenuecat_appkit_host: quarantined failed run at %s\n' "$invalid" >&2
    fi
    exit "$status"
}
trap quarantine EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkdir -p "$RESULT"

docker run --rm --pull never --platform linux/arm64 \
    --network none --read-only \
    --tmpfs /tmp:rw,exec,nosuid,nodev,mode=1777 \
    -v "$ROOT:/w:ro" \
    -v "$PACKAGE:/package:ro" \
    -v "$REVENUECAT:/revenuecat:ro" \
    -v "$RESULT:/proof" \
    "$CONTAINER_IMAGE" bash -lc '
        set -euo pipefail
        W=/w /w/full/appkit/tests/test_revenuecat_appkit_frontier_guest.sh \
            /package /revenuecat /proof/revenuecat-appkit-frontier
        typecheck_result=$(awk -F "\t" '\''$1 == "typecheck" { \
            sub(/^result=/, "", $3); print $3 }'\'' \
            /proof/revenuecat-appkit-frontier/PROOF_COMPLETE)
        if [ "$typecheck_result" = complete ]; then
            W=/w /w/full/appkit/tests/test_revenuecat_library_product_guest.sh \
                /package /revenuecat \
                /proof/revenuecat-appkit-frontier \
                /proof/revenuecat-library-proof
        fi
        W=/w /w/full/adservices/tests/test_revenuecat_frontier_guest.sh \
            /package /revenuecat /proof/revenuecat-frontier-proof
    ' > "$RESULT/docker.stdout" 2> "$RESULT/docker.stderr"

[ "$(hash_file "$PACKAGE/PACKAGE_COMPLETE")" = "$PACKAGE_COMPLETE_SHA_BEFORE" ] \
    || die 'package completion record changed during replay'
[ "$(git -C "$REVENUECAT" rev-parse HEAD^{commit})" = \
    "$EXPECTED_REVENUECAT_COMMIT" ] || die 'RevenueCat commit changed during replay'
[ "$(git -C "$REVENUECAT" rev-parse HEAD^{tree})" = \
    "$EXPECTED_REVENUECAT_TREE" ] || die 'RevenueCat tree changed during replay'
[ -z "$(git -C "$REVENUECAT" status --porcelain=v1 --untracked-files=all)" ] \
    || die 'RevenueCat checkout changed during replay'

APPKIT_PROOF=$RESULT/revenuecat-appkit-frontier
RUNTIME_PROOF=$RESULT/revenuecat-frontier-proof
for regular in "$APPKIT_PROOF/PROOF_COMPLETE" "$APPKIT_PROOF/NEXT_FRONTIER.txt" \
    "$APPKIT_PROOF/source-count.txt" "$RUNTIME_PROOF/PROOF_COMPLETE" \
    "$RUNTIME_PROOF/RevenueCatAttributionRuntime.log" \
    "$RUNTIME_PROOF/RevenueCatZlibRuntime.log" \
    "$RUNTIME_PROOF/RevenueCatIOKitRuntime.log"; do
    [ -f "$regular" ] && [ ! -L "$regular" ] \
        || die "required proof artifact is missing or linked: $regular"
done
grep -Fxq $'repository\tcommit=57043e7e0173c48d64e171944ac76a34d2467fa1\ttree=72a2e1e9b6986fadca9b863d235c4a52aab38fb4' \
    "$APPKIT_PROOF/PROOF_COMPLETE" || die 'AppKit proof repository identity drifted'
grep -Fxq $'sources\ttracked=531\tselected=530' \
    "$APPKIT_PROOF/PROOF_COMPLETE" || die 'AppKit proof source census drifted'
typecheck_result=$(awk -F '\t' '$1 == "typecheck" { sub(/^result=/, "", $3); print $3 }' \
    "$APPKIT_PROOF/PROOF_COMPLETE")
case "$typecheck_result" in complete|advanced) ;; *) die 'typecheck result is invalid' ;; esac
library_result=skipped-not-complete
if [ "$typecheck_result" = complete ]; then
    for regular in \
        "$RESULT/revenuecat-library-proof/PROOF_COMPLETE" \
        "$RESULT/revenuecat-library-proof/lib/libRevenueCat.dylib" \
        "$RESULT/revenuecat-library-proof/modules/RevenueCat.swiftmodule" \
        "$RESULT/revenuecat-library-proof/probe/RevenueCatLibraryRuntime" \
        "$RESULT/revenuecat-library-proof/RevenueCatLibraryRuntime.log"; do
        [ -f "$regular" ] && [ ! -L "$regular" ] \
            || die "required RevenueCat library artifact is missing or linked: $regular"
    done
    grep -Fxq $'format\trevenuecat-library-product-proof-v1' \
        "$RESULT/revenuecat-library-proof/PROOF_COMPLETE" \
        || die 'RevenueCat library product proof format drifted'
    library_result=complete
else
    [ ! -e "$RESULT/revenuecat-library-proof" ] \
        || die 'RevenueCat library stage ran before the 530-source product completed'
fi
grep -Fxq $'format\trevenuecat-frontier-proof-v1' \
    "$RUNTIME_PROOF/PROOF_COMPLETE" || die 'runtime proof format drifted'
grep -Fxq $'repository\tcommit=57043e7e0173c48d64e171944ac76a34d2467fa1\ttree=72a2e1e9b6986fadca9b863d235c4a52aab38fb4' \
    "$RUNTIME_PROOF/PROOF_COMPLETE" || die 'runtime proof repository identity drifted'

{
    printf 'format\trevenuecat-appkit-host-proof-v1\n'
    printf 'support\tbase=%s\thead=%s\ttree=%s\n' \
        "$EXPECTED_SUPPORT_BASE" "$(git -C "$ROOT" rev-parse HEAD^{commit})" \
        "$(git -C "$ROOT" rev-parse HEAD^{tree})"
    printf 'package\tpath=%s\tcomplete-sha256=%s\n' \
        "$PACKAGE" "$PACKAGE_COMPLETE_SHA_BEFORE"
    printf 'repository\tcommit=%s\ttree=%s\tsources=531\tcensus-sha256=%s\n' \
        "$EXPECTED_REVENUECAT_COMMIT" "$EXPECTED_REVENUECAT_TREE" \
        "$source_census_sha"
    printf 'appkit-frontier\tresult=%s\tproof-sha256=%s\n' \
        "$typecheck_result" "$(hash_file "$APPKIT_PROOF/PROOF_COMPLETE")"
    if [ "$library_result" = complete ]; then
        printf 'library-product\tresult=complete\tproof-sha256=%s\n' \
            "$(hash_file "$RESULT/revenuecat-library-proof/PROOF_COMPLETE")"
    else
        printf 'library-product\tresult=%s\n' "$library_result"
    fi
    printf 'runtime-frontier\tconsumers=adservices,zlib,iokit\tproof-sha256=%s\n' \
        "$(hash_file "$RUNTIME_PROOF/PROOF_COMPLETE")"
    printf 'docker\tstdout-sha256=%s\tstderr-sha256=%s\n' \
        "$(hash_file "$RESULT/docker.stdout")" "$(hash_file "$RESULT/docker.stderr")"
} > "$RESULT/HOST_PROOF_COMPLETE"

[ ! -e "$OUTPUT_ROOT" ] && [ ! -L "$OUTPUT_ROOT" ] \
    || die "output appeared during replay: $OUTPUT_ROOT"
mv -- "$RESULT" "$OUTPUT_ROOT"
rmdir "$RUN_ROOT"
RUN_SUCCESS=1
trap - EXIT INT TERM
printf 'REVENUECAT_APPKIT_HOST_OK commit=%s sources=530 result=%s library=%s runtime=adservices,zlib,iokit output=%s\n' \
    "$EXPECTED_REVENUECAT_COMMIT" "$typecheck_result" "$library_result" "$OUTPUT_ROOT"
