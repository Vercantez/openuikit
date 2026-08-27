#!/usr/bin/env python3
"""variance.py -- read N run logs and split the suite into stable and unstable.

A single 108-scene pass is a SAMPLE, not a measurement, when the failures are
address-dependent. This reports the three populations that matter:

  ALWAYS PASS   rendered in every run          -- the real capability floor
  ALWAYS FAIL   failed in every run            -- the real wall
  FLIPPED       passed in some runs, not others -- residual address sensitivity

The flippers are the interesting rows: a stable pass and a stable fail both
hide the fact that placement still matters, and only the flip rate shows it.

Usage: variance.py <run1.txt> <run2.txt> ...
Each file is run_suite.sh output: "<scene> ok" or "<scene> EXIT=<n>".
"""
import re
import sys
from collections import defaultdict


def parse(path):
    """-> {scene: True/False}, and how each failure presented.

    HANG must be parsed, not skipped. Skipping it silently drops the scene from
    that run, and a scene missing from one run then looks like a FLIPPER -- which
    is how constraints_form_row first showed up as "FAIL FAIL" in the flipper
    list, a contradiction that gave the bug away.
    """
    ok, how = {}, {}
    for line in open(path):
        m = re.match(r"^(\S+)\s+(ok|HANG|EXIT=(\d+))\s*$", line)
        if not m:
            continue
        scene, verdict = m.group(1), m.group(2)
        ok[scene] = verdict == "ok"
        if verdict == "HANG":
            how[scene] = "HANG"
        elif m.group(3):
            how[scene] = int(m.group(3))
    return ok, how


def main():
    paths = sys.argv[1:]
    if not paths:
        sys.exit("usage: variance.py <run1.txt> ...")
    runs = [parse(p) for p in paths]
    scenes = sorted(set().union(*(set(r[0]) for r in runs)))

    always_pass, always_fail, flipped = [], [], []
    for s in scenes:
        results = [r[0].get(s) for r in runs]
        if any(x is None for x in results):
            # A scene absent from a run is a HOLE in the data, not a result.
            # Reporting it as a pass or a fail would invent a measurement.
            flipped.append((s, ["ok" if x else ("FAIL" if x is False else "MISSING")
                                for x in results]))
        elif all(results):
            always_pass.append(s)
        elif not any(results):
            always_fail.append(s)
        else:
            flipped.append((s, ["ok" if x else "FAIL" for x in results]))

    n = len(paths)
    print("VARIANCE across %d full runs of %d scenes" % (n, len(scenes)))
    for p, r in zip(paths, runs):
        passed = sum(1 for v in r[0].values() if v)
        print("   %-28s %d ok / %d" % (p.split("/")[-1], passed, len(r[0])))
    print()
    print("  ALWAYS PASS : %3d   <- the capability floor" % len(always_pass))
    print("  ALWAYS FAIL : %3d   <- the wall" % len(always_fail))
    print("  FLIPPED     : %3d   <- residual address sensitivity" % len(flipped))
    print("  union that rendered at least once: %d" % (len(always_pass) + len(flipped)))
    print()

    if flipped:
        print("FLIPPERS (the interesting rows):")
        for s, pat in flipped:
            print("   %-32s %s" % (s, "  ".join(pat)))
        print()

    codes = defaultdict(int)
    for s in always_fail:
        for r in runs:
            if s in r[1]:
                codes[r[1][s]] += 1
    if codes:
        print("exit codes among ALWAYS FAIL (all runs pooled):")
        for c, k in sorted(codes.items(), key=lambda kv: -kv[1]):
            what = {139: "SIGSEGV", 133: "SIGTRAP (glibc abort)", 135: "SIGBUS",
                    137: "SIGKILL", 71: "machorun bail",
                    1: "driver reported failure",
                    "HANG": "spun until the 120s timeout"}.get(c, "")
            print("   %-9s %4d   %s" % (c if isinstance(c, str) else "exit %d" % c, k, what))
        print()

    print("ALWAYS FAIL (%d) -- listed, never omitted:" % len(always_fail))
    for s in always_fail:
        print("   ", s)


if __name__ == "__main__":
    main()
