#!/bin/bash
# teeth_resolution.sh -- prove the resolution oracle can FAIL.
#
#     ./teeth_resolution.sh <fixture-dir> <results-dir> <fresh-work-dir>
#
# The oracle now reports 234 of 234 and 90 of 90, which is exactly when a
# comparison deserves least trust.  Each tooth plants a specific defect and
# requires the oracle to catch it, by name.
#
# Nothing here writes to the fixture, the results, or the corpus: every tooth
# works on a copy in the work directory.
set -uo pipefail
FIX=${1:?usage: teeth_resolution.sh <fixture-dir> <results-dir> <fresh-work-dir>}
RES=${2:?}
W=${3:?}
HERE=$(cd "$(dirname "$0")" && pwd)

if [ -e "$W" ] && [ -n "$(ls -A "$W" 2>/dev/null)" ]; then
    echo "REFUSING: $W is not empty -- point me at a fresh directory" >&2; exit 2
fi
mkdir -p "$W"
pass=0; fail=0
ok()  { echo "   PASS  $1"; pass=$((pass+1)); }
bad() { echo "   FAIL  $1"; fail=$((fail+1)); }

echo "== TOOTH 1: a PLANTED WRONG PAYLOAD must fail (end to end, through the device)"
# Swap the BYTES of two candidate files of one asset.  The compiled .car is
# rebuilt from the untouched .xcassets, so UIKit still returns the correct
# image -- but the candidate file the index's choice points at now holds the
# other variant's pixels, so identification lands on the wrong candidate.
# This is the only tooth that needs a device run, and it needs one because it
# is the only one that exercises the whole path.
cp -R "$FIX" "$W/fix1"
cat > "$W/plant1.py" <<'PLANT'
import json, os, sys
fx = sys.argv[1]
grid = json.load(open(os.path.join(fx, "grid.json")))
rows = {r["asset"]: r for r in grid["rows"]}
# TARGET A ROW THE ORACLE ACTUALLY SCORES.  The first version of this tooth
# took the first asset with an any/dark pair and landed on ProtonMail's
# `AppIcon-calculator-preview` -- an asset whose rows the oracle ALREADY
# excludes as UNIDENTIFIED.  So the plant changed a number nobody was looking
# at, the scoreboard stayed 234 of 234, and the tooth reported FAIL while the
# oracle was working correctly.
#
# A tooth that plants into an excluded row is vacuous, which is the exact
# failure teeth exist to prevent -- so the target is chosen deliberately
# (`SynLightDark`: three same-size variants, always scored) and the shell
# asserts afterwards that the oracle named THAT asset, not merely that
# something failed.
for name in ["SynLightDark"] + sorted(rows):
    r = rows.get(name)
    if not r or r["kind"] != "image":
        continue
    by = {}
    for c in r["candidates"]:
        by.setdefault(c["appearance"], c)
    if "any" in by and "dark" in by:
        a, b = by["any"], by["dark"]
        pa = os.path.join(fx, "Candidates", a["file"])
        pb = os.path.join(fx, "Candidates", b["file"])
        da, db = open(pa, "rb").read(), open(pb, "rb").read()
        open(pa, "wb").write(db)
        open(pb, "wb").write(da)
        sys.stderr.write("   planted: swapped the BYTES of %s and %s in %s\n"
                         % (a["filename"], b["filename"], r["asset"]))
        print(r["asset"])
        break
else:
    sys.exit(1)
