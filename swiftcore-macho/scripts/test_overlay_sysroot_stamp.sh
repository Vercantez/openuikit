#!/bin/bash
# Overlay sysroot staging is input-keyed. A pre-existing MacOSX.sdk with
# clean-room math.h / no stamp is displaced, never rm'd; mismatch restages
# into a fresh directory. Stamp also keys usr/lib/*.tbd from the FE sysroot
# (scratch/sysroot_fe4[-x86_64], phase2 / machorun gen_tbd): a tbd-only
# source change is MISMATCH, not MATCH. Stamp also keys the FE source
# usr/include/Darwin.modulemap bytes: regenerating that map (main unexpanded
# vs an expanded overlay copy) is MISMATCH, not MATCH. Refuse-before-cmake if math.h lacks
# fmaxl, sys/proc.h lacks extern_proc, a Darwin Clang overlay map names a
# header that is not on disk, or an include_next wrapper (objc4-priv
# crt_externs.h: first directive `#include_next <same-basename>`) has no
# later -isysroot target. Apple's limits.h / machine/limits.h / i386/limits.h
# are not that shape (buried include_next is clang's resource dir; arm/
# limits.h is off-arch on x86_64). libc++ usr/include/c++/v1 module.modulemap
# is outside that closure and must not refuse.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/overlay_sysroot.inc"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/overlay_targets.inc"
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
W=$tmp/work
export W SWIFTCORE_DARWIN_ARCH=x86_64
unset SWIFTCORE_FE_SYSROOT
# A live $OPENUIKIT_ROOT/scratch/sysroot_fe4-x86_64 (or machorun/sdk tbds)
# on the developer tree must not win these fixtures. Cycle sets
# SWIFTCORE_FE_SYSROOT at the named FE sysroot; tests use W's scratch only.
overlay_sysroot_source_candidates() {
  local arch=${SWIFTCORE_DARWIN_ARCH:-x86_64}
  [ -n "${SWIFTCORE_FE_SYSROOT:-}" ] && printf '%s\n' "$SWIFTCORE_FE_SYSROOT"
  if [ -n "${W:-}" ]; then
    printf '%s\n' "$W/scratch/sysroot_fe4-${arch}"
    if [ "$arch" = x86_64 ]; then
      printf '%s\n' "$W/scratch/sysroot_fe4-x86_64"
    fi
  fi
}
overlay_sysroot_gen_tbd_candidates() {
  [ -n "${W:-}" ] && printf '%s\n' "$W/machorun-sdk"
  [ -n "${W:-}" ] && printf '%s\n' "$W/machorun/sdk"
}

need() {
  local cond=$1 msg=$2
  if eval "$cond"; then
    echo "  OK  $msg"
  else
    echo "  FAIL $msg"
    fail=1
  fi
}

fill_required_headers() {
  local sdk=$1
  mkdir -p "$sdk/usr/include/sys" "$sdk/usr/lib"
  cp "$ROOT/sdk/overlay-darwin/math.h" "$sdk/usr/include/math.h"
  cp "$ROOT/sdk/overlay-darwin/MacTypes.h" "$sdk/usr/include/MacTypes.h"
  cp "$ROOT/sdk/overlay-darwin/ConditionalMacros.h" "$sdk/usr/include/ConditionalMacros.h"
  cp "$OPENUIKIT_ROOT/machorun/sdk/usr/include/sys/proc.h" \
    "$sdk/usr/include/sys/proc.h"
  echo 'module Darwin [system] { header "math.h" header "sys/proc.h" export * }' \
    > "$sdk/usr/include/Darwin.modulemap"
}

echo "=== stamp MATCH vs ABSENT / recipe mismatch ==="
mkdir -p "$tmp/sdkA/usr/include/sys"
cp "$ROOT/sdk/overlay-darwin/math.h" "$tmp/sdkA/usr/include/math.h"
cp "$OPENUIKIT_ROOT/machorun/sdk/usr/include/sys/proc.h" \
  "$tmp/sdkA/usr/include/sys/proc.h"
echo 'module Darwin [system] { header "math.h" header "sys/proc.h" export * }' \
  > "$tmp/sdkA/usr/include/Darwin.modulemap"
overlay_sysroot_write_stamp "$tmp/sdkA"
set +e
diff_out=$(overlay_sysroot_stamp_diff "$tmp/sdkA/$OVERLAY_SYSROOT_STAMP")
st=$?
set -e
[ "$st" -eq 0 ] && echo "  OK  stamp MATCH rc=0" || { echo "  FAIL stamp MATCH rc=$st"; echo "$diff_out"; fail=1; }
set +e
missing=$(overlay_sysroot_stamp_diff "$tmp/absent")
st=$?
set -e
printf '%s\n' "$missing" | grep -q 'stamp=ABSENT' \
  && echo "  OK  missing stamp is ABSENT" || { echo "  FAIL missing stamp"; fail=1; }
[ "$st" -ne 0 ] && echo "  OK  missing stamp rc!=0" || { echo "  FAIL missing stamp rc=0"; fail=1; }
echo 'recipe=stale.0' > "$tmp/sdkA/$OVERLAY_SYSROOT_STAMP"
set +e
diff_out=$(overlay_sysroot_stamp_diff "$tmp/sdkA/$OVERLAY_SYSROOT_STAMP")
st=$?
set -e
printf '%s\n' "$diff_out" | grep -q 'recipe stale.0->' \
  && echo "  OK  recipe mismatch named" || { echo "  FAIL recipe diff: $diff_out"; fail=1; }
[ "$st" -ne 0 ] && echo "  OK  mismatch rc!=0" || { echo "  FAIL mismatch rc=0"; fail=1; }

echo
echo "=== print headers + refuse fmaxl / extern_proc ==="
overlay_sysroot_print_headers "$tmp/sdkA" >"$tmp/print1"
# restore a matching tree for print (stamp was clobbered; headers still good)
grep -q 'header usr/include/math.h present' "$tmp/print1" \
  && echo "  OK  printed math.h present" || { echo "  FAIL print math.h"; fail=1; }
grep -q 'fmaxl=yes' "$tmp/print1" \
  && echo "  OK  fmaxl=yes" || { echo "  FAIL fmaxl not yes"; cat "$tmp/print1"; fail=1; }
grep -q 'extern_proc=yes' "$tmp/print1" \
  && echo "  OK  extern_proc=yes" || { echo "  FAIL extern_proc not yes"; fail=1; }
grep -q 'overlay_sysroot: source=ABSENT tbd_sha=ABSENT' "$tmp/print1" \
  && echo "  OK  source=ABSENT tbd_sha=ABSENT (no FE sysroot)" \
  || { echo "  FAIL source/tbd_sha line"; cat "$tmp/print1"; fail=1; }

mkdir -p "$tmp/bad/usr/include/sys"
echo '/* clean-room math.h — no fmaxl */' > "$tmp/bad/usr/include/math.h"
echo 'struct proc { int p; };' > "$tmp/bad/usr/include/sys/proc.h"
set +e
refuse=$(overlay_sysroot_refuse_incomplete "$tmp/bad" 2>&1)
st=$?
set -e
printf '%s\n' "$refuse"
[ "$st" -eq 2 ] && echo "  OK  refuse rc=2" || { echo "  FAIL refuse rc=$st"; fail=1; }
printf '%s\n' "$refuse" | grep -q 'CANNOT_OVERLAY_SYSROOT_MATH_H' \
  && echo "  OK  CANNOT_OVERLAY_SYSROOT_MATH_H" || { echo "  FAIL missing MATH_H"; fail=1; }
printf '%s\n' "$refuse" | grep -q 'CANNOT_OVERLAY_SYSROOT_PROC_H' \
  && echo "  OK  CANNOT_OVERLAY_SYSROOT_PROC_H" || { echo "  FAIL missing PROC_H"; fail=1; }
printf '%s\n' "$refuse" | grep -q 'lacks fmaxl' \
  && echo "  OK  fmaxl reason" || { echo "  FAIL fmaxl reason"; fail=1; }
printf '%s\n' "$refuse" | grep -q 'lacks extern_proc' \
  && echo "  OK  extern_proc reason" || { echo "  FAIL extern_proc reason"; fail=1; }

echo
echo "=== pre-existing MacOSX.sdk is displaced, never rm'd; restage is a fresh dir ==="
mkdir -p "$tmp/sdk/MacOSX.sdk/usr/include" "$tmp/sdk/MacOSX.sdk/usr/lib"
echo 'OPERATOR_CANARY' > "$tmp/sdk/MacOSX.sdk/CANARY"
echo '/* clean-room */' > "$tmp/sdk/MacOSX.sdk/usr/include/math.h"
# gen_tbd output lives in the old tree; restage must copy it into the fresh dest.
cat > "$tmp/sdk/MacOSX.sdk/usr/lib/libSystem.B.tbd" <<'TBD'
--- !tapi-tbd-v3
archs: [ x86_64 ]
install-name: /usr/lib/libSystem.B.dylib
TBD
overlay_sysroot_begin "$tmp/sdk"
need '[ "${OVERLAY_SYSROOT_REUSE}" = 0 ]' "begin restage (REUSE=0)"
need '[ -d "$OVERLAY_SYSROOT_DEST" ]' "fresh dest exists"
need '[[ "$OVERLAY_SYSROOT_DEST" == *MacOSX.sdk.overlay-* ]]' "fresh dest is MacOSX.sdk.overlay-*"
need '[ -f "$tmp/sdk/MacOSX.sdk/CANARY" ]' "live canary still in place during stage"
fresh=$OVERLAY_SYSROOT_DEST
fill_required_headers "$fresh"
set +e
overlay_sysroot_finish "$tmp/sdk" "$fresh"
fin_st=$?
set -e
[ "$fin_st" -eq 0 ] && echo "  OK  finish rc=0" || { echo "  FAIL finish rc=$fin_st"; fail=1; }
need '[ -L "$tmp/sdk/MacOSX.sdk" ]' "live MacOSX.sdk is a symlink"
need '[ ! -f "$tmp/sdk/MacOSX.sdk/CANARY" ]' "canary is not in the new live tree"
stale=$(ls -d "$tmp/sdk"/MacOSX.sdk.stale-* 2>/dev/null | head -1)
if [ -n "$stale" ] && [ -f "$stale/CANARY" ]; then
  echo "  OK  canary displaced to $stale (not rm'd)"
  grep -q OPERATOR_CANARY "$stale/CANARY" \
    && echo "  OK  displaced tree still has OPERATOR_CANARY" \
    || { echo "  FAIL canary contents"; fail=1; }
