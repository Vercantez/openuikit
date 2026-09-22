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
#   - the conformance apps re-rendered against the goldens COMMITTED in the
#     merged tree (goldens/ios), refused when those goldens are stale or are
#     not the ones the board rows were graded against (golden_sha).
# Then: git merge --no-ff, pin advance (scripts/vendor_pins.sh,
# env/contract.json, scripts/env/test_contract.py), test_contract,
# test_vendor_tree (chained on the attestation line), push.
#
# Speed (docs/agent_reports/gate-speed.md), none of it skips a check:
#   - CHECK_ONLY runs take no lock and run in their own scratch root
#     (/tmp/agent_gate.XXXXXX, or GATE_SCRATCH); real merges hold the lock.
#   - A passing CHECK_ONLY run stamps its verdict under GATE_STATE
#     (/tmp/agent_gate_state) keyed on the merged tree id + this script's sha +
#     knobs + toolchains; the real merge of the same merged tree reuses it
#     (printed as VERDICT REUSED; FORCE_RECHECK=1 reruns; GATE_VERDICT_TTL_H=24).
#   - Linux docker build, guest route and test-bundle build start as soon as
#     the merged tree exists and are joined where the serial gate ran them;
#     conformance replays run GATE_JOBS (4) at a time; recaptures stay serial
#     on the simulator. GATE_SERIAL=1 restores the one-at-a-time order.
#   - GATE_WARM=1: persistent build caches (off by default; see the report).
# Knobs: GATE_GOLDENS=tmp grades against the machine-local /tmp round captures
# (the old route); ALLOW_STALE_GOLDENS="<set or App> ..." accepts named stale
# or unpinned golden sets (said in the merge).
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
trap 'drop_lock' EXIT; trap 'exit 130' INT TERM HUP
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

# ---------------------------------------------------------------------------
# The merged tree, without a worktree: the verdict stamp is keyed on it.
BASE=${GATE_BASE:-main}
if [ "$BASE" != main ] && [[ -z "${CHECK_ONLY:-}" ]]; then echo "REFUSED: GATE_BASE is for CHECK_ONLY experiments only"; exit 2; fi
MERGED_TREE=$(git merge-tree --write-tree "$BASE" "$BR" 2>/dev/null | head -1) || { echo "MERGE CONFLICT with main"; exit 4; }
GOLDENS=${GATE_GOLDENS:-committed}
case $GOLDENS in committed|tmp) ;; *) echo "GATE_GOLDENS must be committed or tmp" >&2; exit 2 ;; esac
GATE_STATE=${GATE_STATE:-/tmp/agent_gate_state}
# Everything besides the merged tree that can change a verdict: this script,
# the override knobs, the toolchains and images, the guest sysroot, and (only
# with GATE_GOLDENS=tmp) the machine-local round captures.
verdict_key() {
  {
    echo "tree $MERGED_TREE"
    echo "gate $(shasum -a 256 < "$SELF" | cut -c1-64)"
    for v in ALLOW_DROP ALLOW_STALE_GOLDENS ALLOW_PATHS RECAPTURE_APPS GATE_GOLDENS GATE_WARM; do echo "$v=${!v:-}"; done
    swift --version 2>&1 | head -1
    docker image inspect -f '{{.Id}}' swift:6.2-noble 2>/dev/null || echo no-linux-image
    docker images --no-trunc --format '{{.Repository}}:{{.Tag}} {{.ID}}' 2>/dev/null | grep '^swift-macho-spike:' | sort
    for f in scratch/fe4_out/FoundationEssentials.swiftmodule /Users/miguelsalinas/openuikit/scratch/fe4_out/FoundationEssentials.swiftmodule \
             /Users/miguelsalinas/swift-macho-linux/scratch/fe4_out/FoundationEssentials.swiftmodule; do
      if [ -e "$f" ]; then shasum -a 256 "$f"; fi
    done
    if [ "$GOLDENS" = tmp ]; then
      python3 -c 'import glob, os
for d in sorted(glob.glob("/tmp/golden_realapp_ios") + glob.glob("/tmp/hc-conformance-*/golden")):
    for r, _, fs in sorted(os.walk(d)):
        for f in sorted(fs):
            p = os.path.join(r, f); st = os.stat(p); print(p, st.st_size, st.st_mtime)'
    fi
  } | shasum -a 256 | cut -c1-64
}
KEY=$(verdict_key)
STAMP=$GATE_STATE/verdicts/$KEY
REUSED=""
# A real merge (or CHECK_ONLY with REUSE_VERDICT=1) whose merged tree, gate
# script and inputs match a passing CHECK_ONLY run reuses that verdict.
if { [[ -z "${CHECK_ONLY:-}" ]] || [ -n "${REUSE_VERDICT:-}" ]; } && [ -z "${FORCE_RECHECK:-}" ] && [ -f "$STAMP" ] \
   && [ -n "$(find "$STAMP" -mmin -$(( ${GATE_VERDICT_TTL_H:-24} * 60 )) 2>/dev/null)" ]; then
  REUSED=1
  stage "VERDICT REUSED — every check below already passed on this exact merged tree"
  sed 's/^/     /' "$STAMP"
  echo "     key $KEY (merged tree $MERGED_TREE, gate script sha, knobs, toolchains); FORCE_RECHECK=1 reruns every check"
