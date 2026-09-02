#!/bin/bash
# host_deny_gate.sh -- grade src/host_deny.c, in BOTH directions.
#
#   scripts/host_deny_gate.sh
#
# WHAT IT GRADES, and why both halves are needed:
#
#   FIRES    every name in src/host_deny.c's table, called from a dylib on the
#            runtime side of src/resolve.c's is_runtime line, stops the process
#            with a message naming itself. A refusal nobody has watched fire is
#            a comment.
#   DOES NOT every control name -- an ABI-compatible symbol arriving by exactly
#   FIRE     the same route -- host-binds and RETURNS THE RIGHT VALUE. Without
#            this half, a deny-list that denied everything would score full
#            marks, and so would one wired to a path that is never taken.
#   WITNESS  what the fallback would have done, measured on the host with the
#            Darwin constants a guest actually carries. Not a pass/fail: it is
#            the evidence for the table, printed so it cannot drift.
#
# THE TABLE IS READ OUT OF THE SOURCE, not restated here. A gate carrying its
# own copy of the list it grades cannot notice a row being added -- which is
# the scope-blindness this project keeps rediscovering -- so the names come
# from src/host_deny.c and are then required to be present IN THE BUILT LOADER
# as well, because the source and the binary are different claims.
#
# It runs inside the test-bed container: it needs clang + ld64.lld to build a
# Mach-O dylib and a Mach-O guest, and a Linux/aarch64 gcc for the witness.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/harness/common.sh"

IMAGE="${MACHORUN_IMAGE:-machorun-testbed:24.04}"
CNAME="machorun-hostdeny-$$"

command -v docker >/dev/null 2>&1 || die "docker not installed"
docker info >/dev/null 2>&1 || die "docker daemon not reachable"

# ------------------------------------------------------------- the table
# X(mangled, "cname", ... -- one row per denied symbol.
DENIED=$(grep -oE '^ *X\([a-z_0-9]+, "[a-z_0-9]+"' "$ROOT/src/host_deny.c" \
           | sed 's/.*"\(.*\)"/\1/' | LC_ALL=C sort -u)
CONTROLS="remquo nanf"

[ -n "$DENIED" ] || die "no deny rows parsed out of src/host_deny.c -- the
  table's shape changed and this gate is now grading nothing. Refusing rather
  than reporting 0 failures out of 0."

n_denied=$(printf '%s\n' "$DENIED" | grep -c .)
n_control=$(printf '%s\n' $CONTROLS | grep -c .)

printf '%shost-bind deny-list gate%s  (%d denied, %d control)\n' \
    "$C_BLD" "$C_RESET" "$n_denied" "$n_control"

[ -x "$ROOT/build/machorun" ] || die "no build/machorun -- scripts/build.sh loader"

CONTAINER_SCRIPT="$(cat <<'INNER'
set -u
cd /work
FAIL=0
PASS=0
CLANG=clang
LD64=ld64.lld-18
command -v $LD64 >/dev/null 2>&1 || LD64=ld64.lld
TARGET=arm64-apple-macos11
SDK=/work/sdk
W=$(mktemp -d)

# The SOURCE says these names are denied; the LOADER is what denies them, and
# a stale build is this tree's standing failure mode. Ask the binary. (Run in
# here rather than on the host: the host is macOS and its `strings` does not
# read a Linux ELF, so the check would have failed open.)
absent=""
for s in $DENY_NAMES; do
    strings /work/build/machorun | grep -qx "_$s" || absent="$absent _$s"
done
if [ -n "$absent" ]; then
    echo "STALE-LOADER$absent"
    exit 0
fi
echo "  ok    build/machorun contains every name in src/host_deny.c's table"
PASS=$((PASS+1))

