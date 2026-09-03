#!/bin/bash
# build_stdlib --print-flags must reach cmake argv without touching
# MACHORUN/darwin or running check_undefined.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
build=$SCRIPT_DIR/build_stdlib.sh
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# A fake check_undefined that fails loudly if invoked.
mkdir -p "$tmp/bin"
cat > "$tmp/bin/check_undefined.sh" <<'EOF'
#!/bin/bash
echo "FAIL check_undefined was invoked: $*" >&2
exit 99
EOF
chmod +x "$tmp/bin/check_undefined.sh"
# Also a `bash` trampoline? The real script is called by absolute path from
# gen_tbd. The dry path must not call gen_tbd at all.

echo "=== build_stdlib --print-flags ==="
set +e
out=$(
  env PATH="$tmp/bin:$PATH" \
    SWIFTCORE_OVERLAYS=1 SWIFTCORE_BUILD_DISPATCH=1 \
    SWIFTCORE_DARWIN_ARCH=x86_64 \
    SWIFT_HOST_VARIANT_ARCH=x86_64 \
    SWIFT_HOST_TRIPLE=x86_64-unknown-linux-gnu \
    W="$tmp/work" B="$tmp/work/build" \
    bash "$build" --print-flags 2>&1
)
rc=$?
set -e
printf '%s\n' "$out" | tail -5
echo "--- rc=$rc ---"

[ "$rc" -eq 0 ] && echo "  OK  rc=0" || { echo "  FAIL rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q -- '-DSWIFT_SDKS=OSX' \
  && echo "  OK  reached cmake argv" \
  || { echo "  FAIL no cmake OSX SDK flag"; fail=1; }
printf '%s\n' "$out" | grep -q -- '-DSWIFT_ENABLE_DISPATCH=ON' \
  && echo "  OK  overlays pass ENABLE_DISPATCH=ON" \
  || { echo "  FAIL missing ENABLE_DISPATCH=ON"; fail=1; }
printf '%s\n' "$out" | grep -q -- '-DSWIFT_USE_LINKER=lld' \
  && echo "  OK  print-flags has SWIFT_USE_LINKER=lld" \
  || { echo "  FAIL missing SWIFT_USE_LINKER=lld"; fail=1; }
printf '%s\n' "$out" | grep -q -- 'CMAKE_CXX_COMPILER=.*/shims/clang++' \
  && echo "  OK  print-flags CXX is Darwin-link shim" \
  || { echo "  FAIL missing shim CXX compiler"; fail=1; }
printf '%s\n' "$out" | grep -q -- 'SWIFT_NATIVE_CLANG_TOOLS_PATH=.*/shims' \
  && echo "  OK  print-flags native clang path is shims" \
  || { echo "  FAIL missing native clang shims path"; fail=1; }
printf '%s\n' "$out" | grep -q -- '-DSWIFT_ENABLE_EXPERIMENTAL_OBSERVATION=ON' \
  && echo "  OK  overlays pass OBSERVATION=ON" \
  || { echo "  FAIL missing OBSERVATION=ON"; fail=1; }
printf '%s\n' "$out" | grep -qi 'check_undefined' \
  && { echo "  FAIL invoked check_undefined"; fail=1; } \
  || echo "  OK  did not run check_undefined"
printf '%s\n' "$out" | grep -q 'CHECK 5:' \
  && { echo "  FAIL ran gen_tbd CHECK 5"; fail=1; } \
  || echo "  OK  did not run CHECK 5"
printf '%s\n' "$out" | grep -q 'bootstrap sources' \
  && { echo "  FAIL ran bootstrap on print-flags"; fail=1; } \
  || echo "  OK  skipped bootstrap"
printf '%s\n' "$out" | grep -qi 'machorun darwin userland' \
  && { echo "  FAIL built darwin userland on print-flags"; fail=1; } \
  || echo "  OK  skipped machorun darwin/tbd"

echo
echo "=== STOP_AFTER=print-flags is the same dry path ==="
set +e
out2=$(
  SWIFTCORE_OVERLAYS=0 SWIFTCORE_BUILD_DISPATCH=0 \
    SWIFTCORE_DARWIN_ARCH=x86_64 \
    STOP_AFTER=print-flags \
    W="$tmp/work" B="$tmp/work/build" \
    bash "$build" 2>&1
)
rc2=$?
set -e
[ "$rc2" -eq 0 ] && echo "  OK  STOP_AFTER=print-flags rc=0" \
  || { echo "  FAIL STOP_AFTER rc=$rc2"; fail=1; }
printf '%s\n' "$out2" | grep -q -- '-DSWIFT_SDKS=OSX' \
  && echo "  OK  STOP_AFTER reached cmake argv" \
  || { echo "  FAIL STOP_AFTER missed cmake"; fail=1; }

echo
echo "=== overlay scoreboard harness still runs after this gate is gone ==="
# Existing test_overlay_scoreboard.sh covers the ninja loop. Confirm the
# tbd invocation in build_stdlib exports the skip so a full run cannot
# die at CHECK 5.
grep -q 'MACHORUN_SKIP_HOSTFALLBACK_CHECK=1' "$build" \
  && echo "  OK  build_stdlib exports MACHORUN_SKIP_HOSTFALLBACK_CHECK=1 before tbd" \
  || { echo "  FAIL tbd still runs CHECK 5 as a gate"; fail=1; }

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- build_stdlib dry path reaches cmake; CHECK 5 is not an overlay gate"
  exit 0
fi
echo "FAIL"
exit 1
