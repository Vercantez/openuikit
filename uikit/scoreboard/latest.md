# Scoreboard — 5398ac1c (2026-09-04T16:56Z)

iOS scene suite: **112/113** · Catalyst gate: **124/124**

| scene | category | score | bar | blob pt² | layout | status |
|---|---|---|---|---|---|---|
| NavFlow:t4800 | conformance | 88.39 | 97.5 | 77.5 | 12 | fail |
| NavFlow:t200 | conformance | 89.25 | 97.5 | 77.5 | 12 | fail |
| NavFlow:t2100 | conformance | 89.25 | 97.5 | 77.5 | 12 | fail |
| NavFlow:t1200 | conformance | 93.01 | 97.5 | 74.0 | 16 | fail |
| NavFlow:t3000 | conformance | 97.73 | 97.5 | 98.2 | 3 | pass |
| realapp_settings_light | realapp | 98.53 | 98.4 | 2.0 | 0 | pass |
| realapp_settings_dark | realapp | 98.55 | 98.4 | 2.0 | 0 | pass |
| realapp_history_light | realapp | 99.14 | 99.0 | 2.6 | 0 | pass |
| corner_radius | geometry | 99.41 | 99.5 | 1.0 | 0 | open — 99.41 vs 99.5: every rounded corner on iOS carries a near-tangent coverage ramp about r/2 pt long along the curve (measured 2026-09-04/05 at radii 2-20, 2x and 3x); no closed-form rule fit every sample. A score-targeted parameter fit (exp shoulder + 0.172 radius bias) reached exactly 99.500 and was rejected as a fudge. Needs a rasteriser-level model (filtered SDF?) derived from the per-pixel samples, not tuned to the score. |
| borders | geometry | 99.63 | 99.5 | 0.8 | 0 | pass |
| gradient_dark | geometry | 99.80 | 99.5 | 0.0 | 0 | pass |

4 row(s) to climb; 1 measured-open.