else
  echo "  FAIL no stale tree with canary"
  ls -la "$tmp/sdk" || true
  fail=1
fi
grep -q fmaxl "$tmp/sdk/MacOSX.sdk/usr/include/math.h" \
  && echo "  OK  live math.h has fmaxl" || { echo "  FAIL live math.h"; fail=1; }
[ -f "$tmp/sdk/MacOSX.sdk/$OVERLAY_SYSROOT_STAMP" ] \
  && echo "  OK  live stamp written" || { echo "  FAIL no stamp"; fail=1; }
[ -f "$tmp/sdk/MacOSX.sdk/usr/lib/libSystem.B.tbd" ] \
  && echo "  OK  displace → tbds present in the new tree" \
  || { echo "  FAIL new tree missing libSystem.B.tbd"; ls -la "$tmp/sdk/MacOSX.sdk/usr/lib" || true; fail=1; }
grep -q 'install-name: /usr/lib/libSystem.B.dylib' "$tmp/sdk/MacOSX.sdk/usr/lib/libSystem.B.tbd" \
  && echo "  OK  copied tbd is the displaced stub" || { echo "  FAIL tbd contents"; fail=1; }
[ -f "$stale/usr/lib/libSystem.B.tbd" ] \
  && echo "  OK  displaced tree still has the tbd (not rm'd)" \
  || { echo "  FAIL stale missing tbd"; fail=1; }

echo
echo "=== matching stamp + complete headers → reuse, no second dest ==="
overlay_sysroot_begin "$tmp/sdk"
need '[ "${OVERLAY_SYSROOT_REUSE}" = 1 ]' "second begin reuses"
need '[ -f "$stale/CANARY" ]' "stale canary still exists after reuse"

echo
echo "=== tbd-only change in FE source → stamp=MISMATCH and restage ==="
fe=$W/scratch/sysroot_fe4-x86_64
mkdir -p "$fe/usr/lib" "$fe/usr/lib/swift/System.swiftmodule" "$fe/usr/lib/swift/Darwin.swiftmodule"
cat > "$fe/usr/lib/libSystem.B.tbd" <<'TBD'
--- !tapi-tbd-v3
archs: [ x86_64 ]
install-name: /usr/lib/libSystem.B.dylib
exports:
  - archs: [ x86_64 ]
    symbols: [ _fmaxl ]
TBD
ln -sfn libSystem.B.tbd "$fe/usr/lib/libSystem.tbd"
export SWIFTCORE_FE_SYSROOT=$fe
echo '--- !tapi-tbd-v3' > "$fe/usr/lib/swift/libswiftCore.tbd"
echo 'module System {}' > "$fe/usr/lib/swift/System.swiftmodule/x86_64-apple-macos.swiftinterface"
# Darwin is one of the twelve overlays the build produces itself: its
# swiftmodule must NOT be seeded into the SDK copy (resource-dir wins).
echo 'module Darwin {}' > "$fe/usr/lib/swift/Darwin.swiftmodule/x86_64-apple-macos.swiftinterface"

sdk_tbd=$tmp/sdkTbd
mkdir -p "$sdk_tbd"
overlay_sysroot_begin "$sdk_tbd" >"$tmp/begin_fe" 2>&1
st=$?
cat "$tmp/begin_fe"
[ "$st" -eq 0 ] && echo "  OK  first FE begin rc=0" || { echo "  FAIL first FE begin rc=$st"; fail=1; }
grep -q "overlay_sysroot: source=$fe tbd_sha=" "$tmp/begin_fe" \
  && echo "  OK  begin source=scratch/sysroot_fe4-x86_64" \
  || { echo "  FAIL begin source line"; cat "$tmp/begin_fe"; fail=1; }
grep -q 'tbd_sha=ABSENT' "$tmp/begin_fe" \
  && { echo "  FAIL tbd_sha=ABSENT with FE tbds present"; fail=1; } \
  || echo "  OK  tbd_sha is not ABSENT"
need '[ "${OVERLAY_SYSROOT_REUSE}" = 0 ]' "first FE begin restages"
fresh_fe=$OVERLAY_SYSROOT_DEST
fill_required_headers "$fresh_fe"
set +e
overlay_sysroot_finish "$sdk_tbd" "$fresh_fe" >"$tmp/fe.finish1" 2>&1
fin_st=$?
set -e
cat "$tmp/fe.finish1"
[ "$fin_st" -eq 0 ] && echo "  OK  first FE finish rc=0" || { echo "  FAIL first FE finish rc=$fin_st"; fail=1; }
grep -q '_fmaxl' "$sdk_tbd/MacOSX.sdk/usr/lib/libSystem.tbd" \
  && echo "  OK  dest libSystem.tbd came from FE source" \
  || { echo "  FAIL dest missing FE tbd"; fail=1; }
[ -f "$sdk_tbd/MacOSX.sdk/usr/lib/swift/libswiftCore.tbd" ] \
  && echo "  OK  dest has usr/lib/swift/libswiftCore.tbd" \
  || { echo "  FAIL dest missing swift tbd"; fail=1; }
[ -f "$sdk_tbd/MacOSX.sdk/usr/lib/swift/System.swiftmodule/x86_64-apple-macos.swiftinterface" ] \
  && echo "  OK  dest has System.swiftmodule slice" \
  || { echo "  FAIL dest missing swiftmodule"; fail=1; }
[ ! -e "$sdk_tbd/MacOSX.sdk/usr/lib/swift/Darwin.swiftmodule" ] \
  && echo "  OK  dest does not seed the self-built Darwin.swiftmodule" \
  || { echo "  FAIL dest seeded Darwin.swiftmodule (self-built overlay module must come from -resource-dir)"; fail=1; }
grep -q "overlay_sysroot: source=$fe tbd_sha=" "$tmp/fe.finish1" \
  && echo "  OK  finish print_headers source= FE sysroot" \
  || { echo "  FAIL finish source line"; fail=1; }
grep -q '^machorun.HEAD=' "$sdk_tbd/MacOSX.sdk/$OVERLAY_SYSROOT_STAMP" \
  && echo "  OK  stamp records machorun.HEAD (darwin tbds from gen_tbd)" \
  || { echo "  FAIL stamp missing machorun.HEAD"; fail=1; }
grep -q '^usr/lib/libSystem.tbd=' "$sdk_tbd/MacOSX.sdk/$OVERLAY_SYSROOT_STAMP" \
  && echo "  OK  stamp records usr/lib/libSystem.tbd" \
  || { echo "  FAIL stamp missing libSystem.tbd key"; cat "$sdk_tbd/MacOSX.sdk/$OVERLAY_SYSROOT_STAMP"; fail=1; }
grep -q '^usr/include/Darwin.modulemap=' "$sdk_tbd/MacOSX.sdk/$OVERLAY_SYSROOT_STAMP" \
  && echo "  OK  stamp records usr/include/Darwin.modulemap" \
  || { echo "  FAIL stamp missing Darwin.modulemap key"; cat "$sdk_tbd/MacOSX.sdk/$OVERLAY_SYSROOT_STAMP"; fail=1; }

echo
echo "=== nothing changed in FE source → stamp=MATCH ==="
overlay_sysroot_begin "$sdk_tbd" >"$tmp/begin_match" 2>&1
st=$?
cat "$tmp/begin_match"
[ "$st" -eq 0 ] && echo "  OK  MATCH begin rc=0" || { echo "  FAIL MATCH begin rc=$st"; fail=1; }
need '[ "${OVERLAY_SYSROOT_REUSE}" = 1 ]' "unchanged FE source reuses (stamp MATCH)"
grep -q 'stamp MATCH' "$tmp/begin_match" \
  && echo "  OK  begin printed stamp MATCH" \
  || { echo "  FAIL MATCH text"; cat "$tmp/begin_match"; fail=1; }
grep -q "overlay_sysroot: source=$fe tbd_sha=" "$tmp/begin_match" \
  && echo "  OK  MATCH run still prints source= tbd_sha=" \
  || { echo "  FAIL MATCH source line"; fail=1; }

echo
echo "=== only libSystem.tbd changes in FE source → stamp=MISMATCH, displace, restage ==="
# Simulate PR #67: gen_tbd / phase2 updated _fmal in the FE tree; overlay
# headers and HEAD:machorun are unchanged.
cat > "$fe/usr/lib/libSystem.B.tbd" <<'TBD'
--- !tapi-tbd-v3
archs: [ x86_64 ]
install-name: /usr/lib/libSystem.B.dylib
exports:
  - archs: [ x86_64 ]
    symbols: [ _fmaxl, _fmal ]
TBD
overlay_sysroot_begin "$sdk_tbd" >"$tmp/begin_mis" 2>&1
st=$?
cat "$tmp/begin_mis"
[ "$st" -eq 0 ] && echo "  OK  tbd-mismatch begin rc=0" || { echo "  FAIL tbd-mismatch begin rc=$st"; fail=1; }
need '[ "${OVERLAY_SYSROOT_REUSE}" = 0 ]' "tbd-only change restages (REUSE=0)"
grep -q 'overlay_sysroot: stamp=MISMATCH' "$tmp/begin_mis" \
  && echo "  OK  stamp=MISMATCH" \
  || { echo "  FAIL missing stamp=MISMATCH"; cat "$tmp/begin_mis"; fail=1; }
