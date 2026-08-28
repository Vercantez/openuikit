#!/bin/bash
# teeth.sh -- prove the gates can FAIL.
#
#     ./teeth.sh <corpus-dir> <fresh-work-dir>
#
# Every check in this directory is a check that passed on the first corpus run.
# That is exactly when a gate is least trustworthy: a comparison that trivially
# agrees, an accounting identity that cannot be violated, and a refusal that
# never fires all look identical to working ones.  Each tooth below plants a
# specific defect and requires the corresponding gate to catch it, by name.
#
# The planting is done on COPIES in the work directory.  The corpus is pinned
# and read-only here; ~/uikit is read-only for agents generally.
set -uo pipefail
CORPUS=${1:?usage: teeth.sh <corpus-dir> <fresh-work-dir>}
W=${2:?usage: teeth.sh <corpus-dir> <fresh-work-dir>}
HERE=$(cd "$(dirname "$0")" && pwd)
TOOL="$HERE/xcassets_tool.py"

if [ -e "$W" ] && [ -n "$(ls -A "$W" 2>/dev/null)" ]; then
    echo "REFUSING: $W is not empty -- point me at a fresh directory" >&2; exit 2
fi
mkdir -p "$W"
pass=0; fail=0
ok()   { echo "   PASS  $1"; pass=$((pass+1)); }
bad()  { echo "   FAIL  $1"; fail=$((fail+1)); }

# A small real catalog, copied so the corpus is never written to.
SRC=$(find "$CORPUS/Hackers" -name 'Colors.xcassets' -type d | head -1)
[ -n "$SRC" ] || { echo "no Colors.xcassets in the corpus" >&2; exit 2; }

# The copy MUST keep the `.xcassets` suffix: the reader identifies a catalog by
# its extension, so `cp -R src $W/cat` produced "no .xcassets found" and every
# tooth "passed the refusal check" for entirely the wrong reason.  A tooth that
# fires on the harness rather than on the planted defect is worse than no tooth.
fresh() { rm -rf "$W/cat.xcassets" "$W/out"; cp -R "$SRC" "$W/cat.xcassets"; }
# pick a real COLORSET Contents.json, not the catalog root (which has no `colors`)
victim_colorset() { find "$W/cat.xcassets" -name Contents.json -path '*.colorset/*' | sort | head -1; }

echo "== TOOTH 1: a corrupted Contents.json must REFUSE, naming the file"
fresh
victim=$(victim_colorset)
printf '{ "colors": [ ' > "$victim"          # truncated JSON
out=$(python3 "$TOOL" index "$W/cat.xcassets" --out "$W/out" 2>&1); rc=$?
if [ $rc -eq 2 ] && grep -q "REFUSED" <<<"$out" && grep -q "not valid UTF-8 JSON" <<<"$out" \
   && grep -qF "$(basename "$(dirname "$victim")")" <<<"$out"; then
    ok "exit $rc, refused and named $(basename "$(dirname "$victim")")"
else
    bad "expected a refusal naming the file; got exit $rc: $(head -2 <<<"$out")"
fi

echo "== TOOTH 2: an unknown Contents.json key must REFUSE"
fresh
victim=$(victim_colorset)
python3 - "$victim" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); d["colors"][0]["wibble"]="x"
json.dump(d,open(sys.argv[1],'w'))
PY
out=$(python3 "$TOOL" index "$W/cat.xcassets" --out "$W/out" 2>&1); rc=$?
if [ $rc -eq 2 ] && grep -q "unknown .* key 'wibble'" <<<"$out"; then
    ok "exit $rc, refused on the unknown key by name"
else
    bad "expected a refusal on 'wibble'; got exit $rc: $(head -2 <<<"$out")"
fi

echo "== TOOTH 3: an unknown VALUE in a known key must REFUSE"
fresh
victim=$(victim_colorset)
python3 - "$victim" <<'PY'
import json,sys
d=json.load(open(sys.argv[1])); d["colors"][0]["idiom"]="toaster"
json.dump(d,open(sys.argv[1],'w'))
PY
out=$(python3 "$TOOL" index "$W/cat.xcassets" --out "$W/out" 2>&1); rc=$?
if [ $rc -eq 2 ] && grep -q "unknown idiom value 'toaster'" <<<"$out"; then
    ok "exit $rc, refused on the unknown value by name"
