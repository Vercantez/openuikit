#!/bin/bash
# quartz_pixel.sh -- the differential for the DRAWING fixtures.
#
#   scripts/quartz_pixel.sh                run BOTH sides and compare (macOS host)
#   scripts/quartz_pixel.sh objc_shapes just that one
#   scripts/quartz_pixel.sh --record       re-record the macOS baselines, run nothing else
#   scripts/quartz_pixel.sh --linux        Linux side only, compare against the baselines
#
# The fixtures it grades are listed in tests/draw_manifest.tsv -- read that file
# first; its header says why they are not in tests/manifest.tsv and why they
# need a runner of their own.
#
# Same discipline as scripts/difftest.sh, one rung further: the artefact under
# comparison is a PNG, not stdout. Method, unchanged:
#
#   * The macOS side EXECUTES tests/bin/<id> natively, every run. The committed
#     baseline is not trusted as a substitute for running it -- if macOS's own
#     output has moved, that is a fact worth learning before grading Linux
#     against it, and it is reported as BASELINE-DRIFT.
#   * The Linux side runs THE SAME BYTES under build/machorun in the test-bed
#     container.
#   * A mismatch is reported, never recorded. tests/expected/ is written ONLY
#     by --record, only on macOS. The container gets tests/expected bind-mounted
#     READ-ONLY on top of the writable /work mount, so that rule is enforced by
#     the kernel and not by good intentions -- the same guarantee
#     harness/run_linux.sh already gives.
#
# WHAT A PASS MEANS, precisely. The same precompiled arm64 Mach-O, built by
# Apple's clang against Apple's SDK, produced the same PNG when run by macOS's
# own dyld against an Apple-clang libquartz (and, for rungs o and p, Apple's own
# shipping libobjc), and when run by machorun on Linux/arm64 against a libquartz
# built by clang-18 for Mach-O against sdk/ and our Mach-O build of Apple's
# objc4. Per-stage checksums on stdout localise any difference to the drawing
# stage that first diverged; on a PNG mismatch, harness/pngdiff.c then localises
# it to a rectangle of pixels. See the header of each tests/src/<id>.{c,m} for
# what its stages are for and which one is the transcendental (libm) canary.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/harness/common.sh"

DRAW_MANIFEST="$ROOT/tests/draw_manifest.tsv"
EXP="$ROOT/tests/expected"
ACT="$ROOT/tests/actual/quartz"
QZ_MACOS="${QUARTZ_MACOS_OUT:-$ROOT/build/quartz-macos}"
IMAGE="${MACHORUN_IMAGE:-machorun-testbed:24.04}"
PNGDIFF="$ROOT/build/tools/pngdiff"

MODE=both
SELECT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --record)  MODE=record ;;
        --linux)   MODE=linux ;;
        -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
        --)        ;;
        -*)        die "unknown option $1" ;;
        *)         SELECT="$SELECT $1" ;;
    esac
    shift
done

[ -f "$DRAW_MANIFEST" ] || die "missing $DRAW_MANIFEST"

# ---------------------------------------------------------------- manifest
draw_rows() {
    grep -v '^[[:space:]]*#' "$DRAW_MANIFEST" | grep -v '^[[:space:]]*$'
}

selected() { # selected <id>
    [ -z "$SELECT" ] && return 0
    local w
    for w in $SELECT; do [ "$w" = "$1" ] && return 0; done
    return 1
}

IDS=""
NEEDS=""
while IFS= read -r row; do
    id="$(field "$row" 1)"
    selected "$id" || continue
    [ -f "$ROOT/tests/bin/$id" ] || \
        die "no tests/bin/$id -- build it on macOS: tests/build_fixtures.sh $id"
    IDS="$IDS $id"
    NEEDS="$NEEDS,$(field "$row" 2)"
done <<EOF
$(draw_rows)
EOF
[ -n "$IDS" ] || die "no drawing fixtures selected (asked for:${SELECT:- everything})"

# The Linux side builds only what the selected fixtures actually load. objc4 is
# 32 Objective-C++ translation units; a quartz-only run must not pay for it.
case "$NEEDS" in *objc*) WANT_OBJC=1 ;; *) WANT_OBJC=0 ;; esac

mkdir -p "$ACT"
rc_overall=0

