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
OUT=$ROOT/build/full/$SUITE

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

scenes=("$UIKIT"/fixtures/scenes/*.json)
echo "run_suite: ${#scenes[@]} scenes -> $OUT"

pass=0; crash=0
for s in "${scenes[@]}"; do
    name=$(basename "$s" .json)
    out=$(docker run --rm "${STACKOPT[@]}" \
        -v "$ROOT:/w" -v "$UIKIT:/uikit:ro" -w /w/build/full \
        -e MACHORUN_ROOT=/w/scratch/mrroot_full \
        -e OPENUIKIT_RESOURCE_ROOT=/uikit/Sources/OpenUIKit/Resources \
        -e OPENUIKIT_FONT_DIR=/w/scratch/fonts \
        -e OPENUIKIT_BACKEND="${OPENUIKIT_BACKEND:-quartz}" \
        swift-macho-spike:noble \
        /w/scratch/mrroot_full/machorun ./render_full "/w/build/full/$SUITE" "/uikit/fixtures/scenes/$name.json" 2>&1)
    st=$?
    if [ $st -eq 0 ]; then
        pass=$((pass+1)); printf '%-34s ok\n' "$name"
    else
        crash=$((crash+1)); printf '%-34s EXIT=%d\n' "$name" "$st"
        { echo "########## $name (exit $st)"; echo "$out"; } >>"$LOG"
    fi
done
echo
echo "run_suite: rendered_ok=$pass  failed=$crash  (failures logged to $LOG)"
