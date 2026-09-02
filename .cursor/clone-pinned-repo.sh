#!/usr/bin/env bash
# Clone one upstream Git repository to an exact commit+tree pin.
#
# Usage: clone-pinned-repo.sh --lock FILE --id SOURCE_ID --repo-root PATH
#
# Discipline matches install-static-evidence.sh: commit pins only (never tags),
# origin is read from the checkout's own config, a failed fetch leaves no dest,
# and HEAD plus HEAD^{tree} must both match the lock.

set -euo pipefail

lock_path=
source_id=
repo_root=

usage() {
    printf 'usage: clone-pinned-repo.sh --lock FILE --id SOURCE_ID --repo-root PATH\n' >&2
    exit 2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --lock) lock_path=${2-}; shift 2 ;;
        --id) source_id=${2-}; shift 2 ;;
        --repo-root) repo_root=${2-}; shift 2 ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
done
[ -n "$lock_path" ] && [ -n "$source_id" ] && [ -n "$repo_root" ] || usage
[ -f "$lock_path" ] || { printf 'cursor-corpus: lock is missing: %s\n' "$lock_path" >&2; exit 1; }
case "$repo_root" in ''|/) printf 'cursor-corpus: unsafe repository root\n' >&2; exit 1 ;; esac

repository=$(jq -er --arg id "$source_id" \
    '.sources[] | select(.id == $id) | .repository' "$lock_path")
commit=$(jq -er --arg id "$source_id" \
    '.sources[] | select(.id == $id) | .commit' "$lock_path")
tree=$(jq -er --arg id "$source_id" \
    '.sources[] | select(.id == $id) | .tree' "$lock_path")
destination_rel=$(jq -er --arg id "$source_id" \
    '.sources[] | select(.id == $id) | .destination' "$lock_path")

[[ "$repository" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git$ ]] \
    || { printf 'cursor-corpus: unapproved repository URL for %s\n' "$source_id" >&2; exit 1; }
case "$commit" in *[!0-9a-f]*|'') printf 'cursor-corpus: invalid commit pin for %s\n' "$source_id" >&2; exit 1 ;; esac
[ "${#commit}" -eq 40 ] || { printf 'cursor-corpus: commit pin is not 40 hex for %s\n' "$source_id" >&2; exit 1; }
case "$tree" in *[!0-9a-f]*|'') printf 'cursor-corpus: invalid tree pin for %s\n' "$source_id" >&2; exit 1 ;; esac
[ "${#tree}" -eq 40 ] || { printf 'cursor-corpus: tree pin is not 40 hex for %s\n' "$source_id" >&2; exit 1; }
[[ "$destination_rel" =~ ^scratch/[A-Za-z0-9._/-]+$ ]] \
    || { printf 'cursor-corpus: destination is not under scratch/ for %s\n' "$source_id" >&2; exit 1; }
case "/$destination_rel/" in
    *'/../'*|*'/./'*|'//'*) printf 'cursor-corpus: unsafe destination for %s\n' "$source_id" >&2; exit 1 ;;
esac

dest=$repo_root/$destination_rel
dest_parent=$(dirname -- "$dest")
staging_root=
cleanup_staging() {
    if [ -n "$staging_root" ] && [ -e "$staging_root" ]; then
        case "$staging_root" in
            "$dest_parent"/.cursor-corpus.*) rm -rf -- "$staging_root" ;;
            *) printf 'cursor-corpus: refusing unsafe staging cleanup\n' >&2; return 1 ;;
        esac
    fi
}
trap cleanup_staging EXIT HUP INT TERM

self_dir=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
origin_guard=$self_dir/validate-static-evidence-origin.sh
if [ ! -f "$origin_guard" ] || [ -L "$origin_guard" ]; then
    printf 'cursor-corpus: origin guard is missing or unsafe\n' >&2
    exit 1
fi

git_at() {
    local root=$1
    shift
    git -c safe.directory="$root" -C "$root" "$@"
}

checkout_is_valid() {
    local root=$1
    [ -d "$root/.git" ] || return 1
    [ ! -L "$root" ] || return 1
    [ "$(git_at "$root" rev-parse HEAD)" = "$commit" ] || return 1
    [ "$(git_at "$root" rev-parse 'HEAD^{tree}')" = "$tree" ] || return 1
    bash "$origin_guard" "$root" "$repository"
    local status
    status=$(git_at "$root" --no-optional-locks status \
        --porcelain=v1 --untracked-files=all --ignored) \
        || return 1
    [ -z "$status" ]
}

if [ -e "$dest" ]; then
    if checkout_is_valid "$dest"; then
        printf 'CURSOR_CORPUS_OK id=%s commit=%s tree=%s dest=%s reused=1\n' \
            "$source_id" "$commit" "$tree" "$destination_rel"
        exit 0
    fi
fi

mkdir -p "$dest_parent"
staging_root=$(mktemp -d "$dest_parent/.cursor-corpus.XXXXXX")
checkout_root=$staging_root/checkout
git init -q "$checkout_root"
git_at "$checkout_root" remote add origin "$repository"
git_at "$checkout_root" config remote.origin.promisor true
git_at "$checkout_root" config remote.origin.partialclonefilter blob:none
bash "$origin_guard" "$checkout_root" "$repository"
git_at "$checkout_root" fetch --filter=blob:none --depth=1 origin "$commit"
git_at "$checkout_root" checkout --detach "$commit"

checkout_is_valid "$checkout_root" \
    || { printf 'cursor-corpus: staged %s failed pin+origin+clean checks\n' "$source_id" >&2; exit 1; }

if [ -e "$dest" ] || [ -L "$dest" ]; then
    rm -rf -- "$dest"
fi
mv -T -n -- "$checkout_root" "$dest"
if [ -e "$checkout_root" ] || [ ! -d "$dest/.git" ]; then
    printf 'cursor-corpus: atomic publication lost a race for %s\n' "$source_id" >&2
    exit 1
fi
rmdir "$staging_root"
staging_root=

checkout_is_valid "$dest" \
    || { printf 'cursor-corpus: published %s failed pin+origin+clean checks\n' "$source_id" >&2; exit 1; }

printf 'CURSOR_CORPUS_OK id=%s commit=%s tree=%s dest=%s reused=0\n' \
    "$source_id" "$commit" "$tree" "$destination_rel"
