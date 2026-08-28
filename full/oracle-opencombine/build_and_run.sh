#!/bin/bash
# Host-side durable entry point. It clones/checks out the pinned upstream tree,
# attests it, copies only disposable subjects into the existing fm-build
# container, and brings the evidence back under scratch/.
set -euo pipefail
export LC_ALL=C

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
POLICY=$HERE/policy.json
POLICY_TOOL=$HERE/policy_tool.pl
OUT=${1:-$ROOT/scratch/opencombine-core-2026-08-28}

# Output is deliberately restricted to the repository's ignored scratch tree.
# That makes the refusal auditable and prevents an accidental broad copy target.
OUT_PARENT=$(cd "$(dirname "$OUT")" 2>/dev/null && pwd -P) || {
    echo "REFUSED: output parent does not exist: $(dirname "$OUT")" >&2; exit 2; }
OUT_ABS=$OUT_PARENT/$(basename "$OUT")
case "$OUT_ABS" in
    "$ROOT"/scratch/*) ;;
    *) echo "REFUSED: output must be a new child of $ROOT/scratch: $OUT_ABS" >&2; exit 2 ;;
esac
[ ! -e "$OUT_ABS" ] || {
    echo "REFUSED: output path already exists; choose a brand-new subject: $OUT_ABS" >&2
    exit 2
}

perl "$POLICY_TOOL" assets "$POLICY" "$HERE"
eval "$(perl "$POLICY_TOOL" env "$POLICY")"

RUNTIME_ROOT=${RUNTIME_ROOT:-$ROOT/scratch/mrroot_full}
RUNTIME_ROOT=$(cd "$RUNTIME_ROOT" 2>/dev/null && pwd -P) || {
    echo "REFUSED: runtime root does not resolve to a directory: $RUNTIME_ROOT" >&2
    exit 2
}
perl "$POLICY_TOOL" runtime "$POLICY" "$RUNTIME_ROOT"

CONTAINER=${FM_BUILD_CONTAINER:-fm-build}
MACHORUN_CONTAINER=${MACHORUN_CONTAINER:?set MACHORUN_CONTAINER to the pinned loader path in fm-build}
CONCURRENCY_MODULE_CONTAINER=${CONCURRENCY_MODULE_CONTAINER:?set CONCURRENCY_MODULE_CONTAINER to the source-built module root in fm-build}
SWIFT_MODULE_CONTAINER=${SWIFT_MODULE_CONTAINER:-/work/swiftmodule}
CLONE_SOURCE=${OPENCOMBINE_CLONE_SOURCE:-$OC_REPOSITORY_URL}

safe_name=$(basename "$OUT_ABS" | tr -c 'A-Za-z0-9._-' '_')
CONTAINER_OUT=${CONTAINER_OUT:-/tmp/opencombine-core.$safe_name}
[[ "$CONTAINER_OUT" =~ ^/tmp/opencombine-core\.[A-Za-z0-9._-]+$ ]] || {
    echo "REFUSED: CONTAINER_OUT must be one safe path segment matching /tmp/opencombine-core.*" >&2
    exit 2
}

command -v git >/dev/null || { echo "REFUSED: git is unavailable" >&2; exit 2; }
command -v docker >/dev/null || { echo "REFUSED: docker is unavailable" >&2; exit 2; }
docker inspect "$CONTAINER" >/dev/null 2>&1 || {
    echo "REFUSED: container is unavailable: $CONTAINER" >&2; exit 2; }
[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER")" = true ] || {
    echo "REFUSED: container is not running: $CONTAINER" >&2; exit 2; }
CONTAINER_IMAGE_ID=$(docker inspect -f '{{.Image}}' "$CONTAINER")
[ "$CONTAINER_IMAGE_ID" = "$OC_CONTAINER_IMAGE_ID" ] || {
    echo "REFUSED: container image changed: expected $OC_CONTAINER_IMAGE_ID, got $CONTAINER_IMAGE_ID" >&2
    exit 3
}
if docker exec "$CONTAINER" test -e "$CONTAINER_OUT"; then
    echo "REFUSED: container subject already exists; choose a new CONTAINER_OUT: $CONTAINER_OUT" >&2
    exit 2
fi

mkdir "$OUT_ABS"
mkdir "$OUT_ABS/host-audit"
{
    printf 'repository URL\t%s\n' "$OC_REPOSITORY_URL"
    printf 'clone source\t%s\n' "$CLONE_SOURCE"
    printf 'pinned commit\t%s\n' "$OC_COMMIT"
    printf 'container\t%s\n' "$CONTAINER"
    printf 'container image\t%s\n' "$CONTAINER_IMAGE_ID"
    printf 'container subject\t%s\n' "$CONTAINER_OUT"
    printf 'runtime root\t%s\n' "$RUNTIME_ROOT"
    printf 'machorun input\t%s\n' "$MACHORUN_CONTAINER"
    printf 'Swift module root input\t%s\n' "$SWIFT_MODULE_CONTAINER"
    printf 'Concurrency module input\t%s\n' "$CONCURRENCY_MODULE_CONTAINER"
} > "$OUT_ABS/RUN.txt"

echo "==> clone and detach at the reviewed OpenCombine commit"
git clone --quiet --no-checkout --no-local -- "$CLONE_SOURCE" "$OUT_ABS/source"
git -C "$OUT_ABS/source" checkout --quiet --detach "$OC_COMMIT"
perl "$POLICY_TOOL" attest "$POLICY" "$OUT_ABS/source" \
    "$OUT_ABS/host-audit/core-sources.before.nul" \
    "$OUT_ABS/host-audit/core-sources.before.json" \
    | tee "$OUT_ABS/host-audit/source-before.log"

echo "==> copy exact disposable subjects into $CONTAINER:$CONTAINER_OUT"
docker exec "$CONTAINER" mkdir "$CONTAINER_OUT"
docker cp "$HERE" "$CONTAINER:$CONTAINER_OUT/tooling"
docker cp "$OUT_ABS/source" "$CONTAINER:$CONTAINER_OUT/source"
docker cp "$RUNTIME_ROOT" "$CONTAINER:$CONTAINER_OUT/base-root"

echo "==> build, strict-link, stage, audit, and run guest controls"
docker exec \
    -e MACHORUN_BIN="$MACHORUN_CONTAINER" \
    -e CONCURRENCY_MODULE_ROOT="$CONCURRENCY_MODULE_CONTAINER" \
    -e SWIFT_MODULE_ROOT="$SWIFT_MODULE_CONTAINER" \
    "$CONTAINER" bash "$CONTAINER_OUT/tooling/container_build.sh" "$CONTAINER_OUT" \
    | tee "$OUT_ABS/container-build.log"

echo "==> copy durable artifacts and evidence back to the host output"
mkdir "$OUT_ABS/export"
docker cp "$CONTAINER:$CONTAINER_OUT/export/." "$OUT_ABS/export/"
docker cp "$CONTAINER:$CONTAINER_OUT/export.manifest.nul" \
    "$OUT_ABS/host-audit/container-export.manifest.nul"
perl "$POLICY_TOOL" verify-tree "$POLICY" "$OUT_ABS/export" \
    "$OUT_ABS/host-audit/container-export.manifest.nul" \
    | tee "$OUT_ABS/host-audit/export-copy.log"

perl "$POLICY_TOOL" attest "$POLICY" "$OUT_ABS/source" \
    "$OUT_ABS/host-audit/core-sources.after.nul" \
    "$OUT_ABS/host-audit/core-sources.after.json" \
    | tee "$OUT_ABS/host-audit/source-after.log"
cmp -s "$OUT_ABS/host-audit/core-sources.before.nul" \
       "$OUT_ABS/host-audit/core-sources.after.nul" || {
    echo "REFUSED: host source list changed across the container build" >&2; exit 4; }
cmp -s "$OUT_ABS/host-audit/core-sources.before.json" \
       "$OUT_ABS/host-audit/core-sources.after.json" || {
    echo "REFUSED: host source attestation changed across the container build" >&2; exit 4; }

echo "PASS: durable OpenCombine evidence is at $OUT_ABS"
echo "      disposable container subject remains at $CONTAINER_OUT for inspection"
