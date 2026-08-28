#!/usr/bin/env python3
"""Classify each external dependency by RUNNING THE SAME INSTRUMENTS ON IT.

A dependency is a demand row of its own: it must compile against our stack
before its app builds at all, and a dep that is SwiftUI/Combine-bound or
Objective-C drags its app down regardless of the app's own code. So the deps
are cloned (`clone_deps.sh`) and pushed through `ladder_census.py` exactly like
the apps -- the classification below is MEASURED, not a name-lookup table.

Classes, assigned by rule, in this order (first match wins):

  ObjC                  >=30% of source lines are .m/.mm -- the facade road
  SwiftUI/Combine-bound declares a `: View`/`some View`, or imports Combine
                        in >=10% of its files
  UIKit-bound           imports UIKit in >=10% of its files (needs OpenUIKit,
                        not just Foundation -- a different, larger surface)
  networking-bound      references the URLSession family (all ABSENT here)
  Foundation-heavy      >=1 model-layer reference per 2 files, no networking
  pure-Swift portable   none of the above

The `#selector` column is the route-(a) column and is reported for every dep,
because a dep with `#selector` blocks route (a) for EVERY app that uses it --
which is the compounding the app-only count misses.

    ./dep_class.py <deps-census.json> <deps.json> <out.json> <app-census.json>
"""
import json, sys
from collections import defaultdict

NET = {"URLSession", "URLSessionTask", "URLSessionDataTask", "URLSessionDownloadTask",
       "URLSessionUploadTask", "URLSessionConfiguration", "URLSessionDelegate",
       "URLSessionTaskDelegate", "URLSessionDataDelegate", "URLRequest", "URLResponse",
       "HTTPURLResponse", "URLComponents", "URLQueryItem", "URLCache", "URLCredential",
       "URLProtectionSpace", "URLAuthenticationChallenge", "NSURLSession", "NSURLRequest",
       "NSURLResponse", "NSHTTPURLResponse", "NSURLComponents", "NSURLConnection",
       "URLProtocol", "NSURLProtocol", "URLError"}


def classify(d):
    s, m = d["swiftui"], d["model"]
    files = max(1, s.get("files", 0))
    mlines = d["languages"]["lines"].get(".m", 0) + d["languages"]["lines"].get(".mm", 0)
    objc_pct = 100.0 * mlines / max(1, mlines + d["swift_lines"])
    net = m["families"].get("networking", 0)
    # Thresholds, and why they are not "> 0". A FIRST PASS used `if net:` and
    # `if view_bearing_files:` and got two libraries wrong in a way that looked
    # authoritative: SwiftSoup (an HTML parser, ONE incidental URL-family
    # reference) came out "networking-bound", and Alamofire and GRDB came out
    # "SwiftUI-bound" off a demo app and a documentation folder. The demo
    # folders are now excluded from the walk; these thresholds are the second
    # guard, so a single incidental reference cannot rename a library.
    if objc_pct >= 30:
        return "ObjC", objc_pct, net
    if (s.get("view_bearing_files", 0) >= 3
            or s.get("import_swiftui", 0) >= 0.05 * files
            or s.get("import_combine", 0) >= 0.10 * files):
        return "SwiftUI/Combine-bound", objc_pct, net
    if s.get("import_uikit", 0) >= 0.10 * files:
        return "UIKit-bound", objc_pct, net
    if net >= 25 and net >= files / 4:
        return "networking-bound", objc_pct, net
    if m["uses"] >= files / 2:
        return "Foundation-heavy", objc_pct, net
    return "pure-Swift portable", objc_pct, net


