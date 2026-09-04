#!/usr/bin/env bash
# One x86 cycle, in the right order, on the box.
#
#   bash scripts/ops/x86_cycle.sh [--dry-run] [tree]
#
# Replaces the operator files /tmp/x86_stage_inputs_phase2.sh and
# /tmp/x86_overlays_phase2.sh. phase2.sh stays the rung runner.
#
# Order is load-bearing. Overlay ninja before phase2 regenerated the darwin
# .tbds left a machorun surface change "undefined" for one more cycle
# (ssm_x86both, 2026-09-03). TBD first, then overlays, then roots, then rungs.
#
# Do not wrap children in an ERR trap that swallows their log: print the
# child's log path and tail it on failure.
set -eu
# No `pipefail` ERR trap. Child logs must stay on stderr/stdout.

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=common.inc
. "$HERE/common.inc"
ROOT=$(ops_root)
# shellcheck source=../x86/stamp.inc
. "$ROOT/scripts/x86/stamp.inc"

DRY=0
if [ "${1:-}" = "--dry-run" ]; then
    DRY=1
    shift
fi

TREE=${1:-}
if [ -z "$TREE" ]; then
    TREE=$(ops_contract_get "$ROOT/env/contract.json" hosts.ec2-x86_64.tree)
fi

BUNDLE_URI=${OPENUIKIT_BUNDLE_URI:-}
SHA=${OPENUIKIT_SHA:-}
STUB=${OPENUIKIT_CYCLE_STUB:-0}
S3_REGION=${OPENUIKIT_S3_REGION:-}

OVERLAY_CMD='NINJA_JOBS=16 SWIFTCORE_DARWIN_ARCH=x86_64 SWIFTCORE_OVERLAYS=1 SWIFTCORE_BUILD_DISPATCH=1 SWIFTCORE_FE_SYSROOT=$TREE/scratch/sysroot_fe4-x86_64 SWIFT_TOOLCHAIN=/opt/swift bash swiftcore-macho/scripts/build_stdlib.sh'

stage_names() {
    printf '%s\n' \
        fetch_bundle \
        checkout \
        prepare \
        tbd \
        sysroot \
        overlays \
        roots \
        phase2
}

if [ "$DRY" -eq 1 ]; then
    echo "x86_cycle dry-run tree=$TREE sha=${SHA:-HEAD} bundle=${BUNDLE_URI:-unset}"
    echo "order: fetch_bundle -> checkout -> prepare -> tbd -> sysroot -> overlays -> roots -> phase2"
    echo "overlays after tbd (ssm_x86both inverted this and left undefineds for one cycle)"
    echo "overlay: $OVERLAY_CMD"
    n=0
    while IFS= read -r name; do
        n=$((n + 1))
        printf 'STAGE %s status=planned key=dry-run product=%s sha256=dry-run\n' \
            "$name" "$TREE"
    done < <(stage_names)
    echo "RUNG_SCOREBOARD a=planned b=planned c=planned (positive boards quoted by phase2, not the negative control)"
    exit 0
fi

run_logged() {
    local name=$1 log=$2
    shift 2
    echo "== $name: $*" >&2
    # $? after `if cmd; then ...; fi` is the if's status (0), not cmd's:
    # every failed stage printed "failed rc=0" and was reported rebuilt
    # (measured 2026-09-03: sysroot, overlays and phase2 all "failed rc=0").
    # Do not capture rc=$? after the if; that reintroduces the mask.
    local rc=0
    "$@" >"$log" 2>&1 || rc=$?
    if [ "$rc" -eq 0 ]; then
        return 0
    fi
    echo "x86_cycle: $name failed rc=$rc log=$log (child log follows, not hidden by ERR trap)" >&2
    tail -n 80 "$log" >&2 || true
    return "$rc"
}

emit_stage() {
    local name=$1 status=$2 product=$3
    local key
    key=$(printf '%s\n' "$name" "$product" "${SHA:-}" | sha256sum | awk '{print $1}')
    stamp_stage_line "$name" "$status" "$key" "$product"
}

# Child logs print reused=1 / rebuilt reason= to stderr (captured in the log).
status_from_log() {
    local log=$1
    if [ -f "$log" ] && grep -q 'reused=1 stamp=' "$log" && ! grep -q 'rebuilt reason=' "$log"; then
        printf 'reused\n'
        return 0
    fi
    printf 'rebuilt\n'
}

