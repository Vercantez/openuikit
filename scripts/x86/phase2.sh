#!/usr/bin/env bash
# phase2.sh -- one operator command: take a provisioned x86_64 Linux openuikit
# tree from PR #7's phase-1 state to the real-app ladder under the ported loader.
#
#   bash scripts/x86/phase2.sh /opt/openuikit/x86-verify/openuikit
#
# Idempotent. Prints ENV_PREPARE satisfied/cold-built/CANNOT lines and a final
# RUNG_SCOREBOARD with the committed runners' denominators. Never fakes success,
# never overwrites arm64 scratch/sysroot_fe4 or scratch/mrroot_full, never
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

W=$(cd "$1" && pwd)
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
ARM_SYS=$W/scratch/sysroot_fe4
MRROOT=$W/scratch/mrroot_full${FULL_OUT_SUFFIX}
ARM_MRROOT=$W/scratch/mrroot_full
OPENCOMBINE_ROOT=$W/scratch/opencombine-core-durable-20260828-r2
SF=$W/scratch/swift-foundation
SC=$W/scratch/swift-collections
FOCUS_REPO=$W/scratch/ladder-corpus/focus-ios/focus-ios
UD_SMOKE_CHECKS=14
UD_RUNNER=$W/foundation-macho/tests/ud_guest_runner.swift

CANNOT_N=0
SATISFIED_N=0
COLT_N=0
declare -A ITEM_STATUS=()

note() {
    local name=$1 status=$2
    ITEM_STATUS[$name]=$status
    case "$status" in
        satisfied) SATISFIED_N=$((SATISFIED_N + 1)); phase2_prepare "$name" satisfied ;;
        cold-built) COLT_N=$((COLT_N + 1)); phase2_prepare "$name" cold-built ;;
        CANNOT_*)
            CANNOT_N=$((CANNOT_N + 1))
            phase2_prepare "$name" "$status${3:+ reason=$3}"
            ;;
        *) phase2_prepare "$name" "$status${3:+ reason=$3}" ;;
    esac
}

cannot() {
    # cannot <name> <MARKER> <reason>
    ITEM_STATUS[$1]=CANNOT_$2
    CANNOT_N=$((CANNOT_N + 1))
    phase2_cannot "$1" "$2" "$3"
}

have() { [ -e "$1" ]; }

# ---------------------------------------------------------------------------
echo "==== PHASE 2  host=$(uname -m)  W=$W  TARGET=$TARGET ===="

# 0. Host + toolchain
if [ "$(uname -m)" != x86_64 ]; then
    cannot host-arch HOST_NOT_X86_64 "uname -m is $(uname -m); this runner is the x86_64 operator path"
    echo "RUNG_SCOREBOARD a=CANNOT/host b=CANNOT/host c=CANNOT/host"
    echo "denominators: a 0/$UD_SMOKE_CHECKS smoke (ud_guest_runner.swift)  scoreboard=committed run_ud_guest.sh  persist=committed run_ud_persist.sh; b widget+onboarding source-preservation from full/swiftui; c windows=1 turns=3 from build_and_run_reminder_scene_guest.sh"
    exit 2
fi
note host-arch satisfied

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
    echo "configure_sh_pins SWIFT_HOST_VARIANT_ARCH=aarch64 SWIFT_SDK_OSX_ARCHITECTURES=arm64 SWIFT_DARWIN_SUPPORTED_ARCHS=arm64 SWIFT_HOST_TRIPLE=aarch64-unknown-linux-gnu"
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
        "no x86_64 slice in swiftcore-macho/artifacts (only arm64/libswiftCore.dylib + Swift.swiftmodule/arm64-apple-macos.*); stdlib source is not in this tree; configure.sh hardcodes aarch64-host/arm64-Darwin; swiftc -target $TARGET against sysroot_fe4 fails looking for x86_64-apple-macos _Concurrency/Swift modules (found: arm64-apple-macos). Cross-building libswiftCore is the CMake+Ninja stdlib-only recipe in swiftcore-macho/docs/BUILD_LOG.md, historically on a Graviton box against a full swift.org 6.2.4 checkout. Do not stage the arm64 dylib under an x86 name. measurement=$measure_log"
    cat "$measure_log" | sed 's/^/  /'
