#!/usr/bin/env bash
# phase2.sh -- one operator command: take a provisioned x86_64 Linux openuikit
# tree from PR #7's phase-1 state to the real-app ladder under the ported loader.
#
#   bash scripts/x86/phase2.sh /opt/openuikit/x86-verify/openuikit
#
# Idempotent. Prints ENV_PREPARE satisfied/cold-built/CANNOT lines and a final
# RUNG_SCOREBOARD with the committed runners' denominators. Never fakes success,
# never overwrites arm64 scratch/sysroot_fe4, scratch/mrroot, scratch/mrroot_fe,
# or scratch/mrroot_full, never
# rewrites durable arm64 OpenCombine object SHAs.
#
# Measure first: libswiftCore-for-x86 is the likeliest hard wall. That
# measurement runs before any later Swift guest work so a missing stdlib is
# reported, not discovered after a half-built FE tree.
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=common.inc
. "$HERE/common.inc"

usage() {
    echo "usage: bash scripts/x86/phase2.sh /opt/openuikit/x86-verify/openuikit" >&2
    exit 2
}

[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && usage
[ $# -eq 1 ] || usage

W=$(cd "$1" && pwd -P)
[ -f "$W/machorun/scripts/build.sh" ] || {
    echo "phase2: $W is not an openuikit tree (missing machorun/scripts/build.sh)" >&2
    exit 2
}
[ -f "$W/full/scripts/guest_arch.inc" ] || {
    echo "phase2: $W is missing full/scripts/guest_arch.inc (need PR #7 phase 1)" >&2
    exit 2
}

export W
export CC="${CC:-clang-18}"
export DARWIN_CLANG="${DARWIN_CLANG:-clang-18}"
export PATH="/usr/lib/llvm-18/bin:${PATH:-}"

# full/ first (and only): macos15 TARGET, SYSROOT_SUFFIX, OPENCOMBINE_EXPORT_SUFFIX.
# machorun/scripts/guest_arch.inc is a different triple (macos11 / DARWIN_TARGET)
# and is sourced by the loader recipes themselves. Do not let it clobber these.
# shellcheck disable=SC1091
. "$W/full/scripts/guest_arch.inc"

MACHORUN=$W/machorun
SYS=$W/scratch/sysroot_fe4${FULL_OUT_SUFFIX}
FE_CLANG_SYS=$SYS
ARM_SYS=$W/scratch/sysroot_fe4
# Base runtime (loader + x86 darwin userland + x86 libswiftCore). Same role as
# arm64 scratch/mrroot from scripts/stage_swift_runtime.sh. build_full.sh
# defaults BASE_RUNTIME_SOURCE here when FULL_OUT_SUFFIX=-x86_64.
BASE_MRROOT=$W/scratch/mrroot${FULL_OUT_SUFFIX}
ARM_BASE_MRROOT=$W/scratch/mrroot
FE_MRROOT=$W/scratch/mrroot_fe${FULL_OUT_SUFFIX}
ARM_FE_MRROOT=$W/scratch/mrroot_fe
MRROOT=$W/scratch/mrroot_full${FULL_OUT_SUFFIX}
ARM_MRROOT=$W/scratch/mrroot_full
OPENCOMBINE_ROOT=$W/scratch/opencombine-core-durable-20260828-r2
SF=$W/scratch/swift-foundation
SC=$W/scratch/swift-collections
FOCUS_REPO=$W/scratch/ladder-corpus/focus-ios/focus-ios
# Dedicated per-target cache, physical spelling only. host-w-layout's
# /w -> $W symlink makes $W/scratch/modcache_fe4 and /w/scratch/modcache_fe4
# the same files; clang then reports '_DarwinFoundation2' defined in both .pcm
# paths. Never mix those spellings in one build; pass this MC to every x86 swiftc.
MC=$(phase2_canonical_dir "$W/scratch/modcache_fe4${FULL_OUT_SUFFIX}")
export MC
UD_SMOKE_CHECKS=14
UD_RUNNER=$W/foundation-macho/tests/ud_guest_runner.swift

CANNOT_N=0
SATISFIED_N=0
COLT_N=0
declare -A ITEM_STATUS=()

note() {
    local name=$1 status=$2 extra=${3:-}
    ITEM_STATUS[$name]=$status
    case "$status" in
        satisfied)
            SATISFIED_N=$((SATISFIED_N + 1))
            phase2_prepare "$name" "satisfied${extra:+ $extra}"
            ;;
        cold-built)
            COLT_N=$((COLT_N + 1))
            phase2_prepare "$name" "cold-built${extra:+ $extra}"
            ;;
        CANNOT_*)
            CANNOT_N=$((CANNOT_N + 1))
            phase2_prepare "$name" "$status${extra:+ $extra}"
            ;;
        *) phase2_prepare "$name" "$status${extra:+ $extra}" ;;
    esac
}

cannot() {
    # cannot <name> <MARKER> <reason>
    ITEM_STATUS[$1]=CANNOT_$2
    CANNOT_N=$((CANNOT_N + 1))
    phase2_cannot "$1" "$2" "$3"
}

# PHASE2_RUNGS (default abc): which rungs to run. A rung that is not selected is
# reported as SKIP on the scoreboard -- never as a pass -- so a sharded cycle
# (run_box.sh x86 cycle --only b) stays honest about what it did not measure.
# Defined before host-w-layout / focus-pin so those items only CANNOT when
# the rung that needs them is selected.
PHASE2_RUNGS=${PHASE2_RUNGS:-abc}
phase2_rung_selected_quiet() {
    case "$PHASE2_RUNGS" in *"$1"*) return 0 ;; esac
    return 1
}
phase2_rung_selected() {
    phase2_rung_selected_quiet "$1" && return 0
    echo "== rung $1: SKIPPED (PHASE2_RUNGS=$PHASE2_RUNGS)"
    return 1
}

have() { [ -e "$1" ]; }

# ---------------------------------------------------------------------------
echo "==== PHASE 2  host=$(uname -m)  W=$W  TARGET=$TARGET  MC=$MC ===="

# 0. Host + toolchain
if [ "$(uname -m)" != x86_64 ]; then
    cannot host-arch HOST_NOT_X86_64 "uname -m is $(uname -m); this runner is the x86_64 operator path"
    echo "RUNG_SCOREBOARD a=CANNOT/host b=CANNOT/host c=CANNOT/host"
    echo "denominators: a 0/$UD_SMOKE_CHECKS smoke (ud_guest_runner.swift)  scoreboard=committed run_ud_guest.sh  persist=committed run_ud_persist.sh; b widget+onboarding source-preservation from full/swiftui; c windows=1 turns=3 from build_and_run_reminder_scene_guest.sh"
    exit 2
fi
note host-arch satisfied
note module-cache satisfied "path=$MC"

missing_tools=()
for t in clang-18 clang++-18 ld64.lld-18 llvm-otool-18 llvm-nm-18 swiftc git python3 perl patch file sha256sum; do
    command -v "$t" >/dev/null || missing_tools+=("$t")
done
if [ "${#missing_tools[@]}" -ne 0 ]; then
    cannot toolchain MISSING_TOOLS "missing: ${missing_tools[*]}"
    echo "RUNG_SCOREBOARD a=CANNOT/toolchain b=CANNOT/toolchain c=CANNOT/toolchain"
    echo "denominators: a 0/$UD_SMOKE_CHECKS smoke; b 0/2 guests; c 0/1 scene"
    exit 2
fi
swift_ver=$(swiftc --version | sed -n '1p')
case "$swift_ver" in
    *6.2.4*) note toolchain satisfied ;;
    *) cannot toolchain SWIFT_VERSION "swiftc is '$swift_ver', need Swift 6.2.4" ; exit 2 ;;
esac
# Overlay / stdlib scripts source swiftcore-macho/scripts/guest_arch.inc, which
# used to look only at /opt/swift624 and /usr/bin. Export the toolchain we
# actually found so SWIFT_TOOLCHAIN wins there.
if [ -z "${SWIFT_TOOLCHAIN:-}" ]; then
    SWIFT_TOOLCHAIN=$(cd "$(dirname "$(command -v swiftc)")/.." && pwd)
    export SWIFT_TOOLCHAIN
fi

# ---------------------------------------------------------------------------
# 1. MEASURE libswiftCore-for-x86 FIRST. Do not spend the rest of the ladder
#    pretending a later Swift guest can run without it.
echo "==== measure libswiftCore-for-x86 (before any other Swift guest work) ===="
artifacts=$W/swiftcore-macho/artifacts
x86_core=$artifacts/swift-macosx/x86_64/libswiftCore.dylib
x86_mod=$artifacts/swift-macosx/Swift.swiftmodule/x86_64-apple-macos.swiftmodule
arm_core=$artifacts/swift-macosx/arm64/libswiftCore.dylib
measure_log=$W/scratch/phase2-libswiftcore-x86.txt
mkdir -p "$W/scratch"
{
    echo "measured_at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "host $(uname -m)"
    echo "swiftc $swift_ver"
    echo "artifacts $artifacts"
    echo "arm64_core $( [ -f "$arm_core" ] && file -b "$arm_core" || echo ABSENT )"
    echo "x86_64_core $( [ -f "$x86_core" ] && file -b "$x86_core" || echo ABSENT )"
    echo "x86_64_swiftmodule $( [ -f "$x86_mod" ] && echo PRESENT || echo ABSENT )"
    echo "stdlib_source ABSENT (no swiftcore-macho/swift, scratch/swift, /opt/swift-source)"
    echo "configure_sh guest_arch.inc SWIFTCORE_DARWIN_ARCH (arm64 argv intact; x86_64 default on x86_64 Linux). pin swift-6.2.4-RELEASE ee343b46aef81c3ac7c5d7960cb35a41a88c5a9b"
    echo "cmake_lists $( [ -f "$W/swiftcore-macho/CMakeLists.txt" ] && echo PRESENT || echo ABSENT -- source not vendored )"
} > "$measure_log"

probe_dir=$(mktemp -d)
printf 'public func ping() -> Int { 1 }\n' > "$probe_dir/t.swift"
set +e
swiftc -target "$TARGET" -sdk "$ARM_SYS" \
    -runtime-compatibility-version none -parse-as-library -module-name T \
    -emit-object -o "$probe_dir/t.o" "$probe_dir/t.swift" \
    >"$probe_dir/out" 2>"$probe_dir/err"
probe_rc=$?
set -e
{
    echo "swiftc_x86_against_arm64_sysroot rc=$probe_rc"
    echo "stderr_head $(head -n 3 "$probe_dir/err" | tr '\n' ' | ')"
} >> "$measure_log"
rm -rf "$probe_dir"

LIBSWIFTCORE_X86=0
if [ -f "$x86_core" ] && phase2_is_x86_macho "$x86_core" && [ -f "$x86_mod" ]; then
    LIBSWIFTCORE_X86=1
    note libswiftCore-x86 satisfied
    echo "  (x86_64 libswiftCore + swiftmodule present under artifacts/)"
else
    cannot libswiftCore-x86 BUILD_LIBSWIFTCORE_X86 \
        "no x86_64 slice in swiftcore-macho/artifacts (need swift-macosx/x86_64/libswiftCore.dylib + Swift.swiftmodule/x86_64-apple-macos.swiftmodule). configure.sh is guest_arch.inc (SWIFTCORE_DARWIN_ARCH), not a hardcoded aarch64 rewrite. Cross-build: NINJA_JOBS=16 SWIFTCORE_DARWIN_ARCH=x86_64 SWIFTCORE_OVERLAYS=1 bash swiftcore-macho/scripts/build_stdlib.sh (docs/X86_64.md). Do not stage the arm64 dylib under an x86 name. measurement=$measure_log"
    cat "$measure_log" | sed 's/^/  /'
fi

