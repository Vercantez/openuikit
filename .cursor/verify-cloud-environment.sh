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
    if git -C "$repo_root" ls-files -- "$relative" | grep -q .; then
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

swift_version=$(swiftc --version)
case "$swift_version" in
    *'Swift version 6.2.4'*'Target: '*'linux'*) ;;
    *) printf 'cursor-environment: unexpected Swift toolchain:\n%s\n' "$swift_version" >&2; exit 1 ;;
esac

printf 'import Foundation\nfunc probeFoundation() {\n    let value = Data([0x4f, 0x4b])\n    _ = value.count\n}\n' \
    | swiftc -parse-as-library -typecheck -module-name CursorEnvironmentProbe -

printf 'CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean\n'
