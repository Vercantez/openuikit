#!/bin/bash
# A parked foreign-arch dylib is not a library path. CHECK 5 must not grade
# usr/lib-arm64-park (or any *-park directory): that is the phase2 /
# build_stdlib parking spot for leftover arm64 slices, and the loader does
# not search it.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MR=$(cd "$SCRIPT_DIR/.." && pwd)
OPENUIKIT=$(cd "$MR/.." && pwd)
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

check=$SCRIPT_DIR/check_undefined.sh
sys=$MR/darwin/usr/lib/libSystem.B.dylib
parked_core=$OPENUIKIT/swiftcore-macho/artifacts/swift-macosx/arm64/libswiftCore.dylib

[ -f "$sys" ] || { echo "FAIL no $sys"; exit 1; }
[ -f "$parked_core" ] || { echo "FAIL no arm64 libswiftCore at $parked_core"; exit 1; }
[ -x "$check" ] || { echo "FAIL no $check"; exit 1; }

# Minimal fixture: the live x86 libSystem (and friends) plus an arm64
# libswiftCore dropped exactly where phase2 parks it.
fix=$tmp/darwin
mkdir -p "$fix/usr/lib" "$fix/usr/lib-arm64-park/swift"
for d in "$MR"/darwin/usr/lib/*.dylib; do
  ln -s "$d" "$fix/usr/lib/$(basename "$d")"
done

images() { printf '%s\n' "$1" | awk '/Mach-O images/{print $1; exit}'; }
files()  { printf '%s\n' "$1" | sed -n 's/.*(\([0-9][0-9]*\) files considered).*/\1/p' | head -1; }

echo "=== baseline: x86 dylibs only ==="
set +e
base=$("$check" "$fix" 2>&1)
brc=$?
set -e
printf '%s\n' "$base" | head -8
base_n=$(images "$base")
base_f=$(files "$base")
echo "  baseline images=$base_n files=$base_f rc=$brc"

echo
echo "=== same tree + usr/lib-arm64-park/swift/libswiftCore.dylib (arm64) ==="
cp -a "$parked_core" "$fix/usr/lib-arm64-park/swift/libswiftCore.dylib"
file -b "$fix/usr/lib-arm64-park/swift/libswiftCore.dylib" | sed 's/^/  parked: /'
set +e
with=$("$check" --strict "$fix" 2>&1)
wrc=$?
set -e
printf '%s\n' "$with" | head -20
with_n=$(images "$with")
with_f=$(files "$with")
echo "  with-park images=$with_n files=$with_f rc=$wrc (strict)"

[ "$with_n" = "$base_n" ] && [ -n "$with_n" ] \
  && echo "  OK  Mach-O image count unchanged ($with_n)" \
  || { echo "  FAIL images baseline=$base_n with-park=$with_n"; fail=1; }
[ "$with_f" = "$base_f" ] && [ -n "$with_f" ] \
  && echo "  OK  files considered unchanged ($with_f)" \
  || { echo "  FAIL files baseline=$base_f with-park=$with_f"; fail=1; }

printf '%s\n' "$with" | grep -q 'lib-arm64-park' \
  && { echo "  FAIL CHECK 5 named the parking directory"; fail=1; } \
  || echo "  OK  findings do not name lib-arm64-park"

# The operator log's 14 plain names (flockfile family) came from the parked
# arm64 libswiftCore. They must not appear just because it is on disk.
printf '%s\n' "$with" | grep -qE '_flockfile|_funlockfile' \
  && { echo "  FAIL parked libswiftCore imports leaked into CHECK 5"; fail=1; } \
  || echo "  OK  parked libswiftCore imports are not CHECK 5 findings"

# Control: the same dylib under usr/lib/ (a real library path) MUST count.
echo
echo "=== control: same arm64 dylib under usr/lib/swift/ must count ==="
mkdir -p "$fix/usr/lib/swift"
cp -a "$parked_core" "$fix/usr/lib/swift/libswiftCore.dylib"
set +e
ctrl=$("$check" "$fix" 2>&1)
crc=$?
set -e
ctrl_n=$(images "$ctrl")
echo "  control images=$ctrl_n rc=$crc"
if [ -n "$base_n" ] && [ -n "$ctrl_n" ] && [ "$ctrl_n" -gt "$base_n" ]; then
  echo "  OK  a dylib under usr/lib/swift/ is graded (images $base_n -> $ctrl_n)"
else
  echo "  FAIL control did not increase image count (baseline=$base_n control=$ctrl_n)"
  fail=1
fi
printf '%s\n' "$ctrl" | grep -qE '_flockfile|_funlockfile' \
  && echo "  OK  those imports ARE visible when the dylib is on a library path" \
  || echo "  note: flockfile not in this root's unaccounted set (ok if defined elsewhere)"

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- parked foreign-arch dylib does not count toward CHECK 5"
  exit 0
fi
echo "FAIL"
exit 1
