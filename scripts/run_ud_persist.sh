#!/bin/bash
# run_ud_persist.sh -- #92, the guest PERSIST phase: does what the port wrote
# survive a FRESH PROCESS under machorun?
#
#   scripts/run_ud_persist.sh [ROOT]        # default /work/root
#
# WHY THIS IS A SEPARATE RUN AND NOT A LONGER TEST. The #87 step 4 board writes
# and reads in ONE process, so everything it reads back could have come from
# CF's in-memory preferences cache. On Darwin that ambiguity is tolerable --
# writes go through cfprefsd and the file is not authoritative in real time. Our
# stack has NO DAEMON, so persistence must come from the file, which makes this
# the route where a format or flush defect actually bites and the one route not
# previously testing it.
#
# THREE PHASES, and the third is the one that gives the second its meaning:
#
#   1. WRITE      a process writes the corpus, synchronises, exits scoring
#                 nothing.
#   2. WITNESS    an INDEPENDENT check, from the shell, that a plist appeared on
#                 disk and is non-trivial. The guest asserting its own success
#                 is the claim under test, so the evidence must come from
#                 outside it.
#   3. READ       a FRESH process reads and scores. Must pass.
#   4. CONTROL    the plist is DELETED and the read is repeated. It MUST FAIL.
#                 An agreement-only board scores well against an empty store --
#                 this is the run that proves it does not here.
set -uo pipefail

W=${W:-/work}
R=${R:-/repo}
ROOT=${1:-$W/root}
BIN=${BIN:-$W/bin/ud_score_guest}
MRUN=${MRUN:-/stage/machorun-bin}
SUITE=com.example.udguest.persist
PREFS=${PREFS:-/root/Library/Preferences}
PLIST=$PREFS/$SUITE.plist
OTHER=$PREFS/$SUITE.other.plist

hr() { echo; echo "########## $*"; }

hr "0. clean slate"
rm -f "$PLIST" "$OTHER"
echo "  removed $PLIST"
[ -e "$PLIST" ] && { echo "  REFUSING: could not remove the plist" >&2; exit 2; }
echo "  confirmed absent"

hr "1. WRITE (a process that scores nothing)"
UD_MODE=persist-write MACHORUN_ROOT="$ROOT" "$MRUN" "$BIN" 2>&1 | grep -vE "_CFGetHostUUIDString"
rc=${PIPESTATUS[0]}
[ "$rc" -eq 0 ] || { echo "  write phase exited $rc" >&2; exit 3; }

hr "2. WITNESS — from the shell, not from the guest"
if [ ! -f "$PLIST" ]; then
    echo "  ✗ no file at $PLIST after the write phase." >&2
    echo "    The write reported success and left nothing on disk; that is the" >&2
    echo "    'succeeds and does nothing' shape and it is why this check is" >&2
    echo "    outside the process making the claim." >&2
    exit 4
fi
sz=$(wc -c < "$PLIST")
magic=$(head -c8 "$PLIST")
echo "  $PLIST"
echo "    $sz bytes, magic '$magic'"
[ "$sz" -gt 512 ] || { echo "  ✗ implausibly small for the corpus written" >&2; exit 4; }
[ "$magic" = "bplist00" ] || echo "  NOTE: not a binary plist — format is '$magic'"
# A distinctive value must be IN THE BYTES. If the file existed but held an
# older or empty domain, the size check alone would pass.
if grep -qa "9223372036854775807" "$PLIST" 2>/dev/null; then
    echo "    contains a distinctive corpus value (Int.max as a stored string)"
else
    echo "  ✗ the file does not contain a value the corpus definitely wrote." >&2
    exit 4
fi

hr "3. READ (a FRESH process; nothing it reads was written by it)"
UD_MODE=persist-read MACHORUN_ROOT="$ROOT" "$MRUN" "$BIN" 2>&1 \
  | grep -vE "_CFGetHostUUIDString" | tail -30
read_rc=${PIPESTATUS[0]}
echo "  read phase exit $read_rc"

hr "4. NEGATIVE CONTROL — same binary, store DELETED, must FAIL"
cp "$PLIST" "$PLIST.keep"
rm -f "$PLIST" "$OTHER"
[ -e "$PLIST" ] && { echo "  REFUSING: the mutation did not take effect" >&2; exit 5; }
echo "  store deleted and confirmed absent (the mutation TOOK -- #89 lost two"
echo "  teeth tests to mutations that silently did not)"
UD_MODE=persist-read MACHORUN_ROOT="$ROOT" "$MRUN" "$BIN" 2>&1 \
  | grep -vE "_CFGetHostUUIDString" \
  | grep -E "presence:|witness:|✗|✓ every written|PORT: scored|GUEST SCOREBOARD"
ctl_rc=${PIPESTATUS[0]}
echo "  control exit $ctl_rc"
mv -f "$PLIST.keep" "$PLIST"

hr "VERDICT"
fail=0
if [ "$read_rc" -ne 0 ]; then
    echo "  ✗ the fresh-process read FAILED. What the port wrote does not come"
    echo "    back after a restart."
    fail=1
else
    echo "  ✓ a fresh process re-read what the port wrote, and scored it."
fi
if [ "$ctl_rc" -eq 0 ]; then
    echo "  ✗ the control PASSED with no store on disk. This board cannot tell a"
    echo "    populated store from an empty one, so phase 3 means nothing."
    fail=1
else
    echo "  ✓ with the store deleted the same binary FAILS (exit $ctl_rc) — the"
    echo "    read phase is grading the file, not agreeing with itself."
fi
exit $fail
