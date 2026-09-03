#!/usr/bin/env bash
# Merge-gate the operator has been running by hand per PR.
#
#   scripts/ops/premerge.sh <pr-number>
#
# Worktree the PR merged with origin/main, run scripts/env/test_contract.py,
# advance the machorun/uikit vendor pin (sed the three files, commit
# "Advance the machorun vendor pin…") when those subtrees changed, run
# scripts/test_vendor_tree.sh in that case, run test scripts named in the PR
# body, print a one-line verdict.
set -euo pipefail

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
# shellcheck source=common.inc
. "$HERE/common.inc"
ROOT=$(ops_root)

usage() {
    echo "usage: scripts/ops/premerge.sh <pr-number>" >&2
    exit 2
}
[ $# -eq 1 ] || usage
PR=$1
case "$PR" in
    *[!0-9]*) usage ;;
esac

json=$(ops_gh pr view "$PR" --json number,title,body,baseRefName)
body=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["body"] or "")' <<<"$json")

WT=${OPENUIKIT_PREMERGE_WORKDIR:-}
OWN_WT=0
SKIP_GIT=${OPENUIKIT_PREMERGE_SKIP_GIT:-0}

if [ "$SKIP_GIT" = 1 ]; then
    [ -n "$WT" ] || { echo "premerge: OPENUIKIT_PREMERGE_WORKDIR required with SKIP_GIT" >&2; exit 2; }
else
    if [ -z "$WT" ]; then
        WT=$(mktemp -d /tmp/openuikit-premerge-$PR.XXXXXX)
        OWN_WT=1
    fi
    cleanup() {
        if [ "$OWN_WT" -eq 1 ]; then
            git -C "$ROOT" worktree remove --force "$WT" 2>/dev/null || rm -rf "$WT"
        fi
    }
    trap cleanup EXIT
    git -C "$ROOT" fetch origin main
    git -C "$ROOT" fetch origin "pull/$PR/head:premerge-pr-$PR"
    if [ "$OWN_WT" -eq 1 ]; then
        git -C "$ROOT" worktree add --detach "$WT" origin/main
    fi
    git -C "$WT" merge --no-edit "premerge-pr-$PR" \
        || git -C "$WT" merge --no-edit "FETCH_HEAD"
fi

fail=0
notes=

run() {
    local label=$1
    shift
    echo "== premerge: $label" >&2
    if ( cd "$WT" && "$@" ); then
        notes="${notes:+$notes,}ok:$label"
        return 0
    fi
    fail=$((fail + 1))
    notes="${notes:+$notes,}FAIL:$label"
    return 1
}

run test_contract python3 scripts/env/test_contract.py || true

changed=${OPENUIKIT_PREMERGE_CHANGED:-}
if [ -z "$changed" ]; then
    changed=$(git -C "$WT" diff --name-only origin/main...HEAD || git -C "$WT" diff --name-only origin/main || true)
fi
machorun_uikit=0
echo "$changed" | grep -q '^machorun/' && machorun_uikit=1
echo "$changed" | grep -q '^uikit/' && machorun_uikit=1

if [ "$machorun_uikit" -eq 1 ]; then
    live_mr=$(git -C "$WT" rev-parse HEAD:machorun)
    live_uk=$(git -C "$WT" rev-parse HEAD:uikit)
    pin_mr=$(sed -n 's/^EXPECTED_INREPO_MACHORUN_TREE=//p' "$WT/scripts/vendor_pins.sh")
    pin_uk=$(sed -n 's/^EXPECTED_INREPO_UIKIT_TREE=//p' "$WT/scripts/vendor_pins.sh")
    if [ "$live_mr" != "$pin_mr" ] || [ "$live_uk" != "$pin_uk" ]; then
        echo "== premerge: advancing vendor pins machorun $pin_mr->$live_mr uikit $pin_uk->$live_uk" >&2
        python3 - "$WT/scripts/vendor_pins.sh" "$live_mr" "$live_uk" <<'PY'