# ---------------------------------------------------------------------------
# 2. machorun substrate: loader, darwin, objc4, quartz, tbd
echo "==== machorun substrate (build.sh all, objc4, quartz, tbd) ===="

phase2_machorun_key() {
    local product=$1
    shift
    local tree
    tree=$(phase2_git "$W" rev-parse HEAD:machorun 2>/dev/null | tr -d '[:space:]') || tree=missing
    stamp_key "$product" "$tree" "$@"
}

ensure_loader() {
    local bin=$MACHORUN/build/machorun
    local key
    key=$(phase2_machorun_key "$bin" loader)
    if stamp_reuse "$bin" "$key"; then
        note machorun-loader satisfied "reused=1 stamp=$(stamp_short "$key")"
        return 0
    fi
    stamp_rebuild_reason "$bin" "$key"
    echo "== cold-build loader (CC=$CC)"
    sh "$MACHORUN/scripts/build.sh" loader
    if phase2_is_elf_x86_loader "$bin"; then
        stamp_write "$bin" "$key"
        note machorun-loader cold-built
        return 0
    fi
    cannot machorun-loader BUILD_LOADER "scripts/build.sh loader did not produce an x86-64 ELF PIE at $bin"
    return 1
}

ensure_darwin() {
    local dylib=$MACHORUN/darwin/usr/lib/libSystem.B.dylib
    local key
    key=$(phase2_machorun_key "$dylib" darwin)
    if stamp_reuse "$dylib" "$key"; then
        note machorun-darwin satisfied "reused=1 stamp=$(stamp_short "$key")"
        return 0
    fi
    stamp_rebuild_reason "$dylib" "$key"
    echo "== cold-build darwin userland (x86_64-apple-macos)"
    sh "$MACHORUN/scripts/build.sh" darwin
    if stamp_expected_kind "$dylib"; then
        stamp_write "$dylib" "$key"
        note machorun-darwin cold-built
        return 0
    fi
    cannot machorun-darwin BUILD_DARWIN "libSystem.B.dylib is not X86_64 Mach-O after build.sh darwin ($(file -b "$dylib" 2>/dev/null || echo missing))"
    return 1
}

ensure_objc4() {
    local dylib=$MACHORUN/darwin/usr/lib/libobjc.A.dylib
    local key
    key=$(phase2_machorun_key "$dylib" objc4)
    if stamp_reuse "$dylib" "$key"; then
        note machorun-objc4 satisfied "reused=1 stamp=$(stamp_short "$key")"
        return 0
    fi
    stamp_rebuild_reason "$dylib" "$key"
    echo "== cold-build objc4 (unblocks the objc fixture CANNOT_BUILD_LIBOBJC_X86)"
    bash "$MACHORUN/scripts/build_objc4.sh"
    if stamp_expected_kind "$dylib"; then
        stamp_write "$dylib" "$key"
        note machorun-objc4 cold-built
        return 0
    fi
    cannot machorun-objc4 BUILD_LIBOBJC_X86 "libobjc.A.dylib is not X86_64 Mach-O after build_objc4.sh"
    return 1
}

ensure_quartz() {
    local dylib=$MACHORUN/darwin/usr/lib/libquartz.dylib
    local key
    key=$(phase2_machorun_key "$dylib" quartz)
    if stamp_reuse "$dylib" "$key"; then
        note machorun-quartz satisfied "reused=1 stamp=$(stamp_short "$key")"
        return 0
    fi
    stamp_rebuild_reason "$dylib" "$key"
    echo "== cold-build quartz"
    bash "$MACHORUN/scripts/build_quartz.sh"
    if stamp_expected_kind "$dylib"; then
        stamp_write "$dylib" "$key"
        note machorun-quartz cold-built
        return 0
    fi
    cannot machorun-quartz BUILD_QUARTZ_X86 "libquartz.dylib is not X86_64 Mach-O after build_quartz.sh"
    return 1
}

ensure_tbd() {
    local tbd=$MACHORUN/sdk/usr/lib/libSystem.tbd
    local key
    key=$(phase2_machorun_key "$tbd" tbd "$MACHORUN/build/machorun")
    if stamp_reuse "$tbd" "$key" && grep -q x86_64 "$tbd"; then
        note machorun-tbd satisfied "reused=1 stamp=$(stamp_short "$key")"
        return 0
    fi
    stamp_rebuild_reason "$tbd" "$key"
    if ! phase2_is_elf_x86_loader "$MACHORUN/build/machorun"; then
        cannot machorun-tbd GENERATE_TBD "gen_tbd.sh CHECK 1 needs the host ELF loader; loader is missing"
        return 1
    fi
    echo "== cold-generate .tbd (CHECK 1 against this loader)"
    # CHECK 4 scans every dylib under darwin/usr/lib. An arm64 staged
    # libswiftcompat beside a freshly built x86 libSystem is a mixed-slice
    # coin toss, not a generated stub. Park arm64 dylibs beside (do not
    # delete) so the x86 .tbd projection is honest.
    phase2_park_arm64_darwin_dylibs "$MACHORUN/darwin/usr/lib"
    set +e
    sh "$MACHORUN/scripts/build.sh" tbd
    st=$?
    set -e
    if [ "$st" -eq 0 ] && [ -s "$tbd" ]; then
        stamp_write "$tbd" "$key"
        note machorun-tbd cold-built
        return 0
    fi
    tbd_state=missing
    [ -s "$tbd" ] && tbd_state=present
    cannot machorun-tbd GENERATE_TBD "build.sh tbd exit $st; $tbd $tbd_state. CHECK 1 needs this loader's exports; CHECK 4 refuses duplicate symbols across dylibs (arm64 libswiftcompat leftover beside x86 libSystem is a mixed-arch wall, not a faked tbd)."
    return 1
}

ensure_loader || true
ensure_darwin || true
ensure_objc4 || true
ensure_quartz || true
ensure_tbd || true

# ---------------------------------------------------------------------------
# 3. x86 sysroot beside arm64 sysroot_fe4
# Idempotency keys on INPUT shas (libswiftCore artifact, modulemap generator,
# Darwin overlay text), not on the output directory existing. A sysroot staged
# before x86 libswiftCore landed must restage; print which input changed.
echo "==== x86 sysroot (beside $ARM_SYS, never overwrite) ===="
[ -d "$ARM_SYS" ] || echo "  note: arm64 sysroot_fe4 is absent; textual Darwin overlays cannot be copied"
SYSROOT_OK=0
SYSROOT_HEADERS=0
x86_bf=$artifacts/swift-macosx/_Builtin_float.swiftmodule/x86_64-apple-macos.swiftmodule
gen_py=$MACHORUN/scripts/gen_darwin_modulemap.py
overlay_if=$(phase2_sysroot_overlay_if "$ARM_SYS" "$artifacts" || true)
arm_dmap=$(phase2_sysroot_dmap_input "$ARM_SYS")
stamp=$SYS/$PHASE2_SYSROOT_STAMP
need_core=0
need_bf=0
[ -f "$x86_core" ] && phase2_is_x86_macho "$x86_core" && need_core=1
[ -f "$x86_bf" ] && need_bf=1

sysroot_input_changed() {
    local diff
    diff=$(phase2_sysroot_stamp_diff "$stamp" \
        "$x86_core" "$x86_mod" "$x86_bf" "$gen_py" \
        "${overlay_if:-}" "$arm_dmap" \
        "$FE_SYSROOT_MEASUREMENT_HEADERS_FILE" || true)
    if [ -n "$diff" ]; then
        printf '%s\n' "$diff"
        return 0
    fi
    return 1
}

run_sysroot_stager() {
    local st
    set +e
    bash "$HERE/stage_fe_sysroot.sh"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && [ -d "$SYS/usr/include" ]; then
        SYSROOT_HEADERS=1
        if phase2_sysroot_complete "$SYS" "$need_core" "$need_bf"; then
            note sysroot-fe4-x86 cold-built "darwin_headers=ok measurement_headers=ok"
            SYSROOT_OK=1
        elif [ ! -d "$SYS/usr/lib/swift/Darwin.swiftmodule" ] \
            && [ ! -f "$SYS/usr/lib/swift/Darwin.swiftinterface" ]; then
            cannot sysroot-fe4-x86 STAGE_XCODE_DARWIN_OVERLAYS \
                "headers+x86 dylibs staged at $SYS; Darwin.swiftmodule/swiftinterface absent (Linux cannot materialize Apple's overlay interfaces; arm64 sysroot_fe4 also lacks them). FE compile needs canImport(Darwin)==true."
        elif [ ! -f "$SYS/usr/include/Darwin.modulemap" ]; then
            cannot sysroot-fe4-x86 DARWIN_CLANG_MODULEMAP \
                "Darwin.swiftinterface is present but usr/include/Darwin.modulemap is not (underlying Objective-C module Darwin). Generator needs Xcode; arm64 sysroot_fe4 had no pruned maps to copy. FE fails with 'underlying Objective-C module Darwin not found' / '_DarwinFoundation1._errno'."
        elif ! phase2_darwin_modulemap_headers_ok "$SYS"; then
            cannot sysroot-fe4-x86 DARWIN_MODULEMAP_HEADERS \
                "Darwin.modulemap present but header paths named by staged modulemaps are absent: missing=$(phase2_darwin_modulemap_missing_headers "$SYS" || true). The Linux fallback must copy generator outputs from the arm64 sysroot including usr/include/_modules, not maps alone."
        elif ! phase2_measurement_headers_ok "$SYS"; then
            cannot sysroot-fe4-x86 FE_MEASUREMENT_HEADERS \
                "FileManager/sdk-gap measurement headers absent after restage: missing=$(phase2_measurement_headers_missing "$SYS" || true). x86 stages this set from arm64 sysroot_fe4 with stage_absent (shared list full/foundation/fe_sysroot_measurement_headers.txt)."
        elif [ "$need_core" -eq 1 ] && { [ ! -f "$SYS/usr/lib/swift/libswiftCore.dylib" ] || ! phase2_is_x86_macho "$SYS/usr/lib/swift/libswiftCore.dylib"; }; then
            cannot sysroot-fe4-x86 STAGE_LIBSWIFTCORE \
                "x86 libswiftCore is in artifacts but was not staged into $SYS/usr/lib/swift"
        elif [ ! -e "$SYS/usr/lib/libobjc.tbd" ] || ! phase2_tbd_is_x86_target "$SYS/usr/lib/libobjc.tbd"; then
            cannot sysroot-fe4-x86 X86_SYSROOT_TBDS \
                "libobjc.tbd absent or not x86_64-macos after restage; -lobjc cannot resolve render_full.o's _objc_sync_exit/_objc_sync_enter/_objc_setAssociatedObject/_objc_getAssociatedObject/_objc_opt_self/_objc_getClassList/_objc_getClass/__objc_empty_cache"
        else
            cannot sysroot-fe4-x86 STAGE_FE_SYSROOT \
                "stage_fe_sysroot.sh exit 0 but sysroot is incomplete at $SYS"
        fi
    elif [ "$st" -eq 3 ]; then
        if [ -d "$SYS/usr/include" ]; then
            cannot sysroot-fe4-x86 STAGE_XCODE_DARWIN_OVERLAYS \
                "headers+x86 dylibs staged at $SYS; Darwin.swiftmodule/swiftinterface absent (Linux cannot materialize Apple's overlay interfaces; arm64 sysroot_fe4 also lacks them). FE compile needs canImport(Darwin)==true."
            SYSROOT_HEADERS=1
        else
            cannot sysroot-fe4-x86 STAGE_FE_SYSROOT "stage_fe_sysroot.sh exit 3 and $SYS missing"
        fi
    else
        cannot sysroot-fe4-x86 STAGE_FE_SYSROOT "stage_fe_sysroot.sh exit $st"
    fi
}

