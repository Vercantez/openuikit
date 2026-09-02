#!/bin/bash
# run_suite.sh -- render every scene in ~/uikit/fixtures/scenes under machorun
# and score the result against ~/uikit/golden.
#
# ONE SCENE PER PROCESS, deliberately. A scene that crashes the guest takes the
# process with it; batching would lose every scene after the first crash and
# make the failure unattributable. 108 process launches is cheap next to that.
#
# Fonts: Apple's SFNS*.ttf are not redistributable, so they are copied from the
# host macOS at run time into scratch/fonts, exactly as ~/uikit's own
# scripts/linux_verify.sh does. Without them, glyphs absent from the harvested
# ink table do not draw at all and every text scene fails for a reason that has
# nothing to do with machorun.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
UIKIT=${UIKIT:-$HOME/uikit}
SUITE=${SUITE:-suite}
CONTAINER_IMAGE=${CONTAINER_IMAGE:-swift-macho-spike:noble}
# MRROOT lets a run use an alternative guest root -- e.g. one with a different
# Swift runtime. The runtime turned out to be the discriminator for most of the
# failures, so comparing roots is a first-class operation, not a hack.
MRROOT_WAS_SET=${MRROOT+yes}
MRROOT=${MRROOT:-/w/scratch/mrroot_full}
MRMOUNT=${MRMOUNT:-}
OUT=$ROOT/build/full/$SUITE

if [ "$(uname -m)" != aarch64 ] && [ "$(uname -m)" != arm64 ]; then
    bash "$ROOT/.cursor/refuse-arm64-execution.sh" || exit $?
fi

# Freshness is asserted ONLY for the default root. scratch/mrroot_full is a COPY
# of machorun's userland, and a copy read long after it was made is
# indistinguishable from a fresh one -- an enumeration on 2026-08-27 found four
# such roots still carrying a malloc_type bug that had been fixed upstream weeks
# earlier, in trees guests were actually executed against.
#
# But an EXPLICIT MRROOT is the entire point of the knob three comments up:
# comparing an alternative runtime is a first-class operation here, and half the
# reason to point at another root is that it is deliberately NOT current.
# Refusing that would break the feature in the name of protecting it.
if [ -z "${MRROOT_WAS_SET:-}" ]; then
    "$ROOT/scripts/require_fresh_root.sh" scratch/mrroot_full || exit 1
fi

# LOW_HEAP=1 runs every scene with RLIMIT_STACK unlimited, which flips Linux to
# the LEGACY bottom-up mmap layout process-wide: the PIE, and therefore brk and
# the whole C heap, land near 0x5555... instead of 0xaaaa..., i.e. BELOW 2^47.
#
# This is a MEASUREMENT, not a fix -- machorun's own commit rejects the same
# trick as a fix for image placement, for good reasons that apply here too (it
# is a property of how the process was invoked, it lapses across a re-exec, and
# it moves every unrelated allocation). It is used here only to answer one
# question: are the suite's remaining failures all the same heap-placement bug?
STACKOPT=()
[ "${LOW_HEAP:-0}" = 1 ] && STACKOPT=(--ulimit stack=-1)
# `${STACKOPT[@]+"${STACKOPT[@]}"}` at the use site below, not a bare
# `"${STACKOPT[@]}"`. Under `set -u` bash 3.2 -- which IS /bin/bash on macOS --
# treats an EMPTY array's expansion as an unbound variable and dies with exit
# 127 before the first scene. This script only ever ran because it was invoked
# as `bash run_suite.sh` with Homebrew's bash 5 first on PATH; `./run_suite.sh`
# honoured the shebang and never worked. Fixing the expansion rather than
# pinning the shebang keeps it running on a stock macOS too.
FONTS=$ROOT/scratch/fonts
LOG=$ROOT/build/full/$SUITE.log

mkdir -p "$OUT" "$FONTS"
rm -f "$LOG"

