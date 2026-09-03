#!/bin/bash
# The execute-guest marker is decided by a positive loader probe, never by
# assuming this process is a cloud-agent VM.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/probe_machorun.inc"
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "=== empty tree is not a loader ==="
set +e
got=$(
  unset MACHORUN_LOADER MACHORUN OPENUIKIT_ROOT
  MACHORUN=/no/such/machorun OPENUIKIT_ROOT=/no/such/openuikit W="$tmp" \
    probe_x86_macho_loader
)
rc=$?
set -e
[ "$rc" -ne 0 ] && echo "  OK  no loader rc=$rc" || { echo "  FAIL probed a loader: $got"; fail=1; }

echo
echo "=== real loader on this host (if present) ==="
# Point only at well-known in-tree / work-dir loaders; still a positive probe.
found=0
for cand in \
  "${SCRIPT_DIR}/../../machorun/build/machorun" \
  "$HOME/work/machorun/build/machorun" \
  /workspace/machorun/build/machorun
do
  [ -x "$cand" ] || continue
  set +e
  got=$(
    SWIFTCORE_DARWIN_ARCH=x86_64 \
      MACHORUN_LOADER="$cand" MACHORUN=/no/such OPENUIKIT_ROOT=/no/such W="$tmp" \
      probe_x86_macho_loader
  )
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    echo "  OK  probed $got"
    printf '%s' "$got" | grep -q "$cand" && echo "  OK  path is the candidate" \
      || { echo "  FAIL got=$got want $cand"; fail=1; }
    found=1
    break
  fi
done
if [ "$found" = 0 ]; then
  echo "  skip (no in-tree machorun ELF on this host)"
fi

echo
echo "=== script that is not a machorun loader is rejected ==="
printf '#!/bin/bash\necho hello\n' > "$tmp/not-loader"
chmod +x "$tmp/not-loader"
set +e
got=$(MACHORUN_LOADER="$tmp/not-loader" MACHORUN=/no OPENUIKIT_ROOT=/no W="$tmp" \
  probe_x86_macho_loader)
rc=$?
set -e
[ "$rc" -ne 0 ] && echo "  OK  non-ELF / non-machorun rejected" \
  || { echo "  FAIL accepted $got"; fail=1; }

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- loader probe is positive, not a VM assumption"
  exit 0
fi
echo "FAIL"
exit 1
