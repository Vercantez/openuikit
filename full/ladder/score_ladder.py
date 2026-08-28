#!/usr/bin/env python3
"""Turn the ladder census into a ranked ladder.

THE RUBRIC IS ORDINAL AND EXPLICIT. Every subscore is a bucket of a MEASURED
quantity, 0 (clear) to 3 (wall), with the thresholds written here rather than
chosen per app. The composite is a plain sum -- no weights, because nothing in
this project measures the relative cost of "one more Apple framework" against
"one more missing UIKit type", and inventing a weight would give the ranking a
precision the inputs do not have.

So: read the SUBSCORES. The total orders apps into bands; it does not claim
that a 12 is twice a 6.

Three extra inputs the census JSON does not carry, all measured separately and
passed in as files:
  nibdeps.tsv   app <tab> #.swift files containing @IBOutlet <tab> #.swift files
  imports-full-*.json  untruncated per-app {module: files-importing-it}
  dep-classes-*.json   per-app rollup of the 30 externally-cloned dependencies,
                       each pushed through ladder_census.py itself (dep_class.py)

THE DEP COLUMN IS A DEMAND ROW, NOT A BUILD NOTE. A dependency must itself
compile against this stack before its app builds at all, so an app whose own
code is perfectly UIKit-shaped is still bounded by its worst LOAD-BEARING
dependency. And `SEL` for route (a) is the app's own `#selector` count PLUS its
load-bearing deps' -- measured, this moves eidolon from 8 to 165.

`DEP` is `?` for an app none of whose external dependencies were among the 30
measured. `?` scores 0, so those apps' totals are FLOORS, not clean sheets.
"""
import json, sys
from collections import defaultdict

HEAVY = {"WebKit","CoreData","AVFoundation","AVKit","MapKit","Photos","PhotosUI","CoreLocation",
         "StoreKit","Metal","MetalKit","SceneKit","SpriteKit","ARKit","Vision","CoreML","HealthKit",
         "CallKit","PushKit","WidgetKit","AppIntents","Intents","IntentsUI","MessageUI","Contacts",
         "EventKit","PassKit","SafariServices","CoreBluetooth","CoreMotion","CoreTelephony",
         "CryptoKit","LocalAuthentication","Security","UserNotifications","BackgroundTasks",
         "CoreImage","CoreText","MediaPlayer","QuickLook","LinkPresentation","SwiftData","Charts",
         "Speech","GroupActivities","CarPlay","WatchConnectivity","WatchKit","MultipeerConnectivity",
         "Network","NetworkExtension","CoreAudio","VideoToolbox","CoreMedia","Accelerate",
         "NaturalLanguage","CoreSpotlight","AuthenticationServices","DeviceCheck","AdSupport",
         "AppTrackingTransparency","GameController","GameplayKit","ExternalAccessory","CloudKit",
         "Social","AlarmKit","CoreHaptics","CoreNFC","ImageIO","AudioToolbox","MobileCoreServices",
         "UniformTypeIdentifiers","SystemConfiguration","CoreServices","AppKit"}

# Third-party stacks that carry the app's NETWORKING, and are therefore
# invisible to the model census's Foundation alphabet.
NETLIBS = {"Alamofire","Moya","AFNetworking","Apollo","ApolloAPI","GraphAPI","Starscream",
           "SocketRocket","NIOHTTP1","AsyncHTTPClient","SwiftyJSON","AlamofireImage","Kingfisher",
           "SDWebImage","Nuke","HAKit","PromiseKit","ReactiveSwift","RxSwift","RxCocoa"}

# Worst-load-bearing-dependency class -> subscore. UIKit-bound is cheap here
# (OpenUIKit exists); SwiftUI/Combine-bound is the wall (it does not).
DEP_SCORE = {"pure-Swift portable": 0, "Foundation-heavy": 1, "UIKit-bound": 1,
             "networking-bound": 2, "ObjC": 2, "SwiftUI/Combine-bound": 3}

FREE = {"NSCoder","NSObject","NSString","NSValue"}
OOS  = {"UINib","UIStoryboard","UIStoryboardSegue","UIWebView"}


def bucket(v, t1, t2, t3):
    return 0 if v < t1 else 1 if v < t2 else 2 if v < t3 else 3


