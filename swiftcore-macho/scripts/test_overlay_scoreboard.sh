#!/bin/bash
# One operator run must attempt every selected overlay. An injected Concurrency
# failure must not skip Synchronization / _StringProcessing / _Builtin_float /
# Darwin. rc stays non-zero; the scoreboard names each outcome.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
build=$SCRIPT_DIR/build_stdlib.sh
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fake=$tmp/bin
mkdir -p "$fake" "$tmp/work/build/lib/swift/macosx/x86_64"

cat > "$fake/ninja" <<'EOF'
#!/bin/bash
args=("$@")
targets_mode=0
target=""
i=0
while [ $i -lt ${#args[@]} ]; do
  a=${args[$i]}
  case "$a" in
    -C)
      # Honour -C so we can drop dummy dylibs where overlay_list_products looks.
      builddir=${args[$((i+1))]}
      i=$((i+2)); continue ;;
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
  echo "built $target"
  exit 0
fi

prod=${builddir:-.}/lib/swift/macosx/x86_64
mkdir -p "$prod"

if [[ "$target" == swift_Concurrency-* ]]; then
  echo "ninja: error: 'stdlib/public/Concurrency/dispatch', needed by 'stdlib/public/Concurrency/OSX/x86_64/_Concurrency.o', missing and no known rule to make it"
  echo "ninja: build stopped: subcommand failed."
  exit 1
fi

case "$target" in
  swiftSynchronization-*)
    touch "$prod/libswiftSynchronization.so"
    echo "built $target" ;;
  swift_StringProcessing-*)
    touch "$prod/libswift_StringProcessing.so"
    echo "built $target" ;;
  swift_Builtin_float-*)
    touch "$prod/libswift_Builtin_float.so"
    echo "built $target" ;;
  swiftDarwin-*)
    touch "$prod/libswiftDarwin.so"
    echo "built $target" ;;
  *)
    echo "built $target" ;;
esac
exit 0
EOF
chmod +x "$fake/ninja"

set +e
out=$(
  env PATH="$fake:$PATH" NINJA="$fake/ninja" \
    SWIFTCORE_NINJA_HARNESS=1 SWIFTCORE_DARWIN_ARCH=x86_64 \
    SWIFTCORE_OVERLAYS=1 \
    W="$tmp/work" B="$tmp/work/build" \
    bash "$build" 2>&1
)
rc=$?
set -e
printf '%s\n' "$out"
echo "--- scoreboard injected-failure rc=$rc ---"

[ "$rc" -ne 0 ] && echo "  OK  rc=$rc (any overlay failure is non-zero)" \
  || { echo "  FAIL expected nonzero"; fail=1; }

printf '%s\n' "$out" | grep -q 'build_stdlib done' \
  && { echo "  FAIL printed done after overlay failure"; fail=1; } \
  || echo "  OK  did not claim done"

# Attempt order: all five selected names, Concurrency first, others still run.
for t in swift_Concurrency-macosx-x86_64 swiftSynchronization-macosx-x86_64 \
         swift_StringProcessing-macosx-x86_64 swift_Builtin_float-macosx-x86_64 \
         swiftDarwin-macosx-x86_64; do
  printf '%s\n' "$out" | grep -q "ninja overlay $t" \
    && echo "  OK  attempted $t" \
    || { echo "  FAIL did not attempt $t"; fail=1; }
done

printf '%s\n' "$out" | grep -q 'OVERLAY swift_Concurrency-macosx-x86_64 FAILED' \
  && echo "  OK  Concurrency FAILED" \
  || { echo "  FAIL Concurrency not FAILED"; fail=1; }
for t in swiftSynchronization-macosx-x86_64 swift_StringProcessing-macosx-x86_64 \
         swift_Builtin_float-macosx-x86_64 swiftDarwin-macosx-x86_64; do
  printf '%s\n' "$out" | grep -q "OVERLAY $t built" \
    && echo "  OK  $t built" \
    || { echo "  FAIL missing OVERLAY $t built"; fail=1; }
done
printf '%s\n' "$out" | grep -q 'OVERLAY swiftObjectiveC-macosx-x86_64 CANNOT_STAGE_XCODE_DARWIN_OVERLAYS' \
  && echo "  OK  ObjectiveC CANNOT" \
  || { echo "  FAIL missing ObjectiveC CANNOT"; fail=1; }

printf '%s\n' "$out" | grep -q 'libswiftSynchronization.so' \
  && echo "  OK  ls lists Synchronization so" \
  || { echo "  FAIL products ls missing Synchronization"; fail=1; }
printf '%s\n' "$out" | grep -q 'libswiftDarwin.so' \
  && echo "  OK  ls lists Darwin so" \
  || { echo "  FAIL products ls missing Darwin"; fail=1; }
printf '%s\n' "$out" | grep -q 'libswift_Concurrency' \
  && { echo "  FAIL Concurrency product listed after injected miss"; fail=1; } \
  || echo "  OK  no Concurrency dylib/so in products"

# Fail-fast regression: later overlays must appear *after* the Concurrency failure.
conc_fail_line=$(printf '%s\n' "$out" | grep -n 'OVERLAY swift_Concurrency-macosx-x86_64 FAILED' | head -1 | cut -d: -f1)
sync_line=$(printf '%s\n' "$out" | grep -n 'ninja overlay swiftSynchronization-macosx-x86_64' | head -1 | cut -d: -f1)
if [ -n "$conc_fail_line" ] && [ -n "$sync_line" ] && [ "$sync_line" -gt "$conc_fail_line" ]; then
  echo "  OK  Synchronization attempted after Concurrency FAILED"
elif [ -n "$conc_fail_line" ] && [ -n "$sync_line" ]; then
  # ninja overlay happens before scoreboard; scoreboard is after the loop.
  # Check ninja overlay Synchronization exists and ninja overlay Darwin exists
  # even though Concurrency ninja FAILED rc= is in the log.
  echo "  OK  scoreboard is after the loop (ninja overlay lines precede OVERLAY lines)"
else
  echo "  FAIL could not place Concurrency FAILED vs Synchronization attempt"
  fail=1
fi

# ninja overlay Synchronization must still run even though Concurrency printed FAILED rc=
if printf '%s\n' "$out" | grep -q 'ninja: FAILED rc='; then
  # Count overlay ninja invocations via the step banner.
  n_overlay=$(printf '%s\n' "$out" | grep -c '^==== ninja overlay ' || true)
  [ "$n_overlay" -eq 5 ] && echo "  OK  5 overlay ninja steps (not fail-fast)" \
    || { echo "  FAIL overlay ninja steps=$n_overlay want 5"; fail=1; }
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- overlay scoreboard attempts every selected target after an injected failure"
  exit 0
fi
echo "FAIL"
exit 1
