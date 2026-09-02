#!/usr/bin/env python3
"""API census: what UIKit do real apps actually use, and what do we have?

Scans Swift sources for UIKit symbol references, weights them by how many
distinct real-world apps use each symbol, and diffs against OpenUIKit's
exported API. Output is a punch list ordered by real-world demand, not by
UIKit's alphabet.

Usage:
  census.py --apps <dir-of-checkouts> --sdk-types <file> --ours <file>
            [--json report.json] [--top N]

--sdk-types: newline-separated list of real UIKit type names (from the SDK
             headers) so we only count symbols that are genuinely UIKit.
--ours:      newline-separated list of types OpenUIKit exports publicly.
"""
import argparse, json, os, re, sys
from collections import defaultdict

# UIKit-ish identifiers: UIFoo, NSLayoutFoo, CAFoo used in source.
SYMBOL_RE = re.compile(r'\b((?:UI|NS|CA)[A-Z][A-Za-z0-9_]*)\b')
# Members are counted per owning type only when we can see `Type.member` or
# `.member(` — cheap but good enough to rank API demand.
MEMBER_RE = re.compile(r'\b(UI[A-Z][A-Za-z0-9_]*)\s*\.\s*([a-z][A-Za-z0-9_]*)')

SKIP_DIRS = {".git", "Pods", "Carthage", "build", ".build", "DerivedData",
             "node_modules", "vendor", "Tests", "TestsSupport"}

def swift_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for f in filenames:
            if f.endswith(".swift"):
                yield os.path.join(dirpath, f)

def census_app(root, valid_types):
    """Returns (type -> occurrence count, (type,member) -> count) for one app."""
    types = defaultdict(int)
    members = defaultdict(int)
    nfiles = 0
    for path in swift_files(root):
        try:
            src = open(path, errors="ignore").read()
        except OSError:
            continue
        nfiles += 1
        # Strip line comments cheaply so commented-out code doesn't count.
        src = re.sub(r'//[^\n]*', '', src)
        for m in SYMBOL_RE.finditer(src):
            name = m.group(1)
            if name in valid_types:
                types[name] += 1
        for m in MEMBER_RE.finditer(src):
            if m.group(1) in valid_types:
                members[(m.group(1), m.group(2))] += 1
    return types, members, nfiles

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apps", required=True)
    ap.add_argument("--sdk-types", required=True)
    ap.add_argument("--ours", required=True)
    ap.add_argument("--json")
    ap.add_argument("--top", type=int, default=40)
    args = ap.parse_args()

    valid = set(open(args.sdk_types).read().split())
    ours = set(open(args.ours).read().split())

    apps = sorted(d for d in os.listdir(args.apps)
                  if os.path.isdir(os.path.join(args.apps, d)))
    if not apps:
        sys.exit(f"no app checkouts in {args.apps}")

    total_uses = defaultdict(int)      # symbol -> total occurrences
    app_count = defaultdict(int)       # symbol -> number of apps using it
    member_uses = defaultdict(int)
    per_app = {}

    for a in apps:
        t, mem, nfiles = census_app(os.path.join(args.apps, a), valid)
        per_app[a] = {"files": nfiles, "distinct_types": len(t)}
        for k, v in t.items():
            total_uses[k] += v
            app_count[k] += 1
        for k, v in mem.items():
            member_uses[k] += v
        print(f"  {a}: {nfiles} swift files, {len(t)} distinct UIKit types", file=sys.stderr)

    # Demand score: present in many apps first, then raw frequency.
    def score(sym):
        return (app_count[sym], total_uses[sym])

    used = sorted(total_uses, key=score, reverse=True)
    missing = [s for s in used if s not in ours]
    have = [s for s in used if s in ours]

    # Frequency-weighted coverage: of all UIKit symbol occurrences in real
    # apps, what fraction refers to something we implement?
    tot = sum(total_uses.values())
    covered = sum(total_uses[s] for s in have)
    weighted = 100.0 * covered / tot if tot else 0.0

    print(f"\napps scanned: {len(apps)}")
    print(f"distinct UIKit types referenced: {len(used)}")
    print(f"  implemented: {len(have)}   missing: {len(missing)}")
    print(f"frequency-weighted coverage: {weighted:.1f}%"
          f"  ({covered:,} of {tot:,} symbol uses)")

    print(f"\nTOP {args.top} MISSING (ranked by #apps, then uses) — the punch list:")
    print(f"{'symbol':38} {'apps':>5} {'uses':>7}")
    for s in missing[:args.top]:
        print(f"{s:38} {app_count[s]:>5} {total_uses[s]:>7,}")

    if args.json:
        json.dump({
            "apps": per_app,
            "weighted_coverage": weighted,
            "implemented": [{"symbol": s, "apps": app_count[s], "uses": total_uses[s]} for s in have],
            "missing": [{"symbol": s, "apps": app_count[s], "uses": total_uses[s]} for s in missing],
            "missing_members_of_implemented": [
                {"type": t, "member": m, "uses": c}
                for (t, m), c in sorted(member_uses.items(), key=lambda kv: -kv[1])
                if t in ours
            ][:400],
        }, open(args.json, "w"), indent=1)
        print(f"\nwrote {args.json}")

main()
