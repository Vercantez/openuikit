#!/bin/bash
# quartz_pixel.sh -- the differential for tests/bin/15_quartz.
#
#   scripts/quartz_pixel.sh            run BOTH sides and compare (macOS host)
#   scripts/quartz_pixel.sh --record   re-record the macOS baseline, run nothing else
#   scripts/quartz_pixel.sh --linux    Linux side only, compare against the baseline
#
# Same discipline as scripts/difftest.sh, one rung further: the artefact under
# comparison is a PNG, not stdout. Method, unchanged:
#
#   * The macOS side EXECUTES tests/bin/15_quartz natively, every run. The
#     committed baseline is not trusted as a substitute for running it -- if
#     macOS's own output has moved, that is a fact worth learning before
#     grading Linux against it.
#   * The Linux side runs THE SAME BYTES under build/machorun in the test-bed
#     container.
#   * A mismatch is reported, never recorded. tests/expected/ is written ONLY
#     by --record, only on macOS.
#
# WHY 15_quartz IS NOT IN tests/manifest.tsv. Two reasons, both structural.
# Its result is a file rather than stdout, and its macOS run needs
# DYLD_LIBRARY_PATH because its install name is /usr/lib/libquartz.dylib -- an
# absolute Darwin path that exists on neither host (scripts/build_quartz_macos.sh
# explains why that is the right install name and why @rpath is not). The shared
# harness sets neither, and teaching it to would put a fixture-specific special
# case into the thing that grades every other fixture.
#
# WHAT A PASS HERE MEANS, precisely. The same precompiled arm64 Mach-O, built by
# Apple's clang against Apple's SDK, produced the same 26 KB PNG when run by
# macOS's own dyld against a libquartz built by Apple's clang, and when run by
# machorun on Linux/arm64 against a libquartz built by clang-18 for Mach-O
# against sdk/. Nine per-stage checksums on stdout localise any difference to
# the drawing stage that first diverged -- see the header of tests/src/15_quartz.c
# for what each stage is for and which one is the transcendental (libm) canary.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/harness/common.sh"

ID=15_quartz
FIX="$ROOT/tests/bin/$ID"
EXP="$ROOT/tests/expected"
ACT="$ROOT/tests/actual/quartz"
QZ_MACOS="${QUARTZ_MACOS_OUT:-$ROOT/build/quartz-macos}"
IMAGE="${MACHORUN_IMAGE:-machorun-testbed:24.04}"

MODE=both
case "${1:---}" in
    --record) MODE=record ;;
    --linux)  MODE=linux ;;
    --) ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) die "unknown option $1" ;;
esac

[ -f "$FIX" ] || die "no $FIX -- build it on macOS: tests/build_fixtures.sh 15_quartz"

mkdir -p "$ACT"
rc_overall=0

# --------------------------------------------------------------- macOS side
# Both sides write a file called 15_quartz.png, in their OWN directory. Same
# leaf name on purpose: the fixture echoes the path it wrote, so a different
# name would show up as a stdout difference on every single run and train the
# reader to ignore the one signal that localises a real divergence.
run_macos() { # run_macos <outdir>
    local out="$1"
    [ "$(uname -s)" = "Darwin" ] || die "the oracle side only runs on macOS"
    mkdir -p "$out"
    # Rebuild the oracle library from vendor/quartz every time. It is a build
    # product, deliberately not committed: committing it would let the oracle
    # drift from the sources the Linux side compiles.
    bash "$ROOT/scripts/build_quartz_macos.sh" > "$out/.build.log" 2>&1 \
        || { sed -n '1,20p' "$out/.build.log" >&2; die "macOS libquartz build failed"; }

    rm -f "$out/$ID.png"
    ( cd "$out" && LC_ALL=C LANG=C TZ=UTC \
        DYLD_LIBRARY_PATH="$QZ_MACOS" "$FIX" "$ID.png" ) \
        > "$out/$ID.stdout" 2> "$out/$ID.stderr"
    echo $? > "$out/$ID.exit"
}

