#!/usr/bin/env bash
# In-VM x86_64 scoreboard: run tests/bin-x86_64/* under the ported loader and
# grade against tests/expected/ (Darwin/arm64 baselines).
#
#   built / run / matching / needs-new-baseline / failing
# plus refused (cannot produce a guest) — never a silent skip.
#
# Genuinely arch-dependent mismatches are NEEDS_DARWIN_X86_BASELINE, not FAIL:
# do not bend the fixture. The operator re-records those on macOS/Rosetta into
# tests/expected-x86_64/. If a mismatch is not one of the measured arch
# divergences below, it is FAIL — a port that "passes" because the check
# could not see the difference is worse than a failure.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/tests/bin-x86_64"
EXPECTED="$ROOT/tests/expected"
ACTUAL="$ROOT/tests/actual-x86_64"
MANIFEST="$ROOT/tests/manifest.tsv"
LOADER="$ROOT/build/machorun"
REFUSE="$BIN/.refuse"
X86_EXPECTED="$ROOT/tests/expected-x86_64"

export MACHORUN_ROOT="$ROOT"
export LC_ALL=C LANG=C TZ=UTC

if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "CANNOT_SCORE_X86: host is $(uname -m), need x86_64" >&2
    exit 1
fi
if [[ ! -x "$LOADER" ]]; then
    echo "CANNOT_SCORE_X86: no $LOADER — scripts/build.sh loader" >&2
    exit 1
fi
if [[ ! -d "$BIN" ]]; then
    echo "CANNOT_SCORE_X86: no $BIN — scripts/build_fixtures_linux_x86_64.sh" >&2
    exit 1
fi

