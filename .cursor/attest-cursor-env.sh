#!/usr/bin/env bash
# Accept a run as a substitute for docker-run of the pinned swift:6.2-noble
# image when this VM already is that toolchain.
#
# Success requires:
#   1. verify-cloud-environment.sh has written a stamp, and
#   2. the live fingerprint still matches that stamp (and therefore the pinned
#      image digest / Swift 6.2.4 linux / LLVM 18 inventory).
# Refuse loudly otherwise. Never treat docker-absent as a skip.

set -euo pipefail

self_dir=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(unset CDPATH; cd -- "$self_dir/.." && pwd)

stamp=$repo_root/scratch/.cursor-env-attestation.json
fingerprint_tool=$repo_root/.cursor/toolchain-fingerprint.sh
[ -f "$fingerprint_tool" ] && [ ! -L "$fingerprint_tool" ] \
    || { printf 'cursor-env-attest: fingerprint tool is missing\n' >&2; exit 2; }

if [ ! -f "$stamp" ] || [ -L "$stamp" ]; then
    printf 'cursor-env-attest: REFUSING -- no attestation stamp at %s (run .cursor/verify-cloud-environment.sh)\n' \
        "$stamp" >&2
    exit 2
fi

expected=$(jq -er '.fingerprintSha256' "$stamp")
expected_digest=$(jq -er '.pinnedImageDigest' "$stamp")
expected_ok=$(jq -er '.swiftEnvironmentOk' "$stamp")
[ "$expected_ok" = true ] \
    || { printf 'cursor-env-attest: REFUSING -- stamp does not record CURSOR_SWIFT_ENVIRONMENT_OK\n' >&2; exit 2; }
[ "$expected_digest" = sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc ] \
    || { printf 'cursor-env-attest: REFUSING -- stamp image digest differs from pinned swift:6.2-noble\n' >&2; exit 2; }

live=$(bash "$fingerprint_tool" | sha256sum | awk '{print $1}')
[ "$live" = "$expected" ] \
    || { printf 'cursor-env-attest: REFUSING -- live toolchain fingerprint %s != stamp %s\n' \
        "$live" "$expected" >&2; exit 2; }

printf 'CURSOR_ENV_TOOLCHAIN_ATTESTED image=swift:6.2-noble@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc fingerprint=%s\n' \
    "$live"
