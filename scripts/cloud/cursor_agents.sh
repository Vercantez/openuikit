#!/bin/sh
# Launch and manage Cursor cloud (background) agents against this monorepo.
#
#   scripts/cloud/cursor_agents.sh verify              check the API key works
#   scripts/cloud/cursor_agents.sh launch "PROMPT"     start one agent on main
#   scripts/cloud/cursor_agents.sh launch-file F.md    start one agent, prompt from file
#   scripts/cloud/cursor_agents.sh list                list recent agents
#   scripts/cloud/cursor_agents.sh status AGENT_ID     one agent's status
#
# The key is read from $CURSOR_API_KEY, else from .env at the repo root
# (CURSOR_API_KEY=...). .env is gitignored; never commit the key.
#
# Model policy (deliberate): cursor-grok-4.6-high — high effort, NON-fast.
# Override per launch with CURSOR_MODEL=... if a task warrants it.
set -eu

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
API=https://api.cursor.com
MODEL=${CURSOR_MODEL:-cursor-grok-4.6-high}
REPO_URL=${CURSOR_REPO:-https://github.com/Vercantez/openuikit}
REF=${CURSOR_REF:-main}

if [ -z "${CURSOR_API_KEY:-}" ] && [ -f "$repo_root/.env" ]; then
    CURSOR_API_KEY=$(sed -n 's/^CURSOR_API_KEY=//p' "$repo_root/.env" | tail -1)
fi
[ -n "${CURSOR_API_KEY:-}" ] || {
    echo "cursor-agents: no CURSOR_API_KEY in env or $repo_root/.env" >&2
    echo "cursor-agents: create one at cursor.com/dashboard -> API Keys" >&2
    exit 2
}

auth() { curl -sS -H "Authorization: Bearer $CURSOR_API_KEY" -H 'Content-Type: application/json' "$@"; }

cmd=${1:-}; shift 2>/dev/null || true
case "$cmd" in
verify)
    # /v0/me identifies the key; failure prints the API's own error.
    auth "$API/v0/me" | python3 -m json.tool
    ;;
launch|launch-file)
    if [ "$cmd" = launch-file ]; then
        [ -f "${1:-}" ] || { echo "cursor-agents: prompt file missing" >&2; exit 2; }
        prompt=$(cat "$1")
    else
        prompt=${1:-}
    fi
    [ -n "$prompt" ] || { echo "cursor-agents: empty prompt refused" >&2; exit 2; }
    payload=$(python3 - "$prompt" "$MODEL" "$REPO_URL" "$REF" <<'PY'
import json, sys
prompt, model, repo, ref = sys.argv[1:5]
print(json.dumps({
    "prompt": {"text": prompt},
    "model": model,
    "source": {"repository": repo, "ref": ref},
    "target": {"autoCreatePr": True},
}))
PY
)
    out=$(auth -X POST "$API/v0/agents" -d "$payload")
    echo "$out" | python3 -m json.tool
    echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("LAUNCHED", d.get("id","?"), "model='"$MODEL"'")' || true
    ;;
list)
    auth "$API/v0/agents?limit=${1:-20}" | python3 -m json.tool
    ;;
status)
    [ -n "${1:-}" ] || { echo "cursor-agents: agent id required" >&2; exit 2; }
    auth "$API/v0/agents/$1" | python3 -m json.tool
    ;;
*)
    sed -n '2,15p' "$0"; exit 2 ;;
esac