def main():
    census = json.load(open(sys.argv[1]))["apps"]
    imports = json.load(open(sys.argv[2]))
    nib = {}
    for line in open(sys.argv[3]):
        a, ib, sw = line.split()
        nib[a] = (int(ib), int(sw))
    deprol = json.load(open(sys.argv[4]))["per_app"] if len(sys.argv) > 5 else {}

    rows = []
    for a, v in census.items():
        u, s, m = v["uikit"], v["swiftui"], v["model"]
        miss = dict(u["missing"])
        gap = sum(c for t, c in miss.items() if t not in FREE and t not in OOS)
        gapT = len([t for t in miss if t not in FREE and t not in OOS])

        sui_f = s.get("view_bearing_files", 0)
        uik_f = s.get("uikit_subclass_files", 0)
        sui_pct = 100.0 * sui_f / (sui_f + uik_f) if (sui_f + uik_f) else 0.0

        ibf, swf = nib.get(a, (0, 1))
        nib_pct = 100.0 * ibf / swf if swf else 0.0

        imp = imports[a]
        heavy = sum(1 for h in HEAVY if imp.get(h, 0))
        mods = len(imp)
        netlib_files = sum(imp.get(n, 0) for n in NETLIBS)
        netuses = m["families"].get("networking", 0)
        sel = s.get("selector_sites", 0)
        files = s.get("files", 0)

        # ObjC share of source. An ObjC-majority app is not on the Swift
        # recompile path at all -- it needs the ObjC FACADE as a real
        # UIKit.framework, which docs/OBJC_FACADE.md sizes at ~10k lines for
        # the top-20 types and ~30k for everything. Different, farther project.
        mlines = (v["languages"]["lines"].get(".m", 0)
                  + v["languages"]["lines"].get(".mm", 0))
        objc_pct = 100.0 * mlines / (mlines + v["swift_lines"]) if (mlines + v["swift_lines"]) else 0.0

        sc = {
            "UI":   bucket(sui_pct, 10, 25, 50),
            "OBJC": bucket(objc_pct, 2, 10, 30),
            "NIB":  0 if ibf == 0 else bucket(nib_pct, 0.01, 5, 15),
            "UIK":  0 if gap == 0 else bucket(gap, 1, 100, 500),
            "MOD":  bucket(mods, 25, 50, 100),
            "FW":   bucket(heavy, 3, 9, 21),
            "NET":  min(3, bucket(netuses, 50, 300, 800) + (1 if netlib_files >= 10 else 0)),
            "SIZE": bucket(files, 300, 800, 2000),
        }
        dr = deprol.get(a)
        dep_cls = dr["worst_load_bearing_class"] if dr else None
        sc["DEP"] = DEP_SCORE.get(dep_cls, 0) if dr else 0
        dep_sel = dr["load_bearing_selector_sites"] if dr else 0
        total_sel = sel + dep_sel
        sc_a = dict(sc)
        sc_a["SEL"] = 0 if total_sel == 0 else bucket(total_sel, 1, 11, 101)

        rows.append({
            "app": a,
            "score_b": sum(sc.values()), "score_a": sum(sc_a.values()),
            "sub": sc, "sel_bucket": sc_a["SEL"],
            "dep_class": dep_cls, "dep_measured": bool(dr),
            "raw": {"swift_files": files, "swift_lines": v["swift_lines"],
                    "dep_selector_sites": dep_sel, "total_selector_sites": total_sel,
                    "load_bearing_deps": dr["load_bearing"] if dr else None,
                    "sui_pct": round(sui_pct, 1), "sui_files": sui_f, "uikit_files": uik_f,
                    "nib_files": ibf, "nib_pct": round(nib_pct, 1),
                    "uikit_uses": u["uses"], "uikit_gap_uses": gap, "uikit_gap_types": gapT,
                    "uikit_eff_pct": round(100.0 * (u["uses"] - gap) / u["uses"], 1) if u["uses"] else 0,
                    "modules": mods, "heavy_frameworks": heavy,
                    "model_uses": m["uses"], "net_uses": netuses, "netlib_files": netlib_files,
                    "selector_sites": sel, "selector_wiring": s.get("selector_wiring", 0),
                    "selector_deep": s.get("selector_deep", 0),
                    "selector_unclassified": s.get("selector_unclassified", 0),
                    "objc_sites": s.get("objc_sites", 0),
                    "objc_m_files": v["languages"]["files"].get(".m", 0),
                    "objc_m_lines": mlines, "objc_pct": round(objc_pct, 1)},
            "build": {k: vv for k, vv in v["build"].items() if k != "_dep_urls"},
        })

    # SwiftUI-majority is a GATE, not a summand: a majority-SwiftUI app is FAR
    # regardless of everything else, because the framework does not exist here.
    for r in rows:
        if r["sub"]["UI"] == 3:
            r["verdict_b"] = "FAR (SwiftUI-majority)"
        elif r["sub"]["DEP"] == 3:
            r["verdict_b"] = "FAR (SwiftUI-bound load-bearing dep)"
        elif r["sub"]["OBJC"] == 3:
            r["verdict_b"] = "FAR (ObjC-majority: facade project)"
        elif r["score_b"] <= 9:
            r["verdict_b"] = "NEAR"
        elif r["score_b"] <= 16:
            r["verdict_b"] = "MID"
        else:
            r["verdict_b"] = "FAR"
        if r["sub"]["UI"] == 3:
            r["verdict_a"] = "FAR (SwiftUI-majority)"
        elif r["sub"]["DEP"] == 3:
            r["verdict_a"] = "FAR (SwiftUI-bound load-bearing dep)"
        elif r["sub"]["OBJC"] == 3:
            r["verdict_a"] = "FAR (ObjC-majority: facade project)"
        elif r["sel_bucket"] == 3:
            r["verdict_a"] = "FAR (#selector wall)"
        elif r["score_a"] <= 11:
            r["verdict_a"] = "NEAR"
        elif r["score_a"] <= 19:
            r["verdict_a"] = "MID"
        else:
            r["verdict_a"] = "FAR"

    rows.sort(key=lambda r: (r["score_b"], r["score_a"]))
    json.dump(rows, open(sys.argv[5] if len(sys.argv) > 5 else sys.argv[4], "w"), indent=1)

    hdr = ["UI", "OBJC", "NIB", "UIK", "DEP", "MOD", "FW", "NET", "SIZE"]
    print(f"{'app':<20}" + "".join(f"{h:>6}" for h in hdr)
          + f"{'=B':>5}{'SEL':>5}{'=A':>5}  {'verdict (b) Apple tc':<24}verdict (a) Linux swiftc")
    for r in rows:
        print(f"{r['app']:<20}" + "".join(f"{(str(r['sub'][h]) if (h != 'DEP' or r['dep_measured']) else '?'):>6}" for h in hdr)
              + f"{r['score_b']:>5}{r['sel_bucket']:>5}{r['score_a']:>5}  "
              + f"{r['verdict_b']:<24}{r['verdict_a']}")


main()
