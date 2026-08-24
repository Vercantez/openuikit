# OpenUIKit Architecture

A portable reimplementation of UIKit, validated against **real UIKit** (via the
Mac Catalyst oracle in `Tools/oracle`). Ground truth lives in `golden/`.

## Hard rules

1. `Sources/OpenCoreGraphics` and `Sources/OpenUIKit` must **never** import
   Foundation or any Apple framework. Pure Swift stdlib + the two C shims
   (`CPortableIO` for file reads, `CSTBTrueType` for glyph rasterization).
   `Sources/openrender` (the CLI) MAY use Foundation.
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

## Module ownership map

| Path | Owner module | Status |
|---|---|---|
| `Sources/OpenCoreGraphics/Geometry.swift` | core (done) | frozen |
| `Sources/OpenCoreGraphics/Canvas.swift` | core (done) | frozen contract |
| `Sources/OpenCoreGraphics/PNG.swift` | core (done) | frozen |
| `Sources/OpenCoreGraphics/Rasterizer.swift` | **rasterizer** | stub — implement |
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
For a view with alpha `a`, cornerRadius `r`:
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
- `UISwitch` thumb does not draw via offscreen `layer.render` — scene
  `switch_onoff` is `layoutOnly` until the oracle hosts a real window
  (planned: full Catalyst app with `drawHierarchy`).
- Oracle is Mac Catalyst iOS 26.1 UIKit. That version's metrics/colors are
  canon.

## openrender CLI contract (must mirror oracle exactly)

```
openrender render <outdir> <scene.json>...
```
Reads scene JSON per `docs/SCENE_SPEC.md`, builds OpenUIKit views, layouts,
writes `<name>.png` + `<name>.layout.json` in the same format as the oracle
(sorted keys, 3-decimal rounding, same intrinsic/sizeThatFits200 rules).
