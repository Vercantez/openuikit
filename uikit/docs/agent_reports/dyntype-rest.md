# Dynamic Type rest (NavFlow / Modal / Tabs / Pager / Notes at ax1)

The Dynamic Type axis (`conformance_flow.sh --ax1`) already covered Forms,
Feed and TableEditor. This round captures NavFlow, Modal, Tabs, Pager and
Notes at `.accessibilityLarge` on the SE 2x and closes the two largest
measured misses per app under the iOS cut.

## Harness

`scripts/conformance_flow.sh <workdir> <App> --ax1` sets
`CONFPROBE_CONTENT_SIZE` / `OPENUIKIT_APP_CONTENT_SIZE=ax1`. Capture names
are suffixed `.ax1` (`t200.ax1`). Default `.large` stays unsuffixed.

The pin is `window.traitOverrides.preferredContentSizeCategory =
.accessibilityLarge` before `makeRoot()` (the same setter realapp `_ax1`
uses). **`UITraitCollection.current` stays `.large`.**

MEASURED Pager t200.ax1 / Modal t200.ax1 / Notes t200.ax1 / Feed t200.ax1,
iPhone SE 2x / iOS 26.1:

| call | golden |
|---|---|
| `preferredFont(forTextStyle:)` (no `compatibleWith:`) | Pager heading **34**, cards **17**, Modal root buttons **17**, Notes rows **17/15/13**, Feed cards **15** |
| `preferredFont(..., compatibleWith: view.traitCollection)` / `UIFontMetrics.scaledValue` | chrome: large title **48**, classic `textLabel` **33**, search field **80**, alert title **33** |

`UIWindow.traitCollection` previously copied `current` and ignored
`traitOverrides`, so descendants never saw ax1. The override is now applied
on the window (then inherited through `UIView.traitCollection`).

## Baseline (before the iOS-cut rules, SE 2x / iOS 26.1)

| app | worst | mean | notes |
|---|---|---|---|
| NavFlow | **84.759** (t3000.ax1) | 87.817 | t200.ax1 87-ish; large title still 34/106/116 |
| Modal | **64.815** (t5200.ax1) | 92.850 | alert 17/15/48; root buttons already 17 |
| Tabs | **83.013** (t6000.ax1) | 89.863 | cells 52/17; search field 44 |
| Pager | 98.625 | 98.701 | heading would be 48 if `current` were ax1 |
| Notes | **41.825** (t11000.ax1) | 74.613 | list fonts already 17/15/13 |

## Frames (golden, SE 2x / iOS 26.1)

**NavFlow t200.ax1:** large title Library **48 Bold** `[16, 64, 156, 57.5]`;
`_UINavigationBarLargeTitleView` `[0, 64, 375, 61.5]`; bar
`[0, 10, 375, 115.5]`; table `safeAreaInsets.top` **125.5**. Classic
value1 labels **33** h=39.5 in **44** pt rows (`heightForRowAt`). Headers
stay **17** / 38 pt.

**Modal t5200.ax1:** title 33 Semibold h=39.5; message 30 Regular 2-line
**72**; action pills **63.5** (= 12+39.5+12); action labels 33 Medium
h=39.5, intrinsic width, centred in the pill. Root UIButtons stay 17.

**Tabs t200.ax1:** plain classic cells **80** with 33 pt labels filling the
cell. Tab titles stay **10**. t4000.ax1: bar **96**, field
`[16, 18, 252, 80]`, placeholder 33 Medium. `UIFontMetrics.body.scaledValue(44)`
at ax1 = **80**. Extra height `max(6, 8+field+8-54)` → 6 / 42.

**Pager t200.ax1:** heading 34 / cards 17 (construction-time
`preferredFont`).

**Notes t200.ax1:** list 17/15/13. t4000.ax1 search matches Tabs (bar 96,
field 80). First-section header golden **38** compact vs ours 55.5 (OPEN).

## Rules (iOS cut)

1. **`UIWindow.traitCollection` stamps `traitOverrides.preferredContentSizeCategory`.**
   Without this, every chrome rule that reads `view.traitCollection` stayed
   `.large`. `current` is unchanged.