grep -qE 'overlay_sysroot: usr/lib/libSystem\.tbd [0-9a-f]+->[0-9a-f]+' "$tmp/begin_mis" \
  && echo "  OK  libSystem.tbd old->new" \
  || { echo "  FAIL libSystem.tbd diff"; cat "$tmp/begin_mis"; fail=1; }
grep -q 'overlay-darwin.math.h' "$tmp/begin_mis" \
  && { echo "  FAIL header keys also mismatched on tbd-only change"; fail=1; } \
  || echo "  OK  overlay-darwin headers did not mismatch"
need '[[ "$OVERLAY_SYSROOT_DEST" == *MacOSX.sdk.overlay-* ]]' "tbd mismatch fresh dest"
fresh_mis=$OVERLAY_SYSROOT_DEST
fill_required_headers "$fresh_mis"
set +e
overlay_sysroot_finish "$sdk_tbd" "$fresh_mis" >"$tmp/fe.finish2" 2>&1
fin_st=$?
set -e
cat "$tmp/fe.finish2"
[ "$fin_st" -eq 0 ] && echo "  OK  tbd restage finish rc=0" || { echo "  FAIL tbd restage finish rc=$fin_st"; fail=1; }
grep -q '_fmal' "$sdk_tbd/MacOSX.sdk/usr/lib/libSystem.tbd" \
  && echo "  OK  restaged dest libSystem.tbd has _fmal" \
  || { echo "  FAIL restaged dest still lacks _fmal"; fail=1; }
stale_tbd=$(ls -d "$sdk_tbd"/MacOSX.sdk.stale-* 2>/dev/null | head -1)
if [ -n "$stale_tbd" ] && [ -f "$stale_tbd/usr/lib/libSystem.B.tbd" ]; then
  echo "  OK  previous SDK displaced to $stale_tbd (not rm'd)"
  grep -q '_fmal' "$stale_tbd/usr/lib/libSystem.B.tbd" \
    && { echo "  FAIL displaced tree already has _fmal"; fail=1; } \
    || echo "  OK  displaced tree still has the pre-_fmal tbd"
else
  echo "  FAIL no stale tree after tbd restage"
  ls -la "$sdk_tbd" || true
  fail=1
fi

echo
echo "=== after tbd restage, nothing changed → MATCH again ==="
overlay_sysroot_begin "$sdk_tbd" >"$tmp/begin_again" 2>&1
st=$?
cat "$tmp/begin_again"
need '[ "${OVERLAY_SYSROOT_REUSE}" = 1 ]' "post-restage unchanged source MATCH"
grep -q 'stamp MATCH' "$tmp/begin_again" \
  && echo "  OK  post-restage stamp MATCH" \
  || { echo "  FAIL post-restage MATCH"; cat "$tmp/begin_again"; fail=1; }

echo
echo "=== Darwin.modulemap byte change in FE source → stamp=MISMATCH and restage ==="
# Operator box: main regenerated the unexpanded FE sysroot map, but
# sdk/MacOSX.sdk kept the expanded copy because the stamp keyed header
# names, not map bytes.
mkdir -p "$fe/usr/include"
echo 'module Darwin [system] { header "math.h" export * }' \
  > "$fe/usr/include/Darwin.modulemap"
overlay_sysroot_begin "$sdk_tbd" >"$tmp/begin_dmap" 2>&1
st=$?
cat "$tmp/begin_dmap"
[ "$st" -eq 0 ] && echo "  OK  Darwin.modulemap-mismatch begin rc=0" \
  || { echo "  FAIL Darwin.modulemap-mismatch begin rc=$st"; fail=1; }
need '[ "${OVERLAY_SYSROOT_REUSE}" = 0 ]' "Darwin.modulemap byte change restages (REUSE=0)"
grep -q 'overlay_sysroot: stamp=MISMATCH' "$tmp/begin_dmap" \
  && echo "  OK  Darwin.modulemap stamp=MISMATCH" \
  || { echo "  FAIL missing Darwin.modulemap stamp=MISMATCH"; cat "$tmp/begin_dmap"; fail=1; }
grep -qE 'overlay_sysroot: usr/include/Darwin.modulemap ' "$tmp/begin_dmap" \
  && echo "  OK  Darwin.modulemap old->new" \
  || { echo "  FAIL Darwin.modulemap diff"; cat "$tmp/begin_dmap"; fail=1; }
grep -q 'overlay-darwin.math.h' "$tmp/begin_dmap" \
  && { echo "  FAIL header keys also mismatched on Darwin.modulemap-only change"; fail=1; } \
  || echo "  OK  overlay-darwin headers did not mismatch"
fresh_dmap=$OVERLAY_SYSROOT_DEST
fill_required_headers "$fresh_dmap"
set +e
overlay_sysroot_finish "$sdk_tbd" "$fresh_dmap" >"$tmp/fe.finish_dmap" 2>&1
fin_st=$?
set -e
cat "$tmp/fe.finish_dmap"
[ "$fin_st" -eq 0 ] && echo "  OK  Darwin.modulemap restage finish rc=0" \
  || { echo "  FAIL Darwin.modulemap restage finish rc=$fin_st"; fail=1; }
grep -q '^usr/include/Darwin.modulemap=' "$sdk_tbd/MacOSX.sdk/$OVERLAY_SYSROOT_STAMP" \
  && ! grep -q '^usr/include/Darwin.modulemap=ABSENT$' "$sdk_tbd/MacOSX.sdk/$OVERLAY_SYSROOT_STAMP" \
  && echo "  OK  restaged stamp hashes FE Darwin.modulemap bytes" \
  || { echo "  FAIL restaged stamp still ABSENT or missing map key"; cat "$sdk_tbd/MacOSX.sdk/$OVERLAY_SYSROOT_STAMP"; fail=1; }

echo
echo "=== expanded Darwin.modulemap in FE source → MISMATCH again ==="
echo 'module Darwin [system] { header "math.h" header "unistd.h" export * }' \
  > "$fe/usr/include/Darwin.modulemap"
overlay_sysroot_begin "$sdk_tbd" >"$tmp/begin_dmap2" 2>&1
st=$?
cat "$tmp/begin_dmap2"
need '[ "${OVERLAY_SYSROOT_REUSE}" = 0 ]' "expanded Darwin.modulemap restages"
grep -q 'overlay_sysroot: stamp=MISMATCH' "$tmp/begin_dmap2" \
  && echo "  OK  expanded map stamp=MISMATCH" \
  || { echo "  FAIL expanded map did not mismatch"; cat "$tmp/begin_dmap2"; fail=1; }
fresh_dmap2=$OVERLAY_SYSROOT_DEST
fill_required_headers "$fresh_dmap2"
set +e
overlay_sysroot_finish "$sdk_tbd" "$fresh_dmap2" >"$tmp/fe.finish_dmap2" 2>&1
fin_st=$?
set -e
[ "$fin_st" -eq 0 ] && echo "  OK  expanded map restage finish rc=0" \
  || { echo "  FAIL expanded map restage finish rc=$fin_st"; fail=1; }
overlay_sysroot_begin "$sdk_tbd" >"$tmp/begin_dmap_match" 2>&1
need '[ "${OVERLAY_SYSROOT_REUSE}" = 1 ]' "unchanged Darwin.modulemap MATCH"
grep -q 'stamp MATCH' "$tmp/begin_dmap_match" \
  && echo "  OK  post-map-restage stamp MATCH" \
  || { echo "  FAIL post-map-restage MATCH"; cat "$tmp/begin_dmap_match"; fail=1; }

echo
echo "=== listed required header missing → refuse (not stamp MATCH) ==="
mkdir -p "$tmp/noCM/usr/lib"
fill_required_headers "$tmp/noCM"
echo '--- !tapi-tbd-v3' > "$tmp/noCM/usr/lib/libSystem.B.tbd"
rm -f "$tmp/noCM/usr/include/ConditionalMacros.h"
overlay_sysroot_write_stamp "$tmp/noCM"
set +e
print_cm=$(overlay_sysroot_print_headers "$tmp/noCM" 2>&1)
refuse_cm=$(overlay_sysroot_refuse_incomplete "$tmp/noCM" 2>&1)
st=$?
set -e
printf '%s\n' "$print_cm" | tail -15
printf '%s\n' "$refuse_cm"
[ "$st" -eq 2 ] && echo "  OK  missing ConditionalMacros.h refuse rc=2" \
  || { echo "  FAIL missing header rc=$st"; fail=1; }
printf '%s\n' "$refuse_cm" | grep -q 'CANNOT_OVERLAY_SYSROOT_HEADER' \
  && echo "  OK  CANNOT_OVERLAY_SYSROOT_HEADER" || { echo "  FAIL missing HEADER marker"; fail=1; }
printf '%s\n' "$refuse_cm" | grep -q 'usr/include/ConditionalMacros.h' \
  && echo "  OK  HEADER names ConditionalMacros.h" || { echo "  FAIL HEADER path"; fail=1; }
printf '%s\n' "$print_cm" | grep -q 'header usr/include/ConditionalMacros.h ABSENT' \
  && echo "  OK  print lists ConditionalMacros.h ABSENT" || { echo "  FAIL print ABSENT"; fail=1; }
printf '%s\n' "$print_cm" | grep -q 'stamp=MATCH recipe=' \
  && { echo "  FAIL stamp=MATCH while required header ABSENT"; fail=1; } \
  || echo "  OK  did not print stamp=MATCH for incomplete tree"
printf '%s\n' "$print_cm" | grep -q 'tree=INCOMPLETE' \
  && echo "  OK  stamp=MATCH-inputs tree=INCOMPLETE" \
  || { echo "  FAIL missing INCOMPLETE"; fail=1; }
