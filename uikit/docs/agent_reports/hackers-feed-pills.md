# Hackers feed: preserve a compressed column's measured height

2026-09-07 — `agent/hackers-feed-pills`.
Oracle: iPhone 16 / iOS 26.1 (23B86), 393×852 pt, 1179×2556 px @3x.
Starting point: [hackers-feed-rows](hackers-feed-rows.md).
No app source, golden, or pin changed.

## Result

| Measurement | Before | After | Real iOS |
|---|---:|---:|---:|
| `realapp_hackers_feed_light` score, straight alpha @3x | 94.662 | **98.235** | bar 97.5 |
| RGB MAE | 5.799 | **2.017** | 0 |
| Two-line column window y (pt) | 138.167 | **128** | 128 |
| Two-line column height (pt) | 77 | **97.333** | 97.333 |
| Two-line pill window y (pt) | 209.167 | **199** | 199 |
| Two-line pill height (pt) | 6 | **26.333** | 26.333 |
| Two-line pill label window y (pt) | 215.167 | **205** | 205 |
| Two-line pill label height (pt) | 0 | **14.333** | 14.333 |
| One-line column window y / height (pt) | 255.333 / 77 | **255.333 / 77** | 255.333 / 77 |
| Two-line / one-line cell height (pt) | 127.333 / 107 | **127.333 / 107** | 127.333 / 107 |

Score improvement **+3.573 points**. The placement wall is closed; the
screen exceeds 97.5 without changing its row padding or symbol rendering.

Official scorer output:

```text
before: realapp_hackers_feed_light: pixels ({'score': np.float64(94.662), 'mae': 5.799, 'blob': 167.2, 'blob_bbox': [116.7, 410.0, 22.3, 19.3], 'missing': {'area': 55.8, 'bbox': [114.0, 155.7, 12.7, 9.0], 'golden_std': 116.01, 'our_std': 5.78, 'ratio': 0.05}}, None)
after:  realapp_hackers_feed_light: pixels ({'score': np.float64(98.235), 'mae': 2.017, 'blob': 137.7, 'blob_bbox': [116.7, 406.7, 22.3, 12.7], 'missing': {'area': 53.7, 'bbox': [190.7, 78.0, 8.7, 12.3], 'golden_std': 116.55, 'our_std': 0.0, 'ratio': 0.0}}, None)
```

## Fresh measurement and rule

Rebuilt the prior report's scratch SwiftUI probe as **HackersPillMetrics**
under `/tmp/hackers-feed-pills-probe/`, installed it on private simulator
`HackersPillMetrics-hackers-feed-pills`, and captured a real window after
three seconds. GeometryReader background preferences report `.global`
frames. Both the original binary rerun and a fresh compilation of its
source reproduce the same vertical geometry. The simulator was shut down
after capture. The suite uses separate devices with the same private suffix.

The probe reproduces a 55 pt thumbnail, HStack gap 12, text column with
VStack spacing 6, 12 pt domain, 17 pt semibold headline, pill row top
padding 4, 12 pt labels, 12×12 symbols, pill inner gap 4, padding 6 vertical
and 10 horizontal, capsule background, and flexible leading column frame.
The titles are `Show HN: A tiny UIKit Hacker News client` and
`Swift 6.2 is now available`. The pill labels are `128`, `42`, and `Save`.
`MeasuredPillRow` in the focused test carries this fixture, replacing the
probe's GeometryReader markers with accessibility identifiers.

Fresh native frames `[x, y, width, height]`, window points:

| Component | Two-line row | One-line row |
|---|---|---|
| Column | [83, 128, 294, 97.333] | [83, 255.333, 294, 77] |
| Headline | [83, 148.333, 294, 40.667] | [83, 275.667, 294, 20.333] |
| Upvote capsule | [83, 199, 56.667, 26.333] | [83, 306, 56.667, 26.333] |
| Upvote label | [109, 205, 20.667, 14.333] | [109, 312, 20.667, 14.333] |
| Comment capsule | [147.667, 199, 51, 26.333] | [147.667, 306, 51, 26.333] |
| Comment label | [173.667, 205, 15, 14.333] | [173.667, 312, 15, 14.333] |
| Save capsule | [313.667, 199, 63.333, 26.333] | [313.667, 306, 63.333, 26.333] |
| Save label | [339.667, 205, 27.333, 14.333] | [339.667, 312, 27.333, 14.333] |

