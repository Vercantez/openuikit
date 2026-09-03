#!/bin/bash
# POSIX overlay headers are Apple's, from the machorun SDK pins, refuse-overwrite.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "=== stage into empty sysroot prints provenance ==="
mkdir -p "$tmp/sdk"
set +e
out=$(bash "$SCRIPT_DIR/stage_overlay_posix.sh" "$tmp/sdk" 2>&1)
rc=$?
set -e
printf '%s\n' "$out"
[ "$rc" -eq 0 ] && echo "  OK  rc=0" || { echo "  FAIL rc=$rc"; fail=1; }
for h in usr/include/semaphore.h usr/include/sys/ioctl.h usr/include/sys/ioccom.h \
         usr/include/sys/ttycom.h usr/include/sys/filio.h usr/include/sys/sockio.h; do
  [ -f "$tmp/sdk/$h" ] && echo "  OK  $h" || { echo "  FAIL missing $h"; fail=1; }
done
printf '%s\n' "$out" | grep -q 'tag=Libc-1752.120.2' \
  && echo "  OK  Libc tag" || { echo "  FAIL missing Libc tag"; fail=1; }
printf '%s\n' "$out" | grep -q 'commit=4e34d0559e3a1b081afeb8604d9e204a1f31321d' \
  && echo "  OK  Libc commit" || { echo "  FAIL missing Libc commit"; fail=1; }
printf '%s\n' "$out" | grep -q 'tag=xnu-12377.121.6' \
  && echo "  OK  xnu tag" || { echo "  FAIL missing xnu tag"; fail=1; }
printf '%s\n' "$out" | grep -q 'commit=ac9718fb1af618d5ce8678d0dc6e8a58f252216f' \
  && echo "  OK  xnu commit" || { echo "  FAIL missing xnu commit"; fail=1; }
# Byte-identical to the vendored Apple file, not a stand-in.
cmp -s "$ROOT/sdk/overlay-posix/semaphore.h" "$tmp/sdk/usr/include/semaphore.h" \
  && echo "  OK  semaphore.h is the vendored Apple file" \
  || { echo "  FAIL semaphore.h mismatch"; fail=1; }
grep -q '_BSD_SEMAPHORE_H' "$tmp/sdk/usr/include/semaphore.h" \
  && echo "  OK  Apple POSIX wrapper guard" || { echo "  FAIL not Apple wrapper"; fail=1; }

echo
echo "=== refuse overwrite ==="
set +e
out=$(bash "$SCRIPT_DIR/stage_overlay_posix.sh" "$tmp/sdk" 2>&1)
rc=$?
set -e
[ "$rc" -eq 2 ] && echo "  OK  rc=2" || { echo "  FAIL rc=$rc want 2"; fail=1; }
printf '%s\n' "$out" | grep -q REFUSING \
  && echo "  OK  REFUSING" || { echo "  FAIL no REFUSING"; fail=1; }

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- overlay POSIX headers staged from Apple OSS pins"
  exit 0
fi
echo "FAIL"
exit 1