# --------------------------------------------------------------- macOS side
# Both sides write <id>.png in their OWN directory. Same leaf name on purpose:
# each fixture echoes the path it wrote, so a different name would show up as a
# stdout difference on every single run and train the reader to ignore the one
# signal that localises a real divergence.
run_macos() { # run_macos <outdir>
    local out="$1" id
    [ "$(uname -s)" = "Darwin" ] || die "the oracle side only runs on macOS"
    mkdir -p "$out"
    # Rebuild the oracle library from vendor/quartz every time. It is a build
    # product, deliberately not committed: committing it would let the oracle
    # drift from the sources the Linux side compiles.
    bash "$ROOT/scripts/build_quartz_macos.sh" > "$out/.build.log" 2>&1 \
        || { sed -n '1,20p' "$out/.build.log" >&2; die "macOS libquartz build failed"; }

    for id in $IDS; do
        rm -f "$out/$id.png"
        ( cd "$out" && LC_ALL=C LANG=C TZ=UTC \
            DYLD_LIBRARY_PATH="$QZ_MACOS" "$ROOT/tests/bin/$id" "$id.png" ) \
            > "$out/$id.stdout" 2> "$out/$id.stderr"
        echo $? > "$out/$id.exit"
    done
}

# --------------------------------------------------------------- Linux side
run_linux() {
    if [ "$(uname -m)" != aarch64 ] && [ "$(uname -m)" != arm64 ]; then
        bash "$(git -C "$ROOT" rev-parse --show-toplevel)/.cursor/refuse-arm64-execution.sh" \
            || exit $?
    fi
    command -v docker >/dev/null 2>&1 || die "docker not installed on this host"
    docker info >/dev/null 2>&1        || die "docker daemon not reachable"
    docker image inspect "$IMAGE" >/dev/null 2>&1 || \
        die "no test-bed image $IMAGE -- harness/run_linux.sh --build-image"

    # Exact, unique container name. Never rm by filter: this host runs
    # unrelated containers.
    local cname="machorun-quartz-$$"
    mkdir -p "$ACT/linux"
    local id
    for id in $IDS; do rm -f "$ACT/linux/$id.png"; done

    # tests/expected is mounted READ-ONLY on top of the writable /work mount.
    # Docker applies bind mounts in destination-path order, so the deeper,
    # read-only one wins for that subtree. This is the same kernel-enforced
    # guarantee harness/run_linux.sh gives, and it is what makes "the Linux
    # side cannot rewrite a baseline" a fact rather than a policy.
    # A fingerprint from the previous run would be read as this one's if the
    # container dies before writing its own. Same hazard as run_linux.sh.
    rm -f "$ACT/.fingerprint"
    docker run --rm -i --name "$cname" --platform linux/arm64 \
        -e "MR_IDS=$IDS" -e "MR_OBJC=$WANT_OBJC" \
        -v "$ROOT:/work" -v "$ROOT/tests/expected:/work/tests/expected:ro" \
        -w /work "$IMAGE" bash -s > "$ACT/.linux.log" 2>&1 <<'INNER'
set -e
cd /work
L=/work/tests/actual/quartz
mkdir -p "$L/linux"
sh scripts/build.sh loader        > "$L/.loader.log" 2>&1
sh scripts/build_darwin.sh        > "$L/.darwin.log" 2>&1
if [ "$MR_OBJC" = 1 ]; then
    bash scripts/build_objc4.sh   > "$L/.objc4.log" 2>&1
fi
bash scripts/build_quartz.sh      > "$L/.quartz.log" 2>&1
# THE BRACKET STARTS HERE, AFTER THE BUILD. Placing it at the top of the script
# was tried and is wrong: this gate builds the loader itself, so the artefacts
# change on every ordinary run and the check fired every time. A gate that cries
# wolf is a gate people stop reading -- caught by running it, not by review.
. /work/harness/common.sh
FP_BEFORE="$(gate_fingerprint)"
cd "$L/linux"
export LC_ALL=C LANG=C TZ=UTC
for id in $MR_IDS; do
    rc=0
    /work/build/machorun "/work/tests/bin/$id" "$id.png" \
        > "$id.stdout" 2> "$id.stderr" || rc=$?
    echo $rc > "$id.exit"
done
printf '%s\t%s\n' "$FP_BEFORE" "$(gate_fingerprint)" > "$L/.fingerprint"
INNER
    local drc=$?
    if [ $drc -ne 0 ]; then
        echo "${C_RED}the container run failed:${C_RESET}" >&2
        tail -30 "$ACT/.linux.log" >&2
        for l in .objc4.log .quartz.log; do
            [ -s "$ACT/$l" ] && { echo "--- $l"; tail -20 "$ACT/$l"; } >&2
        done
        return 1
    fi
    return 0
}

