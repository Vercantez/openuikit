#!/usr/bin/env python3
"""Cursor cloud-agent wave orchestration for this monorepo.

One manifest in, one state file out, four subcommands:

  launch   --manifest M.json --state S.json     start every item's agent
  status   --state S.json [--refresh]           one line per agent
  followup --state S.json --key K --prompt-file F   nudge one agent (repair)
  collect  --state S.json --out REPORT.md       wave report: states + PR URLs

Manifest shape:
  {
    "name": "fw-wave-4",
    "model": "cursor-grok-4.6-high",          # default; effort high, non-fast
    "source": {"repository": "https://github.com/Vercantez/openuikit",
                "ref": "main"},
    "preamble": "House rules text shared by every item...",
    "items": [{"key": "webkit", "prompt": "task text..."}, ...]
  }

The state file is the record of the campaign (commit it under ops/campaigns/).
Launching is idempotent per key: items that already carry an agentId are
skipped, so a partially failed launch can simply be rerun.

The API key comes from $CURSOR_API_KEY or CURSOR_API_KEY=... in the repo-root
.env (gitignored). Requests that fail print the API's own error and mark the
item; they never fake a launch.
"""
import argparse
import json
import pathlib
import sys
import time
import urllib.error
import urllib.request

API = "https://api.cursor.com"
REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
TERMINAL = {"FINISHED", "ERROR", "EXPIRED", "CANCELLED"}


def api_key() -> str:
    import os
    key = os.environ.get("CURSOR_API_KEY", "")
    env = REPO_ROOT / ".env"
    if not key and env.is_file():
        for line in env.read_text().splitlines():
            if line.startswith("CURSOR_API_KEY="):
                key = line.split("=", 1)[1].strip()
    if not key:
        sys.exit("wave: no CURSOR_API_KEY in env or .env")
    return key


