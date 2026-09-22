#!/usr/bin/env bash
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
SELF=$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")
cd "$(dirname "$0")/../.."          # monorepo root
GATE_T0=$(date +%s)
stage() { echo "==> $* [+$(( $(date +%s) - GATE_T0 ))s]"; }
# One merge at a time: several waiters once launched merges into main together.
# Only a REAL merge takes the lock (for its whole run, so what it checked is
# what it merges); CHECK_ONLY runs never touch main and run concurrently, each
# in its own scratch root. A lock whose recorded owner is dead is stale
# (2026-09-17: two merges slept 38 min and 3 h on locks left by finished
# operator chains); reclaim it.
MERGE_LOCK=${GATE_LOCK:-/tmp/agent_merge.lock}
HAVE_LOCK=""
take_lock() {
  [ -n "$HAVE_LOCK" ] && return 0
  until mkdir "$MERGE_LOCK" 2>/dev/null; do
    lock_pid=$(cat "$MERGE_LOCK/pid" 2>/dev/null)
    if [ -n "$lock_pid" ] && ! kill -0 "$lock_pid" 2>/dev/null; then rm -rf "$MERGE_LOCK"; continue; fi
    sleep 30
  done
  echo $$ > "$MERGE_LOCK/pid"   # the holder; a monitor removes the lock only when this pid is dead
  HAVE_LOCK=1
}
drop_lock() {
  [ -n "$HAVE_LOCK" ] || return 0
  [ "$(cat "$MERGE_LOCK/pid" 2>/dev/null)" = "$$" ] && rm -rf "$MERGE_LOCK"
  HAVE_LOCK=""
}
[[ -n "${CHECK_ONLY:-}" ]] || take_lock
trap 'drop_lock' EXIT INT TERM HUP
ROOT=$(pwd)
NAME=${1:?usage: agent_merge.sh <branch>}
git fetch -q origin 2>/dev/null || true
# Resolve the agent branch FIRST: `cursor-agent --worktree <name>` also leaves
# a local base branch called <name> at the commit the agent started from —
# already in main — and a bare-name lookup once matched that, checked main
# against itself and "merged" nothing (false green #439).
BR=""
for cand in "agent/$NAME" "$NAME" "origin/agent/$NAME" "origin/$NAME"; do
  git rev-parse --verify -q "$cand" >/dev/null && { BR=$cand; break; }
done
[[ -n "$BR" ]] || { echo "no such branch: $NAME" >&2; exit 2; }
ADDS=$(git rev-list --count main.."$BR")
stage "$BR: $(git log --oneline -1 "$BR") — $ADDS commit(s) over main"
[ "$ADDS" -gt 0 ] || { echo "REFUSED: $BR adds no commits over main (stale base branch?)"; exit 3; }
stage "files changed vs main:"
git diff --stat main..."$BR" | tail -15
# ALLOW_PATHS='^full/foundation/|^full/scripts/build_full\.sh$' widens the scope for
# a named task (the guest Foundation, the guest builder); pin files stay refused.
if git diff --name-only main..."$BR" | grep -vE '^uikit/' | grep -vE "${ALLOW_PATHS:-^$}" | grep -q .; then
  echo "REFUSED: the branch touches files outside uikit/ (and outside ALLOW_PATHS):"; git diff --name-only main..."$BR" | grep -vE '^uikit/' | grep -vE "${ALLOW_PATHS:-^$}"; exit 3
fi
if git diff --name-only main..."$BR" | grep -qE '^(scripts/vendor_pins.sh|env/|scripts/env/)'; then
  echo "REFUSED: the branch touches the pin files"; exit 3
fi
if git diff --name-only main..."$BR" | grep -qE 'Package\.resolved$|\.app/'; then
  echo "REFUSED: the branch commits Package.resolved or a probe .app bundle"; exit 3
