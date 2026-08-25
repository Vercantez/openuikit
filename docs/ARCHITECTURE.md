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

## Animation (M6)

`Sources/OpenUIKit/UIViewAnimation.swift` implements
`UIView.animate(withDuration:delay:options:animations:completion:)` and the
`usingSpringWithDamping:` variant. Property setters inside the block record
from→to animations on the view (model updates immediately — UIKit
semantics); `OpenUIKitRuntime.animationTime` is the settable presentation
clock; LayerBridge samples the recorded animations at that time and builds
the QZLayer tree from PRESENTATION values (quartz's animation/timing engine
evaluates beziers and spring envelopes; Swift applies values with CA's
delay-fill/removal, color-space and transform-decomposition semantics).
openrender renders scene-spec-v3 animation scenes one frame per
`captureTimes` entry (`<name>.t<ms>.png`, same naming as oracle2's
frozen-clock captures). Details incl. the exactly reverse-engineered UIKit
spring duration fit: `docs/QUARTZ_NOTES.md` "M6: animation engine";
scope notes in `docs/KNOWN_GAPS.md`.

## Events (M7)

Hit testing (`UIView.point(inside:with:)` / `hitTest(_:with:)` /
`convert(_:to:/from:)`) implements exact UIKit semantics, verified probe-by-
probe against real UIKit via scene-spec-v4 `"hitTests"` (see
docs/SCENE_SPEC.md "Hit tests"). Touch delivery is host-driven and
wall-clock-free — the host feeds its input stream into a `UIWindow`:

```swift
let window = UIWindow(frame: screenBounds)   // host sizes it
window.addSubview(rootView)
// one call per pointer/touch phase change; timestamps from any monotonic clock
window.sendTouch(.began, at: p, timestamp: t, touchID: 0)
window.sendTouch(.moved, at: p2, timestamp: t2, touchID: 0)
window.sendTouch(.ended, at: p2, timestamp: t3, touchID: 0)
window.tick(timestamp: now)   // per-frame while touches are down (long press)
```

`sendTouch` maintains `UITouch` identity/tapCount, lays out + hit-tests on
began, and routes UIEvents: gesture recognizers on the hit-test view's
superview chain observe first, recognition applies cancelsTouchesInView
(the view gets `touchesCancelled` — even for a lift-recognized tap), then
the view's `touchesBegan/Moved/Ended/Cancelled` run. `UIControl` implements
UIKit's tracking (begin/continue/endTracking, highlight, drag enter/exit,
touchUpInside/Outside) with closure targets
(`addTarget(for:) { control, event in }` — no ObjC selectors);
`UIButton` dims its title to alpha 0.2 while highlighted (golden-exact);
`UISwitch` toggles + fires `.valueChanged` on inside release with the
golden-fitted thumb-slide animation. Gesture recognizers: tap (multi-tap
via UITouch.tapCount), pan (10 pt slop, translation/velocity), long press
(0.5 s via event timestamps or `tick`). All timing comes in through the
API — synthetic sequences are fully deterministic (EventSystemTests).

## Module ownership map

