# UIToolbar intrinsic height: 54 was a fixture frame, iOS says 48 / 44

Branch `agent/toolbar-intrinsic-height`, 2026-09-10. Task: the
firefox-blocking-rows report (2026-09-09) noted `UIToolbar`
`sizeThatFits` / `intrinsicContentSize` read 48 on iPhone 16 / iOS 26.1
while the port carried 54. Measure it per trait before changing anything,
find where the 54 came from, fix the rule, prove it.

## Where 54 came from

`git log -S'defaultHeight: CGFloat = 54'` in the pre-subtree uikit history:
`8730cf3` (2026-08-25, "M13 bars & appearance"), the commit that created
`UIToolbar.swift`. Its message lists the platter height (48) and alignment
as measured and never mentions the bar height. The only artefact with a 54
is `fixtures/scenes/toolbar_basic.json`, which HANDS each bar a
`[0, y, 393, 54]` frame; the golden layout (`golden/toolbar_basic.layout.json`)
echoes that frame back through `UICoreHostingView<RootView> [0, 0, 393, 54]`.
So 54 was the fixture author's choice of frame — the same 54 as the
navigation bar's content height (`UINavigationBar.iOSBarContentHeight`),
which is the likely source — and `intrinsicContentSize` was set to the
frame the golden happened to use. No probe ever read a toolbar's intrinsic
size until firefoxrowsprobe did.

## Probe

`Tools/oracle2/toolbarheightprobe/main.swift` +
`scripts/toolbar_height_probe_sim.sh` (README lists every row). iPhone 16,
iPhone SE 3rd gen, iPad A16, all iOS 26.1, portrait then in-app rotation to
landscape; `UIBarStyle` `.default` and `.black`; with and without items.
Reads: `intrinsicContentSize`, `sizeThatFits` (three sizes),
`systemLayoutSizeFitting` (three ways), `sizeToFit`, hosted 44 / 54 / 64 pt
frames with the subview tree, a bar pinned to a controller's bottom (view
bottom and safe-area bottom) by Auto Layout with no height constraint —
read in the adding turn, one turn later, and via app-like paths
(`viewDidLoad`, add-then-wait, after `invalidateIntrinsicContentSize`) —
and a `UINavigationController` made the window root with
`isToolbarHidden = false`, dumping every view that reaches into the bottom
140 pt in window coordinates. Transcripts `ios-26.1-{iphone16,se,ipad}.json`
beside the probe. Simulators created with `SIM_DEVICE_SUFFIX` and deleted.

## Measured table

| device / orientation | intrinsic = sizeThatFits | Auto Layout frame | platter row (h, x) | nav slot in window | child SA.bottom |
| --- | --- | --- | --- | --- | --- |
| iPhone 16 portrait (compact w × regular h) | **48** | 48 (`[0, 804, 393, 48]`; SA-pinned `[0, 770, …]`) | 48, x 16 | `[0, 766, 393, 86]`, platters `[28, 776, 337, 48]` | **86** (34 without items) |
| iPhone 16 landscape (compact h) | 48 detached, **44** hosted | **48** (`[0, 345, 852, 48]`, also from viewDidLoad; 44 only after `invalidateIntrinsicContentSize`) | 44, x 126 (600 pt row) | `[59, 311, 734, 82]`, platters `[87, 321, 678, 44]` | 82 (20) |
| iPhone SE 3 portrait (2x, SA 20/0) | 48 | 48 (`[0, 619, 375, 48]`) | 48, x 16 | `[0, 581, 375, 86]`, platters `[28, 591, 319, 48]` | 86 (0) |
| iPhone SE 3 landscape | 48 detached, 44 hosted | 48 (`[0, 327, 667, 48]`) | 44, x 20 | `[0, 293, 667, 82]`, platters `[28, 303, 611, 44]` | 82 (0) |
| iPad A16 portrait and landscape (regular × regular) | **44**, cold too | 44 (`[0, 1136, 820, 44]`; SA-pinned `[0, 1111, …]`) | 44, x 20 | `[0, 1101, 820, 79]`, platters `[10, 1111, 800, 44]` | 79 (25) |

