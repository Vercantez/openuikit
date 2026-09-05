# Scoreboard — f6912fa1 (2026-09-05T01:54Z)

iOS scene suite: **112/113** · Catalyst gate: **124/124**

conformance captured: Feed @ 2026-09-04T20:52, Forms @ 2026-09-04T20:52, Modal @ 2026-09-04T20:52, NavFlow @ 2026-09-04T20:53, Pager @ 2026-09-04T20:53, TableEditor @ 2026-09-04T20:53, Tabs @ 2026-09-04T20:54

| scene | category | score | bar | blob pt² | layout | status |
|---|---|---|---|---|---|---|
| realapp_focus_settings_light | realapp | 80.34 | 80.2 | 3668.9 | 0 | pass |
| Tabs:t2000 | conformance | 84.57 | 97.5 | 226.5 | 8 | fail |
| Tabs:t6000 | conformance | 88.17 | 97.5 | 220.5 | 42 | fail |
| Tabs:t7000 | conformance | 92.26 | 97.5 | 220.5 | 47 | fail |
| Tabs:t4000 | conformance | 92.66 | 97.5 | 220.5 | 46 | fail |
| Tabs:t5000 | conformance | 92.89 | 97.5 | 220.5 | 44 | fail |
| Tabs:t200 | conformance | 92.93 | 97.5 | 220.5 | 44 | fail |
| Tabs:t3000 | conformance | 93.17 | 97.5 | 220.5 | 44 | fail |
| Modal:t600 | conformance | 97.59 | 97.5 | 17.0 | 0 | pass |
| NavFlow:t3000 | conformance | 97.78 | 97.5 | 97.2 | 2 | pass |
| Tabs:t1000 | conformance | 97.79 | 97.5 | 220.2 | 20 | pass |
| realapp_settings_light_xxxl | realapp | 98.13 | 98.0 | 3.4 | 0 | pass |
| realapp_settings_light | realapp | 98.53 | 98.4 | 2.0 | 0 | pass |
| realapp_settings_dark | realapp | 98.55 | 98.4 | 2.0 | 0 | pass |
| realapp_settings_light_xs | realapp | 98.64 | 98.4 | 2.6 | 0 | pass |
| realapp_history_light | realapp | 99.14 | 99.0 | 2.6 | 0 | pass |
| corner_radius | geometry | 99.41 | 99.5 | 1.0 | 0 | open — 99.41 vs 99.5: every rounded corner on iOS carries a near-tangent coverage ramp about r/2 pt long along the curve (measured 2026-09-04/05 at radii 2-20, 2x and 3x); no closed-form rule fit every sample. A score-targeted parameter fit (exp shoulder + 0.172 radius bias) reached exactly 99.500 and was rejected as a fudge. Needs a rasteriser-level model (filtered SDF?) derived from the per-pixel samples, not tuned to the score. |
| realapp_settings_light_ipad | realapp | 99.51 | 99.4 | 1.8 | 0 | pass |
| borders | geometry | 99.63 | 99.5 | 0.8 | 0 | pass |
| realapp_storage_light_ipad | realapp | 99.69 | 99.5 | 12.0 | 0 | pass |
| realapp_history_light_ipad | realapp | 99.76 | 99.6 | 6.5 | 0 | pass |
| gradient_dark | geometry | 99.80 | 99.5 | 0.0 | 0 | pass |

7 row(s) to climb; 1 measured-open.
