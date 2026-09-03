#!/bin/bash
# One-command Darwin stdlib cross-build on Linux.
#
# Recorded recipe: docs/BUILD_LOG.md §7, retargeted via scripts/guest_arch.inc.
# Arm64 on Graviton is still the default on an aarch64 host. This script on an
# x86_64 host produces the x86_64 slice beside the committed arm64 artifacts.
#
# Operator (16 vCPU x86_64 Ubuntu 24.04, clang-18, Swift 6.2.4):
#
#   NINJA_JOBS=16 SWIFTCORE_DARWIN_ARCH=x86_64 SWIFTCORE_OVERLAYS=1 \
#     bash swiftcore-macho/scripts/build_stdlib.sh
#
# This 4-vCPU / 15 GiB cloud-agent VM uses NINJA_JOBS=2. It will configure and
# compile as far as RAM/time allow; it will not fake a dylib. Execution of the
# linked guest is refused here — that is the operator host's job.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SWIFTCORE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
OPENUIKIT_ROOT=$(cd "$SWIFTCORE_ROOT/.." && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"

W=${W:-$HOME/work}
B=${B:-$W/build}
MACHORUN=${MACHORUN:-$OPENUIKIT_ROOT/machorun}
NINJA_JOBS=${NINJA_JOBS:-2}
STOP_AFTER=${STOP_AFTER:-}   # configure | ninja-first | link | all
export W B TC SWIFTCORE_DARWIN_ARCH SWIFT_HOST_VARIANT_ARCH

mkdir -p "$W"
step() { printf '\n==== %s ====\n' "$*"; }

# ---------------------------------------------------------------------------
# 0. Recorded arm64 artifacts must still be the arm64 slice after we finish.
# ---------------------------------------------------------------------------
ARM_CORE=$SWIFTCORE_ROOT/artifacts/swift-macosx/arm64/libswiftCore.dylib
ARM_SHA_BEFORE=
if [ -f "$ARM_CORE" ]; then
  ARM_SHA_BEFORE=$(sha256sum "$ARM_CORE" | awk '{print $1}')
  echo "arm64 libswiftCore sha256 before: $ARM_SHA_BEFORE"
fi

# ---------------------------------------------------------------------------
# 1. Sources + toolchain
# ---------------------------------------------------------------------------
step "bootstrap sources (pin $SWIFT_PIN_COMMIT)"
bash "$SCRIPT_DIR/bootstrap_box.sh"

# ---------------------------------------------------------------------------
# 2. x86_64 Darwin userland + .tbd (PR #7). Park leftover arm64 dylibs so
#    gen_tbd CHECK 4 is not a mixed-slice coin toss.
# ---------------------------------------------------------------------------
step "machorun darwin userland for $SWIFTCORE_DARWIN_ARCH"
export DARWIN_CLANG="${DARWIN_CLANG:-clang-18}"
export CC="${CC:-clang-18}"
case "$SWIFTCORE_DARWIN_ARCH" in
  x86_64) export DARWIN_TARGET="${DARWIN_TARGET:-x86_64-apple-macos11}" ;;
  arm64)  export DARWIN_TARGET="${DARWIN_TARGET:-arm64-apple-macos11}" ;;
