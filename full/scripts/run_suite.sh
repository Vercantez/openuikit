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
# MRROOT lets a run use an alternative guest root -- e.g. one with a different
# Swift runtime. The runtime turned out to be the discriminator for most of the
# failures, so comparing roots is a first-class operation, not a hack.
MRROOT_WAS_SET=${MRROOT+yes}
MRROOT=${MRROOT:-/w/scratch/mrroot_full}
MRMOUNT=${MRMOUNT:-}
OUT=$ROOT/build/full/$SUITE

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

scenes=("$UIKIT"/fixtures/scenes/*.json)
echo "run_suite: ${#scenes[@]} scenes -> $OUT (timeout ${SCENE_TIMEOUT}s/scene)"

pass=0; crash=0; hung=0
for s in "${scenes[@]}"; do
    name=$(basename "$s" .json)
    # Named, so a timed-out container can be reaped by EXACT name. Killing the
    # docker CLI does not stop the container it started.
    cname="mrsuite_${SUITE}_${name}"
    out=$(timeout --signal=KILL "$SCENE_TIMEOUT" docker run --rm --name "$cname" "${STACKOPT[@]}" \
        -v "$ROOT:/w" -v "$UIKIT:/uikit:ro" -w /w/build/full \
        ${MRMOUNT:+-v "$MRMOUNT"} \
        -e MACHORUN_ROOT="$MRROOT" \
        -e OPENUIKIT_RESOURCE_ROOT=/uikit/Sources/OpenUIKit/Resources \
        -e OPENUIKIT_FONT_DIR=/w/scratch/fonts \
        -e OPENUIKIT_BACKEND="${OPENUIKIT_BACKEND:-quartz}" \
        swift-macho-spike:noble \
        "$MRROOT/machorun" ./render_full "/w/build/full/$SUITE" "/uikit/fixtures/scenes/$name.json" 2>&1)
    st=$?
    if [ $st -eq 0 ]; then
        pass=$((pass+1)); printf '%-34s ok\n' "$name"
    elif [ $st -eq 137 ]; then
        docker rm -f "$cname" >/dev/null 2>&1 || true
        # 137 = timeout(1) SIGKILLed it. Reported as HANG rather than folded in
        # with the crashes: a spin and a bad dereference need different hunting.
        hung=$((hung+1)); printf '%-34s HANG\n' "$name"
        { echo "########## $name (HANG, killed after ${SCENE_TIMEOUT}s)"; echo "$out"; } >>"$LOG"
    else
        crash=$((crash+1)); printf '%-34s EXIT=%d\n' "$name" "$st"
        { echo "########## $name (exit $st)"; echo "$out"; } >>"$LOG"
    fi
done
echo
echo "run_suite: rendered_ok=$pass  crashed=$crash  hung=$hung  (failures logged to $LOG)"
