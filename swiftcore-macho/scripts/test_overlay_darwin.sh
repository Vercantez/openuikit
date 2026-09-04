#!/bin/bash
# Darwin overlay headers are Apple's (Libm / CarbonHeaders), staged with
# provenance. Darwin.modulemap names only headers that exist.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
# A live cycle exports SWIFTCORE_FE_SYSROOT and W=$TREE. Tests that stage a
# fixture FE tree (or generate from overlay-darwin pins) must not inherit those.
unset SWIFTCORE_FE_SYSROOT
unset W

echo "=== stage into empty sysroot (x86_64) replaces nothing, writes Darwin.modulemap ==="
mkdir -p "$tmp/sdk" "$tmp/no-fe"
set +e
out=$(SWIFTCORE_FE_SYSROOT="$tmp/no-fe" SWIFTCORE_DARWIN_ARCH=x86_64 \
  bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$tmp/sdk" 2>&1)
rc=$?
set -e
printf '%s\n' "$out"
[ "$rc" -eq 0 ] && echo "  OK  rc=0" || { echo "  FAIL rc=$rc"; fail=1; }
for h in usr/include/math.h usr/include/architecture/i386/math.h \
         usr/include/MacTypes.h usr/include/ConditionalMacros.h \
         usr/include/Darwin.modulemap usr/include/module.modulemap; do
  [ -f "$tmp/sdk/$h" ] && echo "  OK  $h" || { echo "  FAIL missing $h"; fail=1; }
done
printf '%s\n' "$out" | grep -q 'tag=Libm-2026' \
  && echo "  OK  Libm tag" || { echo "  FAIL missing Libm tag"; fail=1; }
printf '%s\n' "$out" | grep -q 'commit=17a5f9daa3f5679f7536b26f133b40cc078753c3' \
  && echo "  OK  Libm commit" || { echo "  FAIL missing Libm commit"; fail=1; }
printf '%s\n' "$out" | grep -q 'tag=CarbonHeaders-18.1' \
  && echo "  OK  CarbonHeaders tag" || { echo "  FAIL missing CarbonHeaders tag"; fail=1; }
printf '%s\n' "$out" | grep -q 'commit=214a9ae7ab3c0c78ddb50328ca226e6313c4c782' \
  && echo "  OK  CarbonHeaders commit" || { echo "  FAIL missing CarbonHeaders commit"; fail=1; }
cmp -s "$ROOT/sdk/overlay-darwin/math.h" "$tmp/sdk/usr/include/math.h" \
  && echo "  OK  math.h is the vendored Libm Intel file" \
  || { echo "  FAIL math.h mismatch"; fail=1; }
grep -q 'extern float  acosf' "$tmp/sdk/usr/include/math.h" \
  && echo "  OK  acosf is a real prototype (not a macro)" \
  || { echo "  FAIL acosf missing"; fail=1; }
grep -q 'typedef SInt32                          OSStatus' "$tmp/sdk/usr/include/MacTypes.h" \
  && echo "  OK  OSStatus in Apple MacTypes.h" \
  || { echo "  FAIL no OSStatus"; fail=1; }
grep -q 'module Darwin' "$tmp/sdk/usr/include/Darwin.modulemap" \
  && echo "  OK  Darwin.modulemap declares module Darwin" \
  || { echo "  FAIL no module Darwin"; fail=1; }
grep -q 'header "math.h"' "$tmp/sdk/usr/include/Darwin.modulemap" \
  && echo "  OK  Darwin.modulemap names math.h" \
  || { echo "  FAIL math.h not in modulemap"; fail=1; }
grep -q 'extern module Darwin' "$tmp/sdk/usr/include/module.modulemap" \
  && echo "  OK  module.modulemap references Darwin" \
  || { echo "  FAIL no extern module Darwin"; fail=1; }
# Generated map must not name a header that is not there.
while IFS= read -r h; do
  [ -f "$tmp/sdk/usr/include/$h" ] && echo "  OK  map header exists: $h" \
    || { echo "  FAIL map names absent $h"; fail=1; }
done < <(sed -n 's/.*header "\([^"]*\)".*/\1/p' "$tmp/sdk/usr/include/Darwin.modulemap")

echo
echo "=== replace clean-room math.h / MacTypes.h in a pre-populated sysroot ==="
mkdir -p "$tmp/sdk2/usr/include"
echo '/* clean-room stand-in */' > "$tmp/sdk2/usr/include/math.h"
echo '/* clean-room stand-in */' > "$tmp/sdk2/usr/include/MacTypes.h"
set +e
out=$(SWIFTCORE_FE_SYSROOT="$tmp/no-fe" SWIFTCORE_DARWIN_ARCH=x86_64 \
  bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$tmp/sdk2" 2>&1)
rc=$?
set -e
printf '%s\n' "$out" | tail -20
[ "$rc" -eq 0 ] && echo "  OK  replace rc=0" || { echo "  FAIL replace rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q 'replacing usr/include/math.h' \
  && echo "  OK  replaced math.h" || { echo "  FAIL did not replace math.h"; fail=1; }
cmp -s "$ROOT/sdk/overlay-darwin/math.h" "$tmp/sdk2/usr/include/math.h" \
  && echo "  OK  math.h now Apple Intel" || { echo "  FAIL math.h still stand-in"; fail=1; }

echo
echo "=== arm64 path does not overwrite math.h with Intel Libm ==="
mkdir -p "$tmp/sdk3/usr/include"
echo '/* arm64 clean-room math.h */' > "$tmp/sdk3/usr/include/math.h"
set +e
out=$(SWIFTCORE_FE_SYSROOT="$tmp/no-fe" SWIFTCORE_DARWIN_ARCH=arm64 \
  bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$tmp/sdk3" 2>&1)
rc=$?
set -e
[ "$rc" -eq 0 ] && echo "  OK  arm64 rc=0" || { echo "  FAIL arm64 rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q 'skipping Libm Intel math.h' \
  && echo "  OK  skipped Intel math.h on arm64" \
  || { echo "  FAIL arm64 still staged Intel math.h"; fail=1; }
grep -q 'arm64 clean-room math.h' "$tmp/sdk3/usr/include/math.h" \
  && echo "  OK  arm64 math.h untouched" || { echo "  FAIL arm64 math.h replaced"; fail=1; }

echo
echo "=== FE sysroot Darwin.modulemap is copied when present ==="
mkdir -p "$tmp/fe/usr/include" "$tmp/sdk4/usr/include" "$tmp/work/scratch"
echo 'module Darwin [system] { header "math.h" export * }' \
  > "$tmp/fe/usr/include/Darwin.modulemap"
echo 'extern module Darwin "Darwin.modulemap"' > "$tmp/fe/usr/include/module.modulemap"
echo 'extern float acosf(float);' > "$tmp/fe/usr/include/math.h"
echo 'extern long double fmaxl(long double, long double);' >> "$tmp/fe/usr/include/math.h"
ln -sfn "$tmp/fe" "$tmp/work/scratch/sysroot_fe4-x86_64"
set +e
out=$(W="$tmp/work" SWIFTCORE_DARWIN_ARCH=x86_64 \
  bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$tmp/sdk4" 2>&1)
rc=$?
set -e
printf '%s\n' "$out"
[ "$rc" -eq 0 ] && echo "  OK  FE rc=0" || { echo "  FAIL FE rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q 'FE sysroot' \
  && echo "  OK  used FE sysroot" || { echo "  FAIL did not use FE"; fail=1; }
grep -q 'header "math.h"' "$tmp/sdk4/usr/include/Darwin.modulemap" \
  && echo "  OK  FE Darwin.modulemap copied" \
  || { echo "  FAIL FE map missing"; fail=1; }
grep -q 'extern float acosf' "$tmp/sdk4/usr/include/math.h" \
  && echo "  OK  FE math.h copied" || { echo "  FAIL FE math.h missing"; fail=1; }
grep -q fmaxl "$tmp/sdk4/usr/include/math.h" \
  && echo "  OK  FE math.h kept (has fmaxl)" || { echo "  FAIL FE math.h lost fmaxl"; fail=1; }
[ -f "$tmp/sdk4/usr/include/ConditionalMacros.h" ] \
  && echo "  OK  FE missing ConditionalMacros.h repaired from pin" \
  || { echo "  FAIL FE ConditionalMacros.h still absent"; fail=1; }

echo
echo "=== FE DarwinFoundation1.modulemap names complex.h; staged from sdk-gaps ==="
mkdir -p "$tmp/fe3/usr/include" "$tmp/sdk6/usr/include" "$tmp/work3/scratch"
echo 'module Darwin [system] { header "math.h" export * }' \
  > "$tmp/fe3/usr/include/Darwin.modulemap"
cat > "$tmp/fe3/usr/include/DarwinFoundation1.modulemap" <<'EOF'
module _DarwinFoundation1 [system] {
  header "complex.h"
  export *
}
EOF
echo 'extern module Darwin "Darwin.modulemap"' > "$tmp/fe3/usr/include/module.modulemap"
echo 'extern float acosf(float);' > "$tmp/fe3/usr/include/math.h"
echo 'extern long double fmaxl(long double, long double);' >> "$tmp/fe3/usr/include/math.h"
ln -sfn "$tmp/fe3" "$tmp/work3/scratch/sysroot_fe4-x86_64"
set +e
out=$(W="$tmp/work3" SWIFTCORE_DARWIN_ARCH=x86_64 \
  bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$tmp/sdk6" 2>&1)
rc=$?
set -e
printf '%s\n' "$out" | tail -25
[ "$rc" -eq 0 ] && echo "  OK  FE-complex rc=0" || { echo "  FAIL FE-complex rc=$rc"; fail=1; }
grep -q 'header "complex.h"' "$tmp/sdk6/usr/include/DarwinFoundation1.modulemap" \
  && echo "  OK  FE DarwinFoundation1.modulemap copied" \
  || { echo "  FAIL Foundation1 map missing"; fail=1; }
[ -f "$tmp/sdk6/usr/include/complex.h" ] \
  && echo "  OK  complex.h staged" || { echo "  FAIL complex.h absent after FE maps"; fail=1; }
cmp -s "$ROOT/../full/sdk-gaps/usr/include/complex.h" "$tmp/sdk6/usr/include/complex.h" \
  && echo "  OK  complex.h is full/sdk-gaps stub" || { echo "  FAIL complex.h not sdk-gaps"; fail=1; }
printf '%s\n' "$out" | grep -q 'staged modulemap header complex.h' \
  && echo "  OK  fill named complex.h" || { echo "  FAIL no fill log for complex.h"; fail=1; }

echo
echo "=== FE math.h without fmaxl is repaired from overlay-darwin Intel pin ==="
mkdir -p "$tmp/fe2/usr/include" "$tmp/sdk5/usr/include" "$tmp/work2/scratch"
echo 'module Darwin [system] { header "math.h" export * }' \
  > "$tmp/fe2/usr/include/Darwin.modulemap"
echo 'extern module Darwin "Darwin.modulemap"' > "$tmp/fe2/usr/include/module.modulemap"
echo 'extern float acosf(float); /* no fmaxl */' > "$tmp/fe2/usr/include/math.h"
ln -sfn "$tmp/fe2" "$tmp/work2/scratch/sysroot_fe4-x86_64"
set +e
out=$(W="$tmp/work2" SWIFTCORE_DARWIN_ARCH=x86_64 \
  bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$tmp/sdk5" 2>&1)
rc=$?
set -e
printf '%s\n' "$out" | tail -25
[ "$rc" -eq 0 ] && echo "  OK  FE-repair rc=0" || { echo "  FAIL FE-repair rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q 'math.h lacks fmaxl' \
  && echo "  OK  named the fmaxl repair" || { echo "  FAIL no fmaxl repair line"; fail=1; }
grep -q fmaxl "$tmp/sdk5/usr/include/math.h" \
  && echo "  OK  repaired math.h has fmaxl" || { echo "  FAIL repaired math.h"; fail=1; }
cmp -s "$ROOT/sdk/overlay-darwin/math.h" "$tmp/sdk5/usr/include/math.h" \
  && echo "  OK  repaired math.h is the Intel pin" || { echo "  FAIL not Intel pin"; fail=1; }

echo
echo "=== FE Darwin.modulemap is not extra-inserted (dest cmp FE) ==="
mkdir -p "$tmp/feC/usr/include/sys" "$tmp/sdkC/usr/include" "$tmp/workC/scratch"
# Unexpanded FE map does not name math.h as a real header line. Extra-insert
# of `header "math.h"` made the overlay SDK copy differ from the sysroot.
cat > "$tmp/feC/usr/include/Darwin.modulemap" <<'EOF'
module Darwin [system] [extern_c] {
  export *
}
EOF
echo 'extern module Darwin "Darwin.modulemap"' > "$tmp/feC/usr/include/module.modulemap"
echo 'extern float acosf(float);' > "$tmp/feC/usr/include/math.h"
echo 'extern long double fmaxl(long double, long double);' >> "$tmp/feC/usr/include/math.h"
echo 'struct extern_proc { int p_pid; };' > "$tmp/feC/usr/include/sys/proc.h"
ln -sfn "$tmp/feC" "$tmp/workC/scratch/sysroot_fe4-x86_64"
set +e
out=$(SWIFTCORE_FE_SYSROOT="$tmp/feC" W="$tmp/workC" SWIFTCORE_DARWIN_ARCH=x86_64 \
  bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$tmp/sdkC" 2>&1)
rc=$?
set -e
printf '%s\n' "$out" | tail -15
[ "$rc" -eq 0 ] && echo "  OK  FE-cmp rc=0" || { echo "  FAIL FE-cmp rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q 'Darwin.modulemap now names' \
  && { echo "  FAIL extra-inserted into FE Darwin.modulemap copy"; fail=1; } \
  || echo "  OK  no extra-insert into FE Darwin.modulemap copy"
cmp -s "$tmp/feC/usr/include/Darwin.modulemap" "$tmp/sdkC/usr/include/Darwin.modulemap" \
  && echo "  OK  SDK Darwin.modulemap cmps FE sysroot" \
  || { echo "  FAIL SDK Darwin.modulemap differs from FE"; fail=1; }

echo
echo "=== box-path six-row pins (SYS machorun math.h, SDK Libm insert) ==="
# Operator-box MAIN cycle at 27c6b679 (a+b+c) measured:
#   2ee3efbfc91a89ef 10344 scratch/sysroot_fe4-x86_64/usr/include/math.h
#   64c43951eaec1da9 24257 sdk/MacOSX.sdk/usr/include/math.h
#   MISSING tgmath.h on both
#   de7edcc6107af239 18703 sys/proc.h (both)
#   10499cb2286f2dc3  9055 MacTypes.h (both)
#   68c22176598f53f8  1918 Darwin.modulemap (both; does not name math.h)
#   e67ded36201eedc5  2041 SYS module.modulemap vs 14541f5a 1883 SDK
#   include tree digest 1a8d31fa51df8db9 / 506 files
# ARM Darwin.modulemap 1918 B is operator-box only; here dest-sync + the
# four in-repo pin files must reproduce the split. module.modulemap may
# differ. Never write SYS.
# shellcheck disable=SC1091
. "$SCRIPT_DIR/overlay_sysroot.inc"
OPENUIKIT_ROOT=$(cd "$ROOT/.." && pwd)
box=$tmp/box
sys=$box/scratch/sysroot_fe4-x86_64
sdk=$box/sdk/MacOSX.sdk
mkdir -p "$sys/usr/include/sys" "$sys/usr/lib" "$sdk/usr/include"
cp "$OPENUIKIT_ROOT/machorun/sdk/usr/include/math.h" "$sys/usr/include/math.h"
cp "$OPENUIKIT_ROOT/machorun/sdk/usr/include/MacTypes.h" "$sys/usr/include/MacTypes.h"
cp "$OPENUIKIT_ROOT/machorun/sdk/usr/include/sys/proc.h" "$sys/usr/include/sys/proc.h"
cat > "$sys/usr/include/Darwin.modulemap" <<'EOF'
module Darwin [system] [extern_c] {
  module MacTypes {
    header "MacTypes.h"
    export *
  }
  export *
  extern module C "Darwin_C.modulemap"
}
EOF
cat > "$sys/usr/include/Darwin_C.modulemap" <<'EOF'
module Darwin.C [system] [extern_c] {
  module math {
    header "math.h"
    export *
  }
  export *
}
EOF
printf 'module ObjectiveC [system] { header "objc/objc.h" export * }\nextern module Darwin "Darwin.modulemap"\n' \
  > "$sys/usr/include/module.modulemap"
cat > "$sys/usr/lib/libSystem.B.tbd" <<'TBD'
--- !tapi-tbd-v3
archs: [ x86_64 ]
install-name: /usr/lib/libSystem.B.dylib
TBD
cp -a "$sys" "$box/sys-before"
cp -a "$sys/usr/include/." "$sdk/usr/include/"
export W=$box
export SWIFTCORE_FE_SYSROOT=$sys
overlay_sysroot_source_candidates() {
  printf '%s\n' "$SWIFTCORE_FE_SYSROOT"
}
set +e
out=$(W="$box" SWIFTCORE_FE_SYSROOT="$sys" SWIFTCORE_DARWIN_ARCH=x86_64 \
  bash "$SCRIPT_DIR/stage_overlay_darwin.sh" "$sdk" 2>&1)
rc=$?
sync_out=$(overlay_sysroot_sync_darwin_modulemap "$sdk" 2>&1)
sync_st=$?
ins_out=$(overlay_sysroot_ensure_intel_math_h "$sdk" 2>&1)
ins_st=$?
set -e
printf '%s\n' "$out" | tail -20
printf '%s\n' "$sync_out"
printf '%s\n' "$ins_out"
[ "$rc" -eq 0 ] && echo "  OK  stage_overlay_darwin rc=0" || { echo "  FAIL stage rc=$rc"; fail=1; }
[ "$sync_st" -eq 0 ] && echo "  OK  dest-sync rc=0" || { echo "  FAIL dest-sync rc=$sync_st"; fail=1; }
[ "$ins_st" -eq 0 ] && echo "  OK  Libm insert rc=0" || { echo "  FAIL Libm insert rc=$ins_st"; fail=1; }
if diff -rq "$box/sys-before" "$sys" >/dev/null; then
  echo "  OK  SYS tree unchanged (Libm insert did not write SYS)"
else
  echo "  FAIL SYS mutated by overlay staging"
  diff -rq "$box/sys-before" "$sys" | head -20
  fail=1
fi

box_row() {
  local p=$1 rel=$2
  if [ -f "$p" ]; then
    printf '%s  %6s  %s\n' \
      "$(sha256sum "$p" | awk '{print substr($1,1,16)}')" \
      "$(wc -c < "$p" | tr -d ' ')" \
      "$rel"
  else
    echo "MISSING $rel"
  fi
}
echo "HEAD=$(git -C "$OPENUIKIT_ROOT" rev-parse --short=9 HEAD 2>/dev/null || echo unknown)"
box_row "$sys/usr/include/math.h" "scratch/sysroot_fe4-x86_64/usr/include/math.h"
box_row "$sdk/usr/include/math.h" "sdk/MacOSX.sdk/usr/include/math.h"
box_row "$sys/usr/include/tgmath.h" "scratch/sysroot_fe4-x86_64/usr/include/tgmath.h"
box_row "$sdk/usr/include/tgmath.h" "sdk/MacOSX.sdk/usr/include/tgmath.h"
box_row "$sys/usr/include/sys/proc.h" "scratch/sysroot_fe4-x86_64/usr/include/sys/proc.h"
box_row "$sdk/usr/include/sys/proc.h" "sdk/MacOSX.sdk/usr/include/sys/proc.h"
box_row "$sys/usr/include/MacTypes.h" "scratch/sysroot_fe4-x86_64/usr/include/MacTypes.h"
box_row "$sdk/usr/include/MacTypes.h" "sdk/MacOSX.sdk/usr/include/MacTypes.h"
box_row "$sys/usr/include/Darwin.modulemap" "scratch/sysroot_fe4-x86_64/usr/include/Darwin.modulemap"
box_row "$sdk/usr/include/Darwin.modulemap" "sdk/MacOSX.sdk/usr/include/Darwin.modulemap"
box_row "$sys/usr/include/module.modulemap" "scratch/sysroot_fe4-x86_64/usr/include/module.modulemap"
box_row "$sdk/usr/include/module.modulemap" "sdk/MacOSX.sdk/usr/include/module.modulemap"

sys_math=$(sha256sum "$sys/usr/include/math.h" | awk '{print substr($1,1,16)}')
sdk_math=$(sha256sum "$sdk/usr/include/math.h" | awk '{print substr($1,1,16)}')
sys_math_sz=$(wc -c < "$sys/usr/include/math.h" | tr -d ' ')
sdk_math_sz=$(wc -c < "$sdk/usr/include/math.h" | tr -d ' ')
[ "$sys_math" = 2ee3efbfc91a89ef ] && [ "$sys_math_sz" = 10344 ] \
  && echo "  OK  SYS math.h is machorun 2ee3efbfc91a89ef 10344" \
  || { echo "  FAIL SYS math.h $sys_math $sys_math_sz"; fail=1; }
[ "$sdk_math" = 64c43951eaec1da9 ] && [ "$sdk_math_sz" = 24257 ] \
  && echo "  OK  SDK math.h is Libm 64c43951eaec1da9 24257" \
  || { echo "  FAIL SDK math.h $sdk_math $sdk_math_sz"; fail=1; }
[ ! -e "$sys/usr/include/tgmath.h" ] && [ ! -e "$sdk/usr/include/tgmath.h" ] \
  && echo "  OK  tgmath.h MISSING on SYS and SDK" \
  || { echo "  FAIL tgmath.h present"; fail=1; }
sys_proc=$(sha256sum "$sys/usr/include/sys/proc.h" | awk '{print substr($1,1,16)}')
sdk_proc=$(sha256sum "$sdk/usr/include/sys/proc.h" | awk '{print substr($1,1,16)}')
[ "$sys_proc" = de7edcc6107af239 ] && [ "$sdk_proc" = de7edcc6107af239 ] \
  && echo "  OK  sys/proc.h de7edcc6107af239 on SYS and SDK" \
  || { echo "  FAIL sys/proc.h sys=$sys_proc sdk=$sdk_proc"; fail=1; }
sys_mac=$(sha256sum "$sys/usr/include/MacTypes.h" | awk '{print substr($1,1,16)}')
sdk_mac=$(sha256sum "$sdk/usr/include/MacTypes.h" | awk '{print substr($1,1,16)}')
[ "$sys_mac" = 10499cb2286f2dc3 ] && [ "$sdk_mac" = 10499cb2286f2dc3 ] \
  && echo "  OK  MacTypes.h 10499cb2286f2dc3 on SYS and SDK" \
  || { echo "  FAIL MacTypes.h sys=$sys_mac sdk=$sdk_mac"; fail=1; }
cmp -s "$sys/usr/include/Darwin.modulemap" "$sdk/usr/include/Darwin.modulemap" \
  && echo "  OK  Darwin.modulemap dest-synced SYS == SDK" \
  || { echo "  FAIL Darwin.modulemap SYS != SDK"; fail=1; }
if grep -q 'header "math.h"' "$sys/usr/include/Darwin.modulemap" \
    || grep -q 'header "math.h"' "$sdk/usr/include/Darwin.modulemap"; then
  echo "  FAIL Darwin.modulemap names math.h (must stay Darwin.C)"
  fail=1
else
  echo "  OK  Darwin.modulemap does not name math.h"
fi
if cmp -s "$sys/usr/include/module.modulemap" "$sdk/usr/include/module.modulemap"; then
  echo "  OK  module.modulemap happened to match (box MAIN cycle they differ)"
else
  echo "  OK  module.modulemap SYS vs SDK differ (legitimate on MAIN)"
fi
set +e
sys_refuse=$(overlay_sysroot_ensure_intel_math_h "$sys" 2>&1)
sys_refuse_st=$?
set -e
[ "$sys_refuse_st" -ne 0 ] \
  && echo "  OK  Libm insert refuses overlay-copied SYS" \
  || { echo "  FAIL Libm insert wrote SYS rc=$sys_refuse_st"; fail=1; }
printf '%s\n' "$sys_refuse" | grep -q 'REFUSING Libm math.h insert onto overlay-copied SYS' \
  && echo "  OK  SYS refuse named overlay-copied SYS" \
  || { echo "  FAIL SYS refuse text"; fail=1; }

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- overlay Darwin headers staged from Apple OSS / FE sysroot"
  exit 0
fi
echo "FAIL"
exit 1