# --------------------------------------------------------------- the report
# Built on demand and only when a PNG mismatch has to be explained. Failing to
# build the reporter is a warning: it must never turn a diagnosable failure
# into an undiagnosable one, and it must never turn a PASS into anything.
ensure_pngdiff() {
    [ -x "$PNGDIFF" ] && return 0
    mkdir -p "$(dirname "$PNGDIFF")"
    ${CC:-cc} -O1 -o "$PNGDIFF" "$ROOT/harness/pngdiff.c" \
        -I "$ROOT/vendor/quartz/third_party" -lm > "$ACT/.pngdiff.log" 2>&1 && return 0
    printf '      %s(could not build harness/pngdiff.c -- see %s)%s\n' \
        "$C_YEL" "$ACT/.pngdiff.log" "$C_RESET"
    return 1
}

# bytes_of <path> -- size, or "-" if it is not there. `wc -c < missing` fails in
# the SHELL, before wc runs, so a 2>/dev/null on wc does not suppress it: the run
# that most needs a clean report (no PNG was produced) was the one that got a
# bash error interleaved into the table.
bytes_of() { [ -f "$1" ] && wc -c < "$1" | tr -d ' ' || printf '%s' '-'; }

show_stdout_diff() { # show_stdout_diff <ref-prefix> <act-prefix>
    if cmp -s "$1.stdout" "$2.stdout"; then
        printf '    %-20s %sidentical%s\n' "stage checksums" "$C_GRN" "$C_RESET"
        return 0
    fi
    printf '    %-20s %sDIFFER%s -- first divergent line:\n' "stage checksums" "$C_RED" "$C_RESET"
    diff "$1.stdout" "$2.stdout" | sed -n '1,12p' | sed 's/^/        /'
    return 1
}

# --------------------------------------------------------------------- run
case "$MODE" in
record)
    [ "$(uname -s)" = "Darwin" ] || die "--record only runs on macOS: the baseline is the oracle's"
    mkdir -p "$EXP"
    run_macos "$ACT/macos"
    for id in $IDS; do
        cp "$ACT/macos/$id.png"    "$EXP/$id.png"
        cp "$ACT/macos/$id.stdout" "$EXP/$id.stdout"
        cp "$ACT/macos/$id.stderr" "$EXP/$id.stderr"
        cp "$ACT/macos/$id.exit"   "$EXP/$id.exit"
        printf '%srecorded%s tests/expected/%s.{png,stdout,stderr,exit}  (%s bytes, sha %s)\n' \
            "$C_BLD" "$C_RESET" "$id" "$(wc -c < "$EXP/$id.png" | tr -d ' ')" \
            "$(shasum -a 256 "$EXP/$id.png" | cut -c1-16)"
    done
    printf '\n%sNote:%s tests/expected/PROVENANCE is stamped by harness/run_macos.sh --record,\n' \
        "$C_BLD" "$C_RESET"
    printf 'which is what scripts/difftest.sh reads before it will grade anything. Run it too.\n'
    ;;
