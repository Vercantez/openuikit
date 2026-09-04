#!/bin/zsh
# agent_merge.sh <branch> — the operator half of the fan-out: check an
# agent's branch the way a merge to main must be checked, merge it, advance
# the uikit vendor pin, and push.
#
#   uikit/scripts/agent_merge.sh agent/attrtext-paragraph
#   CHECK_ONLY=1 uikit/scripts/agent_merge.sh nav-large-titles   # no merge
#
# Checks (all must pass, in a temporary worktree of the MERGED tree):
#   - swift build of openrender; Catalyst gate 109/109 (or the agent's new
#     total if it added goldens — the script prints the count);
#   - the real-app screens do not drop below 99.0 / 98.4 / 98.4;
#   - Linux build in swift:6.2-noble;
#   - the agent touched nothing outside uikit/ and none of the pin files.
# Then: git merge --no-ff, pin advance (scripts/vendor_pins.sh,
# env/contract.json, scripts/env/test_contract.py), test_contract,
# test_vendor_tree (chained on the attestation line), push.
set -e
cd "$(dirname "$0")/../.."          # monorepo root
ROOT=$(pwd)
BR=${1:?usage: agent_merge.sh <branch>}
git fetch -q origin 2>/dev/null || true
git rev-parse --verify -q "$BR" >/dev/null || BR="origin/$BR"
git rev-parse --verify -q "$BR" >/dev/null || { echo "no such branch: $1" >&2; exit 2 }
echo "==> $BR: $(git log --oneline -1 "$BR")"
echo "==> files changed vs main:"
git diff --stat main..."$BR" | tail -15
if git diff --name-only main..."$BR" | grep -vE '^uikit/' | grep -q .; then
  echo "REFUSED: the branch touches files outside uikit/:"; git diff --name-only main..."$BR" | grep -vE '^uikit/'; exit 3
fi
if git diff --name-only main..."$BR" | grep -qE '^(scripts/vendor_pins.sh|env/|scripts/env/)'; then
  echo "REFUSED: the branch touches the pin files"; exit 3
fi

WT=$(mktemp -d /tmp/agent_merge.XXXX)
git worktree add -q --detach "$WT" main
trap 'git -C "$WT" merge --abort 2>/dev/null; git worktree remove --force "$WT" 2>/dev/null' EXIT
git -C "$WT" merge -q --no-ff --no-commit "$BR" || { echo "MERGE CONFLICT with main"; exit 4 }
cd "$WT/uikit"
echo "==> macOS build + Catalyst gate"
swift build -c release --product openrender 2>&1 | grep -E 'error|Build of' | tail -3
rm -rf /tmp/agent_merge_gate; ./.build/release/openrender render /tmp/agent_merge_gate fixtures/scenes/*.json >/dev/null
python3 Tools/compare/compare.py --out /tmp/agent_merge_gate 2>&1 | grep -E '^FAIL|scenes pass' | tail -5
python3 Tools/compare/compare.py --out /tmp/agent_merge_gate 2>&1 | grep -q '^FAIL' && { echo "GATE RED"; exit 5 }
echo "==> real-app screens"
rm -rf /tmp/agent_merge_app; OPENUIKIT_REALAPP_SCALE=3 OPENUIKIT_FORCE_IOS=1 ./.build/release/openrender realapp /tmp/agent_merge_app >/dev/null
python3 Tools/compare/compare_realapp.py --golden /tmp/golden_realapp_ios --out /tmp/agent_merge_app --scale 3 2>&1 | grep pixels | cut -c1-80
python3 - <<'PY' || exit 6
import re, subprocess
out = subprocess.run(['python3', 'Tools/compare/compare_realapp.py', '--golden', '/tmp/golden_realapp_ios', '--out', '/tmp/agent_merge_app', '--scale', '3'], capture_output=True, text=True).stdout
floors = {'realapp_history_light': 99.0, 'realapp_settings_light': 98.4, 'realapp_settings_dark': 98.4}
for name, floor in floors.items():
    m = re.search(name + r".*?'score': np\.float64\(([\d.]+)\)", out)
    if not m or float(m.group(1)) < floor: raise SystemExit(f'REAL APP DROPPED: {name} {m.group(1) if m else "?"} < {floor}')
PY
echo "==> Linux build"
docker run --rm -v "$WT/uikit":/src:ro swift:6.2-noble bash -c 'cp -r /src /work && cd /work && rm -f Package.resolved && swift build -c release --product openrender 2>&1 | grep -E "error|Build of" | tail -3' | tail -3
docker run --rm -v "$WT/uikit":/src:ro swift:6.2-noble bash -c 'cp -r /src /work && cd /work && rm -f Package.resolved && swift build -c release --product openrender >/dev/null 2>&1' || { echo "LINUX BUILD RED"; exit 7 }
cd "$WT" && git merge --abort 2>/dev/null || true
cd "$ROOT"
[[ -n "${CHECK_ONLY:-}" ]] && { echo "checks passed (CHECK_ONLY)"; exit 0 }

echo "==> merging into main"
git checkout -q main && git merge --no-ff -q -m "Merge $BR (agent fan-out; checked by scripts/agent_merge.sh)" "$BR"
OLD=$(grep -o 'EXPECTED_INREPO_UIKIT_TREE=[0-9a-f]*' scripts/vendor_pins.sh | cut -d= -f2); NEW=$(git rev-parse HEAD:uikit)
sed -i "s/$OLD/$NEW/" scripts/vendor_pins.sh env/contract.json scripts/env/test_contract.py
python3 scripts/env/test_contract.py 2>&1 | tail -1
rm -f uikit/Package.resolved uikit/1
bash scripts/test_vendor_tree.sh 2>&1 | grep -q VENDOR_TREE_ATTESTATION_OK || { echo "VENDOR TREE ATTESTATION FAILED — fix before pushing"; exit 8 }
git add scripts/vendor_pins.sh env/contract.json scripts/env/test_contract.py
git commit -q -m "Advance the uikit vendor pin and env contract after merging $BR

EXPECTED_INREPO_UIKIT_TREE $OLD -> $NEW."
git push -q origin main && git log --oneline -3 | cat
echo "merged and pushed; run the Linux authorities for $(git rev-parse --short HEAD)"
