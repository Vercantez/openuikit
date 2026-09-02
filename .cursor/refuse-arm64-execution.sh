#!/usr/bin/env bash
# Canonical refusal for any gate that would execute arm64 Mach-O under machorun.
# machorun is a native aarch64 Linux host binary; this x86_64 VM can compile and
# link arm64 Mach-O but cannot run it. Do not qemu, docker-with-qemu, or stub.

set -euo pipefail

host=$(uname -m)
if [ "$host" = aarch64 ] || [ "$host" = arm64 ]; then
    printf 'cursor-env: refuse-arm64-execution is for non-aarch64 hosts (this host is %s)\n' \
        "$host" >&2
    exit 64
fi

printf 'CURSOR_ENV_CANNOT_EXECUTE_ARM64 host=%s machorun=arm64-linux-native split=compile-link-static-in-vm/execution-arm64-ec2/macos-oracle-local-only\n' \
    "$host" >&2
exit 2