def call(method: str, path: str, body=None):
    req = urllib.request.Request(
        API + path,
        data=json.dumps(body).encode() if body is not None else None,
        method=method,
        headers={
            "Authorization": f"Bearer {api_key()}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.load(resp), None
    except urllib.error.HTTPError as e:
        return None, f"HTTP {e.code}: {e.read().decode(errors='replace')[:300]}"
    except Exception as e:  # noqa: BLE001 - report, never fake
        return None, str(e)


def load(path):
    return json.loads(pathlib.Path(path).read_text())


def save(path, data):
    p = pathlib.Path(path)
    p.write_text(json.dumps(data, indent=1, sort_keys=True) + "\n")


def cmd_launch(args):
    manifest = load(args.manifest)
    state_path = pathlib.Path(args.state)
    state = load(state_path) if state_path.exists() else {
        "campaign": manifest.get("name", "wave"),
        "model": manifest.get("model", "cursor-grok-4.6-high"),
        "source": manifest["source"],
        "items": {},
    }
    preamble = manifest.get("preamble", "").strip()
    launched = skipped = failed = 0
    for item in manifest["items"]:
        key = item["key"]
        rec = state["items"].setdefault(key, {})
        if rec.get("agentId"):
            skipped += 1
            continue
        text = (preamble + "\n\n" + item["prompt"].strip()).strip()
        body = {
            "prompt": {"text": text},
            "model": state["model"],
            "source": state["source"],
            "target": {"autoCreatePr": True},
        }
        out, err = call("POST", "/v0/agents", body)
        if err:
            rec["launchError"] = err
            failed += 1
            print(f"FAIL   {key}: {err}")
        else:
            rec.update(
                agentId=out.get("id"),
                agentName=out.get("name"),
                agentUrl=(out.get("target") or {}).get("url")
                or f"https://cursor.com/agents/{out.get('id')}",
                status=out.get("status", "CREATING"),
                launchedAt=out.get("createdAt"),
            )
            rec.pop("launchError", None)
            launched += 1
            print(f"LAUNCH {key}: {out.get('id')}")
        save(state_path, state)  # persist after every call; rerun is resume
        time.sleep(args.stagger)
    total = len(manifest["items"])
    print(f"wave: {launched} launched, {skipped} already-launched, "
          f"{failed} failed (denominator={total})")
    return 1 if failed else 0


def refresh(state):
    for key, rec in state["items"].items():
        if not rec.get("agentId") or rec.get("status") in TERMINAL:
            continue
        out, err = call("GET", f"/v0/agents/{rec['agentId']}")
        if err:
            rec["pollError"] = err
            continue
        rec.pop("pollError", None)
        rec["status"] = out.get("status", rec.get("status"))
        pr = (out.get("target") or {}).get("prUrl")
        if pr:
            rec["prUrl"] = pr
        summary = out.get("summary")
        if summary:
            rec["summary"] = summary


def cmd_status(args):
    state = load(args.state)
    if args.refresh:
        refresh(state)
        save(args.state, state)
    counts = {}
    for key in sorted(state["items"]):
        rec = state["items"][key]
        st = rec.get("status", "UNLAUNCHED")
        counts[st] = counts.get(st, 0) + 1
        print(f"{st:10} {key:28} {rec.get('prUrl', '-')}")
    total = len(state["items"])
    summary = " ".join(f"{k}={v}" for k, v in sorted(counts.items()))
    print(f"wave: {summary} (denominator={total})")


def cmd_followup(args):
    state = load(args.state)
    rec = state["items"].get(args.key) or sys.exit(f"wave: unknown key {args.key}")
    if not rec.get("agentId"):
        sys.exit(f"wave: {args.key} was never launched")
    text = pathlib.Path(args.prompt_file).read_text().strip()
    out, err = call("POST", f"/v0/agents/{rec['agentId']}/followup",
                    {"prompt": {"text": text}})
    if err:
        sys.exit(f"wave: followup failed: {err}")
    rec.setdefault("followups", []).append({"at": time.strftime("%FT%TZ", time.gmtime())})
    save(args.state, state)
    print(f"FOLLOWUP {args.key}: delivered to {rec['agentId']}")


def cmd_collect(args):
    state = load(args.state)
    refresh(state)
    save(args.state, state)
    lines = [f"# Wave report: {state['campaign']}",
             "",
             f"Model: `{state['model']}` · repo {state['source']['repository']}"
             f" @ {state['source'].get('ref', 'main')}",
             "",
             "| key | status | PR | summary |",
             "| --- | --- | --- | --- |"]
    for key in sorted(state["items"]):
        rec = state["items"][key]
        lines.append(
            f"| {key} | {rec.get('status', 'UNLAUNCHED')} "
            f"| {rec.get('prUrl', '-')} "
            f"| {(rec.get('summary') or '').replace('|', '/')[:140]} |")
    terminal = sum(1 for r in state["items"].values()
                   if r.get("status") in TERMINAL)
    lines += ["", f"{terminal} of {len(state['items'])} agents terminal."]
    report = "\n".join(lines) + "\n"
    if args.out:
        pathlib.Path(args.out).write_text(report)
        print(f"wave: report written to {args.out}")
    else:
        print(report)


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("launch")
    a.add_argument("--manifest", required=True)
    a.add_argument("--state", required=True)
    a.add_argument("--stagger", type=float, default=3.0,
                   help="seconds between launches")
    a.set_defaults(fn=cmd_launch)
    b = sub.add_parser("status")
    b.add_argument("--state", required=True)
    b.add_argument("--refresh", action="store_true")
    b.set_defaults(fn=cmd_status)
    c = sub.add_parser("followup")
    c.add_argument("--state", required=True)
    c.add_argument("--key", required=True)
    c.add_argument("--prompt-file", required=True)
    c.set_defaults(fn=cmd_followup)
    d = sub.add_parser("collect")
    d.add_argument("--state", required=True)
    d.add_argument("--out")
    d.set_defaults(fn=cmd_collect)
    args = p.parse_args()
    sys.exit(args.fn(args) or 0)


if __name__ == "__main__":
    main()