Nothing changes with `UIBarStyle` or with items present vs absent, except
that a nav controller shows NO slot when the top controller has no items.
Platters are top-aligned at y 0 in 48 / 54 / 64 pt bars and centred when
the bar is shorter than the platter (44 pt bar → `[16, −2, 361, 48]`). The
`toolbar` object of a `UINavigationController` is not in the hierarchy on
iOS 26.1 (superview nil, frame = the whole view, `items` nil even with
`toolbarItems` set); the bar UIKit shows is a hosted `_UIInheritedView`
slot = 10 + platter + 28 on a phone (86 / 82, independent of the 0 / 20 /
34 home-indicator inset), 10 + 44 + 25 on the pad (79), platters 10 pt
below the slot top and 28 (pad: 10) in from the side — the same slot the
port's `UISearchBar.BottomDock` already carried for the bottom search field
(Ledger t200: 86 / 82). Image items in a toolbar are platter-sized circles
(48 × 48 on the phone, 44 × 44 on the pad; the Tabs t2000 goldens agree:
`[210, 0, 48, 48]` phone, `[651, 0, 44, 44]` iPad).

The iPad row is confirmed by an existing real-iOS golden:
`goldens/ios/hc-conformance-Tabs-ipad/Tabs.t2000.layout.json` has the
toolbar's `_UIInheritedView [20, 0, 780, 44]` inside a 54 pt frame; the
phone golden has `[16, 0, 343, 48]`.

## Port before → after

| observation | iOS 26.1 | port before | port after |
| --- | --- | --- | --- |
| `intrinsicContentSize.height` / `sizeThatFits.height`, phone | 48 | 54 | 48 |
| same, pad | 44 | 54 | 44 |
| same, phone compact height, hosted | 44 (Auto Layout still frames 48) | 54 | 48 — the laid-out number; a direct read deviates by design (documented on `UIToolbar.defaultHeight`) |
| Auto Layout bottom-pinned frame height, phone / pad | 48 / 44 | 54 / 54 | 48 / 44 |
| platter row height / margin, phone regular | 48 / 16 | 48 / 16 | unchanged |
| platter row height / margin, pad or compact height | 44 / 20 | 48 / 16 | 44 / 20 |
| platter y in a 44 / 54 / 64 pt bar | −2 / 0 / 0 | 0 / 0 / 0 | −2 / 0 / 0 |
| image item platter width in a toolbar, phone | 48 | 44 | 48 (`max(w, platterHeight)`) |
| nav toolbar frame, iPhone 16 portrait with items | slot `[0, 766, 393, 86]` | `[0, 798, 393, 54]` | `[0, 766, 393, 86]`, platters at `[28, 776, 48, 48]` |
| nav toolbar, compact height / pad | 82 / 79 | 54 / 54 | 82 / 79 |
| child `safeAreaInsets.bottom` under a nav toolbar with items (iOS cut) | 86 | 54 | 86 |
| `isToolbarHidden = false`, no `toolbarItems` | no bar, SA stays the window's | 54 pt bar and inset | no slot, SA stays the window's |
| `toolbar_basic` golden (explicit 54 pt frames) | platters y 0, 48 tall | same | same — a 54 pt frame is ≥ platter-high, so nothing moves |
| Tabs t2000 (54 pt height anchor) | platters y 0 | same | same on the phone; the iPad screen's platters go 48 → 44 (the golden's number) |

Classic (Catalyst) cut: the nav toolbar keeps the bar's intrinsic height at
the bottom edge (now 48; never measured on Catalyst either).

## Files

- `Sources/OpenUIKit/UIToolbar.swift`: header measurements;
  `defaultHeight` is now `isPad ? 44 : 48`; `_platterTopInset` /
  `_platterSideInset` for the nav slot; layout uses the trait platter height
  and margin, top-aligned-or-centred.
