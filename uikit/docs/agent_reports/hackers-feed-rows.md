# Hackers feed: row insets and missing toolbar gear

2026-09-07 — `agent/hackers-feed-rows`, base `a1bf3e22`.
Oracle: carried `goldens/ios/golden_realapp_ios/realapp_hackers_feed_light`
PNG and layout, iPhone 16 / iOS 26.1 (23B86), 393×852 pt, 1179×2556 px @3x.
No app source, golden, or pin changed.

## Result

| Measurement | Fresh baseline | After | Oracle |
|---|---:|---:|---:|
| `compare_realapp.py` score, straight alpha @3x | 85.536 FAIL | **94.662 FAIL** | bar 97.5 |
| MAE | 13.903 | **5.799** | 0 |
| Two-line row height (pt) | 129.333 | **127.333** | 127.333 |
| One-line row height (pt) | 109 | **107** | 107 |
| Seventh visible row y, list coordinates (pt) | 694.667 | **682.667** | 682.667 |
| Gear image alignment box, platter coordinates | blank SwiftUI view, 44×44 | **[8.333, 9, 27.333, 27]** | [8.333, 9, 27.333, 27] |

Score improvement: **+9.126 points**. Both requested causes are closed;
the screen is still below the bar because of the separately measured
SwiftUI content gaps below. The old focus-score value 86.311 was a guest
render with blank glyph misses; this branch compares the same native route
before and after, as focus-fidelity-tables did (85.536).

Official scorer output:

```text
before: realapp_hackers_feed_light: pixels ({'score': np.float64(85.536), 'mae': 13.903, 'blob': 150.2, 'blob_bbox': [118.3, 620.7, 13.7, 24.7], 'missing': {'area': 134.3, 'bbox': [287.3, 70.0, 23.0, 23.0], 'golden_std': 98.67, 'our_std': 0.24, 'ratio': 0.002}}, None)
after:  realapp_hackers_feed_light: pixels ({'score': np.float64(94.662), 'mae': 5.799, 'blob': 167.2, 'blob_bbox': [116.7, 410.0, 22.3, 19.3], 'missing': {'area': 55.8, 'bbox': [114.0, 155.7, 12.7, 9.0], 'golden_std': 116.01, 'our_std': 5.78, 'ratio': 0.05}}, None)
```

## 1. The extra 2 pt is the List's outer vertical padding

This feed does **not** use OpenUIKit's `UITableView` or its self-sizing
path. The unmodified `FeedView` builds a SwiftUI `List`; the port's
`Sources/SwiftUI/Hosting.swift:placeList` creates a `UIScrollView` and
explicitly sizes ordinary UIView row hosts. Changing UITableView would
not affect this screen.

The golden's `ListCollectionViewCell` and `CellHostingView` hide the
SwiftUI descendants. To distinguish label height from outer padding, the
scratch **HackersRowMetrics** app reproduces the DesignSystem stub's
column: 12 pt domain, 17 pt semibold headline, VStack spacing 6, pill row
padding-top 4, 12 pt pill text and 12×12 symbol frames, pill padding 6
vertical / 10 horizontal, thumbnail 55 and HStack gap 12. GeometryReader
background preferences record each component's global frame. The probe
and app use the same fonts and modifiers; app source was read-only.

Scratch source and captures: `/tmp/hackers-row-probe/`; private devices
`HackersRowMetrics-hackers-feed-rows` (iPhone 16 @3x) and
`OpenUIKit-2x-hackers-feed-rows` (SE 3rd gen @2x), both iOS 26.1.
No parameter search was performed.

| Probe frame/size | iPhone 16 @3x | SE @2x |
|---|---:|---:|
| Navigation bar bottom (window y) | 113 | 74 |
| First row content top | 128 | 89 |
| Domain line height | 14.333 | 14.5 |
| Two-line headline height | 40.667 | 41 |
| One-line headline height | 20.333 | 20.5 |
| Pill height, including 6+6 padding | 26.333 | 26.5 |
| Two-line column / row content height | 97.333 | 98 |
| One-line column / row content height | 77 | 77.5 |
| Next row content top | 255.333 | 217 |
| Derived two-line cell height | 127.333 | 128 |
| Outer inset, each end | **15** | **15** |

At 3x, 14.333 + 40.667 + 26.333 + 6 + 6 + 4 = 97.333.
The next content top minus the first is 127.333, leaving exactly 30 pt
outside the content; the measured leading 15 fixes the trailing 15.
The golden's 1 pt separator overlays the cell's final point. It adds no
row height. Horizontal inset stays 16. The old comment incorrectly
estimated the content as 95.333 / 75, then assigned 16+16 padding.

Rule: iOS plain/automatic List vertical insets **16 → 15**. Catalyst
retains its existing zero-inset path. All seven visible cell frames now
match the golden, including row y values
`0, 127.333, 234.333, 361.667, 468.667, 575.667, 682.667`.

## 2. The 23×23 region is gear ink, not a missing row accessory

The app source's `settingsButton` is a trailing ToolbarItem containing
`Label("Settings", systemImage: "gearshape").labelStyle(.iconOnly)
.font(.headline).foregroundStyle(.primary)`.

The fresh baseline corrects the earlier report's missing-entry diagnosis:
its layout already contains `_UIBarButtonItemView [277, 0, 44, 44]`,
with a `_SwiftUIHostingView` and `_SystemSymbolView` inside it. Toolbar
collection works. `_SystemSymbolView.drawContent` returns without drawing
for `gearshape`; the toolbar bridge explicitly admitted only the search
symbol to its native image route.

