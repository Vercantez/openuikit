# Scene Specification v5.2

A **scene** is a JSON file describing a UIKit view hierarchy. Two renderers consume it:

- `Tools/oracle` — renders with **real UIKit** (Mac Catalyst, offscreen `layer.render`). Output goes to `golden/`. Scenes marked `"window": true` are instead rendered by `Tools/oracle2` (real `UIWindow` + `drawHierarchy`) — see below. Scenes with a top-level `"modal"` key are rendered by **real iOS UIKit in the headless iOS Simulator** (`scripts/render_sim_scenes.sh`, SimScene app) — Catalyst cannot produce the iOS pageSheet look (v5, see "Modal sheet").
- `openrender` (this repo's `OpenUIKit`) — the portable reimplementation. Output goes to `out/`.

Each renderer produces, for a **static** scene `<name>`:
- `<name>.png` — RGBA PNG of the root view rendered at `scale` (pixel size = size × scale).
- `<name>.layout.json` — post-layout geometry dump (see below).

A scene with top-level `"animations"` (v3) instead produces one PNG **per
capture time** plus one shared layout dump — see “Animations (v3)”.

`Tools/compare/compare.py` diffs the two directories and emits a per-scene report.

## Top level

```json
{
  "name": "boxes_nested",
  "size": [320, 240],
  "scale": 2,
  "style": "light",
  "root": { ...view... }
}
```

- `size`: logical point size of the root view. Root frame is `(0, 0, w, h)`.
- `scale`: render scale (default 2). PNG pixels = points × scale.
- `style`: `"light"` (default) or `"dark"`. Applied via `overrideUserInterfaceStyle`.
- `window` (optional, bool): `true` means the scene's golden **must be rendered
  by `Tools/oracle2`** — a Mac Catalyst app that hosts the hierarchy in a real
  `UIWindow` (scene lifecycle, app activated) and captures it with
  `drawHierarchy(afterScreenUpdates: true)`. Required for controls whose layers
  are drawn only by the render server and produce nothing through offscreen
  `layer.render(in:)` (e.g. the `UISwitch` thumb). Regenerate with
  `Tools/oracle2/run.sh render golden <scene.json>` (or `scripts/regen_goldens.sh`,
  which routes scenes to the right oracle automatically). Note the oracle2 app
  window flashes briefly on screen while rendering. openrender treats the key
  as documentation only — it renders every scene the same way. v2's compositing
  path shifts flat colors by 1–2 counts (max seen: 5) vs v1, well inside the
  pixel tolerance, but do not regenerate normal scenes with v2.

## View objects

Common keys (all optional unless noted):

| key | type | notes |
|---|---|---|
| `class` | string | required. One of the supported classes below. |
| `frame` | `[x,y,w,h]` | in superview coordinates (points). Default `[0,0,0,0]`. |
| `backgroundColor` | color | default nil (transparent). |
| `alpha` | number | 0–1. |
| `hidden` | bool | |
| `clipsToBounds` | bool | |
| `cornerRadius` | number | `layer.cornerRadius`. Applies to background & border. |
| `borderWidth` | number | `layer.borderWidth`. |
| `borderColor` | color | `layer.borderColor`. |
| `transform` | `[a,b,c,d,tx,ty]` | `CGAffineTransform`. Applied after frame is set (set frame first, then transform). |
| `shadowColor` | color | `layer.shadowColor`. Default black. |
| `shadowOpacity` | number | 0–1, `layer.shadowOpacity`. Default 0 (no shadow). |
| `shadowOffset` | `[w,h]` | `layer.shadowOffset`. Default `[0,-3]` (CALayer default). |
| `shadowRadius` | number | `layer.shadowRadius` (blur). Default 3. |

Shadow note: `masksToBounds` must be `false` for a shadow to be visible — do
not combine `clipsToBounds: true` with shadow keys on the same view (put the
clipping on a child instead). Also remember the root view's background is never
drawn (long-standing root-frame quirk — the root keeps frame `[0,0,0,0]`, see
the note in `Tools/oracle/SceneKit.swift`), so shadow scenes that want a
visible backdrop must add an explicit full-size background subview.
| `autoresizingMask` | array of strings | any of `"flexibleWidth"`, `"flexibleHeight"`, `"flexibleLeftMargin"`, `"flexibleRightMargin"`, `"flexibleTopMargin"`, `"flexibleBottomMargin"`. |
| `sizeToFit` | bool | call `sizeToFit()` after properties are set (origin preserved). |
| `userInteractionEnabled` | bool | `isUserInteractionEnabled` (v4). Default: UIKit's (true; false for UILabel/UIImageView). |
| `subviews` | array | child view objects, in order. |

### `UIView`
No extra keys.

### `UILabel`
| key | type | notes |
|---|---|---|
| `text` | string | |
| `fontSize` | number | default 17 |
| `fontWeight` | string | `ultraLight, thin, light, regular, medium, semibold, bold, heavy, black` (default `regular`) |
| `italic` | bool | uses `.italicSystemFont` (only valid with regular weight) |
| `monospaced` | bool | uses `.monospacedSystemFont(ofSize:weight:)` |
| `textColor` | color | default `label` |
| `textAlignment` | string | `left, center, right, natural, justified` |
| `numberOfLines` | int | default 1; 0 = unlimited |
| `lineBreakMode` | string | `wordWrap, charWrap, clip, truncateHead, truncateTail, truncateMiddle` |

### `UIImageView`
Images are synthesized (no asset files) from an `image` object:
```json
"image": { "kind": "checker", "size": [40, 40], "colors": ["#FF0000", "#0000FF"], "tile": 8 }
"image": { "kind": "gradient", "size": [40, 40], "colors": ["#FF0000", "#0000FF"], "direction": "vertical" }
"image": { "kind": "solid", "size": [40, 40], "colors": ["#00FF00"] }
```
| key | notes |
|---|---|
| `contentMode` | `scaleToFill, scaleAspectFit, scaleAspectFill, center, top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight, redraw` |

### `UIGradientView` (v2)
A `UIView` whose backing layer is a `CAGradientLayer` (the oracle implements it
as a tiny UIView subclass overriding `layerClass`, named exactly
`UIGradientView` so layout dumps agree). All common view keys apply.
| key | type | notes |
|---|---|---|
| `colors` | `[color, ...]` | required, ≥ 2 entries. Resolved against the scene style, then set as `CAGradientLayer.colors`. |
| `locations` | `[number, ...]` | optional, 0–1 each, one per color. Default nil (evenly spaced). |
| `startPoint` | `[x,y]` | unit coordinates. Default `[0.5, 0]`. |
| `endPoint` | `[x,y]` | unit coordinates. Default `[0.5, 1]`. |
| `gradientType` | string | only `"axial"` for now (the default). |

### `UIButton`
Plain style (`UIButton(type: .system)` legacy layout — no UIButtonConfiguration):
| key | notes |
|---|---|
| `title` | string |
| `fontSize`, `fontWeight` | applied to `titleLabel!.font` |
| `titleColor` | color; default = tintColor (systemBlue) |
| `enabled` | bool |
| `highlighted` | bool (v4). Sets `isHighlighted = true` — a plain .system button renders its title dimmed. |

### `UISwitch`
| key | notes |
|---|---|
| `on` | bool |
| `onTintColor` | color |
(frame width/height are ignored by UIKit — it is intrinsic 51×31)

### `UIProgressView`
| key | notes |
|---|---|
| `progress` | 0–1 |
| `progressTintColor`, `trackTintColor` | color |

### `UISlider` (v5.2 — app-compat cluster, requires `"window": true`)
The iOS 26 thumb is a `_UILiquidLensView` the render server draws, so slider
scenes must be captured by `Tools/oracle2` (the same rule `UISwitch`
follows); the track and the minimum-track fill would render offscreen.
| key | type | notes |
|---|---|---|
| `value` | number | default 0, clamped into the range. |
| `minimumValue` / `maximumValue` | number | default 0 / 1. |
| `minimumTrackTintColor` | color | default = tintColor (systemBlue). |
| `maximumTrackTintColor` | color | default = the measured translucent neutral. |
| `thumbTintColor` | color | default white. |
| `enabled` | bool | |

Measured metrics (Catalyst iOS 26, `control_slider`): `intrinsic` =
`(-1, 34)`; track 6 pt tall, full width, vertically centred, capsule;
thumb 37 x 24 capsule at `x = round(fraction × (width − 37))` (the thumb is
a subview, so its origin lands on UIKit's integer-point frame grid) with a
soft shadow; the minimum-track fill runs to the UNROUNDED thumb centre.

### `UISegmentedControl` (v5.2 — app-compat cluster, requires `"window": true`)
The selected pill is a `_UILiquidLensView` (render-server only); the
background and titles do render offscreen.
| key | type | notes |
|---|---|---|
| `segments` | `[string]` | segment titles, in order. |
| `selectedSegmentIndex` | int | default none. |
| `selectedSegmentTintColor` | color | default white (light) / (90,90,96) (dark). |
| `enabled` | bool | |

Measured metrics (`control_segmented`): capsule background
`tertiarySystemFill`; segments split the width with integer-floor
boundaries (280 / 3 → 93, 93, 94); the selected pill is the segment rect
inset 2 pt on every side, circular capsule; titles are 13 pt system,
REGULAR unselected and MEDIUM selected, centred with the origin rounded
half-up to the pixel grid. The layout dump carries NO `intrinsic` for this
class (see docs/KNOWN_GAPS.md).

### `UIActivityIndicatorView` (v5.2 — app-compat cluster)
Renders through the offscreen v1 oracle (no `"window"` needed): the spin
animation is discarded offscreen, so the golden pins the REST pose, which
is exactly what OpenUIKit draws at `animationTime == 0`.
| key | type | notes |
|---|---|---|
| `style` | string | `medium` (default, 20x20) or `large` (37x37). |
| `color` | color | default = the measured dynamic neutral gray. |
| `animating` | bool | default true (`startAnimating()`). |
| `hidesWhenStopped` | bool | default true. |

Eight capsule blades 45° apart with a fixed opacity ladder — full metrics
in `Sources/OpenUIKit/UIActivityIndicatorView.swift`.

### `UIPageControl` (v5.2 — app-compat cluster, requires `"window": true`)
| key | type | notes |
|---|---|---|
| `numberOfPages` | int | default 3. |
| `currentPage` | int | default 0. |
| `hidesForSinglePage` | bool | default false. |
| `pageIndicatorTintColor` | color | default white @ 45 %. |
| `currentPageIndicatorTintColor` | color | default opaque white. |

Careful when re-probing: with DEFAULT colors the control is invisible over a
white background (white at 45 % on white), which looks exactly like "the
oracle does not draw it" — probe over black/red instead (that is how the
defaults above were measured). Metrics: content box `18n + 20` wide, 26 tall,
centred in the bounds; dot slots are 10 pt wide on an 18 pt pitch starting
14 pt inside the content box and vertically centred, and the drawn dot is a
7.59 pt circle 0.19 pt left of / below its slot centre (fitted from the
golden's ink area and centroid).

### `UIScrollView` (v4.1 — M7.5)
A real scroll view; `contentOffset` IS the layer's bounds origin, so a static
scene verifies scrolled rendering (children shifted by −offset, clipped by the
scroll view's bounds) against real UIKit. All common view keys apply
(`clipsToBounds` defaults to **true** for scroll views in both renderers).
| key | type | notes |
|---|---|---|
| `contentSize` | `[w,h]` | `contentSize`. Default `[0,0]`. |
| `contentOffset` | `[x,y]` | applied AFTER frame/children (both renderers). May be out of range (renders the overscrolled state). |
| `contentInset` | `[top,left,bottom,right]` | `contentInset`. No visual effect on a static scene (it only changes the legal offset range). |

The oracle pins `contentInsetAdjustmentBehavior = .never` (no VC/safe-area
offscreen) and disables both indicators, so the layout dump carries no
private indicator subviews; OpenUIKit creates its indicator bars lazily on
first scroll, so static scenes match. Scroll physics (deceleration,
rubber-band, bounce) are unit-tested against the closed forms in
`UIScrollPhysics` and exercised live via openhost scripted captures —
oracle time-sampled traces come with M8.

### `UITextField` (v4.2 — M8 text input)
Static (unfocused) rendering only — no offscreen oracle can capture the
focused look (first responder requires a window/keyboard). Scenes cover the
empty+placeholder and with-text states.
| key | type | notes |
|---|---|---|
| `borderStyle` | string | `none` (default), `line`, `bezel`, `roundedRect`. Fixtures use `roundedRect`. |
| `text` | string | Non-editing overflow truncates the tail with an ellipsis, like UILabel. |
| `placeholder` | string | drawn in `placeholderText` when `text` is empty. |
| `fontSize`, `fontWeight` | | default system 17 regular. |
| `textColor` | color | default `label`. |

The layout dump carries `intrinsic` for text fields (roundedRect =
`(ceil(textWidth) + 28, 34)`; placeholder widths ceil to the pixel grid).
Both renderers keep their private internal subviews out of the structural
comparison (compare.py PUBLIC_CLASSES).

### `UITextView` (v4.2 — M8 text input)
A UIScrollView subclass. Multiline wrapped text: container inset (8, 0, 8, 0),
line-fragment padding 5, line height = the font's integer UIFont.lineHeight.
The oracle pins `contentInsetAdjustmentBehavior = .never` and hides both
indicators (same rule as UIScrollView).
| key | type | notes |
|---|---|---|
| `text` | string | |
| `fontSize`, `fontWeight` | | default system 17 regular (always applied — real UITextView's nil-font 12 pt legacy default is not exercised). |
| `textColor` | color | default `label`. |

### `UITableView` (v5 — M10 chrome)
A real `UITableView` with an in-scene data source (no reuse — every cell is
built fresh; the driver object is retained for the process lifetime). Modern
cell chrome: cells use `UIListContentConfiguration` via
`defaultContentConfiguration()` (adapts to the init style). The oracle pins
`contentInsetAdjustmentBehavior = .never`, hides both indicators (same rule
as UIScrollView) and pins `traitOverrides.horizontalSizeClass = .compact`
(iPhone metrics — the Catalyst idiom is .pad). `contentOffset` works (the
generic UIScrollView post-frame path applies — UITableView is a scroll view).

| key | type | notes |
|---|---|---|
| `style` | string | `plain` (default) or `insetGrouped`. |
| `sections` | array | `[{"header": str?, "footer": str?, "rows": [...]}]` |

Row object keys:

| key | type | notes |
|---|---|---|
| `style` | string | `default` (default), `subtitle`, `value1` — the `UITableViewCell.CellStyle` the cell is created with. |
| `text` | string | primary text. |
| `detailText` | string | secondary text (subtitle below / value1 right-aligned). |
| `accessory` | string | `none` (default), `disclosureIndicator`, `checkmark`. |
| `selected` | bool | `true` renders the row's selection highlight (`setSelected` in `willDisplay`). |

Layout dumps include the private cell tree (`UITableViewCell`,
`UITableViewHeaderFooterView`, separators, …) — compare.py skips those
subtrees; only the `UITableView` frame is compared structurally. Light
scenes render via the offscreen v1 oracle. Dark table scenes MUST be
`"window": true` (offscreen dynamic-color resolution is light-only), and
windowed table scenes must NOT touch the scene's top edge — a scroll view
flush against the window top gets iOS 26's scroll-edge-effect pocket, which
blurs/swallows the first section header (verified; inset the table ≥ ~40 pt,
see `tableview_dark`).

Key oracle-measured metrics (Catalyst iOS 26, compact, scale 2 — see the
`tableview_*` goldens/dumps for the full details):
- Plain: cell height **51.5 pt**; cell label x=16, y=15.5, 17 pt regular;
  section header height **40.5 pt** (label 17 pt semibold at x=8, y=10,
  ~#858585 on white), first header preceded by **22 pt**
  `sectionHeaderTopPadding`; separator **1 pt** thick, inset 16 left /
  8 right, #E6E6E6 on white.
- insetGrouped: card side inset **9 pt** (wrapper 8 + background 1), card
  corner radius ≈ 26 pt (iOS 26); default/value1 cell height 51.5 pt,
  subtitle cell height **70.5 pt** (secondary label at y=36, height 19);
  value1 detail right-aligned to 16 pt margin, secondaryLabel; header
  40.5 pt / 17 pt semibold (NOT uppercased on iOS 26); footer height 30,
  13 pt footnote.
- Selection highlight: full-bleed row **#DCDCDC** (light).
- Accessories: disclosure chevron 10.5×14 pt at right margin 16 (gray);
  checkmark 19×18 pt (tint blue, measured (0,136,255) light).

### `UINavigationStack` (v5 — M10 chrome, root-only, requires `"window": true`)
A real `UINavigationController` (one content VC hosting a full-size
`UIScrollView` with the scene `subviews` as content), added as a CHILD view
controller of the oracle2 host VC (`prefersLargeTitles`,
`largeTitleDisplayMode .always` when `largeTitle`, explicit
`setContentScrollView(_, for: .top)` binding). The container view is a
UIView subclass named `UINavigationStack` (dump class matches); the
controller view below it is private and skipped by compare.py.
`traitOverrides.horizontalSizeClass = .compact` for iPhone bar metrics.

| key | type | notes |
|---|---|---|
| `title` | string | `navigationItem.title`. |
| `largeTitle` | bool | `prefersLargeTitles` + display mode `.always`. |
| `contentSize` | `[w,h]` | the content scroll view's contentSize. |
| `contentOffset` | `[x,y]` | applied LIVE post-attach (the bar only tracks observed offsets). Omit for the expanded rest state — the oracle nudges the offset once to engage the expanded large-title layout (Catalyst never engages it spontaneously), then settles at the new rest offset. |
| `subviews` | array | children of the content scroll view (NOT of the stack view). |

**Root-frame quirk exemption** (like constraint scenes): a root
`UINavigationStack`/`UITabBarStack` gets the REAL `[0, 0, w, h]` frame —
dumps carry it, and openrender must mirror.

Oracle-measured metrics (Catalyst iOS 26, compact width, no safe-area top,
375 pt wide — `navbar_large`/`navbar_inline`/`navbar_dark` goldens):
- iOS 26 bars are TRANSPARENT at rest (no material until content scrolls
  under; then the scroll-edge effect provides a progressive blur).
- Expanded: `adjustedContentInset.top` = **116 pt** = 10 (top padding) +
  54 (inline bar zone) + 52 (large-title zone). Large title: 34 pt bold at
  x=20 (label frame `[20, 3, w, 40.5]` inside the 52 pt zone, i.e. glyphs
  ~y 67–107.5 in scene space); the inline centered title is alpha 0.
- Collapsed (`contentOffset` y past the reveal): inline bar zone 10..64
  (**54 pt** bar at y=10), centered 17 pt semibold title (label height 21 at
  bar-local y 11.5); large title alpha 0; scroll-edge-effect blur pocket
  over the content behind the bar region.

### `UITabBarStack` (v5 — M10 chrome, root-only, requires `"window": true`)
A real `UITabBarController` child VC; items get titles + synthesized
TEMPLATE images (the standard scene-spec `image` object, rendered
`.alwaysTemplate` — SF Symbols are not portable). Selected tab's `content`
view (if any) fills that tab's VC view. Catalyst leaves the fully laid-out
`UITabBar` hidden+alpha 0 (it expects NSToolbar hosting, which oracle2
suppresses); the oracle reveals it post-attach (`isHidden = false`,
`alpha = 1`). Compact width override → bottom (iPhone) bar.

| key | type | notes |
|---|---|---|
| `items` | array | `[{"title": str, "image": {…}?, "content": {view}?}]` (≤ 5). |
| `selectedIndex` | int | default 0. |
| `tintColor` | color | `tabBar.tintColor` (selected item color). |

Oracle-measured metrics (iOS 26 liquid-glass floating bar, 375×480 scene):
- Bar group region: bottom **72 pt** (y 408–480); floating platter
  `[51, 408, 274, 62]` (10 pt bottom margin), near-white glass
  (≈#FDFDFE) with soft shadow.
- Selected item: capsule highlight ≈#EBEBEC behind icon+title, tinted
  (default tint measured (52,124,238); `tintColor` respected — see
  `tabbar_tinted` systemPink).
- Unselected items: near-black (≈#191919) icon+title; item titles ~10 pt.

### Modal sheet (v5 — M10 chrome): top-level `"modal"` key

```json
"modal": { "style": "pageSheet", "grabber": false, "content": { ...view object... } }
```

`"grabber"` (v5.1 — M11, optional, default `false`) sets
`sheetPresentationController.prefersGrabberVisible`. UIKit's own default is
false, which is why `modal_sheet` carries no grabber and
`modal_sheet_grabber` does.

Presents a REAL `.pageSheet` over the scene root (the base screen) and
captures the WHOLE WINDOW after presenting without animation. Catalyst
bridges pageSheet into an AppKit sheet window (`_UIBridgedPresentationWindow`)
whose Mac chrome is composited outside UIKit — NOT the iOS look — so modal
scenes are rendered by real iOS UIKit in the headless iOS Simulator
(`scripts/render_sim_scenes.sh`; `scripts/regen_goldens.sh` routes them
automatically). Requirements: `"window": true`, scene size = the simulator
device's portrait size (iPhone 16: **393 × 852**). The capture is the app
window only — no status bar (SpringBoard overlay). The `content` view fills
the presented VC's view (autoresized); the sheet content area is NOT part of
the layout dump (pixels validate it).

Oracle-measured metrics (real iOS 26, iPhone 16): dimming = black at
**20 %** over the base (white base → #CCCCCC); sheet top edge at
**59 pt**, full width, continuous rounded top corners (left-edge white reach
per Δy from the top edge: 5 pt → 9.25, 10 pt → 6, 15 pt → 3.75,
20 pt → 2.25, 25 pt → 1.25, 30 pt → 0.75, 35 pt → 0.5 — ≈ 24 pt
continuous-corner fit); the base view controller is pushed back (scaled)
behind the dimming.

The top inset was **59.5** in M10 (a fit to the golden's edge profile); M11's
`sheetprobe` reads the live frame off real iOS as `(0, 59, 393, 793)`, and
adopting 59 improved both modal scenes by ~0.09 points. The grabber is
36 × 5 pt with corner radius 2.5, its top edge 5 pt below the sheet's, centred
at x 178.5 (no rounding), filled with systemFill's base gray at alpha 0.4295 —
(197, 197, 200) over a white sheet. Full interaction measurements:
docs/APP_FEEL.md "Measured sheet interaction".

### `UIStackView`
| key | notes |
|---|---|
| `axis` | `horizontal, vertical` |
| `spacing` | number |
| `stackDistribution` | `fill, fillEqually, fillProportionally, equalSpacing, equalCentering` |
| `stackAlignment` | `fill, leading, trailing, center, top, bottom, firstBaseline, lastBaseline` |
Children are `arrangedSubviews` (added in order). The stack view itself gets an explicit `frame`.

## Animations (v3)

Two additional top-level keys turn a scene into a multi-frame **animation
scene**:

```json
{
  "name": "anim_fade",
  "size": [200, 200],
  "scale": 2,
  "window": true,
  "root": { ... },
  "animations": [
    {
      "target": "1",
      "kind": "uiview-animate",
      "duration": 1.0,
      "delay": 0.0,
      "curve": "linear",
      "changes": { "alpha": 0.0 }
    }
  ],
  "captureTimes": [0.0, 0.25, 0.5, 0.75, 1.0]
}
```

### `animations` — array of animation entries

Each entry describes ONE `UIView.animate` call (kind `"uiview-animate"`) or
one `UISwitch.setOn(_:animated: true)` call (kind `"switch-setOn"`, v4 —
see below):

| key | type | notes |
|---|---|---|
| `target` | string | required. Dot-joined subview-index path from root (`"0.1"`; `""` = root), same addressing as layout-dump `path`. |
| `kind` | string | `"uiview-animate"` (default) or `"switch-setOn"`. |
| `duration` | number | seconds. Default 0.25. |
| `delay` | number | seconds before the animation starts. Default 0. During the delay the view shows the FROM state (UIKit fills backwards). |
| `curve` | string | `linear`, `easeIn`, `easeOut`, `easeInOut` (default `easeInOut`). Mutually exclusive with `spring`. |
| `spring` | object | `{"damping": d, "initialVelocity": v}` → `UIView.animate(withDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:)`. `damping` is the UIKit damping ratio (1 = no overshoot), `initialVelocity` in UIKit's normalized units. |
| `changes` | object | required, non-empty. Property → target value, applied INSIDE the animation block. |

Animatable properties in `changes` (all use the normal scene-spec value
encodings; colors are resolved eagerly against the scene `style`):

| property | value | applied as |
|---|---|---|
| `frame` | `[x,y,w,h]` | `view.frame = …` |
| `center` | `[x,y]` | `view.center = …` |
| `bounds` | `[x,y,w,h]` | `view.bounds = …` |
| `alpha` | number | `view.alpha = …` |
| `backgroundColor` | color | `view.backgroundColor = …` |
| `transform` | `[a,b,c,d,tx,ty]` | `view.transform = …` |
| `cornerRadius` | number | `view.layer.cornerRadius = …` (UIView-animatable since iOS 11) |

Multiple entries are allowed and run CONCURRENTLY (all started before the
first capture). Entries targeting the **same** view must share one `delay`
(the oracle realizes delay by shifting that layer's timeline — see below);
put differently-delayed animations on different views.

### `captureTimes` — array of seconds

Absolute times measured from animation start (t = 0 is the moment the
`UIView.animate` calls commit — i.e. the FROM state for every non-delayed
animation). Times at or beyond `delay + duration` show the settled TO state.
Required when `animations` is present. Keep values at whole milliseconds.

### Outputs

For each capture time `t` the renderer writes
`<name>.t<ms>.png` where `<ms>` is `round(t*1000)` zero-padded to at least
3 digits: `0.08 → anim_x.t080.png`, `0.5 → anim_x.t500.png`,
`1.0 → anim_x.t1000.png`. There is **one** shared `<name>.layout.json` —
the pre-animation (t = 0 model) layout; layout comparison happens only there.
No plain `<name>.png` is written for animation scenes.

### Oracle capture mechanism (deterministic — no wall-clock sampling)

Animation scenes MUST set `"window": true`: Core Animation **discards**
animations attached to layers that have no render context (verified:
`animationKeys()` empties on `CATransaction.flush()` and `presentation()`
stays nil offscreen), so the offscreen v1 oracle cannot capture them —
`Tools/oracle` refuses such scenes. `Tools/oracle2` renders them:

1. The scene wrapper's layer clock is FROZEN before anything commits:
   `wrapper.layer.speed = 0; wrapper.layer.timeOffset = 0`. Every
   descendant's local time is then pinned to `wrapper.layer.timeOffset`
   (`local = (parent − begin) × speed + timeOffset`), so
   `CACurrentMediaTime()` cancels out of all timing math entirely — two runs
   produce byte-identical frames.
2. The real `UIView.animate(withDuration:delay:…)` /
   `usingSpringWithDamping:` call is made with the JSON's `changes`. At
   commit, UIKit resolves the CAAnimation's `beginTime` via
   `convertTime(now + delay)`; under the frozen ancestor every media time
   converts to the frozen constant 0, which lands the animation exactly on
   the seek timeline `[0, duration]` — but also annihilates `delay`. The
   oracle reintroduces the delay deterministically by shifting the TARGET
   layer's own timeline (`layer.beginTime = delay`, `layer.fillMode = .both`
   so the layer still displays its FROM state before its begin time). Net:
   the animation is active over `[delay, delay + duration]` on the seek
   timeline with real UIKit fill semantics.
3. For each capture time `t` (in order): `wrapper.layer.timeOffset = t`,
   then `drawHierarchy(afterScreenUpdates: true)` — the seek is committed
   and the render server composites the presentation tree at frozen time
   `t` before capture. With `speed = 0` the completion/removal never fires,
   so `t ≥ delay + duration` renders the model (TO) values.

Validated: a 1 s linear alpha fade samples exactly 0.75/0.5/0.25 at
t = 0.25/0.5/0.75; easeIn starts slow, easeOut fast; spring
(damping 0.35/0.6) visibly overshoots the target and settles; delayed
animations hold the FROM state through the delay. Byte-identical across
runs for the full 10-scene fixture set.

### `switch-setOn` animation kind (v4)

```json
"animations": [ { "kind": "switch-setOn", "target": "1", "on": true } ]
```

The oracle calls the REAL `UISwitch.setOn(_:animated: true)`; openrender
calls OpenUIKit's. `on` (bool) is required; `duration`/`delay`/`curve`
keys are not accepted (the switch supplies its own timing). Cannot be
mixed with `uiview-animate` entries in one scene, and `t = 0` must not be
a capture time (the first wall-clock frame races the animation commit).

Capture mechanism differs from uiview-animate — the frozen seek CANNOT
capture this control (probed on Catalyst iOS 26.1):

- The blue "well" slide is a real CASpringAnimation — critically damped,
  duration-fit satisfying UIKit's ω·D = 9.2334 settling equation
  (off→on ωn = 9.2400 / D = 0.99947; on→off ωn = 15.7080 / D = 0.58792) —
  but its beginTime comes from `CACurrentMediaTime()` unconverted, and
- the THUMB is a display-link-driven `_UILiquidLensView` with no
  CAAnimation at all: under a frozen layer clock it crawls on wall time
  and ignores the seek,
- and UIKit applies `setOn(animated: true)` WITHOUT animation for a
  hierarchy that has never been displayed.

oracle2 therefore renders these scenes on the WALL clock: settle the
window 0.3 s, call setOn, snapshot as the elapsed media time crosses each
capture time. Frames carry a few ms of scheduling jitter (NOT
byte-deterministic like the frozen path); the control threshold absorbs
it. OpenUIKit reproduces the toggle with the probed well springs (local
coverage linear in spring progress, per-side offsets — blue enters at the
left end first turning on, leaves the right end first turning off) and a
golden-fitted thumb bezier (0.160, 0.004)-(0.406, 1.192) over 0.336 s
(see UISwitch.swift).

### Comparison (compare.py)

An animation scene compares EVERY captured frame with the scene's normal
category threshold (an animating label scene is still `text`, plain boxes
are `geometry`, …). Layout is compared once (t = 0). The scene passes iff
layout passes and **all** frames pass; the report lists per-frame scores and
the scene's headline score is the worst frame. Diff heatmaps land in
`out/diffs/<name>.t<ms>.diff.png`. As `"window": true` scenes, animation
goldens are decoded as premultiplied (the oracle2 rule above).

## Hit tests (v4)

An optional top-level `"hitTests": [[x, y], ...]` array of probe points in
ROOT coordinates. Each point is hit-tested against real UIKit's
`UIView.hitTest(_:with:)` semantics and the results are appended to the
layout dump:

```json
"hitTests": [
  { "point": [310, 275], "path": "3.0.2" },
  { "point": [30, 75],   "path": null }
]
```

- `path` is the dot-joined subview-index path (layout-dump addressing) of
  the hit view, or `null` on a miss.
- Results are NORMALIZED to the nearest scene-defined ancestor: when UIKit
  returns a private implementation subview (UISwitch internals,
  `UIButtonLabel`, ...), the dumped path is the nearest view that exists in
  the scene JSON, so both renderers report comparable paths.
- The root container keeps the degenerate `(0,0,0,0)` frame (root-frame
  quirk), so the driver runs UIKit's hit-test recursion step at the root
  itself (reverse subview order, converted point, first hit wins);
  consequence: the ROOT view is never a hit result — probes that hit
  nothing dump `null`. Keep probe points within the scene size.
- compare.py checks probe-by-probe EXACT path equality (a mismatch is a
  layout failure).

Oracle-verified semantics reproduced by OpenUIKit (fixtures/scenes/
hit_testing.json): reverse-subview-order (front-to-back) search; transforms
applied about the view center; `isHidden`, `alpha < 0.01` and
`isUserInteractionEnabled == false` each prune their whole subtree;
`point(inside:)` is min-edge inclusive / max-edge exclusive; a subview
region OUTSIDE its parent's bounds is unreachable regardless of
`clipsToBounds` (the recursion tests `point(inside:)` on every ancestor);
UILabel / UIImageView default to interaction disabled (touches fall
through to their superview).

## Constraints (v4.3 — M9 Auto Layout)

An optional top-level `"constraints"` array activates REAL
`NSLayoutConstraint`s in the oracle (OpenUIKit must solve to the same frames).
Golden = real UIKit's solver output via the normal layout dump; constraint
solving works offscreen (proved for stack views in M3, re-verified for plain
constraints — no window needed for `layoutIfNeeded`).

```json
"constraints": [
  { "item": "0", "attribute": "leading", "toItem": "", "constant": 16 },
  { "item": "0", "attribute": "width", "relation": "ge", "toItem": null, "constant": 80 },
  { "item": "1", "attribute": "top", "toItem": "0", "toAttribute": "bottom",
    "multiplier": 1, "constant": 12, "priority": 750 }
]
```

Constraint entry keys:

| key | type | notes |
|---|---|---|
| `item` | string | required. Dot-joined subview-index path (layout-dump addressing); `""` = root. |
| `attribute` | string | required. One of `left, right, top, bottom, leading, trailing, width, height, centerX, centerY, firstBaseline, lastBaseline`. |
| `relation` | string | `eq` (default), `le`, `ge`. |
| `toItem` | string or null | second item's path; null/omitted = unary (sizes). |
| `toAttribute` | string | second attribute. Defaults to `attribute` when `toItem` is present; invalid without `toItem`. |
| `multiplier` | number | default 1. |
| `constant` | number | default 0. |
| `priority` | number | default 1000 (required). Set BEFORE activation. |

Per-view keys (any view class):

| key | type | notes |
|---|---|---|
| `useConstraints` | bool | `true` sets `translatesAutoresizingMaskIntoConstraints = false`. Such views may omit `frame` entirely. |
| `huggingH` / `huggingV` | number | `setContentHuggingPriority(_:for:)` horizontal / vertical (UIKit default 250 for most views, 251 label vertical). |
| `compressionH` / `compressionV` | number | `setContentCompressionResistancePriority(_:for:)` (default 750). |

Frame-based siblings mix freely with constraint views: a view without
`useConstraints` keeps `translates... = true`, its frame becomes autoresizing
constraints, and constraint views may reference its edges (see
`constraints_mixed_frames.json`). Constraint views may also be children of a
frame-based parent.

**Root-frame quirk exemption**: the PRESENCE of the top-level `"constraints"`
key (even `[]`) gives the root its REAL frame `[0, 0, w, h]` — constraints
pinning to a 0-sized root would be useless. Consequences, which openrender
must mirror: constraint-scene layout dumps have root frame `[0, 0, w, h]`
(not `[0,0,0,0]`), and the root's `backgroundColor` DRAWS. All pre-v4.3
scenes lack the key, so no old golden changes.

**Solver rounding (oracle-observed, offscreen Catalyst iOS 26.1, scale 2)** —
UIKit does NOT dump raw solver reals; each constraint-positioned view's frame
is rounded, and OpenUIKit must reproduce this to hold the 0.5 pt layout
tolerance on adversarial fixtures:

- **Origin components round to the nearest integer POINT**, ties away from
  zero — not to the pixel (0.5) grid, despite scale 2: exact x 113.333 → 113,
  214.667 → 215, 47.5 → 48, 117.5 → 118, 219.5 → 220.
- **Size components round to the nearest 0.5 pt (pixel at 2x)**: exact width
  93.333 → 93.5, 190.667 → 190.5, 106.656 → 106.5. Sub-point constants
  survive when on-grid (a 0.5-pt separator height stays 0.5).
- Rounding is per-view in LOCAL (superview) coordinates, not window space: a
  constraint child of a frame-based parent at x = 199.5 keeps its exact local
  frame.
- Rounding happens per view AFTER solving, so required relations can end up
  visibly off-grid: in `constraints_chain` the trailing pin lands at
  308.5 with constant −12 on a 320-wide root (exact 308), and equal-width
  chains keep EQUAL rounded widths (3 × 93.5) rather than distributing the
  error.
- A hairline pinned flush to the bottom edge (exact y 55.5) rounds to y 56 —
  pushed entirely OUT of the scene. Fixtures that want a visible hairline
  must keep the exact origin on the integer grid (`constraints_form_row`
  pins `bottom` at −0.5 with height 0.5 → y 55).
- Views with intrinsic-size text keep their pixel-grid intrinsic widths
  (…​.5 values) — those are already on the size grid.

Fixture family `constraints_*` (12 scenes): edge pins, center+size,
leading/trailing chains (equal + 2× multiplied widths), aspect multipliers,
inequalities with competing priorities, hugging battle (251 vs 250, both
orders), compression battle (750 vs 749, both orders, plus a `le` width
squeeze), mixed frame/constraint siblings + constraint child in frame parent,
centerX/centerY with multiplier ≠ 1, first/last baseline alignment across
font sizes, nested constraint containers (3 levels), realistic form row
(fixed icon, flexible label, hugging value, 0.5-pt separator).

## Colors

A color is a JSON string, one of:
- `"#RRGGBB"` or `"#RRGGBBAA"` (sRGB)
- `"rgba(r,g,b,a)"` — components 0–1, sRGB
- `"clear"`, `"black"`, `"white"`
- A UIKit semantic/system name, resolved through the scene's `style`:
  `systemRed, systemOrange, systemYellow, systemGreen, systemMint, systemTeal, systemCyan, systemBlue, systemIndigo, systemPurple, systemPink, systemBrown, systemGray, systemGray2..systemGray6, label, secondaryLabel, tertiaryLabel, quaternaryLabel, systemBackground, secondarySystemBackground, tertiarySystemBackground, systemGroupedBackground, secondarySystemGroupedBackground, tertiarySystemGroupedBackground, separator, opaqueSeparator, link, placeholderText, systemFill, secondarySystemFill, tertiarySystemFill, quaternarySystemFill, tintColor`

Exact resolved sRGB values for both styles are dumped by the oracle into `golden/system_colors.json`; OpenUIKit must be data-driven from a vendored copy of that table (`Sources/OpenUIKit/Resources/system_colors.json`).

## Layout dump

`<name>.layout.json`:
```json
{
  "name": "boxes_nested",
  "views": [
    { "path": "", "class": "UIView", "frame": [0,0,320,240] },
    { "path": "0", "class": "UIView", "frame": [20,20,100,60] },
    { "path": "0.1", "class": "UILabel", "frame": [4,2,60,20.5],
      "intrinsic": [60, 20.5], "sizeThatFits200": [60, 20.5] }
  ]
}
```
- `path`: dot-joined subview indices from root (root = `""`).
- `frame`: post-`layoutIfNeeded` frame in superview coordinates, values rounded to 3 decimals.
- `intrinsic`: `intrinsicContentSize` for UILabel/UIButton/UISwitch/UIImageView/UIProgressView (`-1` for UIView.noIntrinsicMetric).
- `sizeThatFits200`: `sizeThatFits(CGSize(width: 200, height: .greatestFiniteMagnitude))` for labels & buttons.

## Comparison thresholds (compare.py)

- **Layout**: every frame component must match within **0.5 pt** (hard fail otherwise). Intrinsic sizes within 0.5 pt.
- **Pixels**: both images are composited over white (each decoded with its own
  alpha encoding) and the per-pixel delta is the max over the composited RGB
  channels and the raw alpha channel; delta ≤ 6 counts as matching. Score =
  % matching pixels.
  - Alpha encodings: openrender and `Tools/oracle` goldens use straight
    (unassociated) alpha — the PNG norm. `Tools/oracle2` goldens
    (`"window": true` scenes; `drawHierarchy` → `UIImage.pngData`) carry
    **premultiplied** RGB in semi-transparent regions, so compare.py decodes
    a golden as premultiplied exactly when the scene sets `"window": true`.
    Comparing raw channels would report huge RGB deltas at low alpha even
    when the renders agree (regression test: `Tools/compare/test_compare.py`).
  - Geometry-only scenes (no text/controls): pass ≥ 99.5%
  - Effects scenes (geometry-only scenes that use shadows): pass ≥ 98% —
    shadows are large blurry regions, so small blur differences touch many pixels.
  - Text scenes: pass ≥ 97%
  - Control scenes (button/switch/progress): pass ≥ 96%
  - Chrome scenes (v5: any UITableView / UINavigationStack / UITabBarStack,
    or a top-level "modal"): pass ≥ 95% — system-drawn material (glass
    platters, edge-effect gradients, sheet shadows) covers large regions.
    Chrome outranks the other categories.
  - Category rule for v2 features: shadows and gradients do **not** change a
    scene's category by themselves — a gradient-only scene is `geometry`, a
    shadow scene with no text/controls is `effects`, and a scene that also
    contains text or controls keeps its `text`/`control` category (and threshold).
- **Structural gate** (below): a hard, category-independent cap on how large a
  single contiguous *wrong* region may be. A scene passes only if layout
  passes AND the percentage passes AND the structural gate passes.
- Report also includes mean absolute error, the largest severe-diff component
  (`blob`, in pt²) and a diff heatmap PNG per failing scene in `out/diffs/`
  (red = delta magnitude, dim green = matching, blue = the severe mask the
  structural gate runs on).

## Structural diff gate (compare.py)

A percentage threshold is blind to a *small* region being *completely* wrong
on a large canvas. This is not hypothetical: during the Linux portability run
(docs/PORTABILITY.md) `navbar_large` scored **99.5 %** — comfortably over its
95 % chrome threshold — while visibly rendering "Library" as "Li rar". The two
missing 34 pt glyphs were 0.3 % of the pixels, so the score never noticed.

The gate closes that hole and is independent of the score:

1. Build the **severe mask**: pixels whose delta exceeds `STRUCT_DELTA` = **150**
   counts. That is 25× the 6-count match tolerance — far above any
   antialiasing, gamma, blend-calibration or alpha-encoding residual, and
   comfortably below the contrast of real content against its background.
2. Label its **8-connected components** (union-find over the sparse
   coordinate list — the tool stays on numpy + Pillow, no scipy).
3. Fail the frame if the largest component exceeds `STRUCT_MAX_BLOB` =
   **80 pt²**, measured in POINTS² (device pixels ÷ scale²), so the gate means
   the same physical size at 1×, 2× and 3×.

For animation scenes every captured frame is gated, like the percentage.

### Calibration (2026-08-25, all 80 scenes / 134 frames)

| case | largest severe component | verdict |
|---|---|---|
| worst legitimate residual — `modal_sheet`, one stem of the 22 pt bold title (window-mode glyph rasterization) | **33.2 pt²** | passes, 2.4× under the gate |
| next legitimate — `stack_alignment` / `constraints_baseline` | 20.0 / 16.5 pt² | passes |
| **two 34 pt glyphs deleted** from `navbar_large` (the historical bug) | **248.8 pt²** | **FAILS** |
| a `UISwitch` shifted 3 pt | 268.2 pt² | **FAILS** |
| a rounded rect shifted 3 pt (`corner_radius`) | 236.0 pt² | **FAILS** |
| a 17 pt label shifted 3 pt (`demo_settings`) | 90.2 pt² | **FAILS** |

80 pt² sits 2.4× above the worst legitimate residual and 3.1× below the
smallest corruption it must catch. Deliberately-corrupted renders are not
checked in; regenerate them from the recipes above, or run the synthetic
end-to-end assertions in `Tools/compare/test_compare.py`, which build a
canvas that scores > 99.6 % with one solid 12×12 pt patch wrong and assert
the gate rejects it.

### What it does NOT catch (honest)

A **small** view shifted a few points inside a scene whose internals are
private on both sides. `navbar_large` with a 17 pt shelf label moved 3 pt
scores 99.27 % with a largest component of 17 pt², and the layout dump cannot
see it either, because `UINavigationStack` internals are excluded from
`PUBLIC_CLASSES`. Everywhere else a 3 pt shift is a hard layout failure
(frames must match within 0.5 pt), so the two gates together cover it — but
inside chrome subtrees there is still a gap. Closing it needs either the
chrome containers to publish their internal frames, or a per-region score
(which was measured and rejected: local severe-diff density does not separate
`modal_sheet`'s legitimate title residual from a genuinely shifted label).