changed=$(sysroot_input_changed || true)
if [ -z "$changed" ] && phase2_sysroot_complete "$SYS" "$need_core" "$need_bf"; then
    note sysroot-fe4-x86 satisfied "darwin_headers=ok measurement_headers=ok"
    SYSROOT_OK=1
    SYSROOT_HEADERS=1
elif [ -n "$changed" ]; then
    echo "  re-stage sysroot-fe4-x86 (input changed: $(echo "$changed" | tr '\n' ' '))"
    run_sysroot_stager
elif phase2_sysroot_complete "$SYS" "$need_core" "$need_bf"; then
    note sysroot-fe4-x86 satisfied "darwin_headers=ok measurement_headers=ok"
    SYSROOT_OK=1
    SYSROOT_HEADERS=1
else
    # Stamp matches but the tree is incomplete: restaging cannot invent overlays
    # or Darwin.modulemap that the inputs do not provide. Name the hole.
    SYSROOT_HEADERS=0
    [ -d "$SYS/usr/include" ] && SYSROOT_HEADERS=1
    if [ ! -d "$SYS/usr/include" ]; then
        echo "  re-stage sysroot-fe4-x86 (no sysroot yet)"
        run_sysroot_stager
    elif [ ! -d "$SYS/usr/lib/swift/Darwin.swiftmodule" ] \
        && [ ! -f "$SYS/usr/lib/swift/Darwin.swiftinterface" ]; then
        cannot sysroot-fe4-x86 STAGE_XCODE_DARWIN_OVERLAYS \
            "headers+x86 dylibs already at $SYS; Darwin.swiftmodule/swiftinterface absent (Linux cannot materialize Apple's overlay interfaces; arm64 sysroot_fe4 also lacks them). FE compile needs canImport(Darwin)==true."
    elif [ ! -f "$SYS/usr/include/Darwin.modulemap" ]; then
        cannot sysroot-fe4-x86 DARWIN_CLANG_MODULEMAP \
            "Darwin.swiftinterface is present at $SYS but usr/include/Darwin.modulemap is not. Inputs unchanged; generator needs Xcode and arm64 sysroot_fe4 has no pruned maps to copy."
    elif [ -f "$SYS/usr/include/Darwin.modulemap" ] \
        && ! phase2_darwin_modulemap_headers_ok "$SYS"; then
        echo "  re-stage sysroot-fe4-x86 (Darwin modulemap headers missing: $(phase2_darwin_modulemap_missing_headers "$SYS" || true))"
        run_sysroot_stager
    elif ! phase2_measurement_headers_ok "$SYS"; then
        echo "  re-stage sysroot-fe4-x86 (measurement headers missing: $(phase2_measurement_headers_missing "$SYS" || true))"
        run_sysroot_stager
    elif [ "$need_core" -eq 1 ] && { [ ! -f "$SYS/usr/lib/swift/libswiftCore.dylib" ] || ! phase2_is_x86_macho "$SYS/usr/lib/swift/libswiftCore.dylib"; }; then
        echo "  re-stage sysroot-fe4-x86 (libswiftCore artifact present, not in sysroot; stamp should have caught this)"
        run_sysroot_stager
    else
        cannot sysroot-fe4-x86 STAGE_FE_SYSROOT "sysroot at $SYS is incomplete and inputs are unchanged"
    fi
fi
# Never copy arm64 dylibs into the x86 sysroot.
if [ -f "$SYS/usr/lib/libSystem.B.dylib" ] && phase2_is_arm64_macho "$SYS/usr/lib/libSystem.B.dylib"; then
    cannot sysroot-fe4-x86 ARM64_DYLIB_IN_X86_SYSROOT "libSystem.B.dylib in $SYS is still arm64; refuse rather than link against it"
    SYSROOT_OK=0
fi

# Overlay SDK copies $SYS unexpanded. FE Swift / Clang modules use the sibling.
if [ "$SYSROOT_OK" -eq 1 ] || [ "$SYSROOT_HEADERS" -eq 1 ]; then
    if [ ! -d "$(phase2_fe_clang_sysroot "$SYS")" ]; then
        phase2_stage_fe_clang_sysroot "$SYS" "$W" || true
    fi
    if [ -d "$(phase2_fe_clang_sysroot "$SYS")" ]; then
        FE_CLANG_SYS=$(phase2_fe_clang_sysroot "$SYS")
    fi
fi

# ---------------------------------------------------------------------------
# 4. FoundationEssentials + collections + cshims for x86
echo "==== FoundationEssentials / collections / cshims ($TARGET) ===="
FE_OK=0
COL_OK=0
CSHIMS_OK=0
OS_OK=0
FE_IMPORTS_OK=0
FE_OUT=$W/build/full${FULL_OUT_SUFFIX}/foundation
OSMOD=$FE_OUT/os

try_collections() {
    local out=$FE_OUT/collections
    local key tree
    tree=$(phase2_git "$SC" rev-parse 'HEAD^{tree}' 2>/dev/null | tr -d '[:space:]') || tree=missing
    key=$(stamp_key "$out/OrderedCollections.o" \
        "$W/full/foundation/build_collections.sh" \
        "$W/full/foundation/pinned_inputs.pl" \
        "$tree" "$TARGET")
    if stamp_reuse "$out/OrderedCollections.o" "$key"; then
        note collections-x86 satisfied "mc=$MC stamp=$(stamp_short "$key")"
        COL_OK=1
        return 0
    fi
    stamp_rebuild_reason "$out/OrderedCollections.o" "$key"
    [ -d "$SC" ] || { cannot collections-x86 PINNED_SWIFT_COLLECTIONS "no $SC"; return 1; }
    [ "$SYSROOT_OK" -eq 1 ] || { cannot collections-x86 NEEDS_X86_SYSROOT "collections compile needs $SYS"; return 1; }
    [ "$LIBSWIFTCORE_X86" -eq 1 ] || {
        cannot collections-x86 BUILD_LIBSWIFTCORE_X86 "swiftc -target $TARGET cannot compile without an x86_64 Swift.swiftmodule (measured above)"
        return 1
    }
    mkdir -p "$out"
    set +e
    W="$W" SC="$SC" SYS="$FE_CLANG_SYS" OUT="$out" TARGET="$TARGET" MC="$MC" \
        bash "$W/full/foundation/build_collections.sh"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && phase2_is_x86_macho "$out/OrderedCollections.o"; then
        stamp_write "$out/OrderedCollections.o" "$key"
        note collections-x86 cold-built "mc=$MC"
        COL_OK=1
        return 0
    fi
    cannot collections-x86 BUILD_COLLECTIONS "build_collections.sh exit $st mc=$MC"
    return 1
}

try_cshims() {
    local out=$FE_OUT/cshims
    local key tree
    tree=$(phase2_git "$SF" rev-parse 'HEAD^{tree}' 2>/dev/null | tr -d '[:space:]') || tree=missing
    key=$(stamp_key "$out/uuid.o" \
        "$W/full/foundation/build_cshims.sh" \
        "$tree" "$TARGET")
    if stamp_reuse "$out/uuid.o" "$key"; then
        note cshims-x86 satisfied "stamp=$(stamp_short "$key")"
        CSHIMS_OK=1
        return 0
    fi
    stamp_rebuild_reason "$out/uuid.o" "$key"
    [ -d "$SF" ] || { cannot cshims-x86 PINNED_SWIFT_FOUNDATION "no $SF"; return 1; }
    [ "$SYSROOT_HEADERS" -eq 1 ] || [ "$SYSROOT_OK" -eq 1 ] || {
        cannot cshims-x86 NEEDS_X86_SYSROOT "cshims compile needs $SYS"
        return 1
    }
    mkdir -p "$out"
    set +e
    W="$W" SF="$SF" SYS="$FE_CLANG_SYS" OUT="$out" TARGET="$TARGET" \
        bash "$W/full/foundation/build_cshims.sh"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && [ -f "$out/uuid.o" ] && phase2_is_x86_macho "$out/uuid.o"; then
        stamp_write "$out/uuid.o" "$key"
        note cshims-x86 cold-built
        CSHIMS_OK=1
        return 0
    fi
    cannot cshims-x86 BUILD_CSHIMS "build_cshims.sh exit $st"
    return 1
}

try_os_module() {
    local out=$OSMOD
    local key posix_dir
    local -a posix_xcc=()
    posix_dir=$(phase2_posix_overlay_dir "$W" || true)
    if [ -n "$posix_dir" ]; then
        posix_xcc=(-Xcc -I"$posix_dir")
    fi
    key=$(stamp_key "$out/os.o" \
        "$W/full/foundation/build_os_module.sh" \
        "$TARGET" \
        "${posix_dir:-no-posix-overlay}")
    if stamp_reuse "$out/os.o" "$key" && [ -f "$out/os.swiftmodule" ]; then
        note os-module-x86 satisfied "mc=$MC stamp=$(stamp_short "$key")"
        OS_OK=1
        return 0
    fi
    stamp_rebuild_reason "$out/os.o" "$key"
    [ "$SYSROOT_OK" -eq 1 ] || {
        cannot os-module-x86 NEEDS_X86_SYSROOT "os.swift @_exported-imports Darwin; needs $SYS"
        return 1
    }
    [ "$LIBSWIFTCORE_X86" -eq 1 ] || {
        cannot os-module-x86 BUILD_LIBSWIFTCORE_X86 "os-module compile needs x86_64 Swift.swiftmodule"
        return 1
    }
    mkdir -p "$out"
    set +e
    W="$W" SYS="$FE_CLANG_SYS" OUT="$out" TARGET="$TARGET" MC="$MC" \
        bash "$W/full/foundation/build_os_module.sh" "${posix_xcc[@]}"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && [ -f "$out/os.o" ] && phase2_is_x86_macho "$out/os.o" \
        && [ -f "$out/os.swiftmodule" ]; then
        stamp_write "$out/os.o" "$key"
        note os-module-x86 cold-built "mc=$MC"
        OS_OK=1
        return 0
    fi
    cannot os-module-x86 BUILD_OS_MODULE \
        "build_os_module.sh exit $st OUT=$out mc=$MC (beside arm64 scratch/fe4_os, never overwrite). Calendar.swift import os is live because canImport(Darwin) is true."
    return 1
}

try_fe_imports() {
    local report
    report=$(phase2_probe_fe_imports "$FE_CLANG_SYS" "$OSMOD" || true)
    case "$report" in
        MATCH*)
            note fe-imports satisfied
            FE_IMPORTS_OK=1
            echo "  $report"
            return 0
            ;;
        *)
            cannot fe-imports FE_IMPORTS "$report"
            return 1
            ;;
    esac
}

