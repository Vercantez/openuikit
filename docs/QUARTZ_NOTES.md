# Quartz backend notes (M4)

Status: **acceptance passed — `.quartz` is the default backend.**
`OPENUIKIT_BACKEND=swift` (openrender) or `OpenUIKitRuntime.renderBackend =
.swift` selects the pure-Swift fallback.

## Dual-backend suite results (2026-08-24, golden = Mac Catalyst oracle)

Full suite, `swift run -c release openrender`; compare.py score per scene.
Suite render time (quartz backend, all 23 scenes): **≈0.9 s** (budget 60 s).

| scene | cat | threshold | swift | quartz | delta | status (both) |
|---|---|---|---|---|---|---|
| alpha_blend | geometry | 99.5 | 100.0 | 100.0 | +0.000 | PASS |
| borders | geometry | 99.5 | 99.967 | 99.972 | +0.005 | PASS |
| boxes_basic | geometry | 99.5 | 100.0 | 100.0 | +0.000 | PASS |
| boxes_dark | geometry | 99.5 | 100.0 | 100.0 | +0.000 | PASS |
| button_basic | control | 96.0 | 95.258 | 95.258 | +0.000 | FAIL (pre-existing, M3) |
| clip_subviews | geometry | 99.5 | 99.939 | 99.971 | +0.032 | PASS |
| corner_radius | geometry | 99.5 | 99.654 | 99.747 | +0.093 | PASS |
| imageview_modes | control | 96.0 | 75.905 | 75.905 | +0.000 | FAIL (pre-existing, M3) |
| label_align | text | 97.0 | 94.688 | 94.688 | +0.000 | FAIL (pre-existing, M2 ink) |
| label_basic | text | 97.0 | 94.095 | 94.115 | +0.020 | FAIL (pre-existing, M2 ink) |
| label_dark | text | 97.0 | 95.198 | 95.253 | +0.055 | FAIL (pre-existing, M2 ink) |
| label_mono_italic | text | 97.0 | 94.617 | 94.617 | +0.000 | FAIL (pre-existing, M2 ink) |
| label_multiline | text | 97.0 | 94.865 | 94.865 | +0.000 | FAIL (pre-existing, M2 ink) |
| label_sizes | text | 97.0 | 94.642 | 94.642 | +0.000 | FAIL (pre-existing, M2 ink) |
| label_truncate | text | 97.0 | 94.269 | 94.269 | +0.000 | FAIL (pre-existing, M2 ink) |
| label_weights | text | 97.0 | 91.118 | 91.118 | +0.000 | FAIL (pre-existing, M2 ink) |
| nested_deep | geometry | 99.5 | 99.988 | 100.0 | +0.012 | PASS |
| progress_views | control | 96.0 | 92.507 | 92.507 | +0.000 | FAIL (pre-existing, M3) |
| stack_horizontal | control | 96.0 | 27.451 | 27.451 | +0.000 | FAIL (pre-existing, M3) |
| stack_vertical | control | 96.0 | 21.109 | 21.109 | +0.000 | FAIL (pre-existing, M3) |
| switch_onoff | control | 96.0 | 90.529 | 90.529 | +0.000 | FAIL (pre-existing, M3) |
| transforms | geometry | 99.5 | 99.816 | 99.816 | +0.000 | PASS |
| zorder_hidden | geometry | 99.5 | 100.0 | 100.0 | +0.000 | PASS |

Every scene that passes with the Swift backend passes with quartz; **no scene
scores below the Swift backend** (all deltas ≥ 0). The FAILs are the
pre-existing M2 glyph-ink / M3 controls gaps, identical under both backends
(text output is byte-identical by construction — see below).

