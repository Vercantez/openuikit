#!/bin/bash
# SWIFTCORE_OVERLAYS=1 must not reach CMake with an empty string-processing
# path (CMakeLists.txt:41 "No SOURCES given"). Same for libdispatch.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cfg=$SCRIPT_DIR/configure.sh
fail=0

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

need_marker() {
  local out=$1 marker=$2
  printf '%s\n' "$out" | grep -F -- "$marker" >/dev/null && echo "  OK  $marker" \
    || { echo "  FAIL missing $marker"; echo "$out" | head -20; fail=1; }
}

echo "=== refuse overlays=1 with no checkouts (must not invoke cmake) ==="
set +e
out=$(
  SWIFTCORE_OVERLAYS=1 SWIFTCORE_DARWIN_ARCH=x86_64 \
    W="$tmp/empty" B="$tmp/empty/build" \
    bash "$cfg" 2>&1
)
rc=$?
set -e
[ "$rc" -eq 2 ] && echo "  OK  exit 2" || { echo "  FAIL rc=$rc want 2"; fail=1; }
need_marker "$out" "CANNOT_FETCH_STRING_PROCESSING_SOURCE"
need_marker "$out" "swift-experimental-string-processing"
need_marker "$out" "91177e6225c63e885872b83d48e254b1270fa15a"
printf '%s\n' "$out" | grep -F -- "No SOURCES given to target" >/dev/null \
  && { echo "  FAIL cmake diagnostic leaked"; fail=1; } \
  || echo "  OK  no CMakeLists.txt:41 diagnostic"
[ -f "$tmp/empty/configure.log" ] && grep -q cmake "$tmp/empty/configure.log" 2>/dev/null \
  && { echo "  FAIL configure.log looks like cmake ran"; fail=1; } \
  || echo "  OK  cmake not invoked"

echo
echo "=== refuse BUILD_DISPATCH=1 with no libdispatch ==="
set +e
out=$(
  SWIFTCORE_OVERLAYS=0 SWIFTCORE_BUILD_DISPATCH=1 SWIFTCORE_DARWIN_ARCH=x86_64 \
    W="$tmp/nodisp" B="$tmp/nodisp/build" \
    bash "$cfg" 2>&1
)
rc=$?
set -e
[ "$rc" -eq 2 ] && echo "  OK  exit 2" || { echo "  FAIL rc=$rc want 2"; fail=1; }
need_marker "$out" "CANNOT_FETCH_LIBDISPATCH_SOURCE"
need_marker "$out" "swift-corelibs-libdispatch"
need_marker "$out" "2df91f94651f2d924d7506c9d14685929386d779"

echo
echo "=== --print-flags with overlays=1 passes both sibling -D paths ==="
fake=$tmp/print
mkdir -p "$fake/swift-experimental-string-processing/Sources/_StringProcessing"
mkdir -p "$fake/libdispatch"
touch "$fake/libdispatch/CMakeLists.txt"
dump=$(
  SWIFTCORE_OVERLAYS=1 SWIFTCORE_DARWIN_ARCH=x86_64 \
    SWIFT_HOST_VARIANT_ARCH=x86_64 SWIFT_HOST_TRIPLE=x86_64-unknown-linux-gnu \
    W="$fake" bash "$cfg" --print-flags
)
printf '%s\n' "$dump" | grep -F -- "-DSWIFT_PATH_TO_STRING_PROCESSING_SOURCE=$fake/swift-experimental-string-processing" >/dev/null \
  && echo "  OK  STRING_PROCESSING_SOURCE path" \
  || { echo "  FAIL missing STRING_PROCESSING -D"; fail=1; }
printf '%s\n' "$dump" | grep -F -- "-DSWIFT_PATH_TO_LIBDISPATCH_SOURCE=$fake/libdispatch" >/dev/null \
  && echo "  OK  LIBDISPATCH_SOURCE path" \
  || { echo "  FAIL missing LIBDISPATCH -D"; fail=1; }
printf '%s\n' "$dump" | grep -F -- "-DSWIFT_ENABLE_DISPATCH=ON" >/dev/null \
  && echo "  OK  ENABLE_DISPATCH=ON with BUILD_DISPATCH" \
  || { echo "  FAIL missing SWIFT_ENABLE_DISPATCH=ON"; fail=1; }
printf '%s\n' "$dump" | grep -F -- "-DSWIFT_ENABLE_EXPERIMENTAL_STRING_PROCESSING=ON" >/dev/null \
  && echo "  OK  STRING_PROCESSING=ON" \
  || { echo "  FAIL STRING_PROCESSING not ON"; fail=1; }
printf '%s\n' "$dump" | grep -F -- "-DSWIFT_ENABLE_SYNCHRONIZATION=ON" >/dev/null \
  && echo "  OK  SYNCHRONIZATION=ON" \
  || { echo "  FAIL SYNCHRONIZATION not ON"; fail=1; }
printf '%s\n' "$dump" | grep -F -- "-DSWIFT_ENABLE_EXPERIMENTAL_OBSERVATION=ON" >/dev/null \
  && echo "  OK  OBSERVATION=ON" \
  || { echo "  FAIL OBSERVATION not ON"; fail=1; }
printf '%s\n' "$dump" | grep -F -- "-DSWIFT_USE_LINKER=lld" >/dev/null \
  && echo "  OK  SWIFT_USE_LINKER=lld with overlays=1" \
  || { echo "  FAIL missing SWIFT_USE_LINKER=lld"; fail=1; }
printf '%s\n' "$dump" | grep -F -- "CMAKE_CXX_COMPILER=$fake/shims/clang++" >/dev/null \
  && echo "  OK  CXX compiler is Darwin-link shim" \
  || { echo "  FAIL missing shim CXX"; fail=1; }
printf '%s\n' "$dump" | grep -F -- "-DSWIFT_LIPO=$fake/shims/lipo" >/dev/null \
  && echo "  OK  SWIFT_LIPO is single-arch shim" \
  || { echo "  FAIL missing SWIFT_LIPO"; fail=1; }

echo
echo "=== default (overlays off) dump has no empty string-processing -D ==="
def=$(
  unset SWIFTCORE_OVERLAYS SWIFTCORE_BUILD_DISPATCH
  SWIFTCORE_DARWIN_ARCH=x86_64 SWIFT_HOST_VARIANT_ARCH=x86_64 \
    SWIFT_HOST_TRIPLE=x86_64-unknown-linux-gnu \
    W=/tmp/swiftcore-print bash "$cfg" --print-flags
)
printf '%s\n' "$def" | grep -F -- "SWIFT_PATH_TO_STRING_PROCESSING_SOURCE" >/dev/null \
  && { echo "  FAIL core dump still passes STRING_PROCESSING path"; fail=1; } \
  || echo "  OK  core dump has no STRING_PROCESSING path"
printf '%s\n' "$def" | grep -F -- "-DSWIFT_ENABLE_EXPERIMENTAL_STRING_PROCESSING=OFF" >/dev/null \
  && echo "  OK  STRING_PROCESSING=OFF without overlays" \
  || { echo "  FAIL default STRING_PROCESSING not OFF"; fail=1; }

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- refuse-before-cmake; sibling paths explicit when overlays=1"
  exit 0
fi
echo "FAIL"
exit 1
