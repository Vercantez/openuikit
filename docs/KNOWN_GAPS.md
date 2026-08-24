# Known gaps (living document — fixers: read this)

## Text module: glyph_ink.json harvest coverage (HIGH VALUE, well-diagnosed)

Diagnosis from the button-module fixer (commit 0d4da17, oracle A/B probes in its
scratchpad: probe_btn_widths / probe_btn_vs_label / probe_btn_blue) plus the
demo_settings finding:

1. **Harvest coverage.** `Sources/OpenUIKit/Resources/glyph_ink.json` only
   covers the (family, weight, size, style, phase, char) combos of the original
   8 label scenes. Missing (at least): system-regular-11 entirely; 14pt has
   only 12 chars; light/medium/heavy weights only at 19pt; dark mode only
   regular-17; **non-ASCII glyphs entirely** (e.g. "›" U+203A used by
   demo_settings — its ADVANCE is also missing from font_metrics.json, real
   width 8pt vs our 7pt fallback). Misses fall back to fitted GlyphSmoothing
   kernels (~5% per-pixel error); text-dense scenes lose 3–4 score points.
   Fix: extend the harvest tooling to cover the strings/sizes/weights/styles
   used by button_states, button_dark, demo_settings (and extend
   font_metrics advances beyond ASCII, at minimum U+2026 …, U+203A ›).
2. **drawMask blend calibration.** Exact for the `.label` color it was fitted
   on; ~9 counts dark at AA edges for pure black and tint-blue titles. All
   diffs on fully-harvested strings are ≤15 counts. Consider color-dependent
   calibration or fitting the blend exponent per ink color family.
3. Button path is NOT the problem: button text renders byte-identically to the
   label path (verified by A/B probe).

## UIButton (fixed, for the record)
Real UIKit gives the title label the FULL bounds width (squeeze to
floor(width)) and truncates button titles MIDDLE, not tail (commit 0d4da17).

## Earlier accepted residuals (within thresholds, from M2/M3)
- Dark-mode saturated-color text (label_dark link row) has a different ink
  profile than the default color — needs color-keyed harvests.
- truncateHead/Middle per-char tight-advance quantization subtlety (≤+0.11pt).
- Light saturated-color glyphs: small mask-shape differences beyond the gamma
  model.