# A darwin root made of SYMLINKS, never copies. Copying out of the bind mount
# is the documented way to get a silently truncated file in this project
# ([[machorun-project]]); linking cannot truncate anything, and the loader
# stats through the link.
mkdir -p "$W/root/usr/lib"
for f in /work/darwin/usr/lib/*.dylib; do ln -s "$f" "$W/root/usr/lib/"; done

# The staged dylib. -U on each denied/control name is what makes them
# dynamic-lookup binds that no loaded image satisfies -- the same dead end a
# real staged dylib reaches, arriving at the same line of src/resolve.c.
UFLAGS=""
for s in $DENY_NAMES $CONTROL_NAMES; do UFLAGS="$UFLAGS -U _$s"; done

$CLANG -target $TARGET -isysroot $SDK -fPIC -O1 -c \
       /work/tests/host_deny/probe.c -o "$W/probe.o" 2>"$W/cc.log" || {
    echo "PROBE-COMPILE-FAILED"; sed 's/^/    /' "$W/cc.log"; exit 0; }

$LD64 -dylib -arch arm64 -platform_version macos 11.0 11.0 \
      -install_name /usr/lib/libdenyprobe.dylib \
      -L$SDK/usr/lib -lSystem $UFLAGS \
      -o "$W/root/usr/lib/libdenyprobe.dylib" "$W/probe.o" 2>"$W/ld.log" || {
    echo "PROBE-LINK-FAILED"; sed 's/^/    /' "$W/ld.log"; exit 0; }

$CLANG -target $TARGET -isysroot $SDK -O1 -c \
       /work/tests/host_deny/guest.c -o "$W/guest.o" 2>>"$W/cc.log" || {
    echo "GUEST-COMPILE-FAILED"; sed 's/^/    /' "$W/cc.log"; exit 0; }
$LD64 -arch arm64 -platform_version macos 11.0 11.0 \
      -L$SDK/usr/lib -lSystem "$W/root/usr/lib/libdenyprobe.dylib" \
      -o "$W/guest" "$W/guest.o" 2>>"$W/ld.log" || {
    echo "GUEST-LINK-FAILED"; sed 's/^/    /' "$W/ld.log"; exit 0; }

run() { # run <probe-name> -> sets RC, OUT, ERR
    OUT=$(cd "$W" && MACHORUN_ROOT="$W/root" /work/build/machorun "$W/guest" "$1" 2>"$W/err")
    RC=$?
    ERR=$(cat "$W/err")
}

echo "--- denied: must stop the process and name themselves"
for s in $DENY_NAMES; do
    run "$s"
    if [ "$RC" = 70 ] && printf '%s' "$ERR" | grep -q "HOST-BIND DENIED: _$s"; then
        echo "  ok    $s: exit $RC, message names _$s"
        PASS=$((PASS+1))
    else
        echo "  FAIL  $s: exit $RC"
        printf '%s\n' "$OUT" | sed 's/^/          out: /'
        printf '%s\n' "$ERR" | head -3 | sed 's/^/          err: /'
        FAIL=$((FAIL+1))
    fi
done

echo "--- control: must host-bind and return the right value"
for s in $CONTROL_NAMES; do
    run "$s"
    case "$s:$OUT" in
        "remquo:remquo(13.0, 4.0, &quo) returned 1.0, quo 3") ok=1 ;;
        "nanf:nanf(\"\") returned a value with x!=x -> 1")     ok=1 ;;
        *) ok=0 ;;
    esac
    if [ "$RC" = 0 ] && [ "$ok" = 1 ]; then
        echo "  ok    $s: exit 0, $OUT"
        PASS=$((PASS+1))
    else
        echo "  FAIL  $s: exit $RC, returned: ${OUT:-<nothing>}"
        printf '%s\n' "$ERR" | head -3 | sed 's/^/          err: /'
        FAIL=$((FAIL+1))
    fi
done

# A denied name must be denied because it is IN THE TABLE, not because the
# whole path is broken. The control block above is that check; this one is its
# mirror -- the loader must log the denial, so the two are distinguishable in
# a verbose run rather than only by exit status.
run_v() { (cd "$W" && MACHORUN_ROOT="$W/root" MACHORUN_VERBOSE=1 \
             /work/build/machorun "$W/guest" "$1" 2>&1 >/dev/null); }
first=$(echo $DENY_NAMES | awk '{print $1}')
if run_v "$first" | grep -q "host: _$first DENIED"; then
    echo "  ok    verbose log records the denial of _$first at bind time"
    PASS=$((PASS+1))
else
    echo "  FAIL  verbose log does not record _$first being denied"
    FAIL=$((FAIL+1))
fi
if run_v "remquo" | grep -q "host: _remquo -> glibc/loader"; then
    echo "  ok    verbose log records _remquo taking the host fallback"
    PASS=$((PASS+1))
else
    echo "  FAIL  verbose log does not record _remquo host-binding"
    FAIL=$((FAIL+1))
fi

echo "--- witness: what the fallback would have done (measured, not graded)"
gcc -O1 -o "$W/witness" /work/tests/host_deny/witness.c 2>"$W/gcc.log" \
    && (cd "$W" && ./witness) \
    || { echo "  (witness did not build)"; sed 's/^/    /' "$W/gcc.log"; }

echo "TOTAL $PASS pass $FAIL fail"
INNER
)"

set +e
result="$(docker run --rm -i --name "$CNAME" --platform linux/arm64 \
    -v "$ROOT:/work" \
    -e "DENY_NAMES=$(printf '%s' "$DENIED" | tr '\n' ' ')" \
    -e "CONTROL_NAMES=$CONTROLS" \
    -w /work "$IMAGE" bash -s <<<"$CONTAINER_SCRIPT" 2>&1)"
rc=$?
set -e

printf '%s\n' "$result"

case "$result" in
    *STALE-LOADER*)
        printf '%sSTALE LOADER%s -- src/host_deny.c names symbols the built loader does\n' \
            "$C_RED" "$C_RESET" >&2
        printf '  not contain. Rebuild: scripts/build.sh loader\n' >&2
        exit 1 ;;
    *PROBE-COMPILE-FAILED*|*PROBE-LINK-FAILED*|*GUEST-COMPILE-FAILED*|*GUEST-LINK-FAILED*)
        printf '%sGATE COULD NOT RUN%s -- the fixture did not build, so nothing was graded.\n' \
            "$C_RED" "$C_RESET" >&2
        exit 1 ;;
esac

line="$(printf '%s\n' "$result" | grep '^TOTAL ' | tail -1)"
[ -n "$line" ] || { printf '%sGATE PRODUCED NO SCOREBOARD%s (docker rc=%d)\n' \
    "$C_RED" "$C_RESET" "$rc" >&2; exit 1; }

pass=$(printf '%s' "$line" | awk '{print $2}')
fail=$(printf '%s' "$line" | awk '{print $4}')
want=$((n_denied + n_control + 3))   # + 2 verbose-log checks + 1 loader-freshness

# THE DENOMINATOR IS CHECKED, not printed. A run that graded three of six rows
# and passed all three reports "3 pass 0 fail", which reads as success.
if [ "$fail" != 0 ]; then
    printf '%sFAIL%s  %s of %s checks failed\n' "$C_RED" "$C_RESET" "$fail" "$want" >&2
    exit 1
fi
if [ "$pass" != "$want" ]; then
    printf '%sSCOPE%s  %s checks passed but %s were expected (%s denied + %s control + 2 log).\n' \
        "$C_RED" "$C_RESET" "$pass" "$want" "$n_denied" "$n_control" >&2
    printf '  Something was skipped silently; the scoreboard is not about the table.\n' >&2
    exit 1
fi
printf '%sPASS%s  %s/%s -- %s denied names fire, %s controls do not\n' \
    "$C_GRN" "$C_RESET" "$pass" "$want" "$n_denied" "$n_control"
