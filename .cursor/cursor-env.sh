#!/usr/bin/env bash
# Helpers for gate scripts. Source this file; do not execute it.

# shellcheck disable=SC2034
CURSOR_ENV_PINNED_IMAGE='swift:6.2-noble@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc'

cursor_env_repo_root() {
    local self
    self=$(unset CDPATH; cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
    unset CDPATH
    cd -- "$self/.." && pwd
}

cursor_env_attest() {
    bash "$(cursor_env_repo_root)/.cursor/attest-cursor-env.sh"
}

cursor_env_cannot_execute_arm64() {
    bash "$(cursor_env_repo_root)/.cursor/refuse-arm64-execution.sh"
}

cursor_env_can_execute_arm64() {
    host=$(uname -m)
    [ "$host" = aarch64 ] || [ "$host" = arm64 ]
}

cursor_env_macos_oracle_local_only() {
    printf 'CURSOR_ENV_MACOS_ORACLE_LOCAL_ONLY host=%s\n' "$(uname -s)" >&2
}

# If docker can run, print "docker". If Cursor env attestation passes, print
# "native". Otherwise refuse: docker-absent is not a skip.
#
# Attestation is a substitute ONLY when docker exists to pin swift:6.2-noble
# and the inner work is Linux ELF (or compile/link of arm64 Mach-O). It is
# never a substitute for container isolation, nor for executing arm64 Mach-O
# under machorun (that is CURSOR_ENV_CANNOT_EXECUTE_ARM64).
cursor_env_toolchain_mode() {
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        printf 'docker\n'
        return 0
    fi
    if cursor_env_attest >/dev/null; then
        printf 'native\n'
        return 0
    fi
    printf 'cursor-env: REFUSING -- docker is absent and this host is not an attested Cursor cloud environment matching %s\n' \
        "$CURSOR_ENV_PINNED_IMAGE" >&2
    return 2
}
