#!/bin/bash
# Overlay sysroot staging is input-keyed. A pre-existing MacOSX.sdk with
# clean-room math.h / no stamp is displaced, never rm'd; mismatch restages
# into a fresh directory. Refuse-before-cmake if math.h lacks fmaxl or
# sys/proc.h lacks extern_proc.
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
mkdir -p "$tmp/sdk/MacOSX.sdk/usr/include"
echo 'OPERATOR_CANARY' > "$tmp/sdk/MacOSX.sdk/CANARY"
echo '/* clean-room */' > "$tmp/sdk/MacOSX.sdk/usr/include/math.h"
overlay_sysroot_begin "$tmp/sdk"
need '[ "${OVERLAY_SYSROOT_REUSE}" = 0 ]' "begin restage (REUSE=0)"
need '[ -d "$OVERLAY_SYSROOT_DEST" ]' "fresh dest exists"
need '[[ "$OVERLAY_SYSROOT_DEST" == *MacOSX.sdk.overlay-* ]]' "fresh dest is MacOSX.sdk.overlay-*"
need '[ -f "$tmp/sdk/MacOSX.sdk/CANARY" ]' "live canary still in place during stage"
fresh=$OVERLAY_SYSROOT_DEST
mkdir -p "$fresh/usr/include/sys"
cp "$ROOT/sdk/overlay-darwin/math.h" "$fresh/usr/include/math.h"
cp "$OPENUIKIT_ROOT/machorun/sdk/usr/include/sys/proc.h" \
  "$fresh/usr/include/sys/proc.h"
echo 'module Darwin [system] { header "math.h" header "sys/proc.h" export * }' \
  > "$fresh/usr/include/Darwin.modulemap"
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

echo
echo "=== matching stamp + complete headers → reuse, no second dest ==="
overlay_sysroot_begin "$tmp/sdk"
need '[ "${OVERLAY_SYSROOT_REUSE}" = 1 ]' "second begin reuses"
need '[ -f "$stale/CANARY" ]' "stale canary still exists after reuse"

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