The port's test produces the same column, headline, pill, and label
vertical frames after the fix. Its upvote label width is 20.5 (capsule
56.5), versus the native probe's 20.667 (56.667); no horizontal glyph
metric was adjusted to hide that residual. The actual feed has different
counts (`312` / `128`) from the scratch probe. Its first capsule and label
also move from y 209.167 / 215.167 and heights 6 / 0 to y 199 / 205 and
heights 26.333 / 14.333. Absolute feed frames were reconstructed from
parent-relative dumps, subtracting each UIScrollView's contentOffset;
the List's offset is [0, -113].

Cause: `measure(.hStack)` already remeasures compressed widths under the
iOS cut. `placeHStack` measured its children at the full row width, then
compressed the text column to 294 pt, but retained its old 77 pt height.
Centering 77 inside 97.333 adds **(97.333−77)/2 = 10.167** to y. The nested
VStack needs the additional headline line and exhausts its old allocation
before reaching the pills. This is not a Text ideal-size or capsule rule.

Rule: **when an iOS HStack assigns a child less width than its initial
measurement, remeasure its height at the assigned width before resolving
vertical alignment**. The existing available-height clamp remains. This
adds no constants. Catalyst keeps its existing path. The rule's comment
names the probe and its measured values.

## Verification

- Failing first: `HackersFeedFidelityTests`, **6 assertions failed** on the
  two-line column/pill/label y and height; one-line controls passed.
- After: `HackersFeedFidelityTests|SwiftUIDesignSystemTests|GlassMaterialTests`
  **38/38 passed**.
- Catalyst: before and after **124/124**; all **178 rendered PNGs**
  (including animation frames) byte-identical.
- Real apps: other **14/14 PNGs byte-identical**. All 14 scorable screens
  print their scores; the existing browser size mismatch / `None` layout
  coordinate causes the full comparator to terminate afterward. The
  isolated Hackers score above runs cleanly against unchanged copies of
  its carried goldens. This comparator issue was also present in the
  prior report and is outside this change.
- Fresh iOS suite: before and after **112/113**; sole miss `corner_radius`
  **99.411**. All **113/113** rendered PNGs byte-identical.
- Linux `swift:6.2-noble` release: **passed**, 230.78 s.
- `CHECK_ONLY=1 bash scripts/agent_merge.sh agent/hackers-feed-pills` runs
  on the implementation commit next; the follow-up report records its output.

## Remaining measured wall

The before/golden/after sheet still shows the blank `safari`, `arrow.up`,
`message`, and `bookmark` renderers. The title menu's empty ink region is
now the scorer's missing region, `[190.7, 78, 8.7, 12.3]`. The headline
still wraps `...Hacker News / client` instead of `...Hacker / News client`
at the same 294 pt column width. These were not changed: this branch closes
one measured placement rule and leaves the optional symbol routing for a
separate measurement. No score-targeted parameters were searched.

## Reproduce

Run from `uikit/`:

```sh
swift test --filter 'HackersFeedFidelityTests|SwiftUIDesignSystemTests|GlassMaterialTests'
swift build -c release --product openrender
OPENUIKIT_REALAPP_SCALE=3 OPENUIKIT_FORCE_IOS=1 ./.build/release/openrender realapp /tmp/app-hackers-feed-pills-after
python3 Tools/compare/compare_realapp.py --golden goldens/ios/golden_realapp_ios --out /tmp/app-hackers-feed-pills-after --scale 3 --golden-straight-alpha
SIM_DEVICE_SUFFIX=-hackers-feed-pills scripts/ios_suite.sh /tmp/suite-hackers-feed-pills
./.build/release/openrender render /tmp/gate-hackers-feed-pills fixtures/scenes/*.json
python3 Tools/compare/compare.py --out /tmp/gate-hackers-feed-pills
CHECK_ONLY=1 bash scripts/agent_merge.sh agent/hackers-feed-pills
```

This is a real-app SwiftUI screen, not a SceneKit JSON fixture, so its
named-scene oracle loop is the real-app render/comparator above. The
scratch source/capture, golden preference dump, parsed before/after test
frames, absolute real-app dumps and crop sheet are under
`/tmp/hackers-feed-pills-probe/`. The baseline release executable is
`/tmp/openrender-hackers-feed-pills-before`; it renders the same fresh
suite scenes for a direct before/after comparison without stashing files
while simulator capture is running. No golden bytes are modified.
