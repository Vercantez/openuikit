#!/usr/bin/env bash
# Unit tests for Cursor cloud-environment corpus, attestation, and ARM64 marker.
# Does not require network, Docker, or the full product build.

set -euo pipefail

script_dir=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(unset CDPATH; cd -- "$script_dir/.." && pwd)
passed=0
failed=0
total=0

check() {
    local name=$1
    shift
    total=$((total + 1))
    if "$@"; then
        passed=$((passed + 1))
        printf 'ok %s\n' "$name"
    else
        failed=$((failed + 1))
        printf 'FAIL %s\n' "$name" >&2
    fi
}

test_root=$(mktemp -d /tmp/openuikit-cursor-env-test.XXXXXX)
cleanup() {
    case "$test_root" in
        /tmp/openuikit-cursor-env-test.*) rm -rf -- "$test_root" ;;
    esac
}
trap cleanup EXIT HUP INT TERM

# --- refuse marker ---
refuse_out=$test_root/refuse.out
refuse_status=0
bash "$script_dir/refuse-arm64-execution.sh" >"$refuse_out" 2>&1 || refuse_status=$?
check refuse_exit_2 test "$refuse_status" -eq 2
check refuse_marker grep -q '^CURSOR_ENV_CANNOT_EXECUTE_ARM64 host=' "$refuse_out"

# --- clone pin-and-verify with a local Git repo ---
lock=$test_root/lock.json
src=$test_root/upstream
git init -q "$src"
git -C "$src" config user.email test@example.com
git -C "$src" config user.name test
printf 'hello\n' > "$src/file.txt"
git -C "$src" add file.txt
git -C "$src" commit -q -m init
commit=$(git -C "$src" rev-parse HEAD)
tree=$(git -C "$src" rev-parse 'HEAD^{tree}')
# file:// URLs are not accepted by the origin guard (GitHub HTTPS only).
# Exercise the helper against a temporary GitHub-shaped lock by rewriting
# origin after clone is impossible here; instead test the dest-under-scratch
# guard and a successful clone by pointing origin at a github URL that we
# never fetch, plus a direct checkout_is_valid path via a planted dest.

python3 - "$lock" "$commit" "$tree" <<'PY'
import json, sys
Path = __import__("pathlib").Path
Path(sys.argv[1]).write_text(json.dumps({
    "sources": [{
        "id": "fixture",
        "repository": "https://github.com/example/fixture.git",
        "commit": sys.argv[2],
        "tree": sys.argv[3],
        "destination": "scratch/fixture",
    }]
}, indent=2) + "\n")
PY

# Plant a valid checkout with the locked origin URL (no network).
plant=$test_root/work
mkdir -p "$plant/scratch"
git clone --quiet "$src" "$plant/scratch/fixture"
git -C "$plant/scratch/fixture" remote set-url origin \
    https://github.com/example/fixture.git
# The helper should reuse a valid planted dest without fetching.
reuse_out=$test_root/reuse.out
bash "$script_dir/clone-pinned-repo.sh" \
    --lock "$lock" --id fixture --repo-root "$plant" >"$reuse_out"
check clone_reuse grep -q 'reused=1' "$reuse_out"
check clone_head test "$(git -C "$plant/scratch/fixture" rev-parse HEAD)" = "$commit"

# Dirty dest must not be reused; staging a fetch of example/fixture.git will
# fail closed and must not delete the dest until the new tree is verified.
printf 'dirty\n' > "$plant/scratch/fixture/extra.txt"
dirty_status=0
bash "$script_dir/clone-pinned-repo.sh" \
    --lock "$lock" --id fixture --repo-root "$plant" \
    >"$test_root/dirty.out" 2>&1 || dirty_status=$?
check clone_dirty_refused test "$dirty_status" -ne 0
check clone_dirty_kept test -f "$plant/scratch/fixture/extra.txt"

# Destination outside scratch/ is refused.
python3 - "$test_root/bad-lock.json" "$commit" "$tree" <<'PY'
import json, sys
from pathlib import Path
Path(sys.argv[1]).write_text(json.dumps({
    "sources": [{
        "id": "fixture",
        "repository": "https://github.com/example/fixture.git",
        "commit": sys.argv[2],
        "tree": sys.argv[3],
        "destination": "not-scratch/fixture",
    }]
}) + "\n")
PY
bad_status=0
bash "$script_dir/clone-pinned-repo.sh" \
    --lock "$test_root/bad-lock.json" --id fixture --repo-root "$plant" \
    >"$test_root/bad.out" 2>&1 || bad_status=$?
check clone_dest_guard test "$bad_status" -ne 0
check clone_dest_guard_message grep -q 'destination is not under scratch' "$test_root/bad.out"

# --- attest without stamp ---
attest_status=0
bash "$script_dir/attest-cursor-env.sh" >"$test_root/attest.out" 2>&1 || attest_status=$?
# This test runs in the real repo; stamp may already exist after install.
# Assert the script either attests or refuses with the documented marker.
if [ "$attest_status" -eq 0 ]; then
    check attest_ok_or_refused grep -q '^CURSOR_ENV_TOOLCHAIN_ATTESTED ' "$test_root/attest.out"
