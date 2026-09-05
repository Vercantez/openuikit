# Tabs t2000 — `title` copies onto `tabBarItem`

Worst Tabs capture on the board (84.57, blob 246, layout 8). The brief
named t2000 as search-focus / keyboard-up; the script is not that.

`Sources/ConformanceApps/Tabs/script.json` captures at
`[0.20, 1.00, 2.00, 3.00, 4.00, 5.00, 6.00, 7.00]` after
select-tab-2 / select-tab-3 / select-tab-1 / focus-search / type-search /
cancel-search / scroll-200. **t2000 is tab 3 (Scroll selected).**
Search-in-navbar + keyboard is **t4000**. Frames first.

Device: iPhone SE 2x / iOS 26.1, `OpenUIKit-2x-tabs-t2000`.
`scripts/conformance_flow.sh /tmp/conformance-Tabs Tabs`. Probe kept in
`/tmp/tabs-t2000-probe` (not the repo).

## What the dumps said

t2000 golden vs ours (before):

- First-tab label: golden **"Library"** `[84, 623, 36, 12]` vs ours
  **"Search"** `[84.5, 623, 35, 12]`.
- Remaining layout noise: other-tab views still in the golden dump
  (Actions / Left / Right) and duplicated tab-bar labels (confprobe
  dumps more of the live tree than openhost).
- Pixel blob **246** at `[264.0, 598.5, 19.0, 19.0]` — selected
  `clock.fill` ink. Out of scope (other agents own symbols / glass).

t4000 search-in-navbar already matched the conf-tabs rule: bar
`[0, 10, 375, 60]`, field `[16, 18, 288, 44]`, dismiss
`[315, 18, 44, 44]` r=17, table SA top 70,
`adjustedContentInset.bottom` **83**.

## Probe (SE 2x)

`/tmp/tabs-t2000-probe/main.swift` on iPhone SE 2x / iOS 26.1. Title
cases and search chrome:

1. Plain VC: `tabBarItem.title = "Search"` then `title = "Library"` →
   item title **Library**. Creating the item if it was nil matches
   (child.tabBarItem is nil before the set, non-nil after).
2. Tabs-like: `nav.tabBarItem = "Search"` then `child.title = "Library"`
   → **both** items become Library even though they are **different
   objects**. `navigationItem.title = "Library"` does **not** copy.
3. Last explicit `nav.tabBarItem.title = "Search"` after Library **wins**
   (afterRewrite Search). Assigning a new item after the child title is
   set leaves that item's title (Search) until the next `title` write.
4. Search rest: bar `[0, 10, 375, 54]`, search `[0, 64, 375, 0]`,
   table `adjustedContentInset` `[64, 0, 83, 0]`. Active: bar
   `[0, 10, 375, 60]`, field `[16, 18, 288, 44]`, dismiss
   `[315, 18, 44, 44]` r=17, table inset `[70, 0, 83, 0]`. Keyboard is
   a `UITextEffectsWindow`; table bottom inset stays **83**.

TabsApp does (2): `nav.tabBarItem = UITabBarItem(title: "Search", …)`
in `makeRoot()`, then `TabsSearchViewController.viewDidLoad` sets
`title = "Library"`. Item views are built at `setViewControllers`,
before that `viewDidLoad`, so the bar has to re-read `item.title`.

This is UIKit title / `tabBarItem` wiring, not a chrome constant.
Catalyst `tabbar_basic` sets item titles directly; 124/124 held without
an iOS-cut guard. The label-reread test runs under
`OpenUIKitRuntime.systemFontCut == .iOS` so the 10 pt tab title metrics
match the capture.

## Rule

- `UIViewController.title` didSet writes `tabBarItem.title` (creates the
  item if nil).
- `UINavigationController._titleDidChange` copies `vc.title` onto
  `nav.tabBarItem.title` when the child is in `viewControllers`.
- `UITabBarItem.title` didSet calls `_bar?.setNeedsLayout()`;
  `_UITabBarItemView.layoutSubviews` re-reads `item.title`.

## After (`SKIP_CAPTURE=1`, same goldens)

| capture | before | after | blob | notes |
|---|---|---|---|---|
| t200 | 93.089 | 93.080 | 79.5 | −0.009; Library frame now `[84, 623, 36, 12]` |
| t1000 | 97.914 | **99.294** | 59.0 | +1.380; unselected first-tab label matches |
| t2000 | 84.571 | **84.643** | 246.0 | +0.072; layout **8 → 7** (Search vs Library gone) |
| t3000 | 93.330 | 93.321 | 79.5 | −0.009 |
| t4000 | 92.817 | 92.806 | 79.5 | −0.011 |
| t5000 | 93.066 | 93.027 | 79.5 | −0.039 |
| t6000 | 88.253 | 88.263 | 79.5 | +0.010 |
| t7000 | 92.315 | 92.268 | 59.0 | −0.047 |

Mean **91.919 → 92.088**, worst **84.571 → 84.643**. Blobs unchanged.
No pass → fail (only t1000 was above 97.5, and it rose). The sub-0.05
pixel dips on t200 / t3000 / t4000 / t5000 / t7000 are 10 pt Library
glyph coverage vs the previous coincidental Search overlap against the
same golden; the layout dump now matches the measured title.

t2000 remaining blob is selected `clock.fill` at `[264.0, 598.5, 19.0, 19.0]`.

## OPEN (not modelled)

- Selected-tab SF Symbol ink (`clock.fill` on t2000; unselected
  calendar on t1000 blob 59 inside platter `[51, 584, 274, 62]`).
  Other agents own symbols / glass this wave.
- Other-tab views in the golden dump (Actions / Left / Right) and
  duplicated tab-bar labels — dump-tree mismatch, not a frame miss.
- Classic row height 52 vs `defaultRowHeight` 53 (`scoreboard/open.txt`).
- Keyboard is a separate `UITextEffectsWindow`; not in the PNG.
  Search-in-navbar frames already match (t4000).

## Gates

- Catalyst: **124/124**
- iOS suite: **112/113** (known miss `corner_radius`)
- Real-app floors held: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 /
  98.133 / 97.516 / 99.511 / 82.192** (Focus) / **99.760 / 99.689**
- Linux `swift:6.2-noble` `openrender` green
- `swift test --filter UISearchControllerTests` (8)
