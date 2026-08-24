# OpenUIKit Architecture

A portable reimplementation of UIKit, validated against **real UIKit** (via the
Mac Catalyst oracle in `Tools/oracle`). Ground truth lives in `golden/`.

## Hard rules

1. `Sources/OpenCoreGraphics` and `Sources/OpenUIKit` must **never** import
   Foundation or any Apple framework. Pure Swift stdlib + the C shims
   (`CPortableIO` for file reads, `CSTBTrueType` for glyph rasterization,
   `CQuartz` — the vendored portable quartz library — for the default
   rendering backend). `Sources/openrender` (the CLI) MAY use Foundation.
2. Real UIKit behavior wins every argument. `golden/system_colors.json`,
   `golden/font_metrics.json`, and `golden/*.png|.layout.json` are ground truth.
3. Do not change files another module owns (see map below). The Canvas API in
   `Canvas.swift` is a frozen contract; if it is genuinely insufficient, extend
   it additively.
4. Never use `Date()`, network, or absolute paths in library code.

## Build & verify loop

```sh
swift build                                   # must stay green
swift run openrender render out fixtures/scenes/*.json
python3 Tools/compare/compare.py              # pass/fail per scene
./scripts/build_oracle.sh                     # (re)build the oracle if needed
./Tools/oracle/oracle render golden fixtures/scenes/*.json   # regenerate goldens
```

`compare.py` thresholds are in `docs/SCENE_SPEC.md`. A scene passes when layout
matches within 0.5pt and pixels match at the category threshold.

## Rendering backends (M4)

`Canvas` (the frozen drawing contract) dispatches every drawing op through a
backend chosen at Canvas creation — callers (RenderPass, UILabel, …) are
backend-agnostic:

- **`.quartz` (default)** — `QuartzBackend` renders through the vendored
  **libquartz** (`Sources/CQuartz`, synced from `~/quartz` by
  `scripts/sync_quartz.sh`): the portable C++17 Quartz 2D + CoreAnimation
  reimplementation with the `QZ*` C API, oracle-validated at 97.5/100 vs
  Apple. Adapter notes:
  - QZ user space is y-up/bottom-left (CGBitmapContext-style); a flip CTM
    (`translate 0,H_px; scale s,-s`) applied at context creation makes QZ
    user space identical to Canvas's top-down point space.
  - The QZ backing is premultiplied RGBA8888; after every op the affected
    device region is converted premultiplied→straight into `bitmap.pixels`,
    so the Bitmap is always current (no explicit flush; RGB of fully
    transparent pixels is lost — that is inherent to premultiplied storage).
  - Glyph coverage masks (`drawMask`) are blended CPU-side straight into the
    QZ backing with the same math as the Swift rasterizer, so label output
    is byte-identical between backends (glyph-smoothing tuning preserved).
  - `hardEdges` fills map to `QZContextSetShouldAntialias(false)` (both
    backends threshold at pixel centers); transparency layers map to
    `QZContextSetAlpha` + `Begin/EndTransparencyLayer` (group alpha applied
    at End, CG semantics).
- **`.swift`** — `SwiftRasterizerBackend`: the pure-Swift analytic-coverage
  rasterizer (`Rasterizer.swift`), zero dependencies, unchanged behavior.
  Canvas always keeps the mirror graphics state (CTM + clip mask) itself; it
  serves the public `ctm`, the Swift rasterizer, and quartz's `drawMask` clip.

Selection: `OpenUIKitRuntime.renderBackend` (alias of
`CanvasBackendSelection.current` in OpenCoreGraphics). The library never
reads env vars; **openrender** honors `OPENUIKIT_BACKEND=swift|quartz`.
Dual-backend suite comparison (2026-08): quartz ≥ swift on every scene
(deltas +0.00 to +0.09), text scenes byte-identical. See
`docs/QUARTZ_NOTES.md` for details and known divergences.

## Compositors (M5)

`UIRenderer.render` dispatches on `OpenUIKitRuntime.compositor`
(openrender honors `OPENUIKIT_COMPOSITOR=layers|renderpass`):

