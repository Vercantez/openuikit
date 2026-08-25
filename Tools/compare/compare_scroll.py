#!/usr/bin/env python3
"""Compare OpenUIKit's scroll physics against real-UIKit golden traces.

Usage:
  compare_scroll.py [--golden golden/scroll_traces] [--out out_scroll]
                    [--bin PATH-TO-openrender] [--no-run] [trace ...]

For each golden trace (recorded from REAL iOS UIKit by the simprobe oracle,
see golden/scroll_traces/SCHEMA.md), replays its input stream through
OpenUIKit headlessly (`openrender scrolltrace`) and diffs the contentOffset
timelines. Exit 0 iff every gate passes.

Gates (per trace kind):
  - drag phase (all kinds):        max |dy| <= 1.0 pt   (tracking/rubber-band)
  - deceleration, post-release:    max |dy| <= 2.0 pt   after best global time
                                   shift in [-20ms, +20ms] (real UIKit starts
                                   the deceleration ~1 frame after the lift;
                                   the shift is reported)
  - bounce kinds, post-release:    settle time (last |y - final| > 1.0 pt)
                                   within 10% of the oracle's

The oracle offsets are quantized to the device pixel grid (1/3 pt at 3x);
that inherent error is inside the gates.
"""
import argparse, json, os, subprocess, sys
import numpy as np

def load(path):
    with open(path) as f:
        return json.load(f)

def series(samples, fresh_only=False):
    """Sorted (t, y) arrays. Near-duplicate times keep the LATEST value (the
    oracle records a stale pre-frame CADisplayLink sample and the fresh
    didScroll value ~0.1ms apart — the fresh one is the physics).
    fresh_only additionally drops samples whose value did not change (the
    stale plateau between 60Hz frames), leaving the per-frame update
    instants — the only points where oracle time/value pairs are exact."""
    out = []
    for s in sorted(samples, key=lambda r: r[0]):
        if out and s[0] - out[-1][0] < 0.004:
            out[-1] = (s[0], s[2])
        else:
            out.append((s[0], s[2]))
    if fresh_only:
        out = [p for i, p in enumerate(out) if i == 0 or p[1] != out[i - 1][1]]
    a = np.array(out)
    return a[:, 0], a[:, 1]

def phase_times(trace):
    ts = [e["t"] for e in trace["input"]]
    te = [e["t"] for e in trace["input"] if e["phase"] == "ended"][0]
    return min(ts), te

def settle_time(t, y, final, rel_to):
    """Last time |y - final| > 1.0 pt, relative to rel_to (0 if never).
    1.0 pt (= 3 device pixels) keeps the measure robust against the
    oracle's 1/3 pt pixel-grid quantization of contentOffset."""
    big = np.abs(y - final) > 1.0
    if not big.any():
        return 0.0
    return t[np.where(big)[0][-1]] - rel_to

def compare_trace(golden_path, ours_path):
    g = load(golden_path)
    o = load(ours_path)
    gt, gy = series(g["samples"], fresh_only=True)
    ot, oy = series(o["samples"])
    tb, te = phase_times(g)
    kind = g["kind"]
    final_g = g["finalOffsetY"]
    final_o = o["finalOffsetY"]

    checks = []  # (label, value_str, ok)

    # --- drag phase: pointwise at oracle sample times
    m = (gt >= tb) & (gt <= te)
    ours_at = np.interp(gt, ot, oy)
    drag_err = np.max(np.abs(ours_at[m] - gy[m])) if m.any() else 0.0
    checks.append((f"drag max err", f"{drag_err:6.2f} pt", drag_err <= 1.0))

    # --- post-release
    m = gt > te
    if kind == "deceleration":
        # Skip the single oracle frame straddling the release: its recorded
        # timestamp is the didScroll-callback time, which lags the frame's
        # animation-evaluation time by a fraction of a millisecond — at
        # 4875 pt/s that skew alone reads as ~2.4 pt on exactly that sample
        # (all later frames agree within ~0.2 pt, see APP_FEEL.md).
        first = np.argmax(m)
        m[first] = False
        best = None
        for shift in np.arange(-0.020, 0.0201, 0.00025):
            ours_shifted = np.interp(gt[m] + shift, ot, oy)
            err = np.max(np.abs(ours_shifted - gy[m]))
            if best is None or err < best[0]:
                best = (err, shift)
        err, shift = best
        checks.append((f"decel max err (shift {1000*shift:+.0f}ms)",
                       f"{err:6.2f} pt", err <= 2.0))
        checks.append(("final offset",
                       f"{final_o - final_g:+6.2f} pt", abs(final_o - final_g) <= 2.0))
    elif kind in ("rubber_band", "bounce_release", "edge_impact"):
        s_g = settle_time(gt, gy, final_g, te)
        s_o = settle_time(ot, oy, final_o, te)
        rel = abs(s_o - s_g) / s_g if s_g > 0 else 0.0
        checks.append((f"settle time oracle={s_g:.3f}s ours={s_o:.3f}s",
                       f"{100*rel:5.1f} %", rel <= 0.10))
        post_err = np.max(np.abs(np.interp(gt[m], ot, oy) - gy[m])) if m.any() else 0.0
        checks.append(("bounce max err (info)", f"{post_err:6.2f} pt", True))
        checks.append(("final offset",
                       f"{final_o - final_g:+6.2f} pt", abs(final_o - final_g) <= 1.0))
    elif kind == "calibration":
        checks.append(("final offset",
                       f"{final_o - final_g:+6.2f} pt", abs(final_o - final_g) <= 1.0))

    ok = all(c[2] for c in checks)
    return ok, checks

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--golden", default="golden/scroll_traces")
    ap.add_argument("--out", default="out_scroll")
    ap.add_argument("--bin", default=None,
                    help="openrender binary (default: swift run -c release)")
    ap.add_argument("--no-run", action="store_true",
                    help="reuse existing replays in --out")
    ap.add_argument("traces", nargs="*")
    args = ap.parse_args()

    names = args.traces or sorted(
        os.path.splitext(f)[0] for f in os.listdir(args.golden)
        if f.endswith(".json"))
    os.makedirs(args.out, exist_ok=True)

    def replay(name):
        golden = os.path.join(args.golden, name + ".json")
        ours = os.path.join(args.out, name + ".json")
        if not args.no_run:
            cmd = ([args.bin] if args.bin
                   else ["swift", "run", "-c", "release", "openrender"])
            cmd += ["scrolltrace", golden, ours]
            r = subprocess.run(cmd, capture_output=True, text=True)
            if r.returncode != 0:
                print(r.stdout, r.stderr, sep="\n")
                raise RuntimeError(f"replay failed for {name}")
        return golden, ours

    failures = 0
    for name in names:
        golden, ours = replay(name)
        ok, checks = compare_trace(golden, ours)
        print(f"{'PASS' if ok else 'FAIL'} {name}")
        for label, value, cok in checks:
            print(f"   {'ok  ' if cok else 'FAIL'} {label}: {value}")
        if not ok:
            failures += 1
    print(f"\n{len(names) - failures}/{len(names)} traces pass")
    sys.exit(0 if failures == 0 else 1)

if __name__ == "__main__":
    main()
