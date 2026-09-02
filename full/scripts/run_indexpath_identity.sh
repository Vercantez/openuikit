#!/bin/bash
# Run the literal-UIKit IndexPath identity executable produced by the real full
# build. The source probe imports only UIKit; this runner proves the linked
# Linux-built arm64 Mach-O reaches FoundationEssentials under machorun.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
UIKIT=${UIKIT:-"$ROOT/uikit"}
MRROOT=/w/scratch/mrroot_full
PROBE=$ROOT/build/full/indexpath_identity_probe
SUBJECT_FILE=$ROOT/build/full/uihelpers-subject.sha256
ARTIFACT_FILE=$ROOT/build/full/uihelpers-artifacts.sha256

if [ "$(uname -m)" != aarch64 ] && [ "$(uname -m)" != arm64 ]; then
    bash "$ROOT/.cursor/refuse-arm64-execution.sh" || exit $?
fi

hash_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

fingerprint() {
    {
        printf 'recorded-subject\t%s\n' "$(hash_file "$SUBJECT_FILE")"
        printf 'current-subject\t%s\n' \
            "$(bash "$ROOT/full/scripts/uihelpers_subject.sh" "$ROOT" "$UIKIT")"
        printf 'probe\t%s\n' "$(hash_file "$PROBE")"
        printf 'foundation-essentials-object\t%s\n' \
            "$(hash_file "$ROOT/build/full/foundation/essentials/FoundationEssentials.o")"
        printf 'artifacts\t%s\n' "$(hash_file "$ARTIFACT_FILE")"
        find "$ROOT/scratch/mrroot_full" -type f | LC_ALL=C sort | \
            while IFS= read -r file; do
                printf '%s\t%s\n' "${file#"$ROOT"/}" "$(hash_file "$file")"
            done
    } | if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    else
        shasum -a 256 | awk '{print $1}'
    fi
}

[ -x "$PROBE" ] || { echo "run_indexpath_identity: no $PROBE; rebuild first" >&2; exit 2; }
[ -f "$SUBJECT_FILE" ] && [ -f "$ARTIFACT_FILE" ] || {
    echo "run_indexpath_identity: incomplete build attestation; rebuild first" >&2
    exit 2
}
[ -f "$ROOT/build/full/foundation/essentials/FoundationEssentials.o" ] || {
    echo "run_indexpath_identity: FoundationEssentials object is absent; rebuild first" >&2
    exit 2
}
file "$PROBE" | grep -q 'Mach-O 64-bit executable arm64' || {
    echo "run_indexpath_identity: probe is not an arm64 Mach-O executable" >&2
    exit 2
}

"$ROOT/scripts/require_fresh_root.sh" "$ROOT/scratch/mrroot_full"
recorded_subject=$(tr -d '[:space:]' < "$SUBJECT_FILE")
current_subject=$(bash "$ROOT/full/scripts/uihelpers_subject.sh" "$ROOT" "$UIKIT")
[ "$recorded_subject" = "$current_subject" ] || {
    echo "run_indexpath_identity: source subject is stale; rebuild first" >&2
    exit 2
}
expected_probe=$(awk '$1 == "indexpath_identity_probe" {print $2}' "$ARTIFACT_FILE")
expected_fe=$(awk '$1 == "FoundationEssentials.o" {print $2}' "$ARTIFACT_FILE")
[ "$(wc -l < "$ARTIFACT_FILE" | tr -d '[:space:]')" = 6 ] || {
    echo "run_indexpath_identity: malformed artifact manifest" >&2
    exit 2
}
[ -n "$expected_probe" ] && [ "$expected_probe" = "$(hash_file "$PROBE")" ] || {
    echo "run_indexpath_identity: probe bytes drifted; rebuild first" >&2
    exit 2
}
[ -n "$expected_fe" ] && \
    [ "$expected_fe" = "$(hash_file "$ROOT/build/full/foundation/essentials/FoundationEssentials.o")" ] || {
    echo "run_indexpath_identity: FoundationEssentials object drifted; rebuild first" >&2
    exit 2
}

before=$(fingerprint)
set +e
output=$(docker run --rm \
    --platform linux/arm64 \
    -v "$ROOT:/w" -v "$UIKIT:/uikit:ro" -w /w/build/full \
    -e MACHORUN_ROOT="$MRROOT" \
    swift-macho-spike:noble \
    "$MRROOT/machorun" ./indexpath_identity_probe 2>&1)
status=$?
set -e
printf '%s\n' "$output"
after=$(fingerprint)
[ "$before" = "$after" ] || {
    echo "run_indexpath_identity: RUN VOID -- binary or guest root changed during execution" >&2
    exit 2
}
[ "$status" -eq 0 ] || exit "$status"
printf '%s\n' "$output" | grep -qx 'LITERAL_UIKIT_INDEXPATH_OK' || {
    echo "run_indexpath_identity: success marker missing" >&2
    exit 1
}