if overlay_sysroot_tree_complete "$tmp/noCM"; then
  echo "  FAIL tree_complete true without ConditionalMacros.h"
  fail=1
else
  echo "  OK  tree_complete false"
fi

echo
echo "=== empty tbd set names the tree ==="
mkdir -p "$tmp/notbd"
fill_required_headers "$tmp/notbd"
# usr/lib exists from fill but has no .tbd
set +e
tbd_ref=$(overlay_sysroot_refuse_empty_tbds "$tmp/notbd" 2>&1)
st=$?
set -e
printf '%s\n' "$tbd_ref"
[ "$st" -eq 2 ] && echo "  OK  empty tbd refuse rc=2" || { echo "  FAIL tbd refuse rc=$st"; fail=1; }
printf '%s\n' "$tbd_ref" | grep -q 'CANNOT_OVERLAY_SYSROOT_TBDS' \
  && echo "  OK  CANNOT_OVERLAY_SYSROOT_TBDS" || { echo "  FAIL missing TBDS marker"; fail=1; }
printf '%s\n' "$tbd_ref" | grep -q "tree=$tmp/notbd" \
  && echo "  OK  TBDS refuse names the tree" || { echo "  FAIL TBDS tree path"; fail=1; }

echo
echo "=== modulemap header closure (Darwin Clang maps, not libc++) ==="
mkdir -p "$tmp/mm/usr/include" "$tmp/mm/usr/lib"
fill_required_headers "$tmp/mm"
echo '--- !tapi-tbd-v3' > "$tmp/mm/usr/lib/libSystem.B.tbd"
cat > "$tmp/mm/usr/include/DarwinFoundation1.modulemap" <<'EOF'
module _DarwinFoundation1 [system] {
  header "complex.h"
  export *
}
EOF
need '! overlay_sysroot_modulemap_headers_ok "$tmp/mm"' \
  "DarwinFoundation1 naming complex.h fails overlay closure before fill"
before=$(overlay_sysroot_modulemap_missing_headers "$tmp/mm" || true)
printf '%s\n' "$before" | grep -q 'complex.h' \
  && echo "  OK  missing=complex.h ($before)" \
  || { echo "  FAIL missing headers: $before"; fail=1; }
set +e
refuse_mm=$(overlay_sysroot_refuse_modulemap_headers "$tmp/mm" 2>&1)
st=$?
set -e
printf '%s\n' "$refuse_mm"
[ "$st" -eq 2 ] && echo "  OK  modulemap refuse rc=2" || { echo "  FAIL modulemap refuse rc=$st"; fail=1; }
printf '%s\n' "$refuse_mm" | grep -q 'CANNOT_OVERLAY_SYSROOT_MODULEMAP_HEADER' \
  && echo "  OK  CANNOT_OVERLAY_SYSROOT_MODULEMAP_HEADER" \
  || { echo "  FAIL missing MODULEMAP_HEADER marker"; fail=1; }
printf '%s\n' "$refuse_mm" | grep -q 'complex.h@usr/include/DarwinFoundation1.modulemap' \
  && echo "  OK  refuse names complex.h@DarwinFoundation1.modulemap" \
  || { echo "  FAIL refuse map attribution: $refuse_mm"; fail=1; }
if overlay_sysroot_tree_complete "$tmp/mm"; then
  echo "  FAIL tree_complete true with modulemap header missing"
  fail=1
else
  echo "  OK  tree_complete false while complex.h absent"
fi
overlay_sysroot_fill_modulemap_headers "$tmp/mm" | tee "$tmp/mm.fill"
grep -q 'staged modulemap header complex.h' "$tmp/mm.fill" \
  && echo "  OK  fill staged complex.h from sdk-gaps" \
  || { echo "  FAIL fill did not stage complex.h"; cat "$tmp/mm.fill"; fail=1; }
[ -f "$tmp/mm/usr/include/complex.h" ] \
  && echo "  OK  complex.h now on disk" || { echo "  FAIL complex.h still absent"; fail=1; }
cmp -s "$OPENUIKIT_ROOT/full/sdk-gaps/usr/include/complex.h" \
       "$tmp/mm/usr/include/complex.h" \
  && echo "  OK  complex.h is the sdk-gaps stub" || { echo "  FAIL complex.h contents"; fail=1; }
if overlay_sysroot_modulemap_headers_ok "$tmp/mm"; then
  echo "  OK  overlay closure after fill"
else
  echo "  FAIL still missing $(overlay_sysroot_modulemap_missing_headers "$tmp/mm" || true)"
  fail=1
fi
set +e
overlay_sysroot_refuse_modulemap_headers "$tmp/mm"
st=$?
set -e
[ "$st" -eq 0 ] && echo "  OK  refuse rc=0 after fill" || { echo "  FAIL refuse after fill rc=$st"; fail=1; }
if overlay_sysroot_tree_complete "$tmp/mm"; then
  echo "  OK  tree_complete after fill"
else
  echo "  FAIL tree_complete still false"
  fail=1
fi

echo
echo "=== libc++ modulemap naming algorithm does not refuse ==="
mkdir -p "$tmp/libcxx/usr/include/c++/v1" "$tmp/libcxx/usr/lib"
fill_required_headers "$tmp/libcxx"
echo '--- !tapi-tbd-v3' > "$tmp/libcxx/usr/lib/libSystem.B.tbd"
cat > "$tmp/libcxx/usr/include/c++/v1/module.modulemap" <<'EOF'
module std_algorithm [system] {
  header "algorithm"
  export *
}
EOF
# algorithm is not on disk; overlay compiles do not import std.
print_cxx=$(overlay_sysroot_print_modulemap_closure "$tmp/libcxx" 2>&1)
printf '%s\n' "$print_cxx"
printf '%s\n' "$print_cxx" | grep -q 'modulemap skip usr/include/c++/v1/module.modulemap' \
  && echo "  OK  skip names c++/v1/module.modulemap" \
  || { echo "  FAIL no skip for libc++ map"; fail=1; }
printf '%s\n' "$print_cxx" | grep -q 'modulemap missing header=algorithm' \
  && { echo "  FAIL overlay closure walked libc++ algorithm"; fail=1; } \
  || echo "  OK  algorithm is not an overlay missing header"
printf '%s\n' "$print_cxx" | grep -q 'modulemap headers complete' \
  && echo "  OK  Darwin overlay maps complete with libc++ map present" \
  || { echo "  FAIL libc++ map broke overlay complete"; fail=1; }
set +e
refuse_cxx=$(overlay_sysroot_refuse_modulemap_headers "$tmp/libcxx" 2>&1)
st=$?
set -e
printf '%s\n' "$refuse_cxx"
[ "$st" -eq 0 ] && echo "  OK  libc++ map refuse rc=0" \
  || { echo "  FAIL libc++ map refuse rc=$st"; fail=1; }
printf '%s\n' "$refuse_cxx" | grep -q 'CANNOT_OVERLAY_SYSROOT_MODULEMAP_HEADER' \
  && { echo "  FAIL libc++ map produced CANNOT"; fail=1; } \
  || echo "  OK  no CANNOT for libc++-only missing names"
if overlay_sysroot_tree_complete "$tmp/libcxx"; then
  echo "  OK  tree_complete with libc++ map outside closure"
else
  echo "  FAIL tree_complete false despite Darwin maps complete"
  fail=1
fi
# phase2's all-maps walk still sees algorithm (proves we scoped, not deleted the map)
phase2_miss=$(phase2_darwin_modulemap_missing_headers "$tmp/libcxx" || true)
printf '%s\n' "$phase2_miss" | grep -q 'algorithm' \
  && echo "  OK  phase2 all-maps walk still names algorithm (out of overlay scope)" \
  || { echo "  FAIL phase2 miss=$phase2_miss"; fail=1; }