def main():
    census = json.load(open(sys.argv[1]))["apps"]
    deps = json.load(open(sys.argv[2]))
    used_by = {r["module"]: r["in"] for r in deps["_union_external"]}
    # Import name != repo name for a few; map the ones this corpus needs.
    ALIAS = {"Apollo": ["Apollo", "ApolloAPI", "ApolloTestSupport"],
             "GRDB": ["GRDB"], "Lottie": ["Lottie"], "Sentry": ["Sentry"],
             "RealmSwift": ["RealmSwift", "Realm"], "SDWebImage": ["SDWebImage"],
             "CocoaLumberjack": ["CocoaLumberjack", "CocoaLumberjackSwift"],
             "ReactiveSwift": ["ReactiveSwift", "ReactiveExtensions_TestHelpers"],
             "RxSwift": ["RxSwift", "RxCocoa", "RxOptional", "RxBlocking", "RxNimble"],
             "Alamofire": ["Alamofire"], "AlamofireImage": ["AlamofireImage"],
             "Nimble": ["Nimble", "Nimble_Snapshots"]}

    rows = []
    for name, d in sorted(census.items()):
        cls, objc_pct, net = classify(d)
        names = ALIAS.get(name, [name])
        apps = sorted({a for n in names for a in used_by.get(n, [])})
        s = d["swiftui"]
        rows.append({
            "dep": name, "class": cls, "apps": apps, "n_apps": len(apps),
            "swift_files": s.get("files", 0), "swift_lines": d["swift_lines"],
            "objc_pct": round(objc_pct, 1),
            "import_uikit": s.get("import_uikit", 0),
            "import_swiftui": s.get("import_swiftui", 0),
            "import_combine": s.get("import_combine", 0),
            "view_files": s.get("view_bearing_files", 0),
            "model_uses": d["model"]["uses"], "net_uses": net,
            "selector_sites": s.get("selector_sites", 0),
            "objc_sites": s.get("objc_sites", 0),
            "uikit_gap_uses": sum(c for t, c in d["uikit"]["missing"]),
        })
    rows.sort(key=lambda r: (-r["n_apps"], -r["swift_lines"]))
    json.dump(rows, open(sys.argv[3], "w"), indent=1)

    print(f"{'dep':<17}{'apps':>5}{'files':>7}{'lines':>9}{'ObjC%':>7}{'impUIK':>7}"
          f"{'impSUI':>7}{'impCmb':>7}{'net':>5}{'#sel':>6}{'@objc':>7}  class")
    for r in rows:
        print(f"{r['dep']:<17}{r['n_apps']:>5}{r['swift_files']:>7}{r['swift_lines']:>9}"
              f"{r['objc_pct']:>7}{r['import_uikit']:>7}{r['import_swiftui']:>7}"
              f"{r['import_combine']:>7}{r['net_uses']:>5}{r['selector_sites']:>6}"
              f"{r['objc_sites']:>7}  {r['class']}")
    by = defaultdict(list)
    for r in rows:
        by[r["class"]].append(r["dep"])
    print()
    for c, ds in sorted(by.items(), key=lambda kv: -len(kv[1])):
        print(f"{c:<24}{len(ds):>3}   {', '.join(ds)}")
    print(f"\ndeps with ZERO #selector (route-(a) clean): "
          f"{len([r for r in rows if r['selector_sites'] == 0])} of {len(rows)}")

    # Per-app rollup. Two refinements the first version lacked, both because
    # the first version was misleading:
    #
    #  (a) LOAD-BEARING vs PERIPHERAL. "The worst dep bounds the rung" is only
    #      true of a dep the app is BUILT ON. A crash reporter imported by 2
    #      files and a reactive framework imported by 434 are not the same
    #      constraint, and the first pass ranked focus-ios by `Sentry`, which
    #      2 of its 227 files import. A dep is LOAD-BEARING here if >=5% of the
    #      app's Swift files import it; otherwise it is a candidate for
    #      deletion or a stub, and the app's rung should not be set by it.
    #
    #  (b) A DEP'S `#selector` BLOCKS ROUTE (a) EXACTLY AS HARD AS THE APP'S.
    #      The app-only count in the ladder is therefore not the real one.
    SEVERITY = ["SwiftUI/Combine-bound", "ObjC", "networking-bound",
                "UIKit-bound", "Foundation-heavy", "pure-Swift portable"]
    print("\nPER-APP ROLLUP over the 30 MEASURED deps (a FLOOR -- every app also has "
          "\nunmeasured deps, so the true worst class can only be worse):")
    print(f"  {'app':<20}{'deps':>7}{'bearing':>9}{'own#sel':>9}{'dep#sel':>9}"
          f"{'total':>8}   worst LOAD-BEARING dep class")
    appcensus = json.load(open(sys.argv[4]))["apps"]
    ext = {a: v["external"] for a, v in json.load(open(sys.argv[2])).items()
           if not a.startswith("_")}
    per = defaultdict(list)
    for r in rows:
        for a in r["apps"]:
            per[a].append(r)
    roll = {}
    for a in sorted(per):
        nfiles = max(1, appcensus[a]["swiftui"].get("files", 0))
        own = appcensus[a]["swiftui"].get("selector_sites", 0)
        ds = per[a]
        for d in ds:
            d_files = ext[a].get(d["dep"], 0)
            for alias, real in (("Apollo", ["Apollo", "ApolloAPI", "ApolloTestSupport"]),
                                ("RxSwift", ["RxSwift", "RxCocoa", "RxOptional",
                                             "RxBlocking", "RxNimble"]),
                                ("ReactiveSwift", ["ReactiveSwift",
                                                   "ReactiveExtensions_TestHelpers"]),
                                ("Nimble", ["Nimble", "Nimble_Snapshots"]),
                                ("CocoaLumberjack", ["CocoaLumberjack",
                                                     "CocoaLumberjackSwift"]),
                                ("RealmSwift", ["RealmSwift", "Realm"]),
                                ("SDWebImage", ["SDWebImage", "SDWebImageSwiftUI"])):
                if d["dep"] == alias:
                    d_files = sum(ext[a].get(n, 0) for n in real)
            d["_files_here"] = d_files
        bearing = [d for d in ds if d["_files_here"] >= 0.05 * nfiles]
        def worst_of(lst):
            if not lst:
                return None, []
            w = min(SEVERITY.index(d["class"]) for d in lst)
            return SEVERITY[w], [d["dep"] for d in lst if d["class"] == SEVERITY[w]]
        wc, wd = worst_of(bearing)
        allc, _ = worst_of(ds)
        dep_sel = sum(d["selector_sites"] for d in ds)
        bear_sel = sum(d["selector_sites"] for d in bearing)
        roll[a] = {"measured_deps": len(ds), "load_bearing": [d["dep"] for d in bearing],
                   "worst_load_bearing_class": wc, "worst_load_bearing_deps": wd,
                   "worst_any_class": allc,
                   "own_selector_sites": own, "dep_selector_sites": dep_sel,
                   "load_bearing_selector_sites": bear_sel,
                   "total_selector_sites": own + dep_sel}
        print(f"  {a:<20}{len(ds):>7}{len(bearing):>9}{own:>9}{dep_sel:>9}"
              f"{own + dep_sel:>8}   {wc or '-'}"
              + (f" ({', '.join(wd)})" if wd else ""))
    json.dump({"deps": rows, "per_app": roll}, open(sys.argv[3], "w"), indent=1)


main()