try_fe() {
    local out=$FE_OUT/essentials
    local have_fe=0 have_compat=0
    local fe_key compat_key tree posix_dir
    local -a posix_xcc=()
    posix_dir=$(phase2_posix_overlay_dir "$W" || true)
    if [ -n "$posix_dir" ]; then
        posix_xcc=(-Xcc -I"$posix_dir")
    fi
    tree=$(phase2_git "$SF" rev-parse 'HEAD^{tree}' 2>/dev/null | tr -d '[:space:]') || tree=missing
    fe_key=$(stamp_key "$out/FoundationEssentials.o" \
        "$W/full/foundation/build_fe.sh" \
        "$tree" "$TARGET" \
        "${posix_dir:-no-posix-overlay}")
    compat_key=$(stamp_key "$out/removefile_compat.o" \
        "$W/full/foundation/removefile_compat.c" \
        "$TARGET")
    if stamp_reuse "$out/FoundationEssentials.o" "$fe_key"; then
        have_fe=1
    fi
    if stamp_reuse "$out/removefile_compat.o" "$compat_key"; then
        have_compat=1
    fi
    if [ "$have_fe" -eq 1 ] && [ "$have_compat" -eq 1 ]; then
        note foundationessentials-x86 satisfied "mc=$MC stamp=$(stamp_short "$fe_key")"
        FE_OK=1
        return 0
    fi
    [ "$have_fe" -eq 1 ] || stamp_rebuild_reason "$out/FoundationEssentials.o" "$fe_key"
    [ "$have_compat" -eq 1 ] || stamp_rebuild_reason "$out/removefile_compat.o" "$compat_key"

    compile_fe_removefile_compat() {
        local cst
        mkdir -p "$out"
        set +e
        phase2_compile_removefile_compat "$FE_CLANG_SYS" "$out/removefile_compat.o" "$TARGET" "$W"
        cst=$?
        set -e
        if [ "$cst" -eq 0 ] && [ -f "$out/removefile_compat.o" ] \
            && phase2_is_x86_macho "$out/removefile_compat.o"; then
            stamp_write "$out/removefile_compat.o" "$compat_key"
            return 0
        fi
        cannot foundationessentials-x86 BUILD_FE_REMOVEFILE_COMPAT \
            "removefile_compat.c clang exit $cst (build_fe.sh is Swift-only on both arches; arm64 compiles this in build_full.sh). out=$out"
        return 1
    }

    if [ "$have_fe" -eq 1 ]; then
        [ "$SYSROOT_HEADERS" -eq 1 ] || [ "$SYSROOT_OK" -eq 1 ] || {
            cannot foundationessentials-x86 NEEDS_X86_SYSROOT "removefile_compat.c needs $SYS"
            return 1
        }
        compile_fe_removefile_compat || return 1
        note foundationessentials-x86 cold-built "mc=$MC removefile_compat=ok"
        FE_OK=1
        return 0
    fi

    [ -d "$SF" ] || { cannot foundationessentials-x86 PINNED_SWIFT_FOUNDATION "no $SF"; return 1; }
    [ "$SYSROOT_OK" -eq 1 ] || { cannot foundationessentials-x86 NEEDS_X86_SYSROOT "FE compile needs $SYS"; return 1; }
    [ "$LIBSWIFTCORE_X86" -eq 1 ] || {
        cannot foundationessentials-x86 BUILD_LIBSWIFTCORE_X86 "swiftc -target $TARGET cannot compile 202 FE files without x86_64 Swift/_Concurrency modules"
        return 1
    }
    [ "$OS_OK" -eq 1 ] || {
        cannot foundationessentials-x86 NEEDS_X86_OS_MODULE \
            "canImport(Darwin) is true so Calendar.swift:14 import os is live; os-module-x86 did not produce $OSMOD/os.swiftmodule"
        return 1
    }
    [ "$FE_IMPORTS_OK" -eq 1 ] || {
        cannot foundationessentials-x86 NEEDS_FE_IMPORTS \
            "fe-imports probe refused; not invoking 202-file build_fe.sh"
        return 1
    }
    mkdir -p "$out"
    set +e
    W="$W" SF="$SF" SYS="$FE_CLANG_SYS" TARGET="$TARGET" OSMOD="$OSMOD" \
        COLLECTIONS="$FE_OUT/collections" MC="$MC" \
        bash "$W/full/foundation/build_fe.sh" \
            -emit-module -emit-module-path "$out/FoundationEssentials.swiftmodule" \
            -c -o "$out/FoundationEssentials.o" \
            "${posix_xcc[@]}"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && phase2_is_x86_macho "$out/FoundationEssentials.o"; then
        stamp_write "$out/FoundationEssentials.o" "$fe_key"
        compile_fe_removefile_compat || return 1
        note foundationessentials-x86 cold-built "mc=$MC removefile_compat=ok"
        FE_OK=1
        return 0
    fi
    cannot foundationessentials-x86 BUILD_FE "build_fe.sh exit $st mc=$MC"
    return 1
}

try_cshims || true
try_collections || true
try_os_module || true
try_fe_imports || true
try_fe || true

# ---------------------------------------------------------------------------
# 5. OpenCombine for x86 beside the durable arm64 export/
echo "==== OpenCombine x86 (beside $OPENCOMBINE_ROOT/export) ===="
OC_OK=0
oc_obj=$OPENCOMBINE_ROOT/export-x86_64/artifacts/OpenCombine.o
oc_key=$(stamp_key "$oc_obj" \
    "$HERE/build_opencombine.sh" \
    "$W/full/oracle-opencombine/policy.json" \
    "$TARGET")
if stamp_reuse "$oc_obj" "$oc_key"; then
    note opencombine-x86 satisfied "mc=$MC stamp=$(stamp_short "$oc_key")"
    OC_OK=1
else
    stamp_rebuild_reason "$oc_obj" "$oc_key"
    set +e
    W="$W" SYS="$FE_CLANG_SYS" OPENCOMBINE_ROOT="$OPENCOMBINE_ROOT" MC="$MC" \
        bash "$HERE/build_opencombine.sh"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && [ -f "$oc_obj" ] && phase2_is_x86_macho "$oc_obj"; then
        stamp_write "$oc_obj" "$oc_key"
        note opencombine-x86 cold-built "mc=$MC"
        OC_OK=1
    else
        cannot opencombine-x86 X86_OPENCOMBINE \
            "NEEDS_X86_OPENCOMBINE unresolved: x86 OpenCombine.o not produced (blocked by libswiftCore-x86=$LIBSWIFTCORE_X86 sysroot=$SYSROOT_OK mc=$MC). arm64 durable SHA in export/artifacts still stands; this runner writes only export-x86_64/"
    fi
fi
# Arm64 pin must still be beside, never rewritten.
if [ -f "$OPENCOMBINE_ROOT/export/artifacts/OpenCombine.o" ]; then
    if phase2_is_x86_macho "$OPENCOMBINE_ROOT/export/artifacts/OpenCombine.o"; then
        cannot opencombine-arm64-pin REWROTE_ARM64_OPENCOMBINE \
            "export/artifacts/OpenCombine.o is no longer arm64; the durable pin was overwritten"
    else
        note opencombine-arm64-pin satisfied
    fi
else
    echo "ENV_PREPARE opencombine-arm64-pin absent (durable export/ not on this tree; source pin remains; not a rewrite)"
fi

# ---------------------------------------------------------------------------
# 6. scratch/mrroot-x86_64 (base runtime; analog of arm64 scratch/mrroot)
#    Never write the unsuffixed arm64 tree. Overlays are a separate root.
echo "==== mrroot-x86_64 (base runtime, beside $ARM_BASE_MRROOT) ===="
BASE_MRROOT_OK=0
[ "$BASE_MRROOT" != "$ARM_BASE_MRROOT" ] || {
    cannot mrroot-base-x86 MRROOT_COLLIDES_ARM64 "x86 base mrroot path equals arm64 scratch/mrroot"
}
BASE_KEY=$(stamp_key "$BASE_MRROOT/machorun" \
    "$MACHORUN/build/machorun" \
    "${x86_core:-missing-core}")
if stamp_reuse "$BASE_MRROOT/machorun" "$BASE_KEY" \
    && [ -f "$BASE_MRROOT/darwin/usr/lib/swift/libswiftCore.dylib" ] \
    && phase2_is_x86_macho "$BASE_MRROOT/darwin/usr/lib/swift/libswiftCore.dylib"; then
    note mrroot-base-x86 satisfied "stamp=$(stamp_short "$BASE_KEY")"
    BASE_MRROOT_OK=1
else
    stamp_rebuild_reason "$BASE_MRROOT/machorun" "$BASE_KEY"
    echo "== staging $BASE_MRROOT from machorun darwin + x86 libswiftCore"
    phase2_stage_x86_base_mrroot \
        "$BASE_MRROOT" \
        "$MACHORUN/build/machorun" \
        "$MACHORUN/darwin" \
        "$x86_core"
    if [ -x "$BASE_MRROOT/machorun" ] && phase2_is_elf_x86_loader "$BASE_MRROOT/machorun" \
        && [ -f "$BASE_MRROOT/darwin/usr/lib/swift/libswiftCore.dylib" ] \
        && phase2_is_x86_macho "$BASE_MRROOT/darwin/usr/lib/swift/libswiftCore.dylib"; then
        note mrroot-base-x86 cold-built
        stamp_write "$BASE_MRROOT/machorun" "$BASE_KEY"
        BASE_MRROOT_OK=1
    elif [ "$LIBSWIFTCORE_X86" -ne 1 ]; then
        cannot mrroot-base-x86 BUILD_LIBSWIFTCORE_X86 \
            "loader+x86 darwin staged at $BASE_MRROOT; libswiftCore.dylib omitted because only an arm64 artifact exists"
    else
        cannot mrroot-base-x86 STAGE_MRROOT \
            "copy failed to produce x86 loader+libswiftCore at $BASE_MRROOT"
    fi
fi

# Host Linux runtime boundary for build_full.sh. Always (re)stage, including
# when mrroot-base-x86 is already satisfied: the operator tree had an empty
# scratch/mrroot-x86_64/host/. Copies toolchain libdispatch.so /
# libBlocksRuntime.so, then builds the four Open* helpers as ELF x86_64.
# Incomplete host/ is a named CANNOT (each missing file) before rungs b/c
# invoke build_full.sh.
echo "==== mrroot-x86_64 host/ (Linux runtime boundary) ===="
HOST_RUNTIME_OK=0
if [ "$BASE_MRROOT" = "$ARM_BASE_MRROOT" ]; then
    cannot mrroot-host-x86 MRROOT_COLLIDES_ARM64 "x86 base mrroot path equals arm64 scratch/mrroot"
elif [ ! -d "$BASE_MRROOT" ]; then
    cannot mrroot-host-x86 X86_HOST_RUNTIME \
        "no $BASE_MRROOT to fill host/; mrroot-base-x86 did not produce a dest"
else
    host_report=$(phase2_stage_x86_host_runtime "$BASE_MRROOT" "$W" || true)
    case "$host_report" in
        OK)
            note mrroot-host-x86 satisfied
            HOST_RUNTIME_OK=1
            ;;
        MISSING=*)
            cannot mrroot-host-x86 X86_HOST_RUNTIME \
                "$host_report; resolved=$(openuikit_resolve_swift_linux_lib). build_full.sh copies this closed set from BASE_RUNTIME_SOURCE/host/ and will not run until it is complete."
            ;;
        *)
            cannot mrroot-host-x86 X86_HOST_RUNTIME \
                "host stage produced: ${host_report:-empty}"
            ;;
    esac
fi

# ---------------------------------------------------------------------------
# 6a. scratch/mrroot_fe-x86_64 — FE overlays from the x86 stdlib cross-build.
# Emits CANNOT_X86_OVERLAYS_NOT_BUILT (phase2_cannot prefixes CANNOT_).
# CoreSimulator overlays are arm64-only non-fat; never use that macOS marker.
echo "==== mrroot_fe-x86_64 (FE overlays, beside $ARM_FE_MRROOT) ===="
[ "$FE_MRROOT" != "$ARM_FE_MRROOT" ] || {
    cannot mrroot-fe-overlays-x86 MRROOT_COLLIDES_ARM64 "x86 FE overlay path equals arm64 scratch/mrroot_fe"
}
overlay_report=$(phase2_stage_x86_fe_overlays "$FE_MRROOT" || true)
case "$overlay_report" in
    OK)
        note mrroot-fe-overlays-x86 satisfied
        ;;
    MISSING=*)
        cannot mrroot-fe-overlays-x86 X86_OVERLAYS_NOT_BUILT \
                "$overlay_report; x86 overlays come from swiftcore-macho/artifacts/swift-macosx/x86_64 (PR #20 stdlib staging) or \$HOME/work/build/lib/swift/macosx/x86_64 or scratch/apple-x86-overlays. Durable set is twelve (nine FE + _Concurrency + ObjectiveC + Observation)."
        ;;
    *)
        cannot mrroot-fe-overlays-x86 X86_OVERLAYS_NOT_BUILT \
            "overlay stage produced '$overlay_report'"
        ;;
