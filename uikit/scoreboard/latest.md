# Scoreboard — 04d65820 (2026-09-04T23:43Z)

iOS scene suite: **112/113** · Catalyst gate: **124/124**

conformance captured: Feed @ 2026-09-04T18:41, Forms @ 2026-09-04T18:42, Modal @ 2026-09-04T18:42, NavFlow @ 2026-09-04T18:42, TableEditor @ 2026-09-04T18:42

| scene | category | score | bar | blob pt² | layout | status |
|---|---|---|---|---|---|---|
| Modal:t600 | conformance | 92.63 | 97.5 | 105.0 | 0 | open — 92.626 vs 97.5: medium-sheet present at named frame 12 (0.2 s at 60 Hz). Five conformance_flow runs identical to 3 dp (92.626 all). Glass-fill top (interior 245) 359.5 golden vs 337.0 openhost; rest 317.5 both (t1200). Remaining 42.0 vs 19.5 of the 349.3 pt travel. iOS CA-seeked curve (glass top, frames after present, iPhone SE 2x / iOS 26.1): k=6 476.5, k=9 402.0, k=12 359.5, k=15 338.0, k=18 327.0; k=24 is a wait not a seek (d>20) and reads 320.0. openhost duration-fit ζ=1 D=0.4 PNG curve at the same k: 432.5, 366.5, 337.0, 332, 328, 317.5. Port matches (1+ωt)e^(−ωt) with ω·D=9.233 (UIViewAnimation duration-fit); iOS is slower at every overlapping sample. A duration/ω retarget to remaining 42 at frame 12 is a score fit, not a measurement. The three-clock split (GCD remaining 0.162 / openhost 0.179 / vsync 0.238) is closed; TableEditor t1350/t2350 now lock at remaining 0.1790 = env(9/60) and pass 98.269 / 98.214. blob 105. layout 0. |
| TableEditor:t2350 | conformance | 97.08 | 97.5 | 12.0 | 0 | fail |
| TableEditor:t1350 | conformance | 97.16 | 97.5 | 13.5 | 0 | fail |
| realapp_settings_light_xxxl | realapp | 98.13 | 98.0 | 3.4 | 0 | pass |
| realapp_settings_light | realapp | 98.53 | 98.4 | 2.0 | 0 | pass |
| realapp_settings_dark | realapp | 98.55 | 98.4 | 2.0 | 0 | pass |
| realapp_settings_light_xs | realapp | 98.64 | 98.4 | 2.6 | 0 | pass |
| realapp_history_light | realapp | 99.14 | 99.0 | 2.6 | 0 | pass |
| corner_radius | geometry | 99.41 | 99.5 | 1.0 | 0 | open — 99.41 vs 99.5: every rounded corner on iOS carries a near-tangent coverage ramp about r/2 pt long along the curve (measured 2026-09-04/05 at radii 2-20, 2x and 3x); no closed-form rule fit every sample. A score-targeted parameter fit (exp shoulder + 0.172 radius bias) reached exactly 99.500 and was rejected as a fudge. Needs a rasteriser-level model (filtered SDF?) derived from the per-pixel samples, not tuned to the score. |
| realapp_settings_light_ipad | realapp | 99.51 | 99.4 | 1.8 | 0 | pass |
| borders | geometry | 99.63 | 99.5 | 0.8 | 0 | pass |
| gradient_dark | geometry | 99.80 | 99.5 | 0.0 | 0 | pass |

2 row(s) to climb; 2 measured-open.