- **`.layers` (default)** — `LayerBridge.swift` builds a real **QZLayer
  tree** from the laid-out view hierarchy and lets quartz's CALayer
  compositor (`QZLayerRenderInContext`) do all compositing: background /
  cornerRadius / border / masksToBounds / opacity groups / shadows /
  transforms, UIGradientView → QZGradientLayer (quartz interpolates in
  CA's Generic-RGB space itself). View custom content (label glyphs,
  image pixels, control chrome) still renders through the EXISTING
  drawContent path into a transparent offscreen Canvas at device scale
  and is attached as a contents-image sublayer at index 0, its frame
  snapped out to the device grid so compositing is a 1:1 blit (glyph ink
  tables and CG-profile image resampling are unchanged). The UIKit quirks
  below (unclamped cornerRadius, hard transformed edges, border above
  sublayers, group-opacity shadow ordering, CA shadowRadius blur) are
  reproduced by three surgical patches to the vendored quartz —
  `patches/quartz/`, applied by `scripts/sync_quartz.sh`, documented in
  `docs/QUARTZ_PATCHES.md`. Requires the quartz backend; under
  `renderBackend == .swift` the render pass is used regardless so the
  pure-Swift path stays dependency-free.
- **`.renderPass`** — the hand-written traversal below
  (`UIRenderer.renderPassRender`), kept fully intact as the fallback and
  as the pure-Swift-backend compositor.

Both compositors pass the full 42-scene suite on the quartz backend
(layers ≥ renderpass on every scene except deltas ≤ 0.003; button/gradient
scenes score up to +1.5 higher under layers).

## Module ownership map

| Path | Owner module | Status |
|---|---|---|
| `Sources/OpenCoreGraphics/Geometry.swift` | core (done) | frozen |
| `Sources/OpenCoreGraphics/Canvas.swift` | core (done) | frozen contract (dispatches via Backend.swift) |
| `Sources/OpenCoreGraphics/PNG.swift` | core (done) | frozen |
| `Sources/OpenCoreGraphics/Rasterizer.swift` | **rasterizer** | stub — implement |
| `Sources/OpenCoreGraphics/Backend.swift`, `QuartzBackend.swift` | **quartz-backend** | done |
| `Sources/CQuartz/` | vendored (scripts/sync_quartz.sh) | do not edit by hand — mirror of ~/quartz + `patches/quartz/*` (docs/QUARTZ_PATCHES.md) |
| `Sources/OpenUIKit/LayerBridge.swift` | **view** | done (M5 layers compositor) |
| `Sources/OpenUIKit/MiniJSON.swift` | **runtime-util** | to create |
| `Sources/OpenUIKit/ResourceIO.swift` | **runtime-util** | to create |
| `Sources/OpenUIKit/UIColor.swift`, `SystemColors.swift`, `UITraitCollection.swift` | **color** | to create |
| `Sources/OpenUIKit/CALayer.swift`, `UIView.swift`, `RenderPass.swift` | **view** | to create |
| `Sources/OpenUIKit/UIFont.swift`, `FontEngine.swift`, `TextLayout.swift`, `UILabel.swift` | **text** | to create |
| `Sources/OpenUIKit/UIImage.swift`, `UIImageView.swift` | **image** | to create |
| `Sources/OpenUIKit/UIButton.swift`, `UISwitch.swift`, `UIProgressView.swift` | **controls** | to create |
| `Sources/OpenUIKit/UIStackView.swift` | **stack** | to create |
| `Sources/openrender/main.swift` | **rendercli** | to create |
| `Tests/OpenUIKitTests/*` | shared: add tests for YOUR module only | |

## Behavioral contracts (verified against real UIKit)

### View model
- `UIView` stores `center` + `bounds` + `transform` as source of truth (like
  real UIKit). `frame` is derived: bbox of `bounds` transformed about `center`
  (anchor point 0.5, 0.5). Setting `frame` with identity transform sets
  center/bounds directly.
- `backgroundColor` nil = transparent. Subviews render in array order.
- `isHidden` skips the entire subtree.