from pathlib import Path
import re, sys
path, mr, uk = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
text = path.read_text(encoding="utf-8")
text = re.sub(r"^EXPECTED_INREPO_MACHORUN_TREE=.*$", "EXPECTED_INREPO_MACHORUN_TREE=" + mr, text, count=1, flags=re.M)
text = re.sub(r"^EXPECTED_INREPO_UIKIT_TREE=.*$", "EXPECTED_INREPO_UIKIT_TREE=" + uk, text, count=1, flags=re.M)
path.write_text(text, encoding="utf-8")
PY
        python3 - "$WT/env/contract.json" "$live_mr" "$live_uk" <<'PY'
import json, sys
path, mr, uk = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.loads(open(path, encoding="utf-8").read())
for row in data["checkouts"]:
    if row["id"] == "machorun-inrepo":
        row["tree"] = mr
    if row["id"] == "uikit-inrepo":
        row["tree"] = uk
open(path, "w", encoding="utf-8").write(json.dumps(data, indent=2) + "\n")
PY
        python3 - "$WT/scripts/env/test_contract.py" "$live_mr" "$live_uk" <<'PY'
from pathlib import Path
import re, sys
path, mr, uk = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
text = path.read_text(encoding="utf-8")
text = re.sub(
    r'(checkouts\["machorun-inrepo"\]\["tree"\],\s*\n\s*")([0-9a-f]+)(")',
    r"\g<1>" + mr + r"\g<3>",
    text,
    count=1,
)
text = re.sub(
    r'(checkouts\["uikit-inrepo"\]\["tree"\],\s*\n\s*")([0-9a-f]+)(")',
    r"\g<1>" + uk + r"\g<3>",
    text,
    count=1,
)
path.write_text(text, encoding="utf-8")
PY
        if [ "$SKIP_GIT" != 1 ]; then
            git -C "$WT" add scripts/vendor_pins.sh env/contract.json scripts/env/test_contract.py
            git -C "$WT" commit -m "Advance the machorun vendor pin and env contract to the merged tree"
        fi
        notes="${notes:+$notes,}pin-advanced"
    fi
    run test_vendor_tree bash scripts/test_vendor_tree.sh || true
fi

# PR body names its own test scripts. Run those that exist in the worktree.
while IFS= read -r script; do
    [ -n "$script" ] || continue
    [ -f "$WT/$script" ] || continue
    case "$script" in
        *tests/acceptance/test_host.sh|*/difftest.sh|*/build.sh|*build_fixtures_linux*|*scoreboard*)
            # (difftest/build/fixture/scoreboard scripts are Linux-only too:
            # measured 2026-09-03, PR #103 difftest printed PASS (exit 1) on
            # macOS with no build dirs at all.)
            # A framework lane's acceptance gate needs the Linux toolchain
            # (swift 6.2.4 linux, ld64.lld-18). On macOS it cannot run and
            # must not read as FAIL (measured 2026-09-03: PR #75 CoreMotion
            # graded FAIL here while its Linux VM printed
            # FRAMEWORK_FANOUT_HOST_OK). Grade it on a Linux box
            # (lane gate) or from the PR's quoted marker lines.
            if [ "$(uname -s)" = Linux ]; then
                run "pr:$script" bash "$script" || true
            else
                NOTES="${NOTES:+$NOTES,}needs-linux:pr:$script"
            fi
            ;;
        *.py) run "pr:$script" python3 "$script" || true ;;
        *.sh) run "pr:$script" bash "$script" || true ;;
        *) run "pr:$script" "$script" || true ;;
    esac
done < <(python3 -c '
import re, sys
body = sys.stdin.read()
seen = []
for m in re.finditer(r"(?:bash\s+)?((?:scripts|full)/[\w./-]*test[\w./-]*(?:\.sh|\.py))", body):
    p = m.group(1)
    if p not in seen:
        seen.append(p)
        print(p)
' <<<"$body")

if [ "$fail" -eq 0 ]; then
    printf 'PREMERGE pr=%s verdict=PASS notes=%s\n' "$PR" "${notes:-none}"
    exit 0
fi
printf 'PREMERGE pr=%s verdict=FAIL notes=%s\n' "$PR" "${notes:-none}"
exit 1
