#!/bin/bash
# build_corpus.sh -- regenerate the committed corpus and golden from scratch.
#
#     ./build_corpus.sh <clone-dir> [<date>]
#
# <clone-dir> must contain the four shallow clones the model census names:
#
#     git clone --depth 1 https://github.com/artsy/eidolon           eidolon
#     git clone --depth 1 https://github.com/duckduckgo/iOS          iOS
#     git clone --depth 1 https://github.com/kickstarter/ios-oss     ios-oss
#     git clone --depth 1 https://github.com/Automattic/pocket-casts-ios pocket-casts-ios
#
# THE CORPUS IS NOT BYTE-REPRODUCIBLE and saying so is more useful than
# pretending: the clones are HEAD, so a later run harvests later commits and
# the document set moves.  What IS reproducible is the METHOD -- the selection
# rule, the quotas and the feature fingerprint are all in `harvest_json.py`,
# and the committed corpus carries every document's `origin`.  The golden, in
# contrast, is a pure function of the corpus plus the macOS Foundation on the
# machine, and its `macos` field records which one.
set -euo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only: the golden comes from real Foundation" >&2; exit 1; }
CLONES=${1:?usage: build_corpus.sh <clone-dir> [date]}
DATE=${2:-$(date +%F)}
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

python3 "$HERE/harvest_json.py" "$CLONES" "$WORK/real.json"
python3 "$HERE/gen_synthetic.py" "$WORK/syn.json"
python3 - "$WORK/real.json" "$WORK/syn.json" "$HERE/json-corpus-$DATE.json" <<'PY'
import json, sys
real = json.load(open(sys.argv[1]))
syn = json.load(open(sys.argv[2]))
json.dump(real + syn, open(sys.argv[3], "w"), indent=1, sort_keys=True)
print("corpus: %d real + %d synthetic = %d documents, %d raw bytes"
      % (len(real), len(syn), len(real) + len(syn),
         sum(d["bytes"] for d in real + syn)))
PY

xcrun swiftc -O -D ORACLE_BUILD -o "$WORK/json_oracle" \
    "$HERE/json_canon.swift" "$HERE/json_probes.swift" "$HERE/json_oracle.swift"
"$WORK/json_oracle" "$HERE/json-corpus-$DATE.json" > "$HERE/json-golden-$DATE.json"

# CHECK THE ARTIFACT, NOT THE EXIT STATUS.  A golden that is valid JSON and
# contains no documents is a successful run of a broken tool.
python3 - "$HERE/json-corpus-$DATE.json" "$HERE/json-golden-$DATE.json" <<'PY'
import json, sys
c = json.load(open(sys.argv[1]))
g = json.load(open(sys.argv[2]))
assert len(g["docs"]) == len(c), "golden has %d rows for %d documents" % (len(g["docs"]), len(c))
assert len(g["probes"]) > 0, "no Codable probes in the golden"
assert all(r["id"] == d["id"] for r, d in zip(g["docs"], c)), "row order diverges from the corpus"
print("golden: %d rows, %d probes, generated %s on %s"
      % (len(g["docs"]), len(g["probes"]), g["generated"], g["macos"]))
PY
echo "== wrote $HERE/json-corpus-$DATE.json and $HERE/json-golden-$DATE.json"
