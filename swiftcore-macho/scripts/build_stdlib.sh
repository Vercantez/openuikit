#!/bin/bash
# One-command Darwin stdlib cross-build on Linux.
#
# Recorded recipe: docs/BUILD_LOG.md §7, retargeted via scripts/guest_arch.inc.
# Arm64 on Graviton is still the default on an aarch64 host. This script on an
# x86_64 host produces the x86_64 slice beside the committed arm64 artifacts.
#
# Operator (16 vCPU x86_64 Ubuntu 24.04, clang-18, Swift 6.2.4).
# SWIFT_TOOLCHAIN honors /opt/swift (do not symlink it to /opt/swift624):
#
#   NINJA_JOBS=16 SWIFTCORE_DARWIN_ARCH=x86_64 SWIFTCORE_OVERLAYS=1 \
#     SWIFTCORE_BUILD_DISPATCH=1 SWIFT_TOOLCHAIN=/opt/swift \
#     bash swiftcore-macho/scripts/build_stdlib.sh
#
# SWIFTCORE_OVERLAYS=1 fetches swift-experimental-string-processing and
# (via BUILD_DISPATCH default 1) swift-corelibs-libdispatch at the
# swift-6.2.4-RELEASE commits in guest_arch.inc. CMake is refused with
# CANNOT_FETCH_*_SOURCE if either checkout is missing.