fi
rm -f uikit/Package.resolved   # an untracked one in the operator's tree blocks the merge
# The Linux-hosted arm64-apple-macos GUEST route builds the LIBRARY (OpenUIKit,
# CQuartz) against the port's own Foundation (no DateFormatter / NumberFormatter
# / NSAttributedString ...); the Docker check below uses corelibs and cannot see
# that. Refuse the common traps in changed library sources; the arm64/x86
# authorities are the real check. Since the guest app path (build_full.sh
# "RealAppProbe (top-level + Vendored + ...)", APPINC) EVERY harness file under
# Sources/RealAppProbe — top-level, Vendored/, Focus/, Hackers/, *Modules/ —
# compiles against the core guest package's Foundation, which has all of these
# (carried Darwin goldens under full/foundation/tests), so the harness is no
# longer grepped (LedgerStore.swift was refused for a NumberFormatter the guest
# has). Comment lines do not count (a stub once said "not DateFormatter" and was
# refused).
if git diff main..."$BR" -- 'uikit/Sources/OpenUIKit/*.swift' 'uikit/Sources/CQuartz/*' \
   | grep -E '^\+' | grep -vE '^\+\s*//' | grep -qE 'DateFormatter|NumberFormatter|DateComponentsFormatter|ISO8601DateFormatter|NSRegularExpression|JSONSerialization'; then
  echo "REFUSED: the branch adds a Foundation API the guest LIBRARY route does not have (DateFormatter & co. in OpenUIKit/CQuartz) — use Calendar/DateComponents or the port's own formatting"; exit 3
fi

# An unguarded `import Foundation` in a LIBRARY source breaks the guest library
# route the same way (verify66 @ 302e119b: NSUbiquitousKeyValueStore.swift). The
# siblings guard it: `#if canImport(Foundation)` / `#elseif canImport(Foundation)`
# on the line before. Refuse an added `import Foundation` whose previous diff
# line does not name canImport(Foundation). Removed lines (`-…`) are not context:
# a guarded import that REPLACES `import struct Foundation.URL` was refused once.
if git diff main..."$BR" -- 'uikit/Sources/OpenUIKit/*.swift' 'uikit/Sources/CQuartz/*' \
   | awk '/^\+import Foundation$/ { if (prev !~ /canImport\(Foundation\)/) { bad=1 } } !/^-/ { prev=$0 } END { exit !bad }'; then
  echo "REFUSED: the branch adds an unguarded 'import Foundation' to a library source (guest library route has no Foundation module) — guard it with #if canImport(Foundation) like its siblings"; exit 3
fi

# Every run gets its own scratch root: its worktree ($S/wt) and every output
# (gate/, app/, conf-*/, *.log), so concurrent CHECK_ONLY runs cannot collide.
# GATE_SCRATCH=<dir> picks it (created if missing; should be empty).
# Stale temp worktrees from runs that died (disk full, killed) are 1.1 GB
# each; 25 of them once filled the disk. Reap the worktree of any scratch root
# whose recorded owner is dead, and whole roots older than GATE_KEEP_H (24) h.
for stale in /tmp/agent_gate.*/; do
  [ -d "$stale" ] || continue
  owner=$(cat "$stale/pid" 2>/dev/null || true)
  [ -n "$owner" ] && kill -0 "$owner" 2>/dev/null && continue
  if [ -d "$stale/wt" ]; then git worktree remove --force "$stale/wt" 2>/dev/null || rm -rf "$stale/wt"; fi
  [ -n "$(find "$stale" -maxdepth 0 -mmin +$(( ${GATE_KEEP_H:-24} * 60 )) 2>/dev/null)" ] && rm -rf "$stale"
done
# Legacy roots (/tmp/agent_merge.XXXX, one per pre-scratch run, which always
# held the lock for its whole run): only reaped when no live run holds the lock.
lock_pid=$(cat "$MERGE_LOCK/pid" 2>/dev/null || true)
if [ -n "$HAVE_LOCK" ] || [ -z "$lock_pid" ] || ! kill -0 "$lock_pid" 2>/dev/null; then
  for stale in /tmp/agent_merge.*/; do
    [ -d "$stale" ] || continue
    # the glob also matches the lock directory: the reaper deleted every run's own
    # lock a second after it was taken, so the lock never held (measured: a merge
    # running with /tmp/agent_merge.lock absent).
    [ "${stale%/}" = "$MERGE_LOCK" ] && continue
    [ "${stale%/}" = /tmp/agent_merge.lock ] && continue
    pgrep -f "agent_merge.*$stale" >/dev/null 2>&1 && continue
    git worktree remove --force "$stale" 2>/dev/null || rm -rf "$stale"
  done
