#!/usr/bin/env bash
# Cursor Build install: evidence + corpus + x86 products (including fixtures
# and PHASE2_RUNGS=a) + verify. Timed per step so a Build log shows wall
# time; warn if any single step exceeds ~45 minutes.
#
# Idempotent. Snapshotted once per Build. start.sh must not rebuild this.

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
case "$repo_root" in
    ''|/) printf 'cursor-install: unsafe repository root\n' >&2; exit 1 ;;
esac
cd "$repo_root"

WARN_S=2700
install_start_s=$(date +%s)
over_45=0

run_step() {
    local name=$1
    shift
    local start_s elapsed
    start_s=$(date +%s)
    printf 'CURSOR_INSTALL_STEP_BEGIN name=%s\n' "$name"
    "$@"
    elapsed=$(( $(date +%s) - start_s ))
    printf 'CURSOR_INSTALL_STEP name=%s elapsed_s=%s\n' "$name" "$elapsed"
    if [ "$elapsed" -gt "$WARN_S" ]; then
        over_45=1
        printf 'CURSOR_INSTALL_STEP_OVER_45MIN name=%s elapsed_s=%s warn_s=%s\n' \
            "$name" "$elapsed" "$WARN_S"
    fi
}

run_step evidence bash "$repo_root/.cursor/install-static-evidence.sh"
run_step corpus bash "$repo_root/.cursor/install-scratch-corpus.sh"
run_step products bash "$repo_root/.cursor/install-built-products.sh"
run_step verify bash "$repo_root/.cursor/verify-cloud-environment.sh"

total_s=$(( $(date +%s) - install_start_s ))
printf 'CURSOR_INSTALL_TIMING total_s=%s over_45min=%s\n' "$total_s" "$over_45"
if [ "$over_45" -eq 1 ]; then
    printf 'cursor-install: one or more steps exceeded ~45 minutes (see CURSOR_INSTALL_STEP_OVER_45MIN)\n' >&2
fi
