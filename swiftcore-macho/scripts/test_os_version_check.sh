#!/bin/bash
# Prove Darwin overlay availability: a tiny x86_64-macos object that
# references __isPlatformVersionAtLeast is undefined until linked against
# the compiler-rt os_version_check.<arch>.o, then llvm-nm no longer reports
# it undefined. Next to test_sdk_overlays.sh.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

NM=${NM:-/usr/lib/llvm-18/bin/llvm-nm}
[ -x "$NM" ] || NM=$(command -v llvm-nm-18 || command -v llvm-nm)
LD64=${LD64_LLD:-/usr/lib/llvm-18/bin/ld64.lld}
[ -x "$LD64" ] || LD64=$(command -v ld64.lld-18 || command -v ld64.lld)
CC=$(command -v clang-18 || command -v clang)

find_complete_sdk() {
  local d
  for d in \
    "${SWIFTCORE_SDKROOT:-}" \
    "${SWIFTCORE_DARWIN_SDK:-}" \
    "${W:-$HOME/work}/sdk/MacOSX.sdk" \
    /root/work/sdk/MacOSX.sdk \
    /home/ubuntu/work/sdk/MacOSX.sdk
  do
    [ -n "$d" ] || continue
    if [ -f "$d/usr/include/dispatch/dispatch.h" ] \
        && [ -f "$d/usr/include/dlfcn.h" ] \
        && { [ -f "$d/usr/include/CoreFoundation/CoreFoundation.h" ] \
          || [ -f "$d/System/Library/Frameworks/CoreFoundation.framework/Headers/CoreFoundation.h" ]; } \
        && [ -f "$d/usr/include/i386/types.h" ]; then
      printf '%s\n' "$d"
      return 0
    fi
  done
  return 1
}

assemble_union_sdk() {
  local dest=$1
  local inc_src cf_src
  inc_src=""
  for d in "$ROOT/machorun/sdk" /workspace/machorun/sdk; do
    if [ -f "$d/usr/include/i386/types.h" ] && [ -f "$d/usr/include/dispatch/dispatch.h" ]; then
      inc_src=$d
      break
    fi
  done
  cf_src=""
  for d in "$ROOT/scratch/sysroot_fe4" /workspace/scratch/sysroot_fe4; do
    if [ -f "$d/usr/include/CoreFoundation/CoreFoundation.h" ]; then
      cf_src=$d
      break
    fi
  done
  if [ -z "$inc_src" ] || [ -z "$cf_src" ]; then
    echo "cannot assemble union SDK (need machorun i386+dispatch and fe4 CoreFoundation)" >&2
    return 1
  fi
  mkdir -p "$dest/usr"
  cp -a "$inc_src/usr/include" "$dest/usr/include"
  if [ ! -f "$dest/usr/include/CoreFoundation/CoreFoundation.h" ]; then
    cp -a "$cf_src/usr/include/CoreFoundation" "$dest/usr/include/"
  fi
  printf '%s\n' "$dest"
}

echo "=== missing sysroot headers fail loudly ==="
empty=$tmp/empty-sdk
mkdir -p "$empty/usr/include"
set +e
out=$(SWIFTCORE_SDKROOT="$empty" SWIFTCORE_DARWIN_ARCH=x86_64 \
  bash "$SCRIPT_DIR/build_compiler_rt_osx.sh" "$tmp/should-not-exist.o" 2>&1)
st=$?
set -e
printf '%s\n' "$out" | tail -8
[ "$st" -ne 0 ] && echo "  OK  missing headers rc=$st" \
  || { echo "  FAIL compiled without dispatch/dlfcn/CF headers"; fail=1; }
printf '%s\n' "$out" | grep -q 'lacks <dispatch/dispatch.h>' \
  && echo "  OK  named missing <dispatch/dispatch.h>" \
  || { echo "  FAIL did not name dispatch.h"; fail=1; }
[ ! -f "$tmp/should-not-exist.o" ] && echo "  OK  no object on header failure" \
  || { echo "  FAIL wrote object despite missing headers"; fail=1; }

