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

# REQUIRES a machorun that places every image below 2^47.
#
# libswiftCore has Apple's arm64 ISA_MASK (0x00007ffffffffff8 — 47 bits) inlined
# into swift_unknownObjectRetain, swift_getObjectType and friends, which then
# read class->bits at +0x20. A loader that maps dylibs at 0xffff... — which is
# what mmap(NULL) gives you on aarch64 Linux — makes that mask silently clear
# bit 47, and Swift faults on the truncated class pointer.
#
# Fixed in machorun a1718a4 ("place every image below 2^47"), which reserves an
# arena at 8 GiB, so nothing is needed here any more. This scope previously set
# `ulimit -s unlimited` to flip Linux to the legacy bottom-up mmap layout; that
# is deliberately gone. An ambient rlimit is invisible at the point it matters
# and lapses across a re-exec.
#
# If these tests start dying with SIGSEGV in swift_unknownObjectRetain, the
# loader predates a1718a4. See docs/DECISION.md §3.

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
