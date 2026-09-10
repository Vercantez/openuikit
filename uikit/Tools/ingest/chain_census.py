#!/usr/bin/env python3
"""Build a spm_app_chain.py package target by target and record the diagnostics.

For every target in the spec (shims first, then targets in order) run
`swift build --target <name>` in the generated package, parse the compiler
diagnostics, and write a JSON census: per target the unique error count, the
files touched, and the errors grouped by a normalised message (identifiers
in quotes kept, so "has no member 'foo'" stays distinct per member). The run
stops at the first target that fails unless --continue is given; a failing
target's dependents are reported as "not reached", never as passing.

    python3 Tools/ingest/chain_census.py SPEC --package DIR --out census.json [--continue] [--timeout SEC]
"""
from __future__ import annotations

import argparse
import collections
import json
import os
import re
import subprocess
import sys
import time

DIAG = re.compile(r"^(?P<file>/[^:\n]+\.swift):(?P<line>\d+):(?P<col>\d+): (?P<kind>error|warning|note): (?P<msg>.*)$")
QUOTED = re.compile(r"'([^']*)'")


def normalise(msg: str) -> str:
    # keep quoted identifiers, drop free-form tails after ';'
    return msg.split("; ")[0].strip()


def member_of(msg: str) -> str | None:
    m = re.search(r"has no member '([^']+)'", msg)
    if m:
        return m.group(1)
    m = re.search(r"cannot find '([^']+)' in scope", msg)
    if m:
        return m.group(1)
    m = re.search(r"cannot find type '([^']+)' in scope", msg)
    if m:
        return m.group(1)
    m = re.search(r"no such module '([^']+)'", msg)
    if m:
        return "module " + m.group(1)
    return None


def run_target(pkg: str, name: str, timeout: int, jobs: int) -> dict:
    own_dir = os.path.realpath(os.path.join(pkg, "Sources", name))
    cmd = ["swift", "build", "--target", name, "-j", str(jobs)]
    t0 = time.time()
    try:
        p = subprocess.run(cmd, cwd=pkg, capture_output=True, text=True, timeout=timeout)
        rc, out = p.returncode, p.stdout + "\n" + p.stderr
    except subprocess.TimeoutExpired as e:
        rc, out = -9, (e.stdout or "") + "\n" + (e.stderr or "") + "\n<timeout>"
    seen = set()
    errors = []
    notes = []
    for line in out.splitlines():
        m = DIAG.match(line.strip())
        if not m:
            continue
        key = (m.group("file"), m.group("line"), m.group("col"), m.group("msg"))
        if key in seen:
            continue
        seen.add(key)
        rec = {"file": m.group("file"), "line": int(m.group("line")), "col": int(m.group("col")),
               "msg": m.group("msg"), "own": os.path.realpath(m.group("file")).startswith(own_dir + os.sep)}
        if m.group("kind") == "error":
            errors.append(rec)
        elif m.group("kind") == "note" and "protocol requires" in m.group("msg"):
            # "protocol requires property 'x' with type 'T'; add a stub for conformance"
            notes.append(rec)
    own_errors = [e for e in errors if e["own"]]
    dep_errors = [e for e in errors if not e["own"]]
    requirements = collections.Counter(re.sub(r"; .*$", "", n["msg"]) for n in notes)
    groups = collections.Counter(normalise(e["msg"]) for e in errors)
    members = collections.Counter(member_of(e["msg"]) for e in errors if member_of(e["msg"]))
    files = collections.Counter(os.path.basename(e["file"]) for e in errors)
    # "error: <msg>" lines without a file (manifest/link errors)
    other = sorted({l.strip() for l in out.splitlines() if l.strip().startswith("error:")})
    status = "passed" if rc == 0 else ("timeout" if rc == -9 else "failed")
    if status == "failed" and errors and not own_errors:
        status = "blocked by dependency"
    return {
        "target": name, "command": " ".join(cmd), "exit": rc, "seconds": round(time.time() - t0, 1),
        "unique_errors": len(errors), "own_errors": len(own_errors), "dependency_errors": len(dep_errors),
        "files_with_errors": len(files),
        "errors_by_message": groups.most_common(), "missing_members": members.most_common(),
        "unmet_protocol_requirements": requirements.most_common(),
        "errors_by_file": files.most_common(), "other_errors": other[:50],
        "errors": errors, "notes": notes,
        "status": status,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("spec")
    ap.add_argument("--package", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--only", nargs="*", help="restrict to these targets (still in spec order)")
    ap.add_argument("--continue", dest="cont", action="store_true")
    ap.add_argument("--timeout", type=int, default=540)
    ap.add_argument("--jobs", type=int, default=4)
    args = ap.parse_args()
    spec = json.load(open(args.spec))
    order = [t["name"] for t in spec.get("shims", [])] + [t["name"] for t in spec["targets"]]
    if args.only:
        order = [n for n in order if n in set(args.only)]
    results = []
    if os.path.exists(args.out):
        try:
            results = [r for r in json.load(open(args.out))["targets"] if r["status"] == "passed" and r["target"] not in (args.only or [])]
        except Exception:
            results = []
    done = {r["target"] for r in results}
    stopped = None
    for name in order:
        if name in done:
            continue
        if stopped and not args.cont:
            results.append({"target": name, "status": "not reached", "blocked_by": stopped})
            continue
        r = run_target(args.package, name, args.timeout, args.jobs)
        print(f"{name}: {r['status']} exit={r['exit']} errors={r['unique_errors']} (own {r['own_errors']}, deps {r['dependency_errors']}) files={r['files_with_errors']} {r['seconds']}s", flush=True)
        for msg, n in r["errors_by_message"][:5]:
            print(f"   {n:4d}  {msg}")
        results.append(r)
        if r["status"] != "passed" and not stopped:
            stopped = name
        with open(args.out, "w") as f:
            json.dump({"spec": os.path.abspath(args.spec), "package": os.path.abspath(args.package),
                       "targets": results}, f, indent=1)
    with open(args.out, "w") as f:
        json.dump({"spec": os.path.abspath(args.spec), "package": os.path.abspath(args.package),
                   "targets": results}, f, indent=1)
    return 0 if not stopped else 2


if __name__ == "__main__":
    sys.exit(main())
