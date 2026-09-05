#!/usr/bin/env python3
"""scoreboard.py — the one number-set the fidelity hill-climb climbs.

Collects, into scoreboard/latest.json and scoreboard/latest.md (repo-relative,
committed per round so the climb has a history):

  - the iOS scene suite (scripts/ios_suite.sh work dir, default /tmp/ios_suite):
    per-scene score / blob / layout issues / category threshold, pass count;
  - the real-app screens (compare_realapp.py output on a render dir);
  - the Catalyst gate count (compare.py on a gate render dir);
  - conformance apps (scripts/conformance_flow.sh work dirs, when present):
    per-app, per-capture scores.

Usage:
  scripts/scoreboard.py [--suite /tmp/ios_suite] [--realapp-out DIR]
                        [--gate-out DIR] [--conformance DIR...] [--write]

Without --write it prints the markdown only. Rows carry a "status":
  pass       at or above the category threshold
  fail       below it, nobody working on it
  open       below it but the difference has been measured and written up as
             not modellable yet (listed in scoreboard/open.txt, one name per
             line, with the reason after a '#') — the climb skips these.
"""
import argparse, json, os, re, subprocess, sys, datetime

THRESH = {"geometry": 99.5, "effects": 98.0, "text": 97.0, "control": 96.0, "chrome": 97.5}
REALAPP_FLOOR = {
    "realapp_history_light": 99.0,
    "realapp_settings_light": 98.4,
    "realapp_settings_dark": 98.4,
    "realapp_storage_light": 99.0,   # xib-driven Storage & Data Use screen: 99.41 on 2026-09-05
    # Dynamic Type sizes of realapp_settings_light (window trait override),
    # measured 2026-09-04 on iPhone 16 / iOS 26.1 after the stack-floor and
    # scaledValue-vs-application-category rules.
    "realapp_settings_light_xs": 98.4,     # 98.639
    "realapp_settings_light_xxxl": 98.0,   # 98.133
    "realapp_settings_light_ax1": 97.0,    # 97.516
    # iPad (A16) 820×1180 @2x portrait of Settings. MEASURED 2026-09-04
    # after the pad formSheet card rule: 99.511.
    "realapp_settings_light_ipad": 99.4,   # 99.511
    # Firefox Focus Settings (iPhone 16 / iOS 26.1). MEASURED 80.345 after
    # the opaque-bar inset, nil container fill, and inset-grouped footer wrap.
    "realapp_focus_settings_light": 80.2,   # 80.345
    # Hackers feed (weiran/Hackers 83016de, iPhone 16 / iOS 26.1).
    # MEASURED 84.582 after swipe-at-rest hidden, .plain listRowInsets 16,
    # empty ViewBuilder rows dropped, list rest offset −113, HStack
    # remeasure at placeHStack widths.
    "realapp_hackers_feed_light": 84.4,     # 84.582
    # iPad (A16) History picker + Storage screen. MEASURED 2026-09-04:
    # history formSheet [120, 753, 580, 157] 99.760; storage large-title
    # x 20 and grouped cell margin 16 → 99.689.
    "realapp_history_light_ipad": 99.6,   # 99.760
    "realapp_storage_light_ipad": 99.5,   # 99.689
}

def parse_compare(path):
    rows = []
    if not os.path.exists(path): return rows
    for line in open(path):
        m = re.match(r'^(PASS|FAIL)\s+(\S+)\s+\[(\w+)\s*\]\s+pixels=\s*([\d.]+)\s+blob=\s*([\d.]+)\s+layout_issues=(\d+)', line)
        if m:
            rows.append({"scene": m.group(2), "category": m.group(3), "score": float(m.group(4)),
                         "blob": float(m.group(5)), "layout_issues": int(m.group(6)),
                         "verdict": m.group(1), "threshold": THRESH.get(m.group(3), 97.0)})
    return rows

def parse_realapp(out_dir, golden="/tmp/golden_realapp_ios"):
    rows = []
    if not (out_dir and os.path.isdir(out_dir) and os.path.isdir(golden)): return rows
    r = subprocess.run([sys.executable, "Tools/compare/compare_realapp.py", "--golden", golden,
                        "--out", out_dir, "--scale", "3"], capture_output=True, text=True)
    for name, floor in REALAPP_FLOOR.items():
        m = re.search(name + r".*?'score': np\.float64\(([\d.]+)\).*?'blob': ([\d.]+)", r.stdout)
        if m:
            rows.append({"scene": name, "category": "realapp", "score": float(m.group(1)),
                         "blob": float(m.group(2)), "layout_issues": 0,
                         "verdict": "PASS" if float(m.group(1)) >= floor else "FAIL", "threshold": floor})
    return rows