### Render pass (order matters — matches CALayer compositing)
(The contract below is what BOTH compositors implement: RenderPass.swift
directly, LayerBridge via the patched quartz layer compositor.)
For a view with alpha `a`, cornerRadius `r`:
0. Layer shadow (spec v2, `shadowOpacity > 0 && !masksToBounds`): the
   blurred, offset silhouette of the layer's shape (outer rounded rect when
   the background is visible, else the border ring) composites BENEATH
   everything and is never occluded by the layer's own content. With `a < 1`
   the shadow is drawn BEFORE the transparency layer at strength
   `shadowColor.alpha × shadowOpacity × a` (verified vs
   golden/alpha_shadow_group — the shadow shows through a translucent
   layer); otherwise it rides the background/border fill via the Canvas
   shadow state (CanvasEffects.swift). Blur: `Canvas.setShadow(blur:
   2×shadowRadius)` renders Gaussian sigma = shadowRadius points (both
   backends share the same 3× box-blur construction; sigma fitted
   0.93·r·scale px against golden/shadows_radii). Offset +y is DOWN.
1. If `a < 1`: `beginTransparencyLayer(alpha: a)` — alpha groups the WHOLE
   subtree (background + content + subviews + border composite first, then
   fade as a unit).
2. Background fill: rounded rect (radius `r`) in bounds.
3. View content (label text, image, control chrome).
4. Subviews (each: save state; translate to its position; concatenate its
   transform about its center; recurse; restore). If `clipsToBounds`, clip to
   rounded bounds BEFORE drawing subviews (content of the layer itself is
   also clipped by masksToBounds in CA — apply the clip before step 3).
5. **Border last, on top of subviews** — CALayer draws `borderWidth`/
   `borderColor` above its contents and sublayers. Border is centered on the
   bounds edge path but clipped to the outside edge: draw the rounded-rect
   ring between `bounds` and `bounds.insetBy(borderWidth)` (fill the ring,
   do not stroke the midline).
6. End transparency layer if opened.

Root render for openrender: `Canvas(bitmap: Bitmap(w*scale, h*scale), scale:)`,
then render the root view; PNG out is non-premultiplied RGBA (compare.py
converts both sides via PIL, so alpha handling just has to be consistent —
the oracle outputs standard PNG).

### Corner radius
`layer.cornerRadius` uses **circular** corners (kappa bezier approximation is
fine — `Path.roundedRect` implements it). Radius clamps to min(w,h)/2.
UIKit does NOT use continuous corners unless requested; default `cornerCurve`
is `.circular`.

### Anti-aliasing
- Plain (non-transformed) layer edges are pixel-aligned rect fills — when
  edges land on integer pixel boundaries there is no AA to worry about; when
  fractional, CG applies analytic coverage AA. Implement analytic-coverage AA
  for all fills.
- **Rotated/scaled layers do NOT anti-alias their edges** in UIKit
  (`edgeAntialiasingMask` is effectively off; see golden/transforms.png —
  hard-edged rotated rects). The render pass, not the rasterizer, handles
  this: rasterize transformed layer rects with AA disabled at the edge
  (round coverage to 0/1) while still AA-ing rounded corners/text. Simplest
  approach matching goldens: when a view has a non-identity, non-translation
  transform, fill its background with hard (threshold 0.5) coverage.

### Gradients (UIGradientView / CAGradientLayer, spec v2)
- `startPoint`/`endPoint` are in the layer's UNIT space (top-left geometry);
  pixels project onto the axis in unit space (a (0,0)→(1,1) gradient on a
  non-square layer follows the unit diagonal — golden/gradient_basic).
- CA does NOT interpolate in gamma-sRGB (CGGradient-style) or linear light.
  Fitting the golden ramps: interpolation is linear in a gamma-1.8 encoded
  space whose linear primaries are a small matrix away from linear sRGB
  (Generic-RGB-profile-like; `_CAGradientColorSpace` in UIGradientView.swift,
  least-squares calibrated on gradient_basic/multi, validated on
  gradient_dark with < 3 counts max error). UIGradientView densifies each
  stop segment into 24 sRGB sub-stops; both backends then draw the same
  piecewise-linear sRGB gradient (`Canvas.drawLinearGradient`).