if [ "$STUB" = 1 ]; then
    mkdir -p "$TREE" 2>/dev/null || TREE=$(mktemp -d /tmp/x86-cycle-stub.XXXXXX)
    while IFS= read -r name; do
        emit_stage "$name" reused "$TREE"
    done < <(stage_names)
    echo "RUNG_SCOREBOARD a=PASS/smoke 14/14 (stub)  b=PASS/widget+onboarding  c=PASS/windows=1 turns=3 paced=true"
    echo "GUEST SCOREBOARD port 579/579 (positive board; not the negative control)"
    exit 0
fi

cd "$TREE"
# A fresh Cursor VM is not the operator EC2 tree: export W / FULL_OUT_SUFFIX so
# stage_fe_sysroot.sh and phase2 helpers resolve suffixed x86 paths, and point
# SWIFT_TOOLCHAIN at the image's Swift (not a hardcoded /opt/swift).
export W=$TREE
# shellcheck disable=SC1091
. "$TREE/full/scripts/guest_arch.inc"
export CC="${CC:-clang-18}"
export DARWIN_CLANG="${DARWIN_CLANG:-clang-18}"
if [ -z "${SWIFT_TOOLCHAIN:-}" ]; then
    if [ -x /opt/swift/usr/bin/swiftc ]; then
        SWIFT_TOOLCHAIN=/opt/swift
    elif [ -x /opt/swift624/usr/bin/swiftc ]; then
        SWIFT_TOOLCHAIN=/opt/swift624
    else
        SWIFT_TOOLCHAIN=/usr
    fi
fi
export SWIFT_TOOLCHAIN

LOGDIR=${OPENUIKIT_CYCLE_LOGDIR:-$TREE/scratch/x86-cycle-logs}
mkdir -p "$LOGDIR"

# 1. fetch bundle. s3:// goes through aws (the operator prefix in
# env/contract.json); http(s) is the urllib fallback. urllib cannot speak S3.
if [ -z "$S3_REGION" ]; then
    S3_REGION=$(ops_contract_get "$ROOT/env/contract.json" transfer.s3_region)
fi
if [ -n "$BUNDLE_URI" ]; then
    bundle=$LOGDIR/openuikit.bundle
    fetch_rc=0
    case "$BUNDLE_URI" in
        s3://*)
            run_logged fetch_bundle "$LOGDIR/fetch.log" \
                ops_aws s3 cp "$BUNDLE_URI" "$bundle" --region "$S3_REGION" \
                || fetch_rc=$?
            ;;
        *)
            run_logged fetch_bundle "$LOGDIR/fetch.log" \
                python3 -c 'import sys,urllib.request; urllib.request.urlretrieve(sys.argv[1], sys.argv[2])' \
                    "$BUNDLE_URI" "$bundle" \
                || fetch_rc=$?
            ;;
    esac
    if [ "$fetch_rc" -eq 0 ]; then
        emit_stage fetch_bundle rebuilt "$bundle"
    else
        emit_stage fetch_bundle cannot "$bundle"
        exit 2
    fi
else
    emit_stage fetch_bundle reused "$TREE/.git"
fi

# 2. checkout
if [ -n "$SHA" ]; then
    if [ -n "${bundle:-}" ] && [ -f "${bundle:-}" ]; then
        git bundle verify "$bundle" >/dev/null
        # run_box.sh pins the sha at refs/ops/bundle (git bundle needs a ref);
        # fetch that ref and insist it is the sha the operator named.
        git fetch "$bundle" refs/ops/bundle
        [ "$(git rev-parse FETCH_HEAD)" = "$SHA" ] || {
            echo "x86_cycle: bundle ref is $(git rev-parse FETCH_HEAD), expected $SHA" >&2
            exit 2
        }
    fi
    if git checkout --force "$SHA"; then
        emit_stage checkout rebuilt "$TREE"
    else
        emit_stage checkout cannot "$TREE"
        exit 2
    fi
else
    emit_stage checkout reused "$TREE"
fi

# 3. prepare.py (loader/darwin/tbd through stamps). On x86_64 a missing
# loader is CANNOT (the operator EC2 already has one). A fresh VM then
# cold-builds via ensure_machorun.sh and parks leftover arm64 dylibs
# before tbd. STAGE prepare names the loader that actually exists.
if ! run_logged prepare "$LOGDIR/prepare.log" python3 "$TREE/scripts/env/prepare.py"; then
    emit_stage prepare cannot "$TREE/machorun/build/machorun"
    exit 2
