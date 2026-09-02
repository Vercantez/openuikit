#!/bin/bash
# Run the focused OpenUIKit compatibility surfaces used by focus-ios UIHelpers
# as an arm64 Mach-O guest. This is intentionally a checked-in invocation: the
# renderer needs OpenUIKit's data files at run time, and omitting that mount can
# make text metrics silently fall back before a layout assertion fails.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
UIKIT=${UIKIT:-"$ROOT/uikit"}
MRROOT=/w/scratch/mrroot_full
RENDERER=$ROOT/build/full/render_full
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

hash_stream() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    else
        shasum -a 256 | awk '{print $1}'
    fi
}

guest_fingerprint() {
    {
        printf 'render_full\t%s\n' "$(hash_file "$RENDERER")"
        find "$ROOT/scratch/mrroot_full" -type f \
            \( -name machorun -o -name '*.dylib' \) | LC_ALL=C sort | \
            while IFS= read -r file; do
                rel=${file#"$ROOT"/}
                printf '%s\t%s\n' "$rel" "$(hash_file "$file")"
            done
    } | hash_stream
}

[ -x "$RENDERER" ] || {
    echo "run_uihelpers: no built renderer at $RENDERER; run full/scripts/build_full.sh first" >&2
    exit 2
}
[ -x "$ROOT/build/full/indexpath_identity_probe" ] || {
    echo "run_uihelpers: no built literal-UIKit identity probe; rebuild first" >&2
    exit 2
}
[ -f "$ROOT/build/full/foundation/essentials/FoundationEssentials.o" ] || {
    echo "run_uihelpers: no built FoundationEssentials object; rebuild first" >&2
    exit 2
}
[ -f "$UIKIT/Sources/OpenUIKit/Resources/font_metrics.json" ] || {
    echo "run_uihelpers: UIKIT=$UIKIT has no OpenUIKit resource tree" >&2
    exit 2
}
[ -f "$SUBJECT_FILE" ] || {
    echo "run_uihelpers: no recorded source digest at $SUBJECT_FILE; rebuild first" >&2
    exit 2
}
[ -f "$ARTIFACT_FILE" ] || {
    echo "run_uihelpers: no artifact digest at $ARTIFACT_FILE; rebuild first" >&2
    exit 2
}

# A green result against yesterday's loader or yesterday's test binary is not
# evidence. The root checker validates the staged/derived manifest against the
# current machorun checkout. The content digest makes any source or resource
# drift fail closed until build_full.sh has relinked the renderer.
"$ROOT/scripts/require_fresh_root.sh" "$ROOT/scratch/mrroot_full"
recorded_subject=$(tr -d '[:space:]' < "$SUBJECT_FILE")
current_subject=$(bash "$ROOT/full/scripts/uihelpers_subject.sh" "$ROOT" "$UIKIT")
if [ "$recorded_subject" != "$current_subject" ]; then
    echo "run_uihelpers: renderer subject is stale; rebuild first" >&2
    echo "  built:   $recorded_subject" >&2
    echo "  current: $current_subject" >&2
    exit 2
fi
artifact_lines=$(wc -l < "$ARTIFACT_FILE" | tr -d '[:space:]')
expected_renderer=$(awk '$1 == "render_full" {print $2}' "$ARTIFACT_FILE")
expected_indexpath=$(awk '$1 == "indexpath_identity_probe" {print $2}' "$ARTIFACT_FILE")
expected_fe=$(awk '$1 == "FoundationEssentials.o" {print $2}' "$ARTIFACT_FILE")
expected_quartz=$(awk '$1 == "libquartz.dylib" {print $2}' "$ARTIFACT_FILE")
expected_system=$(awk '$1 == "libSystem.B.dylib" {print $2}' "$ARTIFACT_FILE")
expected_cxx=$(awk '$1 == "libc++.1.dylib" {print $2}' "$ARTIFACT_FILE")
if [ "$artifact_lines" != 6 ] || [ -z "$expected_renderer" ] || \
   [ -z "$expected_indexpath" ] || [ -z "$expected_fe" ] || \
   [ -z "$expected_quartz" ] || [ -z "$expected_system" ] || \
   [ -z "$expected_cxx" ]; then
    echo "run_uihelpers: malformed artifact digest at $ARTIFACT_FILE" >&2
    exit 2
fi
current_renderer=$(hash_file "$RENDERER")
current_indexpath=$(hash_file "$ROOT/build/full/indexpath_identity_probe")
current_fe=$(hash_file "$ROOT/build/full/foundation/essentials/FoundationEssentials.o")
current_quartz=$(hash_file "$ROOT/scratch/mrroot_full/darwin/usr/lib/libquartz.dylib")
current_system=$(hash_file "$ROOT/scratch/mrroot_full/darwin/usr/lib/libSystem.B.dylib")
current_cxx=$(hash_file "$ROOT/scratch/mrroot_full/darwin/usr/lib/libc++.1.dylib")
if [ "$expected_renderer" != "$current_renderer" ] || \
   [ "$expected_indexpath" != "$current_indexpath" ] || \
   [ "$expected_fe" != "$current_fe" ] || \
   [ "$expected_quartz" != "$current_quartz" ] || \
   [ "$expected_system" != "$current_system" ] || \
   [ "$expected_cxx" != "$current_cxx" ]; then
    echo "run_uihelpers: built guest artifacts drifted; rebuild first" >&2
    exit 2
fi

# Bracket the actual execution subject. A source edit or another build after
# the preflight checks must void this result, even if all 13 guest assertions
# happened to print PASS against a half-swapped root.
artifact_marker_before=$(hash_file "$ARTIFACT_FILE")
root_before=$(guest_fingerprint)

set +e
docker run --rm \
    -v "$ROOT:/w" \
    -v "$UIKIT:/uikit:ro" \
    -w /w/build/full \
    -e MACHORUN_ROOT="$MRROOT" \
    -e OPENUIKIT_RESOURCE_ROOT=/uikit/Sources/OpenUIKit/Resources \
    swift-macho-spike:noble \
    "$MRROOT/machorun" ./render_full uihelpers
guest_status=$?
set -e

for required in "$SUBJECT_FILE" "$ARTIFACT_FILE" "$RENDERER" \
                "$ROOT/scratch/mrroot_full/machorun" \
                "$ROOT/scratch/mrroot_full/darwin/usr/lib/libquartz.dylib"; do
    [ -f "$required" ] || {
        echo "run_uihelpers: RUN VOID -- execution subject disappeared: $required" >&2
        exit 2
    }
done
subject_after=$(tr -d '[:space:]' < "$SUBJECT_FILE")
artifact_marker_after=$(hash_file "$ARTIFACT_FILE")
set +e
current_subject_after=$(bash "$ROOT/full/scripts/uihelpers_subject.sh" "$ROOT" "$UIKIT")
subject_check_status=$?
root_after=$(guest_fingerprint)
root_check_status=$?
set -e
if [ "$subject_check_status" -ne 0 ] || [ "$root_check_status" -ne 0 ] || \
   [ "$recorded_subject" != "$subject_after" ] || \
   [ "$recorded_subject" != "$current_subject_after" ] || \
   [ "$artifact_marker_before" != "$artifact_marker_after" ] || \
   [ "$root_before" != "$root_after" ]; then
    echo "run_uihelpers: RUN VOID -- sources, artifacts, or guest root changed during execution" >&2
    echo "  root before: $root_before" >&2
    echo "  root after:  $root_after" >&2
    exit 2
fi

exit "$guest_status"