fi

if [ -z "$REUSED" ]; then
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
git worktree add -q --detach "$WT" "$BASE"
BG_PIDS=""
SIM_LOCK=/tmp/conformance_sim.lock
HAVE_SIM=""
killtree() { local c; for c in $(pgrep -P "$1" 2>/dev/null); do killtree "$c"; done; kill "$1" 2>/dev/null || true; }
cleanup() {
  local rc=$?; set +e   # never let a cleanup failure replace the verdict (a failing
                        # git in the old trap turned exit 9 into 128)
  for p in $BG_PIDS; do killtree "$p"; done
  docker rm -f "gate-linux-$$" >/dev/null 2>&1 || true
  if [ -n "$HAVE_SIM" ]; then rm -rf "$SIM_LOCK"; fi
  if [ -n "${SLOT_LOCK:-}" ]; then rm -rf "$SLOT_LOCK"; fi
  git -C "$WT" merge --abort 2>/dev/null; git worktree remove --force "$WT" 2>/dev/null; git worktree prune; drop_lock
  exit $rc
}
trap cleanup EXIT; trap 'exit 130' INT TERM HUP
git -C "$WT" merge -q --no-ff --no-commit "$BR" || { echo "MERGE CONFLICT with main"; exit 4; }
WT_TREE=$(git -C "$WT" write-tree)
STAMP_OK=1
if [ "$WT_TREE" != "$MERGED_TREE" ]; then
  echo "   note: worktree merge $WT_TREE != merge-tree $MERGED_TREE; this run will not stamp a reusable verdict"; STAMP_OK=""
fi
cd "$WT/uikit"
if [ "$GOLDENS" = tmp ]; then
  # GATE_GOLDENS=tmp: grade against this machine's last round captures in /tmp
  # (the pre-committed-goldens route). When /tmp has none, fall back to the
  # committed snapshot; restore.sh leaves live /tmp captures alone.
  echo "   GATE_GOLDENS=tmp: goldens are the machine-local /tmp round captures (provenance unchecked)"
  if [[ -d goldens/ios && -f goldens/ios/manifest.json ]]; then
    zsh scripts/goldens_restore.sh
  fi
  REALAPP_GOLDEN=/tmp/golden_realapp_ios
else
  # Default: the goldens COMMITTED in the merged tree (goldens/ios, sha256 per
  # file in manifest.json), copied into this run's scratch root. The shared,
  # mutable /tmp round captures are never read (2026-09-22: they were all
  # overwritten with older goldens and every conformance row read as a drop).
  REALAPP_GOLDEN=$S/golden_realapp_ios
fi