esac

# 6a2. BASE_RUNTIME_SOURCE / FE_RUNTIME_SOURCE layout vs build_full.sh.
# Always (re)fill loud-abort stubs + libswiftcompat + BASE swift dylibs, then
# name every remaining hole BEFORE rungs b/c invoke build_full.sh.
echo "==== mrroot-x86_64 layout (build_full BASE/FE contract) ===="
LAYOUT_OK=0
if [ "$BASE_MRROOT" = "$ARM_BASE_MRROOT" ]; then
    cannot mrroot-layout-x86 MRROOT_COLLIDES_ARM64 \
        "x86 base mrroot path equals arm64 scratch/mrroot"
elif [ ! -d "$BASE_MRROOT" ]; then
    cannot mrroot-layout-x86 X86_MRROOT_LAYOUT \
        "no $BASE_MRROOT to fill; mrroot-base-x86 did not produce a dest"
else
    layout_report=$(phase2_stage_x86_mrroot_layout \
        "$BASE_MRROOT" "$FE_MRROOT" "$W" "$SYS" "$MACHORUN/build/machorun" || true)
    case "$layout_report" in
        OK)
            note mrroot-layout-x86 satisfied
            LAYOUT_OK=1
            ;;
        MISSING=*)
            cannot mrroot-layout-x86 X86_MRROOT_LAYOUT \
                "$layout_report; loud-abort stubs from scripts/build_runtime_shims.sh STUBS_ONLY; libswiftcompat from swiftcore-macho/scripts/build_compat.sh; libswift_Concurrency/ObjectiveC from x86 overlay search (never arm64 ELF). build_full.sh will not run until this closed set is complete."
            ;;
        *)
            cannot mrroot-layout-x86 X86_MRROOT_LAYOUT \
                "layout stage produced: ${layout_report:-empty}"
            ;;
    esac
fi

# 6a3. Consumer .tbd set (build_full / widget gate / link_ud_guest), not the
# Apple SDK's whole overlay inventory. BEFORE build_full: -lobjc looks for
# libobjc.tbd; the widget gate lstat()s named $SYS/usr/lib/swift/*.tbd.
echo "==== x86 sysroot .tbd set (consumer inventory; gen_tbd + gen_swift_tbd) ===="
SYSROOT_TBDS_OK=0
tbd_report=$(phase2_sysroot_tbd_resolve "$SYS" "$ARM_SYS" || true)
tbd_extras=$(phase2_sysroot_tbd_extras "$ARM_SYS" | paste -sd, - || true)
[ -z "$tbd_extras" ] || echo "  NOTE extra Apple-SDK .tbd names in arm64 sysroot (not required; no consumer links them): $tbd_extras"
case "$tbd_report" in
    OK)
        note sysroot-tbds-x86 satisfied
        SYSROOT_TBDS_OK=1
        ;;
    *)
        cannot sysroot-tbds-x86 X86_SYSROOT_TBDS \
            "${tbd_report:-empty}; required set is consumer link/load names (build_full.sh -lSystem/-lobjc/libquartz, widget expected_*_inputs/loads, link_ud_guest.sh, attest.pl) — usr/lib/{libSystem,libSystem.B,libobjc,libobjc.A,libc++,libc++.1,libc++abi,libquartz}.tbd + usr/lib/swift/{libswiftCore + twelve overlays}.tbd. Extra Apple-SDK names (ARKit, AppKit, …) are a NOTE, not a CANNOT. Darwin tbds from machorun gen_tbd; Swift tbds from scripts/x86/gen_swift_tbd.sh. Never copy arm64 tbds."
        ;;
esac

# ---------------------------------------------------------------------------
# 6b. mrroot_full-x86_64 beside mrroot_full
echo "==== mrroot_full-x86_64 (beside $ARM_MRROOT) ===="
MRROOT_OK=0
[ "$MRROOT" != "$ARM_MRROOT" ] || {
    cannot mrroot-x86 MRROOT_COLLIDES_ARM64 "x86 mrroot path equals arm64 path"
}
if [ -x "$MRROOT/machorun" ] && phase2_is_elf_x86_loader "$MRROOT/machorun" \
    && [ -f "$MRROOT/darwin/usr/lib/libSystem.B.dylib" ] \
    && phase2_is_x86_macho "$MRROOT/darwin/usr/lib/libSystem.B.dylib" \
    && [ -f "$MRROOT/darwin/usr/lib/swift/libswiftCore.dylib" ]; then
    if phase2_is_arm64_macho "$MRROOT/darwin/usr/lib/swift/libswiftCore.dylib"; then
        cannot mrroot-x86 ARM64_SWIFTCORE_IN_X86_MRROOT \
            "refusing to call this an x86 root: libswiftCore.dylib is still arm64"
    elif phase2_is_x86_macho "$MRROOT/darwin/usr/lib/swift/libswiftCore.dylib"; then
        note mrroot-x86 satisfied
        MRROOT_OK=1
    else
        cannot mrroot-x86 MRROOT_SWIFTCORE_ARCH \
            "libswiftCore.dylib in $MRROOT is neither X86_64 nor ARM64"
    fi
else
    if ! phase2_is_elf_x86_loader "$MACHORUN/build/machorun"; then
        cannot mrroot-x86 STAGE_MRROOT_LOADER "no x86 ELF loader to copy into $MRROOT"
    elif [ "$LIBSWIFTCORE_X86" -ne 1 ]; then
        # Stage what we can (loader + x86 darwin dylibs) but refuse to copy arm64 libswiftCore.
        echo "== staging x86 mrroot without libswiftCore (honest partial; not MRROOT_OK)"
        mkdir -p "$MRROOT/darwin/usr/lib/swift"
        cp -f "$MACHORUN/build/machorun" "$MRROOT/machorun"
        chmod a+x "$MRROOT/machorun"
        if [ -d "$MACHORUN/darwin/usr/lib" ]; then
            while IFS= read -r -d '' d; do
                rel=${d#"$MACHORUN/darwin/usr/lib/"}
                case "$rel" in
                    swift/libswiftCore.dylib|swift/libswift_Concurrency.dylib) continue ;;
                esac
                if phase2_is_x86_macho "$d"; then
                    mkdir -p "$MRROOT/darwin/usr/lib/$(dirname "$rel")"
                    cp -a "$d" "$MRROOT/darwin/usr/lib/$rel"
                fi
            done < <(find "$MACHORUN/darwin/usr/lib" -type f -name '*.dylib' -print0)
        fi
        cannot mrroot-x86 BUILD_LIBSWIFTCORE_X86 \
            "loader+x86 libSystem/objc/quartz staged at $MRROOT; libswiftCore.dylib omitted because only an arm64 artifact exists. build_full.sh would otherwise copy that arm64 dylib into an x86-named root."
    else
        echo "== cold-stage x86 mrroot from current machorun + x86 libswiftCore"
        rm -rf "$MRROOT"
        mkdir -p "$MRROOT/darwin/usr/lib/swift"
        cp -f "$MACHORUN/build/machorun" "$MRROOT/machorun"
        chmod a+x "$MRROOT/machorun"
        cp -a "$MACHORUN/darwin/usr/lib/." "$MRROOT/darwin/usr/lib/"
        cp -f "$x86_core" "$MRROOT/darwin/usr/lib/swift/libswiftCore.dylib"
        if phase2_is_x86_macho "$MRROOT/darwin/usr/lib/swift/libswiftCore.dylib" \
            && phase2_is_elf_x86_loader "$MRROOT/machorun"; then
            note mrroot-x86 cold-built
            MRROOT_OK=1
        else
            cannot mrroot-x86 STAGE_MRROOT "copy failed to produce x86 loader+libswiftCore"
        fi
    fi
fi

# 6b2. Loadable overlays into the run root. build_full.sh copies swift
# dylibs from BASE/FE; that is how libswiftObjectiveC arrived as the Apple
# extract (BASE fill skipped an existing x86 Mach-O). Always restage from
# artifacts when present; refuse a dyld-cache extract (no LC_DYLD_INFO /
# LC_DYLD_CHAINED_FIXUPS) with CANNOT_STAGE_CACHE_EXTRACT. One
# OVERLAY_PROVENANCE line per staged overlay (name, srcdir, sha256 prefix,
# fixups=dyld_info|chained from llvm-objdump --macho --private-headers).
echo "==== mrroot_full-x86_64 overlays (artifacts first; refuse cache extracts) ===="
if [ -d "$MRROOT" ]; then
    overlay_full_report=$(phase2_stage_x86_run_root_overlays "$MRROOT" || true)
    printf '%s\n' "$overlay_full_report"
    if printf '%s\n' "$overlay_full_report" | grep -q '^CANNOT_STAGE_CACHE_EXTRACT'; then
        cannot mrroot-overlays-x86 STAGE_CACHE_EXTRACT \
            "$(printf '%s\n' "$overlay_full_report" | grep '^CANNOT_STAGE_CACHE_EXTRACT' | tr '\n' ' ' | phase2_flatten)"
    else
        note mrroot-overlays-x86 satisfied
    fi
else
    cannot mrroot-overlays-x86 STAGE_CACHE_EXTRACT \
        "no $MRROOT to stage overlays into (mrroot-x86 did not produce a dest)"
fi

echo "==== mrroot_full-x86_64 Foundation placeholders (empty; not loud-abort) ===="
if [ -d "$MRROOT" ]; then
    if phase2_stage_x86_foundation_placeholders "$MRROOT" "$W" "$SYS"; then
        note mrroot-placeholders-x86 satisfied
    else
        cannot mrroot-placeholders-x86 STAGE_FOUNDATION_PLACEHOLDERS \
            "build_foundation_placeholder.sh failed for $MRROOT; run_ud_guest.sh refuses empty Foundation slots. Loud-abort stubs stay in $BASE_MRROOT."
    fi
fi

# ---------------------------------------------------------------------------
# 6c. Guest-visible /w layout (FocusWidgetGuestMain.swift fonts). Rung a does
#     not open /w. Cursor cloud already mounts /w, so ln -sfn $W /w fails.
#     Only CANNOT when rung b is selected; otherwise note the fact.
echo "==== /w layout (guest-visible fonts path) ===="
W_LAYOUT=0
w_resolved=$(readlink -f /w 2>/dev/null || true)
if [ -d /w ] && [ "$w_resolved" = "$W" ]; then
    note host-w-layout satisfied
    W_LAYOUT=1
elif [ ! -e /w ] && ln -sfn "$W" /w 2>/dev/null; then
    note host-w-layout cold-built
    W_LAYOUT=1
elif phase2_rung_selected_quiet b; then
    cannot host-w-layout HOST_W_LAYOUT \
        "FocusWidgetGuestMain.swift opens /w/build/swiftui-guest/fonts; cannot ln -s $W /w (resolved=$(readlink -f /w 2>/dev/null || echo missing)). Widget argv already uses \$OUT; fonts still need this docker-era path. Operator: ln -sfn $W /w"
else
    note host-w-layout skipped \
        "PHASE2_RUNGS=$PHASE2_RUNGS; /w resolved=${w_resolved:-missing} is not $W (Cursor mounts /w). Rung b would CANNOT_HOST_W_LAYOUT; do not fake /w."
fi

