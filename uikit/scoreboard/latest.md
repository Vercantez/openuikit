# Scoreboard — 7ed87486 (2026-09-04T16:23Z)

iOS scene suite: **96/98** · Catalyst gate: **124/124**

| scene | category | score | bar | blob pt² | layout | status |
|---|---|---|---|---|---|---|
| attrtext_paragraph | text | 96.08 | 97.0 | 15.2 | 1 | fail |
| realapp_settings_light | realapp | 98.53 | 98.4 | 2.0 | 0 | pass |
| realapp_settings_dark | realapp | 98.55 | 98.4 | 2.0 | 0 | pass |
| realapp_history_light | realapp | 99.14 | 99.0 | 2.6 | 0 | pass |
| corner_radius | geometry | 99.41 | 99.5 | 1.0 | 0 | open — 99.41 vs 99.5: every rounded corner on iOS carries a near-tangent coverage ramp about r/2 pt long along the curve (measured 2026-09-04/05 at radii 2-20, 2x and 3x); no closed-form rule fit every sample. A score-targeted parameter fit (exp shoulder + 0.172 radius bias) reached exactly 99.500 and was rejected as a fudge. Needs a rasteriser-level model (filtered SDF?) derived from the per-pixel samples, not tuned to the score. |
| borders | geometry | 99.63 | 99.5 | 0.8 | 0 | pass |
| gradient_dark | geometry | 99.80 | 99.5 | 0.0 | 0 | pass |

1 row(s) to climb; 1 measured-open.