def parse_gate(gate_out):
    if not (gate_out and os.path.isdir(gate_out)): return None
    r = subprocess.run([sys.executable, "Tools/compare/compare.py", "--out", gate_out], capture_output=True, text=True)
    m = re.search(r'(\d+)/(\d+) scenes pass', r.stdout + r.stderr)
    return {"pass": int(m.group(1)), "total": int(m.group(2))} if m else None

CONFORMANCE_CAPTURED = {}   # app -> ISO time the summary was written (see #440)

def parse_conformance(dirs):
    rows = []
    for d in dirs or []:
        summary = os.path.join(d, "summary.json")
        if not os.path.exists(summary): continue
        s = json.load(open(summary))
        # A board once scored reports left in /tmp by earlier agent runs and
        # picked rows the merged code had already fixed; every row carries the
        # time its summary was written so a stale capture is visible.
        captured = datetime.datetime.fromtimestamp(os.path.getmtime(summary)).strftime("%Y-%m-%dT%H:%M")
        app = str(s.get("app"))
        key = app
        if s.get("style") == "dark":
            key = key + ".dark"
        if s.get("direction") == "rtl":
            key = key + ".rtl"
        CONFORMANCE_CAPTURED[key] = captured
        for cap in s.get("captures", []):
            rows.append({"scene": f"{s.get('app')}:{cap.get('name')}", "category": "conformance",
                         "score": float(cap.get("score", 0)), "blob": float(cap.get("blob", 0)),
                         "layout_issues": int(cap.get("layout_issues", 0)), "captured": captured,
                         "verdict": "PASS" if float(cap.get("score", 0)) >= 97.5 else "FAIL", "threshold": 97.5})
    return rows

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--suite", default="/tmp/ios_suite")
    ap.add_argument("--realapp-out")
    ap.add_argument("--gate-out")
    ap.add_argument("--conformance", nargs="*")
    ap.add_argument("--write", action="store_true")
    a = ap.parse_args()
    os.makedirs("scoreboard", exist_ok=True)
    open_set = {}
    if os.path.exists("scoreboard/open.txt"):
        for line in open("scoreboard/open.txt"):
            line = line.strip()
            if line and not line.startswith("#"):
                name, _, why = line.partition("#"); open_set[name.strip()] = why.strip()
    rows = parse_compare(os.path.join(a.suite, "compare.txt")) + parse_realapp(a.realapp_out) + parse_conformance(a.conformance)
    for r in rows:
        r["status"] = "pass" if r["verdict"] == "PASS" else ("open" if r["scene"] in open_set else "fail")
        if r["status"] == "open": r["open_reason"] = open_set[r["scene"]]
    gate = parse_gate(a.gate_out)
    head = subprocess.run(["git", "rev-parse", "--short", "HEAD"], capture_output=True, text=True).stdout.strip()
    board = {"head": head, "date": datetime.datetime.utcnow().isoformat(timespec="minutes") + "Z",
             "suite": {"pass": sum(r["verdict"] == "PASS" for r in rows if r["category"] not in ("realapp", "conformance")),
                       "total": sum(1 for r in rows if r["category"] not in ("realapp", "conformance"))},
             "gate": gate, "rows": sorted(rows, key=lambda r: r["score"])}
    worst = [r for r in board["rows"] if r["status"] == "fail"]
    md = [f"# Scoreboard — {head} ({board['date']})", "",
          f"iOS scene suite: **{board['suite']['pass']}/{board['suite']['total']}**"
          + (f" · Catalyst gate: **{gate['pass']}/{gate['total']}**" if gate else ""), "",
          ("conformance captured: " + ", ".join(f"{a} @ {t}" for a, t in sorted(CONFORMANCE_CAPTURED.items()))
           if CONFORMANCE_CAPTURED else "conformance: none"), "",
          "| scene | category | score | bar | blob pt² | layout | status |", "|---|---|---|---|---|---|---|"]
    for r in board["rows"]:
        if r["status"] == "pass" and r["score"] >= r["threshold"] + 0.3: continue  # keep the table about the frontier
        md.append(f"| {r['scene']} | {r['category']} | {r['score']:.2f} | {r['threshold']} | {r['blob']:.1f} | {r['layout_issues']} | {r['status']}"
                  + (f" — {r['open_reason']}" if r.get("open_reason") else "") + " |")
    md.append(""); md.append(f"{len(worst)} row(s) to climb; {sum(r['status']=='open' for r in rows)} measured-open.")
    text = "\n".join(md) + "\n"
    if a.write:
        json.dump(board, open("scoreboard/latest.json", "w"), indent=1)
        open("scoreboard/latest.md", "w").write(text)
    print(text)

if __name__ == "__main__":
    main()