# ---------------------------------------------------------------------------
# 6d. x86_64 ud_guest via foundation-macho's committed linker. Work tree is
#     scratch/ud-guest-x86_64 (never the unsuffixed arm64 path). FE objects
#     are reused from build/full-x86_64/foundation; this does not compile FE
#     again. Link-time does not need the nine overlay dylibs (tbd-first);
#     rung a still needs them at load.
echo "==== ud-guest-x86 (committed $PHASE2_UD_GUEST_LINKER) ===="
UD_GUEST_ITEM_OK=0
ud_report=$(phase2_try_ud_guest \
    "$W" \
    "$FE_OUT" \
    "$SYS" \
    "$TARGET" \
    "$MC" \
    "$MACHORUN/darwin/usr/lib" \
    "$MACHORUN/build/machorun" \
    || true)
    case "$ud_report" in
    OK\ bin=*)
        UD_GUEST_BIN=${ud_report#*bin=}
        UD_GUEST_BIN=${UD_GUEST_BIN%% *}
        UD_GUEST_W=$W/scratch/ud-guest-x86_64
        export UD_GUEST_BIN UD_GUEST_W
        echo "  $ud_report"
        if phase2_cftest_stub_list_stale "$UD_GUEST_W"; then
            stale_line=$(phase2_cftest_stub_stale_cannot "$UD_GUEST_W")
            cannot cftest-stubs CFTEST_STALE "${stale_line#CANNOT_CFTEST_STALE }"
            cannot ud-guest-x86 UD_GUEST_CFTEST_STALE \
                "stub-func-active.txt is newer than lib/libCFTest.dylib; will not treat this as satisfied. See ENV_PREPARE cftest-stubs."
        else
            cftest_log=$UD_GUEST_W/lib/build_cftest_harness.log
            link_log=$UD_GUEST_W/link_ud_guest.log
            reuse_note=
            if [ -f "$cftest_log" ] && grep -q 'libCFTest reused=1 stamp=' "$cftest_log"; then
                reuse_note=$(grep 'libCFTest reused=1 stamp=' "$cftest_log" | tail -1)
                echo "  $reuse_note"
            elif [ -f "$cftest_log" ] && grep -q 'libCFTest relinked ' "$cftest_log"; then
                echo "  $(grep 'libCFTest relinked ' "$cftest_log" | tail -1)"
            fi
            if [ -f "$link_log" ] && grep -q 'ud_guest reused=1 stamp=' "$link_log"; then
                note ud-guest-x86 satisfied "reused=1 $ud_report"
            else
                note ud-guest-x86 cold-built "$ud_report"
            fi
            UD_GUEST_ITEM_OK=1
            if [ -f "$UD_GUEST_W/stub-func-active.txt" ]; then
                stub_n=$(grep -c . "$UD_GUEST_W/stub-func-active.txt" || true)
                if [ -n "$reuse_note" ]; then
                    note cftest-stubs satisfied "count=$stub_n $reuse_note"
                else
                    note cftest-stubs satisfied "count=$stub_n"
                fi
            fi
        fi
        ;;
    CANNOT_CFTEST_STUBS*)
        cannot cftest-stubs CFTEST_STUBS "${ud_report#CANNOT_CFTEST_STUBS }"
        cannot ud-guest-x86 UD_GUEST_CFTEST_STUBS \
            "libCFTest stub set refused; see ENV_PREPARE cftest-stubs. Will not link ud_guest against it."
        ;;
    CANNOT_CFTEST_STALE*)
        cannot cftest-stubs CFTEST_STALE "${ud_report#CANNOT_CFTEST_STALE }"
        cannot ud-guest-x86 UD_GUEST_CFTEST_STALE \
            "stub-func-active.txt is newer than lib/libCFTest.dylib; see ENV_PREPARE cftest-stubs. Will not treat this as satisfied."
        ;;
    CANNOT_CFTEST_INPUTS*)
        cannot cftest-stubs CFTEST_INPUTS "${ud_report#CANNOT_CFTEST_INPUTS }"
        cannot ud-guest-x86 UD_GUEST_CFTEST_INPUTS \
            "libCFTest input stamp mismatch; see ENV_PREPARE cftest-stubs. Will not reuse a dylib whose objects/stub-set/tbds/argv drifted."
        ;;
    CANNOT_UD_GUEST_*)
        ud_marker=${ud_report#CANNOT_UD_GUEST_}
        ud_marker=${ud_marker%% *}
        ud_rest=${ud_report#CANNOT_UD_GUEST_${ud_marker} }
        cannot ud-guest-x86 "UD_GUEST_$ud_marker" "$ud_rest"
        ;;
    *)
        cannot ud-guest-x86 UD_GUEST_UNKNOWN "ud-guest-x86 produced: ${ud_report:-empty}"
        ;;
esac

# Carried-golden scoreboard guest. Same objects as ud_guest; committed
# recipe is foundation-macho/scripts/build_ud_score_guest.sh. Stamp reuse
# is bin/ud_score_guest.inputs (objects + libCFTest sha + link argv).
echo "==== ud-score-guest (committed foundation-macho/scripts/build_ud_score_guest.sh) ===="
if [ "$UD_GUEST_ITEM_OK" -eq 1 ]; then
    score_report=$(phase2_try_ud_score_guest \
        "$W" \
        "${UD_GUEST_W:-$W/scratch/ud-guest-x86_64}" \
        "$SYS" \
        "$MC" \
        "$FE_OUT" \
        || true)
    case "$score_report" in
        OK\ bin=*status=satisfied*)
            UD_SCORE_BIN=${score_report#*bin=}
            UD_SCORE_BIN=${UD_SCORE_BIN%% *}
            export UD_SCORE_BIN
            note ud-score-guest satisfied "$score_report"
            echo "  $score_report"
            ;;
        OK\ bin=*status=cold-built*)
            UD_SCORE_BIN=${score_report#*bin=}
            UD_SCORE_BIN=${UD_SCORE_BIN%% *}
            export UD_SCORE_BIN
            note ud-score-guest cold-built "$score_report"
            echo "  $score_report"
            ;;
        OK\ bin=*)
            UD_SCORE_BIN=${score_report#*bin=}
            UD_SCORE_BIN=${UD_SCORE_BIN%% *}
            export UD_SCORE_BIN
            note ud-score-guest cold-built "$score_report"
            echo "  $score_report"
            ;;
        CANNOT_UD_GUEST_*)
            score_marker=${score_report#CANNOT_UD_GUEST_}
            score_marker=${score_marker%% *}
            score_rest=${score_report#CANNOT_UD_GUEST_${score_marker} }
            cannot ud-score-guest "UD_GUEST_$score_marker" "$score_rest"
            ;;
        *)
            cannot ud-score-guest UD_SCORE_UNKNOWN \
                "ud-score-guest produced: ${score_report:-empty}"
            ;;
    esac
else
    cannot ud-score-guest UD_SCORE_INPUTS \
        "ud-guest-x86 did not produce FE/libCFTest/port objects. Committed recipe is foundation-macho/scripts/build_ud_score_guest.sh; persist not faked."
fi

# Stage libCFTest into the run root after link, before run. Arm64
# build_cftest_harness.sh copies into $W/root; x86 W is the ud-guest work
# tree, so this is the analogue for scratch/mrroot_full-x86_64. Not a
# build_full.sh step (that script never stages libCFTest).
echo "==== libCFTest into run root (after link, before run_ud_guest.sh) ===="
if [ "$UD_GUEST_ITEM_OK" -eq 1 ] && [ -d "$MRROOT" ]; then
    cftest_src=${UD_GUEST_W:-$W/scratch/ud-guest-x86_64}/lib/libCFTest.dylib
    cftest_report=$(phase2_stage_cftest_into_run_root "$cftest_src" "$MRROOT" || true)
    case "$cftest_report" in
        status=satisfied\ path=*)
            note libCFTest-run-root satisfied "${cftest_report#status=satisfied }"
            ;;
        status=cold-built\ path=*)
            note libCFTest-run-root cold-built "${cftest_report#status=cold-built }"
            ;;
        *)
            cannot libCFTest-run-root CFTEST_STAGE \
                "${cftest_report:-empty}. arm64 stages via build_cftest_harness.sh into \$W/root; x86 stages scratch/ud-guest-x86_64/lib/libCFTest.dylib into $MRROOT/darwin/usr/lib/libCFTest.dylib (not the CoreFoundation.framework slot)."
            ;;
    esac
elif [ "$UD_GUEST_ITEM_OK" -eq 1 ]; then
    cannot libCFTest-run-root CFTEST_STAGE \
        "ud_guest linked but no run root at $MRROOT to stage libCFTest.dylib into"
fi

