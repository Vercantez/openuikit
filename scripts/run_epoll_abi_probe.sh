#!/bin/bash
# Verify our hand-written Linux ABI against REAL glibc headers, and prove the
# check can fail. Runs on Linux (host compiler); skipped on macOS.
#
# This is NOT the same check as the Darwin-side _Static_asserts in the staged
# headers: those pin our own mirror and would keep passing if glibc moved. See
# the header comment in sdk/tests/epoll_abi_probe.c.
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
PROBE=$HERE/sdk/tests/epoll_abi_probe.c

if [ "$(uname -s)" != "Linux" ]; then
  echo "SKIP: epoll ABI probe is the Linux half (host is $(uname -s))."
  echo "      On macOS run it in a container:"
  echo "      docker run --rm --platform linux/arm64 -v \"\$PWD/sdk/tests:/t:ro\" \\"
  echo "        machorun-testbed:24.04 cc -std=gnu11 -fsyntax-only /t/epoll_abi_probe.c"
  exit 0
fi

cc -std=gnu11 -fsyntax-only "$PROBE"
echo "PASS: hand-written Linux ABI matches real glibc"

# A probe never shown to fail is not a probe.
if cc -std=gnu11 -DEPOLL_ABI_PROBE_MUTANT -fsyntax-only "$PROBE" 2>/dev/null; then
  echo "FAIL: the mutant compiled. This probe cannot detect a wrong layout." >&2
  exit 1
fi
echo "PASS: mutant rejected (the probe has teeth)"
