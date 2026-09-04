#!/usr/bin/env bash
# Install the public scratch corpus at the exact commit+tree pins.
# A failed clone leaves no destination tree (staging is discarded).

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
case "$repo_root" in ''|/) printf 'cursor-corpus: unsafe repository root\n' >&2; exit 1 ;; esac

lock=$repo_root/.cursor/scratch-corpus-pins.json
cloner=$repo_root/.cursor/clone-pinned-repo.sh
[ -f "$lock" ] && [ ! -L "$lock" ] || { printf 'cursor-corpus: pin lock is missing\n' >&2; exit 1; }
[ -f "$cloner" ] && [ ! -L "$cloner" ] || { printf 'cursor-corpus: cloner is missing\n' >&2; exit 1; }

mkdir -p "$repo_root/scratch"

ids=$(jq -er '.sources[].id' "$lock")
count=0
ok=0
while IFS= read -r id; do
    [ -n "$id" ] || continue
    count=$((count + 1))
    bash "$cloner" --lock "$lock" --id "$id" --repo-root "$repo_root"
    ok=$((ok + 1))
done <<EOF
$ids
EOF

[ "$count" -gt 0 ] || { printf 'cursor-corpus: pin lock named no sources\n' >&2; exit 1; }
[ "$ok" -eq "$count" ] || { printf 'cursor-corpus: cloned %s/%s sources\n' "$ok" "$count" >&2; exit 1; }

# ICU and CoreFoundation are locked by contract rows, not the corpus pin file
# (a checkout cannot be locked in two places). Destination/commit/tree come
# from env/contract.json via scripts/env/contract.py.
python3 - "$repo_root" "$cloner" <<'PY'
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(sys.argv[1])
cloner = Path(sys.argv[2])
sys.path.insert(0, str(root / "scripts"))
from env.contract import checkouts_by_id, load_contract

ids = ("swift-foundation-icu", "swift-corelibs-foundation")
by_id = checkouts_by_id(load_contract(root))
scratch = root / "scratch"
scratch.mkdir(parents=True, exist_ok=True)
cloned = 0
for ident in ids:
    row = by_id[ident]
    lock_dir = Path(
        tempfile.mkdtemp(prefix=".env-contract-lock.", dir=str(scratch))
    )
    lock = lock_dir / "lock.json"
    try:
        lock.write_text(
            json.dumps(
                {
                    "sources": [
                        {
                            "id": ident,
                            "repository": row["repository"],
                            "commit": row["commit"],
                            "tree": row["tree"],
                            "destination": row["destination"],
                        }
                    ]
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        subprocess.check_call(
            [
                "bash",
                str(cloner),
                "--lock",
                str(lock),
                "--id",
                ident,
                "--repo-root",
                str(root),
            ]
        )
        cloned += 1
    finally:
        shutil.rmtree(lock_dir, ignore_errors=True)
if cloned != len(ids):
    raise SystemExit("cursor-corpus: contract checkout clone count drifted")
print(f"CURSOR_CONTRACT_CHECKOUTS_OK cloned={cloned}/{len(ids)}", file=sys.stderr)
PY

# Fail-closed extra check for the two repos whose compile inputs are also
# pinned by full/foundation/pinned_inputs.pl (ignored-source teeth).
pinned_inputs=$repo_root/full/foundation/pinned_inputs.pl
if [ -f "$pinned_inputs" ] && [ ! -L "$pinned_inputs" ]; then
    perl "$pinned_inputs" verify \
        --swift-foundation "$repo_root/scratch/swift-foundation" \
        --swift-collections "$repo_root/scratch/swift-collections"
fi

printf 'CURSOR_SCRATCH_CORPUS_OK sources=%s/%s\n' "$ok" "$count"