echo
echo "=== configure.sh refuses before cmake when modulemap header is missing ==="
mkdir -p "$W/swift-experimental-string-processing/Sources/_StringProcessing"
mkdir -p "$W/libdispatch"
touch "$W/libdispatch/CMakeLists.txt"
mkdir -p "$W/sdk/MacOSX.sdk/usr/include/sys" "$W/sdk/MacOSX.sdk/usr/lib"
fill_required_headers "$W/sdk/MacOSX.sdk"
echo '--- !tapi-tbd-v3' > "$W/sdk/MacOSX.sdk/usr/lib/libSystem.B.tbd"
cat > "$W/sdk/MacOSX.sdk/usr/include/DarwinFoundation1.modulemap" <<'EOF'
module _DarwinFoundation1 [system] { header "complex.h" export * }
EOF
set +e
out=$(
  SWIFTCORE_OVERLAYS=1 SWIFTCORE_DARWIN_ARCH=x86_64 \
    W="$W" B="$W/build-mm" \
    bash "$SCRIPT_DIR/configure.sh" 2>&1
)
rc=$?
set -e
printf '%s\n' "$out" | tail -20
[ "$rc" -eq 2 ] && echo "  OK  configure modulemap rc=2" || { echo "  FAIL configure modulemap rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q 'CANNOT_OVERLAY_SYSROOT_MODULEMAP_HEADER' \
  && echo "  OK  configure named MODULEMAP_HEADER" \
  || { echo "  FAIL configure MODULEMAP_HEADER"; fail=1; }
printf '%s\n' "$out" | grep -q 'complex.h@usr/include/DarwinFoundation1.modulemap' \
  && echo "  OK  configure names map for complex.h" \
  || { echo "  FAIL configure map attribution"; fail=1; }
[ -f "$W/configure.log" ] && grep -q cmake "$W/configure.log" 2>/dev/null \
  && { echo "  FAIL cmake ran after modulemap refuse"; fail=1; } \
  || echo "  OK  cmake not invoked after modulemap refuse"

echo
echo "=== stage_sdk.sh does not rm -rf \$W/sdk ==="
if grep -n 'rm -rf "$W/sdk"' "$SCRIPT_DIR/stage_sdk.sh"; then
  echo "  FAIL stage_sdk.sh still rm -rf \$W/sdk"
  fail=1
else
  echo "  OK  no rm -rf \$W/sdk"
fi

echo
echo "=== stage_sdk.sh does not flatten include_next wrappers onto usr/include ==="
if grep -nF 'install -D {} "$SDK/usr/include/{}"' "$SCRIPT_DIR/stage_sdk.sh"; then
  echo "  FAIL stage_sdk.sh still install -D objc4-priv onto usr/include"
  fail=1
else
  echo "  OK  no flatten install -D onto usr/include"
fi
grep -q 'overlay_sysroot_install_objc4_priv' "$SCRIPT_DIR/stage_sdk.sh" \
  && echo "  OK  stage_sdk calls overlay_sysroot_install_objc4_priv" \
  || { echo "  FAIL stage_sdk missing overlay_sysroot_install_objc4_priv"; fail=1; }

echo
echo "=== include_next wrapper predicate: objc4 vs Apple limits.h ==="
wrap=$OPENUIKIT_ROOT/machorun/vendor/objc4-priv/crt_externs.h
pub=$OPENUIKIT_ROOT/machorun/sdk/usr/include/crt_externs.h
apple_limits=$OPENUIKIT_ROOT/machorun/sdk/usr/include/limits.h
machine_limits=$OPENUIKIT_ROOT/machorun/sdk/usr/include/machine/limits.h
i386_limits=$OPENUIKIT_ROOT/machorun/sdk/usr/include/i386/limits.h
arm_limits=$OPENUIKIT_ROOT/machorun/sdk/usr/include/arm/limits.h
need '[ -f "$wrap" ]' "objc4-priv crt_externs.h present"
need '[ -f "$pub" ]' "machorun-sdk public crt_externs.h present"
need '[ -f "$apple_limits" ]' "Apple limits.h present"
need '[ -f "$machine_limits" ]' "machine/limits.h present"
need '[ -f "$i386_limits" ]' "i386/limits.h present"
need '[ -f "$arm_limits" ]' "arm/limits.h present"
overlay_sysroot_is_include_next_wrapper "$wrap" \
  && echo "  OK  objc4-priv crt_externs.h is the wrapper shape" \
  || { echo "  FAIL objc4 wrapper not recognized"; fail=1; }
overlay_sysroot_is_include_next_wrapper "$pub" \
  && { echo "  FAIL public crt_externs.h classified as wrapper"; fail=1; } \
  || echo "  OK  public crt_externs.h is not a wrapper"
overlay_sysroot_is_include_next_wrapper "$apple_limits" \
  && { echo "  FAIL Apple limits.h classified as wrapper"; fail=1; } \
  || echo "  OK  Apple limits.h is not a wrapper"
overlay_sysroot_is_include_next_wrapper "$machine_limits" \
  && { echo "  FAIL machine/limits.h classified as wrapper"; fail=1; } \
  || echo "  OK  machine/limits.h is not a wrapper"
overlay_sysroot_is_include_next_wrapper "$i386_limits" \
  && { echo "  FAIL i386/limits.h classified as wrapper (buried include_next)"; fail=1; } \
  || echo "  OK  i386/limits.h is not a wrapper"
overlay_sysroot_is_include_next_wrapper "$arm_limits" \
  && { echo "  FAIL arm/limits.h classified as wrapper (buried include_next)"; fail=1; } \
  || echo "  OK  arm/limits.h is not a wrapper"
grep -q include_next "$i386_limits" \
  && echo "  OK  i386/limits.h still contains include_next (clang resource dir)" \
  || { echo "  FAIL i386/limits.h lost include_next"; fail=1; }

echo
echo "=== Apple limits.h + machine/limits.h, only i386/limits.h → complete on x86_64 ==="
mkdir -p "$tmp/lim/usr/include/machine" "$tmp/lim/usr/include/i386" \
  "$tmp/lim/usr/lib"
fill_required_headers "$tmp/lim"
echo '--- !tapi-tbd-v3' > "$tmp/lim/usr/lib/libSystem.B.tbd"
cp "$apple_limits" "$tmp/lim/usr/include/limits.h"
cp "$machine_limits" "$tmp/lim/usr/include/machine/limits.h"
cp "$i386_limits" "$tmp/lim/usr/include/i386/limits.h"
need '[ ! -e "$tmp/lim/usr/include/arm/limits.h" ]' \
  "arm/limits.h absent (x86_64-only sysroot)"
SWIFTCORE_DARWIN_ARCH=x86_64
if overlay_sysroot_tree_complete "$tmp/lim"; then
  echo "  OK  tree_complete true (Apple limits.h, no arm/limits.h)"
else
  echo "  FAIL tree_complete false on Apple limits.h x86_64 shape"
  overlay_sysroot_include_next_missing_entries "$tmp/lim" || true
  fail=1
fi
set +e
print_lim=$(overlay_sysroot_print_headers "$tmp/lim" 2>&1)
refuse_lim=$(overlay_sysroot_refuse_incomplete "$tmp/lim" 2>&1)
st=$?
set -e
[ "$st" -eq 0 ] && echo "  OK  Apple limits.h refuse rc=0" \
  || { echo "  FAIL Apple limits.h refuse rc=$st"; printf '%s\n' "$refuse_lim"; fail=1; }
printf '%s\n' "$refuse_lim" | grep -q CANNOT_OVERLAY_SYSROOT_INCLUDE_NEXT \
  && { echo "  FAIL Apple limits.h still INCLUDE_NEXT"; printf '%s\n' "$refuse_lim"; fail=1; } \
  || echo "  OK  Apple limits.h is not INCLUDE_NEXT"
printf '%s\n' "$print_lim$refuse_lim" | grep -q 'limits.h@usr/include/' \
  && { echo "  FAIL still attributes missing limits.h"; printf '%s\n' "$print_lim$refuse_lim"; fail=1; } \
  || echo "  OK  did not name i386/arm limits.h as a missing wrapper"
mkdir -p "$tmp/lim/usr/include/arm"
cp "$arm_limits" "$tmp/lim/usr/include/arm/limits.h"
if overlay_sysroot_tree_complete "$tmp/lim"; then
  echo "  OK  tree_complete still true with off-arch arm/limits.h present"
else
  echo "  FAIL arm/limits.h presence made tree incomplete"
  overlay_sysroot_include_next_missing_entries "$tmp/lim" || true
  fail=1
fi

echo
echo "=== objc4-priv include_next wrapper at usr/include is refused ==="
need '[ -f "$wrap" ]' "objc4-priv crt_externs.h present"
need '[ -f "$pub" ]' "machorun-sdk public crt_externs.h present"
grep -q include_next "$wrap" \
  && echo "  OK  objc4-priv crt_externs.h is include_next wrapper" \
  || { echo "  FAIL wrapper lacks include_next"; fail=1; }
grep -q include_next "$pub" \
  && { echo "  FAIL public crt_externs.h has include_next"; fail=1; } \
  || echo "  OK  public crt_externs.h has no include_next"
mkdir -p "$tmp/crtwrap/usr/include" "$tmp/crtwrap/usr/lib"
fill_required_headers "$tmp/crtwrap"
echo '--- !tapi-tbd-v3' > "$tmp/crtwrap/usr/lib/libSystem.B.tbd"
cp "$wrap" "$tmp/crtwrap/usr/include/crt_externs.h"
overlay_sysroot_write_stamp "$tmp/crtwrap"
if overlay_sysroot_tree_complete "$tmp/crtwrap"; then
  echo "  FAIL tree_complete true with wrapper-only crt_externs.h"
  fail=1
else
  echo "  OK  tree_complete false (wrapper target absent)"
fi
set +e
print_wrap=$(overlay_sysroot_print_headers "$tmp/crtwrap" 2>&1)
refuse_wrap=$(overlay_sysroot_refuse_incomplete "$tmp/crtwrap" 2>&1)
st=$?
set -e
printf '%s\n' "$print_wrap" | grep -q 'include_next missing header=crt_externs.h' \
  && echo "  OK  print names missing crt_externs.h" \
  || { echo "  FAIL print include_next"; printf '%s\n' "$print_wrap" | tail -20; fail=1; }
[ "$st" -eq 2 ] && echo "  OK  wrapper-only refuse rc=2" \
  || { echo "  FAIL wrapper-only refuse rc=$st"; printf '%s\n' "$refuse_wrap"; fail=1; }
printf '%s\n' "$refuse_wrap" | grep -q 'CANNOT_OVERLAY_SYSROOT_INCLUDE_NEXT' \
  && echo "  OK  CANNOT_OVERLAY_SYSROOT_INCLUDE_NEXT" \
  || { echo "  FAIL missing INCLUDE_NEXT marker"; printf '%s\n' "$refuse_wrap"; fail=1; }
printf '%s\n' "$refuse_wrap" | grep -q 'crt_externs.h@usr/include/crt_externs.h' \
  && echo "  OK  missing names wrapper path" \
  || { echo "  FAIL missing attribution"; printf '%s\n' "$refuse_wrap"; fail=1; }

echo
echo "=== fill_include_next_wrappers restores public header behind wrapper ==="
overlay_sysroot_fill_include_next_wrappers "$tmp/crtwrap" | tee "$tmp/crt.fill"
grep -q 'usr/local/include' "$tmp/crt.fill" \
  && echo "  OK  fill moved wrapper to usr/local/include" \
  || { echo "  FAIL fill did not mention usr/local/include"; cat "$tmp/crt.fill"; fail=1; }
need '[ -f "$tmp/crtwrap/usr/local/include/crt_externs.h" ]' \
  "wrapper at usr/local/include/crt_externs.h"
need '[ -f "$tmp/crtwrap/usr/include/crt_externs.h" ]' \
  "public header at usr/include/crt_externs.h"
overlay_sysroot_is_include_next_wrapper "$tmp/crtwrap/usr/local/include/crt_externs.h" \
  && echo "  OK  usr/local/include/crt_externs.h is the wrapper" \
  || { echo "  FAIL usr/local is not the wrapper"; fail=1; }
overlay_sysroot_is_include_next_wrapper "$tmp/crtwrap/usr/include/crt_externs.h" \
  && { echo "  FAIL usr/include still the wrapper"; fail=1; } \
  || echo "  OK  usr/include/crt_externs.h is not the wrapper"
grep -q _NSGetArgc "$tmp/crtwrap/usr/include/crt_externs.h" \
  && echo "  OK  usr/include declares _NSGetArgc" \
  || { echo "  FAIL public header lacks _NSGetArgc"; fail=1; }
if overlay_sysroot_tree_complete "$tmp/crtwrap"; then
  echo "  OK  tree_complete true after fill"
else
  echo "  FAIL tree_complete false after fill"
  fail=1
fi
set +e
refuse_filled=$(overlay_sysroot_refuse_incomplete "$tmp/crtwrap" 2>&1)
st=$?
set -e
[ "$st" -eq 0 ] && echo "  OK  filled refuse rc=0" \
  || { echo "  FAIL filled refuse rc=$st"; printf '%s\n' "$refuse_filled"; fail=1; }
printf '%s\n' "$refuse_filled" | grep -q CANNOT_OVERLAY_SYSROOT_INCLUDE_NEXT \
  && { echo "  FAIL filled still INCLUDE_NEXT"; printf '%s\n' "$refuse_filled"; fail=1; } \
  || echo "  OK  filled is not INCLUDE_NEXT"

echo
echo "=== working copy (public header only, no wrapper) still complete ==="
mkdir -p "$tmp/crtpub/usr/include" "$tmp/crtpub/usr/lib"
fill_required_headers "$tmp/crtpub"
echo '--- !tapi-tbd-v3' > "$tmp/crtpub/usr/lib/libSystem.B.tbd"
cp "$pub" "$tmp/crtpub/usr/include/crt_externs.h"
if overlay_sysroot_tree_complete "$tmp/crtpub"; then
  echo "  OK  public-only tree_complete true"
else
  echo "  FAIL public-only tree_complete false"
  fail=1
fi
set +e
refuse_pub=$(overlay_sysroot_refuse_incomplete "$tmp/crtpub" 2>&1)
st=$?
set -e
[ "$st" -eq 0 ] && echo "  OK  public-only refuse rc=0" \
  || { echo "  FAIL public-only refuse rc=$st"; printf '%s\n' "$refuse_pub"; fail=1; }

echo
echo "=== overlay_sysroot_install_objc4_priv keeps public usr/include ==="
mkdir -p "$tmp/privsrc" "$tmp/sdkinst/usr/include/os"
cp "$wrap" "$tmp/privsrc/crt_externs.h"
mkdir -p "$tmp/privsrc/os"
echo '/* not a wrapper */' > "$tmp/privsrc/os/lock_private.h"
echo '/* public from machorun-sdk step 1 */' > "$tmp/sdkinst/usr/include/crt_externs.h"
echo '_NSGetArgc public' >> "$tmp/sdkinst/usr/include/crt_externs.h"
overlay_sysroot_install_objc4_priv "$tmp/privsrc" "$tmp/sdkinst"
need '[ -f "$tmp/sdkinst/usr/local/include/crt_externs.h" ]' \
  "install put wrapper at usr/local/include"
need '[ -f "$tmp/sdkinst/usr/include/os/lock_private.h" ]' \
  "non-wrapper priv header still at usr/include"
overlay_sysroot_is_include_next_wrapper "$tmp/sdkinst/usr/local/include/crt_externs.h" \
  && echo "  OK  installed wrapper is include_next" \
  || { echo "  FAIL installed usr/local is not wrapper"; fail=1; }
overlay_sysroot_is_include_next_wrapper "$tmp/sdkinst/usr/include/crt_externs.h" \
  && { echo "  FAIL install overwrote usr/include with wrapper"; fail=1; } \
  || echo "  OK  usr/include crt_externs.h not overwritten"
grep -q '_NSGetArgc public' "$tmp/sdkinst/usr/include/crt_externs.h" \
  && echo "  OK  step-1 public header preserved" \
  || { echo "  FAIL public header lost"; fail=1; }

echo
echo "=== clang -isysroot finds public crt_externs.h via include_next ==="
clang18=$(command -v clang-18 || true)
if [ -n "$clang18" ]; then
  clang_sdk=$tmp/clangsdk
  mkdir -p "$clang_sdk"
  cp -a "$OPENUIKIT_ROOT/machorun/sdk/usr" "$clang_sdk/usr"
  mkdir -p "$clang_sdk/usr/local/include"
  cp "$pub" "$clang_sdk/usr/include/crt_externs.h"
  cp "$wrap" "$clang_sdk/usr/local/include/crt_externs.h"
  printf '%s\n' '#include <crt_externs.h>' > "$tmp/crt_probe.c"
  set +e
  pre=$("$clang18" -target x86_64-apple-macos13.0 -isysroot "$clang_sdk" \
    -E "$tmp/crt_probe.c" 2>"$tmp/crt_probe.err")
  st=$?
  set -e
  [ "$st" -eq 0 ] && echo "  OK  clang -E rc=0" \
    || { echo "  FAIL clang -E rc=$st"; cat "$tmp/crt_probe.err"; fail=1; }
  printf '%s\n' "$pre" | grep -q _NSGetArgc \
    && echo "  OK  clang -E sees _NSGetArgc (public header via include_next)" \
    || { echo "  FAIL clang -E missing _NSGetArgc"; fail=1; }
  printf '%s\n' "$pre" | grep -q __progname \
    && echo "  OK  clang -E sees __progname (objc4-priv wrapper)" \
    || { echo "  FAIL clang -E missing wrapper __progname"; fail=1; }
  printf '%s\n' "$pre" | grep -q usr/local/include/crt_externs.h \
    && echo "  OK  -E entered usr/local/include wrapper first" \
    || { echo "  FAIL -E did not enter usr/local/include"; fail=1; }
  printf '%s\n' "$pre" | grep -q usr/include/crt_externs.h \
    && echo "  OK  -E include_next'd usr/include public header" \
    || { echo "  FAIL -E did not reach usr/include"; fail=1; }
  # Wrapper-only (the restage bug): same -E must fail at include_next.
  mkdir -p "$tmp/clangbad/usr/include"
  cp "$wrap" "$tmp/clangbad/usr/include/crt_externs.h"
  set +e
  "$clang18" -target x86_64-apple-macos13.0 -isysroot "$tmp/clangbad" \
    -E "$tmp/crt_probe.c" >/dev/null 2>"$tmp/crt_probe_bad.err"
  badst=$?
  set -e
  if grep -q "file not found" "$tmp/crt_probe_bad.err"; then
    echo "  OK  wrapper-only clang -E fails at include_next (operator shape)"
  else
    echo "  FAIL wrapper-only clang -E did not reproduce crt_externs.h file not found"
    echo "  rc=$badst"
    cat "$tmp/crt_probe_bad.err" | head -20
    fail=1
  fi
  grep -q 'crt_externs.h:13:15' "$tmp/crt_probe_bad.err" \
    && echo "  OK  error is crt_externs.h:13:15" \
    || { echo "  FAIL error is not crt_externs.h:13:15"; cat "$tmp/crt_probe_bad.err"; fail=1; }
  [ "$badst" -ne 0 ] && echo "  OK  wrapper-only clang -E rc!=0" \
    || { echo "  FAIL wrapper-only clang -E succeeded"; fail=1; }
else
  echo "  skip clang -E (no clang-18)"
fi

echo
echo "=== configure.sh refuses before cmake when math.h lacks fmaxl ==="
cfg=$SCRIPT_DIR/configure.sh
mkdir -p "$W/swift-experimental-string-processing/Sources/_StringProcessing"
mkdir -p "$W/libdispatch"
touch "$W/libdispatch/CMakeLists.txt"
mkdir -p "$W/sdk/MacOSX.sdk/usr/include/sys"
echo '/* clean-room */' > "$W/sdk/MacOSX.sdk/usr/include/math.h"
echo 'struct proc { int p; };' > "$W/sdk/MacOSX.sdk/usr/include/sys/proc.h"
set +e
out=$(
  SWIFTCORE_OVERLAYS=1 SWIFTCORE_DARWIN_ARCH=x86_64 \
    W="$W" B="$W/build" \
    bash "$cfg" 2>&1
)
rc=$?
set -e
printf '%s\n' "$out" | tail -30
[ "$rc" -eq 2 ] && echo "  OK  configure rc=2" || { echo "  FAIL configure rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q 'CANNOT_OVERLAY_SYSROOT_MATH_H' \
  && echo "  OK  configure named MATH_H" || { echo "  FAIL configure MATH_H"; fail=1; }
printf '%s\n' "$out" | grep -q 'CANNOT_OVERLAY_SYSROOT_PROC_H' \
  && echo "  OK  configure named PROC_H" || { echo "  FAIL configure PROC_H"; fail=1; }
printf '%s\n' "$out" | grep -q 'overlay_sysroot: header usr/include/math.h present' \
  && echo "  OK  configure printed math.h sha before refuse" \
  || { echo "  FAIL configure did not print headers"; fail=1; }
[ -f "$W/configure.log" ] && grep -q cmake "$W/configure.log" 2>/dev/null \
  && { echo "  FAIL cmake ran after overlay sysroot refuse"; fail=1; } \
  || echo "  OK  cmake not invoked"

echo
echo "=== ninja Darwin.o -sdk / -isysroot extracted from -t commands ==="
fake=$tmp/bin
mkdir -p "$fake" "$tmp/ninjabuild"
cat > "$fake/ninja" <<'EOF'
#!/bin/bash
args=("$@")
i=0
tool=""
node=""
while [ $i -lt ${#args[@]} ]; do
  a=${args[$i]}
  case "$a" in
    -C) i=$((i+2)); continue ;;
    -t)
      i=$((i+1)); tool=${args[$i]:-}; i=$((i+1)); continue ;;
    *) node=$a; i=$((i+1)); continue ;;
  esac
done
if [ "$tool" = commands ]; then
  echo "swiftc -target x86_64-apple-macos15.0 -sdk /root/work/sdk/MacOSX.sdk -c Darwin.swift"
  echo "clang -isysroot /root/work/sdk/MacOSX.sdk -c magic.c"
  exit 0
fi
exit 0
EOF
chmod +x "$fake/ninja"
set +e
out=$(NINJA="$fake/ninja" overlay_print_isysroot_from_ninja "$tmp/ninjabuild" x86_64)
st=$?
set -e
printf '%s\n' "$out"
[ "$st" -eq 0 ] && echo "  OK  print_isysroot rc=0" || { echo "  FAIL print_isysroot rc=$st"; fail=1; }
printf '%s\n' "$out" | grep -q -- '-sdk=/root/work/sdk/MacOSX.sdk' \
  && echo "  OK  printed -sdk from ninja commands" || { echo "  FAIL missing -sdk"; fail=1; }
printf '%s\n' "$out" | grep -q -- '-isysroot=/root/work/sdk/MacOSX.sdk' \
  && echo "  OK  printed -isysroot from ninja commands" || { echo "  FAIL missing -isysroot"; fail=1; }

echo
echo "=== ninja Darwin dylib link is printed and -soname rewritten ==="
cat > "$fake/ninja" <<'EOF'
#!/bin/bash
args=("$@")
i=0
tool=""
node=""
while [ $i -lt ${#args[@]} ]; do
  a=${args[$i]}
  case "$a" in
    -C) i=$((i+2)); continue ;;
    -t)
      i=$((i+1)); tool=${args[$i]:-}; i=$((i+1)); continue ;;
    *) node=$a; i=$((i+1)); continue ;;
  esac
