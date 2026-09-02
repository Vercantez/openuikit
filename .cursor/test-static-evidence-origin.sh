#!/usr/bin/env bash

set -euo pipefail

script_dir=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
origin_guard=$script_dir/validate-static-evidence-origin.sh
if [ ! -f "$origin_guard" ] || [ -L "$origin_guard" ]; then
    printf 'cursor-evidence-origin-test: origin guard is missing or unsafe\n' >&2
    exit 1
fi

test_root=$(mktemp -d /tmp/openuikit-evidence-origin-test.XXXXXX)
cleanup_test_root() {
    case "$test_root" in
        /tmp/openuikit-evidence-origin-test.*) rm -rf -- "$test_root" ;;
        *) printf 'cursor-evidence-origin-test: refusing unsafe cleanup\n' >&2; return 1 ;;
    esac
}
trap cleanup_test_root EXIT HUP INT TERM

mkdir -p "$test_root/home" "$test_root/xdg" "$test_root/repository"
clean_env=(
    env -i
    "PATH=$PATH"
    "HOME=$test_root/home"
    "XDG_CONFIG_HOME=$test_root/xdg"
    GIT_CONFIG_NOSYSTEM=1
)
expected_repository=https://github.com/dotnet/macios.git
rewritten_repository=https://x-access-token:cursor-test@github.com/dotnet/macios.git

"${clean_env[@]}" git init -q "$test_root/repository"
"${clean_env[@]}" git -C "$test_root/repository" remote add origin \
    "$expected_repository"
"${clean_env[@]}" git config --global \
    'url.https://x-access-token:cursor-test@github.com/.insteadOf' \
    https://github.com/

# This is the Cursor failure mode: transport resolution is rewritten, while
# the repository-local lock remains the exact pinned public HTTPS URL.
resolved_origin=$("${clean_env[@]}" git -C "$test_root/repository" \
    remote get-url origin)
[ "$resolved_origin" = "$rewritten_repository" ] \
    || { printf 'cursor-evidence-origin-test: rewrite simulation did not activate\n' >&2; exit 1; }
"${clean_env[@]}" bash "$origin_guard" "$test_root/repository" \
    "$expected_repository"

# A real local change must still fail even when a global rewrite is active.
"${clean_env[@]}" git -C "$test_root/repository" config --local \
    remote.origin.url https://github.com/attacker/macios.git
if "${clean_env[@]}" bash "$origin_guard" "$test_root/repository" \
    "$expected_repository" >/dev/null 2>&1; then
    printf 'cursor-evidence-origin-test: changed local origin was accepted\n' >&2
    exit 1
fi

# Missing local state cannot be supplied by global or command-environment
# config, nor by an include.path outside the checkout's own config file.
"${clean_env[@]}" git -C "$test_root/repository" config --local \
    --unset-all remote.origin.url
"${clean_env[@]}" git config --global remote.origin.url "$expected_repository"
if "${clean_env[@]}" env \
    GIT_CONFIG_COUNT=1 \
    GIT_CONFIG_KEY_0=remote.origin.url \
    "GIT_CONFIG_VALUE_0=$expected_repository" \
    bash "$origin_guard" "$test_root/repository" \
    "$expected_repository" >/dev/null 2>&1; then
    printf 'cursor-evidence-origin-test: injected origin was accepted\n' >&2
    exit 1
fi

injected_config=$test_root/injected.config
printf '[remote "origin"]\n\turl = %s\n' "$expected_repository" > "$injected_config"
"${clean_env[@]}" git -C "$test_root/repository" config --local \
    include.path "$injected_config"
if "${clean_env[@]}" bash "$origin_guard" "$test_root/repository" \
    "$expected_repository" >/dev/null 2>&1; then
    printf 'cursor-evidence-origin-test: included origin was accepted\n' >&2
    exit 1
fi
"${clean_env[@]}" git -C "$test_root/repository" config --local \
    --unset-all include.path

# Duplicate values are ambiguous even when every value happens to match.
"${clean_env[@]}" git -C "$test_root/repository" config --local --add \
    remote.origin.url "$expected_repository"
"${clean_env[@]}" git -C "$test_root/repository" config --local --add \
    remote.origin.url "$expected_repository"
if "${clean_env[@]}" bash "$origin_guard" "$test_root/repository" \
    "$expected_repository" >/dev/null 2>&1; then
    printf 'cursor-evidence-origin-test: multivalued local origin was accepted\n' >&2
    exit 1
fi

printf '%s\n' \
    'CURSOR_STATIC_EVIDENCE_ORIGIN_TEST_OK rewrite=ignored changed=refused missing=refused multivalue=refused injected=refused'