# Stages that need only the merged sources start now and are joined where the
# serial gate ran them, so every verdict and exit code keeps its place:
#   Linux build (docker)       joined after the conformance apps  (exit 7)
#   guest library route        joined after the Catalyst gate     (exit 2)
#   test bundle (debug build)  joined after the guest route       (exit 5)
# GATE_SERIAL=1 runs them in place instead (timing comparisons).
bg() { # <name> <cmd...>: run in the background, rc to $S/<name>.rc
  local name=$1; shift
  ( set +e; "$@" > "$S/$name.log" 2>&1; echo $? > "$S/$name.rc.tmp"; mv "$S/$name.rc.tmp" "$S/$name.rc" ) &
  BG_PIDS="$BG_PIDS $!"
}
join_bg() { # <name>: wait for it, echo its rc
  while [ ! -f "$S/$1.rc" ]; do sleep 1; done
  cat "$S/$1.rc"
}
linux_build() {
  # The merged tree exactly (git archive of the worktree's index), not a copy
  # of the worktree: that copied the macOS .build into the container.
  # One container: the openrender line is printed as before (status ignored),
  # then openrender + ConformanceApps + the OpenUIKitTests target decide.
  # openrender AND the ConformanceApps target (openhost needs SDL2, absent in the
  # plain image): the Ledger app's DateComponentsFormatter (unavailable in corelibs)
  # passed the openrender-only step and broke the Docker verify (#468). AND the test
  # bundle: TextKitTests' bare `NotificationCenter` was ambiguous only on corelibs and
  # reached main because only the Docker verify builds tests (verify83). Only the
  # OpenUIKitTests target: --build-tests would also build openhost, whose CSDL2
  # needs SDL2 (absent in the plain image).
  git -C "$WT" archive --format=tar "$WT_TREE:uikit" \
  | docker run --rm -i --name "gate-linux-$$" $LINUX_VOLUMES swift:6.2-noble bash -c '
      mkdir -p /work && tar -xf - -C /work && cd /work && rm -f Package.resolved
      swift build -c release --product openrender 2>&1 | grep -E "error|Build of" | tail -3
      swift build -c release --product openrender >/dev/null 2>&1 && swift build -c release --target ConformanceApps >/dev/null 2>&1 && swift build --target OpenUIKitTests 2>&1 | grep -E "error:" | head -5; test ${PIPESTATUS[0]} -eq 0'
}
guest_route() { GUEST_ROUTE_OUT=$S/guest-route bash scripts/guest_route_check.sh; }
test_bundle() {
  # its own scratch path, so it builds alongside the release build (one .build
  # would serialize them on SwiftPM's lock); same sources, same pins
  swift build --build-tests --scratch-path "$TESTS_SCRATCH"
}
TESTS_SCRATCH=$WT/uikit/.build-tests
LINUX_VOLUMES=""
SCRATCH_ARGS=""
# GATE_WARM=1 (off by default): a persistent SwiftPM scratch dir per slot
# (GATE_CACHE, default ~/Library/Caches/agent_gate/<toolchain>/slot-N, one run
# per slot) for the release and test builds, and a docker volume per slot for
# the Linux .build. The worktree path is new every run, so every uikit module
# is recompiled from scratch; what is reused is the dependency checkouts and
# their products (swift-syntax, OpenCombine). Equivalence evidence and why it
# is not the default: docs/agent_reports/gate-speed.md.
if [ -n "${GATE_WARM:-}" ]; then
  CACHE=${GATE_CACHE:-$HOME/Library/Caches/agent_gate}/$(swift --version 2>&1 | shasum | cut -c1-12)
  mkdir -p "$CACHE"
  for n in 1 2 3 4; do
    if ! mkdir "$CACHE/lock-$n" 2>/dev/null; then
      p=$(cat "$CACHE/lock-$n/pid" 2>/dev/null || true)
      { [ -n "$p" ] && kill -0 "$p" 2>/dev/null; } && continue
      rm -rf "$CACHE/lock-$n"; mkdir "$CACHE/lock-$n" 2>/dev/null || continue
    fi
    echo $$ > "$CACHE/lock-$n/pid"; SLOT=$CACHE/slot-$n; SLOT_LOCK=$CACHE/lock-$n; break
  done
  if [ -n "${SLOT:-}" ]; then
    mkdir -p "$SLOT/build"
    SCRATCH_ARGS="--scratch-path $SLOT/build"; TESTS_SCRATCH=$SLOT/tests
    rm -rf .build; ln -s "$SLOT/build" .build        # ./.build/release/* keeps working
    LINUX_VOLUMES="-v agent-gate-$(basename "$CACHE")-$n:/work/.build"
    echo "   GATE_WARM: build caches in $SLOT (docker volume agent-gate-$(basename "$CACHE")-$n)"
  else
    echo "   GATE_WARM: every cache slot is busy; building cold"
  fi
