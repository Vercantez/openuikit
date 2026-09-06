#!/usr/bin/env python3
"""codex_cloud_campaign.py — run a framework-fanout campaign on Codex Cloud.

Twin of the Cursor cloud campaign loop (user directive 2026-09-16: move cloud
depth waves to Codex). One Codex Cloud task per framework lane, submitted with
`codex cloud exec --env ENV --branch <startingRef> "<prompt>"`, polled with
`codex cloud status`, harvested with `codex cloud apply` into a local worktree
of the seed branch, committed and pushed as agent/fw-<slug>-cc so the existing
sealed gate (`fw_merge.sh <slug> origin/agent/fw-<slug>-cc`) grades it exactly
like a Cursor branch. The Codex Cloud agent phase has no network, so the agent
never pushes; the operator harvests.

Usage:
  codex_cloud_campaign.py <campaign.json> [--env ID] [--max-active N] [--limit N]
                          [--slugs a,b,c] [--poll SECONDS] [--dry-run] [--once]
State: <campaign>.codex.state.json (per slug: taskId, status, branch, sha).
"""
import argparse, functools, json, os, re, subprocess, sys, time, datetime, shutil
print = functools.partial(print, flush=True)

ENV_DEFAULT = "6a9de055eaf081918405e62d8ea487f6"   # Vercantez/openuikit-linux-platform
ROOT = os.path.expanduser("~/openuikit")
PLATFORM_URL = "git@github.com:Vercantez/openuikit-linux-platform.git"
ADDENDUM = (
    "\n\nCODEX CLOUD RUN: this task runs in a Codex Cloud container of the platform "
    "repository with NO network in the agent phase. Do not try to push, open a PR, or "
    "fetch anything; leave every change committed or uncommitted in the working tree — "
    "the operator harvests it with `codex cloud apply` and pushes it as your branch. "
    "The environment marker to cite is `CODEX_SWIFT_ENVIRONMENT_OK swift=6.2.4 "
    "target=linux products=clean` (printed by the setup script after Cursor's own "
    "marker). Your final message MUST paste the last 10 lines of the sealed gate "
    "(`{gate}`) verbatim and the honest before/after implemented counts."
)

def sh(args, cwd=None, timeout=900, check=False):
    r = subprocess.run(args, cwd=cwd, capture_output=True, text=True, timeout=timeout)
    if check and r.returncode != 0:
        raise RuntimeError(f"{' '.join(args)} rc={r.returncode}: {r.stderr[-800:]}")
    return r

def now(): return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def load_state(path, camp):
    if os.path.exists(path):
        return json.load(open(path))
    return {"campaign": camp["campaign"]["id"], "env": None, "startingRef": camp["repository"]["startingRef"],
            "createdAt": now(), "frameworks": {}}

def save_state(path, st):
    st["updatedAt"] = now()
    tmp = path + ".tmp"; json.dump(st, open(tmp, "w"), indent=1, sort_keys=True); os.replace(tmp, path)

STATUS_RE = re.compile(r"^\[([A-Z_ ]+)\]")
def task_status(task_id):
    """Return (state, raw). state ∈ {'active','done','error','unknown'}."""
    r = sh(["codex", "cloud", "status", task_id], timeout=120)
    raw = (r.stdout + r.stderr).strip()
    m = STATUS_RE.match(raw)
    tag = m.group(1).strip() if m else ""
    if r.returncode != 0 and not tag:
        return "unknown", raw
    if tag in ("ERROR", "FAILED", "CANCELLED", "CANCELED"): return "error", raw
    if tag in ("READY", "DONE", "COMPLETED", "SUCCESS", "APPLIED"): return "done", raw
    if tag in ("PENDING", "RUNNING", "QUEUED", "IN PROGRESS", "IN_PROGRESS"): return "active", raw
    # unknown tag: treat "no diff"/"diff" lines as done only if not obviously pending
    if re.search(r"\b(pending|running|queued|in progress)\b", raw, re.I): return "active", raw
    if tag: return "done", raw
    return "unknown", raw

