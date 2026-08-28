#!/bin/bash
# stage_fe_guest.sh -- stage the GUEST FoundationEssentials build into the
# fm-build container, so FE and CoreFoundation can live in one process.
#
#   scripts/stage_fe_guest.sh [--check]
#
# #87 step 1+2. UserDefaults is the first ported class whose implementation is
# Swift-over-CF rather than pure Swift, so its guest runner is the first
# artifact that needs BOTH halves of Foundation. Measured before starting:
# `nm -u FoundationEssentials.o | grep _CF[A-Z]` is ZERO and CF references
# nothing in FE, so the two halves are DISJOINT and this is an additive
# staging job, not an integration. The port is the only thing referencing both,
# by design (docs/DECISION.md).
#
# WHY THIS REUSES AN ARTIFACT INSTEAD OF BUILDING ONE. The guest FE module was
# already built for #58/#72 and lives in ~/swift-macho-linux/scratch/fe4_out.
# Rebuilding a 202-file module to obtain a byte-different copy of something
# that already exists would produce no new information -- and would create the
# second authority this project has already been bitten by. So this script
# VERIFIES rather than rebuilds, and every verification below refuses rather
# than warns.
#
# WHAT IT REFUSES ON, and each is a claim someone could otherwise assume:
#
#   1. the source trees are not at their PINS.  The 202-files/0-errors result
#      was measured at these commits; a different commit is a different
#      measurement wearing the same number.
#   2. an artifact is OLDER than a source it was built from.  A binary older
#      than its own source passes every git-level check
#      (stale-artifact-invisible-to-every-check), and this project has now hit
#      that twice in one day, once in machorun's dylib and once in an SDK .tbd.
#   3. an artifact is MISSING.  Staging a partial set produces link errors that
#      read as port problems.
#
# It does NOT verify that the artifact was built FROM the pinned commit -- only
# that the tree is at the pin now and that the artifact is newer than the
# sources. That is a real gap and is stated rather than papered over: a tree
# checked out to the pin AFTER a build would satisfy both checks. The
# artifact's own provenance would need a manifest written at build time, which
# ~/swift-macho-linux does not currently emit (its #75).
set -uo pipefail

NAME=${NAME:-fm-build}
SML=${SML:-$HOME/swift-macho-linux}
CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

# THE PINS. Re-derived from the trees on 2026-08-28, not recalled.
# swift-foundation's release/6.2.2 HEAD carries BOTH swift-6.2.1-RELEASE and
# swift-6.2.2-RELEASE -- the module did not change between them -- so a
# `git describe` here prints 6.2.1 and reads as the wrong branch. Compare the
# COMMIT, never the tag.
PIN_SWIFT_FOUNDATION=c6793ef0c19c2cbaeba5a0e52078f129afc7dcfc
PIN_SWIFT_COLLECTIONS=9bf03ff58ce34478e66aaee630e491823326fd06

SF=$SML/scratch/swift-foundation
SC=$SML/scratch/swift-collections
OUT=$SML/scratch/fe4_out
COLL=$SML/scratch/fe4_collections
OSMOD=$SML/scratch/fe4_os
CSHIMS=$SML/scratch/fe4_cshims

fail=0
note() { printf '  %s\n' "$*"; }
bad()  { printf '  REFUSED: %s\n' "$*" >&2; fail=1; }

