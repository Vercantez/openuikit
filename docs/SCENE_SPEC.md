# Scene Specification v4

A **scene** is a JSON file describing a UIKit view hierarchy. Two renderers consume it:

- `Tools/oracle` — renders with **real UIKit** (Mac Catalyst, offscreen `layer.render`). Output goes to `golden/`. Scenes marked `"window": true` are instead rendered by `Tools/oracle2` (real `UIWindow` + `drawHierarchy`) — see below.
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
  - Category rule for v2 features: shadows and gradients do **not** change a
    scene's category by themselves — a gradient-only scene is `geometry`, a
    shadow scene with no text/controls is `effects`, and a scene that also
    contains text or controls keeps its `text`/`control` category (and threshold).
- Report also includes mean absolute error and a diff heatmap PNG per failing scene in `out/diffs/`.