### Colors
- `UIColor` is dynamic: semantic colors (`.label`, `.systemBackground`, …)
  resolve through the current `UITraitCollection` (light/dark). The resolved
  sRGB values MUST be loaded from `Sources/OpenUIKit/Resources/system_colors.json`
  (copied from golden — regenerate with `oracle colors`).
- Blending happens on gamma-encoded sRGB values (CG semantics for sRGB
  surfaces): `dst = src*a + dst*(1-a)` per channel on 0–255 values.

### Text
- Font ground truth: `golden/font_metrics.json` — per size/weight: ascender,
  descender (negative), lineHeight, capHeight, xHeight, leading, per-ASCII-char
  advances, and reference string widths. `UIFont` + label sizing MUST be
  data-driven from a vendored copy in `Sources/OpenUIKit/Resources/`.
  Note SF switches optical family at 20pt (Text→Display) — the table has
  per-integer-size entries; interpolate linearly between adjacent entries for
  fractional sizes.
- Single-line label width from the table = stringWidth (sum of advances is
  close but the table's `stringWidths` reveal kerning — validate; if sums
  are off by >0.5pt implement pair adjustment from stb_truetype kerning).
- `UILabel.sizeThatFits`/`intrinsicContentSize` height for 1 line =
  ceil-to-pixel of font.lineHeight (check goldens: 17pt → 20.0? verify
  exact rounding: label height 20.0 for 17pt, width 83.5 for "Hello UIKit"
  at scale 2 → width rounds up to nearest 0.5 = 1/scale).
- Glyph rendering: stb_truetype on the system font file. On macOS load
  `/System/Library/Fonts/SFNS.ttf` (variable font: stb uses the default
  instance = Regular; for other weights try named instances or fall back to
  `SFNS.ttf` + `SFNSMono.ttf`, check `/System/Library/Fonts/` — verify what
  file gives closest visual match; SF Pro downloads may exist under
  `/Library/Fonts`). Text baseline: first line baseline at
  `ascender` from the top of the text rect; vertical centering in a fixed
  frame: text block of height n*lineHeight centered and the block offset
  rounded to pixel (verify against golden/label_align.png).

### Traits
`UITraitCollection(userInterfaceStyle:)` with `.light`/`.dark`.
The scene runner sets the root trait environment; views inherit.
`overrideUserInterfaceStyle` on UIView overrides for the subtree.

## Oracle notes / known gaps
- `UISwitch` thumb does not draw via offscreen `layer.render` — such scenes
  carry a top-level `"window": true` and are rendered by **`Tools/oracle2`**,
  a Mac Catalyst APP (`scripts/build_oracle2.sh`, run via
  `Tools/oracle2/run.sh render <outdir> <scene.json>...`) that hosts the
  hierarchy in a real `UIWindow` attached to a `UIWindowScene`, activates the
  app (inactive Catalyst windows desaturate control tints), waits until the
  render server composites (probe poll), then captures with
  `drawHierarchy(afterScreenUpdates: true)`. Scene building/layout dumping is
  shared with v1 via `Tools/oracle/SceneKit.swift`, so layout dumps are
  byte-identical; pixels differ from v1 by ≤2 counts in flat regions (≤5 max,
  display color-space round trip) — do not regenerate normal scenes with v2.
  `scripts/regen_goldens.sh` routes each scene to the right oracle.
- Oracle is Mac Catalyst iOS 26.1 UIKit. That version's metrics/colors are
  canon.

## openrender CLI contract (must mirror oracle exactly)

```
openrender render <outdir> <scene.json>...
```
Reads scene JSON per `docs/SCENE_SPEC.md`, builds OpenUIKit views, layouts,
writes `<name>.png` + `<name>.layout.json` in the same format as the oracle
(sorted keys, 3-decimal rounding, same intrinsic/sizeThatFits200 rules).
