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

# Fail-closed extra check for the two repos whose compile inputs are also
# pinned by full/foundation/pinned_inputs.pl (ignored-source teeth).
pinned_inputs=$repo_root/full/foundation/pinned_inputs.pl
if [ -f "$pinned_inputs" ] && [ ! -L "$pinned_inputs" ]; then
    perl "$pinned_inputs" verify \
        --swift-foundation "$repo_root/scratch/swift-foundation" \
        --swift-collections "$repo_root/scratch/swift-collections"
fi

printf 'CURSOR_SCRATCH_CORPUS_OK sources=%s/%s\n' "$ok" "$count"