done
if [ "$tool" = commands ]; then
  echo "clang++ -target x86_64-apple-macosx13.0 -isysroot /root/work/sdk/MacOSX.sdk -L/usr/lib/llvm-18/lib -shared -Wl,-soname,libswiftDarwin.so -o lib/swift/macosx/x86_64/libswiftDarwin.so Darwin.o"
  exit 0
fi
exit 0
EOF
chmod +x "$fake/ninja"
set +e
out=$(NINJA="$fake/ninja" overlay_print_darwin_link_from_ninja "$tmp/ninjabuild" x86_64)
st=$?
set -e
printf '%s\n' "$out"
[ "$st" -eq 0 ] && echo "  OK  print_darwin_link rc=0" || { echo "  FAIL print_darwin_link rc=$st"; fail=1; }
printf '%s\n' "$out" | grep -q 'overlay_link: ninja' \
  && echo "  OK  printed ninja Darwin link" || { echo "  FAIL missing ninja link"; fail=1; }
printf '%s\n' "$out" | grep -q -- '-Wl,-soname,libswiftDarwin.so' \
  && echo "  OK  ninja line has -soname" || { echo "  FAIL ninja line missing -soname"; fail=1; }
printf '%s\n' "$out" | grep -q 'overlay_link: driver argv' \
  && echo "  OK  printed driver argv" || { echo "  FAIL missing driver argv"; fail=1; }