sdk=$(find_complete_sdk) || sdk=""
if [ -z "$sdk" ]; then
  echo "no full MacOSX.sdk; assembling a header union for this VM"
  sdk=$(assemble_union_sdk "$tmp/MacOSX.sdk") || sdk=""
fi
if [ -z "$sdk" ]; then
  echo "FAIL no Darwin sysroot with <dispatch/dispatch.h>, <dlfcn.h>, CoreFoundation, i386/types.h"
  exit 1
fi
echo "sdk=$sdk"
echo "ld64=$LD64"
echo "nm=$NM"

echo
echo "=== compile os_version_check.c for x86_64-apple-macos ==="
rt_o=$tmp/os_version_check.x86_64.o
set +e
build_out=$(SWIFTCORE_SDKROOT="$sdk" SWIFTCORE_DARWIN_ARCH=x86_64 \
  SWIFTCORE_WORK="$tmp/work" \
  bash "$SCRIPT_DIR/build_compiler_rt_osx.sh" "$rt_o" 2>&1)
st=$?
set -e
printf '%s\n' "$build_out"
[ "$st" -eq 0 ] && [ -f "$rt_o" ] && echo "  OK  x86_64 object rc=0" \
  || { echo "  FAIL compile availability object rc=$st"; fail=1; }
printf '%s\n' "$build_out" | grep -q 'header <dispatch/dispatch.h>' \
  && echo "  OK  found dispatch.h" || { echo "  FAIL no dispatch.h probe"; fail=1; }
printf '%s\n' "$build_out" | grep -q 'header <dlfcn.h>' \
  && echo "  OK  found dlfcn.h" || { echo "  FAIL no dlfcn.h probe"; fail=1; }
printf '%s\n' "$build_out" | grep -q 'header <CoreFoundation/CoreFoundation.h>' \
  && echo "  OK  found CoreFoundation.h" || { echo "  FAIL no CF header probe"; fail=1; }

echo
echo "=== arch-parametric: arm64 object (even if this host is x86_64) ==="
rt_arm=$tmp/os_version_check.arm64.o
set +e
arm_out=$(SWIFTCORE_SDKROOT="$sdk" SWIFTCORE_DARWIN_ARCH=arm64 \
  bash "$SCRIPT_DIR/build_compiler_rt_osx.sh" "$rt_arm" 2>&1)
arm_st=$?
set -e
printf '%s\n' "$arm_out" | tail -6
[ "$arm_st" -eq 0 ] && [ -f "$rt_arm" ] && echo "  OK  arm64 object rc=0" \
  || { echo "  FAIL arm64 availability object rc=$arm_st"; fail=1; }
if [ -f "$rt_arm" ]; then
  "$NM" "$rt_arm" 2>/dev/null | grep -q 'isPlatformVersionAtLeast' \
    && echo "  OK  arm64 object defines isPlatformVersionAtLeast" \
    || { echo "  FAIL arm64 object missing symbol"; fail=1; }
fi

echo
echo "=== tiny x86_64-macos object references __isPlatformVersionAtLeast ==="
cat > "$tmp/ref.c" <<'EOF'
#include <stdint.h>
int32_t __isPlatformVersionAtLeast(uint32_t, uint32_t, uint32_t, uint32_t);
int probe(void) {
  return __isPlatformVersionAtLeast(1, 14, 0, 0);
}
EOF
set +e
"$CC" -c -target x86_64-apple-macosx13.0 -isysroot "$sdk" \
  -o "$tmp/ref.o" "$tmp/ref.c" 2>"$tmp/ref.err"
c_st=$?
set -e
if [ "$c_st" -ne 0 ]; then
  echo "  FAIL compile ref.c rc=$c_st"; cat "$tmp/ref.err"; fail=1