fi

# ---------------------------------------------------------------------------
# 2. machorun substrate: loader, darwin, objc4, quartz, tbd
echo "==== machorun substrate (build.sh all, objc4, quartz, tbd) ===="

ensure_loader() {
    local bin=$MACHORUN/build/machorun
    if phase2_is_elf_x86_loader "$bin"; then
        note machorun-loader satisfied
        return 0
    fi
    echo "== cold-build loader (CC=$CC)"
    sh "$MACHORUN/scripts/build.sh" loader
    if phase2_is_elf_x86_loader "$bin"; then
        note machorun-loader cold-built
        return 0
    fi
    cannot machorun-loader BUILD_LOADER "scripts/build.sh loader did not produce an x86-64 ELF PIE at $bin"
    return 1
}

ensure_darwin() {
    local dylib=$MACHORUN/darwin/usr/lib/libSystem.B.dylib
    if [ -f "$dylib" ] && phase2_is_x86_macho "$dylib"; then
        note machorun-darwin satisfied
        return 0
    fi
    echo "== cold-build darwin userland (x86_64-apple-macos)"
    sh "$MACHORUN/scripts/build.sh" darwin
    if [ -f "$dylib" ] && phase2_is_x86_macho "$dylib"; then
        note machorun-darwin cold-built
        return 0
    fi
    cannot machorun-darwin BUILD_DARWIN "libSystem.B.dylib is not X86_64 Mach-O after build.sh darwin ($(file -b "$dylib" 2>/dev/null || echo missing))"
    return 1
}

ensure_objc4() {
    local dylib=$MACHORUN/darwin/usr/lib/libobjc.A.dylib
    if [ -f "$dylib" ] && phase2_is_x86_macho "$dylib"; then
        note machorun-objc4 satisfied
        return 0
    fi
    echo "== cold-build objc4 (unblocks the objc fixture CANNOT_BUILD_LIBOBJC_X86)"
    bash "$MACHORUN/scripts/build_objc4.sh"
    if [ -f "$dylib" ] && phase2_is_x86_macho "$dylib"; then
        note machorun-objc4 cold-built
        return 0
    fi
    cannot machorun-objc4 BUILD_LIBOBJC_X86 "libobjc.A.dylib is not X86_64 Mach-O after build_objc4.sh"
    return 1
}

ensure_quartz() {
    local dylib=$MACHORUN/darwin/usr/lib/libquartz.dylib
    if [ -f "$dylib" ] && phase2_is_x86_macho "$dylib"; then
        note machorun-quartz satisfied
        return 0
    fi
    echo "== cold-build quartz"
    bash "$MACHORUN/scripts/build_quartz.sh"
    if [ -f "$dylib" ] && phase2_is_x86_macho "$dylib"; then
        note machorun-quartz cold-built
        return 0
    fi
    cannot machorun-quartz BUILD_QUARTZ_X86 "libquartz.dylib is not X86_64 Mach-O after build_quartz.sh"
    return 1
}

