#!/bin/bash
# SWIFT_TOOLCHAIN / command -v swiftc must win over the hardcoded
# /opt/swift624 path. The operator host keeps 6.2.4 at /opt/swift.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
inc=$SCRIPT_DIR/guest_arch.inc
fail=0

echo "=== SWIFT_TOOLCHAIN missing dir refuses ==="
set +e
out=$(
  unset TC SWIFTCORE_GUEST_ARCH_INC
  SWIFT_TOOLCHAIN=/no/such/swiftcore-toolchain
  # shellcheck disable=SC1091
  . "$inc" 2>&1
)
rc=$?
set -e
[ "$rc" -ne 0 ] && echo "  OK  exit $rc" || { echo "  FAIL expected nonzero"; fail=1; }
printf '%s\n' "$out" | grep -F -- "SWIFT_TOOLCHAIN=/no/such/swiftcore-toolchain" >/dev/null \
  && echo "  OK  names the missing toolchain" \
  || { echo "  FAIL did not name SWIFT_TOOLCHAIN"; echo "$out"; fail=1; }

echo
echo "=== SWIFT_TOOLCHAIN with usr/bin/swiftc ==="
fake=$(mktemp -d)
trap 'rm -rf "$fake"' EXIT
mkdir -p "$fake/opt/swift/usr/bin"
ln -s "$(command -v swiftc)" "$fake/opt/swift/usr/bin/swiftc"
got=$(
  unset TC SWIFTCORE_GUEST_ARCH_INC
  SWIFT_TOOLCHAIN="$fake/opt/swift"
  # shellcheck disable=SC1091
  . "$inc"
  printf '%s\n' "$TC"
)
[ "$got" = "$fake/opt/swift/usr" ] && echo "  OK  TC=$got" \
  || { echo "  FAIL TC=$got want $fake/opt/swift/usr"; fail=1; }

echo
echo "=== default on this VM finds a swiftc ==="
got=$(
  unset TC SWIFT_TOOLCHAIN SWIFTCORE_GUEST_ARCH_INC
  # shellcheck disable=SC1091
  . "$inc"
  printf '%s\n' "$TC"
)
[ -x "$got/bin/swiftc" ] && echo "  OK  default TC=$got" \
  || { echo "  FAIL default TC=$got has no swiftc"; fail=1; }

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- SWIFT_TOOLCHAIN honored; /opt/swift624 is not the only path"
  exit 0
fi
echo "FAIL"
exit 1