fi
git worktree prune
if [ -n "${GATE_SCRATCH:-}" ]; then S=$GATE_SCRATCH; mkdir -p "$S"; else S=$(mktemp -d /tmp/agent_gate.XXXXXX); fi
S=$(cd "$S" && pwd -P)
echo $$ > "$S/pid"
WT=$S/wt
stage "scratch root $S (worktree, outputs, logs)"
git worktree add -q --detach "$WT" main
trap 'git -C "$WT" merge --abort 2>/dev/null; git worktree remove --force "$WT" 2>/dev/null; git worktree prune; drop_lock' EXIT INT TERM HUP
git -C "$WT" merge -q --no-ff --no-commit "$BR" || { echo "MERGE CONFLICT with main"; exit 4; }
cd "$WT/uikit"
# When /tmp has no simulator goldens (Linux merge box, or a wiped Mac),
# fall back to the committed snapshot. restore.sh leaves live /tmp captures
# alone and prints which source it used.
if [[ -d goldens/ios && -f goldens/ios/manifest.json ]]; then
  zsh scripts/goldens_restore.sh
fi
stage "macOS build + Catalyst gate"
swift build -c release --product openrender 2>&1 | grep -E 'error|Build of' | tail -3
rm -rf $S/gate; ./.build/release/openrender render $S/gate fixtures/scenes/*.json >/dev/null
python3 Tools/compare/compare.py --out $S/gate 2>&1 | grep -E '^FAIL|scenes pass' | tail -5
python3 Tools/compare/compare.py --out $S/gate 2>&1 | grep -q '^FAIL' && { echo "GATE RED"; exit 5; }
stage "guest library route (Foundation hidden)"
# The Docker/corelibs Linux build cannot see this: OpenUIKit is compiled
# against a Darwin sysroot with no Foundation.swiftmodule (rung b/c, build_full.sh).
# x86 cycle c4dce839 went red on unguarded NSNumber/URL/Data after the ladder
# merges. Refuse that class at merge time (Mac, under 10 minutes).
GUEST_ROUTE_OUT=$S/guest-route bash scripts/guest_route_check.sh
stage "test bundle builds (a keep-both on a test file once merged an unbalanced class)"
swift build --build-tests > $S/tests.log 2>&1 || { grep -E 'error:' $S/tests.log | head -5; echo "TEST BUNDLE RED"; exit 5; }
stage "real-app screens"
rm -rf $S/app; OPENUIKIT_REALAPP_SCALE=3 OPENUIKIT_FORCE_IOS=1 ./.build/release/openrender realapp $S/app >/dev/null
python3 Tools/compare/compare_realapp.py --golden /tmp/golden_realapp_ios --out $S/app --scale 3 2>&1 | grep pixels | cut -c1-80
GATE_S=$S python3 - <<'PY' || exit 6
import os, re, subprocess
out = subprocess.run(['python3', 'Tools/compare/compare_realapp.py', '--golden', '/tmp/golden_realapp_ios', '--out', os.environ['GATE_S'] + '/app', '--scale', '3'], capture_output=True, text=True).stdout
floors = {'realapp_history_light': 99.0, 'realapp_settings_light': 98.4, 'realapp_settings_dark': 98.4, 'realapp_storage_light': 99.0, 'realapp_settings_light_xs': 98.4, 'realapp_settings_light_xxxl': 98.0, 'realapp_settings_light_ax1': 97.0, 'realapp_settings_light_ipad': 99.4, 'realapp_history_light_ipad': 99.6, 'realapp_storage_light_ipad': 99.5, 'realapp_focus_settings_light': 80.2, 'realapp_hackers_feed_light': 84.4}
for name, floor in floors.items():
    m = re.search(name + r".*?'score': np\.float64\(([\d.]+)\)", out)
    if not m or float(m.group(1)) < floor: raise SystemExit(f'REAL APP DROPPED: {name} {m.group(1) if m else "?"} < {floor}')
PY
stage "conformance apps (SKIP_CAPTURE re-render against the last round's goldens)"
# Wave 12 merged a page-transition regression (Pager t600 98.9 -> 95.9) that
# the gate and the real-app floors cannot see. Every app the last round
# captured (/tmp/hc-conformance-<App>) is re-rendered from the merged tree
# and graded against scoreboard/latest.json: a passing row must stay at or
# above its bar, a failing row must not lose more than 0.5.
for app_dir in Sources/ConformanceApps/*/; do
  [ -d "$app_dir" ] || continue
  app=$(basename "$app_dir")
  [ -d /tmp/hc-conformance-$app/golden ] || { echo "   $app: no round capture, skipped"; continue; }
  rm -rf $S/conf-$app; cp -r /tmp/hc-conformance-$app $S/conf-$app
  # A branch that changes the PROBE (how a frame is named, what is dumped)
  # invalidates the round's goldens for that app: RECAPTURE_APPS="Pager Tabs"
