#!/bin/bash
# Overlay sysroot staging is input-keyed. A pre-existing MacOSX.sdk with
# clean-room math.h / no stamp is displaced, never rm'd; mismatch restages
# into a fresh directory. Refuse-before-cmake if math.h lacks fmaxl,
# sys/proc.h lacks extern_proc, or a Darwin Clang overlay map names a header
# that is not on disk. libc++ usr/include/c++/v1/module.modulemap is outside
# that closure and must not refuse.
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
  echo "clang++ -target x86_64-apple-macosx13.0 -shared -Wl,-soname,libswiftDarwin.so -o lib/swift/macosx/x86_64/libswiftDarwin.so Darwin.o"
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
  echo ": && /root/work/shims/clang++ -target x86_64-apple-macosx13.0 -shared -Wl,-soname,libswiftDarwin.so -o lib/swift/macosx/x86_64/libswiftDarwin.so Darwin.o && :"
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
  echo "clang++ -target x86_64-apple-macosx13.0 -shared -Wl,-soname,libswiftDarwin.so -o lib/swift/macosx/x86_64/libswiftDarwin.so Darwin.o"
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
