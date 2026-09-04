# Scoreboard — 003eaabc (2026-09-04T20:38Z)

iOS scene suite: **112/113** · Catalyst gate: **124/124**

| scene | category | score | bar | blob pt² | layout | status |
|---|---|---|---|---|---|---|
| Feed:t3800 | conformance | 19.15 | 97.5 | 17052.5 | 10 | fail |
| Feed:t4800 | conformance | 19.15 | 97.5 | 17052.5 | 10 | fail |
| Feed:t2800 | conformance | 20.89 | 97.5 | 17052.5 | 10 | fail |
| Modal:t1200 | conformance | 50.96 | 97.5 | 4.5 | 0 | fail |
| Modal:t600 | conformance | 52.75 | 97.5 | 102.0 | 0 | fail |
| Feed:t200 | conformance | 60.71 | 97.5 | 0.0 | 2 | fail |
| Feed:t1800 | conformance | 60.71 | 97.5 | 0.0 | 2 | fail |
| Feed:t700 | conformance | 67.20 | 97.5 | 32.0 | 1 | fail |
| TableEditor:t2350 | conformance | 94.64 | 97.5 | 14.2 | 0 | open — 94.64 vs 97.5: automatic-insert +0.15 s remaining 0.162 from discs (Alpha cy 198.88 vs dest 208.95) vs openhost 0.178 / vsync 0.238 — the same three-clock split as t1350. Extra fail vs t900 is 4.79 % (8 sliding rows). Zero is at rest both sides (dy 0.18 = rest disc residual). Insert Juliet dest is fully off-screen so it does not take the 52 pt clipped-row height spring. layout 0. |
| TableEditor:t1350 | conformance | 95.95 | 97.5 | 32.8 | 0 | open — 95.95 vs 97.5: fade-delete +0.15 s remaining travel is 0.162 of 62 pt from delete-control centres on the GCD golden (Delta cy 280.99 vs dest 270.95), vs openhost's exact 0.15 of the measured CASpringAnimation (ω=20.944, remaining (1+ωt)e^(−ωt)=0.179, ours disc dy +1.14 pt). Display-tick rowanimprobe at media +0.15 s reads remaining 0.238, matching env(t−1/60) (CATransaction commits on the next vsync). Three clocks, one spring: no begin-time offset fits GCD golden, vsync, and openhost together. A duration retarget to remaining 0.162 at t=0.15 is a score fit, not a measurement. Extra fail vs t900 rest is 3.46 % (text of the 7 sliding rows); layout 0. |
| NavFlow:t4800 | conformance | 97.52 | 97.5 | 6.2 | 1 | pass |
| NavFlow:t3000 | conformance | 97.58 | 97.5 | 95.2 | 3 | pass |
| realapp_settings_light | realapp | 98.53 | 98.4 | 2.0 | 0 | pass |
| realapp_settings_dark | realapp | 98.55 | 98.4 | 2.0 | 0 | pass |
| realapp_history_light | realapp | 99.14 | 99.0 | 2.6 | 0 | pass |
| corner_radius | geometry | 99.41 | 99.5 | 1.0 | 0 | open — 99.41 vs 99.5: every rounded corner on iOS carries a near-tangent coverage ramp about r/2 pt long along the curve (measured 2026-09-04/05 at radii 2-20, 2x and 3x); no closed-form rule fit every sample. A score-targeted parameter fit (exp shoulder + 0.172 radius bias) reached exactly 99.500 and was rejected as a fudge. Needs a rasteriser-level model (filtered SDF?) derived from the per-pixel samples, not tuned to the score. |
| borders | geometry | 99.63 | 99.5 | 0.8 | 0 | pass |
| gradient_dark | geometry | 99.80 | 99.5 | 0.0 | 0 | pass |

8 row(s) to climb; 3 measured-open.