# This 4-vCPU / 15 GiB cloud-agent VM uses NINJA_JOBS=2. It will configure and
# compile as far as RAM/time allow; it will not fake a dylib. Execution of the
# linked guest is a positive machorun-loader probe in verify_hello.sh, not a
# VM assumption.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SWIFTCORE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
OPENUIKIT_ROOT=$(cd "$SWIFTCORE_ROOT/.." && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/ninja_checked.inc"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/overlay_targets.inc"

W=${W:-$HOME/work}
B=${B:-$W/build}
MACHORUN=${MACHORUN:-$OPENUIKIT_ROOT/machorun}
NINJA_JOBS=${NINJA_JOBS:-2}
STOP_AFTER=${STOP_AFTER:-}   # print-flags | configure | ninja-first | link | all
# Overlays imply dispatch: phase-2 needs _Concurrency as well as
# _StringProcessing / Synchronization. Operator may still set
# SWIFTCORE_BUILD_DISPATCH=1 explicitly.
if [ "${SWIFTCORE_OVERLAYS:-0}" = 1 ]; then
  SWIFTCORE_BUILD_DISPATCH=${SWIFTCORE_BUILD_DISPATCH:-1}
fi
export W B TC SWIFTCORE_DARWIN_ARCH SWIFT_HOST_VARIANT_ARCH
export SWIFTCORE_OVERLAYS SWIFTCORE_BUILD_DISPATCH
export SWIFT_TOOLCHAIN SWIFT_PATH_TO_STRING_PROCESSING_SOURCE SWIFT_PATH_TO_LIBDISPATCH_SOURCE

# Dry path: dump cmake argv and exit. Does not touch MACHORUN/darwin, does not
# run check_undefined. Operator overlay runs still go through ninja + scoreboard.
if [ "${1:-}" = --print-flags ] || [ "${STOP_AFTER:-}" = print-flags ]; then
  bash "$SCRIPT_DIR/configure.sh" --print-flags
  exit 0
fi

mkdir -p "$W"
step() { printf '\n==== %s ====\n' "$*"; }

# Every ninja invocation reports its status. Core must link with lld
# (-DSWIFT_USE_LINKER=lld). Overlay targets are attempted independently
# (scoreboard OVERLAY <name> built|FAILED|CANNOT_*); any overlay failure
# keeps the script rc non-zero. A core ninja failure is not swallowed so
# overlays can still run (they depend on libswiftCore.so; lld is what
# lets that edge succeed).
run_stdlib_ninja() {
  local core_st=0 overlay_rc=0
  step "ninja $SWIFTCORE_NINJA_CORE -j$NINJA_JOBS"
  ninja_checked "$W/build.log" -C "$B" -j "$NINJA_JOBS" \
    "$SWIFTCORE_NINJA_CORE" || core_st=$?
  obj_n=$(find "$B" -name '*.o' 2>/dev/null | wc -l)
  echo "objects=$obj_n"
  if [ "$core_st" -ne 0 ]; then
    overlay_rc=$core_st
    so=$B/lib/swift/macosx/${SWIFTCORE_DARWIN_ARCH}/libswiftCore.so
    if [ ! -e "$so" ]; then
      echo "CANNOT_ELF_SO_LLD: ninja $SWIFTCORE_NINJA_CORE rc=$core_st did not produce $so (lld is configured; this is a real link wall, not gold)" >&2
    fi
  fi
  if [ "$STOP_AFTER" = ninja-first ]; then
    echo "STOP_AFTER=ninja-first — first ninja finished. objects=$obj_n core_st=$core_st"
    if [ "$core_st" -ne 0 ]; then
      exit "$core_st"
    fi
    exit 0
  fi
  if [ "${SWIFTCORE_OVERLAYS:-0}" = 1 ]; then
    local sel_rc=0 ninja_st=0 t
    # Attempt every selected overlay even if select named a CANNOT, so one
    # operator run measures all five. ninja itself rebuilds real deps of
    # the requested target; we do not skip later names because an earlier
    # ninja failed.
    set +e
    overlay_select_targets "$B" "$SWIFTCORE_DARWIN_ARCH"
    sel_rc=$?
    set -e
    if [ "$sel_rc" -ne 0 ]; then
      overlay_rc=$sel_rc
    fi
    if [ ${#OVERLAY_NINJA_TARGETS[@]} -gt 0 ]; then
      for t in "${OVERLAY_NINJA_TARGETS[@]}"; do
        step "ninja overlay $t"
        ninja_st=0
        ninja_checked "$W/build.log" -C "$B" -j "$NINJA_JOBS" "$t" || ninja_st=$?
        if [ "$ninja_st" -eq 0 ]; then
          OVERLAY_STATUS[$t]=built
        else
          OVERLAY_STATUS[$t]=FAILED
          if [ "$overlay_rc" -eq 0 ]; then
            overlay_rc=$ninja_st
          fi
        fi
      done
    fi
    overlay_print_scoreboard "$SWIFTCORE_DARWIN_ARCH"
    overlay_list_products "$B/lib/swift/macosx"
    if [ "$overlay_rc" -ne 0 ]; then
      echo "overlay: FAILED rc=$overlay_rc" >&2
      return "$overlay_rc"
    fi
  fi
  if [ "$core_st" -ne 0 ]; then
    echo "core: FAILED rc=$core_st" >&2
    return "$core_st"
  fi
}

# Test hook: skip bootstrap/cmake so test_ninja_rc.sh can prove a failing
# ninja target makes this script exit non-zero.
if [ "${SWIFTCORE_NINJA_HARNESS:-0}" = 1 ]; then
  mkdir -p "$B"
  run_stdlib_ninja
  echo "build_stdlib done darwin_arch=$SWIFTCORE_DARWIN_ARCH harness=1"
  exit 0
fi

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
# Overlay/stdlib needs .tbd files (gen_tbd CHECKs 0–4). CHECK 5 is a
# host-fallback audit of $MACHORUN/darwin — a tree this script does not own
# on the operator box (phase2 parks arm64 libswiftCore at usr/lib-arm64-park).
# Probe the loader later in verify_hello.sh; do not gate overlays on that audit.
export MACHORUN_SKIP_HOSTFALLBACK_CHECK=1
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
# 6. Build. Darwin-target shared links use -fuse-ld=lld (not gold). Overlay
#    ninja failures are recorded on the scoreboard; every selected overlay is
#    still attempted, then the script exits non-zero if any failed.
# ---------------------------------------------------------------------------
run_stdlib_ninja

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
  bash "$SCRIPT_DIR/verify_hello.sh"
else
  echo "NO libswiftCore.dylib at $CORE_OUT"
  echo "objects compiled: $obj_n"
  echo "This VM did not produce the dylib. Operator command:"
  echo "  NINJA_JOBS=16 SWIFTCORE_DARWIN_ARCH=x86_64 SWIFTCORE_OVERLAYS=1 \\"
  echo "    SWIFTCORE_BUILD_DISPATCH=1 SWIFT_TOOLCHAIN=/opt/swift \\"
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
