#!/bin/bash
# A failing ninja target must make build_stdlib.sh exit non-zero.
# SWIFTCORE_NINJA_HARNESS=1 skips bootstrap/cmake so this is a unit test.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
build=$SCRIPT_DIR/build_stdlib.sh
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fake=$tmp/bin
mkdir -p "$fake" "$tmp/work/build"

cat > "$fake/ninja" <<'EOF'
#!/bin/bash
# Minimal fake ninja. Honors -C / -t targets / -j, then the target name.
args=("$@")
targets_mode=0
target=""
i=0
while [ $i -lt ${#args[@]} ]; do
  a=${args[$i]}
  case "$a" in
    -C) i=$((i+2)); continue ;;
    -j) i=$((i+2)); continue ;;
    -t)
      i=$((i+1))
      if [ "${args[$i]:-}" = targets ]; then targets_mode=1; fi
      i=$((i+1)); continue
      ;;
    *) target=$a; i=$((i+1)); continue ;;
  esac
done

if [ "$targets_mode" = 1 ]; then
  cat <<'T'
swiftCore-macosx-x86_64: phony
swift_Concurrency-macosx-x86_64: phony
swiftSynchronization-macosx-x86_64: phony
swift_StringProcessing-macosx-x86_64: phony
swift_Builtin_float-macosx-x86_64: phony
swiftDarwin-macosx-x86_64: phony
T
  exit 0
fi

echo "FAILED: $target"
echo "ninja: error: fake ninja failing $target"
exit 1
EOF
chmod +x "$fake/ninja"

run() {
  local label=$1; shift
  set +e
  out=$(
    PATH="$fake:$PATH" NINJA="$fake/ninja" \
      SWIFTCORE_NINJA_HARNESS=1 SWIFTCORE_DARWIN_ARCH=x86_64 \
      W="$tmp/work" B="$tmp/work/build" \
      "$@" \
      bash "$build" 2>&1
  )
  rc=$?
  set -e
  printf '%s\n' "$out"
  echo "--- $label rc=$rc ---"
}

echo "=== failing core ninja (no gold wall) makes build_stdlib exit non-zero ==="
run core SWIFTCORE_OVERLAYS=0
if [ "$rc" -ne 0 ]; then
  echo "  OK  rc=$rc"
else
  echo "  FAIL expected nonzero"; fail=1
fi
printf '%s\n' "$out" | grep -q 'ninja: FAILED rc=' \
  && echo "  OK  ninja_checked reported failure" \
  || { echo "  FAIL missing ninja: FAILED"; fail=1; }
printf '%s\n' "$out" | grep -q 'build_stdlib done' \
  && { echo "  FAIL printed build_stdlib done after ninja failure"; fail=1; } \
  || echo "  OK  did not claim done"

echo
echo "=== failing overlay ninja makes build_stdlib exit non-zero ==="
# Core is allowed to hit the gold wall; overlay must still fail the script.
cat > "$fake/ninja" <<'EOF'
#!/bin/bash
args=("$@")
targets_mode=0
target=""
i=0
while [ $i -lt ${#args[@]} ]; do
  a=${args[$i]}
  case "$a" in
    -C) i=$((i+2)); continue ;;
    -j) i=$((i+2)); continue ;;
    -t)
      i=$((i+1))
      if [ "${args[$i]:-}" = targets ]; then targets_mode=1; fi
      i=$((i+1)); continue
      ;;
    *) target=$a; i=$((i+1)); continue ;;
  esac
done
if [ "$targets_mode" = 1 ]; then
  cat <<'T'
swiftCore-macosx-x86_64: phony
swift_Concurrency-macosx-x86_64: phony
swiftSynchronization-macosx-x86_64: phony
swift_StringProcessing-macosx-x86_64: phony
swift_Builtin_float-macosx-x86_64: phony
swiftDarwin-macosx-x86_64: phony
T
  exit 0
fi
if [[ "$target" == swiftCore-* ]]; then
  echo "clang++: error: invalid linker name in argument '-fuse-ld=gold'"
  echo "ninja: build stopped: subcommand failed."
  exit 1
fi
echo "FAILED: stdlib/public/Platform/OSX/x86_64/Darwin.o"
echo "error: 'semaphore.h' file not found"
echo "ninja: build stopped: subcommand failed."
exit 1
EOF
chmod +x "$fake/ninja"

run overlay SWIFTCORE_OVERLAYS=1
if [ "$rc" -ne 0 ]; then
  echo "  OK  rc=$rc"
else
  echo "  FAIL expected nonzero after overlay ninja failure"; fail=1
fi
printf '%s\n' "$out" | grep -q 'expected ELF gold wall' \
  && echo "  OK  core gold wall allowed" \
  || { echo "  FAIL core gold wall not recognized"; fail=1; }
printf '%s\n' "$out" | grep -q 'ninja: FAILED rc=' \
  && echo "  OK  overlay ninja propagated" \
  || { echo "  FAIL overlay failure swallowed"; fail=1; }
printf '%s\n' "$out" | grep -q 'build_stdlib done' \
  && { echo "  FAIL printed done after overlay failure"; fail=1; } \
  || echo "  OK  did not claim done"
printf '%s\n' "$out" | grep -q 'swiftObjectiveC' \
  && { echo "  FAIL asked ninja for swiftObjectiveC"; fail=1; } \
  || echo "  OK  did not invoke missing ObjectiveC target"

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- failing ninja makes build_stdlib.sh exit non-zero"
  exit 0
fi
echo "FAIL"
exit 1
