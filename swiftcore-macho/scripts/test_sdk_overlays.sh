#!/bin/bash
# The five Apple-SDK overlays are built by build_sdk_overlays.sh (not ninja).
# Darwin links must not mention /usr/lib/llvm-18/lib; dylibs need LC_DYLD_INFO.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/overlay_targets.inc"
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
OTOOL=${OTOOL:-llvm-otool-18}
command -v "$OTOOL" >/dev/null || OTOOL=llvm-otool

echo "=== harness skips side recipe ==="
# shellcheck disable=SC2034
SWIFTCORE_NINJA_HARNESS=1
out=$(overlay_build_xcode_shells /no/build x86_64)
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -q 'skip (SWIFTCORE_NINJA_HARNESS=1)' \
  && echo "  OK  harness skip" || { echo "  FAIL harness ran recipe"; fail=1; }
unset SWIFTCORE_NINJA_HARNESS

echo
echo "=== live recipe (SDK + Darwin resource-dir) ==="
W=${W:-$HOME/work}
B=${B:-$W/build}
SDK=${SDK:-$W/sdk/MacOSX.sdk}
if [ -f "$SDK/usr/include/Darwin.modulemap" ] \
    && [ -d "$B/lib/swift/macosx/Swift.swiftmodule" ]; then
  set +e
  out=$(W="$W" B="$B" SDK="$SDK" SWIFTCORE_DARWIN_ARCH=x86_64 \
    bash "$SCRIPT_DIR/build_sdk_overlays.sh" x86_64 "$B" 2>&1)
  rc=$?
  set -e
  printf '%s\n' "$out" | tail -40
  [ "$rc" -eq 0 ] && echo "  OK  recipe rc=0" || { echo "  FAIL recipe rc=$rc"; fail=1; }
  printf '%s\n' "$out" | grep -q 'source=synthesized' \
    && echo "  OK  synthesized shells when sysroot interface absent" \
    || echo "  note: sysroot interfaces were used (operator tree)"
  printf '%s\n' "$out" | grep -q 'cxx_runtime=' \
    && echo "  OK  cxx_runtime printed" || { echo "  FAIL missing cxx_runtime"; fail=1; }
  printf '%s\n' "$out" | grep -q 'compiler_rt=' \
    && echo "  OK  compiler_rt printed" || { echo "  FAIL missing compiler_rt"; fail=1; }
  printf '%s\n' "$out" | grep -q '/usr/lib/llvm-18/lib' \
    && { echo "  FAIL Darwin link still has /usr/lib/llvm-18/lib"; fail=1; } \
    || echo "  OK  no host llvm-18/lib on Darwin links"
  for n in libswift_DarwinFoundation1.dylib libswift_DarwinFoundation2.dylib \
           libswift_DarwinFoundation3.dylib libswift_errno.dylib \
           libswiftObjectiveC.dylib; do
    f=$B/lib/swift/macosx/x86_64/$n
    [ -f "$f" ] || { echo "  FAIL missing $n"; fail=1; continue; }
    hdr=$("$OTOOL" -hv "$f")
    echo "$hdr" | grep -Eq 'MH_MAGIC_64[[:space:]]+X86_64' \
      && echo "  OK  $n X86_64 DYLIB" || { echo "  FAIL $n header"; fail=1; }
    id=$("$OTOOL" -D "$f" | tail -1)
    [ "$id" = "/usr/lib/swift/$n" ] && echo "  OK  $n LC_ID_DYLIB" \
      || { echo "  FAIL $n id $id"; fail=1; }
    "$OTOOL" -l "$f" | grep -q LC_DYLD_INFO \
      && echo "  OK  $n LC_DYLD_INFO" || { echo "  FAIL $n no LC_DYLD_INFO"; fail=1; }
  done
  nm_df=$(llvm-nm-18 --defined-only --extern-only \
    "$B/lib/swift/macosx/x86_64/libswift_DarwinFoundation1.dylib" | awk '{print $NF}')
  echo "$nm_df" | grep -q 'FORCE_LOAD_$_swift_DarwinFoundation1' \
    && echo "  OK  DF1 FORCE_LOAD" || { echo "  FAIL DF1 FORCE_LOAD"; fail=1; }
  nm_e=$(llvm-nm-18 --defined-only --extern-only \
    "$B/lib/swift/macosx/x86_64/libswift_errno.dylib" | awk '{print $NF}')
  echo "$nm_e" | grep -q '\$s6Darwin5errnos5Int32Vvg' \
    && echo "  OK  Darwin.errno getter in libswift_errno" \
    || { echo "  FAIL missing Darwin.errno"; fail=1; }
  nm_o=$(llvm-nm-18 --defined-only --extern-only \
    "$B/lib/swift/macosx/x86_64/libswiftObjectiveC.dylib" | awk '{print $NF}')
  echo "$nm_o" | grep -q 'FORCE_LOAD_$_swiftObjectiveC' \
    && echo "  OK  ObjectiveC FORCE_LOAD" || { echo "  FAIL objc FORCE_LOAD"; fail=1; }
  echo "$nm_o" | grep -q 'NSObjectC10ObjectiveCE2eeoiySbAB_ABtFZ' \
    && echo "  OK  NSObject ==" || { echo "  FAIL missing NSObject =="; fail=1; }
  echo "$nm_o" | grep -q 'NSObjectC10ObjectiveCE4hash4into' \
    && echo "  OK  NSObject hash" || { echo "  FAIL missing NSObject hash"; fail=1; }
  echo "$nm_o" | grep -q 'ObjectiveC8SelectorV' \
    && echo "  OK  Selector helpers" || { echo "  FAIL missing Selector"; fail=1; }
  # The five SDK overlays must not grow Darwin's LC_REEXPORT_DYLIB set.
  for n in libswift_DarwinFoundation1.dylib libswift_DarwinFoundation2.dylib \
           libswift_DarwinFoundation3.dylib libswift_errno.dylib \
           libswiftObjectiveC.dylib; do
    f=$B/lib/swift/macosx/x86_64/$n
    [ -f "$f" ] || continue
    rx=$("$OTOOL" -l "$f" | awk '/LC_REEXPORT_DYLIB/{c++} END{print c+0}')
    [ "$rx" -eq 0 ] && echo "  OK  $n has 0 LC_REEXPORT_DYLIB" \
      || { echo "  FAIL $n has $rx LC_REEXPORT_DYLIB (only Darwin re-exports the shells)"; fail=1; }
  done
  darwin=$B/lib/swift/macosx/x86_64/libswiftDarwin.dylib
  [ -f "$darwin" ] || darwin=$B/lib/swift/macosx/x86_64/libswiftDarwin.so
  if [ -f "$darwin" ]; then
    # shellcheck source=overlay_targets.inc
    . "$SCRIPT_DIR/overlay_targets.inc"
    have=$(overlay_darwin_lc_reexport_names "$darwin")
    want=$(overlay_darwin_reexport_install_names | sort -u)
    if [ "$(printf '%s\n' "$have")" = "$(printf '%s\n' "$want")" ]; then
      echo "  OK  libswiftDarwin has exactly four LC_REEXPORT_DYLIB"
    else
      echo "  FAIL libswiftDarwin LC_REEXPORT_DYLIB:"
      echo "    have:"; printf '%s\n' "$have" | sed 's/^/      /'
      echo "    want:"; printf '%s\n' "$want" | sed 's/^/      /'
      fail=1
    fi
  else
    echo "  note: libswiftDarwin not in this live recipe (ninja target; operator overlay loop)"
  fi
else
  echo "  skip live recipe (no MacOSX.sdk Darwin map or Swift.swiftmodule)"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- five SDK overlays from in-tree shells; Darwin driver; LC_DYLD_INFO"
  exit 0
fi
echo "FAIL"
exit 1