def submit(env, branch, prompt, dry):
    if dry:
        print(f"  DRY RUN: codex cloud exec --env {env} --branch {branch} <prompt {len(prompt)} chars>")
        return "task_dry_" + str(int(time.time()))
    r = sh(["codex", "cloud", "exec", "--env", env, "--branch", branch, prompt], timeout=300)
    out = r.stdout + r.stderr
    m = re.search(r"task_e_[0-9a-f]+", out)
    if not m:
        raise RuntimeError(f"submit failed rc={r.returncode}: {out[-600:]}")
    return m.group(0)

def ensure_platform_remote():
    r = sh(["git", "remote"], cwd=ROOT)
    if "platform" not in r.stdout.split():
        sh(["git", "remote", "add", "platform", PLATFORM_URL], cwd=ROOT, check=True)

def harvest(fw, task_id, starting_ref, st_entry):
    """Apply the task diff onto a fresh worktree of the seed branch, commit, push agent/fw-<slug>-cc."""
    slug = fw["slug"]; branch = f"agent/fw-{slug}-cc"
    if re.search(r"^no diff\s*$", st_entry.get("lastStatus", ""), re.M):
        return {"status": "no_diff", "reason": "codex cloud status reports no diff"}
    ensure_platform_remote()
    sh(["git", "fetch", "-q", "platform", starting_ref], cwd=ROOT, check=True)
    wt = f"/tmp/wt-codex-{slug}"
    sh(["git", "worktree", "remove", "--force", wt], cwd=ROOT)
    shutil.rmtree(wt, ignore_errors=True)
    sh(["git", "worktree", "add", "-q", "--detach", wt, "FETCH_HEAD"], cwd=ROOT, check=True)
    r = sh(["codex", "cloud", "apply", task_id], cwd=wt, timeout=600)
    applied = r.returncode == 0
    for junk in ("error.log",):   # the codex CLI writes its debug log (with the account id) into cwd
        try: os.remove(os.path.join(wt, junk))
        except FileNotFoundError: pass
    changed = sh(["git", "status", "--porcelain"], cwd=wt).stdout.strip()
    owned_prefixes = [p.split("*")[0].rstrip("/") for p in fw.get("ownedPaths", []) + fw.get("editablePaths", [])]
    owned_changed = [l[3:] for l in changed.splitlines() if any(l[3:].startswith(op) for op in owned_prefixes)]
    if changed and not owned_changed:
        sh(["git", "worktree", "remove", "--force", wt], cwd=ROOT)
        return {"status": "no_diff", "reason": "apply changed nothing under the framework's owned paths",
                "changed": changed.splitlines()[:10], "applyTail": (r.stdout + r.stderr)[-500:]}
    if not changed:
        sh(["git", "worktree", "remove", "--force", wt], cwd=ROOT)
        return {"status": "no_diff", "applyRc": r.returncode, "applyTail": (r.stdout + r.stderr)[-500:]}
    outside = [l[3:] for l in changed.splitlines() if not any(
        l[3:].startswith(p.rstrip("*/").rstrip("/")) for p in fw.get("ownedPaths", []) + fw.get("editablePaths", []) + ["uikit/docs/"])]
    sh(["git", "add", "-A"], cwd=wt, check=True)
    msg = (f"{fw['module']}: Codex Cloud depth pass ({task_id})\n\n"
           f"Campaign {st_entry.get('campaign','')}; seed {starting_ref}; harvested with codex cloud apply.\n\n"
           "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>\n"
           "Claude-Session: https://claude.ai/code/session_0188aCUiPNF2xwAWXcozrKDS")
    sh(["git", "-c", "user.name=Claude Fable 5.1", "-c", "user.email=noreply@anthropic.com", "commit", "-q", "-m", msg], cwd=wt, check=True)
    sha = sh(["git", "rev-parse", "HEAD"], cwd=wt).stdout.strip()
    sh(["git", "push", "-q", "-f", "origin", f"HEAD:refs/heads/{branch}"], cwd=wt, check=True)
    sh(["git", "worktree", "remove", "--force", wt], cwd=ROOT)
    stat = sh(["git", "diff", "--shortstat", "FETCH_HEAD", sha], cwd=ROOT).stdout.strip()
    return {"status": "harvested", "branch": branch, "sha": sha, "shortstat": stat, "outsideOwned": outside[:20],
            "applied": applied}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("campaign"); ap.add_argument("--env", default=ENV_DEFAULT)
    ap.add_argument("--max-active", type=int, default=8); ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--slugs", default=""); ap.add_argument("--poll", type=int, default=120)
    ap.add_argument("--dry-run", action="store_true"); ap.add_argument("--once", action="store_true")
    ap.add_argument("--branch", default="")
    a = ap.parse_args()
    camp = json.load(open(a.campaign))
    st_path = a.campaign.replace(".json", ".codex.state.json")
    st = load_state(st_path, camp); st["env"] = a.env
    starting_ref = a.branch or camp["repository"]["startingRef"]
    st["startingRef"] = starting_ref
    want = [f for f in camp["frameworks"] if not a.slugs or f["slug"] in a.slugs.split(",")]
    if a.limit: want = want[:a.limit]
    # the seed branch must exist on the platform repo (Codex clones from there)
    r = sh(["git", "ls-remote", "--heads", PLATFORM_URL, starting_ref], timeout=120)
    if starting_ref not in r.stdout:
        print(f"REFUSED: seed branch {starting_ref} is not on {PLATFORM_URL}; push it first "
              f"(git push {PLATFORM_URL} origin/{starting_ref}:refs/heads/{starting_ref})"); return 2
    print(f"campaign {camp['campaign']['id']} on env {a.env} seed {starting_ref}: {len(want)} lanes, max-active {a.max_active}")
    while True:
        fws = st["frameworks"]
        active = [s for s, e in fws.items() if e.get("status") == "active"]
        # poll active
        for slug in active:
            e = fws[slug]; state, raw = task_status(e["taskId"])
            e["lastStatus"] = raw[:400]; e["polledAt"] = now()
            if state == "done":
                fw = next(f for f in camp["frameworks"] if f["slug"] == slug)
                try:
                    e["lastStatus"] = raw[:400]
                res = harvest(fw, e["taskId"], starting_ref, {**st, **e}); e.update(res)
                    print(f"  {slug}: {res['status']} {res.get('shortstat','')} -> {res.get('branch','')}")
                except Exception as ex:
                    e["status"] = "harvest_failed"; e["error"] = str(ex)[-600:]; print(f"  {slug}: HARVEST FAILED {ex}")
            elif state == "error":
                e["status"] = "error"; print(f"  {slug}: ERROR {raw.splitlines()[0][:120] if raw else ''}")
            save_state(st_path, st)
        # submit
        active = [s for s, e in fws.items() if e.get("status") == "active"]
        for fw in want:
            if len(active) >= a.max_active: break
            if fw["slug"] in fws: continue
            prompt = fw["prompt"] + ADDENDUM.format(gate=fw.get("gate", "the framework's tests/acceptance/test_host.sh"))
            try:
                tid = submit(a.env, starting_ref, prompt, a.dry_run)
                fws[fw["slug"]] = {"taskId": tid, "status": "active", "submittedAt": now(), "module": fw["module"]}
                active.append(fw["slug"]); print(f"  submitted {fw['slug']} -> {tid}")
            except Exception as ex:
                fws[fw["slug"]] = {"status": "submit_failed", "error": str(ex)[-400:]}; print(f"  {fw['slug']}: SUBMIT FAILED {ex}")
            save_state(st_path, st)
            time.sleep(5)
        done = {s: e["status"] for s, e in fws.items() if e.get("status") != "active"}
        remaining = [f["slug"] for f in want if f["slug"] not in fws]
        print(f"[{now()}] active {len(active)} done {len(done)} remaining {len(remaining)}")
        if a.once or (not active and not remaining): break
        time.sleep(a.poll)
    print("MERGE COMMANDS (sealed gate, one at a time):")
    for s, e in st["frameworks"].items():
        if e.get("status") == "harvested":
            print(f"  bash $S/fw_merge.sh {s} {e['branch']}")
    print("CODEX_CLOUD_CAMPAIGN_DONE", json.dumps({s: e.get("status") for s, e in st["frameworks"].items()}))
    return 0

if __name__ == "__main__":
    sys.exit(main())
