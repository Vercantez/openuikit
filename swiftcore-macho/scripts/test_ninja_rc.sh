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
      tool=${args[$i]:-}
      i=$((i+1))
      case "$tool" in
        targets) targets_mode=1 ;;
        commands)
          echo "swiftc -sdk /sdk/MacOSX.sdk -c Darwin.swift"
          exit 0 ;;
        query)
          echo "${args[$i]:-unknown}:"
          echo "  input: phony"
          exit 0 ;;
      esac
      continue
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
swift_RegexParser-macosx-x86_64: phony
swiftObservation-macosx-x86_64: phony
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
  local label=$1 overlays=$2
  set +e
  out=$(
    env PATH="$fake:$PATH" NINJA="$fake/ninja" \
      SWIFTCORE_NINJA_HARNESS=1 SWIFTCORE_DARWIN_ARCH=x86_64 \
      SWIFTCORE_OVERLAYS="$overlays" \
      SWIFTCORE_TEST_RC126_EXEC="${SWIFTCORE_TEST_RC126_EXEC:-}" \
      W="$tmp/work" B="$tmp/work/build" \
      bash "$build" 2>&1
  )
  rc=$?
  set -e
  printf '%s\n' "$out"
  echo "--- $label rc=$rc ---"
}

echo "=== failing core ninja (no gold wall) makes build_stdlib exit non-zero ==="
run core 0
if [ "$rc" -ne 0 ]; then
  echo "  OK  rc=$rc"
else
  echo "  FAIL expected nonzero"; fail=1
fi
if [ "$rc" -eq 126 ]; then
  echo "  FAIL core ninja exit 1 must not become build_stdlib rc=126 (not-executable)"; fail=1
else
  echo "  OK  rc is not 126"
fi
printf '%s\n' "$out" | grep -q 'ninja: FAILED rc=' \
  && echo "  OK  ninja_checked reported failure" \
  || { echo "  FAIL missing ninja: FAILED"; fail=1; }
printf '%s\n' "$out" | grep -q 'build_stdlib done' \
  && { echo "  FAIL printed build_stdlib done after ninja failure"; fail=1; } \
  || echo "  OK  did not claim done"

echo
echo "=== failing overlay ninja makes build_stdlib exit non-zero ==="
# Core must succeed (lld, not an allowed gold wall). Overlay must still fail the script.
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
      tool=${args[$i]:-}
      i=$((i+1))
      case "$tool" in
        targets) targets_mode=1 ;;
        commands)
          echo "swiftc -sdk /sdk/MacOSX.sdk -c Darwin.swift"
          exit 0 ;;
        query)
          echo "${args[$i]:-unknown}:"
          echo "  input: phony"
          exit 0 ;;
      esac
      continue
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
swift_RegexParser-macosx-x86_64: phony
swiftObservation-macosx-x86_64: phony
swiftDarwin-macosx-x86_64: phony
T
  exit 0
fi
if [[ "$target" == swiftCore-* ]]; then
  echo "built $target"
  exit 0
fi
echo "FAILED: stdlib/public/Platform/OSX/x86_64/Darwin.o"
echo "error: 'semaphore.h' file not found"
echo "ninja: build stopped: subcommand failed."
exit 1
EOF
chmod +x "$fake/ninja"

run overlay 1
if [ "$rc" -ne 0 ]; then
  echo "  OK  rc=$rc"
else
  echo "  FAIL expected nonzero after overlay ninja failure"; fail=1
fi
printf '%s\n' "$out" | grep -q 'expected ELF gold wall' \
  && { echo "  FAIL gold wall still treated as allowed"; fail=1; } \
  || echo "  OK  gold wall is not an allowed core skip"
printf '%s\n' "$out" | grep -q 'ninja: FAILED rc=' \
  && echo "  OK  overlay ninja propagated" \
  || { echo "  FAIL overlay failure swallowed"; fail=1; }
printf '%s\n' "$out" | grep -q 'build_stdlib done' \
  && { echo "  FAIL printed done after overlay failure"; fail=1; } \
  || echo "  OK  did not claim done"
