# Known gaps (living document — fixers: read this)

## demo_settings: remaining FAIL is window-capture ALPHA ENCODING, not text

After the text fixes below (2026-08-24), demo_settings measures 95.42 against
golden with compare.py's raw-channel diff, but 99.54 when both images are
composited over white with the golden interpreted as PREMULTIPLIED alpha.
Root cause: oracle2 (drawHierarchy) window captures store semi-transparent
pixels premultiplied — the `tertiarySystemFill` search bar is
(14,14,15,a=30) in golden (= 118·30/255) where our PNG stores straight
(115,115,123,a=31). That one 350x36pt bar is ~4.1% of the scene's pixels,
all counted as mismatches by the raw-channel compare. Owner: fixture
(compare.py could normalize encodings) or rendercli/rasterizer (premultiply
window-scene output). NOT the text module: every text region of the scene
now matches within tolerance. Opaque pixels are unaffected (premultiplied ==
straight at alpha 255), which is why deep_mixed passes.

## Glyph ink harvest: coverage tooling now automated (2026-08-24)

`OPENUIKIT_INK_LOG=<path> openrender render ...` dumps every ink-table miss
("W|family|size|style|tag|codepoint" for window-table misses, "O|..." for
offscreen). Harvest tooling (text-fixer scratchpad `h2/`): gen.py turns the
miss list into space-prefixed single-glyph probe scenes at integer x (all
phase tags per missed char, validation cells included), rendered by BOTH
oracle1 (offscreen entries) and oracle2 (window entries); extract2.py
validates extraction against already-stored entries (geometry byte-exact;
values within ±1 count — the residual of representing each phase BIN by one
mask) and merges only new keys. Dark-mode cells: Catalyst dark
systemBackground renders lum 30, full label ink 221, so masks are
v = round((lum-30)·255/191) with bbox threshold lum > 30.6 (validated ±2
counts against the stored regular-17 dark entries).
Coverage added: all button_states/button_dark/demo_settings combos
(regular 11/13/14/15/17/20/24, light/medium/heavy/bold 17, bold 34,
semibold 17 incl. U+203A, regular-15 dark, semibold-17 dark; window
variants for demo_settings' strings). Regression tests:
GlyphInkTableTests.testOffscreenCoverageForButtonStates /
testWindowCoverageForDemoSettings / testOffscreenDarkCoverageForButtonDark.

## Non-ASCII advances: vendored in font_metrics.json (2026-08-24)

Resources/font_metrics.json "advances" now also carries oracle-measured
non-ASCII advances (– — ‘ ’ “ ” • … ‹ › · × ° →, all families/weights/
sizes; scratchpad advprobe.swift, same NSString.size measurement as the
oracle's fontmetrics dump). FontEngine interpolates them like ASCII ones;
U+2026 keeps its exact label-context (tight-table) advance. This fixed all
14 demo_settings layout failures (U+203A at semibold-17 is 7.5693pt → 8pt
ceiled label width; the old font-file fallback gave 7pt).

## Text in window scenes: SOLVED mechanism, extend coverage as needed

Window scenes (`"window": true`, oracle2/drawHierarchy goldens) rasterize
label glyphs darker/crisper than offscreen `layer.render` — real UIKit's
own offscreen render of deep_mixed mismatches the window golden by the same
~5% the old renderer did, and no pointwise coverage transfer reproduces it
(it is a spatial re-rendering). Fix (text module): window-variant ink masks
in `Sources/OpenUIKit/Resources/glyph_ink_window.json`, harvested with the
SAME probe methodology as glyph_ink.json but rendered through oracle2
(space-prefixed single-glyph labels at integer x; extraction validated
byte-exact against the offscreen table first). Selected via
`GlyphInkTable.windowCompositing`, set by openrender from the scene's
`window` flag; per-glyph fallback to the offscreen table. Coverage today:
deep_mixed's strings (fixed deep_mixed 95.95 → 99.64) plus all of
demo_settings' strings (34pt bold title, 17pt regular/semibold incl. U+203A,
13pt incl. U+2014, 15pt button titles) via the automated miss-log harvest
(`h2/` in the text-fixer scratchpad, successor of `wharvest/`); see
"Glyph ink harvest" above. Window dark mode remains unharvested (no window
dark scene exists yet).

## Text module: glyph_ink.json harvest coverage — RESOLVED 2026-08-24

Item 1 of the old diagnosis (harvest coverage + non-ASCII advances) is fixed;
see the two sections above. button_states 94.90 → 96.60 PASS. Still open:

- **drawMask blend calibration.** Exact for the `.label` color it was fitted
  on; ~9 counts dark at AA edges for pure black and tint-blue titles. All
  diffs on fully-harvested strings are ≤15 counts. Consider color-dependent
  calibration or fitting the blend exponent per ink color family. (Was not
  needed to pass button_states once coverage landed.)
- Button path is NOT the problem: button text renders byte-identically to the
  label path (verified by A/B probe, commit 0d4da17).

## UIButton (fixed, for the record)
Real UIKit gives the title label the FULL bounds width (squeeze to
floor(width)) and truncates button titles MIDDLE, not tail (commit 0d4da17).

## Earlier accepted residuals (within thresholds, from M2/M3)
- Dark-mode saturated-color text (label_dark link row) has a different ink
  profile than the default color — needs color-keyed harvests.
- truncateHead/Middle per-char tight-advance quantization subtlety (≤+0.11pt).
- Light saturated-color glyphs: small mask-shape differences beyond the gamma
  model.

## Animation engine (M6, 2026-08-24): scope notes

- Presentation sampling requires the DEFAULT pipeline (quartz backend +
  layers compositor). Under `OPENUIKIT_COMPOSITOR=renderpass` or
  `OPENUIKIT_BACKEND=swift` animation scenes render MODEL values only
  (every frame = final state). Owner: view module, only if a host ever
  needs animated rendering on the pure-Swift path.
- `UIView.animate` completion handlers run synchronously with
  `finished == true` (no run loop in the portable core; the host drives
  time via `OpenUIKitRuntime.animationTime`). Real UIKit delivers them
  after `delay + duration` of wall time.
- Spring initialVelocity: UIKit's internal duration-fit solver picks a
  much softer spring (a different root of the same settling equation —
  see docs/QUARTZ_NOTES.md) once the velocity crosses a threshold
  (measured: between v=1.65 and v=1.7 at ζ=0.5, D=1, scaling roughly with
  1/D; near the crossover UIKit emits unconverged garbage parameters,
  e.g. ζ=0.5 D=2 v=0.9 → stiffness 354.6 with settlingDuration < D). We
  always take the settled (largest) root, which matches UIKit for
  moderate velocities (probed: exact for v ∈ [−2, 1.65] at ζ=0.5 D=1)
  and diverges deliberately in the garbage regime. All fixtures use v=0,
  where the model is exact to 8+ digits.
- Transform interpolation implements CA's decomposition for the 2D affine
  subset (translation/scale/shear/rotation lerp, rotation shortest-path).
  Degenerate (rank-deficient) matrices fall back to componentwise lerp;
  180° rotations are ambiguous (CA's quaternion slerp has the same
  ambiguity). backgroundColor nil endpoints lerp as transparent black
  (CA snaps); no fixture covers either.
- A `bounds`/frame resize animates the layer rect only — a view's CONTENT
  image (glyph ink, image resampling, control chrome) is not re-stretched
  per frame the way CA scales `contents` with the presentation bounds.
  No fixture resizes a content-bearing view; revisit if one does.