fi
if ! run_logged ensure_machorun "$LOGDIR/ensure_machorun.log" \
    bash "$TREE/scripts/x86/ensure_machorun.sh" "$TREE"; then
    echo "x86_cycle: ensure_machorun failed (loader/darwin/objc4/quartz or arm64 park)" >&2
    emit_stage prepare cannot "$TREE/machorun/build/machorun"
    exit 2
fi
emit_stage prepare "$(status_from_log "$LOGDIR/ensure_machorun.log")" \
    "$TREE/machorun/build/machorun"

# 4. build.sh tbd must be clean (after darwin, before overlays)
if run_logged tbd "$LOGDIR/tbd.log" sh "$TREE/machorun/scripts/build.sh" tbd; then
    emit_stage tbd "$(status_from_log "$LOGDIR/tbd.log")" "$TREE/machorun/sdk/usr/lib/libSystem.tbd"
else
    emit_stage tbd cannot "$TREE/machorun/sdk/usr/lib/libSystem.tbd"
    exit 2
fi

# 4b. the regenerated machorun tbds must reach the x86 sysroot before the
# overlay links read it. Measured 2026-09-03 (cycle at 5807d94a): machorun/sdk
# libSystem.B.tbd regenerated 15:17 with __dispatch_main_q, but
# scratch/sysroot_fe4-x86_64 kept the 14:54 copy (stage_fe_sysroot reuses its
# own product) and every Concurrency/Observation link still said undefined.
# The arm64 driver does the same copy by hand after build_full.
tbd_synced=0
for t in "$TREE"/machorun/sdk/usr/lib/*.tbd; do
    [ -f "$t" ] || continue
    dst="$TREE/scratch/sysroot_fe4-x86_64/usr/lib/$(basename "$t")"
    if [ -f "$dst" ] && [ "$(sha256sum "$t" | cut -c1-64)" = "$(sha256sum "$dst" | cut -c1-64)" ]; then
        continue
    fi
    mkdir -p "$(dirname "$dst")" && cp -f "$t" "$dst" && tbd_synced=$((tbd_synced + 1))
done
if [ "$tbd_synced" -gt 0 ]; then
    emit_stage tbd-sysroot rebuilt "$TREE/scratch/sysroot_fe4-x86_64/usr/lib (synced $tbd_synced tbd)"
else
    emit_stage tbd-sysroot reused "$TREE/scratch/sysroot_fe4-x86_64/usr/lib"
fi

# 5. stage sysroot
if run_logged sysroot "$LOGDIR/sysroot.log" \
    env W="$TREE" bash "$TREE/scripts/x86/stage_fe_sysroot.sh"; then
    emit_stage sysroot "$(status_from_log "$LOGDIR/sysroot.log")" "$TREE/scratch/sysroot_fe4-x86_64"
else
    emit_stage sysroot cannot "$TREE/scratch/sysroot_fe4-x86_64"
    exit 2
fi

# 6. overlays AFTER tbd. PR #64 argv. Child log is tailed on failure.
# OPENUIKIT_CYCLE_SKIP_OVERLAYS=1 (run_box.sh --only) reuses the artifacts as
# they are -- reported as a reused stage, never as rebuilt.
# shellcheck disable=SC2086
if [ "${OPENUIKIT_CYCLE_SKIP_OVERLAYS:-0}" = 1 ]; then
    emit_stage overlays reused "$TREE/swiftcore-macho/artifacts/swift-macosx/x86_64 (skipped by request)"
elif run_logged overlays "$LOGDIR/overlays.log" \
    env NINJA_JOBS=16 SWIFTCORE_DARWIN_ARCH=x86_64 SWIFTCORE_OVERLAYS=1 \
        SWIFTCORE_BUILD_DISPATCH=1 SWIFT_TOOLCHAIN="$SWIFT_TOOLCHAIN" \
        SWIFTCORE_FE_SYSROOT="$TREE/scratch/sysroot_fe4-x86_64" \
        bash "$TREE/swiftcore-macho/scripts/build_stdlib.sh"; then
    emit_stage overlays "$(status_from_log "$LOGDIR/overlays.log")" "$TREE/swiftcore-macho/artifacts/swift-macosx/x86_64"
else
    emit_stage overlays cannot "$TREE/swiftcore-macho/artifacts/swift-macosx/x86_64"
    exit 2
fi

# 7. stage roots. Operator box lets phase2 do this; SKIP_PHASE2 callers
# (tests, box -o) still need the trees. Cursor install no longer skips phase2.
# Mirror phase2's helpers (base + host + layout + build_full umbrellas).
if run_logged roots "$LOGDIR/roots.log" \
    bash "$TREE/scripts/x86/stage_cycle_roots.sh" "$TREE"; then
    emit_stage roots "$(status_from_log "$LOGDIR/roots.log")" "$TREE/scratch/mrroot-x86_64"
else
    emit_stage roots cannot "$TREE/scratch/mrroot-x86_64"
    exit 2
fi

# 7b. inputs phase2 needs that the proven operator driver staged by hand
# (measured 2026-09-03, first committed cycle: rung b CANNOT_FOCUS_BUNDLE, rung c
# build_full REFUSING -- machorun/darwin/usr/lib/swift/libswiftCore.dylib
# missing after the stamped darwin rebuild).
#  - the current x86 libswiftCore into machorun's darwin tree (build_full and
#    the Reminder script stage "from the current machorun runtime");
#  - the normalized Focus bundles staged on the box (arch-independent
#    resources proven on the arm64 authority; the committed Linux/x86_64
#    resource proof refuses for want of a reviewed rasterizer profile).
core_src=$TREE/swiftcore-macho/artifacts/swift-macosx/x86_64/libswiftCore.dylib
core_dst=$TREE/machorun/darwin/usr/lib/swift/libswiftCore.dylib
if [ -f "$core_src" ]; then
    mkdir -p "$(dirname "$core_dst")"
    # A symlink here (verify_hello.sh left one into /root/work/build at the
    # 44152400 cycle) reads as the same bytes but stage_swift_core_runtime.py
    # refuses "not a regular non-symlink file"; only a regular file is reuse.
    if [ -f "$core_dst" ] && [ ! -L "$core_dst" ] && [ "$(sha256sum "$core_src" | cut -c1-64)" = "$(sha256sum "$core_dst" | cut -c1-64)" ]; then
        emit_stage libswiftcore-darwin reused "$core_dst"
    else
        rm -f "$core_dst"
        cp -f "$core_src" "$core_dst"
        emit_stage libswiftcore-darwin rebuilt "$core_dst"
    fi
else
    emit_stage libswiftcore-darwin cannot "$core_src"
    exit 2
fi
FB=$(ls -d /tmp/focus-resources-x86-staged.* 2>/dev/null | head -1)
if [ -n "$FB" ] && [ -d "$FB/bundles/Focus_Widget.bundle" ]; then
    export FOCUS_WIDGET_BUNDLE="$FB/bundles/Focus_Widget.bundle"
    # The onboarding gate takes the normalized-bundles DIRECTORY (phase2 asks
    # for FOCUS_ONBOARDING_BUNDLES once the widget guest has passed).
    export FOCUS_ONBOARDING_BUNDLES="$FB/bundles"
    emit_stage focus-bundle reused "$FOCUS_WIDGET_BUNDLE (+onboarding bundles dir $FOCUS_ONBOARDING_BUNDLES)"
else
    emit_stage focus-bundle cannot "/tmp/focus-resources-x86-staged.*/bundles/Focus_Widget.bundle"
