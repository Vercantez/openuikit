#!/usr/bin/env bash
# Prove that the expensive WMO product stage cannot run from an incomplete,
# drifted, or stale 530-source frontier result. These mutations stop before any
# compiler or Docker invocation.

set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd -P)
DRIVER=$ROOT/full/appkit/tests/test_revenuecat_library_product_guest.sh
SCRATCH=$(mktemp -d /private/tmp/revenuecat-library-gate-mutations.XXXXXX)
PACKAGE=$SCRATCH/package
FRONTIER=$SCRATCH/revenuecat-appkit-frontier
OUTPUT=$SCRATCH/revenuecat-library-proof

cleanup() {
    if [ -e "$SCRATCH" ]; then
        if [ -x /usr/bin/trash ]; then
            /usr/bin/trash "$SCRATCH"
        else
            find "$SCRATCH" -depth -delete
        fi
    fi
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$PACKAGE" "$FRONTIER"
: > "$PACKAGE/PACKAGE_COMPLETE"

write_proof() {
    local status_value=$1 result=$2 repository_row=$3 sources_row=$4
    printf 'status=%s\n' "$status_value" > "$FRONTIER/status.txt"
    {
        printf 'format\trevenuecat-appkit-frontier-proof-v1\n'
        printf '%s\n' "$repository_row"
        printf '%s\n' "$sources_row"
        printf 'typecheck\tstatus=%s\tresult=%s\tstderr-sha256=%064d\n' \
            "$status_value" "$result" 0
    } > "$FRONTIER/PROOF_COMPLETE"
}

run_refusal() {
    local mutation=$1 expected=$2 status
    set +e
    "$DRIVER" "$PACKAGE" /does/not/matter "$FRONTIER" "$OUTPUT" \
        > "$SCRATCH/$mutation.stdout" 2> "$SCRATCH/$mutation.stderr"
    status=$?
    set -e
    [ "$status" -eq 2 ] || {
        printf 'mutation %s exit %s, expected 2\n' "$mutation" "$status" >&2
        exit 1
    }
    grep -Fq "$expected" "$SCRATCH/$mutation.stderr" || {
        printf 'mutation %s did not report %s\n' "$mutation" "$expected" >&2
        exit 1
    }
    [ ! -e "$OUTPUT" ] || {
        printf 'mutation %s created output\n' "$mutation" >&2
        exit 1
    }
}

repository=$'repository\tcommit=57043e7e0173c48d64e171944ac76a34d2467fa1\ttree=72a2e1e9b6986fadca9b863d235c4a52aab38fb4'
sources=$'sources\ttracked=531\tselected=530'
write_proof 1 advanced "$repository" "$sources"
run_refusal incomplete-status '530-source frontier did not complete successfully'

write_proof 0 advanced "$repository" "$sources"
run_refusal incomplete-result '530-source frontier completion record is not complete'

write_proof 0 complete $'repository\tcommit=wrong\ttree=wrong' "$sources"
run_refusal repository-drift '530-source frontier repository identity drifted'

write_proof 0 complete "$repository" $'sources\ttracked=531\tselected=529'
run_refusal source-drift '530-source frontier source census drifted'

printf 'REVENUECAT_LIBRARY_GATE_MUTATIONS_OK mutations=4 compiler-invocations=0\n'
