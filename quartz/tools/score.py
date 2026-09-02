#!/usr/bin/env python3
"""Aggregate qzcompare metrics, append history, render an HTML report."""
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output"
METRICS = ROOT / "metrics"
HISTORY = METRICS / "history.jsonl"
LATEST = METRICS / "latest.json"
HTML = OUT / "report.html"


def load_latest() -> dict:
    p = OUT / "metrics.json"
    if not p.exists():
        sys.exit(f"missing {p}; run qzcompare first")
    return json.loads(p.read_text())


def main() -> None:
    METRICS.mkdir(exist_ok=True)
    data = load_latest()
    data["ts"] = datetime.now(timezone.utc).isoformat()
    LATEST.write_text(json.dumps(data, indent=2))
    with HISTORY.open("a") as f:
        f.write(json.dumps(data) + "\n")

    hist = []
    if HISTORY.exists():
        for line in HISTORY.read_text().splitlines():
            if line.strip():
                hist.append(json.loads(line))

    scenes = sorted(data.get("scenes", []), key=lambda s: -s["mae"])
    rows = []
    for s in scenes:
        name = s["name"]
        suite = s.get("suite", "cg")
        rows.append(
            f"<tr>"
            f"<td>{suite}</td>"
            f"<td><code>{name}</code></td>"
            f"<td>{s['mae']:.3f}</td>"
            f"<td>{s['rmse']:.3f}</td>"
            f"<td>{s['max_err']}</td>"
            f"<td>{s['exact_pct']:.1f}%</td>"
            f"<td>{s['close_pct']:.1f}%</td>"
            f"<td><img src='apple/{name}.png' width='128'></td>"
            f"<td><img src='qz/{name}.png' width='128'></td>"
            f"<td><img src='diff/{name}.png' width='128'></td>"
            f"</tr>"
        )

    hist_rows = []
    for i, h in enumerate(hist, 1):
        hist_rows.append(
            f"<tr><td>{i}</td><td>{h.get('ts','')}</td>"
            f"<td><b>{h.get('score',0):.2f}</b></td>"
            f"<td>{h.get('mean_mae',0):.4f}</td>"
            f"<td>{h.get('mean_exact_pct',0):.2f}%</td>"
            f"<td>{h.get('mean_close_pct',0):.2f}%</td>"
            f"<td>{h.get('worst_max',0)}</td></tr>"
        )

    delta = ""
    if len(hist) >= 2:
        dscore = hist[-1]["score"] - hist[-2]["score"]
        dmae = hist[-1]["mean_mae"] - hist[-2]["mean_mae"]
        arrow = "IMPROVED" if dscore > 0.05 else ("REGRESSED" if dscore < -0.05 else "FLAT")
        delta = f"<p>vs previous: score {dscore:+.2f}  MAE {dmae:+.4f}  — <b>{arrow}</b></p>"

    html = f"""<!doctype html>
<meta charset=utf-8>
<title>Quartz vs Apple CoreGraphics</title>
<style>
body {{ font-family: ui-sans-serif, system-ui; margin: 24px; background: #111; color: #eee; }}
table {{ border-collapse: collapse; }}
td, th {{ border: 1px solid #333; padding: 6px 8px; vertical-align: middle; }}
img {{ background: #222; image-rendering: pixelated; }}
code {{ color: #9cf; }}
.score {{ font-size: 48px; margin: 0; }}
</style>
<h1>Portable Quartz vs official Apple CoreGraphics</h1>
<p class=score>SCORE {data.get('score',0):.2f} / 100</p>
<p>mean MAE {data.get('mean_mae',0):.4f} · exact {data.get('mean_exact_pct',0):.2f}% ·
close (≤8) {data.get('mean_close_pct',0):.2f}% · worst max err {data.get('worst_max',0)}</p>
{delta}
<h2>History</h2>
<table>
<tr><th>#</th><th>time</th><th>score</th><th>MAE</th><th>exact</th><th>close</th><th>worst</th></tr>
{''.join(hist_rows)}
</table>
<h2>Scenes (worst MAE first)</h2>
<table>
<tr><th>suite</th><th>scene</th><th>MAE</th><th>RMSE</th><th>max</th><th>exact</th><th>close</th>
<th>Apple</th><th>Ours</th><th>Diff ×8</th></tr>
{''.join(rows)}
</table>
"""
    HTML.write_text(html)
    print(f"score={data.get('score'):.2f}  mae={data.get('mean_mae'):.4f}  "
          f"exact={data.get('mean_exact_pct'):.2f}%  close={data.get('mean_close_pct'):.2f}%")
    print(f"wrote {LATEST}")
    print(f"appended {HISTORY} ({len(hist)} runs)")
    print(f"report {HTML}")
    if len(hist) >= 2:
        print(delta.replace("<p>", "").replace("</p>", "").replace("<b>", "").replace("</b>", ""))


if __name__ == "__main__":
    main()
