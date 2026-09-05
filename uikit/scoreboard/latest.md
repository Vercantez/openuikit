# Scoreboard — 22bfb242 (2026-09-05T03:13Z)

iOS scene suite: **112/113** · Catalyst gate: **124/124**

conformance captured: Feed @ 2026-09-04T22:11, Forms @ 2026-09-04T22:11, Modal @ 2026-09-04T22:12, NavFlow @ 2026-09-04T22:12, Pager @ 2026-09-04T22:12, TableEditor @ 2026-09-04T22:13, Tabs @ 2026-09-04T22:13

| scene | category | score | bar | blob pt² | layout | status |
|---|---|---|---|---|---|---|
| Tabs:t2000 | conformance | 84.63 | 97.5 | 246.0 | 8 | fail |
| Tabs:t6000 | conformance | 88.25 | 97.5 | 79.5 | 31 | fail |
| Tabs:t7000 | conformance | 92.25 | 97.5 | 59.0 | 35 | fail |
| Tabs:t4000 | conformance | 92.79 | 97.5 | 79.5 | 33 | fail |
| Tabs:t5000 | conformance | 93.02 | 97.5 | 79.5 | 34 | fail |
| Tabs:t200 | conformance | 93.07 | 97.5 | 79.5 | 31 | fail |
| Tabs:t3000 | conformance | 93.31 | 97.5 | 79.5 | 31 | fail |
| Pager:t600 | conformance | 95.85 | 97.5 | 9271.0 | 2 | fail |
| Pager:t500 | conformance | 97.54 | 97.5 | 5080.0 | 2 | pass |
| TableEditor:t2350 | conformance | 97.58 | 97.5 | 12.0 | 0 | pass |
| Modal:t600 | conformance | 97.64 | 97.5 | 34.8 | 0 | pass |
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

8 row(s) to climb; 1 measured-open.