fi

# 8. phase2 rungs. Quote POSITIVE boards (phase2 already does; do not tail -1
# the persist log past NEGATIVE CONTROL).
# OPENUIKIT_CYCLE_SKIP_PHASE2=1: substrate only (tests / run_box.sh -o).
# Cursor install does not set this; it exports PHASE2_RUNGS=a so rung a is
# snapshotted. Same skip contract as OPENUIKIT_CYCLE_SKIP_OVERLAYS.
if [ "${OPENUIKIT_CYCLE_SKIP_PHASE2:-0}" = 1 ]; then
    emit_stage phase2 reused "$TREE (skipped by OPENUIKIT_CYCLE_SKIP_PHASE2=1)"
elif run_logged phase2 "$LOGDIR/phase2.log" \
    bash "$TREE/scripts/x86/phase2.sh" "$TREE"; then
    emit_stage phase2 "$(status_from_log "$LOGDIR/phase2.log")" "$TREE"
    grep -E 'RUNG_SCOREBOARD|GUEST SCOREBOARD|ENV_PREPARE_SUMMARY|CANNOT_' \
        "$LOGDIR/phase2.log" || true
else
    emit_stage phase2 cannot "$TREE"
    grep -E 'RUNG_SCOREBOARD|GUEST SCOREBOARD|CANNOT_' "$LOGDIR/phase2.log" || true
    exit 2
fi
exit 0