- `Sources/OpenUIKit/UIBarButtonItem.swift`: `_UIBarMetrics`
  `toolbarPlatterHeightForCurrentTraits`, `toolbarSideMarginForCurrentTraits`,
  `toolbarSlotTopPadding` / `BottomPadding` / `SideInset` / `Height`;
  image items never narrower than the platter is tall.
- `Sources/OpenUIKit/UINavigationController.swift`: `toolbarHeight` is the
  slot under the iOS cut and 0 without items; the toolbar frame is the slot
  with the platter insets; `updateToolbar` re-frames when items appear or
  vanish; `isToolbarHidden` fills items before framing.
- `Tests/OpenUIKitTests/ToolbarHeightTests.swift` (11 tests, every number
  a transcript row). Failing-first against main: with the two
  `_UIBarMetrics` table assertions removed the file compiles and reports
  54 for every 48 / 44 and `[0, 798, 393, 54]` for the slot (30
  assertions); with them, it does not compile (the metrics did not exist).
- `Tools/oracle2/toolbarheightprobe/` (probe, README, three transcripts),
  `scripts/toolbar_height_probe_sim.sh`, `.gitignore` for its `.app`.

## Gates

```
swift test --filter ToolbarHeightTests
  11 tests, 0 failures
swift test --filter "ToolbarHeightTests|ToolbarDelegateTests|NavigationToolbarTests|BarItemLayoutTests|BarButtonItemTests|BarButtonActionTests|BarAppearanceTests"
  52 tests, 0 failures
swift test --filter "Navigation|Toolbar|SafeArea|AutoLayout|Hosting|SwiftUI"
  227 tests, 2 failures — both in
  IOSNavigationBarTransitionTests.testIOSInlineBarIsTransparentAndContentUnderlaps
  (nav-bar appearance proxy left `.opaque` by an earlier suite). Pre-existing
  and unrelated: the same 2 failures with `--skip ToolbarHeightTests`, the
  same 2 on main's Sources with the new file removed, and 18/18 when that
  suite runs alone.
```

Merge check (`CHECK_ONLY=1 uikit/scripts/agent_merge.sh agent/toolbar-intrinsic-height`):
three runs hit `MERGE CONFLICT with main` on `docs/REAL_APP_TEST.md` rows
added by concurrent landings (resolved by keeping both sides, merges
34d30f5a / 68a0f579 / 4be19aa1); the first full run went `LINUX BUILD RED`
on a bare `@MainActor` on the two test helpers (guarded in 3a5b106c); on
3a5b106c:

```
checks passed (CHECK_ONLY)
```

707 board rows re-rendered, none below its board value (Tabs:t2000 84.946
= board; Tabs-ipad:t2000 98.657 = board; Tabs:t1000 / Tabs-ipad:t1000 up
0.03 / 0.07); real-app floors held (realapp_ledger_light 99.61).

## Walls and leftovers

- Compact-height direct reads: iOS answers 44 to `intrinsicContentSize`
  on a hosted phone bar in landscape while Auto Layout frames it 48 (the
  engine's cached cold read). The port returns 48 from both, matching every
  laid-out pixel and deviating on the direct read. Modelling the cache
  would need the port's engine to snapshot intrinsic sizes before trait
  propagation; not done.
- iPhone 16 landscape packs the free-standing platter row into 600 pt at
  x 126 (SE landscape: full width minus 20 each side). A readable-width cap
  on wide compact-height bars; not modelled, transcript row
  `landscape.frame.default.items.hosted54.tree`.
- `UINavigationController.toolbar` is detached with nil `items` on iOS
  26.1. The port keeps a real bar in the hierarchy (openrender's scenes and
  the classic cut draw through it); `NavigationToolbarTests` still assert
  `toolbar.items` follows the top controller, which is the pre-iOS-26
  contract apps read.
- The port declares no `UIBarStyle`; no ladder app source reads one (only
  an Eidolon storyboard), so none was added — the transcript carries both
  styles and no number differs.
- iPad slot bottom padding (25) equals the one iPad's safe-area inset;
  whether it is a constant or the inset needs a second pad device.
