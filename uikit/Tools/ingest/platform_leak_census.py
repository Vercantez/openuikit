#!/usr/bin/env python3
"""Split a chain_census target's errors into macOS-branch leakage vs the rest.

Route (b) on the macOS triple compiles every `#if os(macOS)` /
`canImport(AppKit)` branch of an app's packages and drops every
`#if os(iOS)` / `canImport(UIKit)` one. This tool attributes a target's
errors to that leakage when it can prove it, and leaves the rest as the
port's (or the app's) own work list. It is a LOWER bound: cascades (an
expression that fails because an earlier leaked name did) stay in "rest".

  L1 the message names an AppKit type, or an RS*-style alias that resolves
     to one on macOS (NSImage, NSColor, NSFont, NSView, RSImage, RSColor, ...)
  L2 the message says "unavailable in macOS"
  L3 the name the error is about (cannot find X / has no member X) is
     defined in the scoped corpus only inside a branch the macOS compile drops
  L4 a member of type T defined only in a dropped `extension T` (the name
     may exist elsewhere, e.g. `UIStoryboard.account` vs a local `account`)

    python3 platform_leak_census.py CENSUS.json TARGET_SCOPE.json CORPUS_APP_DIR TARGET [--out OUT.json]

TARGET_SCOPE.json is full/ladder/target_scope.py output; its `files` plus
`excluded_whole_file_guard` are the definitions searched.
"""
from __future__ import annotations

import argparse
import collections
import json
import os
import re
import sys

MAC_TRUE = re.compile(r"os\(macOS\)|os\(OSX\)|canImport\(AppKit\)|targetEnvironment\(macCatalyst\)")
IOS_TRUE = re.compile(r"os\(iOS\)|canImport\(UIKit\)|os\(tvOS\)|os\(visionOS\)|os\(watchOS\)")
DEF = re.compile(r"\b(?:func|var|let|class|struct|enum|protocol|typealias|case|actor)\s+`?([A-Za-z_][A-Za-z0-9_]*)")
NAME = re.compile(r"(?:cannot find (?:type )?'([^']+)' in scope|has no member '([^']+)')")
APPKIT = re.compile(r"\b(NSImage|NSColor|NSFont|NSView|NSViewController|RSImage|RSColor|RSFont|RSView)\b")


def active_on_macos(cond: str) -> bool | None:
    """Whether a `#if` condition is true when compiling for macOS (None: unknown)."""
    c = cond.strip()
    if "||" in c:
        vals = [active_on_macos(p) for p in c.split("||")]
        if any(v is True for v in vals):
            return True
        return False if all(v is False for v in vals) else None
    if "&&" in c:
        vals = [active_on_macos(p) for p in c.split("&&")]
        if any(v is False for v in vals):
            return False
        return True if all(v is True for v in vals) else None
    neg = c.startswith("!")
    core = c.lstrip("!").strip()
    if MAC_TRUE.search(core) and not IOS_TRUE.search(core):
        v = "macCatalyst" not in core
        return (not v) if neg else v
    if IOS_TRUE.search(core) and not MAC_TRUE.search(core):
        return neg
    return None


def definitions(paths: dict[str, str]) -> dict[str, list[tuple[str, int, bool, str]]]:
    """name -> [(relpath, line, active_on_macos, dropped-conditions)] from {relpath: text}."""
    defs = collections.defaultdict(list)
    for rel, text in paths.items():
        stack: list[list] = []
        for i, line in enumerate(text.splitlines(), 1):
            s = line.split("//")[0].strip()
            if s.startswith("#if "):
                c = s[4:]
                stack.append([c, active_on_macos(c)])
                continue
            if s.startswith("#elseif "):
                prev = stack[-1] if stack else ["", None]
                c = s[8:]
                stack[-1] = [f"!({prev[0]}) && {c}", (False if prev[1] is True else active_on_macos(c))]
                continue
            if s.startswith("#else"):
                if stack:
                    c, a = stack[-1]
                    stack[-1] = [f"!({c})", (None if a is None else not a)]
                continue
            if s.startswith("#endif"):
                if stack:
                    stack.pop()
                continue
            for m in DEF.finditer(s):
                active = all(a is not False for _, a in stack)
                conds = " && ".join(c for c, a in stack if a is False)
                defs[m.group(1)].append((rel, i, active, conds))
    return defs


def classify(errors: list[dict], defs, texts: dict[str, str]) -> dict:
    leak, where, rest, per_file = (collections.Counter() for _ in range(4))
    for e in errors:
        msg = e["msg"]
        why = None
        if APPKIT.search(msg):
            why = "L1 AppKit type via the macOS branch (" + APPKIT.search(msg).group(1) + ")"
        elif "unavailable in macOS" in msg:
            why = "L2 unavailable in macOS"
        else:
            m = NAME.search(msg)
            if m:
                name = m.group(1) or m.group(2)
                ds = defs.get(name, [])
                if ds and not any(a for _, _, a, _ in ds):
                    f, ln, _, cond = ds[0]
                    why = "L3 defined only under a dropped branch"
                    where[f"{f}:{ln} [{cond}] {name}"] += 1
                else:
                    tm = re.search(r"(?:value of )?type '([A-Za-z_.]+)'", msg)
                    tname = tm.group(1).split(".")[-1] if tm else None
                    for f, ln, a, cond in (ds if tname else []):
                        if not a and re.search(rf"\b(extension|class|struct)\s+{re.escape(tname)}\b", texts[f]):
                            why = "L4 member defined only in a dropped extension of the type"
                            where[f"{f}:{ln} [{cond}] {tname}.{name}"] += 1
                            break
        if why:
            leak[why] += 1
            per_file[os.path.basename(e["file"])] += 1
        else:
            rest[msg.split("; ")[0]] += 1
    return {"total": len(errors), "leakage": sum(leak.values()), "rest": sum(rest.values()),
            "leakage_by_rule": leak.most_common(), "leakage_definitions": where.most_common(),
            "leakage_by_file": per_file.most_common(), "rest_by_message": rest.most_common()}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("census")
    ap.add_argument("scope")
    ap.add_argument("corpus_app")
    ap.add_argument("target")
    ap.add_argument("--app", default=None, help="app key in the scope file (default: the only one)")
    ap.add_argument("--out")
    a = ap.parse_args()
    apps = json.load(open(a.scope))["apps"]
    scope = apps[a.app or next(iter(apps))]
    rels = [f for f in scope["files"] if f.endswith(".swift")]
    rels += [e["file"] for e in scope.get("excluded_whole_file_guard", [])]
    texts = {r: open(os.path.join(a.corpus_app, r), errors="ignore").read()
             for r in rels if os.path.exists(os.path.join(a.corpus_app, r))}
    t = [x for x in json.load(open(a.census))["targets"] if x["target"] == a.target][0]
    out = {"target": a.target, **classify(t.get("errors", []), definitions(texts), texts)}
    if a.out:
        json.dump(out, open(a.out, "w"), indent=1)
    print(f"{a.target}: total {out['total']} leakage {out['leakage']} rest {out['rest']}")
    for k, v in out["leakage_by_rule"]:
        print(f"  {v:4d} {k}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