# Linux Dispatch host bridge + Darwin runtime image. Reuse the Reminder/Focus
# helper (BASE_MRROOT/host from phase2_build_x86_host_helpers) when it already
# ran. Do not mutate mrroot_full; the runner clones a run-local overlay.
echo "==== ud-guest-dispatch (Linux host bridge + Darwin OpenDispatch) ===="
UD_DISPATCH_HOST=
UD_DISPATCH_DARWIN=
if [ "$UD_GUEST_ITEM_OK" -eq 1 ]; then
    dispatch_report=$(phase2_ud_guest_ensure_dispatch \
        "$W" \
        "${UD_GUEST_W:-$W/scratch/ud-guest-x86_64}" \
        "$SYS" \
        "$TARGET" \
        "$BASE_MRROOT/host/libOpenDispatchHost.so" \
        || true)
    case "$dispatch_report" in
        status=satisfied\ bridge=*)
            UD_DISPATCH_HOST=${dispatch_report#*bridge=}
            UD_DISPATCH_HOST=${UD_DISPATCH_HOST%% *}
            UD_DISPATCH_DARWIN=${dispatch_report#*runtime=}
            UD_DISPATCH_DARWIN=${UD_DISPATCH_DARWIN%% *}
            export UD_DISPATCH_HOST UD_DISPATCH_DARWIN
            note ud-guest-dispatch satisfied "${dispatch_report#status=satisfied }"
            ;;
        status=cold-built\ bridge=*)
            UD_DISPATCH_HOST=${dispatch_report#*bridge=}
            UD_DISPATCH_HOST=${UD_DISPATCH_HOST%% *}
            UD_DISPATCH_DARWIN=${dispatch_report#*runtime=}
            UD_DISPATCH_DARWIN=${UD_DISPATCH_DARWIN%% *}
            export UD_DISPATCH_HOST UD_DISPATCH_DARWIN
            note ud-guest-dispatch cold-built "${dispatch_report#status=cold-built }"
            ;;
        *)
            cannot ud-guest-dispatch UD_GUEST_DISPATCH \
                "${dispatch_report:-empty}. Reuse $BASE_MRROOT/host/libOpenDispatchHost.so when already ELF; otherwise full/dispatch/build_host_bridge.sh. Darwin image is OpenDispatchBridge.c with LC_ID /usr/lib/libOpenDispatch.dylib."
            ;;
    esac
fi

# Rung a does not invoke build_full.sh, whose stamp copy is what refreshes
# $MRROOT/machorun for rungs b/c. The mrroot-x86 "satisfied" path also skips
# the copy. Refresh here so rung a execs the loader just built, not a stale
# $MRROOT/machorun from an earlier tree (the DF2 exit-74 vs manual-run split).
echo "==== run-root loader refresh (stamp, before rung a) ===="
if [ -x "$MACHORUN/build/machorun" ] && [ -d "$MRROOT" ]; then
    loader_key=$(stamp_key "$MRROOT/machorun" "$MACHORUN/build/machorun")
    if stamp_reuse "$MRROOT/machorun" "$loader_key"; then
        echo "  $MRROOT/machorun reused stamp=$(stamp_short "$loader_key") sha256=$(sha256sum "$MRROOT/machorun" | awk '{print $1}')"
    else
        stamp_rebuild_reason "$MRROOT/machorun" "$loader_key"
        cp -f "$MACHORUN/build/machorun" "$MRROOT/machorun"
        chmod a+x "$MRROOT/machorun"
        stamp_write "$MRROOT/machorun" "$loader_key"
        echo "  refreshed $MRROOT/machorun from $MACHORUN/build/machorun sha256=$(sha256sum "$MRROOT/machorun" | awk '{print $1}')"
    fi
fi

# ---------------------------------------------------------------------------
# 7. Rungs. Reuse committed gates. Never invent new denominators.
echo "==== rungs (committed runners only) ===="

actual_smoke=$(grep -c '^check(' "$UD_RUNNER" || true)
[ "$actual_smoke" = "$UD_SMOKE_CHECKS" ] || {
    echo "phase2: ud_guest_runner.swift has $actual_smoke check() calls, expected $UD_SMOKE_CHECKS" >&2
    echo "        the denominator is the committed runner's, not this script's. refuse rather than invent." >&2
    cannot rung-a-denominator SMOKE_DENOMINATOR "ud_guest_runner.swift check() count $actual_smoke != $UD_SMOKE_CHECKS"
}

RUNG_A=CANNOT
RUNG_A_DETAIL=not-run
RUNG_B=CANNOT
RUNG_B_DETAIL=not-run
RUNG_C=CANNOT
RUNG_C_DETAIL=not-run

find_existing_dir() {
    local c
    for c in "$@"; do
        [ -n "$c" ] || continue
        [ -d "$c" ] || continue
        printf '%s\n' "$c"
        return 0
    done
    return 1
}

find_existing_file() {
    local c
    for c in "$@"; do
        [ -n "$c" ] || continue
        [ -f "$c" ] || continue
        printf '%s\n' "$c"
        return 0
    done
    return 1
}



# Rung a: ud_guest smoke (14) + scoreboard + persist
if phase2_rung_selected a && [ "$FE_OK" -eq 1 ] && [ "$MRROOT_OK" -eq 1 ] && [ "$LIBSWIFTCORE_X86" -eq 1 ]; then
    echo "== rung a: foundation-macho run_ud_guest.sh + run_ud_persist.sh"
    # The committed runners take a NAMED root and a binary. If this tree has
    # not yet linked ud_guest for x86, refuse rather than invent a new linker.
    ud_w=$W/scratch/ud-guest-x86_64
    ud_r=$W/foundation-macho
    ud_bin=$(find_existing_file \
        "${UD_GUEST_BIN:-}" \
        "$ud_w/bin/ud_guest" \
        "$W/scratch/ud-guest/bin/ud_guest" \
        "$ud_r/bin/ud_guest" || true)
    ud_score=$(find_existing_file \
        "${UD_SCORE_BIN:-}" \
        "$ud_w/bin/ud_score_guest" \
        "$W/scratch/ud-guest/bin/ud_score_guest" \
        "$ud_r/bin/ud_score_guest" || true)
    if [ -n "$ud_bin" ] && phase2_is_x86_macho "$ud_bin"; then
        # ud_dispatch_run.inc reuses $W/runroot if Foundation is present
        # (existence, not content). A stale clone keeps the pre-mapping
        # libCFTest and the smoke still exits 71.
        rm -rf "${UD_GUEST_W:-$ud_w}/runroot"
        set +e
        W=${UD_GUEST_W:-$ud_w} \
            R=$ud_r \
            BIN=$ud_bin \
            MRUN=$MRROOT/machorun \
            DISPATCH_HOST=${UD_DISPATCH_HOST:-} \
            DISPATCH_DARWIN=${UD_DISPATCH_DARWIN:-} \
            bash "$ud_r/scripts/run_ud_guest.sh" "$MRROOT" \
            2>&1 | tee "$W/scratch/phase2-rung-a-smoke.log"
        smoke_rc=${PIPESTATUS[0]}
        set -e
        smoke_pass=$(grep -E 'guest runner: pass ' "$W/scratch/phase2-rung-a-smoke.log" | tail -1 || true)
        if [ "$smoke_rc" -eq 0 ]; then
            RUNG_A_DETAIL="smoke $UD_SMOKE_CHECKS/$UD_SMOKE_CHECKS ($smoke_pass)"
            if [ -n "$ud_score" ] && phase2_is_x86_macho "$ud_score"; then
                # run_ud_persist.sh defaults PREFS=/root/Library/Preferences
                # (operator EC2 is root). The guest writes under $HOME; a
                # Cursor cloud agent is not root, so the witness must look
                # there. Do not edit the committed runner.
                : "${PREFS:=$HOME/Library/Preferences}"
                mkdir -p "$PREFS"
                set +e
                W=${UD_GUEST_W:-$ud_w} \
                    R=$ud_r \
                    BIN=$ud_score \
                    MRUN=$MRROOT/machorun \
                    DISPATCH_HOST=${UD_DISPATCH_HOST:-} \
                    DISPATCH_DARWIN=${UD_DISPATCH_DARWIN:-} \
                    PREFS=$PREFS \
                    bash "$ud_r/scripts/run_ud_persist.sh" "$MRROOT" \
                    2>&1 | tee "$W/scratch/phase2-rung-a-persist.log"
                persist_rc=${PIPESTATUS[0]}
                set -e
                # The persist log prints the board TWICE: the positive run
                # (first) and the NEGATIVE CONTROL with the store deleted
                # (last; it must fail and reads e.g. port 313/579). Quote the
                # positive one -- measured 2026-09-03 on x86_64: tail -1 put
                # the control's 313/579 on the scoreboard while the real
                # board was 579/579.
                persist_board=$(sed -n '1,/NEGATIVE CONTROL/p' "$W/scratch/phase2-rung-a-persist.log" | grep 'GUEST SCOREBOARD' | head -1 | phase2_flatten || true)
                persist_port=$(sed -n '1,/NEGATIVE CONTROL/p' "$W/scratch/phase2-rung-a-persist.log" | grep 'PORT: scored' | head -1 | phase2_flatten || true)
                persist_presence=$(sed -n '1,/NEGATIVE CONTROL/p' "$W/scratch/phase2-rung-a-persist.log" | grep 'presence:' | head -1 | phase2_flatten || true)
                if [ -n "$persist_board" ]; then
                    RUNG_A_DETAIL="smoke $UD_SMOKE_CHECKS/$UD_SMOKE_CHECKS ($smoke_pass); persist $persist_board"
                fi
                if [ "$persist_rc" -eq 0 ]; then
                    RUNG_A=PASS
                    note rung-a-ud_guest cold-built "${persist_board:+$persist_board }${persist_port:+$persist_port }${persist_presence:+$persist_presence}"
                else
                    RUNG_A=FAIL
                    cannot rung-a-ud_guest UD_PERSIST \
                        "run_ud_persist.sh exit $persist_rc${persist_board:+; $persist_board}${persist_port:+; $persist_port}. Success bar unchanged: persist-read exit 0 and control must fail (committed run_ud_persist.sh)."
                fi
            else
                cannot rung-a-ud_guest UD_SCOREBOARD "smoke passed; ud_score_guest binary absent (committed build_ud_score_guest.sh). persist not faked."
            fi
        else
            cannot rung-a-ud_guest UD_SMOKE "run_ud_guest.sh exit $smoke_rc (denominator $UD_SMOKE_CHECKS/$UD_SMOKE_CHECKS in ud_guest_runner.swift)"
        fi
    else
        cannot rung-a-ud_guest UD_GUEST_BINARY \
            "no x86_64 ud_guest Mach-O after ud-guest-x86. Committed linker is foundation-macho/scripts/link_ud_guest.sh against scratch/ud-guest-x86_64 (never a second linker). See ENV_PREPARE ud-guest-x86 CANNOT_UD_GUEST_* file=."
        RUNG_A_DETAIL="no ud_guest binary"
    fi
else
    if phase2_rung_selected_quiet a; then
        cannot rung-a-ud_guest UD_GUEST_SUBSTRATE \
            "needs x86 FE (fe=$FE_OK) + x86 mrroot with libswiftCore (mrroot=$MRROOT_OK libswiftCore=$LIBSWIFTCORE_X86). Committed runners: run_ud_guest.sh smoke $UD_SMOKE_CHECKS/$UD_SMOKE_CHECKS in tests/ud_guest_runner.swift; run_ud_persist.sh persist board. Denominators unchanged."
        RUNG_A_DETAIL="blocked by substrate"
    else
        RUNG_A_DETAIL="SKIPPED (PHASE2_RUNGS=$PHASE2_RUNGS)"
    fi
fi

# Rung b: Focus widget + onboarding. Same source-preservation contracts.
FOCUS_PIN=a2832521c1daa0c23419c73705ae043ed60c9791
# Do not require a .git directory on the app subtree. The corpus git root is
# the parent (scratch/ladder-corpus/focus-ios); focus-ios/focus-ios is the
# application checkout inside it.
# Probe names expected and observed on every refusal (including git errors).
focus_pin_probe=$(phase2_probe_focus_pin "$FOCUS_REPO" "$FOCUS_PIN" || true)
case "$focus_pin_probe" in
    MATCH*) note focus-pin satisfied ;;
    *)
        if phase2_rung_selected_quiet b; then
            cannot focus-pin FOCUS_PIN "$focus_pin_probe"
        else
            note focus-pin skipped \
                "PHASE2_RUNGS=$PHASE2_RUNGS; $focus_pin_probe. Rung b would CANNOT_FOCUS_PIN."
        fi
        ;;
esac

find_widget_bundle() {
    local c recorded
    if [ -f "$W/scratch/phase2-focus-resources.path" ]; then
        recorded=$(tr -d '\n' < "$W/scratch/phase2-focus-resources.path")
        [ -d "$recorded/bundles/Focus_Widget.bundle" ] \
            && [ -f "$recorded/bundles/Focus_Widget.bundle/resource-index.json" ] \
            && { printf '%s\n' "$recorded/bundles/Focus_Widget.bundle"; return 0; }
    fi
    for c in \
        "${FOCUS_WIDGET_BUNDLE:-}" \
        "$W/scratch/focus-resources/bundles/Focus_Widget.bundle" \
        "$W/scratch/focus-resources/Focus_Widget.bundle" \
        "$W/scratch/ladder-corpus/focus-ios/bundles/Focus_Widget.bundle" \
        "$W/scratch/ladder-corpus/focus-ios/Focus_Widget.bundle"
    do
        [ -n "$c" ] || continue
        [ -d "$c" ] && [ -f "$c/resource-index.json" ] || continue
        printf '%s\n' "$c"
        return 0
    done
    return 1
}

find_onboarding_bundles_dir() {
    local c recorded
    if [ -f "$W/scratch/phase2-focus-resources.path" ]; then
        recorded=$(tr -d '\n' < "$W/scratch/phase2-focus-resources.path")
        if [ -d "$recorded/bundles/Focus_Onboarding.bundle" ] \
            && [ -d "$recorded/bundles/Focus_Widget.bundle" ]; then
            printf '%s\n' "$recorded/bundles"
            return 0
        fi
    fi
    for c in \
        "${FOCUS_ONBOARDING_BUNDLES:-}" \
        "$W/scratch/focus-resources/bundles" \
        "$W/scratch/ladder-corpus/focus-ios/bundles"
    do
        [ -n "$c" ] || continue
        [ -d "$c/Focus_Onboarding.bundle" ] && [ -d "$c/Focus_Widget.bundle" ] || continue
        printf '%s\n' "$c"
        return 0
    done
    return 1
}

try_normalize_focus_bundles() {
    local marker=$W/scratch/phase2-focus-resources.path
    local recorded out_parent out
    if [ -f "$marker" ]; then
        recorded=$(tr -d '\n' < "$marker")
        if [ -d "$recorded/bundles/Focus_Widget.bundle" ] \
            && [ -f "$recorded/bundles/Focus_Widget.bundle/resource-index.json" ]; then
            return 0
        fi
    fi
    [ "${ITEM_STATUS[focus-pin]:-}" = satisfied ] || return 1
    [ -f "$W/full/focus-ios/onboarding-resources-proof.json" ] || return 1
    # Committed prove() refuses output inside the policy/source git tops and
    # requires a 0700 parent. Use /tmp, never $W/scratch.
    out_parent=$(mktemp -d /tmp/focus-resources-x86.XXXXXX)
    chmod 0700 "$out_parent"
    out=$out_parent/proof
    echo "== committed onboarding_resources_proof.py prove -> $out"
    set +e
    python3 -B "$W/full/focus-ios/onboarding_resources_proof.py" prove \
        "$FOCUS_REPO" \
        "$W/full/focus-ios/onboarding-resources-proof.json" \
        "$out"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && [ -d "$out/bundles/Focus_Widget.bundle" ]; then
        printf '%s\n' "$out" > "$marker"
        return 0
    fi
    return 1
}