# --------------------------------------------------------------- Linux side
run_linux() {
    command -v docker >/dev/null 2>&1 || die "docker not installed on this host"
    docker info >/dev/null 2>&1        || die "docker daemon not reachable"
    docker image inspect "$IMAGE" >/dev/null 2>&1 || \
        die "no test-bed image $IMAGE -- harness/run_linux.sh --build-image"

    # Exact, unique container name. Never rm by filter: this host runs
    # unrelated containers.
    local cname="machorun-quartz-$$"
    mkdir -p "$ACT/linux"
    rm -f "$ACT/linux/$ID.png"
    docker run --rm -i --name "$cname" --platform linux/arm64 \
        -v "$ROOT:/work" -w /work "$IMAGE" bash -s > "$ACT/.linux.log" 2>&1 <<'INNER'
set -e
cd /work
mkdir -p /work/tests/actual/quartz/linux
L=/work/tests/actual/quartz
sh scripts/build.sh loader        > $L/.loader.log 2>&1
sh scripts/build_darwin.sh        > $L/.darwin.log 2>&1
bash scripts/build_quartz.sh      > $L/.quartz.log 2>&1
cd $L/linux
export LC_ALL=C LANG=C TZ=UTC
rc=0
/work/build/machorun /work/tests/bin/15_quartz 15_quartz.png > 15_quartz.stdout 2> 15_quartz.stderr || rc=$?
echo $rc > 15_quartz.exit
INNER
    local drc=$?
    if [ $drc -ne 0 ]; then
        echo "${C_RED}the container run failed:${C_RESET}" >&2
        tail -30 "$ACT/.linux.log" >&2
        [ -s "$ACT/.quartz.log" ] && tail -20 "$ACT/.quartz.log" >&2
        return 1
    fi
    return 0
}

# ------------------------------------------------------------------ compare
show_stdout_diff() { # show_stdout_diff <a> <b>
    if cmp -s "$1" "$2"; then
        printf '  %-22s %sidentical%s\n' "stage checksums" "$C_GRN" "$C_RESET"
    else
        printf '  %-22s %sDIFFER%s -- first divergent stage:\n' "stage checksums" "$C_RED" "$C_RESET"
        diff "$1" "$2" | sed -n '1,12p' | sed 's/^/      /'
        rc_overall=1
    fi
}

case "$MODE" in
record)
    [ "$(uname -s)" = "Darwin" ] || die "--record only runs on macOS: the baseline is the oracle's"
    mkdir -p "$EXP"
    run_macos "$ACT/macos"
    cp "$ACT/macos/$ID.png"    "$EXP/$ID.png"
    cp "$ACT/macos/$ID.stdout" "$EXP/$ID.stdout"
    cp "$ACT/macos/$ID.stderr" "$EXP/$ID.stderr"
    cp "$ACT/macos/$ID.exit"   "$EXP/$ID.exit"
    printf '%srecorded%s tests/expected/%s.{png,stdout,stderr,exit}  (%s bytes, sha %s)\n' \
        "$C_BLD" "$C_RESET" "$ID" "$(wc -c < "$EXP/$ID.png" | tr -d ' ')" \
        "$(shasum -a 256 "$EXP/$ID.png" | cut -c1-16)"
    ;;
