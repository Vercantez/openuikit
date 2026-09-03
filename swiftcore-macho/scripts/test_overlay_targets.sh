#!/bin/bash
# Overlay ninja names come from `ninja -t targets`. Missing required targets
# refuse with CANNOT_OVERLAY_TARGET_ABSENT. ObjectiveC is not invoked.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/overlay_targets.inc"
fail=0
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

echo "=== dump with required overlays + Darwin, no ObjectiveC ==="
cat > "$tmp/targets" <<'EOF'
swift_Concurrency-macosx-x86_64: phony
swiftSynchronization-macosx-x86_64: phony
swift_StringProcessing-macosx-x86_64: phony
swift_Builtin_float-macosx-x86_64: phony
swift_RegexParser-macosx-x86_64: phony
swiftObservation-macosx-x86_64: phony
swiftDarwin-macosx-x86_64: phony
swiftCore-macosx-x86_64: phony
EOF
set +e
NINJA_TARGETS_DUMP="$tmp/targets" overlay_select_targets /no/build x86_64 >"$tmp/out1" 2>&1
rc=$?
set -e
out=$(cat "$tmp/out1")
printf '%s\n' "$out"
[ "$rc" -eq 0 ] && echo "  OK  rc=0" || { echo "  FAIL rc=$rc"; fail=1; }
printf '%s\n' "$out" | grep -q 'will ninja.*swiftDarwin-macosx-x86_64' \
  && echo "  OK  Darwin in ninja list" || { echo "  FAIL Darwin not selected"; fail=1; }
printf '%s\n' "$out" | grep -q 'CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=swiftObjectiveC-macosx-x86_64' \
  && echo "  OK  ObjectiveC named CANNOT" || { echo "  FAIL missing ObjectiveC CANNOT"; fail=1; }
printf '%s\n' "$out" | grep -q 'CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=swift_DarwinFoundation1-macosx-x86_64' \
  && echo "  OK  DarwinFoundation1 named CANNOT" || { echo "  FAIL missing DarwinFoundation1 CANNOT"; fail=1; }
printf '%s\n' "$out" | grep -q 'CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=swift_DarwinFoundation2-macosx-x86_64' \
  && echo "  OK  DarwinFoundation2 named CANNOT" || { echo "  FAIL missing DarwinFoundation2 CANNOT"; fail=1; }
printf '%s\n' "$out" | grep -q 'CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=swift_DarwinFoundation3-macosx-x86_64' \
  && echo "  OK  DarwinFoundation3 named CANNOT" || { echo "  FAIL missing DarwinFoundation3 CANNOT"; fail=1; }
printf '%s\n' "$out" | grep -q 'CANNOT_STAGE_XCODE_DARWIN_OVERLAYS target=swift_errno-macosx-x86_64' \
  && echo "  OK  _errno named CANNOT" || { echo "  FAIL missing _errno CANNOT"; fail=1; }
printf '%s\n' "$out" | grep -q 'will ninja.*swiftObjectiveC' \
  && { echo "  FAIL ObjectiveC still in will-ninja list"; fail=1; } \
  || echo "  OK  ObjectiveC not ninja'd"
[ "${OVERLAY_STATUS[swiftObjectiveC-macosx-x86_64]:-}" = CANNOT_STAGE_XCODE_DARWIN_OVERLAYS ] \
  && echo "  OK  OVERLAY_STATUS ObjectiveC CANNOT" \
  || { echo "  FAIL OVERLAY_STATUS ObjectiveC=${OVERLAY_STATUS[swiftObjectiveC-macosx-x86_64]:-unset}"; fail=1; }

echo
echo "=== missing required _StringProcessing is CANNOT_OVERLAY_TARGET_ABSENT ==="
cat > "$tmp/targets" <<'EOF'
swift_Concurrency-macosx-x86_64: phony
swiftSynchronization-macosx-x86_64: phony
swift_Builtin_float-macosx-x86_64: phony
swift_RegexParser-macosx-x86_64: phony
swiftObservation-macosx-x86_64: phony
swiftDarwin-macosx-x86_64: phony
EOF
set +e
NINJA_TARGETS_DUMP="$tmp/targets" overlay_select_targets /no/build x86_64 >"$tmp/out2" 2>&1
rc=$?
set -e
out=$(cat "$tmp/out2")
printf '%s\n' "$out"
[ "$rc" -eq 2 ] && echo "  OK  rc=2" || { echo "  FAIL rc=$rc want 2"; fail=1; }
printf '%s\n' "$out" | grep -q 'CANNOT_OVERLAY_TARGET_ABSENT target=swift_StringProcessing-macosx-x86_64' \
  && echo "  OK  named the missing required target" \
  || { echo "  FAIL missing CANNOT_OVERLAY_TARGET_ABSENT"; fail=1; }
[ "${OVERLAY_STATUS[swift_StringProcessing-macosx-x86_64]:-}" = CANNOT_OVERLAY_TARGET_ABSENT ] \
  && echo "  OK  OVERLAY_STATUS StringProcessing CANNOT" \
  || { echo "  FAIL OVERLAY_STATUS StringProcessing=${OVERLAY_STATUS[swift_StringProcessing-macosx-x86_64]:-unset}"; fail=1; }
printf '%s\n' "${OVERLAY_NINJA_TARGETS[*]}" | grep -q 'swift_Concurrency-macosx-x86_64' \
  && echo "  OK  still selected Concurrency for ninja" \
  || { echo "  FAIL missing required did not keep other ninja targets"; fail=1; }

echo
echo "=== live ninja -t targets from overlay-cmake-proof (if present) ==="
proof=/tmp/overlay-cmake-proof
if [ -f "$proof/build.ninja" ]; then
  set +e
  out=$(unset NINJA_TARGETS_DUMP; overlay_select_targets "$proof" x86_64 2>&1)
  rc=$?
  set -e
  printf '%s\n' "$out"
  [ "$rc" -eq 0 ] && echo "  OK  live graph rc=0" || { echo "  FAIL live rc=$rc"; fail=1; }
  printf '%s\n' "$out" | grep -q 'swiftObjectiveC' && ! printf '%s\n' "$out" | grep -q 'will ninja.*swiftObjectiveC' \
    && echo "  OK  live graph does not ninja ObjectiveC" \
    || {
      if printf '%s\n' "$out" | grep -q 'will ninja.*swiftObjectiveC'; then
        echo "  FAIL live graph selected ObjectiveC"; fail=1
      else
        echo "  OK  live graph has no ObjectiveC to ninja"
      fi
    }
else
  echo "  skip (no $proof/build.ninja)"
fi

echo
echo "=== overlay_flatten_unarch / overlay_copy_so_as_dylib ==="
mkdir -p "$tmp/build/lib/swift/macosx/x86_64"
echo so > "$tmp/build/lib/swift/macosx/x86_64/libswiftCore.so"
overlay_flatten_unarch "$tmp/build" x86_64
overlay_copy_so_as_dylib "$tmp/build" x86_64
[ -L "$tmp/build/lib/swift/macosx/libswiftCore.so" ] \
  && echo "  OK  unarch symlink" || { echo "  FAIL missing unarch symlink"; fail=1; }
[ -f "$tmp/build/lib/swift/macosx/x86_64/libswiftCore.dylib" ] \
  && echo "  OK  .dylib beside .so" || { echo "  FAIL missing .dylib"; fail=1; }

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS -- overlay targets derived from ninja -t targets; ObjectiveC gated"
  exit 0
fi
echo "FAIL"
exit 1
