#!/usr/bin/env python3
"""Two corpus-wide passes the per-app census does not produce.

  1. UNION UIKit census across the whole corpus -- the 20-app analogue of
     APP_COMPAT.md's "~171 distinct types". `ladder_census.py` truncates its
     per-app `top_used` to 40, so the union CANNOT be reconstructed from it;
     this recomputes from source. Same regex, same SKIP_DIRS as apicensus.

  2. UNTRUNCATED per-app import table. `ladder_census.py` keeps only the top 30
     modules per app, which silently hides every Apple framework in an app
     whose top 30 is all in-tree modules (measured: Telegram-iOS looked like it
     imported ZERO heavy frameworks; it imports 44). `score_ladder.py`'s MOD and
     FW subscores read THIS file, not that one.

     Counted PER FILE (a module importing in 100 files counts 100), and
     `import struct Foo.Bar` is unwrapped so the module is `Foo`, not `struct`.

    ./union_and_imports.py <corpus> <sdk-types> <ours> <union.json> <imports.json>
"""
import os, re, sys, json
from collections import defaultdict

SYM = re.compile(r'\b((?:UI|NS|CA)[A-Z][A-Za-z0-9_]*)\b')
IMPORT = re.compile(r'^\s*(?:@[a-zA-Z_]+\s+)*import\s+'
                    r'(?:(?:struct|class|enum|protocol|func|var|let|typealias)\s+)?'
                    r'([A-Za-z_][A-Za-z0-9_]*)', re.M)
SKIP_UIKIT = {".git", "Pods", "Carthage", "build", ".build", "DerivedData",
              "node_modules", "vendor", "Tests", "TestsSupport"}
SKIP_MODEL = {".git", "Carthage", "Pods", ".build"}
FREE = {"NSCoder", "NSObject", "NSString", "NSValue"}
OOS = {"UINib", "UIStoryboard", "UIStoryboardSegue", "UIWebView"}


def main():
    corpus, sdkf, oursf, unionf, impf = sys.argv[1:6]
    sdk = set(open(sdkf).read().split())
    ours = set(open(oursf).read().split())

    apps, uses = defaultdict(set), defaultdict(int)
    imports, files, lines = {}, 0, 0
    for app in sorted(os.listdir(corpus)):
        d = os.path.join(corpus, app)
        if not os.path.isdir(os.path.join(d, ".git")):
            continue
        # pass 1: UIKit union, apicensus walk
        for dp, dn, fn in os.walk(d):
            dn[:] = [x for x in dn if x not in SKIP_UIKIT]
            for f in fn:
                if not f.endswith(".swift"):
                    continue
                files += 1
                src = re.sub(r'//[^\n]*', '',
                             open(os.path.join(dp, f), encoding="utf-8", errors="ignore").read())
                lines += src.count("\n")
                for m in SYM.finditer(src):
                    if m.group(1) in sdk:
                        apps[m.group(1)].add(app)
                        uses[m.group(1)] += 1
        # pass 2: imports, model walk
        cnt = defaultdict(int)
        for dp, dn, fn in os.walk(d):
            dn[:] = [x for x in dn if x not in SKIP_MODEL]
            for f in fn:
                if not f.endswith(".swift"):
                    continue
                src = open(os.path.join(dp, f), encoding="utf-8", errors="ignore").read()
                for m in set(IMPORT.findall(src)):
                    cnt[m] += 1
        imports[app] = dict(sorted(cnt.items(), key=lambda kv: -kv[1]))

    tot = sum(uses.values())
    have = sum(c for t, c in uses.items() if t in ours)
    # FREE/OOS only apply to types we do not declare. Once NSCoder/UINib land
    # in OpenUIKit they are implemented, not a second subtraction.
    free = sum(c for t, c in uses.items() if t in FREE and t not in ours)
    oos = sum(c for t, c in uses.items() if t in OOS and t not in ours)
    gap = tot - have - free - oos
    n10 = [t for t in uses if len(apps[t]) >= 10]

    print(f"{len(imports)}-app union: {files:,} swift files (Tests-excluded walk), "
          f"{tot:,} UIKit uses")
    print(f"distinct UIKit SDK types referenced: {len(uses)} of {len(sdk)} "
          f"({100.0*len(uses)/len(sdk):.0f}%)")
    print(f"  implemented {len([t for t in uses if t in ours])}   "
          f"missing {len([t for t in uses if t not in ours])}")
    print(f"frequency-weighted coverage: {100.0*have/tot:.1f}%")
    print(f"effective coverage (Foundation-free {free} + out-of-scope {oos} removed): "
          f"{100.0*(tot-gap)/tot:.1f}%   gap {gap:,} uses")
    print(f"types referenced by >=10 of {len(imports)} apps: {len(n10)}  "
          f"(missing: {len([t for t in n10 if t not in ours])})")

    json.dump({"apps": len(imports), "swift_files": files, "uses": tot,
               "distinct": len(uses), "weighted_coverage": 100.0 * have / tot,
               "gap_uses": gap,
               "types": {t: {"apps": len(apps[t]), "uses": c, "ours": t in ours}
                         for t, c in sorted(uses.items(), key=lambda kv: -kv[1])}},
              open(unionf, "w"), indent=1)
    json.dump(imports, open(impf, "w"), indent=1)


main()