fi
swift package resolve $SCRATCH_ARGS >/dev/null 2>&1 || true   # one Package.resolved for every SwiftPM run below
if [ -z "${GATE_SERIAL:-}" ]; then
  bg linux linux_build
  bg guest-route guest_route
  bg tests test_bundle
fi

stage "macOS build + Catalyst gate"
swift build -c release --product openrender $SCRATCH_ARGS 2>&1 | grep -E 'error|Build of' | tail -3
# openhost (the conformance replays) builds while the gate and real apps render
[ -z "${GATE_SERIAL:-}" ] && bg openhost swift build -c release --product openhost $SCRATCH_ARGS
rm -rf $S/gate; ./.build/release/openrender render $S/gate fixtures/scenes/*.json >/dev/null
python3 Tools/compare/compare.py --out $S/gate > $S/gate-compare.txt 2>&1 || true
grep -E '^FAIL|scenes pass' $S/gate-compare.txt | tail -5
grep -q '^FAIL' $S/gate-compare.txt && { echo "GATE RED"; exit 5; }
stage "guest library route (Foundation hidden)"
# The Docker/corelibs Linux build cannot see this: OpenUIKit is compiled
# against a Darwin sysroot with no Foundation.swiftmodule (rung b/c, build_full.sh).
# x86 cycle c4dce839 went red on unguarded NSNumber/URL/Data after the ladder
# merges. Refuse that class at merge time (Mac, under 10 minutes).
if [ -n "${GATE_SERIAL:-}" ]; then guest_route; else
  rc=$(join_bg guest-route); cat $S/guest-route.log; [ "$rc" = 0 ] || exit "$rc"
fi
stage "test bundle builds (a keep-both on a test file once merged an unbalanced class)"
if [ -n "${GATE_SERIAL:-}" ]; then test_bundle > $S/tests.log 2>&1 && echo 0 > $S/tests.rc || echo 1 > $S/tests.rc; fi
[ "$(join_bg tests)" = 0 ] || { grep -E 'error:' $S/tests.log | head -5; echo "TEST BUNDLE RED"; exit 5; }
stage "real-app screens"
if [ "$GOLDENS" = committed ]; then
  if [ -d goldens/ios/golden_realapp_ios ]; then
    rm -rf "$REALAPP_GOLDEN"; mkdir -p "$REALAPP_GOLDEN"; cp -pR goldens/ios/golden_realapp_ios/. "$REALAPP_GOLDEN"/
  else
    echo "   no committed goldens/ios/golden_realapp_ios; using /tmp/golden_realapp_ios"; REALAPP_GOLDEN=/tmp/golden_realapp_ios
  fi
fi
rm -rf $S/app; OPENUIKIT_REALAPP_SCALE=3 OPENUIKIT_FORCE_IOS=1 ./.build/release/openrender realapp $S/app >/dev/null
python3 Tools/compare/compare_realapp.py --golden "$REALAPP_GOLDEN" --out $S/app --scale 3 > $S/app-compare.txt 2> $S/app-compare.err || true
grep pixels $S/app-compare.txt | cut -c1-80
GATE_S=$S python3 - <<'PY' || exit 6
import os, re
out = open(os.environ['GATE_S'] + '/app-compare.txt').read()
floors = {'realapp_history_light': 99.0, 'realapp_settings_light': 98.4, 'realapp_settings_dark': 98.4, 'realapp_storage_light': 99.0, 'realapp_settings_light_xs': 98.4, 'realapp_settings_light_xxxl': 98.0, 'realapp_settings_light_ax1': 97.0, 'realapp_settings_light_ipad': 99.4, 'realapp_history_light_ipad': 99.6, 'realapp_storage_light_ipad': 99.5, 'realapp_focus_settings_light': 80.2, 'realapp_hackers_feed_light': 84.4}
for name, floor in floors.items():
    m = re.search(name + r".*?'score': np\.float64\(([\d.]+)\)", out)
    if not m or float(m.group(1)) < floor: raise SystemExit(f'REAL APP DROPPED: {name} {m.group(1) if m else "?"} < {floor}')
PY
stage "conformance apps (SKIP_CAPTURE re-render against the $([ "$GOLDENS" = tmp ] && echo "last round's /tmp" || echo committed) goldens)"
# Wave 12 merged a page-transition regression (Pager t600 98.9 -> 95.9) that
# the gate and the real-app floors cannot see. Every app with goldens is
# re-rendered from the merged tree and graded against scoreboard/latest.json:
# a passing row must stay at or above its bar, a failing row must not lose
# more than 0.5.
# A branch that changes the PROBE (how a frame is named, what is dumped)
# invalidates the goldens for that app: RECAPTURE_APPS="Pager Tabs" captures
# them again with the merged tree's probe before grading (serially, under
# /tmp/conformance_sim.lock: one simulator).
# Plan: one line per set, in the serial gate's order: <set> <app> <skip> [flag]
: > $S/plan.txt
for app_dir in Sources/ConformanceApps/*/; do
  [ -d "$app_dir" ] || continue
  app=$(basename "$app_dir")
  has_set() {
    if [ "$GOLDENS" = tmp ]; then [ -d /tmp/$1/golden ]; else [ -d goldens/ios/$1 ]; fi
  }
  has_set hc-conformance-$app || { echo "   $app: no $([ "$GOLDENS" = tmp ] && echo "round capture" || echo "committed goldens"), skipped"; continue; }
  for axis in "" ipad dark rtl ax1 xxxl landscape; do
    set=hc-conformance-$app${axis:+-$axis}
    has_set $set || continue
    skip=1
    for r in ${RECAPTURE_APPS:-}; do
      # the serial gate's rules: the app name recaptures every axis; ipad /
      # ax1 / xxxl sets also answer to <App>-<axis>
      if [ "$r" = "$app" ]; then skip=""; fi
      case $axis in ipad|ax1|xxxl) [ "$r" = "$app-$axis" ] && skip="" ;; esac
    done
    echo "$set $app ${skip:-0} ${axis:+--$axis}" >> $S/plan.txt
  done