mkdir -p "$ACTUAL"
rm -f "$ACTUAL"/*.stdout "$ACTUAL"/*.stderr "$ACTUAL"/*.exit "$ACTUAL"/*.verdict

ids=()
while IFS=$'\t' read -r id rest; do
    [[ "$id" == \#* || -z "$id" ]] && continue
    ids+=("$id")
done < "$MANIFEST"
TOTAL=${#ids[@]}

n_built=0 n_run=0 n_match=0 n_base=0 n_fail=0 n_refuse=0 n_norun=0

# Arch-dependent output the arm64 Darwin oracle recorded and Darwin/x86_64
# (Rosetta) will itself disagree with. Confined to these measured substitutions;
# any extra diff is FAIL. Do NOT replace an entire line: that hid a garbage
# long-double value behind sizeof=16 and would have been a false green.
is_arch_baseline() {
    local id="$1"
    local exp="$EXPECTED/$id.stdout"
    local act="$ACTUAL/$id.stdout"
    local tmp
    tmp="$(mktemp -d)"
    # machine field of uname; long-double sizeof (varargs sizeof=N,
    # hostbound_surface's "strtold_l width", fmal/remquol's sizeof_ld / ld80 bit);
    # vm_copy checksums scale with Darwin's page (16 KiB arm64, 4 KiB x86_64)
    # and the fixture uses vm_page_size.
    local arch_sed=(
        -e 's/machine[[:space:]]+\[arm64\]/machine                 [ARCH]/'
        -e 's/machine[[:space:]]+\[x86_64\]/machine                 [ARCH]/'
        -e 's/sizeof=8/sizeof=ARCH/'
        -e 's/sizeof=16/sizeof=ARCH/'
        -e 's/strtold_l width       8/strtold_l width       ARCH/'
        -e 's/strtold_l width       16/strtold_l width       ARCH/'
        -e 's/sizeof_ld               8/sizeof_ld               ARCH/'
        -e 's/sizeof_ld               16/sizeof_ld               ARCH/'
        -e 's/ld80_bit_survives       yes/ld80_bit_survives       ARCH/'
        -e 's/ld80_bit_survives       no/ld80_bit_survives       ARCH/'
        -e 's/vm_allocate aligned=(yes|no)/vm_allocate aligned=ARCH/'
        -e 's/last=[a-z] sum=[0-9]+/last=ARCH sum=ARCH/'
    )
    sed -E "${arch_sed[@]}" "$exp" > "$tmp/e"
    sed -E "${arch_sed[@]}" "$act" > "$tmp/a"
    if ! cmp -s "$tmp/e" "$tmp/a"; then
        rm -rf "$tmp"
        return 1
    fi
    rm -rf "$tmp"
    if cmp -s "$exp" "$act"; then
        return 1
    fi
    return 0
}

printf '%-26s %-22s %s\n' "FIXTURE" "VERDICT" "DETAIL"
printf '%s\n' "--------------------------------------------------------------------------------"

for id in "${ids[@]}"; do
    detail=""
    verdict=""

    if [[ -f "$REFUSE/$id" ]]; then
        marker="$(head -1 "$REFUSE/$id")"
        verdict="REFUSED"
        detail="$marker"
        n_refuse=$((n_refuse + 1))
    elif [[ ! -f "$BIN/$id" ]]; then
        verdict="REFUSED"
        detail="CANNOT_RUN_X86: no binary in tests/bin-x86_64/ and no refuse log"
        n_refuse=$((n_refuse + 1))
        echo "$detail" > "$ACTUAL/$id.verdict"
    else
        n_built=$((n_built + 1))
        rc=0
        (
            cd "$BIN"
            timeout -k 2 20 "$LOADER" "./$id"
        ) >"$ACTUAL/$id.stdout" 2>"$ACTUAL/$id.stderr" || rc=$?
        printf '%d\n' "$rc" > "$ACTUAL/$id.exit"
        n_run=$((n_run + 1))

        if [[ -f "$X86_EXPECTED/$id.exit" ]]; then
            # An operator-recorded Darwin/x86_64 (Rosetta) baseline wins over
            # the arm64 one: exact bytes, no arch mask. Measured 2026-09-03:
            # the eight NEEDS_DARWIN_X86_BASELINE fixtures stayed flagged after
            # the baselines were committed because this branch did not exist.
            ee=$(cat "$X86_EXPECTED/$id.exit")
            ae=$(cat "$ACTUAL/$id.exit")
            if [[ "$ee" == "$ae" ]] \
               && cmp -s "$X86_EXPECTED/$id.stdout" "$ACTUAL/$id.stdout" \
               && { [[ ! -f "$X86_EXPECTED/$id.stderr" ]] || cmp -s "$X86_EXPECTED/$id.stderr" "$ACTUAL/$id.stderr"; }; then
                verdict="MATCH"
                detail="x86_64 Darwin baseline (tests/expected-x86_64)"
                n_match=$((n_match + 1))
            else
                verdict="FAIL"
                detail="differs from tests/expected-x86_64/$id (exit $ee vs $ae); diff tests/actual-x86_64/$id.stdout tests/expected-x86_64/$id.stdout"
                n_fail=$((n_fail + 1))
            fi
        elif [[ ! -f "$EXPECTED/$id.exit" ]]; then
            verdict="NO-ORACLE"
            detail="no tests/expected/$id.exit (parse-only on Darwin too)"
            n_norun=$((n_norun + 1))
        else
            ee=$(cat "$EXPECTED/$id.exit")
            ae=$(cat "$ACTUAL/$id.exit")
            stdout_ok=0 stderr_ok=0
            cmp -s "$EXPECTED/$id.stdout" "$ACTUAL/$id.stdout" && stdout_ok=1
            cmp -s "$EXPECTED/$id.stderr" "$ACTUAL/$id.stderr" && stderr_ok=1
            if [[ "$ee" == "$ae" && "$stdout_ok" == 1 && "$stderr_ok" == 1 ]] \
               && ! grep -q 'vm_allocate aligned=' "$ACTUAL/$id.stdout"; then
                # Exact match, and no page-size line that Darwin/x86 will
                # itself disagree with. (vm_allocate aligned=yes can happen
                # on a 4 KiB allocator by luck of 16 KiB alignment -- that
                # MATCH would be a false green.)
                verdict="MATCH"
                n_match=$((n_match + 1))
            elif [[ "$ee" == "$ae" && "$stderr_ok" == 1 ]] && is_arch_baseline "$id"; then
                verdict="NEEDS_DARWIN_X86_BASELINE"
                detail="arch-dependent stdout vs tests/expected/ (do not bend the fixture)"
                n_base=$((n_base + 1))
            elif [[ "$ee" == "$ae" && "$stderr_ok" == 1 && "$stdout_ok" == 1 ]] \
               && grep -q 'vm_allocate aligned=' "$ACTUAL/$id.stdout"; then
                verdict="NEEDS_DARWIN_X86_BASELINE"
                detail="arch-dependent stdout vs tests/expected/ (do not bend the fixture)"
                n_base=$((n_base + 1))
            else
                verdict="FAIL"
                if [[ "$ee" != "$ae" ]]; then
                    detail="exit $ae, expected $ee"
                elif [[ "$stdout_ok" != 1 ]]; then
                    detail="stdout differs"
                else
                    detail="stderr differs"
                fi
                n_fail=$((n_fail + 1))
            fi
        fi
    fi
    printf '%-26s %-22s %s\n' "$id" "$verdict" "$detail"
    printf '%s\n' "$verdict" > "$ACTUAL/$id.verdict"
done

printf '%s\n' "--------------------------------------------------------------------------------"
printf 'SCOREBOARD  fixtures=%d  built=%d  run=%d  matching=%d  needs-new-baseline=%d  failing=%d  refused=%d  no-oracle=%d\n' \
    "$TOTAL" "$n_built" "$n_run" "$n_match" "$n_base" "$n_fail" "$n_refuse" "$n_norun"
printf 'denominators: matching %d/%d built,  %d/%d run,  %d/%d manifest\n' \
    "$n_match" "$n_built" "$n_match" "$n_run" "$n_match" "$TOTAL"
printf 'refused markers in %s\n' "$REFUSE"

# Record a machine-readable summary for the PR / artifacts.
{
    echo "total=$TOTAL"
    echo "built=$n_built"
    echo "run=$n_run"
    echo "matching=$n_match"
    echo "needs_new_baseline=$n_base"
    echo "failing=$n_fail"
    echo "refused=$n_refuse"
    echo "no_oracle=$n_norun"
} > "$ACTUAL/SCOREBOARD"

# A run that refused everything is not a passing run. Failing fixtures are a
# port bug. NEEDS_DARWIN_X86_BASELINE is an expected remainder, not a pass.
if [[ "$n_fail" -gt 0 ]]; then
    echo
    echo "Failures (unexpected — not arch-baseline):"
    for id in "${ids[@]}"; do
        [[ "$(cat "$ACTUAL/$id.verdict" 2>/dev/null || true)" == FAIL ]] || continue
        echo "---- $id ----"
        echo "exit actual=$(cat "$ACTUAL/$id.exit" 2>/dev/null) expected=$(cat "$EXPECTED/$id.exit" 2>/dev/null)"
        diff -u "$EXPECTED/$id.stdout" "$ACTUAL/$id.stdout" 2>/dev/null | head -40 || true
        echo "stderr:"
        head -20 "$ACTUAL/$id.stderr" 2>/dev/null || true
    done
    exit 1
fi
exit 0
