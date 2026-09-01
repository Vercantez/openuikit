#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
lock_path=$repo_root/full/framework-fanout/external-evidence-sources.json
[ -f "$lock_path" ] \
    || { printf 'cursor-evidence: source lock is missing\n' >&2; exit 1; }

source_id=dotnet-macios
repository=$(jq -er --arg id "$source_id" \
    '.sources[] | select(.id == $id) | .repository' "$lock_path")
commit=$(jq -er --arg id "$source_id" \
    '.sources[] | select(.id == $id) | .commit' "$lock_path")
license_path=$(jq -er --arg id "$source_id" \
    '.sources[] | select(.id == $id) | .licensePath' "$lock_path")
license_sha256=$(jq -er --arg id "$source_id" \
    '.sources[] | select(.id == $id) | .licenseSHA256' "$lock_path")

[[ "$repository" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git$ ]] \
    || { printf 'cursor-evidence: unapproved repository URL\n' >&2; exit 1; }
[[ "$license_path" =~ ^[A-Za-z0-9._/-]+$ ]] \
    || { printf 'cursor-evidence: invalid license path\n' >&2; exit 1; }
case "/$license_path/" in
    *'/../'*|*'/./'*|'//'*) printf 'cursor-evidence: unsafe license path\n' >&2; exit 1 ;;
esac
case "$commit" in
    *[!0-9a-f]*|'') printf 'cursor-evidence: invalid commit pin\n' >&2; exit 1 ;;
esac
[ "${#commit}" -eq 40 ] \
    || { printf 'cursor-evidence: commit pin is not 40 hex characters\n' >&2; exit 1; }
case "$license_sha256" in
    *[!0-9a-f]*|'') printf 'cursor-evidence: invalid license digest\n' >&2; exit 1 ;;
esac
[ "${#license_sha256}" -eq 64 ] \
    || { printf 'cursor-evidence: license digest is not SHA-256\n' >&2; exit 1; }

evidence_parent=/opt/openuikit-evidence
evidence_root=$evidence_parent/dotnet-macios
staging_root=
cleanup_staging() {
    if [ -n "$staging_root" ] && [ -e "$staging_root" ]; then
        case "$staging_root" in
            "$evidence_parent"/.dotnet-macios.*)
                sudo find "$staging_root" -depth -delete
                ;;
            *)
                printf 'cursor-evidence: refusing unsafe staging cleanup\n' >&2
                return 1
                ;;
        esac
    fi
}
trap cleanup_staging EXIT HUP INT TERM

if [ ! -e "$evidence_parent" ]; then
    sudo install -d -o "$(id -u)" -g "$(id -g)" "$evidence_parent"
fi
[ -d "$evidence_parent" ] && [ ! -L "$evidence_parent" ] \
    || { printf 'cursor-evidence: unsafe evidence parent\n' >&2; exit 1; }

new_checkout=false
if [ ! -e "$evidence_root" ]; then
    [ -w "$evidence_parent" ] \
        || { printf 'cursor-evidence: immutable evidence parent lacks the pinned checkout\n' >&2; exit 1; }
    staging_root=$(mktemp -d "$evidence_parent/.dotnet-macios.XXXXXX")
    checkout_root=$staging_root/checkout
    git init -q "$checkout_root"
    new_checkout=true
else
    checkout_root=$evidence_root
fi
[ -d "$checkout_root/.git" ] && [ ! -L "$checkout_root" ] \
    || { printf 'cursor-evidence: evidence checkout is not a Git worktree\n' >&2; exit 1; }
git_evidence() {
    git -c safe.directory="$checkout_root" -C "$checkout_root" "$@"
}
if [ "$new_checkout" = false ]; then
    checkout_status=$(git_evidence --no-optional-locks status \
        --porcelain=v1 --untracked-files=all --ignored) \
        || { printf 'cursor-evidence: cannot inspect existing checkout status\n' >&2; exit 1; }
    [ -z "$checkout_status" ] \
        || { printf 'cursor-evidence: evidence checkout is dirty\n' >&2; exit 1; }
else
    git_evidence remote add origin "$repository"
    git_evidence config remote.origin.promisor true
    git_evidence config remote.origin.partialclonefilter blob:none
fi
[ "$(git_evidence remote get-url origin)" = "$repository" ] \
    || { printf 'cursor-evidence: evidence origin differs from lock\n' >&2; exit 1; }

if [ "$new_checkout" = true ]; then
    git_evidence sparse-checkout init --cone
    git_evidence sparse-checkout set src
    git_evidence fetch --filter=blob:none --depth=1 origin "$commit"
    git_evidence checkout --detach "$commit"
fi

[ "$(git_evidence rev-parse HEAD)" = "$commit" ] \
    || { printf 'cursor-evidence: checked-out commit differs from lock\n' >&2; exit 1; }
sparse_paths=$(git_evidence sparse-checkout list) \
    || { printf 'cursor-evidence: cannot inspect sparse checkout\n' >&2; exit 1; }
[ "$sparse_paths" = src ] \
    || { printf 'cursor-evidence: sparse checkout differs from required src corpus\n' >&2; exit 1; }
[ -d "$checkout_root/src" ] && [ ! -L "$checkout_root/src" ] \
    || { printf 'cursor-evidence: required src corpus is missing\n' >&2; exit 1; }
[ "$(sha256sum "$checkout_root/$license_path" | awk '{print $1}')" = "$license_sha256" ] \
    || { printf 'cursor-evidence: license digest differs from lock\n' >&2; exit 1; }
checkout_status=$(git_evidence --no-optional-locks status \
    --porcelain=v1 --untracked-files=all --ignored) \
    || { printf 'cursor-evidence: cannot inspect checkout status\n' >&2; exit 1; }
[ -z "$checkout_status" ] \
    || { printf 'cursor-evidence: checkout became dirty\n' >&2; exit 1; }
checkout_symlink=$(find "$checkout_root" -type l -print -quit) \
    || { printf 'cursor-evidence: cannot inspect checkout links\n' >&2; exit 1; }
[ -z "$checkout_symlink" ] \
    || { printf 'cursor-evidence: evidence checkout contains a symbolic link\n' >&2; exit 1; }

# Cloud agents receive this corpus as evidence, never as an editable dependency.
# Root ownership and removed write bits prevent accidental drift. Agents have
# sudo, so the verifier and central review still re-establish integrity rather
# than treating filesystem permissions as an adversarial trust boundary.
sudo chown -R root:root "$checkout_root"
sudo chmod -R a-w "$checkout_root"
if [ "$new_checkout" = true ]; then
    sudo mv -T -n -- "$checkout_root" "$evidence_root"
    [ ! -e "$checkout_root" ] && [ -d "$evidence_root/.git" ] \
        || { printf 'cursor-evidence: atomic evidence publication lost a race\n' >&2; exit 1; }
    rmdir "$staging_root"
    staging_root=
fi
sudo chown root:root "$evidence_parent"
sudo chmod 0755 "$evidence_parent"

printf 'CURSOR_STATIC_EVIDENCE_OK source=%s commit=%s\n' "$source_id" "$commit"