printf '%s\n' "$out" | grep -E 'ninja overlay swiftObjectiveC|will ninja.*swiftObjectiveC' \
  && { echo "  FAIL asked ninja for swiftObjectiveC"; fail=1; } \
  || echo "  OK  did not invoke missing ObjectiveC target"
# Fail-fast is gone: every selected overlay is still attempted.
for t in swift_Concurrency-macosx-x86_64 swiftSynchronization-macosx-x86_64 \
         swift_StringProcessing-macosx-x86_64 swift_Builtin_float-macosx-x86_64 \
         swift_RegexParser-macosx-x86_64 swiftObservation-macosx-x86_64 \
         swiftDarwin-macosx-x86_64; do
  printf '%s\n' "$out" | grep -q "ninja overlay $t" \
    && echo "  OK  attempted $t" \
    || { echo "  FAIL did not attempt $t"; fail=1; }
  printf '%s\n' "$out" | grep -q "OVERLAY $t FAILED" \
    && echo "  OK  scoreboard FAILED $t" \
    || { echo "  FAIL missing OVERLAY $t FAILED"; fail=1; }
done
printf '%s\n' "$out" | grep -q 'OVERLAY swiftObjectiveC-macosx-x86_64 CANNOT_STAGE_XCODE_DARWIN_OVERLAYS' \
  && echo "  OK  scoreboard ObjectiveC CANNOT" \
  || { echo "  FAIL missing ObjectiveC scoreboard CANNOT"; fail=1; }
printf '%s\n' "$out" | grep -q 'OVERLAY swift_DarwinFoundation1-macosx-x86_64 CANNOT_STAGE_XCODE_DARWIN_OVERLAYS' \
  && echo "  OK  scoreboard DarwinFoundation1 CANNOT" \
  || { echo "  FAIL missing DarwinFoundation1 scoreboard CANNOT"; fail=1; }
printf '%s\n' "$out" | grep -q 'OVERLAY swift_DarwinFoundation2-macosx-x86_64 CANNOT_STAGE_XCODE_DARWIN_OVERLAYS' \
  && echo "  OK  scoreboard DarwinFoundation2 CANNOT" \
  || { echo "  FAIL missing DarwinFoundation2 scoreboard CANNOT"; fail=1; }
printf '%s\n' "$out" | grep -q 'OVERLAY swift_DarwinFoundation3-macosx-x86_64 CANNOT_STAGE_XCODE_DARWIN_OVERLAYS' \
  && echo "  OK  scoreboard DarwinFoundation3 CANNOT" \
  || { echo "  FAIL missing DarwinFoundation3 scoreboard CANNOT"; fail=1; }

echo
echo "=== core gold wall is NOT allowed (lld is the linker) ==="
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
      tool=${args[$i]:-}
      i=$((i+1))
      case "$tool" in
        targets) targets_mode=1 ;;
        commands)
          echo "swiftc -sdk /sdk/MacOSX.sdk -c Darwin.swift"
          exit 0 ;;
        query)
          echo "${args[$i]:-unknown}:"
          echo "  input: phony"
          exit 0 ;;
      esac
      continue
      ;;
    *) target=$a; i=$((i+1)); continue ;;
  esac
done
if [ "$targets_mode" = 1 ]; then
  echo "swiftCore-macosx-x86_64: phony"
  exit 0
fi
echo "FAILED: lib/swift/macosx/x86_64/libswiftCore.so"
echo "clang++: error: invalid linker name in argument '-fuse-ld=gold'"
echo "ninja: build stopped: subcommand failed."
exit 1
EOF
chmod +x "$fake/ninja"
run gold 0
if [ "$rc" -ne 0 ]; then
  echo "  OK  rc=$rc"
else
  echo "  FAIL gold wall was swallowed"; fail=1
fi
printf '%s\n' "$out" | grep -q 'CANNOT_LINKER_GOLD_REJECTED' \
  && echo "  OK  named CANNOT_LINKER_GOLD_REJECTED" \
  || { echo "  FAIL missing CANNOT_LINKER_GOLD_REJECTED"; fail=1; }
printf '%s\n' "$out" | grep -q 'expected ELF gold wall' \
  && { echo "  FAIL still printed expected ELF gold wall"; fail=1; } \
  || echo "  OK  did not treat gold as expected"