both|linux)
    npass=0; nfail=0; ndrift=0
    if [ "$MODE" = both ]; then
        printf '%s== macOS oracle (native, same bytes)%s\n' "$C_BLD" "$C_RESET"
        run_macos "$ACT/macos"
    fi

    printf '%s== machorun on Linux/arm64 (docker, %s)%s\n' "$C_BLD" "$IMAGE" "$C_RESET"
    run_linux || rc_overall=1

    printf '%s== differential%s\n' "$C_BLD" "$C_RESET"
    for id in $IDS; do
        printf '  %s%s%s\n' "$C_BLD" "$id" "$C_RESET"
        drift=0
        if [ "$MODE" = both ]; then
            printf '    %-20s exit=%s  png=%s bytes\n' "oracle" \
                "$(cat "$ACT/macos/$id.exit" 2>/dev/null)" \
                "$(bytes_of "$ACT/macos/$id.png")"
            # The oracle must still reproduce the committed baseline. This is
            # the check that says "macOS itself has not moved under us", and a
            # fixture whose oracle has moved can never be scored PASS in this
            # run -- re-recording is a deliberate, separate, committable act.
            if [ -f "$EXP/$id.png" ]; then
                if cmp -s "$EXP/$id.png" "$ACT/macos/$id.png" \
                   && cmp -s "$EXP/$id.stdout" "$ACT/macos/$id.stdout" \
                   && cmp -s "$EXP/$id.exit" "$ACT/macos/$id.exit"; then
                    printf '    %-20s %smatches committed baseline%s\n' \
                        "oracle vs baseline" "$C_GRN" "$C_RESET"
                else
                    printf '    %-20s %sBASELINE-DRIFT%s -- the ORACLE moved, not Linux.\n' \
                        "oracle vs baseline" "$C_RED" "$C_RESET"
                    printf '        Investigate before touching anything on the Linux side.\n'
                    if ! cmp -s "$EXP/$id.png" "$ACT/macos/$id.png" && ensure_pngdiff; then
                        "$PNGDIFF" "$EXP/$id.png" "$ACT/macos/$id.png"
                    fi
                    drift=1; ndrift=$((ndrift+1)); rc_overall=1
                fi
            else
                printf '    %-20s %snone committed%s (scripts/quartz_pixel.sh --record)\n' \
                    "oracle vs baseline" "$C_YEL" "$C_RESET"
            fi
            REF="$ACT/macos/$id"
        else
            [ -f "$EXP/$id.png" ] || die "--linux needs a committed baseline for $id (record it on macOS)"
            REF="$EXP/$id"
        fi

        A="$ACT/linux/$id"
        if [ ! -f "$A.exit" ]; then
            printf '    %-20s %sno result produced on Linux%s\n' "linux" "$C_RED" "$C_RESET"
            nfail=$((nfail+1)); rc_overall=1
            continue
        fi
        printf '    %-20s exit=%s  png=%s bytes\n' "linux" "$(cat "$A.exit")" \
            "$(bytes_of "$A.png")"

        bad=0
        show_stdout_diff "$REF" "$A" || bad=1

        if [ ! -f "$A.png" ]; then
            printf '    %-20s %sno PNG produced on Linux%s\n' "png" "$C_RED" "$C_RESET"
            [ -s "$A.stderr" ] && sed -n '1,10p' "$A.stderr" | sed 's/^/        /'
            bad=1
        elif cmp -s "$REF.png" "$A.png"; then
            printf '    %-20s %sBYTE-IDENTICAL%s  (%s bytes, sha256 %s)\n' "png" "$C_GRN" "$C_RESET" \
                "$(wc -c < "$A.png" | tr -d ' ')" \
                "$(shasum -a 256 "$A.png" 2>/dev/null | cut -c1-16)"
        else
            printf '    %-20s %sDIFFERS%s\n' "png" "$C_RED" "$C_RESET"
            printf '      oracle: %s  %s bytes\n      linux : %s  %s bytes\n' \
                "$(shasum -a 256 "$REF.png" | cut -c1-16)" "$(wc -c < "$REF.png" | tr -d ' ')" \
                "$(shasum -a 256 "$A.png" | cut -c1-16)"    "$(wc -c < "$A.png" | tr -d ' ')"
            ensure_pngdiff && "$PNGDIFF" "$REF.png" "$A.png"
            printf '      Do NOT re-record. The stage checksums above say WHEN it diverged;\n'
            printf '      the box above says WHERE.\n'
            bad=1
        fi

        if ! cmp -s "$REF.exit" "$A.exit" 2>/dev/null; then
            printf '    %-20s %sDIFFER%s (oracle %s, linux %s)\n' "exit status" "$C_RED" "$C_RESET" \
                "$(cat "$REF.exit" 2>/dev/null)" "$(cat "$A.exit" 2>/dev/null)"
            bad=1
        fi
        if ! cmp -s "$REF.stderr" "$A.stderr" 2>/dev/null; then
            printf '    %-20s %sDIFFER%s\n' "stderr" "$C_RED" "$C_RESET"
            diff "$REF.stderr" "$A.stderr" | sed -n '1,10p' | sed 's/^/        /'
            bad=1
        fi

        if [ "$drift" = 1 ]; then
            printf '    %-20s %sBASELINE-DRIFT%s (cannot be scored PASS in this run)\n' \
                "verdict" "$C_RED" "$C_RESET"
        elif [ "$bad" = 0 ]; then
            printf '    %-20s %sPASS%s\n' "verdict" "$C_GRN" "$C_RESET"
            npass=$((npass+1))
        else
            printf '    %-20s %sFAIL%s\n' "verdict" "$C_RED" "$C_RESET"
            nfail=$((nfail+1)); rc_overall=1
        fi
    done

    if [ -f "$ACT/.fingerprint" ]; then
        gate_check_stable "$(cut -f1 "$ACT/.fingerprint")" \
                          "$(cut -f2 "$ACT/.fingerprint")" \
                          "loader and darwin/ dylibs" || exit 2
        printf '\n%ssubject%s  build %s\n' "$C_DIM" "$C_RESET" \
            "$(cut -f1 "$ACT/.fingerprint")"
    fi
    printf '%s== scoreboard%s  pass %d  fail %d  baseline-drift %d\n' \
        "$C_BLD" "$C_RESET" "$npass" "$nfail" "$ndrift"
    ;;
esac

exit $rc_overall