if [ "$(uname -s)" = Darwin ]; then
    for f in SFNS.ttf SFNSMono.ttf SFNSItalic.ttf; do
        [ -f "/System/Library/Fonts/$f" ] && cp -f "/System/Library/Fonts/$f" "$FONTS/$f"
    done
fi
[ -f "$FONTS/SFNS.ttf" ] || echo "run_suite: WARNING no SFNS.ttf in $FONTS -- text scenes will not draw glyphs" >&2

# PER-SCENE TIMEOUT. A crash is not the only failure mode: constraints_hugging
# was measured spinning for 22 minutes with no output, and the same scene
# CRASHED on the previous run -- so the corruption can produce an infinite loop
# as readily as a bad pointer. Without a timeout one such scene stalls the whole
# suite and the run silently never finishes. 120s is ~40x the slowest scene that
# completes (animation captures, ~3s).
SCENE_TIMEOUT=${SCENE_TIMEOUT:-120}

# ------------------------------------------- the stability bracket
#
# THIS RUN TAKES MINUTES AND ITS SUBJECT IS SHARED. build/full/render_full and
# scratch/mrroot_full are rebuilt by full/scripts/build_full.sh, and
# scratch/mrroot_full/darwin/usr/lib is restaged from ~/machorun -- both by other
# people and other agents, while this loop is running. A root swapped at scene 50
# gives a 108-line scoreboard in which half the scenes ran against one substrate
# and half against another, and NOTHING IN THE OUTPUT LOOKS DIFFERENT. That is
# not hypothetical here: the record already contains a plausible 64 ok / 43
# crashed taken against half a root.
#
# The standing 108/108 result had to be bracketed BY HAND for exactly this
# reason. Same mechanism as machorun's difftest/objc44/quartz_pixel: a short
# digest over every artefact the run depends on, taken before the first scene and
# after the last, printed beside the verdict so two numbers have to agree.
suite_fingerprint() {
    { echo "$ROOT/build/full/render_full"
      find "$MRROOT_HOST/darwin/usr/lib" -name '*.dylib' -type f 2>/dev/null | LC_ALL=C sort
      find "$MRROOT_HOST/host" -name '*.so' -type f 2>/dev/null | LC_ALL=C sort
      echo "$MRROOT_HOST/machorun"
    } | while IFS= read -r f; do
        [ -f "$f" ] && shasum -a 256 <"$f" | cut -d' ' -f1
    done | shasum -a 256 | cut -c1-12
}
# MRROOT is a path INSIDE the container (/w/...). Map it back to this host so the
# bracket can read the same files the guests will load.
MRROOT_HOST=${MRROOT/#\/w/$ROOT}
HOSTOPT=()
if [ -f "$MRROOT_HOST/host/libOpenDispatchHost.so" ]; then
    HOST_PRELOAD="$MRROOT/host/libOpenDispatchHost.so:$MRROOT/host/libOpenFoundationInternationalizationHost.so:$MRROOT/host/libOpenURLTransportHost.so:$MRROOT/host/libOpenRelativeTimeHost.so"
    for helper in libdispatch.so libBlocksRuntime.so libOpenDispatchHost.so \
                  libOpenFoundationInternationalizationHost.so \
                  libOpenURLTransportHost.so libOpenRelativeTimeHost.so; do
        [ -f "$MRROOT_HOST/host/$helper" ] || {
            echo "run_suite: incomplete staged host runtime: $helper" >&2
            exit 2
        }
    done
    HOSTOPT=(-e "LD_LIBRARY_PATH=$MRROOT/host" -e "LD_PRELOAD=$HOST_PRELOAD")
fi
FP_BEFORE=$(suite_fingerprint)
[ "$FP_BEFORE" != "$(printf '' | shasum -a 256 | cut -c1-12)" ] || {
    echo "run_suite: REFUSING -- fingerprinted nothing under $MRROOT_HOST; is the root populated?" >&2; exit 2; }

scenes=("$UIKIT"/fixtures/scenes/*.json)
echo "run_suite: ${#scenes[@]} scenes -> $OUT (timeout ${SCENE_TIMEOUT}s/scene)"
echo "run_suite: subject $FP_BEFORE -- per-scene results stream to $LOG.progress;"
echo "           the TABLE is printed only if the subject holds still."

# Rows are BUFFERED, not streamed to stdout. If the subject moves the run is
# void and there is no table worth showing -- printing it with a warning above
# leaves 108 lines on screen that someone will quote. Progress still goes to a
# file so a long run can be watched.
PROGRESS=$LOG.progress
: >"$PROGRESS"
rows=""
pass=0; crash=0; hung=0
for s in "${scenes[@]}"; do
    name=$(basename "$s" .json)
    # Named, so a timed-out container can be reaped by EXACT name. Killing the
    # docker CLI does not stop the container it started.
    cname="mrsuite_${SUITE}_${name}"
    out=$(timeout --signal=KILL "$SCENE_TIMEOUT" docker run --rm --name "$cname" ${STACKOPT[@]+"${STACKOPT[@]}"} \
        -v "$ROOT:/w" -v "$UIKIT:/uikit:ro" -w /w/build/full \
        ${MRMOUNT:+-v "$MRMOUNT"} \
        -e MACHORUN_ROOT="$MRROOT" \
        -e OPENUIKIT_RESOURCE_ROOT=/uikit/Sources/OpenUIKit/Resources \
        -e OPENUIKIT_FONT_DIR=/w/scratch/fonts \
        -e OPENUIKIT_BACKEND="${OPENUIKIT_BACKEND:-quartz}" \
        ${HOSTOPT[@]+"${HOSTOPT[@]}"} \
        "$CONTAINER_IMAGE" \
        "$MRROOT/machorun" ./render_full "/w/build/full/$SUITE" "/uikit/fixtures/scenes/$name.json" 2>&1)
    st=$?
    if [ $st -eq 0 ]; then
        pass=$((pass+1)); row=$(printf '%-34s ok' "$name")
    elif [ $st -eq 137 ]; then
        docker rm -f "$cname" >/dev/null 2>&1 || true
        # 137 = timeout(1) SIGKILLed it. Reported as HANG rather than folded in
        # with the crashes: a spin and a bad dereference need different hunting.
        hung=$((hung+1)); row=$(printf '%-34s HANG' "$name")
        { echo "########## $name (HANG, killed after ${SCENE_TIMEOUT}s)"; echo "$out"; } >>"$LOG"
    else
        crash=$((crash+1)); row=$(printf '%-34s EXIT=%d' "$name" "$st")
        { echo "########## $name (exit $st)"; echo "$out"; } >>"$LOG"
    fi
    rows="$rows$row
"
    printf '%s\n' "$row" >>"$PROGRESS"
done

# ------------------------------------------- did the subject hold still?
# BEFORE the table, and instead of it. See the bracket comment above.
FP_AFTER=$(suite_fingerprint)
if [ "$FP_BEFORE" != "$FP_AFTER" ]; then
    {
        echo
        echo "RUN VOID: render_full or the guest root changed while the suite was running."
        echo "  before: $FP_BEFORE"
        echo "  after:  $FP_AFTER"
        echo "  Subject: build/full/render_full + $MRROOT_HOST/{machorun,darwin/usr/lib/*.dylib}."
        echo "  ${#scenes[@]} scenes were rendered against no single substrate, so there is no"
        echo "  scoreboard to print -- the per-scene lines are in $PROGRESS if you"
        echo "  want to see WHERE it changed. Re-run; if another agent is rebuilding,"
        echo "  let its staging land between suite runs rather than during one."
    } >&2
    exit 2
fi

printf '%s' "$rows"
echo
echo "run_suite: rendered_ok=$pass  crashed=$crash  hung=$hung  (failures logged to $LOG)"
echo "run_suite: subject $FP_BEFORE, unchanged across the run (${#scenes[@]} scenes)"