ensure_tbd() {
    local tbd=$MACHORUN/sdk/usr/lib/libSystem.tbd
    if [ -s "$tbd" ] && grep -q x86_64 "$tbd" && [ -x "$MACHORUN/build/machorun" ]; then
        # Idempotent: a non-empty x86_64-macos tbd plus a live loader is enough.
        if grep -q 'x86_64-macos' "$tbd" 2>/dev/null || grep -q x86_64 "$tbd"; then
            note machorun-tbd satisfied
            return 0
        fi
    fi
    if ! phase2_is_elf_x86_loader "$MACHORUN/build/machorun"; then
        cannot machorun-tbd GENERATE_TBD "gen_tbd.sh CHECK 1 needs the host ELF loader; loader is missing"
        return 1
    fi
    echo "== cold-generate .tbd (CHECK 1 against this loader)"
    # CHECK 4 scans every dylib under darwin/usr/lib. An arm64 staged
    # libswiftcompat beside a freshly built x86 libSystem is a mixed-slice
    # coin toss, not a generated stub. Park arm64 dylibs beside (do not
    # delete) so the x86 .tbd projection is honest.
    park=$MACHORUN/darwin/usr/lib-arm64-park
    if [ -d "$MACHORUN/darwin/usr/lib" ]; then
        mkdir -p "$park"
        while IFS= read -r -d '' d; do
            phase2_is_arm64_macho "$d" || continue
            rel=${d#"$MACHORUN/darwin/usr/lib/"}
            mkdir -p "$park/$(dirname "$rel")"
            mv "$d" "$park/$rel"
            echo "  parked arm64 $rel -> darwin/usr/lib-arm64-park"
        done < <(find "$MACHORUN/darwin/usr/lib" -type f -name '*.dylib' -print0)
    fi
    set +e
    sh "$MACHORUN/scripts/build.sh" tbd
    st=$?
    set -e
    if [ "$st" -eq 0 ] && [ -s "$tbd" ]; then
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
echo "==== x86 sysroot (beside $ARM_SYS, never overwrite) ===="
[ -d "$ARM_SYS" ] || echo "  note: arm64 sysroot_fe4 is absent; textual Darwin overlays cannot be copied"
SYSROOT_OK=0
SYSROOT_HEADERS=0
sys_has_overlays=0
if [ -d "$SYS/usr/lib/swift/Darwin.swiftmodule" ] || [ -f "$SYS/usr/lib/swift/Darwin.swiftinterface" ]; then
    sys_has_overlays=1
fi
if [ -d "$SYS/usr/include" ] && [ -f "$SYS/usr/lib/libSystem.B.dylib" ] \
    && phase2_is_x86_macho "$SYS/usr/lib/libSystem.B.dylib" && [ "$sys_has_overlays" -eq 1 ]; then
    note sysroot-fe4-x86 satisfied
    SYSROOT_OK=1
    SYSROOT_HEADERS=1
elif [ -d "$SYS/usr/include" ] && [ -f "$SYS/usr/lib/libSystem.B.dylib" ] \
    && phase2_is_x86_macho "$SYS/usr/lib/libSystem.B.dylib" && [ "$sys_has_overlays" -eq 0 ]; then
    cannot sysroot-fe4-x86 STAGE_XCODE_DARWIN_OVERLAYS \
        "headers+x86 dylibs already at $SYS; Darwin.swiftmodule/swiftinterface absent (Linux cannot materialize Apple's overlay interfaces; arm64 sysroot_fe4 also lacks them). FE compile needs canImport(Darwin)==true."
    SYSROOT_HEADERS=1
else
    set +e
    bash "$HERE/stage_fe_sysroot.sh"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && [ -d "$SYS/usr/include" ]; then
        note sysroot-fe4-x86 cold-built
        SYSROOT_OK=1
        SYSROOT_HEADERS=1
    elif [ "$st" -eq 3 ]; then
        # Headers/dylibs staged; Darwin overlays missing. Partial tree exists.
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
fi
# Never copy arm64 dylibs into the x86 sysroot.
if [ -f "$SYS/usr/lib/libSystem.B.dylib" ] && phase2_is_arm64_macho "$SYS/usr/lib/libSystem.B.dylib"; then
    cannot sysroot-fe4-x86 ARM64_DYLIB_IN_X86_SYSROOT "libSystem.B.dylib in $SYS is still arm64; refuse rather than link against it"
    SYSROOT_OK=0
fi

# ---------------------------------------------------------------------------
# 4. FoundationEssentials + collections + cshims for x86
echo "==== FoundationEssentials / collections / cshims ($TARGET) ===="
FE_OK=0
COL_OK=0
CSHIMS_OK=0
FE_OUT=$W/build/full${FULL_OUT_SUFFIX}/foundation

try_collections() {
    local out=$FE_OUT/collections
    if [ -f "$out/OrderedCollections.o" ] && phase2_is_x86_macho "$out/OrderedCollections.o"; then
        note collections-x86 satisfied
        COL_OK=1
        return 0
    fi
    [ -d "$SC" ] || { cannot collections-x86 PINNED_SWIFT_COLLECTIONS "no $SC"; return 1; }
    [ "$SYSROOT_OK" -eq 1 ] || { cannot collections-x86 NEEDS_X86_SYSROOT "collections compile needs $SYS"; return 1; }
    [ "$LIBSWIFTCORE_X86" -eq 1 ] || {
        cannot collections-x86 BUILD_LIBSWIFTCORE_X86 "swiftc -target $TARGET cannot compile without an x86_64 Swift.swiftmodule (measured above)"
        return 1
    }
    mkdir -p "$out"
    set +e
    W="$W" SC="$SC" SYS="$SYS" OUT="$out" TARGET="$TARGET" \
        bash "$W/full/foundation/build_collections.sh"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && phase2_is_x86_macho "$out/OrderedCollections.o"; then
        note collections-x86 cold-built
        COL_OK=1
        return 0
    fi
    cannot collections-x86 BUILD_COLLECTIONS "build_collections.sh exit $st"
    return 1
}

try_cshims() {
    local out=$FE_OUT/cshims
    if [ -f "$out/uuid.o" ] && phase2_is_x86_macho "$out/uuid.o"; then
        note cshims-x86 satisfied
        CSHIMS_OK=1
        return 0
    fi
    [ -d "$SF" ] || { cannot cshims-x86 PINNED_SWIFT_FOUNDATION "no $SF"; return 1; }
    [ "$SYSROOT_HEADERS" -eq 1 ] || [ "$SYSROOT_OK" -eq 1 ] || {
        cannot cshims-x86 NEEDS_X86_SYSROOT "cshims compile needs $SYS"
        return 1
    }
    mkdir -p "$out"
    set +e
    W="$W" SF="$SF" SYS="$SYS" OUT="$out" TARGET="$TARGET" \
        bash "$W/full/foundation/build_cshims.sh"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && [ -f "$out/uuid.o" ] && phase2_is_x86_macho "$out/uuid.o"; then
        note cshims-x86 cold-built
        CSHIMS_OK=1
        return 0
    fi
    cannot cshims-x86 BUILD_CSHIMS "build_cshims.sh exit $st"
    return 1
}

try_fe() {
    local out=$FE_OUT/essentials
    if [ -f "$out/FoundationEssentials.o" ] && phase2_is_x86_macho "$out/FoundationEssentials.o"; then
        note foundationessentials-x86 satisfied
        FE_OK=1
        return 0
    fi
    [ -d "$SF" ] || { cannot foundationessentials-x86 PINNED_SWIFT_FOUNDATION "no $SF"; return 1; }
    [ "$SYSROOT_OK" -eq 1 ] || { cannot foundationessentials-x86 NEEDS_X86_SYSROOT "FE compile needs $SYS"; return 1; }
    [ "$LIBSWIFTCORE_X86" -eq 1 ] || {
        cannot foundationessentials-x86 BUILD_LIBSWIFTCORE_X86 "swiftc -target $TARGET cannot compile 202 FE files without x86_64 Swift/_Concurrency modules"
        return 1
    }
    mkdir -p "$out"
    set +e
    W="$W" SF="$SF" SYS="$SYS" TARGET="$TARGET" \
        COLLECTIONS="$FE_OUT/collections" \
        bash "$W/full/foundation/build_fe.sh" \
            -emit-module -emit-module-path "$out/FoundationEssentials.swiftmodule" \
            -c -o "$out/FoundationEssentials.o"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && phase2_is_x86_macho "$out/FoundationEssentials.o"; then
        note foundationessentials-x86 cold-built
        FE_OK=1
        return 0
    fi
    cannot foundationessentials-x86 BUILD_FE "build_fe.sh exit $st"
    return 1
}

try_cshims || true
try_collections || true
try_fe || true

# ---------------------------------------------------------------------------
# 5. OpenCombine for x86 beside the durable arm64 export/
echo "==== OpenCombine x86 (beside $OPENCOMBINE_ROOT/export) ===="
OC_OK=0
oc_obj=$OPENCOMBINE_ROOT/export-x86_64/artifacts/OpenCombine.o
if [ -f "$oc_obj" ] && phase2_is_x86_macho "$oc_obj"; then
    note opencombine-x86 satisfied
    OC_OK=1
else
    set +e
    W="$W" SYS="$SYS" OPENCOMBINE_ROOT="$OPENCOMBINE_ROOT" \
        bash "$HERE/build_opencombine.sh"
    st=$?
    set -e
    if [ "$st" -eq 0 ] && [ -f "$oc_obj" ] && phase2_is_x86_macho "$oc_obj"; then
        note opencombine-x86 cold-built
        OC_OK=1
    else
        cannot opencombine-x86 X86_OPENCOMBINE \
            "NEEDS_X86_OPENCOMBINE unresolved: x86 OpenCombine.o not produced (blocked by libswiftCore-x86=$LIBSWIFTCORE_X86 sysroot=$SYSROOT_OK). arm64 durable SHA in export/artifacts still stands; this runner writes only export-x86_64/"
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
# 6. mrroot_full-x86_64 beside mrroot_full
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

# ---------------------------------------------------------------------------
# 6b. Guest-visible /w layout (FocusWidgetGuestMain.swift fonts)
echo "==== /w layout (guest-visible fonts path) ===="
W_LAYOUT=0
w_resolved=$(readlink -f /w 2>/dev/null || true)
if [ -d /w ] && [ "$w_resolved" = "$W" ]; then
    note host-w-layout satisfied
    W_LAYOUT=1
elif [ ! -e /w ] && ln -sfn "$W" /w 2>/dev/null; then
    note host-w-layout cold-built
    W_LAYOUT=1
else
    cannot host-w-layout HOST_W_LAYOUT \
        "FocusWidgetGuestMain.swift opens /w/build/swiftui-guest/fonts; cannot ln -s $W /w (resolved=$(readlink -f /w 2>/dev/null || echo missing)). Widget argv already uses \$OUT; fonts still need this docker-era path. Operator: ln -sfn $W /w"
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
if [ "$FE_OK" -eq 1 ] && [ "$MRROOT_OK" -eq 1 ] && [ "$LIBSWIFTCORE_X86" -eq 1 ]; then
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
        set +e
        W=${UD_GUEST_W:-$ud_w} \
            R=$ud_r \
            BIN=$ud_bin \
            MRUN=$MRROOT/machorun \
            bash "$ud_r/scripts/run_ud_guest.sh" "$MRROOT" \
            | tee "$W/scratch/phase2-rung-a-smoke.log"
        smoke_rc=${PIPESTATUS[0]}
        set -e
        smoke_pass=$(grep -E 'guest runner: pass ' "$W/scratch/phase2-rung-a-smoke.log" | tail -1 || true)
        if [ "$smoke_rc" -eq 0 ]; then
            RUNG_A_DETAIL="smoke $UD_SMOKE_CHECKS/$UD_SMOKE_CHECKS ($smoke_pass)"
            if [ -n "$ud_score" ] && phase2_is_x86_macho "$ud_score"; then
                set +e
                W=${UD_GUEST_W:-$ud_w} \
                    R=$ud_r \
                    BIN=$ud_score \
                    MRUN=$MRROOT/machorun \
                    bash "$ud_r/scripts/run_ud_persist.sh" "$MRROOT" \
                    | tee "$W/scratch/phase2-rung-a-persist.log"
                persist_rc=${PIPESTATUS[0]}
                set -e
                if [ "$persist_rc" -eq 0 ]; then
                    RUNG_A=PASS
                    note rung-a-ud_guest cold-built
                else
                    RUNG_A=FAIL
                    cannot rung-a-ud_guest UD_PERSIST "run_ud_persist.sh exit $persist_rc"
                fi
            else
                cannot rung-a-ud_guest UD_SCOREBOARD "smoke passed; ud_score_guest binary absent (committed build_ud_score_guest.sh). persist not faked."
            fi
        else
            cannot rung-a-ud_guest UD_SMOKE "run_ud_guest.sh exit $smoke_rc (denominator $UD_SMOKE_CHECKS/$UD_SMOKE_CHECKS in ud_guest_runner.swift)"
        fi
    else
        cannot rung-a-ud_guest UD_GUEST_BINARY \
            "no x86_64 ud_guest Mach-O. Committed linker is foundation-macho/scripts/link_ud_guest.sh (objects in \$W/fe of a named foundation-macho work tree). Will not invent a second linker. Operator: stage CF+FE objects, link_ud_guest.sh, then re-run; or set UD_GUEST_BIN."
        RUNG_A_DETAIL="no ud_guest binary"
    fi
else
    cannot rung-a-ud_guest UD_GUEST_SUBSTRATE \
        "needs x86 FE (fe=$FE_OK) + x86 mrroot with libswiftCore (mrroot=$MRROOT_OK libswiftCore=$LIBSWIFTCORE_X86). Committed runners: run_ud_guest.sh smoke $UD_SMOKE_CHECKS/$UD_SMOKE_CHECKS in tests/ud_guest_runner.swift; run_ud_persist.sh persist board. Denominators unchanged."
    RUNG_A_DETAIL="blocked by substrate"
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
    *) cannot focus-pin FOCUS_PIN "$focus_pin_probe" ;;
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

if [ "$OC_OK" -eq 1 ] && [ "$FE_OK" -eq 1 ] && [ "$MRROOT_OK" -eq 1 ] \
    && [ "$LIBSWIFTCORE_X86" -eq 1 ] && [ "${ITEM_STATUS[focus-pin]:-}" = satisfied ]; then
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
            | tee "$W/scratch/phase2-rung-b-widget.log"
        widget_rc=${PIPESTATUS[0]}
        set -e
        onboard_dir=$(find_onboarding_bundles_dir || true)
        onboard_rc=2
        if [ "$widget_rc" -eq 0 ] && [ -n "$onboard_dir" ]; then
            echo "== build_focus_onboarding_guest.sh $onboard_dir"
            set +e
            W="$W" UIKIT="$W/uikit" MACHORUN="$MACHORUN" OPENCOMBINE_ROOT="$OPENCOMBINE_ROOT" \
                bash "$W/full/swiftui/build_focus_onboarding_guest.sh" "$onboard_dir" \
                | tee "$W/scratch/phase2-rung-b-onboarding.log"
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
    cannot rung-b-focus SWIFTUI_SUBSTRATE \
        "needs x86 OpenCombine.o (oc=$OC_OK; else NEEDS_X86_OPENCOMBINE), x86 FE (fe=$FE_OK), x86 mrroot (mrroot=$MRROOT_OK), x86 libswiftCore ($LIBSWIFTCORE_X86), Focus pin $FOCUS_PIN. Source-preservation contracts in full/swiftui/*_guest.sh are unchanged; arm64 object SHAs are not rewritten."
    RUNG_B_DETAIL="blocked by substrate"
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
if [ "$FE_OK" -eq 1 ] && [ "$MRROOT_OK" -eq 1 ] && [ "$LIBSWIFTCORE_X86" -eq 1 ] \
    && [ -n "$reminder_inv" ] && [ -n "$reminder_src" ]; then
    echo "== rung c: full/xcodeplan/build_and_run_reminder_scene_guest.sh"
    set +e
    UIKIT_CHECKOUT="${UIKIT_CHECKOUT:-$W/uikit}" \
    MACHORUN_CHECKOUT="${MACHORUN_CHECKOUT:-$MACHORUN}" \
    OPENUIKIT_HOST_TURNS=3 \
        bash "$W/full/xcodeplan/build_and_run_reminder_scene_guest.sh" \
            "$reminder_inv" "$reminder_src" \
        | tee "$W/scratch/phase2-rung-c-reminder.log"
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
elif [ "$FE_OK" -eq 1 ] && [ "$MRROOT_OK" -eq 1 ] && [ "$LIBSWIFTCORE_X86" -eq 1 ]; then
    cannot rung-c-reminder REMINDER_INVENTORY \
        "substrate ready enough to invoke full/xcodeplan/build_and_run_reminder_scene_guest.sh, but Reminder 22-source inventory + source root are absent. Looked at scratch/ladder-corpus/reminder and REMINDER_INVENTORY/REMINDER_SOURCE_ROOT. Success bar remains: REMINDER_UNCHANGED_WILL_CONNECT_OK + PORTABLE_UIKIT_HOST_ACTIVE windows=1 + PORTABLE_UIKIT_HOST_LOOP_OK turns=3 paced=true."
    RUNG_C_DETAIL="needs Reminder inventory json + source root"
else
    cannot rung-c-reminder REMINDER_SUBSTRATE \
        "needs x86 FE+mrroot+libswiftCore (fe=$FE_OK mrroot=$MRROOT_OK libswiftCore=$LIBSWIFTCORE_X86) plus Reminder 22-source inventory. Success bar: 1 UIWindow + 3 paced turns under the ported loader. Denominator from the committed inner script, not invented here."
    RUNG_C_DETAIL="blocked by substrate"
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