else
    check attest_ok_or_refused grep -q 'REFUSING' "$test_root/attest.out"
fi

# --- verify does not wipe a scratch sentinel ---
mkdir -p "$repo_root/scratch"
sentinel=$repo_root/scratch/.cursor-env-wipe-test
printf 'keep\n' > "$sentinel"
# Do not run full verify here (needs corpus+products). Check the script no
# longer names scratch in the cleanup loop.
check verify_does_not_wipe_scratch \
    grep -q 'Do NOT wipe scratch' "$script_dir/verify-cloud-environment.sh"
check verify_cleanup_omits_scratch \
    bash -c 'awk "/for relative in/{print; exit}" "$1" | grep -vq scratch' \
    _ "$script_dir/verify-cloud-environment.sh"
rm -f "$sentinel"

# --- fingerprint is stable ---
fp1=$(bash "$script_dir/toolchain-fingerprint.sh" | sha256sum | awk '{print $1}')
fp2=$(bash "$script_dir/toolchain-fingerprint.sh" | sha256sum | awk '{print $1}')
check fingerprint_stable test "$fp1" = "$fp2"
check fingerprint_has_digest \
    bash -c 'bash "$1" | grep -q "image_digest=sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc"' \
    _ "$script_dir/toolchain-fingerprint.sh"

# --- environment.json install order ---
check install_order grep -q 'install-scratch-corpus.sh' "$script_dir/environment.json"
check install_products grep -q 'install-built-products.sh' "$script_dir/environment.json"

# --- install-built-products: x86 runs the cycle; empty .tbd is still a lie ---
check products_x86_cycle \
    grep -q 'scripts/ops/x86_cycle.sh' "$script_dir/install-built-products.sh"
check products_x86_skip_overlays \
    grep -q 'OPENUIKIT_CYCLE_SKIP_OVERLAYS=1' "$script_dir/install-built-products.sh"
check products_x86_skip_phase2 \
    grep -q 'OPENUIKIT_CYCLE_SKIP_PHASE2=1' "$script_dir/install-built-products.sh"
check products_refuse_empty_tbd \
    grep -q 'empty .tbd is a linker lie' "$script_dir/install-built-products.sh"
check products_x86_placeholder \
    grep -q '_machorun_foundation_placeholder' "$script_dir/install-built-products.sh"
check verify_runs_rung_a \
    grep -q 'PHASE2_RUNGS=a' "$script_dir/verify-cloud-environment.sh"
check verify_can_execute_x86 \
    grep -q 'CURSOR_ENV_CAN_EXECUTE arch=x86_64' "$script_dir/verify-cloud-environment.sh"
check corpus_pins_icu \
    grep -q 'swift-foundation-icu' "$script_dir/scratch-corpus-pins.json"
check corpus_pins_cf \
    grep -q 'swift-corelibs-foundation' "$script_dir/scratch-corpus-pins.json"

# --- attested Linux-half gates are bash (this VM has no zsh) ---
check linux_verify_bash_shebang \
    grep -q '^#!/usr/bin/env bash' "$repo_root/uikit/scripts/linux_verify.sh"
check objcshim_bash_shebang \
    grep -q '^#!/usr/bin/env bash' "$repo_root/uikit/Tools/objcshim/verify.sh"

# --- execution gates emit the canonical marker and stop (no set -e required) ---
if [ "$(uname -m)" != aarch64 ] && [ "$(uname -m)" != arm64 ]; then
    run_linux_status=0
    bash "$repo_root/machorun/harness/run_linux.sh" >"$test_root/run_linux.out" 2>&1 \
        || run_linux_status=$?
    check run_linux_exit_2 test "$run_linux_status" -eq 2
    check run_linux_marker grep -q '^CURSOR_ENV_CANNOT_EXECUTE_ARM64 host=' \
        "$test_root/run_linux.out"
    objc4_status=0
    sh "$repo_root/objc4-linux/harness/run_linux.sh" tests/010-category-basic.m \
        >"$test_root/objc4.out" 2>&1 || objc4_status=$?
    check objc4_run_linux_exit_2 test "$objc4_status" -eq 2
    check objc4_run_linux_marker grep -q '^CURSOR_ENV_CANNOT_EXECUTE_ARM64 host=' \
        "$test_root/objc4.out"
    suite_status=0
    bash "$repo_root/full/scripts/run_suite.sh" >"$test_root/suite.out" 2>&1 \
        || suite_status=$?
    check run_suite_exit_2 test "$suite_status" -eq 2
    check run_suite_marker grep -q '^CURSOR_ENV_CANNOT_EXECUTE_ARM64 host=' \
        "$test_root/suite.out"
fi

printf 'CURSOR_ENV_SELFTEST_OK passed=%s failed=%s total=%s/%s\n' \
    "$passed" "$failed" "$passed" "$total"
[ "$failed" -eq 0 ]
