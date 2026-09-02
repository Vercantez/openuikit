#!/bin/sh
# Poll Cursor cloud agents until every one reaches a terminal state, then exit.
# Usage: wait_agents.sh AGENT_ID [AGENT_ID...]
# Prints one line per poll per still-running agent, and a final report.
# Exit 0 when all finished; exit 1 if any ended in ERROR/EXPIRED.
set -eu
repo_root=$(cd "$(dirname "$0")/../.." && pwd)
[ $# -ge 1 ] || { echo "usage: wait_agents.sh AGENT_ID..." >&2; exit 2; }
if [ -z "${CURSOR_API_KEY:-}" ] && [ -f "$repo_root/.env" ]; then
    CURSOR_API_KEY=$(sed -n 's/^CURSOR_API_KEY=//p' "$repo_root/.env" | tail -1)
fi
[ -n "${CURSOR_API_KEY:-}" ] || { echo "wait-agents: no CURSOR_API_KEY" >&2; exit 2; }

INTERVAL=${WAIT_INTERVAL:-150}
DEADLINE=$(( $(date +%s) + ${WAIT_MAX_SECONDS:-14400} ))
bad=0
pending="$*"
while :; do
    still=""
    for id in $pending; do
        out=$(curl -sS -H "Authorization: Bearer $CURSOR_API_KEY" "https://api.cursor.com/v0/agents/$id" || echo '{}')
        line=$(printf '%s' "$out" | python3 -c '
import json,sys
try: d=json.load(sys.stdin)
except Exception: d={}
st=d.get("status","UNKNOWN")
pr=(d.get("target") or {}).get("prUrl","")
print(st+"\t"+(d.get("name") or "?")+"\t"+pr)')
        st=${line%%	*}
        printf '%s  %s  %s\n' "$(date +%H:%M:%S)" "$id" "$line"
        case "$st" in
            FINISHED) ;;
            ERROR|EXPIRED|CANCELLED) bad=1 ;;
            *) still="$still $id" ;;
        esac
    done
    pending=$still
    [ -n "$pending" ] || break
    [ "$(date +%s)" -lt "$DEADLINE" ] || { echo "wait-agents: deadline reached with agents still running:$pending"; exit 3; }
    sleep "$INTERVAL"
done
echo "wait-agents: all agents terminal (bad=$bad)"
exit $bad
