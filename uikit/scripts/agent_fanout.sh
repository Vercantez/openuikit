#!/bin/zsh
# agent_fanout.sh <tasks.txt> [max-parallel] — run one LOCAL Cursor agent
# (cursor-agent CLI, non-interactive) per task line, each in its own git
# worktree and branch, with its own simulator devices, briefed by
# docs/AGENT_BRIEF_ORACLE.md + the task text.
#
# tasks.txt: one task per line, "name|model|task text" (# comments allowed).
#   nav-large-titles|claude-opus-5-thinking-high|Fix the large title ...
#
# Each agent:
#   - works in ~/.cursor/worktrees/openuikit/<name> on branch agent/<name>
#     based on origin/main (cursor-agent --worktree), trusted, --force
#     (runs commands without prompting), --print (non-interactive);
#   - gets SIM_DEVICE_SUFFIX=-<name> so its simulator devices are private;
#   - logs to scratch/agents/<name>.log (the monorepo's gitignored scratch/).
#
#   scripts/agent_fanout.sh scripts/agent_tasks.txt 3
#
# Merging, pin advances and the Linux authorities stay with the operator.
set -e
cd "$(dirname "$0")/../.."          # monorepo root
TASKS=${1:?usage: agent_fanout.sh <tasks.txt> [max-parallel]}
MAXPAR=${2:-3}
BRIEF=uikit/docs/AGENT_BRIEF_ORACLE.md
mkdir -p scratch/agents
command -v cursor-agent >/dev/null || { echo "cursor-agent not on PATH" >&2; exit 2 }
cursor-agent status >/dev/null 2>&1 || { echo "cursor-agent is not logged in (cursor-agent login)" >&2; exit 2 }

running=0
while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  name=${line%%|*}; rest=${line#*|}; model=${rest%%|*}; task=${rest#*|}
  prompt="$(cat "$BRIEF")

$task

Environment: AGENT=$name, SIM_DEVICE_SUFFIX=-$name (already exported). Work from the uikit/ directory of this worktree. Push your branch (agent/$name) to origin when done."
  echo "==> launching $name ($model)"
  (
    export AGENT="$name" SIM_DEVICE_SUFFIX="-$name"
    cursor-agent -p --force --trust --model "$model" --worktree "$name" --worktree-base origin/main \
      --output-format text "$prompt" > "scratch/agents/$name.log" 2>&1
    echo "AGENT_DONE rc=$?" >> "scratch/agents/$name.log"
  ) &
  running=$((running + 1))
  # zsh has no `wait -n`: poll the job table until a slot frees up.
  while (( running >= MAXPAR )); do
    sleep 15
    running=$(jobs -r | wc -l | tr -d ' ')
  done
done < "$TASKS"
wait
echo "all agents finished; logs in scratch/agents/, branches agent/<name> (git worktree list)"