done
# Refuse goldens that cannot be what the board was graded against, BEFORE
# spending minutes on renders (committed goldens; the golden_sha pin also
# applies to /tmp captures).
GATE_S=$S GATE_GOLDENS=$GOLDENS python3 - <<'PY' || exit 9
import hashlib, json, os, subprocess, sys
S, mode = os.environ["GATE_S"], os.environ["GATE_GOLDENS"]
allow = set(os.environ.get("ALLOW_STALE_GOLDENS", "").split())
plan = [l.split() for l in open(f"{S}/plan.txt") if l.strip()]
board = [r for r in json.load(open("scoreboard/latest.json"))["rows"] if r["category"] == "conformance"]
man = json.load(open("goldens/ios/manifest.json"))["sets"] if os.path.exists("goldens/ios/manifest.json") else {}
def sha(p): return hashlib.sha256(open(p, "rb").read()).hexdigest()
# identical to Tools/compare/conformance_provenance.py app_fingerprint()
def app_fingerprint(app):
    files = []
    for dirpath, dirnames, filenames in os.walk(f"Sources/ConformanceApps/{app}"):
        dirnames[:] = [n for n in dirnames if not n.startswith(".")]
        files += [os.path.relpath(os.path.join(dirpath, n), ".") for n in filenames if not n.startswith(".")]
    h = hashlib.sha256()
    for rel in sorted(files):
        h.update(rel.encode() + b"\0" + sha(rel).encode() + b"\n")
    return h.hexdigest()
def last_source_change(app):
    t = subprocess.run(["git", "log", "-1", "--no-merges", "--format=%at", "HEAD", "MERGE_HEAD", "--",
                        f"Sources/ConformanceApps/{app}"], capture_output=True, text=True).stdout.strip()
    return int(t) if t else 0