| Path | Owner module | Status |
|---|---|---|
| `Sources/OpenCoreGraphics/Geometry.swift` | core (done) | frozen |
| `Sources/OpenCoreGraphics/Canvas.swift` | core (done) | frozen contract (dispatches via Backend.swift) |
| `Sources/OpenCoreGraphics/PNG.swift` | core (done) | frozen |
| `Sources/OpenCoreGraphics/Rasterizer.swift` | **rasterizer** | stub — implement |
| `Sources/OpenCoreGraphics/Backend.swift`, `QuartzBackend.swift` | **quartz-backend** | done |
| `Sources/CQuartz/` | vendored (scripts/sync_quartz.sh) | do not edit by hand — mirror of ~/quartz + `patches/quartz/*` (docs/QUARTZ_PATCHES.md) |
| `Sources/OpenUIKit/LayerBridge.swift` | **view** | done (M5 layers compositor + M6 presentation sampling) |
| `Sources/OpenUIKit/UIViewAnimation.swift` | **animation** | done (M6 engine) |
| `Sources/OpenUIKit/MiniJSON.swift` | **runtime-util** | to create |
| `Sources/OpenUIKit/ResourceIO.swift` | **runtime-util** | to create |
| `Sources/OpenUIKit/UIColor.swift`, `SystemColors.swift`, `UITraitCollection.swift` | **color** | to create |
| `Sources/OpenUIKit/CALayer.swift`, `UIView.swift`, `RenderPass.swift` | **view** | to create |
| `Sources/OpenUIKit/UIFont.swift`, `FontEngine.swift`, `TextLayout.swift`, `UILabel.swift` | **text** | to create |
| `Sources/OpenUIKit/UIImage.swift`, `UIImageView.swift`, `ImageCodec.swift` | **image** | done (app-compat: PNG/JPEG load+encode via the vendored stb_image) |
| `Sources/OpenUIKit/UIBezierPath.swift`, `UIGraphicsRenderer.swift` | **drawing** | done (app-compat: paths, `UIView.draw(_:)`, `UIGraphicsImageRenderer`) |
| `Sources/OpenUIKit/UIActivityIndicatorView.swift`, `UISlider.swift`, `UISegmentedControl.swift`, `UIPageControl.swift` | **controls** | done (app-compat, oracle fixtures `control_*`) |
| `Sources/OpenUIKit/UIButton.swift`, `UISwitch.swift`, `UIProgressView.swift` | **controls** | done (M7: UIControl-based) |
| `Sources/OpenUIKit/UITouch.swift`, `UIEvent.swift`, `UIGestureRecognizer.swift`, `UIControl.swift` | **event** | done (M7) |
| `Sources/OpenUIKit/UIResponder.swift`, `UIApplication.swift`, `UIScreen.swift`, `UIDevice.swift` | **lifecycle** | done (M12: responder chain + app lifecycle + host-driven environment) |
| `Sources/OpenUIKit/UIScrollView.swift` | **scroll** | done (M7.5: UIKit-exact physics; delaysContentTouches lives in UIEvent.swift's delivery pipeline) |
| `Sources/OpenUIKit/UITableView.swift`, `UITableViewCell.swift`, `UITableViewController.swift` | **tableview** | done (M10: tiled rows, measured chrome, `performUpdates`) |
| `Sources/OpenUIKit/UIReuse.swift`, `UICollectionView.swift`, `UICollectionViewCell.swift`, `UICollectionViewLayout.swift`, `UICollectionViewFlowLayout.swift` | **collection** | done (M13: the reuse machinery lifted out of UITableView into `ReuseRegistry`/`VisibleViewMap` and shared; flow-layout geometry measured by `scripts/flow_probe.sh`, fixtures `collection_*`) |
| `Sources/OpenUIKit/UIStackView.swift` | **stack** | to create |
| `Sources/OpenUIKit/AutoLayout/` (Cassowary, NSLayoutConstraint, Anchors, LayoutEngine) | **autolayout** | done (M9) |
| `Sources/OpenUIKit/AutoLayout/UILayoutGuide.swift` | **autolayout** | done (controls2: `UILayoutGuide` in the solver + the measured safe-area / layout-margins / readable-content model; fixture `constraints_safearea`) |
| `Sources/OpenUIKit/UIRefreshControl.swift`, `UISearchBar.swift`, `UIStepper.swift`, `UIPickerView.swift` | **controls** | done (controls2; only `UIRefreshControl` could be goldened — the others' chrome does not composite offscreen, see docs/KNOWN_GAPS.md) |
| `Sources/OpenUIKit/NotificationCenter.swift`, `Timer.swift` | **lifecycle** | done (controls2: portable, Foundation-shadowing; `Timer` fires from `UIWindow.tick(timestamp:)`) |
| `Sources/OpenUIKit/UIPresentationController.swift`, `UIViewControllerTransitioning.swift`, `UIPresentation.swift` | **viewcontroller** | done (M12: every modal presentation and animated push/pop runs through a presentation controller + animator; the built-in ones are `UISheetPresentationController`/`_UIPageSheetAnimator` and `_UINavigationSlideAnimator`) |
| `Sources/OpenUIKit/UIAlertController.swift`, `UIAlertAction.swift` | **viewcontroller** | done (M12: iOS 26 alert card, measured by `Tools/oracle2/alertprobe`) |
| `Sources/OpenUIKit/UIMenu.swift`, `UIContextMenu.swift` | **menus** | done (M13: UIAction/UIMenu/UIKeyCommand + responder-chain routing; platter measured by `Tools/oracle2/menuprobe`, NO fixture — docs/KNOWN_GAPS.md explains why) |
| `Sources/OpenUIKit/UIAdaptivePresentation.swift`, `UISearchBar.swift`, `UIActivityViewController.swift` | **viewcontroller** / **text-input** | done (M13: the delegate-protocol cluster; the search bar's chrome and the share sheet are documented stubs) |
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
  Two CUTS of that ground truth exist: `golden/font_metrics.json` is the Mac
  Catalyst dump (`.SFNS`, the default) and `golden/font_metrics_ios.json` the
  same dump re-taken on iOS 26.1 (`.SFUI`, `Tools/oracle2/fontprobe`). They
  differ only in advances, by a per-size constant that is zero at 20 pt and
  above — `FontEngine.SystemFontCut` / `OpenUIKitRuntime.systemFontCut`
  selects between them, and openrender picks the iOS cut for the scenes the
  fixture suite renders in the Simulator. docs/KNOWN_GAPS.md has the law.
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

### Responder chain (M12)
`UIResponder` is the real base class: `UIView`, `UIViewController`,
`UIApplication` and `UIScene` all derive from it. `next` implements UIKit's
documented chain —

| responder | next |
|---|---|
| a view | the view controller whose ROOT view it is, else its superview |
| a view controller | the controller that PRESENTED it, else its view's superview |
| a window | its `UIWindowScene` if it has one, else `UIApplication.shared` |
| `UIApplication` | its delegate, when the delegate is a `UIResponder` |

so a control deep inside a pushed screen walks `control -> … -> vc.view ->
vc -> container view -> container vc -> window -> application -> app
delegate -> nil`. `touches*`/`presses*` default to forwarding along it
(UIKit's default); anything that handles a phase overrides WITHOUT calling
super, which is what `UIControl`, `UITableViewCell` and the scroll pipeline
already did. Touch DELIVERY is unchanged: `UIWindow` still hit-tests and
calls the hit view directly (see "Events").

First-responder state lives on `UIWindow.firstResponder`, as in UIKit, and
is reachable from any responder through `_firstResponderWindow` — which is
why a detached view cannot take focus and a view controller can.

### Application lifecycle (M12)
`UIApplicationMain(delegate:)` runs the launch sequence and **returns** —
the portable core has no run loop (see "Hard rules"). The host owns the
loop and drives the rest: `_hostDidBecomeActive()` after the first frame,
`_hostWillResignActive()` / `_hostDidEnterBackground()` /
`_hostWillEnterForeground()` as the surface changes, `_hostWillTerminate()`
on quit. `applicationState` and the delegate callback ORDER are UIKit's;
only the trigger differs. `UIScreen.main` is host-driven
(`_hostConfigure(bounds:scale:)` — openhost points it at the SDL surface it
really opens); `UIDevice.current` reports documented FIXED values, not
measurements. Gaps and the reasoning: docs/KNOWN_GAPS.md "App lifecycle /
environment".

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
  canon — EXCEPT for chrome Catalyst cannot host, which is measured on real
  iOS 26.1 in the headless Simulator instead: the pageSheet (`SimScene`,
  spec v5) and `UIAlertController` (`SimScene` + `Tools/oracle2/alertprobe`,
  spec v5.2). The two platforms genuinely disagree on some semantic colours —
  dark `systemBackground` is 0.1176 on Catalyst and pure black on iOS — so a
  sim-rendered dark scene must not paint with `systemBackground`.
- Behaviour that only exists live (scroll physics, sheet drags, the alert
  transition) is measured by dedicated Simulator probes that sample layer
  `presentation()` per display-link frame: `Tools/oracle2/simprobe`,
  `sheetprobe`, `alertprobe`.
- Some chrome cannot be CAPTURED by either oracle at all, only measured.
  `Tools/oracle2/menuprobe` (M13) is the first case: iOS 26 draws the UIMenu
  platter in the render server, so the probe reads the private view tree for
  geometry and the DEVICE FRAMEBUFFER (`xcrun simctl io screenshot`) for
  fill/shadow/corner, and the numbers are gated by unit tests instead of a
  fixture. When you meet chrome like this, measure it and say so — do not
  invent a golden. See docs/KNOWN_GAPS.md "Menus, actions & delegate
  protocols".

## openrender CLI contract (must mirror oracle exactly)

```
openrender render <outdir> <scene.json>...
```
Reads scene JSON per `docs/SCENE_SPEC.md`, builds OpenUIKit views, layouts,
writes `<name>.png` + `<name>.layout.json` in the same format as the oracle
(sorted keys, 3-decimal rounding, same intrinsic/sizeThatFits200 rules).
