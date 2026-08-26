#!/bin/bash
# Build the slice + overlay + tests and run them under machorun, diffing every
# run against the macOS oracle baselines in tests/baselines/.
#
#   scripts/run_tests.sh
#
# The baselines are produced ON macOS by scripts/oracle_macos.sh against Apple's
# real Foundation. They are never regenerated on Linux — a baseline captured
# from the thing under test proves nothing.
set -uo pipefail
W=${W:-/work}
R=${R:-/repo}
SDK=$W/sdk/MacOSX.sdk
LLD=${LLD_BIN:-/usr/lib/llvm-18/bin}
TRIPLE=arm64-apple-macos13.0
SWIFT_FILTER='_Concurrency|_StringProcessing|SDKSettings'

mkdir -p "$W/obj"
pass=0; fail=0; nooracle=0

# LOAD-BEARING, and the single hardest thing found in this scope.
#
# libswiftCore has Apple's arm64 ISA_MASK (0x00007ffffffffff8 — 47 bits) inlined
# into swift_unknownObjectRetain, swift_getObjectType and friends. machorun maps
# images with mmap(NULL), and aarch64 Linux allocates top-down from 2^48, so
# classes land at 0xffff.... Masking then TRUNCATES every class pointer:
# measured 0xffff86413cd8 -> 0x7fff86413cd8, and Swift faults reading
# class->bits at +0x20.
#
# objc4 does not hit this because machorun patches it
# (patches-macho/0001-wide-va-isa-layout.patch) to the wide 52-bit arm64e isa
# layout. libswiftCore cannot be patched the same way — the mask is baked into
# compiled code in many places.
#
# `ulimit -s unlimited` switches Linux to the legacy BOTTOM-UP mmap layout, which
# allocates from TASK_SIZE/3 upward; classes then land at 0x4000.... below 2^47
# and both runtimes agree. Measured: without it t2_bridge dies with SIGSEGV in
# swift_unknownObjectRetain; with it, it matches the macOS oracle exactly.
#
# This is a workaround, not the fix. The fix belongs in machorun: map images
# below 2^47. See docs/DECISION.md §5.
ulimit -s unlimited 2>/dev/null || \
  echo "WARNING: could not set unlimited stack; expect SIGSEGV in swift_unknownObjectRetain"

run_case() {
  local name=$1 out rc base
  out=$("$W/mrun" "$W/$name" 2>&1); rc=$?
  base="$R/tests/baselines/$name.txt"
  if [ ! -f "$base" ]; then
    echo "NO-ORACLE $name (no baseline at tests/baselines/$name.txt)"
    echo "$out" | sed 's/^/    /'
    nooracle=$((nooracle+1)); return
  fi
  if [ $rc -ne 0 ]; then
    echo "FAIL      $name (exit $rc)"
    echo "$out" | sed 's/^/    /'
    fail=$((fail+1)); return
  fi
  if diff -q <(echo "$out") "$base" >/dev/null 2>&1; then
    echo "PASS      $name"
    pass=$((pass+1))
  else
    echo "FAIL      $name (differs from macOS oracle)"
    diff <(echo "$out") "$base" | sed 's/^/    /'
    fail=$((fail+1))
  fi
}

export MACHORUN_ROOT=$W/root

echo "==> t1_objc (Objective-C against the slice)"
clang -target $TRIPLE -isysroot "$SDK" -fobjc-runtime=macosx-13.0 -fno-objc-arc \
  -I"$R/include" -Os -c "$R/tests/t1_objc.m" -o "$W/obj/t1.o" || exit 1
clang -target $TRIPLE -isysroot "$SDK" -fuse-ld=lld -B "$LLD" -nostdlib \
  -L"$SDK/usr/lib" -L"$W/lib" "$W/obj/t1.o" -lFoundationSlice -lSystem -lobjc \
  -o "$W/t1_objc" || exit 1
run_case t1_objc

echo "==> t2_bridge (Swift <-> ObjC bridging)"
swiftc -c -target $TRIPLE -sdk "$SDK" -O -I "$W/swiftmodule" \
  -module-cache-path "$W/swiftmodcache" \
  "$R/tests/t2_bridge.swift" -o "$W/obj/t2.o" 2>&1 | grep -Ev "$SWIFT_FILTER"
[ -f "$W/obj/t2.o" ] || { echo "FAIL t2_bridge (did not compile)"; exit 1; }
# -lswiftCore before -lSystem: machorun binds flat in load order and libSystem
# exports a swift_release diagnostic stub that would otherwise shadow the real one.
clang -target $TRIPLE -isysroot "$SDK" -fuse-ld=lld -B "$LLD" -nostdlib \
  -L"$SDK/usr/lib" -L"$W/lib" "$W/obj/t2.o" \
  -lswiftCore -lFoundation -lFoundationSlice "$W/lib/libswiftcompat.dylib" \
  -lSystem -lobjc -o "$W/t2_bridge" || exit 1
run_case t2_bridge

echo
echo "pass $pass  fail $fail  no-oracle $nooracle"
[ $fail -eq 0 ]