The golden has the gear's `PlatterView [277, 0, 44, 44]` and a
`UIImageView [2.333, 0, 27.333, 27]` inside the native button wrappers.
The scratch probe uses the same SwiftUI toolbar declaration and dumps
`UIImageView.preferredSymbolConfiguration` after window capture:

```text
textStyle=UICTFontTextStyleBody, weight=Medium, scale=Large
3x UIImage.size: 20.667×20; displayed alignment box: 27.333×27
3x gear alone: window [341.333, 68, 27.333, 27]
2x UIImage.size: 21×20; displayed alignment box: 27.5×27
2x gear alone: window [323, 28.5, 27.5, 27]
```

The solitary probe gear occupies the trailing-most platter. Adding the
search platter moves it left by 44+12=56, giving the feed's image window
frame `[285.333, 68, 27.333, 27]`. At 3x the existing harvested key
`gearshape|17|medium|large|F0` has an 82×81 alignment bitmap and 70×69 ink
crop at offset (6,6). That identifies the scorer's roughly 23×23 region
at `[287.3,70]` without inventing an icon.

Rules:

- SwiftUI's iOS toolbar bridge now creates a native UIImage bar item from
  the existing body/medium/large harvest, retaining the button action and
  isolated platter. Unsupported names and Catalyst keep the custom path.
- OpenUIKit's isolated symbol item keeps the measured **44 pt** platter;
  ordinary image-item padding would otherwise widen the gear to 49.333.
- OpenUIKit floors its horizontal centre to the device grid: 3x x 8.333,
  2x x 8. The existing vertical placement gives the requested 3x y 9.

The gear is no longer missing. Its ink tone is not pixel-exact: in the
fixed original 69×69 pixel region `[862:931,210:279]`, RGB MAE is
**76.889 → 10.956**. The SE's measured vertical image origin is 8.5 pt,
where the existing item layout still rounds to 9; that 2x residual was
not generalized into an unmeasured cross-scale baseline rule.

## Remaining wall (outside the two requested causes)

- Two-line rows still compress the pill backgrounds to **6 pt** and pill
  labels to **0 pt**, versus the probe's **26.333 / 14.333**. Their text
  column starts 10.167 pt too low even though the enclosing cell now has
  the right height. This is VStack/HStack placement, not row padding.
- In-row `safari`, `arrow.up`, `message`, and `bookmark` still use the
  blank generic SwiftUI symbol renderer. No caption/thumbnail symbol
  configurations were harvested or guessed here.
- The title menu still paints an empty platter despite its label in the
  tree. The headline's line break still differs (`...Hacker News / client`
  vs `...Hacker / News client`). The isolated native column is **294 pt**
  wide, the same as the port; the prior report's narrower-column inference
  is not supported by this probe. The text/wrapping cause remains open.

These samples are recorded in `scoreboard/open.txt`; no score-targeted
constants were introduced to push the screen over 97.5.

## Verification

- Failing first: `HackersFeedFidelityTests`, 3 tests, 4 assertions failed
  (129.333 vs 127.333, 109 vs 107, 16 vs 15, missing native gear image).
  Catalyst inset test passed before and after.
- After: `HackersFeedFidelityTests|SwiftUIDesignSystemTests|GlassMaterialTests`
  **37/37** passed. The older toolbar test now checks the native symbol
  image and preserved isolated platter instead of requiring a custom view.
- Catalyst: **124/124**.
- Real-app renders: **14/15 PNGs byte-identical** to baseline; the only
  changed PNG is Hackers feed. Every other scored screen therefore holds.
- Fresh iOS suite baseline: **112/113**, sole miss `corner_radius` 99.411.
- Final fresh iOS suite: **112/113**, the same sole `corner_radius`
  99.411 miss; **113/113 rendered PNGs byte-identical** to baseline.
- Linux `swift:6.2-noble` release build: **passed**, 207.18 s.
- `agent_merge.sh` CHECK_ONLY: pending after the measured commit.

The full real-app comparator prints all scored floors before encountering
its pre-existing browser layout `None` coordinate error / geometry mismatch.
The isolated Hackers comparison also runs cleanly by copying the unchanged
`realapp_hackers_feed_light*` goldens to `/tmp/golden-hackers-feed-rows`.
No golden bytes are altered.

## Reproduce

All commands below run from `uikit/` (the CHECK_ONLY script changes to the
monorepo root itself):

```sh
swift build -c release --product openrender
OPENUIKIT_REALAPP_SCALE=3 OPENUIKIT_FORCE_IOS=1 ./.build/release/openrender realapp /tmp/app-hackers-feed-rows
python3 Tools/compare/compare_realapp.py --golden goldens/ios/golden_realapp_ios --out /tmp/app-hackers-feed-rows --scale 3 --golden-straight-alpha
swift test --filter 'HackersFeedFidelityTests|SwiftUIDesignSystemTests|GlassMaterialTests'
SIM_DEVICE_SUFFIX=-hackers-feed-rows scripts/ios_suite.sh /tmp/suite-hackers-feed-rows
./.build/release/openrender render /tmp/gate-hackers-feed-rows fixtures/scenes/*.json
python3 Tools/compare/compare.py --out /tmp/gate-hackers-feed-rows
CHECK_ONLY=1 bash scripts/agent_merge.sh agent/hackers-feed-rows
```