import datetime
def ts(iso): return datetime.datetime.strptime(iso, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc).timestamp()
bad, notes = [], []
if mode == "committed" and "golden_realapp_ios" in man:
    info = man["golden_realapp_ios"]; d = "goldens/ios/golden_realapp_ios"
    have = set(n for n in os.listdir(d) if not n.startswith("."))
    # every manifest file present with its sha256; files added after the
    # snapshot (not in the manifest) are only reported
    if any(n not in have or sha(os.path.join(d, n)) != info["files"][n] for n in info["files"]):
        bad.append(("golden_realapp_ios", None, "GOLDEN SNAPSHOT CORRUPT: goldens/ios/golden_realapp_ios does not match manifest.json sha256", "restore the set from main or re-run scripts/goldens_snapshot.sh"))
    extra = sorted(have - set(info["files"]))
    if extra:
        notes.append(f"   golden_realapp_ios: {len(extra)} file(s) not in manifest.json ({', '.join(extra[:3])}{' ...' if len(extra) > 3 else ''})")
for set_, app, skip, *flag in plan:
    axis = flag[0][2:] if flag else "base"
    fix = f"uikit/scripts/refresh_conformance_goldens.sh {app} {axis}   # recaptures + regrades; commit goldens/ios and scoreboard/ together"
    if skip == "0":
        print(f"   {set_}: RECAPTURE_APPS — fresh simulator goldens, board pins not checked"); continue
    gdir = f"/tmp/{set_}/golden" if mode == "tmp" else f"goldens/ios/{set_}"
    names = sorted(n for n in os.listdir(gdir) if not n.startswith("."))
    if mode == "committed":
        info = man.get(set_)
        if info is None:
            bad.append((set_, app, f"GOLDEN SNAPSHOT CORRUPT: goldens/ios/{set_} is not in manifest.json", fix)); continue
        if names != sorted(info["files"]) or any(sha(os.path.join(gdir, n)) != info["files"][n] for n in names):
            bad.append((set_, app, f"GOLDEN SNAPSHOT CORRUPT: goldens/ios/{set_} does not match manifest.json sha256", fix)); continue
        prov = os.path.join(gdir, "provenance.json")
        if os.path.exists(prov):
            p = json.load(open(prov))
            if p.get("app_fingerprint") != app_fingerprint(app):
                bad.append((set_, app, f"STALE GOLDENS: Sources/ConformanceApps/{app} changed since {set_} was captured ({p.get('captured')} @ {str(p.get('head'))[:8]})", fix))
        else:
            changed = last_source_change(app)
            if changed and ts(info["captured"]) < changed:
                when = datetime.datetime.fromtimestamp(changed, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
                bad.append((set_, app, f"STALE GOLDENS: Sources/ConformanceApps/{app} changed at {when}, after {set_} was captured ({info['captured']})", fix))
    # the board rows of this set: <summary app>:<t>[.dark][.rtl][.ax1|.xxxl][.landscape]
    sapp = app + ("-ipad" if axis == "ipad" else "")
    suffix = [] if axis in ("base", "ipad") else [axis]
    rows = {r["scene"].split(":", 1)[1]: r for r in board
            if r["scene"].split(":", 1)[0] == sapp and r["scene"].split(":", 1)[1].split(".")[1:] == suffix}
    frames = {n[len(app) + 1:-4]: n for n in names if n.endswith(".png")}
    if not rows:
        notes.append(f"   {set_}: no board rows — its frames are rendered but not graded"); continue
    if set(rows) != set(frames):
        msg = f"BOARD-GOLDEN MISMATCH: {set_} frames {sorted(set(frames) - set(rows))} not on the board, board rows {sorted(set(rows) - set(frames))} not in the goldens"
        # GATE_GOLDENS=tmp keeps the old route's refusals (a missing frame is
        # still refused below as a 0.000 RENDER FAILED): reported only
        if mode == "tmp": notes.append(f"   {msg}")
        else: bad.append((set_, app, msg, fix))
        continue
    pinned = [f for f in frames if rows[f].get("golden_sha")]
    wrong = [f for f in pinned if rows[f]["golden_sha"] != sha(os.path.join(gdir, frames[f]))]
    if wrong:
        bad.append((set_, app, f"BOARD-GOLDEN MISMATCH: {set_} {sorted(wrong)} were graded on the board against a different golden than the one here", fix))
    if len(pinned) < len(frames):
        notes.append(f"   {set_}: {len(frames) - len(pinned)} board row(s) not pinned to a golden (no golden_sha): a drop there may be a stale golden, not a regression")
for n in notes: print(n)
refuse = []
for set_, app, msg, fix in bad:
    if set_ in allow or (app and app in allow) or "all" in allow:
        print(f"   {msg} — ALLOWED (ALLOW_STALE_GOLDENS)")
    else:
        refuse.append(f"{msg}\n      fix: {fix}")
if refuse:
    print("\n".join(refuse))
    raise SystemExit(f"CONFORMANCE GOLDENS REFUSED: {len(refuse)} set(s) (ALLOW_STALE_GOLDENS=\"<set or App> ...\" accepts them, named in the merge)")
PY
seed() { # <set> <dir>: the goldens a set is graded against
  rm -rf "$2"
  if [ "$GOLDENS" = tmp ]; then cp -r /tmp/$1 "$2"
  else mkdir -p "$2/golden"; cp -pR goldens/ios/$1/. "$2/golden"/; fi
}
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
  CONFORMANCE_PREBUILT=1 bash scripts/conformance_flow.sh "$d" "$@" > "$d.log" 2>&1 || { echo "CONFORMANCE FLOW FAILED on retry: $d"; return 1; }
  touch "$d.retried"
  g=$(ls "$d"/golden/*.png 2>/dev/null | wc -l | tr -d ' '); o=$(ls "$d"/ours/*.png 2>/dev/null | wc -l | tr -d ' ')
  [ "$g" = "$o" ] || { echo "RECAPTURE INCOMPLETE: $d golden $g frame(s) vs ours $o"; return 1; }
}
run_set() { # <set> <app> <skip> [flag]: one conformance_flow run, rc to $S/conf-<...>.rc
  local set=$1 app=$2 skip=$3 flag=${4:-}
  local d=$S/conf-${set#hc-conformance-}
  [ "$skip" = 1 ] || echo "   ${set#hc-conformance-}: recapturing goldens with the merged probe"
  seed "$set" "$d"
  [ "$skip" = 1 ] || rm -rf "$d/golden"
  ( set +e; SKIP_CAPTURE=$([ "$skip" = 1 ] && echo 1) CONFORMANCE_PREBUILT=1 bash scripts/conformance_flow.sh "$d" "$app" $flag > "$d.log" 2>&1; echo $? > "$d.rc.tmp"; mv "$d.rc.tmp" "$d.rc" )
}
if [ -s $S/plan.txt ]; then
  if [ -n "${GATE_SERIAL:-}" ]; then swift build -c release --product openhost $SCRATCH_ARGS > $S/openhost.log 2>&1 && echo 0 > $S/openhost.rc || echo 1 > $S/openhost.rc; fi
  [ "$(join_bg openhost)" = 0 ] || { tail -5 $S/openhost.log; echo "CONFORMANCE FLOW FAILED: openhost build (see $S/openhost.log)"; exit 9; }
  # Replays (SKIP_CAPTURE) touch no simulator and write only their own dirs:
  # GATE_JOBS (4) at a time. Recaptures go one at a time on the simulator.
  JOBS=${GATE_JOBS:-4}; [ -n "${GATE_SERIAL:-}" ] && JOBS=1
  ( running=0
    while read -r set app skip flag; do
      [ "$skip" = 1 ] || continue
      run_set "$set" "$app" 1 $flag &
      running=$((running + 1))
      if [ "$running" -ge "$JOBS" ]; then wait -n; running=$((running - 1)); fi
    done < $S/plan.txt
    wait ) &
  POOL=$!; BG_PIDS="$BG_PIDS $POOL"
  if awk '$3 == "0" { f = 1 } END { exit !f }' $S/plan.txt; then
    until mkdir "$SIM_LOCK" 2>/dev/null; do
      p=$(cat "$SIM_LOCK/pid" 2>/dev/null || true)
      if [ -n "$p" ] && ! kill -0 "$p" 2>/dev/null; then rm -rf "$SIM_LOCK"; continue; fi
      sleep 30
    done
    echo $$ > "$SIM_LOCK/pid"; HAVE_SIM=1
    while read -r set app skip flag; do
      [ "$skip" = 0 ] && run_set "$set" "$app" 0 $flag
    done < $S/plan.txt
  fi
  wait $POOL || true
  # verdicts in the serial gate's order: first failing set decides the message
  while read -r set app skip flag; do
    d=$S/conf-${set#hc-conformance-}
    rc=$(cat "$d.rc" 2>/dev/null || echo 1)
    # rc 4 = a short set (conformance_flow.sh SHORT CAPTURE): the frame-count
    # check below retries a short recapture once or refuses it by name
    case $rc in 0|4) ;; *) echo "CONFORMANCE FLOW FAILED: $app${flag:+ $flag} (see $d.log)"; exit 9 ;; esac
    frames_complete "$d" "$([ "$skip" = 1 ] && echo 1)" $app $flag || exit 9
    if [ "$rc" = 4 ] && ! [ -f "$d.retried" ]; then grep -h 'SHORT CAPTURE' "$d.log" | tail -1; echo "CONFORMANCE FLOW SHORT: $app${flag:+ $flag} (see $d.log)"; exit 9; fi
  done < $S/plan.txt
  if [ -n "$HAVE_SIM" ]; then rm -rf "$SIM_LOCK"; HAVE_SIM=""; fi
fi
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
        hint = "" if row.get("golden_sha") else " [board row not pinned to a golden: may be a stale golden]"
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
            else: bad.append(f"{name} {score:.3f} < bar {row['threshold']} (was {row['score']:.3f}){hint}")
        elif score < row["score"] - 0.5:
            # ALLOW_DROP="Tabs:t6000 ..." names failing rows a merge may lower on purpose
            # (a measured interaction another branch owns); it must be said in the merge.
            if name in os.environ.get("ALLOW_DROP", "").split(): print(f"   {name}: {score:.3f} < {row['score']:.3f} ALLOWED (ALLOW_DROP)")
            else: bad.append(f"{name} {score:.3f} dropped from {row['score']:.3f}{hint}")
        print(f"   {name}: {score:.3f} (board {row['score']:.3f})")
if bad: raise SystemExit("CONFORMANCE DROPPED: " + "; ".join(bad))
PY
stage "Linux build"
if [ -n "${GATE_SERIAL:-}" ]; then linux_build > $S/linux.log 2>&1 && echo 0 > $S/linux.rc || echo 1 > $S/linux.rc; fi
rc=$(join_bg linux); tail -8 $S/linux.log
[ "$rc" = 0 ] || { echo "LINUX BUILD RED"; exit 7; }
cd "$WT" && git merge --abort 2>/dev/null || true
cd "$ROOT"
if [[ -n "${CHECK_ONLY:-}" ]] && [ -n "$STAMP_OK" ] && [ -z "${RECAPTURE_APPS:-}" ] && [ "$BASE" = main ]; then
  mkdir -p "$GATE_STATE/verdicts"
  printf 'passed %s on %s: %s (%s) + main %s -> merged tree %s; scratch %s\n' \
    "$(date -u +%FT%TZ)" "$(hostname -s)" "$BR" "$(git rev-parse --short "$BR")" "$(git rev-parse --short main)" "$MERGED_TREE" "$S" > "$STAMP"
  echo "   verdict stamped for reuse by the real merge: $STAMP"
fi
fi  # not REUSED
[[ -n "${CHECK_ONLY:-}" ]] && { stage "checks passed (CHECK_ONLY)"; exit 0; }

stage "merging into main"
# SDK-depth framework merges (scratchpad fw_merge.sh) land on main concurrently
# under their own lock and never touch uikit/; sync main first so the push is a
# fast-forward, and if main still moved before the push, merge it once more.
# What was checked is main+branch as of the check; if origin/main has moved
# uikit/ since, that combination was never checked: refuse (rerun the gate).
git checkout -q main && git fetch -q origin && git merge -q --ff-only origin/main \
  && NOW_TREE=$(git merge-tree --write-tree main "$BR" | head -1) \
  && { [ "$(git rev-parse "$NOW_TREE:uikit")" = "$(git rev-parse "$MERGED_TREE:uikit")" ] \
       || { echo "REFUSED: main's uikit/ moved since the check (origin/main advanced); rerun the gate"; exit 3; }; } \
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