echo "== pins (compare the COMMIT, never the tag)"
for pair in "swift-foundation:$SF:$PIN_SWIFT_FOUNDATION" \
            "swift-collections:$SC:$PIN_SWIFT_COLLECTIONS"; do
    label=${pair%%:*}; rest=${pair#*:}; dir=${rest%%:*}; want=${rest##*:}
    if [ ! -d "$dir/.git" ]; then bad "$label: no git tree at $dir"; continue; fi
    got=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
    if [ "$got" = "$want" ]; then
        note "$label  ${got:0:12}  OK"
    else
        bad "$label is at ${got:0:12}, pinned to ${want:0:12}"
        note "   fix: git -C $dir checkout $want"
    fi
done

echo "== artifacts present, and NEWER than the sources they were built from"
# The FE module is the one whose sources we can point at; the others are
# checked for presence only, and that limit is stated rather than implied.
FE_O=$OUT/FoundationEssentials.o
if [ ! -f "$FE_O" ]; then
    bad "FoundationEssentials.o missing at $FE_O"
else
    newer=$(find "$SF/Sources/FoundationEssentials" -name '*.swift' -newer "$FE_O" 2>/dev/null | wc -l | tr -d ' ')
    nsrc=$(find "$SF/Sources/FoundationEssentials" -name '*.swift' 2>/dev/null | wc -l | tr -d ' ')
    if [ "${newer:-1}" -eq 0 ]; then
        note "FoundationEssentials.o  $(wc -c < "$FE_O" | tr -d ' ') bytes, newer than all $nsrc sources"
    else
        bad "$newer of $nsrc FoundationEssentials sources are NEWER than the built module."
        note "   The artifact predates its own source. Rebuild before trusting it:"
        note "   $SML/full/foundation/build_fe.sh"
    fi
    # The recorded result is 202 files; a different count is a different module.
    [ "${nsrc:-0}" -eq 202 ] || bad "source count is $nsrc, the measured build was 202"
fi

for f in "$OUT/FoundationEssentials.swiftmodule" \
         "$COLL/OrderedCollections.o" "$COLL/InternalCollectionsUtilities.o" \
         "$COLL/_RopeModule.o" "$OSMOD/os.o" \
         "$CSHIMS/platform_shims.o" "$CSHIMS/string_shims.o" "$CSHIMS/uuid.o"; do
    [ -f "$f" ] || bad "missing artifact: $f"
done

# THE DISJOINTNESS THAT MAKES THIS ADDITIVE, re-measured rather than recalled.
# If FE ever grows a CF reference this stops being a staging job and becomes an
# integration, and the person staging should find that out here.
if [ -f "$FE_O" ]; then
    ncf=$(nm -u "$FE_O" 2>/dev/null | grep -cE '^_CF[A-Z]' || true)
    if [ "${ncf:-0}" -eq 0 ]; then
        note "FE references 0 CF symbols -- the halves are still disjoint"
    else
        bad "FE now references $ncf CF symbols; this is no longer purely additive"
    fi
fi

if [ "$fail" -ne 0 ]; then
    echo
    echo "REFUSING to stage. Nothing has been copied." >&2
    exit 2
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
    echo
    echo "check only: everything verified, nothing staged."
    exit 0
fi

docker ps --format '{{.Names}}' | grep -qx "$NAME" || {
    echo "FATAL: container '$NAME' is not running" >&2; exit 2; }

echo "== staging into $NAME:/work/fe"
docker exec "$NAME" bash -lc 'rm -rf /work/fe && mkdir -p /work/fe/{module,collections,os,cshims}'
tar czf - -C "$OUT" FoundationEssentials.o FoundationEssentials.swiftmodule \
    FoundationEssentials.swiftdoc 2>/dev/null \
  | docker exec -i "$NAME" bash -c 'cd /work/fe/module && tar xzf -'
tar czf - -C "$COLL" . | docker exec -i "$NAME" bash -c 'cd /work/fe/collections && tar xzf -'
tar czf - -C "$OSMOD" . | docker exec -i "$NAME" bash -c 'cd /work/fe/os && tar xzf -'
tar czf - -C "$CSHIMS" . | docker exec -i "$NAME" bash -c 'cd /work/fe/cshims && tar xzf -'

# TOOTH: verify what ARRIVED, not what was sent. `docker exec -i` with a broken
# stdin copies nothing and exits 0 -- this script's sibling learned that the
# hard way.
echo "== verifying what arrived"
docker exec "$NAME" bash -lc '
  n=$(find /work/fe -type f | wc -l)
  echo "  files staged: $n"
  [ -f /work/fe/module/FoundationEssentials.o ] || { echo "  *** FoundationEssentials.o did not arrive ***"; exit 3; }
  echo "  FoundationEssentials.o  $(wc -c < /work/fe/module/FoundationEssentials.o) bytes"
  file /work/fe/module/FoundationEssentials.o | sed "s/^/  /"
' || exit 3

echo
echo "staged. Both halves of Foundation are now in one container:"
echo "  /work/fe/...                FoundationEssentials + deps (guest Mach-O)"
echo "  /work/lib/libCFTest.dylib   CoreFoundation"
echo "Next: compile the port against CF's headers and link it with both."
