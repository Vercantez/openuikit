#!/usr/bin/env bash
# refresh_conformance_goldens.sh <App> [axis...] — recapture a conformance
# app's committed golden sets on the simulator AND regrade its board rows, in
# one step (the fix agent_merge.sh prints for STALE GOLDENS / BOARD-GOLDEN
# MISMATCH).
#
#   scripts/refresh_conformance_goldens.sh Forms              # every committed axis
#   scripts/refresh_conformance_goldens.sh Tabs base ipad dark
#
# axes: base ipad dark rtl ax1 xxxl landscape (default: every
# goldens/ios/hc-conformance-<App>[-axis] set already committed).
#
# For each set, serially (one simulator):
#   1. conformance_flow.sh captures real UIKit into <work>/<set>/golden (with
#      provenance.json) and renders + grades this tree's OpenUIKit against it;
#   2. goldens/ios/<set>/ is replaced by the new capture and ONLY that set's
#      manifest.json entry is rewritten (format kept: indent=1, no newline);
# then scoreboard/latest.json gets ONLY those sets' rows replaced, each row
# pinned to its golden by golden_sha, and the old board vs new score is printed
# per row. A row that drops more than 0.5 is flagged: a refresh must not
# quietly absorb a regression. Commit goldens/ios and scoreboard/ together.
#
# REFRESH_WORKDIR=<dir> reuses finished work dirs there instead of capturing
# (resume after a failed step 2). The capture takes /tmp/conformance_sim.lock
# (agent_merge.sh recaptures take it too). SIM_DEVICE_SUFFIX passes through.
set -e
cd "$(dirname "$0")/.."
APP=${1:?usage: refresh_conformance_goldens.sh <App> [base|ipad|dark|rtl|ax1|xxxl|landscape ...]}
shift
[ -f "Sources/ConformanceApps/$APP/script.json" ] || { echo "no such conformance app: $APP" >&2; exit 2; }
AXES=("$@")
if [ ${#AXES[@]} -eq 0 ]; then
  for ax in base ipad dark rtl ax1 xxxl landscape; do
    set=hc-conformance-$APP; [ "$ax" = base ] || set=$set-$ax
    [ -d "goldens/ios/$set" ] && AXES+=("$ax")
  done
  [ ${#AXES[@]} -gt 0 ] || { echo "no committed goldens/ios/hc-conformance-$APP* sets; name the axes to create" >&2; exit 2; }
fi
WORK=${REFRESH_WORKDIR:-$(mktemp -d /tmp/refresh-goldens-$APP.XXXX)}
mkdir -p "$WORK"
echo "==> $APP: axes ${AXES[*]}; work dir $WORK"

SETS=()
if [ -z "${REFRESH_WORKDIR:-}" ]; then
  SIM_LOCK=/tmp/conformance_sim.lock
  until mkdir "$SIM_LOCK" 2>/dev/null; do
    p=$(cat "$SIM_LOCK/pid" 2>/dev/null || true)
    if [ -n "$p" ] && ! kill -0 "$p" 2>/dev/null; then rm -rf "$SIM_LOCK"; continue; fi
    echo "   waiting for the simulator lock (pid ${p:-?})"; sleep 30
  done
  echo $$ > "$SIM_LOCK/pid"
  trap 'rm -rf "$SIM_LOCK"' EXIT INT TERM HUP
  swift build -c release --product openhost 2>&1 | grep -E 'error|Build of' | tail -3
fi
for ax in "${AXES[@]}"; do
  case $ax in
    base) flag="" ;; ipad|dark|rtl|ax1|xxxl|landscape) flag="--$ax" ;;
    *) echo "unknown axis: $ax" >&2; exit 2 ;;
  esac
  set=hc-conformance-$APP; [ "$ax" = base ] || set=$set-$ax
  SETS+=("$set")
  d=$WORK/$set
  if [ -z "${REFRESH_WORKDIR:-}" ]; then
    # a loaded simulator drops frames: a short set (flow exit 4) is retried,
    # never written (REFRESH_ATTEMPTS, default 3)
    want=$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["captures"]))' "Sources/ConformanceApps/$APP/script.json")
    attempt=1
    while :; do
      rm -rf "$d"
      echo "==> capture $set (attempt $attempt)"
      rc=0; CONFORMANCE_PREBUILT=1 bash scripts/conformance_flow.sh "$d" "$APP" $flag > "$d.log" 2>&1 || rc=$?
      g=$(ls "$d"/golden/*.png 2>/dev/null | wc -l | tr -d ' '); o=$(ls "$d"/ours/*.png 2>/dev/null | wc -l | tr -d ' ')
      [ "$rc" = 0 ] && [ "$g" = "$want" ] && [ "$o" = "$want" ] && break
      [ "$rc" = 0 ] || [ "$rc" = 4 ] || { echo "CONFORMANCE FLOW FAILED: $set (exit $rc, see $d.log)"; exit 9; }
      echo "   $set: short capture — golden $g, ours $o of $want frame(s)"
      [ "$attempt" -ge "${REFRESH_ATTEMPTS:-3}" ] && { echo "RECAPTURE INCOMPLETE: $set after $attempt attempts; nothing written"; exit 9; }
      attempt=$((attempt + 1))
    done
  fi
  [ -f "$d/summary.json" ] && [ -f "$d/golden/provenance.json" ] || { echo "$d: no summary.json / golden/provenance.json" >&2; exit 2; }
  want=$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["captures"]))' "Sources/ConformanceApps/$APP/script.json")
  g=$(ls "$d"/golden/*.png 2>/dev/null | wc -l | tr -d ' '); o=$(ls "$d"/ours/*.png 2>/dev/null | wc -l | tr -d ' ')
  [ "$g" = "$want" ] && [ "$o" = "$want" ] || { echo "$d: golden $g, ours $o of $want frame(s); nothing written" >&2; exit 9; }
done

echo "==> goldens/ios: replace ${SETS[*]} (only those manifest entries)"
python3 - "$WORK" "${SETS[@]}" <<'PY'
import datetime, hashlib, json, os, shutil, sys
work, sets = sys.argv[1], sys.argv[2:]
man_path = "goldens/ios/manifest.json"
raw = open(man_path).read()
man = json.loads(raw)
# never reformat the manifest: a plain re-dump must give the same bytes
if json.dumps(man, indent=1) != raw:
    sys.exit("refresh: goldens/ios/manifest.json is not in json.dump(indent=1) form; not rewriting it")
def sha(p): return hashlib.sha256(open(p, "rb").read()).hexdigest()
for name in sets:
    src = os.path.join(work, name, "golden")
    dst = os.path.join("goldens/ios", name)
    names = sorted(n for n in os.listdir(src) if not n.startswith(".") and os.path.isfile(os.path.join(src, n)))
    if os.path.isdir(dst): shutil.rmtree(dst)
    os.makedirs(dst)
    files, newest = {}, 0.0
    for n in names:
        shutil.copy2(os.path.join(src, n), os.path.join(dst, n))
        files[n] = sha(os.path.join(dst, n))
        newest = max(newest, os.path.getmtime(os.path.join(src, n)))
    old = man["sets"].get(name, {})
    device = old.get("device")
    if not device:
        lay = json.load(open(os.path.join(src, next(n for n in names if n.endswith(".layout.json")))))
        sc = lay.get("screen") or {}
        device = f"bounds={sc.get('bounds')} scale={sc.get('scale')}"
    entry = {"dest": f"/tmp/{name}/golden", "device": device,
             "captured": datetime.datetime.fromtimestamp(newest, datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
             "pngs": sum(1 for n in names if n.endswith(".png")), "files": files}
    man["sets"][name] = entry
    print(f"  {name}: {entry['pngs']} png, {len(files)} files, captured {entry['captured']}"
          + (f" (was {old.get('captured')}, {old.get('pngs')} png)" if old else " (new set)"))
open(man_path, "w").write(json.dumps(man, indent=1))
PY

echo "==> scoreboard: regrade only these sets' rows (old board vs new, pinned by golden_sha)"
DIRS=(); for s in "${SETS[@]}"; do DIRS+=("$WORK/$s"); done
python3 scripts/scoreboard.py --refresh-conformance "${DIRS[@]}" --write
echo "==> done: review the deltas above, then commit goldens/ios scoreboard/ together"
git status --short -- goldens/ios scoreboard | head -20