PLANT
PLANTED=$(python3 "$W/plant1.py" "$W/fix1")
if [ -z "$PLANTED" ]; then bad "could not plant"; else
    bash "$HERE/run_resolution_oracle.sh" "$W/fix1" "$W/run1" >"$W/run1.log" 2>&1
    out=$(python3 "$HERE/score_resolution.py" "$W/fix1" "$W/run1" 2>&1); rc=$?
    if [ $rc -ne 0 ] && sed -n '/CHOSE A DIFFERENT VARIANT/,/^-- /p' <<<"$out" \
         | grep -q "$PLANTED"; then
        ok "exit $rc, oracle named the planted asset $PLANTED"
        sed -n '/CHOSE A DIFFERENT VARIANT/,/^-- /p' <<<"$out" | head -4 | sed 's/^/       /'
    else
        bad "the oracle did not name $PLANTED as a divergence; exit $rc"
        grep -E "^IMAGES|VERDICT" <<<"$out" | sed 's/^/       /'
    fi
fi

echo "== TOOTH 2: an INDEX-SIDE mis-resolution must fail (no device run needed)"
# Swap the light/dark LABELS in the grid only.  The catalog, the .car and the
# probe's measurements are untouched -- only the index's idea of which payload
# is the dark one changes -- so the algorithm now resolves dark to the light
# payload and the oracle must say so.  That the probe data can be re-scored
# without re-measuring is the point of keeping the algorithm out of the probe.
cp -R "$FIX" "$W/fix2"
python3 - "$W/fix2" <<'PY'
import json, os, sys
fx = sys.argv[1]
p = os.path.join(fx, "grid.json")
grid = json.load(open(p))
n = 0
for r in grid["rows"]:
    if r["kind"] != "image":
        continue
    dark = [c for c in r["candidates"] if c["appearance"] == "dark"]
    anyv = [c for c in r["candidates"] if c["appearance"] == "any"]
    if dark and anyv:
        dark[0]["appearance"], anyv[0]["appearance"] = "any", "dark"
        n += 1
json.dump(grid, open(p, "w"), indent=1, sort_keys=True)
print("   planted: swapped light/dark labels on %d assets, catalog untouched" % n)
sys.exit(0 if n else 1)
PY
if [ $? -ne 0 ]; then bad "could not plant"; else
    out=$(python3 "$HERE/score_resolution.py" "$W/fix2" "$RES" 2>&1); rc=$?
    if [ $rc -ne 0 ] && grep -q "CHOSE A DIFFERENT VARIANT" <<<"$out"; then
        ok "exit $rc, oracle reported CHOSE A DIFFERENT VARIANT"
        grep -E "^IMAGES|chose differently" <<<"$out" | head -2 | sed 's/^/       /'
    else
        bad "the oracle did not catch a swapped index label; exit $rc"
        grep -E "^IMAGES|VERDICT" <<<"$out" | sed 's/^/       /'
    fi
fi

echo "== TOOTH 3: the VACUOUS case must REFUSE, not pass"
mkdir -p "$W/empty"
out=$(python3 "$HERE/score_resolution.py" "$FIX" "$W/empty" 2>&1); rc=$?
if [ $rc -eq 2 ] && grep -q "REFUSING" <<<"$out"; then
    ok "no result files -> exit $rc, refused"
else
    bad "an empty results directory did not refuse; exit $rc"
fi
# and a results set with rows that decide nothing
mkdir -p "$W/norows"
python3 - "$RES" "$W/norows" <<'PY'
import glob, json, os, sys
src, dst = sys.argv[1], sys.argv[2]
for f in glob.glob(os.path.join(src, "resolution_*.json")):
    d = json.load(open(f))
    d["results"] = []          # measured nothing
    json.dump(d, open(os.path.join(dst, os.path.basename(f)), "w"))
print("   built a results set with zero rows")
PY
out=$(python3 "$HERE/score_resolution.py" "$FIX" "$W/norows" 2>&1); rc=$?
if [ $rc -eq 2 ] && grep -q "REFUSING" <<<"$out"; then
    ok "zero decidable rows -> exit $rc, refused"
else
    bad "a zero-row results set did not refuse; exit $rc"
    grep -E "VERDICT|REFUS" <<<"$out" | sed 's/^/       /'
fi

echo ""
echo "teeth passed $pass, failed $fail"
[ "$fail" -eq 0 ]