printf '%s\n' "$out" | grep 'overlay_link: driver argv' | grep -Eq -- '(^|[[:space:]])(-Wl,)?-?-soname' \
  && { echo "  FAIL driver argv still has GNU -soname"; fail=1; } \
  || echo "  OK  driver argv dropped GNU -soname"
printf '%s\n' "$out" | grep 'overlay_link: driver argv' | grep -q -- '-Wl,-install_name,/usr/lib/swift/libswiftDarwin.dylib' \
  && echo "  OK  driver argv has -install_name" \
  || { echo "  FAIL driver argv missing -install_name"; fail=1; }
printf '%s\n' "$out" | grep 'overlay_link: driver argv' | grep -q -- '-dynamiclib' \
  && { echo "  FAIL driver argv injected -dynamiclib"; fail=1; } \
  || echo "  OK  did not inject -dynamiclib"
printf '%s\n' "$out" | grep -q 'rewritten argv:' \
  && { echo "  FAIL Darwin logged rewritten argv"; fail=1; } \
  || echo "  OK  no rewritten argv for Darwin"
printf '%s\n' "$out" | grep -q 'clangxx_darwin_link: -o lib/swift/macosx/x86_64/libswiftDarwin.so decision=darwin linker=ld64.lld' \
  && echo "  OK  apple-target .so printed decision=darwin linker=ld64.lld" \
  || { echo "  FAIL missing -o decision=darwin line"; fail=1; }
printf '%s\n' "$out" | grep 'overlay_link: driver argv' | grep -q '/usr/lib/llvm-18/lib' \
  && { echo "  FAIL driver argv kept host /usr/lib/llvm-18/lib"; fail=1; } \
  || echo "  OK  dropped host -L/usr/lib/llvm-18/lib"
printf '%s\n' "$out" | grep -q 'clangxx_darwin_link: cxx_runtime=/root/work/sdk/MacOSX.sdk/usr/lib/libc++.tbd' \
  && echo "  OK  cxx_runtime= sysroot libc++.tbd" \
  || { echo "  FAIL missing cxx_runtime tbd"; fail=1; }
printf '%s\n' "$out" | grep -q 'clangxx_darwin_link: compiler_rt=' \
  && printf '%s\n' "$out" | grep 'overlay_link: driver argv' | grep -q 'libclang_rt.osx.a' \
  && echo "  OK  driver argv passes compiler-rt builtins" \
  || { echo "  FAIL missing compiler_rt / libclang_rt.osx.a on Darwin link"; fail=1; }

echo
echo "=== cmake : && clang++ && : wrapper is stripped before rewrite ==="
cat > "$fake/ninja" <<'EOF'
#!/bin/bash
args=("$@")
i=0
tool=""
while [ $i -lt ${#args[@]} ]; do
  a=${args[$i]}
  case "$a" in
    -C) i=$((i+2)); continue ;;
    -t)
      i=$((i+1)); tool=${args[$i]:-}; i=$((i+1)); continue ;;
    *) i=$((i+1)); continue ;;
  esac
done
if [ "$tool" = commands ]; then
  echo ": && /root/work/shims/clang++ -target x86_64-apple-macosx13.0 -isysroot /root/work/sdk/MacOSX.sdk -L/usr/lib/llvm-18/lib -shared -Wl,-soname,libswiftDarwin.so -o lib/swift/macosx/x86_64/libswiftDarwin.so Darwin.o && :"
  exit 0
fi
exit 0
EOF
chmod +x "$fake/ninja"
set +e
out=$(NINJA="$fake/ninja" overlay_print_darwin_link_from_ninja "$tmp/ninjabuild" x86_64)
st=$?
set -e
printf '%s\n' "$out"
[ "$st" -eq 0 ] && echo "  OK  cmake-wrapper print rc=0" || { echo "  FAIL cmake-wrapper rc=$st"; fail=1; }
printf '%s\n' "$out" | grep 'overlay_link: driver argv' | grep -q '&&' \
  && { echo "  FAIL driver argv kept cmake && wrapper"; fail=1; } \
  || echo "  OK  driver argv dropped cmake && wrapper"
printf '%s\n' "$out" | grep -q 'decision=darwin linker=ld64.lld' \
  && echo "  OK  wrapper line classifies apple-target .so as darwin" \
  || { echo "  FAIL wrapper rewrite"; fail=1; }
printf '%s\n' "$out" | grep 'overlay_link: driver argv' | grep -q '/usr/lib/llvm-18/lib' \
  && { echo "  FAIL wrapper driver argv kept host llvm-18/lib"; fail=1; } \
  || echo "  OK  wrapper dropped host -L/usr/lib/llvm-18/lib"

echo
echo "=== ninja -t commands >2MB is not passed as python argv (E2BIG→126) ==="
# ARG_MAX is 2 MiB on this host. Passing ninja -t commands as sys.argv
# made python3 die with "Argument list too long" and bash rc=126.
cat > "$fake/ninja" <<'EOF'
#!/bin/bash
args=("$@")
i=0
tool=""
while [ $i -lt ${#args[@]} ]; do
  a=${args[$i]}
  case "$a" in
    -C) i=$((i+2)); continue ;;
    -t)
      i=$((i+1)); tool=${args[$i]:-}; i=$((i+1)); continue ;;
    *) i=$((i+1)); continue ;;
  esac
done
if [ "$tool" = commands ]; then
  python3 -c 'import sys; sys.stdout.write("padding " * 400000); sys.stdout.write("\n")'
  echo "clang++ -target x86_64-apple-macosx13.0 -isysroot /root/work/sdk/MacOSX.sdk -L/usr/lib/llvm-18/lib -shared -Wl,-soname,libswiftDarwin.so -o lib/swift/macosx/x86_64/libswiftDarwin.so Darwin.o"
  exit 0
fi
exit 0
EOF
chmod +x "$fake/ninja"
set +e
out=$(NINJA="$fake/ninja" overlay_print_darwin_link_from_ninja "$tmp/ninjabuild" x86_64)
st=$?
set -e
printf '%s\n' "$out" | grep '^overlay_link:' | head -5
[ "$st" -eq 0 ] && echo "  OK  >2MB commands print rc=0 (not 126)" \
  || { echo "  FAIL >2MB commands rc=$st"; fail=1; }