2. **Large title size / zone / bar / inset from the bar's traits.**
   `preferredFont(.largeTitle, compatibleWith:).pointSize` with weight
   `.bold`. Label height = 41 at 34 pt, else `FontEngine.labelLineHeight`
   (48 → 57.5). Zone `max(52, labelHeight+4)` → 52 / 61.5. Bar 54+zone →
   106 / 115.5. Expanded inset 10+bar → 116 / 125.5. Label Y: zone 52 →
   57.5; grown zone → **54**. The label is created in
   `configureLargeTitleAppearance` before the bar joins the window (34 pt,
   width 111.5); `updateFromScroll` re-styles from traits so Library is
   **156×57.5**.

3. **Plain classic row `max(52, scaledValue(44))`.** 52 at `.large`, **80**
   at ax1. `.default` / `.value1` / `.value2` `textLabel` /
   `detailTextLabel` use `preferredFont(.body, compatibleWith:)` in
   `layoutSubviews`. Subtitle stays 17/15 (TableEditor-ax1 unmeasured).

4. **Search field `scaledValue(44)`**, nav-inline dismiss = field height,
   overlay extra `max(6, 8+field+8-54)`. Placeholder 33 Medium at ax1.

5. **Alert title/message/action fonts from the presenting view's traits.**
   `_layoutCard` runs before the card is added to the container, so
   `view.traitCollection` is still `current`. Title 33 Semibold, message
   30 Regular, action 33 Medium, pill `max(48, labelLineHeight+24)` =
   63.5. Action labels hug intrinsic width, centred, 12 pt vertical pad.

## After SKIP_CAPTURE=1

| app | worst | mean | two closed |
|---|---|---|---|
| NavFlow | **94.503** (t4800.ax1) | **96.857** | large title 48/115.5/125.5; value1 33/39.5 |
| Modal | **74.357** (t7200.ax1) | **95.156** | root buttons stay 17; alert 33/30/63.5 (t200.ax1 **99.569**, t5200.ax1 **64.815 → 76.987**) |
| Tabs | 82.614 (t6000.ax1) | **92.352** | cells 80 (t200.ax1 **83.013 → 96.421**); t4000.ax1 search 96/80 |
| Pager | **99.353** | **99.424** | `current` stays `.large` (heading 34) |
| Notes | **52.009** (t11000.ax1) | **81.592** | list 17/15/13; t4000.ax1 search 96/80 (t11000.ax1 **41.825 → 52.009**) |

Default-size (must not move): NavFlow mean **99.036** worst 98.196; Modal
mean **99.106**; Tabs mean **93.820** worst 84.641; Pager mean **99.856**
worst 99.745. Notes default worst 67.419 (pre-existing search/alert).

Already-done ax1: Forms worst **98.563** mean 98.601; Feed worst **99.233**
mean 99.380; TableEditor worst 66.532 mean 87.789 (re-run, not dropped
below the prior ax1 work's remaining subtitle/reorder misses).

## OPEN

Recorded in `scoreboard/open.txt`:

- NavFlow inline title / Filter **17 → 21** (h=25.5 vs 20.5).
- Modal t5200.ax1 header extra slack (card 426 vs 384; title relative y 73
  vs 22). t7200.ax1 action-sheet card 304 vs content 381.5.
- Tabs t6000.ax1 search below the 54 pt title (bar 150) vs overlay at
  t4000; ours collapses.
- Notes first-section header 38 vs 55.5; t11000.ax1 search stays active
  under the alert (bar 150 vs 54).
- Tab bar titles stay 10; large-title collapse still 52 (unmeasured
  scroll); subtitle cells (TableEditor-ax1).

## Verify

- `SKIP_CAPTURE=1` named ax1 apps + default NavFlow/Modal/Tabs/Pager/Notes
  + Forms/Feed/TableEditor-ax1 (above).
- Unit tests: `IOSDevicePixelMetricsTests`, `TraitCollectionTests`,
  `UIAlertActionModelTests`, `UISearchControllerTests`,
  `ConformanceRegistryTests`, `DynamicTypeTests` (64 passed).
- iOS suite **112/113** (`corner_radius` 99.411 open).
- Catalyst **124/124**.
- Real-app floors **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 /
  97.516 / 99.511 / 82.192 / 99.760 / 99.689 / 85.393**.
- Linux `swift:6.2-noble` openrender green (179.90 s). No `Package.resolved`.