both|linux)
    if [ "$MODE" = both ]; then
        printf '%s== macOS oracle (native, same bytes)%s\n' "$C_BLD" "$C_RESET"
        run_macos "$ACT/macos"
        printf '  exit=%s  png=%s bytes\n' "$(cat "$ACT/macos/$ID.exit")" \
            "$(wc -c < "$ACT/macos/$ID.png" 2>/dev/null | tr -d ' ')"
        # If a baseline exists, the oracle must still reproduce it. This is the
        # check that says "macOS itself has not moved under us".
        if [ -f "$EXP/$ID.png" ]; then
            if cmp -s "$EXP/$ID.png" "$ACT/macos/$ID.png"; then
                printf '  %-22s %smatches committed baseline%s\n' "oracle vs baseline" "$C_GRN" "$C_RESET"
            else
                printf '  %-22s %sDIFFERS from committed baseline%s -- the ORACLE moved, not Linux.\n' \
                    "oracle vs baseline" "$C_RED" "$C_RESET"
                printf '      Investigate before touching anything on the Linux side.\n'
                rc_overall=1
            fi
        else
            printf '  %-22s %snone committed%s (scripts/quartz_pixel.sh --record)\n' \
                "oracle vs baseline" "$C_YEL" "$C_RESET"
        fi
        REF="$ACT/macos/$ID"
    else
        [ -f "$EXP/$ID.png" ] || die "--linux needs a committed baseline (record it on macOS)"
        REF="$EXP/$ID"
    fi

    printf '%s== machorun on Linux/arm64 (docker, %s)%s\n' "$C_BLD" "$IMAGE" "$C_RESET"
    run_linux || { rc_overall=1; }
    if [ -f "$ACT/linux/$ID.exit" ]; then
        printf '  exit=%s  png=%s bytes\n' "$(cat "$ACT/linux/$ID.exit")" \
            "$(wc -c < "$ACT/linux/$ID.png" 2>/dev/null | tr -d ' ')"
    fi

    printf '%s== differential%s\n' "$C_BLD" "$C_RESET"
    if [ ! -f "$ACT/linux/$ID.png" ]; then
        printf '  %-22s %sno PNG produced on Linux%s\n' "png" "$C_RED" "$C_RESET"
        [ -s "$ACT/linux/$ID.stderr" ] && sed -n '1,10p' "$ACT/linux/$ID.stderr" | sed 's/^/      /'
        rc_overall=1
    else
        show_stdout_diff "$REF.stdout" "$ACT/linux/$ID.stdout"
        if cmp -s "$REF.png" "$ACT/linux/$ID.png"; then
            printf '  %-22s %sBYTE-IDENTICAL%s  (%s bytes, sha256 %s)\n' "png" "$C_GRN" "$C_RESET" \
                "$(wc -c < "$ACT/linux/$ID.png" | tr -d ' ')" \
                "$(shasum -a 256 "$ACT/linux/$ID.png" 2>/dev/null | cut -c1-16)"
        else
            printf '  %-22s %sDIFFERS%s\n' "png" "$C_RED" "$C_RESET"
            printf '      %s\n      %s\n' \
                "oracle: $(shasum -a 256 "$REF.png" | cut -c1-16)  $(wc -c < "$REF.png" | tr -d ' ') bytes" \
                "linux : $(shasum -a 256 "$ACT/linux/$ID.png" | cut -c1-16)  $(wc -c < "$ACT/linux/$ID.png" | tr -d ' ') bytes"
            printf '      Do NOT re-record. The stage checksums above say where it first diverged.\n'
            rc_overall=1
        fi
    fi
    if ! cmp -s "$REF.exit" "$ACT/linux/$ID.exit" 2>/dev/null; then
        printf '  %-22s %sDIFFER%s (oracle %s, linux %s)\n' "exit status" "$C_RED" "$C_RESET" \
            "$(cat "$REF.exit" 2>/dev/null)" "$(cat "$ACT/linux/$ID.exit" 2>/dev/null)"
        rc_overall=1
    fi
    if ! cmp -s "$REF.stderr" "$ACT/linux/$ID.stderr" 2>/dev/null; then
        printf '  %-22s %sDIFFER%s\n' "stderr" "$C_RED" "$C_RESET"
        diff "$REF.stderr" "$ACT/linux/$ID.stderr" | sed -n '1,10p' | sed 's/^/      /'
        rc_overall=1
    fi
    ;;
esac

exit $rc_overall