[ "$st" -eq 126 ] && { echo "  FAIL E2BIG still reported as rc=126"; fail=1; } || true
printf '%s\n' "$out" | grep -q 'Argument list too long' \
  && { echo "  FAIL python still got E2BIG"; fail=1; } \
  || echo "  OK  no Argument list too long"
printf '%s\n' "$out" | grep -q 'decision=darwin linker=ld64.lld' \
  && echo "  OK  huge commands still classified Darwin" \
  || { echo "  FAIL huge commands lost the clang++ line"; fail=1; }

echo
echo "=== overlay FAILED dep=swiftDarwin vs first_error from the graph ==="
cat > "$fake/ninja" <<'EOF'
#!/bin/bash
args=("$@")
i=0
tool=""
node=""
builddir="."
while [ $i -lt ${#args[@]} ]; do
  a=${args[$i]}
  case "$a" in
    -C) builddir=${args[$((i+1))]}; i=$((i+2)); continue ;;
    -t)
      i=$((i+1)); tool=${args[$i]:-}; i=$((i+1)); continue ;;
    *) node=$a; i=$((i+1)); continue ;;
  esac
done
if [ "$tool" = query ]; then
  case "$node" in
    swiftSynchronization-macosx-x86_64)
      echo "swiftSynchronization-macosx-x86_64:"
      echo "  input: phony"
      echo "    lib/swift/macosx/x86_64/libswiftSynchronization.so"
      exit 0 ;;
    lib/swift/macosx/x86_64/libswiftSynchronization.so)
      echo "lib/swift/macosx/x86_64/libswiftSynchronization.so:"
      echo "  input: CXX_SHARED_LIBRARY_LINKER"
      echo "    | lib/swift/macosx/x86_64/libswiftDarwin.so"
      echo "    || stdlib/public/Platform/swiftDarwin-swiftmodule-macosx-x86_64"
      exit 0 ;;
    swift_Builtin_float-macosx-x86_64)
      echo "swift_Builtin_float-macosx-x86_64:"
      echo "  input: phony"
      echo "    lib/swift/macosx/x86_64/libswift_Builtin_float.so"
      exit 0 ;;
    lib/swift/macosx/x86_64/libswift_Builtin_float.so)
      echo "lib/swift/macosx/x86_64/libswift_Builtin_float.so:"
      echo "  input: CXX_SHARED_LIBRARY_LINKER"
      echo "    | lib/swift/macosx/x86_64/libswiftCore.so"
      exit 0 ;;
    swift_Concurrency-macosx-x86_64|lib/swift/macosx/x86_64/libswift_Concurrency.so)
      echo "$node:"
      echo "  input: phony"
      echo "    lib/swift/macosx/x86_64/libswift_Concurrency.so"
      echo "    | lib/swift/macosx/x86_64/libswift_Builtin_float.so"
      exit 0 ;;
    swift_StringProcessing-macosx-x86_64|lib/swift/macosx/x86_64/libswift_StringProcessing.so)
      echo "$node:"
      echo "  input: phony"
      echo "    | lib/swift/macosx/x86_64/libswift_RegexParser.so"
      exit 0 ;;
  esac
  echo "$node:"
  echo "  input: phony"
  exit 0
fi
exit 0
EOF
chmod +x "$fake/ninja"
export NINJA="$fake/ninja"
declare -gA OVERLAY_STATUS
OVERLAY_STATUS=()
echo 'error: cannot find type fmaxl in module Darwin' > "$tmp/darwin.log"
echo "ninja: error: 'stdlib/public/Concurrency/dispatch', needed by '_Concurrency.o', missing and no known rule to make it" \
  > "$tmp/conc.log"
echo 'error: something unique to Builtin_float' > "$tmp/bf.log"
echo 'error: StringProcessing own boom' > "$tmp/sp.log"

overlay_status_on_fail "$tmp/ninjabuild" swiftSynchronization-macosx-x86_64 "$tmp/darwin.log" \
  >"$tmp/cl_sync"
overlay_status_on_fail "$tmp/ninjabuild" swift_Concurrency-macosx-x86_64 "$tmp/conc.log" \
  >"$tmp/cl_conc"
overlay_status_on_fail "$tmp/ninjabuild" swift_Builtin_float-macosx-x86_64 "$tmp/bf.log" \
  >"$tmp/cl_bf"
overlay_status_on_fail "$tmp/ninjabuild" swift_StringProcessing-macosx-x86_64 "$tmp/sp.log" \
  >"$tmp/cl_sp"
overlay_status_on_fail "$tmp/ninjabuild" swiftDarwin-macosx-x86_64 "$tmp/darwin.log" \
  >"$tmp/cl_darwin"

cat "$tmp/cl_sync" "$tmp/cl_conc" "$tmp/cl_bf" "$tmp/cl_sp" "$tmp/cl_darwin"
grep -q 'FAILED dep=swiftDarwin' "$tmp/cl_sync" \
  && echo "  OK  Synchronization dep=swiftDarwin" \
  || { echo "  FAIL Synchronization classify"; fail=1; }
[ "${OVERLAY_STATUS[swiftSynchronization-macosx-x86_64]}" = "FAILED dep=swiftDarwin" ] \
  && echo "  OK  OVERLAY_STATUS Synchronization dep" \
  || { echo "  FAIL STATUS sync=${OVERLAY_STATUS[swiftSynchronization-macosx-x86_64]:-unset}"; fail=1; }
grep -q 'first_error=ninja: error:' "$tmp/cl_conc" \
  && echo "  OK  Concurrency first_error (no Darwin dep)" \
  || { echo "  FAIL Concurrency classify"; cat "$tmp/cl_conc"; fail=1; }
grep -q 'dep=swiftDarwin' "$tmp/cl_conc" \
  && { echo "  FAIL Concurrency wrongly classified as Darwin dep"; fail=1; } \
  || echo "  OK  Concurrency is not dep=swiftDarwin"
grep -q 'first_error=error: something unique to Builtin_float' "$tmp/cl_bf" \
  && echo "  OK  _Builtin_float first_error" \
  || { echo "  FAIL Builtin_float classify"; cat "$tmp/cl_bf"; fail=1; }
grep -q 'first_error=error: StringProcessing own boom' "$tmp/cl_sp" \
  && echo "  OK  _StringProcessing first_error" \
  || { echo "  FAIL StringProcessing classify"; cat "$tmp/cl_sp"; fail=1; }
grep -q 'FAILED first_error=error: cannot find type fmaxl' "$tmp/cl_darwin" \
  && echo "  OK  Darwin first_error" \
  || { echo "  FAIL Darwin classify"; cat "$tmp/cl_darwin"; fail=1; }

echo
echo "=== live ninja graph (if $HOME/work/build exists): who depends on Darwin ==="
unset NINJA
live=$HOME/work/build
if [ -f "$live/build.ninja" ]; then
  for t in swiftSynchronization-macosx-x86_64 swift_Concurrency-macosx-x86_64 \
           swift_StringProcessing-macosx-x86_64 swift_Builtin_float-macosx-x86_64 \
           swift_RegexParser-macosx-x86_64 swiftObservation-macosx-x86_64; do
    if overlay_ninja_depends_on_darwin "$live" "$t"; then
      echo "  live  $t depends on swiftDarwin"
    else
      echo "  live  $t does NOT depend on swiftDarwin"
    fi
  done
  # Synchronization is the one CMake SWIFT_MODULE_DEPENDS Darwin when the
  # SDK overlay is in the graph. The others import Clang Darwin via -sdk.
  if overlay_ninja_depends_on_darwin "$live" swiftSynchronization-macosx-x86_64; then
    echo "  OK  live Synchronization depends on Darwin"
  else
    echo "  FAIL live Synchronization should depend on Darwin"
    fail=1
  fi
  if overlay_ninja_depends_on_darwin "$live" swift_Builtin_float-macosx-x86_64; then
    echo "  FAIL live _Builtin_float should not depend on Darwin overlay"
    fail=1
  else
    echo "  OK  live _Builtin_float does not depend on Darwin overlay"
  fi
  if overlay_ninja_depends_on_darwin "$live" swift_Concurrency-macosx-x86_64; then
    echo "  FAIL live _Concurrency should not depend on Darwin overlay"
    fail=1
  else
    echo "  OK  live _Concurrency does not depend on Darwin overlay"
  fi
  if overlay_ninja_depends_on_darwin "$live" swift_StringProcessing-macosx-x86_64; then
    echo "  FAIL live _StringProcessing should not depend on Darwin overlay"
    fail=1
  else
    echo "  OK  live _StringProcessing does not depend on Darwin overlay"
  fi
  overlay_print_isysroot_from_ninja "$live" x86_64 | tee "$tmp/live_sdk"
  grep -q 'ninja Darwin.o -sdk=' "$tmp/live_sdk" \
    && echo "  OK  live Darwin.o -sdk printed" \
    || { echo "  FAIL live -sdk"; fail=1; }
  overlay_print_overlay_module_evidence "$live" x86_64 | tee "$tmp/live_mod"
  grep -q -- '-fmodule-map-file=ABSENT' "$tmp/live_mod" \
    && echo "  OK  live overlay compiles have no -fmodule-map-file" \
    || { echo "  FAIL live -fmodule-map-file"; fail=1; }
  grep -q 'import Darwin' "$tmp/live_mod" \
    && echo "  OK  live Darwin.swiftinterface imports Darwin" \
    || echo "  skip live swiftinterface imports (not staged)"
else
  echo "  skip live graph (no $live/build.ninja)"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- overlay sysroot is input-keyed; stale trees are displaced; refuse-before-cmake"
  exit 0
fi
echo "FAIL"
exit 1
