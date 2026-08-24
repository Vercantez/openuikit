# Scene Specification v2

A **scene** is a JSON file describing a UIKit view hierarchy. Two renderers consume it:

- `Tools/oracle` — renders with **real UIKit** (Mac Catalyst, offscreen `layer.render`). Output goes to `golden/`. Scenes marked `"window": true` are instead rendered by `Tools/oracle2` (real `UIWindow` + `drawHierarchy`) — see below.
- `openrender` (this repo's `OpenUIKit`) — the portable reimplementation. Output goes to `out/`.

Each renderer produces, for scene `<name>`:
- `<name>.png` — RGBA PNG of the root view rendered at `scale` (pixel size = size × scale).
- `<name>.layout.json` — post-layout geometry dump (see below).

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
