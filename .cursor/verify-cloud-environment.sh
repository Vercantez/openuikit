#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
case "$repo_root" in
    ''|/) printf 'cursor-environment: unsafe repository root: %s\n' "$repo_root" >&2; exit 1 ;;
esac
[ -f "$repo_root/harness/Dockerfile" ] \
    || { printf 'cursor-environment: OpenUIKit repository marker is missing\n' >&2; exit 1; }

# A Build must contain tools, never prior OpenUIKit products. These roots are
# documented as generated and gitignored by the repository. Refuse to remove
# one if it ever gains tracked content.
for relative in .build build scratch; do
    tracked_paths=$(git -C "$repo_root" ls-files -- "$relative") \
        || { printf 'cursor-environment: cannot inspect tracked cleanup paths\n' >&2; exit 1; }
    if [ -n "$tracked_paths" ]; then
        printf 'cursor-environment: refusing to clean tracked path: %s\n' "$relative" >&2
        exit 1
    fi
    generated_root=$repo_root/$relative
    if [ -e "$generated_root" ] || [ -L "$generated_root" ]; then
        rm -rf -- "$generated_root"
    fi
done

for tool in swiftc clang-18 ld64.lld python3 pkg-config git; do
    command -v "$tool" >/dev/null \
        || { printf 'cursor-environment: missing tool: %s\n' "$tool" >&2; exit 1; }
done

evidence_lock=$repo_root/full/framework-fanout/external-evidence-sources.json
[ -f "$evidence_lock" ] \
    || { printf 'cursor-environment: external evidence lock is missing\n' >&2; exit 1; }
[ "${OPENUIKIT_MACIOS_ROOT:-}" = /opt/openuikit-evidence/dotnet-macios ] \
    || { printf 'cursor-environment: OPENUIKIT_MACIOS_ROOT differs\n' >&2; exit 1; }
if [ ! -d "$OPENUIKIT_MACIOS_ROOT/.git" ] || [ -L "$OPENUIKIT_MACIOS_ROOT" ]; then
    printf 'cursor-environment: macios evidence checkout is missing\n' >&2
    exit 1
fi
expected_macios_commit=$(jq -er \
    '.sources[] | select(.id == "dotnet-macios") | .commit' "$evidence_lock")
expected_macios_repository=$(jq -er \
    '.sources[] | select(.id == "dotnet-macios") | .repository' "$evidence_lock")
expected_license_path=$(jq -er \
    '.sources[] | select(.id == "dotnet-macios") | .licensePath' "$evidence_lock")
expected_license_sha256=$(jq -er \
    '.sources[] | select(.id == "dotnet-macios") | .licenseSHA256' "$evidence_lock")
[[ "$expected_macios_repository" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git$ ]] \
    || { printf 'cursor-environment: macios repository URL is invalid\n' >&2; exit 1; }
[[ "$expected_license_path" =~ ^[A-Za-z0-9._/-]+$ ]] \
    || { printf 'cursor-environment: macios license path is invalid\n' >&2; exit 1; }
case "/$expected_license_path/" in
    *'/../'*|*'/./'*|'//'*) printf 'cursor-environment: macios license path is unsafe\n' >&2; exit 1 ;;
esac
git_macios() {
    git -c safe.directory="$OPENUIKIT_MACIOS_ROOT" \
        -C "$OPENUIKIT_MACIOS_ROOT" "$@"
}
[ "$(git_macios rev-parse HEAD)" = "$expected_macios_commit" ] \
    || { printf 'cursor-environment: macios evidence commit differs\n' >&2; exit 1; }
[ "$(git_macios remote get-url origin)" = "$expected_macios_repository" ] \
    || { printf 'cursor-environment: macios evidence origin differs\n' >&2; exit 1; }
macios_sparse_paths=$(git_macios sparse-checkout list) \
    || { printf 'cursor-environment: cannot inspect macios sparse checkout\n' >&2; exit 1; }
[ "$macios_sparse_paths" = src ] \
    || { printf 'cursor-environment: macios sparse checkout differs from required src corpus\n' >&2; exit 1; }
if [ ! -d "$OPENUIKIT_MACIOS_ROOT/src" ] || [ -L "$OPENUIKIT_MACIOS_ROOT/src" ]; then
    printf 'cursor-environment: required macios src corpus is missing\n' >&2
    exit 1
fi
[ "$(sha256sum "$OPENUIKIT_MACIOS_ROOT/$expected_license_path" | awk '{print $1}')" = "$expected_license_sha256" ] \
    || { printf 'cursor-environment: macios evidence license differs\n' >&2; exit 1; }
macios_status=$(git_macios --no-optional-locks status \
    --porcelain=v1 --untracked-files=all --ignored) \
    || { printf 'cursor-environment: cannot inspect macios checkout status\n' >&2; exit 1; }
[ -z "$macios_status" ] \
    || { printf 'cursor-environment: macios evidence checkout is dirty\n' >&2; exit 1; }
[ "$(stat -c '%U:%G:%a' "$(dirname "$OPENUIKIT_MACIOS_ROOT")")" = root:root:755 ] \
    || { printf 'cursor-environment: evidence parent ownership or mode differs\n' >&2; exit 1; }
macios_nonroot=$(find "$OPENUIKIT_MACIOS_ROOT" \
    \( -type f -o -type d \) ! -user root -print -quit) \
    || { printf 'cursor-environment: cannot inspect macios ownership\n' >&2; exit 1; }
[ -z "$macios_nonroot" ] \
    || { printf 'cursor-environment: macios evidence is not root-owned\n' >&2; exit 1; }
macios_writable=$(find "$OPENUIKIT_MACIOS_ROOT" \
    \( -type f -o -type d \) -perm /222 -print -quit) \
    || { printf 'cursor-environment: cannot inspect macios modes\n' >&2; exit 1; }
[ -z "$macios_writable" ] \
    || { printf 'cursor-environment: macios evidence remains writable\n' >&2; exit 1; }
macios_symlink=$(find "$OPENUIKIT_MACIOS_ROOT" -type l -print -quit) \
    || { printf 'cursor-environment: cannot inspect macios links\n' >&2; exit 1; }
[ -z "$macios_symlink" ] \
    || { printf 'cursor-environment: macios evidence contains a symbolic link\n' >&2; exit 1; }

swift_version=$(swiftc --version)
case "$swift_version" in
    *'Swift version 6.2.4'*'Target: '*'linux'*) ;;
    *) printf 'cursor-environment: unexpected Swift toolchain:\n%s\n' "$swift_version" >&2; exit 1 ;;
esac

printf 'import Foundation\nfunc probeFoundation() {\n    let value = Data([0x4f, 0x4b])\n    _ = value.count\n}\n' \
    | swiftc -parse-as-library -typecheck -module-name CursorEnvironmentProbe -

printf 'CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean evidence=dotnet-macios\n'