else
    bad "expected a refusal on 'toaster'; got exit $rc: $(head -2 <<<"$out")"
fi

echo "== TOOTH 4: an entry naming a file that is not there must REFUSE"
IMG=$(find "$CORPUS/Hackers" -name 'Images.xcassets' -type d | head -1)
rm -rf "$W/cat2.xcassets" "$W/out"; cp -R "$IMG" "$W/cat2.xcassets"
gone=$(find "$W/cat2.xcassets" -name '*.png' | head -1)
if [ -n "$gone" ]; then
    rm -f "$gone"
    out=$(python3 "$TOOL" index "$W/cat2.xcassets" --out "$W/out" 2>&1); rc=$?
    if [ $rc -eq 2 ] && grep -q "not in the asset directory" <<<"$out"; then
        ok "exit $rc, refused naming the missing payload"
    else
        bad "expected a refusal on the missing payload; got exit $rc: $(head -2 <<<"$out")"
    fi
else
    bad "no png to remove in $IMG"
fi

echo "== TOOTH 5: a PLANTED WRONG VARIANT must fail the spot oracle"
# Swap the light and dark filenames inside one imageset.  Everything still
# parses, every file is still present, the accounting identity still holds, and
# the round trip is still byte-perfect: ONLY the oracle can see this.
rm -rf "$W/plant" "$W/plantwork"; mkdir -p "$W/plant"
CAND=$(grep -rl '"value" : "dark"' "$CORPUS" --include=Contents.json 2>/dev/null \
       | grep '\.imageset/' | head -40 | while read -r c; do
           n=$(python3 - "$c" <<'PY'
import json,sys
try: d=json.load(open(sys.argv[1]))
except Exception: sys.exit(1)
im=[e for e in d.get("images",[]) if e.get("filename")]
dark=[e for e in im if any(a.get("value")=="dark" for a in e.get("appearances",[]))]
lite=[e for e in im if not e.get("appearances")]
print(1 if (dark and lite and dark[0]["filename"]!=lite[0]["filename"]) else 0)
PY
)
           [ "$n" = "1" ] && { echo "$c"; break; }
       done)
if [ -z "$CAND" ]; then
    bad "found no imageset with distinct light and dark filenames to plant into"
else
    CATDIR=$(python3 -c "import sys,os;p=sys.argv[1]
while not p.endswith('.xcassets'): p=os.path.dirname(p)
print(p)" "$CAND")
    cp -R "$CATDIR" "$W/plant/cat.xcassets"
    REL=${CAND#"$CATDIR"/}
    V="$W/plant/cat.xcassets/$REL"
    echo "   planting into $REL"
    python3 - "$V" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p))
im=[e for e in d["images"] if e.get("filename")]
dark=next(e for e in im if any(a.get("value")=="dark" for a in e.get("appearances",[])))
lite=next(e for e in im if not e.get("appearances"))
dark["filename"], lite["filename"] = lite["filename"], dark["filename"]
json.dump(d, open(p,'w'), indent=2)
print("   swapped light/dark filenames")
PY
    out=$(python3 "$HERE/spot_oracle.py" "$W/plant" "$W/plantwork" 2>&1); rc=$?
    # the planted catalog is not in a git clone, so point the oracle at it directly
    if grep -q "no .xcassets" <<<"$out" || [ -z "$out" ]; then
        mkdir -p "$W/plantapp/.git" && mv "$W/plant/cat.xcassets" "$W/plantapp/" 2>/dev/null
        rm -rf "$W/plantwork"
        out=$(python3 "$HERE/spot_oracle.py" "$W" "$W/plantwork" --apps plantapp 2>&1); rc=$?
    fi
    if [ $rc -ne 0 ] && grep -qE "only in the tool|only in actool" <<<"$out"; then
        n=$(grep -cE "^ +(IMAGE only)" <<<"$out")
        ok "the oracle FAILED (exit $rc) and named the swapped rows"
        grep -E "IMAGE only" <<<"$out" | head -4 | sed 's/^/       /'
    else
        bad "the oracle did not catch a swapped light/dark pair; exit $rc"
        head -20 <<<"$out" | sed 's/^/       /'
    fi
fi

echo ""
echo "teeth passed $pass, failed $fail"
[ "$fail" -eq 0 ]
