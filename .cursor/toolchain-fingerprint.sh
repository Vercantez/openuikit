#!/usr/bin/env bash
# Live toolchain fingerprint for the pinned swift:6.2-noble image.
# Printed as sorted key=value lines so it can be hashed.

set -euo pipefail

digest=sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc
os_id=unknown
os_version=unknown
if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    os_id=${ID:-unknown}
    os_version=${VERSION_ID:-unknown}
fi

swift_line=$(swiftc --version | head -n 1)
clang_line=$(clang-18 --version | head -n 1)
ld_line=$(ld64.lld-18 --version | head -n 1)

printf 'arch=%s\n' "$(uname -m)"
printf 'clang18=%s\n' "$clang_line"
printf 'image_digest=%s\n' "$digest"
printf 'ld64=%s\n' "$ld_line"
printf 'os=%s-%s\n' "$os_id" "$os_version"
printf 'swift=%s\n' "$swift_line"
