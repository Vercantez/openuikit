#!/bin/bash
# Run the fixture corpus under machorun on Linux/arm64, inside Docker.
#
#   harness/run_linux.sh                 run everything
#   harness/run_linux.sh printf       run one fixture
#   harness/run_linux.sh --build-image   force a rebuild of the test-bed image
#
# Results land in tests/actual/linux/. This script NEVER writes to
# tests/expected/ -- baselines are the oracle's alone, and the container gets
# tests/expected mounted read-only so the rule is enforced by the kernel and
# not merely by good intentions.
#
# It is expected to report SKIPPED while the loader does not exist yet. That
# is the honest answer, not a failure.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/harness/common.sh"

IMAGE="${MACHORUN_IMAGE:-machorun-testbed:24.04}"
# Exact, unique container name. Never `docker rm` by filter or by image --
# this host runs unrelated containers.
CNAME="machorun-test-$$"

OUT_DIR="$ACTUAL_DIR/linux"
STATUS_FILE="$OUT_DIR/.status"

FORCE_BUILD=0
ONLY=()
for a in "$@"; do
    case "$a" in
        --build-image) FORCE_BUILD=1 ;;
        --record|--verify)
            die "run_linux.sh does not record anything. Baselines come from harness/run_macos.sh on macOS only." ;;
        -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
        -*) die "unknown option $a" ;;
        *) ONLY+=("$a") ;;
    esac
done

selected() {
    [ ${#ONLY[@]} -eq 0 ] && return 0
    local w
    for w in "${ONLY[@]}"; do [ "$w" = "$1" ] && return 0; done
    return 1
}

mkdir -p "$OUT_DIR"
: > "$STATUS_FILE"

# skip_all <reason>: record a machine-readable reason so difftest.sh can print
# it once instead of repeating it on every row.
skip_all() {
    printf 'skipped\t%s\n' "$1" > "$STATUS_FILE"
    printf '%sSKIPPED%s  %s\n' "$C_YEL" "$C_RESET" "$1"
    exit 0
}

# ------------------------------------------------------- preconditions
command -v docker >/dev/null 2>&1 || skip_all "docker not installed on this host"
docker info >/dev/null 2>&1        || skip_all "docker daemon not reachable"

# The loader. Its build is owned by another agent; we look for it, we do not
# build it ourselves beyond invoking the project's own build entry point.
LOADER_REL="${MACHORUN_LOADER:-build/machorun}"
BUILD_SCRIPT="scripts/build_linux.sh"

if [ ! -f "$ROOT/$BUILD_SCRIPT" ] && [ ! -x "$ROOT/$LOADER_REL" ]; then
    skip_all "no loader yet: neither $BUILD_SCRIPT nor $LOADER_REL exists (src/ is still empty)"
fi

# ------------------------------------------------------- test-bed image
if [ "$FORCE_BUILD" = 1 ] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    printf '%sbuilding %s (first run only, a few minutes)%s\n' "$C_DIM" "$IMAGE" "$C_RESET"
    if ! docker build --platform linux/arm64 -t "$IMAGE" -f "$ROOT/harness/Dockerfile" "$ROOT/harness"; then
        skip_all "could not build test-bed image $IMAGE"
    fi
fi

# ------------------------------------------------------- run in container
# One container for the whole corpus: container startup dwarfs fixture runtime.
# The work is scripted into the container over stdin.
printf '%srunning fixtures under machorun (linux/arm64, %s)%s\n' "$C_BLD" "$IMAGE" "$C_RESET"
printf '%s\n' "----------------------------------------------------------------------"

IDS=()
while IFS= read -r row; do
    id="$(field "$row" 1)"
    selected "$id" && IDS+=("$id")
done < <(manifest_rows)

[ ${#IDS[@]} -gt 0 ] || die "no fixtures selected"

CONTAINER_SCRIPT="$(cat <<'INNER'
set -u
cd /work

# Build the loader if the project provides an entry point for it.
if [ -f scripts/build_linux.sh ]; then
    if ! sh scripts/build_linux.sh > /work/tests/actual/linux/.build.log 2>&1; then
        echo "BUILD-FAILED"
        exit 0
    fi
fi

LOADER="${MACHORUN_LOADER:-build/machorun}"
if [ ! -x "$LOADER" ]; then
    echo "NO-LOADER"
    exit 0
fi
LOADER="$(cd "$(dirname "$LOADER")" && pwd)/$(basename "$LOADER")"

cd /work/tests/bin
export LC_ALL=C LANG=C TZ=UTC
OUT=/work/tests/actual/linux
for id in $FIXTURE_IDS; do
    [ -f "$id" ] || { echo "127" > "$OUT/$id.exit"; : > "$OUT/$id.stdout"; echo "no such fixture" > "$OUT/$id.stderr"; continue; }
    rc=0
    timeout -k 2 20 "$LOADER" "./$id" > "$OUT/$id.stdout" 2> "$OUT/$id.stderr" || rc=$?
    echo "$rc" > "$OUT/$id.exit"
done
echo "RAN"
INNER
)"

set +e
# -i is required: the work script is fed to `bash -s` on the container's stdin.
result="$(docker run --rm -i --name "$CNAME" --platform linux/arm64 \
    -v "$ROOT:/work" \
    -v "$ROOT/tests/expected:/work/tests/expected:ro" \
    -e "FIXTURE_IDS=${IDS[*]}" \
    -e "MACHORUN_LOADER=$LOADER_REL" \
    -w /work "$IMAGE" bash -s <<<"$CONTAINER_SCRIPT" 2>&1)"
rc=$?
set -e

tail_marker="$(printf '%s\n' "$result" | tail -1)"

case "$tail_marker" in
    NO-LOADER)
        skip_all "loader binary $LOADER_REL was not produced by the build" ;;
    BUILD-FAILED)
        printf 'build\tscripts/build_linux.sh failed; see tests/actual/linux/.build.log\n' > "$STATUS_FILE"
        printf '%sBUILD FAILED%s -- see tests/actual/linux/.build.log\n' "$C_RED" "$C_RESET"
        printf '%s\n' "$result" | tail -20
        exit 1 ;;
    RAN)
        printf 'ran\t\n' > "$STATUS_FILE" ;;
    *)
        skip_all "container run failed (rc=$rc): $(printf '%s' "$result" | tail -3 | tr '\n' ' ')" ;;
esac

for id in "${IDS[@]}"; do
    if [ -f "$OUT_DIR/$id.exit" ]; then
        printf '  %-24s exit=%s\n' "$id" "$(cat "$OUT_DIR/$id.exit")"
    else
        printf '  %-24s %sno result%s\n' "$id" "$C_RED" "$C_RESET"
    fi
done
printf '%s\n' "----------------------------------------------------------------------"
echo "results in tests/actual/linux/ -- grade them with scripts/difftest.sh"