esac
park=$MACHORUN/darwin/usr/lib-arm64-park
if [ "$SWIFTCORE_DARWIN_ARCH" = x86_64 ] && [ -d "$MACHORUN/darwin/usr/lib" ]; then
  mkdir -p "$park"
  while IFS= read -r -d '' d; do
    llvm-otool-18 -hv "$d" 2>/dev/null | grep -Eq 'MH_MAGIC_64[[:space:]]+ARM64' || continue
    rel=${d#"$MACHORUN/darwin/usr/lib/"}
    mkdir -p "$park/$(dirname "$rel")"
    mv "$d" "$park/$rel"
    echo "  parked arm64 $rel -> darwin/usr/lib-arm64-park"
  done < <(find "$MACHORUN/darwin/usr/lib" -type f -name '*.dylib' -print0)
fi

sh "$MACHORUN/scripts/build.sh" loader
sh "$MACHORUN/scripts/build.sh" darwin
bash "$MACHORUN/scripts/build_objc4.sh"
# quartz is not a libswiftCore link input; skip unless asked.
if [ "${SWIFTCORE_BUILD_QUARTZ:-0}" = 1 ]; then
  bash "$MACHORUN/scripts/build_quartz.sh"
fi
sh "$MACHORUN/scripts/build.sh" tbd
file -b "$MACHORUN/darwin/usr/lib/libSystem.B.dylib"
ls "$MACHORUN/sdk/usr/lib"/*.tbd | wc -l | sed 's/^/tbds generated: /'

# ---------------------------------------------------------------------------
# 3. Stage the Swift sysroot
# ---------------------------------------------------------------------------
step "stage_sdk"
ln -sfn "$MACHORUN" "$W/machorun"
ln -sfn "$SWIFTCORE_ROOT/sdk/compat" "$W/compat"
ln -sfn "$SWIFTCORE_ROOT/tests" "$W/tests" 2>/dev/null || true
bash "$SCRIPT_DIR/stage_sdk.sh"
tbd_n=$(find "$W/sdk/MacOSX.sdk" -name '*.tbd' | wc -l)
echo "sysroot tbds: $tbd_n"
[ "$tbd_n" -gt 0 ] || {
  echo "build_stdlib: REFUSING empty tbd set — ld64 would see a lie" >&2
  exit 2
}

# ---------------------------------------------------------------------------
# 4. Patches. Legacy image-reg is opt-in and load-bearing for machorun.
#    Patch 6 (widen isa) is arm64-only and OFF.
# ---------------------------------------------------------------------------
step "apply_patches"
export SWIFTCORE_MACHO_LEGACY_IMAGE_REG=1
python3 "$SCRIPT_DIR/apply_patches.py" "$W/swift"

# ---------------------------------------------------------------------------
# 5. Configure
# ---------------------------------------------------------------------------
step "configure darwin_arch=$SWIFTCORE_DARWIN_ARCH host_arch=$SWIFT_HOST_VARIANT_ARCH"
bash "$SCRIPT_DIR/configure.sh"
grep -E 'Architectures:|triple:|Module triple:|Building Swift standard' "$W/configure.log" || true
if [ "$STOP_AFTER" = configure ]; then
  echo "STOP_AFTER=configure — cmake is done. ninja -C $B -j$NINJA_JOBS $SWIFTCORE_NINJA_CORE"
  exit 0
fi

# ---------------------------------------------------------------------------
# 6. Build. The ninja link edge is ELF (.so); that is expected (BUILD_LOG wall 7).
# ---------------------------------------------------------------------------
step "ninja $SWIFTCORE_NINJA_CORE -j$NINJA_JOBS"
set +e
ninja -C "$B" -j "$NINJA_JOBS" "$SWIFTCORE_NINJA_CORE" 2>&1 | tee "$W/build.log"
ninja_st=${PIPESTATUS[0]}
set -e
obj_n=$(find "$B" -name '*.o' | wc -l)
echo "ninja exit=$ninja_st objects=$obj_n"
if [ "$STOP_AFTER" = ninja-first ]; then
  echo "STOP_AFTER=ninja-first — first ninja finished. objects=$obj_n"
  exit 0
fi

# Overlay targets, best-effort after core objects exist. Each is a separate
# ninja invocation so a wall names itself.
if [ "${SWIFTCORE_OVERLAYS:-0}" = 1 ]; then
  for t in \
      "$SWIFTCORE_NINJA_CONCURRENCY" \
      "swiftSynchronization-macosx-${SWIFTCORE_DARWIN_ARCH}" \
      "swift_StringProcessing-macosx-${SWIFTCORE_DARWIN_ARCH}" \
      "swift_Builtin_float-macosx-${SWIFTCORE_DARWIN_ARCH}" \
      "swiftDarwin-macosx-${SWIFTCORE_DARWIN_ARCH}" \
      "swiftObjectiveC-macosx-${SWIFTCORE_DARWIN_ARCH}"
  do
    step "ninja overlay $t"
    set +e
    ninja -C "$B" -j "$NINJA_JOBS" "$t" 2>&1 | tee -a "$W/build.log"
    echo "overlay $t exit=${PIPESTATUS[0]}"
    set -e
  done
fi

# ---------------------------------------------------------------------------
# 7. Mach-O link from ninja's object list
# ---------------------------------------------------------------------------
step "link Mach-O dylibs"
for lib in libswiftCore libswift_Concurrency libswiftSynchronization \
           libswift_StringProcessing libswift_Builtin_float \
           libswiftDarwin libswiftObjectiveC; do
  if grep -q -- "-o lib/swift/macosx/${SWIFTCORE_DARWIN_ARCH}/${lib}.so" "$W/build.log" 2>/dev/null; then
    bash "$SCRIPT_DIR/link_macho_dylib.sh" "$W/build.log" "$lib" || echo "link $lib failed (recorded)"
  else
    echo "no ninja link line for $lib — not produced this run"
  fi
done

if [ "$STOP_AFTER" = link ]; then
  echo "STOP_AFTER=link"
  exit 0
fi

# ---------------------------------------------------------------------------
# 8. Verify + stage. Refuse to overwrite the arm64 slice.
# ---------------------------------------------------------------------------
CORE_OUT=$B/lib/swift/${SWIFTCORE_STDLIB_DIR}/libswiftCore.dylib
if [ -f "$CORE_OUT" ]; then
  step "verify $CORE_OUT"
  bash "$SCRIPT_DIR/verify.sh"
  bash "$SCRIPT_DIR/stage_artifacts.sh"
  bash "$SCRIPT_DIR/verify_hello.sh" || true
else
  echo "NO libswiftCore.dylib at $CORE_OUT"
  echo "objects compiled: $obj_n"
  echo "This VM did not produce the dylib. Operator command:"
  echo "  NINJA_JOBS=16 SWIFTCORE_DARWIN_ARCH=x86_64 SWIFTCORE_OVERLAYS=1 \\"
  echo "    bash swiftcore-macho/scripts/build_stdlib.sh"
  exit 2
fi

if [ -n "$ARM_SHA_BEFORE" ]; then
  ARM_SHA_AFTER=$(sha256sum "$ARM_CORE" | awk '{print $1}')
  if [ "$ARM_SHA_BEFORE" != "$ARM_SHA_AFTER" ]; then
    echo "REFUSING: arm64 libswiftCore sha256 changed $ARM_SHA_BEFORE -> $ARM_SHA_AFTER" >&2
    exit 2
  fi
  echo "arm64 libswiftCore sha256 unchanged: $ARM_SHA_AFTER"
fi

echo "build_stdlib done darwin_arch=$SWIFTCORE_DARWIN_ARCH objects=$obj_n"