printf '%s\n' "$out" | grep -q 'build_stdlib done' \
  && { echo "  FAIL printed done after gold failure"; fail=1; } \
  || echo "  OK  did not claim done"

echo
echo "=== helper rc=126 (not ninja) prints CANNOT_NOT_EXECUTABLE + ls -l ==="
# Core ninja succeeds. A non-+x helper after ninja is the stamp-restage
# case: ninja already returned 0/1, then bash 126s with no CANNOT line
# unless ERR is trapped. Also plant shims without +x so the pre-ninja
# chmod + ls -l is visible.
cat > "$fake/ninja" <<'EOF'
#!/bin/bash
args=("$@")
i=0
while [ $i -lt ${#args[@]} ]; do
  a=${args[$i]}
  case "$a" in
    -C) i=$((i+2)); continue ;;
    -j) i=$((i+2)); continue ;;
    -t)
      i=$((i+1)); tool=${args[$i]:-}; i=$((i+1))
      case "$tool" in
        targets)
          echo "swiftCore-macosx-x86_64: phony"
          echo "swiftDarwin-macosx-x86_64: phony"
          exit 0 ;;
        commands)
          echo "clang++ -target x86_64-apple-macosx13.0 -sdk /sdk/MacOSX.sdk -isysroot /sdk/MacOSX.sdk -c Darwin.swift"
          exit 0 ;;
        query)
          echo "${args[$i]:-unknown}:"
          echo "  input: phony"
          exit 0 ;;
      esac
      continue ;;
    *) i=$((i+1)); continue ;;
  esac
done
exit 0
EOF
chmod +x "$fake/ninja"
mkdir -p "$tmp/work/shims"
printf '#!/bin/bash\nexit 0\n' > "$tmp/work/shims/clang++"
printf '#!/bin/bash\nexit 0\n' > "$tmp/work/shims/clang"
printf '#!/bin/bash\nexit 0\n' > "$tmp/work/shims/lipo"
chmod a-x "$tmp/work/shims/clang++" "$tmp/work/shims/clang" "$tmp/work/shims/lipo"
noexec=$tmp/not-executable
printf '#!/bin/bash\necho should-not-run\n' > "$noexec"
chmod a-x "$noexec"
SWIFTCORE_TEST_RC126_EXEC=$noexec run rc126 1
unset SWIFTCORE_TEST_RC126_EXEC
if [ "$rc" -eq 126 ]; then
  echo "  OK  rc=126"
else
  echo "  FAIL expected rc=126 got rc=$rc"; fail=1
fi
printf '%s\n' "$out" | grep -q 'CANNOT_NOT_EXECUTABLE rc=126 cmd=' \
  && echo "  OK  named CANNOT_NOT_EXECUTABLE with cmd=" \
  || { echo "  FAIL missing CANNOT_NOT_EXECUTABLE cmd="; fail=1; }
printf '%s\n' "$out" | grep -q 'tried-exec ls -l:' \
  && echo "  OK  printed ls -l of the attempted exec" \
  || { echo "  FAIL missing tried-exec ls -l"; fail=1; }
printf '%s\n' "$out" | grep -F "$noexec" \
  && echo "  OK  named the non-+x helper" \
  || { echo "  FAIL missing helper path"; fail=1; }
printf '%s\n' "$out" | grep -q 'build_stdlib: compiler shims (ls -l):' \
  && echo "  OK  printed shims ls -l before ninja" \
  || { echo "  FAIL missing shims ls -l"; fail=1; }
# chmod +x must have restored the planted shims before ninja.
if printf '%s\n' "$out" | grep -E 'compiler shims \(ls -l\):' -A6 | grep -E 'rwx.*clang\+\+' >/dev/null; then
  echo "  OK  clang++ shim is +x in pre-ninja ls -l"
else
  echo "  FAIL clang++ shim was not +x after ensure_compiler_shims"
  printf '%s\n' "$out" | grep -E 'compiler shims' -A8 || true
  fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- failing ninja makes build_stdlib.sh exit non-zero"
  exit 0
fi
echo "FAIL"
exit 1
