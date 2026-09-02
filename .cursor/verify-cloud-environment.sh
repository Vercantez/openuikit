#!/usr/bin/env bash

set -euo pipefail

started_ns=$(date +%s%N)
phase_ns=$started_ns
cleanup_ms=0
tools_ms=0
evidence_ms=0
swift_ms=0
finish_phase() {
    current_ns=$(date +%s%N)
    elapsed_ms=$(( (current_ns - phase_ns) / 1000000 ))
    phase_ns=$current_ns
}

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
finish_phase
cleanup_ms=$elapsed_ms

for tool in \
    swift swiftc \
    clang clang++ clang-18 clang++-18 \
    ld64.lld ld64.lld-18 \
    llvm-nm llvm-nm-18 \
    llvm-otool llvm-otool-18 \
    llvm-objdump llvm-objdump-18 \
    perl patch jq sha256sum shasum cmp file git python3 pkg-config
do
    command -v "$tool" >/dev/null \
        || { printf 'cursor-environment: missing tool: %s\n' "$tool" >&2; exit 1; }
done

# Consumers invoke both spellings. Refuse an image where an unversioned LLVM
# name resolves to a different toolchain instead of the pinned Ubuntu LLVM 18
# binary installed above.
for llvm_tool in llvm-nm llvm-otool llvm-objdump; do
    unversioned_path=$(command -v "$llvm_tool")
    versioned_path=$(command -v "${llvm_tool}-18")
    [ "$(readlink -f "$unversioned_path")" = "$(readlink -f "$versioned_path")" ] \
        || { printf 'cursor-environment: %s does not resolve to %s-18\n' \
            "$llvm_tool" "$llvm_tool" >&2; exit 1; }
done
if command -v llvm-readtapi-18 >/dev/null; then
    command -v llvm-readtapi >/dev/null \
        || { printf 'cursor-environment: missing tool: llvm-readtapi\n' >&2; exit 1; }
    [ "$(readlink -f "$(command -v llvm-readtapi)")" = \
        "$(readlink -f "$(command -v llvm-readtapi-18)")" ] \
        || { printf 'cursor-environment: llvm-readtapi does not resolve to llvm-readtapi-18\n' >&2; exit 1; }
fi
finish_phase
tools_ms=$elapsed_ms

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
origin_guard=$repo_root/.cursor/validate-static-evidence-origin.sh
if [ ! -f "$origin_guard" ] || [ -L "$origin_guard" ]; then
    printf 'cursor-environment: repository origin guard is missing or unsafe\n' >&2
    exit 1
fi
[ "$(git_macios rev-parse HEAD)" = "$expected_macios_commit" ] \
    || { printf 'cursor-environment: macios evidence commit differs\n' >&2; exit 1; }
bash "$origin_guard" "$OPENUIKIT_MACIOS_ROOT" "$expected_macios_repository"
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
finish_phase
evidence_ms=$elapsed_ms

swift_version=$(swiftc --version)
case "$swift_version" in
    *'Swift version 6.2.4'*'Target: '*'linux'*) ;;
    *) printf 'cursor-environment: unexpected Swift toolchain:\n%s\n' "$swift_version" >&2; exit 1 ;;
esac

printf 'import Foundation\nfunc probeFoundation() {\n    let value = Data([0x4f, 0x4b])\n    _ = value.count\n}\n' \
    | swiftc -parse-as-library -typecheck -module-name CursorEnvironmentProbe -
finish_phase
swift_ms=$elapsed_ms
finished_ns=$phase_ns
total_ms=$(( (finished_ns - started_ns) / 1000000 ))

printf 'CURSOR_TOOLCHAIN_INVENTORY_OK swift=swift,swiftc clang=clang,clang++,clang-18,clang++-18 linker=ld64.lld,ld64.lld-18 llvm=llvm-nm,llvm-nm-18,llvm-otool,llvm-otool-18,llvm-objdump,llvm-objdump-18 utilities=perl,patch,jq,sha256sum,shasum,cmp,file,git,python3,pkg-config\n'
printf 'CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean evidence=dotnet-macios\n'
printf 'CURSOR_ENVIRONMENT_METRICS total_ms=%d cleanup_ms=%d tools_ms=%d evidence_ms=%d swift_ms=%d\n' \
    "$total_ms" "$cleanup_ms" "$tools_ms" "$evidence_ms" "$swift_ms"
