#!/bin/bash
# stage_ud_oracle.sh -- MACOS HOST ONLY. Put the Darwin golden into the build
# container, as a generated Swift file that embeds it byte-for-byte.
#
#   scripts/stage_ud_oracle.sh [--check]
#
# The golden is emitted by ~/swift-macho-linux's host oracle
# (`ud_runner golden`) and committed there; this script only carries it across.
# The container has no python, so the embedding happens here.
#
# WHAT IT REFUSES ON, and each is a claim someone would otherwise assume:
#
#   1. the golden is MISSING. An absent golden compiles to an empty table, and
#      an empty scoreboard scores 100% -- the failure that looks like success.
#   2. the golden is STALE against the port it will grade. The golden records
#      real Foundation's answers for a corpus; if the PORT source has moved
#      since, the host number quoted in the golden's header is about a
#      different port. That is not automatically wrong, but it must be said
#      out loud rather than discovered later.
#   3. what ARRIVED is not what was sent. `docker exec -i` with a broken stdin
#      copies nothing and exits 0; this repo's sibling staging script learned
#      that the hard way, so the sha256 is compared on both sides.
set -euo pipefail

NAME=${NAME:-fm-build}
SML=${SML:-$HOME/swift-macho-linux}
ORACLE=$SML/full/oracle-userdefaults
GOLDEN=${GOLDEN:-$ORACLE/darwin-golden-2026-08-28.txt}
PORT_SRC=${PORT_SRC:-$HOME/foundation-macho/src/overlay/UserDefaults.swift}
CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

cd "$(dirname "$0")/.."
fail=0
note() { printf '  %s\n' "$*"; }
bad()  { printf '  REFUSED: %s\n' "$*" >&2; fail=1; }

echo "== the golden"
if [ ! -f "$GOLDEN" ]; then
    bad "no golden at $GOLDEN"
    note "   emit it: $ORACLE/build_ud_host.sh OUT && OUT/ud_runner golden $GOLDEN"
else
    d=$(grep -c $'^D\t' "$GOLDEN" || true)
    c=$(grep -c $'^C\t' "$GOLDEN" || true)
    note "$(basename "$GOLDEN")  D=$d (real Foundation)  C=$c (corelibs)"
    [ "${d:-0}" -gt 0 ] || bad "the golden has no D rows; nothing to grade against"
    [ "${c:-0}" -gt 0 ] || bad "the golden has no C rows; there would be no must-fail column"
fi

# THE PORT THE GOLDEN DESCRIBES vs THE PORT THAT WILL BE GRADED. The golden's
# header carries the host scoreboard; the port sha it was taken at is recorded
# by build_ud_host.sh, not in the golden, so the honest check available here is
# TIME: a golden older than the port source is a golden taken before the port
# changed.
echo "== freshness"
if [ -f "$GOLDEN" ] && [ -f "$PORT_SRC" ]; then
    if [ "$PORT_SRC" -nt "$GOLDEN" ]; then
        bad "the PORT source is newer than the golden."
        note "   $(basename "$PORT_SRC")  $(date -r "$PORT_SRC" '+%Y-%m-%d %H:%M:%S')"
        note "   $(basename "$GOLDEN")  $(date -r "$GOLDEN" '+%Y-%m-%d %H:%M:%S')"
        note "   Re-run the host oracle so the golden describes the port being graded."
    else
        note "golden is newer than the port source it will grade"
    fi
fi

if [ "$fail" -ne 0 ]; then
    echo; echo "REFUSING to stage. Nothing has been copied." >&2; exit 2
fi
[ "$CHECK_ONLY" -eq 1 ] && { echo; echo "check only: verified, nothing staged."; exit 0; }

docker ps --format '{{.Names}}' | grep -qx "$NAME" || {
    echo "FATAL: container '$NAME' is not running" >&2; exit 2; }

echo "== generating the embedded golden"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
python3 scripts/gen_guest_golden.py "$GOLDEN" "$TMP/GuestGolden.swift" | sed 's/^/  /'
SHA_LOCAL=$(shasum -a 256 "$TMP/GuestGolden.swift" | cut -d' ' -f1)

echo "== staging into $NAME:/work/oracle"
docker exec "$NAME" bash -lc 'mkdir -p /work/oracle'
tar czf - -C "$TMP" GuestGolden.swift \
  | docker exec -i "$NAME" bash -c 'cd /work/oracle && tar xzf -'
tar czf - -C "$(dirname "$GOLDEN")" "$(basename "$GOLDEN")" \
  | docker exec -i "$NAME" bash -c 'cd /work/oracle && tar xzf -'

# VERIFY WHAT ARRIVED, not what was sent.
echo "== verifying what arrived"
SHA_REMOTE=$(docker exec "$NAME" bash -lc 'sha256sum /work/oracle/GuestGolden.swift 2>/dev/null | cut -d" " -f1' || true)
if [ "$SHA_LOCAL" != "$SHA_REMOTE" ]; then
    echo "  *** what arrived is not what was sent ***" >&2
    echo "      sent    $SHA_LOCAL" >&2
    echo "      arrived ${SHA_REMOTE:-<nothing>}" >&2
    exit 3
fi
docker exec "$NAME" bash -lc '
  echo "  GuestGolden.swift  $(wc -c < /work/oracle/GuestGolden.swift) bytes"
  grep -m1 "// Rows:" /work/oracle/GuestGolden.swift | sed "s/^/  /"'
echo "  sha256 matches on both sides: ${SHA_LOCAL:0:16}…"
echo
echo "next: docker exec $NAME bash -lc 'bash /repo/scripts/build_ud_score_guest.sh'"
