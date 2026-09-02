#!/usr/bin/env bash

set -euo pipefail

[ "$#" -eq 2 ] \
    || { printf 'cursor-evidence-origin: expected checkout and repository arguments\n' >&2; exit 1; }

checkout_root=$1
expected_repository=$2

case "$checkout_root" in
    ''|/) printf 'cursor-evidence-origin: unsafe checkout root\n' >&2; exit 1 ;;
esac
[[ "$expected_repository" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git$ ]] \
    || { printf 'cursor-evidence-origin: expected repository URL is invalid\n' >&2; exit 1; }

git_config=$checkout_root/.git/config
if [ ! -f "$git_config" ] || [ -L "$git_config" ]; then
    printf 'cursor-evidence-origin: repository-local Git config is missing or unsafe\n' >&2
    exit 1
fi

# Read only the literal value in this checkout's own config. `git remote
# get-url` applies url.*.insteadOf rewrites, and a normal config lookup can
# include global, environment, command-scope, or include.path values. None of
# those may alter or satisfy the repository lock.
origin_dump=$(mktemp /tmp/openuikit-evidence-origin.XXXXXX)
cleanup_origin_dump() {
    rm -f -- "$origin_dump"
}
trap cleanup_origin_dump EXIT HUP INT TERM

if ! git config --no-includes --file "$git_config" --null --get-all \
    remote.origin.url > "$origin_dump"; then
    printf 'cursor-evidence-origin: repository-local origin is missing or unreadable\n' >&2
    exit 1
fi

origin_count=0
origin_value=
while IFS= read -r -d '' candidate; do
    origin_count=$((origin_count + 1))
    origin_value=$candidate
done < "$origin_dump"

[ "$origin_count" -eq 1 ] \
    || { printf 'cursor-evidence-origin: repository-local origin is not singular\n' >&2; exit 1; }
[ "$origin_value" = "$expected_repository" ] \
    || { printf 'cursor-evidence-origin: repository-local origin differs from lock\n' >&2; exit 1; }