# A recapture that comes back short (the iPad probe missed Tabs t6000 once:
# 7 of 8 goldens, scored 0.000 and refused as a fidelity drop) is a capture
# failure: re-run the flow once, then refuse as INCOMPLETE — never score it.
# With SKIP_CAPTURE=1 a short OURS set is a render failure and is refused as is.
frames_complete() { # <dir> <skip> <flow args...>
  local d=$1 skip=$2; shift 2
  local g o; g=$(ls "$d"/golden/*.png 2>/dev/null | wc -l | tr -d ' '); o=$(ls "$d"/ours/*.png 2>/dev/null | wc -l | tr -d ' ')
  [ "$g" = "$o" ] && return 0
  if [ "$skip" = 1 ]; then echo "RENDER INCOMPLETE: $d golden $g frame(s) vs ours $o"; return 1; fi
  echo "   $d: golden $g frame(s) vs ours $o — recapturing once"
  rm -rf "$d"
  bash scripts/conformance_flow.sh "$d" "$@" > "$d.log" 2>&1 || { echo "CONFORMANCE FLOW FAILED on retry: $d"; return 1; }
  g=$(ls "$d"/golden/*.png 2>/dev/null | wc -l | tr -d ' '); o=$(ls "$d"/ours/*.png 2>/dev/null | wc -l | tr -d ' ')
  [ "$g" = "$o" ] || { echo "RECAPTURE INCOMPLETE: $d golden $g frame(s) vs ours $o"; return 1; }
}
  # captures them again with the merged tree's probe before grading.
  skip=1
  for r in ${RECAPTURE_APPS:-}; do
    if [ "$r" = "$app" ]; then
      skip=""; rm -rf $S/conf-$app/golden
      echo "   $app: recapturing goldens with the merged probe"
    fi
  done
  SKIP_CAPTURE=$skip bash scripts/conformance_flow.sh $S/conf-$app $app > $S/conf-$app.log 2>&1 \
    || { echo "CONFORMANCE FLOW FAILED: $app (see $S/conf-$app.log)"; exit 9; }
  frames_complete $S/conf-$app "$skip" $app || exit 9
  if [ -d /tmp/hc-conformance-$app-ipad/golden ]; then
    rm -rf $S/conf-$app-ipad; cp -r /tmp/hc-conformance-$app-ipad $S/conf-$app-ipad
    skip_ipad=1
    for r in ${RECAPTURE_APPS:-}; do
      if [ "$r" = "$app" ] || [ "$r" = "$app-ipad" ]; then
        skip_ipad=""; rm -rf $S/conf-$app-ipad/golden
        echo "   $app-ipad: recapturing goldens with the merged probe"
      fi
    done
    SKIP_CAPTURE=$skip_ipad bash scripts/conformance_flow.sh $S/conf-$app-ipad $app --ipad > $S/conf-$app-ipad.log 2>&1 \
      || { echo "CONFORMANCE FLOW FAILED: $app --ipad (see $S/conf-$app-ipad.log)"; exit 9; }
  frames_complete $S/conf-$app-ipad "$skip_ipad" $app --ipad || exit 9
  fi
  if [ -d /tmp/hc-conformance-$app-dark/golden ]; then
    rm -rf $S/conf-$app-dark; cp -r /tmp/hc-conformance-$app-dark $S/conf-$app-dark
    skipd=1
    for r in ${RECAPTURE_APPS:-}; do
      if [ "$r" = "$app" ]; then
        skipd=""; rm -rf $S/conf-$app-dark/golden
        echo "   $app-dark: recapturing goldens with the merged probe"
      fi
    done
    SKIP_CAPTURE=$skipd bash scripts/conformance_flow.sh $S/conf-$app-dark $app --dark > $S/conf-$app-dark.log 2>&1 \
      || { echo "CONFORMANCE FLOW FAILED: $app --dark (see $S/conf-$app-dark.log)"; exit 9; }
  frames_complete $S/conf-$app-dark "$skipd" $app --dark || exit 9
  fi
  if [ -d /tmp/hc-conformance-$app-rtl/golden ]; then
    rm -rf $S/conf-$app-rtl; cp -r /tmp/hc-conformance-$app-rtl $S/conf-$app-rtl
    skipr=1
    for r in ${RECAPTURE_APPS:-}; do
      if [ "$r" = "$app" ]; then
        skipr=""; rm -rf $S/conf-$app-rtl/golden
        echo "   $app-rtl: recapturing goldens with the merged probe"
      fi
    done
    SKIP_CAPTURE=$skipr bash scripts/conformance_flow.sh $S/conf-$app-rtl $app --rtl > $S/conf-$app-rtl.log 2>&1 \
      || { echo "CONFORMANCE FLOW FAILED: $app --rtl (see $S/conf-$app-rtl.log)"; exit 9; }
  frames_complete $S/conf-$app-rtl "$skipr" $app --rtl || exit 9
  fi
  if [ -d /tmp/hc-conformance-$app-ax1/golden ]; then
    rm -rf $S/conf-$app-ax1; cp -r /tmp/hc-conformance-$app-ax1 $S/conf-$app-ax1
    skipax=1
    for r in ${RECAPTURE_APPS:-}; do
      if [ "$r" = "$app" ] || [ "$r" = "$app-ax1" ]; then
        skipax=""; rm -rf $S/conf-$app-ax1/golden
        echo "   $app-ax1: recapturing goldens with the merged probe"
      fi
    done
    SKIP_CAPTURE=$skipax bash scripts/conformance_flow.sh $S/conf-$app-ax1 $app --ax1 > $S/conf-$app-ax1.log 2>&1 \
      || { echo "CONFORMANCE FLOW FAILED: $app --ax1 (see $S/conf-$app-ax1.log)"; exit 9; }
  frames_complete $S/conf-$app-ax1 "$skipax" $app --ax1 || exit 9
  fi
  if [ -d /tmp/hc-conformance-$app-xxxl/golden ]; then
    rm -rf $S/conf-$app-xxxl; cp -r /tmp/hc-conformance-$app-xxxl $S/conf-$app-xxxl
    skipxx=1
    for r in ${RECAPTURE_APPS:-}; do
      if [ "$r" = "$app" ] || [ "$r" = "$app-xxxl" ]; then
        skipxx=""; rm -rf $S/conf-$app-xxxl/golden
        echo "   $app-xxxl: recapturing goldens with the merged probe"
      fi
    done
    SKIP_CAPTURE=$skipxx bash scripts/conformance_flow.sh $S/conf-$app-xxxl $app --xxxl > $S/conf-$app-xxxl.log 2>&1 \
      || { echo "CONFORMANCE FLOW FAILED: $app --xxxl (see $S/conf-$app-xxxl.log)"; exit 9; }
  frames_complete $S/conf-$app-xxxl "$skipxx" $app --xxxl || exit 9
  fi
  if [ -d /tmp/hc-conformance-$app-landscape/golden ]; then
    rm -rf $S/conf-$app-landscape; cp -r /tmp/hc-conformance-$app-landscape $S/conf-$app-landscape
    skipl=1
    for r in ${RECAPTURE_APPS:-}; do
      if [ "$r" = "$app" ]; then
        skipl=""; rm -rf $S/conf-$app-landscape/golden
        echo "   $app-landscape: recapturing goldens with the merged probe"
      fi
    done
    SKIP_CAPTURE=$skipl bash scripts/conformance_flow.sh $S/conf-$app-landscape $app --landscape > $S/conf-$app-landscape.log 2>&1 \
      || { echo "CONFORMANCE FLOW FAILED: $app --landscape (see $S/conf-$app-landscape.log)"; exit 9; }
  frames_complete $S/conf-$app-landscape "$skipl" $app --landscape || exit 9
  fi
done
GATE_S=$S python3 - <<'PY' || exit 9
import json, os, glob
board = {r["scene"]: r for r in json.load(open("scoreboard/latest.json"))["rows"] if r["category"] == "conformance"}
bad = []
for d in sorted(glob.glob(os.environ['GATE_S'] + "/conf-*")):
    if not os.path.isdir(d): continue
    s = json.load(open(os.path.join(d, "summary.json")))
    for cap in s["captures"]:
        name = f"{s['app']}:{cap['name']}"; score = float(cap["score"]); row = board.get(name)
        if row is None: continue
        if score == 0.0:
            # 0.000 is not a fidelity score: a missing frame or a size mismatch
            # (landscape keyboard-up frames once rendered portrait-sized and sat on
            # the board as 0.00). Refuse it by name, board value or not.
            if name in os.environ.get("ALLOW_DROP", "").split(): print(f"   {name}: 0.000 RENDER FAILED but ALLOWED (ALLOW_DROP)")
            else: bad.append(f"{name} RENDER FAILED (0.000: missing frame or size mismatch, was {row['score']:.3f})")
            continue
        if row["status"] == "pass" and score < row["threshold"]:
            # ALLOW_DROP also covers a passing row that a probe change turns honest
            # (both sides omitted an element before): named in the merge, never silent.
            if name in os.environ.get("ALLOW_DROP", "").split(): print(f"   {name}: {score:.3f} < bar {row['threshold']} (was {row['score']:.3f}) ALLOWED (ALLOW_DROP)")
            else: bad.append(f"{name} {score:.3f} < bar {row['threshold']} (was {row['score']:.3f})")
        elif score < row["score"] - 0.5:
            # ALLOW_DROP="Tabs:t6000 ..." names failing rows a merge may lower on purpose
            # (a measured interaction another branch owns); it must be said in the merge.
            if name in os.environ.get("ALLOW_DROP", "").split(): print(f"   {name}: {score:.3f} < {row['score']:.3f} ALLOWED (ALLOW_DROP)")
            else: bad.append(f"{name} {score:.3f} dropped from {row['score']:.3f}")
        print(f"   {name}: {score:.3f} (board {row['score']:.3f})")
if bad: raise SystemExit("CONFORMANCE DROPPED: " + "; ".join(bad))
PY
stage "Linux build"
docker run --rm -v "$WT/uikit":/src:ro swift:6.2-noble bash -c 'cp -r /src /work && cd /work && rm -f Package.resolved && swift build -c release --product openrender 2>&1 | grep -E "error|Build of" | tail -3' | tail -3
# openrender AND the ConformanceApps target (openhost needs SDL2, absent in the
# plain image): the Ledger app's DateComponentsFormatter (unavailable in corelibs)
# passed the openrender-only step and broke the Docker verify (#468). AND the test
# bundle: TextKitTests' bare `NotificationCenter` was ambiguous only on corelibs and
# reached main because only the Docker verify builds tests (verify83). Only the
# OpenUIKitTests target: --build-tests would also build openhost, whose CSDL2
# needs SDL2 (absent in the plain image).
docker run --rm -v "$WT/uikit":/src:ro swift:6.2-noble bash -c 'cp -r /src /work && cd /work && rm -f Package.resolved && swift build -c release --product openrender >/dev/null 2>&1 && swift build -c release --target ConformanceApps >/dev/null 2>&1 && swift build --target OpenUIKitTests 2>&1 | grep -E "error:" | head -5; test ${PIPESTATUS[0]} -eq 0' || { echo "LINUX BUILD RED"; exit 7; }
cd "$WT" && git merge --abort 2>/dev/null || true
cd "$ROOT"
[[ -n "${CHECK_ONLY:-}" ]] && { stage "checks passed (CHECK_ONLY)"; exit 0; }

stage "merging into main"
# SDK-depth framework merges (scratchpad fw_merge.sh) land on main concurrently
# under their own lock and never touch uikit/; sync main first so the push is a
# fast-forward, and if main still moved before the push, merge it once more.
git checkout -q main && git fetch -q origin && git merge -q --ff-only origin/main \
  && git merge --no-ff -q -m "Merge $BR (agent fan-out; checked by scripts/agent_merge.sh)" "$BR"
OLD=$(grep -o 'EXPECTED_INREPO_UIKIT_TREE=[0-9a-f]*' scripts/vendor_pins.sh | cut -d= -f2); NEW=$(git rev-parse HEAD:uikit)
sed -i "s/$OLD/$NEW/" scripts/vendor_pins.sh env/contract.json scripts/env/test_contract.py
python3 scripts/env/test_contract.py 2>&1 | tail -1
rm -f uikit/Package.resolved uikit/1
bash scripts/test_vendor_tree.sh 2>&1 | grep -q VENDOR_TREE_ATTESTATION_OK || { echo "VENDOR TREE ATTESTATION FAILED — fix before pushing"; exit 8; }
git add scripts/vendor_pins.sh env/contract.json scripts/env/test_contract.py
git commit -q -m "Advance the uikit vendor pin and env contract after merging $BR

EXPECTED_INREPO_UIKIT_TREE $OLD -> $NEW."
if ! git push -q origin main 2>/dev/null; then
  git fetch -q origin && git merge -q --no-edit origin/main && python3 scripts/env/test_contract.py >/dev/null 2>&1 && git push -q origin main || { echo "PUSH FAILED after re-merge"; exit 7; }
fi
git log --oneline -3 | cat
echo "merged and pushed; run the Linux authorities for $(git rev-parse --short HEAD)"
