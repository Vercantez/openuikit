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
set -Eeuo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SWIFTCORE_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
OPENUIKIT_ROOT=$(cd "$SWIFTCORE_ROOT/.." && pwd)
# shellcheck disable=SC1091
. "$SCRIPT_DIR/guest_arch.inc"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/ninja_checked.inc"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/overlay_targets.inc"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/overlay_sysroot.inc"

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
export SWIFTCORE_OVERLAYS SWIFTCORE_BUILD_DISPATCH MACHORUN
export SWIFT_TOOLCHAIN SWIFT_PATH_TO_STRING_PROCESSING_SOURCE SWIFT_PATH_TO_LIBDISPATCH_SOURCE

# rc=126 is bash "found but not executable" (EACCES/ENOEXEC). The operator
# rerun of PR #43 exited 126 with no CANNOT_NOT_EXECUTABLE because that
# string was only printed when ninja_checked itself returned 126. A helper
# after ninja (overlay flatten / print / a $W/shims/* that lost +x on stamp
# restage) aborts under set -e without that line. ERR + errtrace names the
# command and ls -l of what it tried to exec.
_cannot_not_executable() {
  local cmd=${1:-unknown}
  local first expanded path
  echo "CANNOT_NOT_EXECUTABLE rc=126 cmd=$cmd" >&2
  first=${cmd%%[[:space:]]*}
  first=${first#\"}
  first=${first%\"}
  first=${first#\'}
  first=${first%\'}
  expanded=$first
  if [[ "$first" == *'$'* ]]; then
    eval "expanded=$first" 2>/dev/null || expanded=$first
  fi
  path=$expanded
  if [[ "$path" != /* ]] && command -v "$path" >/dev/null 2>&1; then
    path=$(command -v "$path")
  fi
  echo "CANNOT_NOT_EXECUTABLE tried-exec=$path" >&2
  if [ -e "$path" ] || [ -L "$path" ]; then
    ls -l "$path" 2>&1 | sed 's/^/  tried-exec ls -l: /' || true
  else
    echo "  tried-exec: not a path on disk (function or missing): $path" >&2
  fi
  echo "CANNOT_NOT_EXECUTABLE compiler shims:" >&2
  ls -l "$W/shims/clang++" "$W/shims/clang" "$W/shims/lipo" \
    "$SCRIPT_DIR/clangxx_darwin_link.py" 2>&1 | sed 's/^/  /' || true
}

_on_err() {
  local rc=$?
  trap - ERR
  if [ "$rc" -eq 126 ]; then
    _cannot_not_executable "${BASH_COMMAND:-unknown}"
  fi
  exit "$rc"
}
trap '_on_err' ERR

# Stamp restage can rewrite $W/shims without +x. chmod before every ninja
# so the driver wrap is executable; still ls -l so a leftover 126 is obvious.
ensure_compiler_rt_osx() {
  # Fake ninja harnesses must not require a Darwin SDK compile of compiler-rt.
  if [ "${SWIFTCORE_NINJA_HARNESS:-0}" = 1 ]; then
    return 0
  fi
  local sdk="${SWIFTCORE_SDKROOT:-${SWIFTCORE_DARWIN_SDK:-$W/sdk/MacOSX.sdk}}"
  if [ ! -d "$sdk" ]; then
    echo "build_stdlib: skip compiler-rt osx (no SDK at $sdk)"
    return 0
  fi
  local out="${SWIFTCORE_COMPILER_RT_OSX:-$W/build/libclang_rt.osx.a}"
  export SWIFTCORE_SDKROOT="$sdk"
  export SWIFTCORE_WORK="$W"
  export SWIFTCORE_COMPILER_RT_OSX="$out"
  bash "$SCRIPT_DIR/build_compiler_rt_osx.sh" "$out"
}

ensure_compiler_shims() {
  local s
  mkdir -p "$W/shims"
  for s in "$W/shims/clang++" "$W/shims/clang" "$W/shims/lipo"; do
    if [ -e "$s" ]; then
      chmod +x "$s" || true
    fi
  done
  chmod +x "$SCRIPT_DIR/clangxx_darwin_link.py" 2>/dev/null || true
  echo "build_stdlib: compiler shims (ls -l):"
  ls -l "$W/shims/clang++" "$W/shims/clang" "$W/shims/lipo" \
    "$SCRIPT_DIR/clangxx_darwin_link.py" 2>&1 | sed 's/^/  /' || true
  ensure_compiler_rt_osx
}

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
  ensure_compiler_shims
  step "ninja $SWIFTCORE_NINJA_CORE -j$NINJA_JOBS"
  ninja_checked "$W/build.log" -C "$B" -j "$NINJA_JOBS" \
    "$SWIFTCORE_NINJA_CORE" || core_st=$?
  echo "build_stdlib: ninja-core rc=$core_st"
  if [ "$core_st" -eq 126 ]; then
    echo "CANNOT_NOT_EXECUTABLE step=ninja-core rc=126 means a command was found but not executable (EACCES/ENOEXEC), not a link error." >&2
    _cannot_not_executable "ninja -C $B $SWIFTCORE_NINJA_CORE"
    ls -l "$(command -v python3 2>/dev/null || true)" "${LD_LLD:-/}" \
      "${LD64_LLD:-/}" "${TC:-/}/bin/clang++" 2>&1 | sed 's/^/  /' || true
  fi
  obj_n=$(find "$B" -name '*.o' 2>/dev/null | wc -l)
  echo "objects=$obj_n"
  so=$B/lib/swift/macosx/${SWIFTCORE_DARWIN_ARCH}/libswiftCore.so
  dylib=$B/lib/swift/${SWIFTCORE_STDLIB_DIR}/libswiftCore.dylib
  if [ "$core_st" -ne 0 ]; then
    overlay_rc=$core_st
    if [ ! -e "$so" ]; then
      # Linux CMake still emits -shared; the clang++ shim rewrites it. If
      # ninja did not produce .so, try the recorded Mach-O link from the
      # object list (same recipe) so overlay deps are not stuck on gold.
      if grep -q -- "-o lib/swift/macosx/${SWIFTCORE_DARWIN_ARCH}/libswiftCore.so" "$W/build.log" 2>/dev/null; then
        bash "$SCRIPT_DIR/link_macho_dylib.sh" "$W/build.log" libswiftCore || true
      fi
    fi
    if [ ! -e "$so" ] && [ -f "$dylib" ]; then
      cp -f "$dylib" "$so"
      echo "staged ninja .so from $dylib"
    fi
    if [ ! -e "$so" ]; then
      echo "CANNOT_ELF_SO_LINUX_SHARED: ninja $SWIFTCORE_NINJA_CORE rc=$core_st did not produce $so. Linker is lld (not gold). Linux CMake still emits -shared/-soname and names the Darwin dylib .so; apple -target must keep the Darwin driver flags and resolve ld64.lld via --ld-path (not rewrite -dynamiclib/-nostdlib)." >&2
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
    # operator run measures the nine FE dylibs plus _Concurrency / Observation.
    # ninja itself rebuilds real deps of the requested target; we do not skip
    # later names because an earlier ninja failed.
    # Test hook: exec a non-+x helper after ninja so rc=126 is not ninja's.
    if [ -n "${SWIFTCORE_TEST_RC126_EXEC:-}" ]; then
      "${SWIFTCORE_TEST_RC126_EXEC}"
    fi
    overlay_flatten_unarch "$B" "$SWIFTCORE_DARWIN_ARCH"
    overlay_copy_so_as_dylib "$B" "$SWIFTCORE_DARWIN_ARCH"
    python3 "$SCRIPT_DIR/lipo_single_arch.py" --rewrite-ninja "$B" || true
    overlay_print_isysroot_from_ninja "$B" "$SWIFTCORE_DARWIN_ARCH"
    overlay_print_overlay_module_evidence "$B" "$SWIFTCORE_DARWIN_ARCH"
    overlay_print_darwin_link_from_ninja "$B" "$SWIFTCORE_DARWIN_ARCH"
    if [ "${SWIFTCORE_NINJA_HARNESS:-0}" != 1 ]; then
      overlay_sysroot_print_headers "$W/sdk/MacOSX.sdk"
    fi
    set +e
    overlay_select_targets "$B" "$SWIFTCORE_DARWIN_ARCH"
    sel_rc=$?
    set -e
    if [ "$sel_rc" -ne 0 ]; then
      overlay_rc=$sel_rc
    fi
    # DarwinFoundation shells before Darwin ninja: libswiftDarwin re-exports
    # them (Apple's four LC_REEXPORT_DYLIB). Builtin_float is ninja'd first.
    if [ "${SWIFTCORE_NINJA_HARNESS:-0}" != 1 ]; then
      set +e
      overlay_build_xcode_shells "$B" "$SWIFTCORE_DARWIN_ARCH"
      local shells_st=$?
      set -e
      if [ "$shells_st" -ne 0 ] && [ "$overlay_rc" -eq 0 ]; then
        overlay_rc=$shells_st
      fi
    fi
    if [ ${#OVERLAY_NINJA_TARGETS[@]} -gt 0 ]; then
      for t in "${OVERLAY_NINJA_TARGETS[@]}"; do
        step "ninja overlay $t"
        ninja_st=0
        tlog=$W/overlay.${t}.log
        : > "$tlog"
        ensure_compiler_shims
        ninja_checked "$tlog" -C "$B" -j "$NINJA_JOBS" "$t" || ninja_st=$?
        echo "build_stdlib: ninja-overlay $t rc=$ninja_st"
        if [ "$ninja_st" -eq 126 ]; then
          echo "CANNOT_NOT_EXECUTABLE step=ninja-overlay target=$t rc=126" >&2
          _cannot_not_executable "ninja -C $B $t"
        fi
        if [ -f "$tlog" ]; then
          cat "$tlog" >> "$W/build.log" 2>/dev/null || true
        fi
        if [ "$ninja_st" -eq 0 ]; then
          OVERLAY_STATUS[$t]=built
          overlay_flatten_unarch "$B" "$SWIFTCORE_DARWIN_ARCH"
          overlay_copy_so_as_dylib "$B" "$SWIFTCORE_DARWIN_ARCH"
        else
          overlay_status_on_fail "$B" "$t" "$tlog"
          if [ "$overlay_rc" -eq 0 ]; then
            overlay_rc=$ninja_st
          fi
        fi
      done
    fi
    if [ "${SWIFTCORE_NINJA_HARNESS:-0}" != 1 ]; then
      set +e
      overlay_ensure_darwin_reexports "$B" "$SWIFTCORE_DARWIN_ARCH"
      local rx_st=$?
      set -e
      if [ "$rx_st" -ne 0 ]; then
        OVERLAY_STATUS[swiftDarwin-macosx-${SWIFTCORE_DARWIN_ARCH}]="FAILED first_error=CANNOT_DARWIN_REEXPORT"
        if [ "$overlay_rc" -eq 0 ]; then
          overlay_rc=$rx_st
        fi
      fi
    fi
    overlay_print_scoreboard "$SWIFTCORE_DARWIN_ARCH"
    overlay_list_products "$B/lib/swift/macosx"
    if [ "$overlay_rc" -ne 0 ]; then
      echo "overlay: FAILED rc=$overlay_rc" >&2
      echo "build_stdlib: returning overlay_rc=$overlay_rc"
      return "$overlay_rc"
    fi
  fi
  if [ "$core_st" -ne 0 ]; then
    echo "core: FAILED rc=$core_st" >&2
    echo "build_stdlib: returning core_st=$core_st"
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
# 3. Stage the Swift sysroot. .tbd stubs are copied from
#    scratch/sysroot_fe4[-x86_64] (phase2 stages machorun gen_tbd into that
#    tree), not from a leftover MacOSX.sdk whose stamp ignored tbd bytes.
# ---------------------------------------------------------------------------
step "stage_sdk"
ln -sfn "$MACHORUN" "$W/machorun"
ln -sfn "$SWIFTCORE_ROOT/sdk/compat" "$W/compat"
ln -sfn "$SWIFTCORE_ROOT/tests" "$W/tests" 2>/dev/null || true
bash "$SCRIPT_DIR/stage_sdk.sh"
overlay_sysroot_print_headers "$W/sdk/MacOSX.sdk"
tbd_n=$(overlay_sysroot_tbd_count "$W/sdk/MacOSX.sdk")
echo "sysroot tbds: $tbd_n tree=$W/sdk/MacOSX.sdk realpath=$(realpath "$W/sdk/MacOSX.sdk" 2>/dev/null || echo UNRESOLVED)"
overlay_sysroot_refuse_empty_tbds "$W/sdk/MacOSX.sdk" || exit 2

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
           libswift_RegexParser libswiftObservation \
           libswiftDarwin libswiftObjectiveC \
           libswift_DarwinFoundation1 libswift_DarwinFoundation2 \
           libswift_DarwinFoundation3 libswift_errno; do
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