if phase2_rung_selected b && [ "$OC_OK" -eq 1 ] && [ "$FE_OK" -eq 1 ] && [ "$MRROOT_OK" -eq 1 ] \
    && [ "$LIBSWIFTCORE_X86" -eq 1 ] && [ "$HOST_RUNTIME_OK" -eq 1 ] \
    && [ "$LAYOUT_OK" -eq 1 ] && [ "$SYSROOT_TBDS_OK" -eq 1 ] \
    && [ "${ITEM_STATUS[focus-pin]:-}" = satisfied ]; then
    echo "== rung b: full/swiftui Focus widget + onboarding (x86, source pins unchanged)"
    widget_bundle=$(find_widget_bundle || true)
    if [ -z "$widget_bundle" ]; then
        try_normalize_focus_bundles || true
        widget_bundle=$(find_widget_bundle || true)
    fi
    if [ -z "$widget_bundle" ]; then
        cannot rung-b-focus FOCUS_BUNDLE \
            "no normalized Focus_Widget.bundle; committed full/focus-ios/onboarding_resources_proof.py prove did not emit bundles/Focus_Widget.bundle (needs Focus pin + pdftocairo; output must be outside the git top). Operator: set FOCUS_WIDGET_BUNDLE. NEEDS_X86_OPENCOMBINE is resolved by export-x86_64 (arm64 export/ untouched)."
        RUNG_B_DETAIL="no Focus_Widget.bundle"
    else
        echo "== build_focus_widget_guest.sh $widget_bundle"
        set +e
        W="$W" UIKIT="$W/uikit" MACHORUN="$MACHORUN" OPENCOMBINE_ROOT="$OPENCOMBINE_ROOT" \
            bash "$W/full/swiftui/build_focus_widget_guest.sh" "$widget_bundle" \
            2>&1 | tee "$W/scratch/phase2-rung-b-widget.log"
        widget_rc=${PIPESTATUS[0]}
        set -e
        onboard_dir=$(find_onboarding_bundles_dir || true)
        onboard_rc=2
        if [ "$widget_rc" -eq 0 ] && [ -n "$onboard_dir" ]; then
            echo "== build_focus_onboarding_guest.sh $onboard_dir"
            set +e
            W="$W" UIKIT="$W/uikit" MACHORUN="$MACHORUN" OPENCOMBINE_ROOT="$OPENCOMBINE_ROOT" \
                bash "$W/full/swiftui/build_focus_onboarding_guest.sh" "$onboard_dir" \
                2>&1 | tee "$W/scratch/phase2-rung-b-onboarding.log"
            onboard_rc=${PIPESTATUS[0]}
            set -e
        elif [ "$widget_rc" -eq 0 ]; then
            cannot rung-b-focus FOCUS_ONBOARDING_BUNDLE \
                "widget guest passed; no Focus_Onboarding.bundle directory beside it (committed build_focus_onboarding_guest.sh). Set FOCUS_ONBOARDING_BUNDLES."
            RUNG_B_DETAIL="widget ok; onboarding bundle missing"
        fi
        if [ "$widget_rc" -eq 0 ] && [ "$onboard_rc" -eq 0 ]; then
            RUNG_B=PASS
            RUNG_B_DETAIL="widget+onboarding under $OTOOL_CPU loader"
            note rung-b-focus cold-built
        elif [ "$widget_rc" -ne 0 ]; then
            cannot rung-b-focus FOCUS_WIDGET_GUEST \
                "build_focus_widget_guest.sh exit $widget_rc (source-preservation + otool $OTOOL_CPU unchanged; see scratch/phase2-rung-b-widget.log)"
            RUNG_B_DETAIL="widget guest failed"
        elif [ "$onboard_rc" -ne 0 ] && [ -n "$onboard_dir" ]; then
            cannot rung-b-focus FOCUS_ONBOARDING_GUEST \
                "build_focus_onboarding_guest.sh exit $onboard_rc (see scratch/phase2-rung-b-onboarding.log)"
            RUNG_B_DETAIL="onboarding guest failed"
        fi
    fi
else
    if phase2_rung_selected_quiet b; then
        cannot rung-b-focus SWIFTUI_SUBSTRATE \
            "needs x86 OpenCombine.o (oc=$OC_OK; else NEEDS_X86_OPENCOMBINE), x86 FE (fe=$FE_OK), x86 mrroot (mrroot=$MRROOT_OK), x86 libswiftCore ($LIBSWIFTCORE_X86), x86 host runtime (host=$HOST_RUNTIME_OK; else CANNOT_X86_HOST_RUNTIME), x86 mrroot layout (layout=$LAYOUT_OK; else CANNOT_X86_MRROOT_LAYOUT), x86 sysroot tbds (tbds=$SYSROOT_TBDS_OK; else CANNOT_X86_SYSROOT_TBDS), Focus pin $FOCUS_PIN. Source-preservation contracts in full/swiftui/*_guest.sh are unchanged; arm64 object SHAs are not rewritten."
        RUNG_B_DETAIL="blocked by substrate"
    else
        RUNG_B_DETAIL="SKIPPED (PHASE2_RUNGS=$PHASE2_RUNGS)"
    fi
fi

# Rung c: Reminder scene -- one active UIWindow + three paced turns.
reminder_inv=$(find_existing_file \
    "${REMINDER_INVENTORY:-}" \
    "$W/scratch/ladder-corpus/reminder/Reminder.project-inventory.json" \
    "$W/scratch/ladder-corpus/Reminder/Reminder.project-inventory.json" \
    "$W/scratch/Reminder.project-inventory.json" || true)
reminder_src=$(find_existing_dir \
    "${REMINDER_SOURCE_ROOT:-}" \
    "$W/scratch/ladder-corpus/reminder/source" \
    "$W/scratch/ladder-corpus/reminder" \
    "$W/scratch/ladder-corpus/Reminder" || true)
if phase2_rung_selected c && [ "$FE_OK" -eq 1 ] && [ "$MRROOT_OK" -eq 1 ] && [ "$LIBSWIFTCORE_X86" -eq 1 ] \
    && [ "$HOST_RUNTIME_OK" -eq 1 ] && [ "$LAYOUT_OK" -eq 1 ] \
    && [ "$SYSROOT_TBDS_OK" -eq 1 ] \
    && [ -n "$reminder_inv" ] && [ -n "$reminder_src" ]; then
    echo "== rung c: full/xcodeplan/build_and_run_reminder_scene_guest.sh"
    set +e
    UIKIT_CHECKOUT="${UIKIT_CHECKOUT:-$W/uikit}" \
    MACHORUN_CHECKOUT="${MACHORUN_CHECKOUT:-$MACHORUN}" \
    OPENUIKIT_HOST_TURNS=3 \
        bash "$W/full/xcodeplan/build_and_run_reminder_scene_guest.sh" \
            "$reminder_inv" "$reminder_src" \
        2>&1 | tee "$W/scratch/phase2-rung-c-reminder.log"
    rem_rc=${PIPESTATUS[0]}
    set -e
    rem_log=$W/scratch/phase2-rung-c-reminder.log
    if [ "$rem_rc" -eq 0 ] \
        && grep -Fxq "REMINDER_UNCHANGED_WILL_CONNECT_OK" "$rem_log" \
        && grep -Fxq "PORTABLE_UIKIT_HOST_ACTIVE windows=1" "$rem_log" \
        && grep -Fxq "PORTABLE_UIKIT_HOST_LOOP_OK turns=3 paced=true" "$rem_log"; then
        RUNG_C=PASS
        RUNG_C_DETAIL="windows=1 turns=3 paced=true"
        note rung-c-reminder cold-built
    else
        cannot rung-c-reminder REMINDER_SCENE \
            "build_and_run_reminder_scene_guest.sh exit $rem_rc; success bar is REMINDER_UNCHANGED_WILL_CONNECT_OK + PORTABLE_UIKIT_HOST_ACTIVE windows=1 + PORTABLE_UIKIT_HOST_LOOP_OK turns=3 paced=true (committed inner script, not invented here)"
        RUNG_C_DETAIL="scene guest failed"
    fi
elif phase2_rung_selected_quiet c \
    && [ "$FE_OK" -eq 1 ] && [ "$MRROOT_OK" -eq 1 ] && [ "$LIBSWIFTCORE_X86" -eq 1 ] \
    && [ "$HOST_RUNTIME_OK" -eq 1 ] && [ "$LAYOUT_OK" -eq 1 ] \
    && [ "$SYSROOT_TBDS_OK" -eq 1 ]; then
    cannot rung-c-reminder REMINDER_INVENTORY \
        "substrate ready enough to invoke full/xcodeplan/build_and_run_reminder_scene_guest.sh, but Reminder 22-source inventory + source root are absent. Looked at scratch/ladder-corpus/reminder and REMINDER_INVENTORY/REMINDER_SOURCE_ROOT. Success bar remains: REMINDER_UNCHANGED_WILL_CONNECT_OK + PORTABLE_UIKIT_HOST_ACTIVE windows=1 + PORTABLE_UIKIT_HOST_LOOP_OK turns=3 paced=true."
    RUNG_C_DETAIL="needs Reminder inventory json + source root"
elif phase2_rung_selected_quiet c; then
    cannot rung-c-reminder REMINDER_SUBSTRATE \
        "needs x86 FE+mrroot+libswiftCore+host runtime+layout+sysroot tbds (fe=$FE_OK mrroot=$MRROOT_OK libswiftCore=$LIBSWIFTCORE_X86 host=$HOST_RUNTIME_OK layout=$LAYOUT_OK tbds=$SYSROOT_TBDS_OK) plus Reminder 22-source inventory. Success bar: 1 UIWindow + 3 paced turns under the ported loader. Denominator from the committed inner script, not invented here."
    RUNG_C_DETAIL="blocked by substrate"
else
    RUNG_C_DETAIL="SKIPPED (PHASE2_RUNGS=$PHASE2_RUNGS)"
fi

# ---------------------------------------------------------------------------
echo
echo "==== RUNG_SCOREBOARD ===="
echo "RUNG_SCOREBOARD a=$RUNG_A/$RUNG_A_DETAIL  b=$RUNG_B/$RUNG_B_DETAIL  c=$RUNG_C/$RUNG_C_DETAIL"
echo "denominators: a smoke $UD_SMOKE_CHECKS/$UD_SMOKE_CHECKS (foundation-macho/tests/ud_guest_runner.swift check() calls)  scoreboard=committed run_ud_guest.sh/build_ud_score_guest.sh  persist=committed run_ud_persist.sh; b widget+onboarding source-preservation + otool $OTOOL_CPU from full/swiftui/build_focus_{widget,onboarding}_guest.sh; c windows=1 turns=3 paced=true from full/xcodeplan/build_and_run_reminder_scene_guest.sh"
echo "ENV_PREPARE_SUMMARY satisfied=$SATISFIED_N cold-built=$COLT_N CANNOT=$CANNOT_N libswiftCore-x86=$LIBSWIFTCORE_X86"
echo "arm64 trees left untouched: $ARM_SYS $ARM_MRROOT $OPENCOMBINE_ROOT/export"

if [ "$CANNOT_N" -gt 0 ]; then
    echo "phase2: $CANNOT_N CANNOT line(s); refusing overall success." >&2
    exit 2
fi
echo "phase2: all ENV_PREPARE items satisfied or cold-built; rungs passed."
exit 0