else
  echo "--- llvm-nm ref.o (before link) ---"
  "$NM" "$tmp/ref.o" | tee "$tmp/ref.nm"
  if "$NM" "$tmp/ref.o" | grep -E 'isPlatformVersionAtLeast' | grep -q ' U '; then
    echo "  OK  ref.o has undefined isPlatformVersionAtLeast"
  else
    echo "  FAIL ref.o does not show undefined isPlatformVersionAtLeast"
    fail=1
  fi
fi

echo
echo "=== ld64.lld: ref.o + os_version_check.x86_64.o ==="
if [ ! -f "$rt_o" ] || [ ! -f "$tmp/ref.o" ]; then
  echo "  FAIL missing inputs for ld64.lld"; fail=1
else
  set +e
  "$LD64" -arch x86_64 -dylib \
    -platform_version macos 13.0 13.0 \
    -undefined dynamic_lookup \
    -o "$tmp/libavail.dylib" \
    "$tmp/ref.o" "$rt_o" \
    >"$tmp/ld64.out" 2>"$tmp/ld64.err"
  l_st=$?
  set -e
  cat "$tmp/ld64.out" "$tmp/ld64.err" || true
  [ "$l_st" -eq 0 ] && echo "  OK  ld64.lld rc=0" \
    || { echo "  FAIL ld64.lld rc=$l_st"; fail=1; }
  if grep -q "undefined symbol:.*isPlatformVersionAtLeast" "$tmp/ld64.err"; then
    echo "  FAIL ld64.lld still undefined isPlatformVersionAtLeast"
    fail=1
  else
    echo "  OK  ld64.lld did not report undefined isPlatformVersionAtLeast"
  fi
  if [ -f "$tmp/libavail.dylib" ]; then
    echo "--- llvm-nm libavail.dylib (after link) ---"
    "$NM" "$tmp/libavail.dylib" | grep -E 'isPlatformVersionAtLeast|isPlatformOrVariant' \
      | tee "$tmp/dylib.nm" || true
    if "$NM" "$tmp/libavail.dylib" | grep -E 'isPlatformVersionAtLeast' | grep -q ' U '; then
      echo "  FAIL dylib still has undefined isPlatformVersionAtLeast"
      fail=1
    else
      echo "  OK  llvm-nm no longer reports isPlatformVersionAtLeast undefined"
    fi
    if "$NM" "$tmp/libavail.dylib" | grep -q 'isPlatformVersionAtLeast'; then
      echo "  OK  dylib defines isPlatformVersionAtLeast from the builtin object"
    else
      echo "  FAIL dylib missing isPlatformVersionAtLeast"
      fail=1
    fi
  fi
fi

echo
echo "=== clangxx_darwin_link argv includes the object (x86_64 and arm64) ==="
py=$SCRIPT_DIR/clangxx_darwin_link.py
got=$(SWIFTCORE_CLANGXX_PRINT_REWRITTEN=1 \
  SWIFTCORE_COMPILER_RT_OSX="$rt_o" \
  python3 "$py" -target x86_64-apple-macosx13.0 -isysroot "$sdk" \
  -shared -o libswiftDarwin.so Darwin.o 2>"$tmp/shim.err")
printf '%s\n' "$got" | grep -F -- "$rt_o" >/dev/null \
  && echo "  OK  x86_64 Darwin driver argv has the object" \
  || { echo "  FAIL x86_64 argv missing object"; echo "$got"; fail=1; }
got_arm=$(SWIFTCORE_CLANGXX_PRINT_REWRITTEN=1 \
  SWIFTCORE_COMPILER_RT_OSX="$rt_arm" \
  python3 "$py" -target arm64-apple-macosx13.0 -isysroot "$sdk" \
  -shared -o libswiftDarwin.so Darwin.o 2>"$tmp/shim.arm.err")
printf '%s\n' "$got_arm" | grep -F -- "$rt_arm" >/dev/null \
  && echo "  OK  arm64 Darwin driver argv has the object" \
  || { echo "  FAIL arm64 argv missing object"; echo "$got_arm"; fail=1; }

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- os_version_check.<arch>.o resolves __isPlatformVersionAtLeast for ld64.lld"
  exit 0
fi
echo "FAIL"
exit 1