Direct quartz-vs-swift diff: label/transform scenes byte-identical; AA edges
of rounded clips/corners differ by a few counts on a handful of pixels
(quartz's AA is *closer* to real CG there, hence the positive deltas).

## Adapter design decisions

- **Flip CTM**: QZ user space is y-up/bottom-left over a top-down
  premultiplied backing (CGBitmapContext semantics). At creation the adapter
  concats `translate(0, H_px)` + `scale(s, -s)` (device pixels, s = Canvas
  scale), making QZ user space exactly Canvas's top-down point space.
  Proven with the asymmetric `boxes_basic` fixture: byte-identical output.
- **Premul → straight**: the QZ backing is premultiplied; `Bitmap`/`pngData`
  are straight alpha. The adapter converts the affected device region after
  each op (full surface at outermost `EndTransparencyLayer`), so
  `bitmap.pixels` is always current and the conversion happens exactly once
  per pixel write (no double conversion). Inherent loss: RGB of pixels whose
  alpha rounds to 0 (premul cannot represent it). Straight = `round(p*255/a)`.
- **drawMask**: glyph coverage masks are blended CPU-side directly into the
  QZ backing (premultiplied source-over with the same float math as the Swift
  rasterizer, clip from Canvas's mirror clip mask). Chosen over
  `QZContextClipToMask` + fill to keep label output byte-identical with the
  tuned glyph smoothing (and it is much faster: ClipToMask is O(surface)).
- **hardEdges** → `QZContextSetShouldAntialias(false)` around the fill; QZ's
  non-AA rasterizer thresholds at pixel centers, same as the Swift
  `_fillHardEdged` sampling.
- **Transparency layers** → `QZContextSetAlpha(alpha)` +
  `QZContextBeginTransparencyLayer`; QZ captures the alpha at Begin and
  applies it when compositing at End (verified in qz_context.cpp — matches
  CG). The adapter resets alpha to 1 after End because Canvas treats layer
  alpha as a per-layer parameter, not sticky state.
- **drawImage** → `QZImageCreate` (takes straight RGBA, stores premul) +
  counter-flip about the dest rect (QZ, like CG, maps the image bottom row to
  `rect.minY` in y-up space; our user space is top-down).
  `interpolate: true` maps to `kQZInterpolationDefault` — quartz's default
  filter is a sharpened kernel matching real CG, intentionally NOT identical
  to the Swift backend's plain bilinear; `false` → `kQZInterpolationNone`
  (identical to Swift's nearest-neighbor).
- **Canvas mirror state**: Canvas keeps its own CTM + clip coverage mask for
  both backends (public `ctm`, Swift rasterizer state, quartz drawMask clip).
  Under quartz the clip is computed twice (mirror + QZ) — clip ops are rare
  (one per clipsToBounds view / truncating label), cost is negligible.

## v2 ops: shadows + gradients (2026-08)

- **Shadows** — `Canvas.setShadow` state maps to
  `QZContextSetShadowWithColor` inside a Save/RestoreGState bracket around
  the casting fill (QZ composites shadow-then-fill in one op, CG order). QZ
  transforms the offset by the CTM — with the flip CTM, Canvas's top-down
  +y-down offsets pass through unchanged. QZ's blur parameter is in DEVICE
  pixels (sigma = blur/2), so the adapter scales the point-space blur by
  sqrt(|det CTM|). `drawShadowOnly` (group-opacity layers) fills the path
  with a zero-alpha color while the shadow is set: QZ derives the shadow
  from geometry coverage independent of the fill color, and the zero-alpha
  fill blends nothing. The Swift backend ports QZ's exact 3x box-blur
  construction (RasterizerEffects.swift), so backend shadow outputs agree
  to ≤ 1 count on pixel-aligned shapes.
- **Gradients** — `Canvas.drawLinearGradient` maps to `QZGradientCreate` +
  `QZContextDrawLinearGradient` with both draws-before/after options, inside
  a saved clip to the target rect. QZ lerps stops per-channel in straight
  sRGB — identical semantics to the Swift backend's per-pixel projection
  loop, so outputs match to rounding. CAGradientLayer's gamma-1.8
  interpolation space is handled ABOVE this API (UIGradientView densifies
  stops; see ARCHITECTURE.md).
- Suite (2026-08-24): all 9 shadow/gradient scenes pass BOTH backends;
  quartz: shadows_basic 99.99, shadows_radii/dark 100, shadow_with_corner
  100, alpha_shadow_group 100, gradient_basic 100, gradient_multi 99.77,
  gradient_dark 99.89, gradient_in_stack 99.96 (swift within ±0.02).

## M6: animation engine (2026-08-24)

`UIView.animate(withDuration:delay:options:animations:completion:)` and the
spring variant live in `Sources/OpenUIKit/UIViewAnimation.swift`. Inside the
block, property setters (center/bounds/alpha/backgroundColor/transform/
layer.cornerRadius, frame = position + bounds) RECORD from→to animations on
the view and update the model immediately (UIKit semantics: model = final).
`OpenUIKitRuntime.animationTime` is the settable presentation clock;
LayerBridge overwrites each animated layer field with the value sampled at
that time (`applyPresentation`). openrender sets the clock per capture time
and writes `<name>.t<ms>.png` frames (scene spec v3).

Quartz/Swift split (who evaluates what):

- All TIMING evaluation is quartz's animation/timing engine:
  - cubic beziers through `QZMediaTimingFunctionCreateWithControlPoints` +
    `QZMediaTimingFunctionSolve` (the same Newton+bisection x(t) solve CA
    uses; verified against golden frame positions to < 0.1 pt at every
    capture time of anim_move/anim_delay/anim_resize);
  - springs through a scratch `QZSpringAnimation` (opacity 1→0, so the
    sampled opacity IS the remaining-fraction envelope) evaluated with
    `QZLayerCopyPresentation` at the local time.
- VALUE application stays in Swift (LayerBridge) because CA semantics
  quartz's animation value model lacks are needed: per-animation delay with
  backwards fill (FROM before `delay`), exact model snap at
  `delay + duration` (CA removes completed animations — verified in the
  frozen-clock goldens), extended-sRGB componentwise color lerp (verified
  against anim_color: golden pixels match gamma-space lerp exactly), and
  affine interpolation via CA-style decomposition (translation/scale/shear/
  rotation each lerp, rotation shortest-path; anim_transform_rotate goldens
  confirm constant area = pure angle lerp, bbox exact at every frame).
  The edge-antialias rule (transformed layers composite hard-edged) follows
  the PRESENTATION transform.

UIView spring model (reverse-engineered EXACTLY, not fitted): probing the
CASpringAnimation UIKit emits (oracle2 `ORACLE2_ANIM_DEBUG=1`, 30 (ζ, D, v)
combinations) shows mass = 1, damping ratio preserved, and the natural
frequency duration-fit solving, for ζ < 1:

    |(β − v)/ω_d| · e^(−β·D) = 0.001        β = ζ·ω_n, ω_d = ω_n·√(1−ζ²)

(v = normalized initialSpringVelocity; the |…| factor is the sin
coefficient of the underdamped envelope). For v = 0 this closes to
ω_n = ln(1000·ζ/√(1−ζ²)) / (ζ·D) and reproduces UIKit's stiffness/damping
to 8+ significant digits on every probe (ζ ∈ [0.1, 0.99], D ∈ [0.3, 2]).
ζ = 1 solves (1 + (ω−v)·D)·e^(−ω·D) = 0.001 (probe: ω·D = 9.23341).
Residual vs goldens: ≤ 0.16 pt at every spring capture point except the
fastest overshoot frame of the ζ=0.35 spring (+0.64 pt) — the offset
remains when the formula is driven by UIKit's own probed stiffness/damping,
i.e. CA's evaluator deviates from the ideal damped-spring solution there,
not our fit. See AnimationTests + KNOWN_GAPS (large-velocity branch).

Suite: all 10 animation scenes pass compare (worst frame 99.08 % on the
text scene anim_label_move vs 97 % required; worst geometry frame 99.72 %
vs 99.5 %); every frame of anim_fade is 100 %.

## Vendoring / build integration

- `scripts/sync_quartz.sh` mirrors `~/quartz` → `Sources/CQuartz`
  (rsync --delete, idempotent). `Sources/CQuartz/include/module.modulemap` is
  local (not upstream): quartz's package headers are designed to be included
  via `quartz.h` in dependency order, so the module uses `quartz.h` as its
  sole entry point instead of SPM's whole-directory umbrella.
- Vendored sources are an exact upstream mirror PLUS the minimal M5
  layer-compositor patches in `patches/quartz/` (reapplied by
  sync_quartz.sh after every rsync; see docs/QUARTZ_PATCHES.md — each has
  an upstream-suggested fix). Two build-level accommodations in
  Package.swift (not source patches):
  - `STBTT_STATIC` + target-wide `STB_TRUETYPE_IMPLEMENTATION` so quartz's
    private stb_truetype copy has internal linkage and cannot collide with
    the `CSTBTrueType` target when both are linked into one binary.
  - package-level `cxxLanguageStandard: .cxx17`.
- No quartz bugs found in the ops this adapter exercises; no workarounds
  needed beyond the documented semantic mappings above.

## Known divergences (accepted)

- AA edge coverage: quartz supersamples, the Swift backend computes analytic
  coverage — few-count differences on curved/clipped edges (quartz is closer
  to real CG on the suite).
- Interpolated image scaling differs by design (see drawImage above).
- Stroking: quartz strokes geometrically in user space (proper caps/joins/
  dashes); the Swift backend approximates with segment quads + round joints.
  Straight strokes agree; curved/jointed strokes may differ slightly. No
  library code paths currently stroke.
- During a transparency layer, `bitmap.pixels` shows the pre-layer surface
  under quartz (the Swift backend shows the in-progress layer). No observer
  reads mid-layer; after End they agree.
