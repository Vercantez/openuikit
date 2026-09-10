# Signal-iOS: the last four blocking UIKit rows

Branch `agent/signal-last-rows`, 2026-09-10, from `origin/main` `488e8bf3`.
Task: the regenerated ladder table (`ladder-table-regen.md`, 437-name type
list, `full/ladder/gap-classes-nextrungs-2026-09-10.json`) leaves
Signal-iOS with four BLOCKING UIKit rows — `UITab` (3 uses),
`UINavigationBarDelegate` (2), `NSIndexPath` (2), `UICornerConfiguration`
(1). Measure each on the iOS 26.1 oracle, implement what Signal uses, and
show 0 blocking rows.

Nothing outside `uikit/` was written. No pin file, `Package.resolved`
(the one `swift build` drops in `uikit/` is left untracked), `.app`
bundle, app source or corpus clone was touched.

## 1. What Signal uses (corpus `scratch/ladder-corpus/Signal-iOS` at `eec0a2f`, read-only)

| row | sites | members |
|---|---|---|
| `UITab` (3) | `HomeTabBarController.swift` 112–121, 173, 299–320 — iPad + `#available(iOS 18)` only | `UITab(title:image:identifier:) { _ in vc }` with a persisted controller per tab, `badgeValue`, `accessibilityValue`, `UITabBarController.tabs = …`, then the legacy `selectedIndex` and `UITabBarControllerDelegate` `shouldSelect` / `didSelect`; `delegate = self` |
| `UINavigationBarDelegate` (2) | `OWSNavigationController.swift` 248 (a `UINavigationController` subclass), `MediaPageViewController.swift` 1027 | `navigationBar(_:shouldPop:)` (cancels back presses; compares `topViewController?.navigationItem == item`), `navigationBar(_:didPop:)` |
| `NSIndexPath` (2) | `GroupCallVideoGridLayout.swift` 123, `GifPickerLayout.swift` 109 | `NSIndexPath(item:section:)`, `NSIndexPath(row:section:)`, each `as IndexPath` into `UICollectionViewLayoutAttributes(forCellWith:)` |
| `UICornerConfiguration` (1) | `VideoTimelineView.swift` 112 (`#available(iOS 26)`) | `.uniformCorners(radius: .fixed(8))` assigned to `cornerConfiguration` of the view and a subview |

None of the four had a declaration in `uikit/Sources/OpenUIKit` at
`488e8bf3` (grep). Two member-level gaps the classifier cannot see were
found the same way and are closed here because Signal's sites need them:
`UINavigationBar` had no `delegate` property at all, and
`UITabBarController` spelled its delegate `tabBarControllerDelegate`
(Signal writes `delegate = self`; both spellings now work).

Where `NSIndexPath` went: `uikit/Sources/OpenUIKit/NSIndexPath.swift`, a
`typealias` to Foundation's class plus UIKit's two-component conveniences —
the type is Foundation's and UIKit only adds `NSIndexPath+UIKitAdditions.h`
(`indexPathForRow:inSection:`, `indexPathForItem:inSection:`, `section`,
`row`, `item`), which is exactly what the extension declares. It is a UIKit
file, not a Foundation-port one, because the Foundation port carries
Foundation's own surface and these five members are UIKit's. It is a
separate file (not `FoundationTypes.swift`) because that file imports
AppKit on macOS, and — MEASURED with `swift test` — a test target that
imports only XCTest and OpenUIKit does NOT see AppKit's
`indexPathForItem:inSection:` initializer (it appears as
`init(forItem:inSection:)` there) but DOES see AppKit's `item` / `section`
properties; so the initializer is declared everywhere and the two properties
only where AppKit is absent. The Foundation-hidden guest route
(`FoundationEssentials`) has no `NSIndexPath` class and gets none here.

## 2. Probe

`Tools/oracle2/signallastrowsprobe/` (README there) — `main.swift`, driven
by `scripts/signal_last_rows_probe_sim.sh` on a private iPhone 16 and, with
the `ipad` argument, iPad (A16), both iOS 26.1 / 23B86. One app, four
sections; the corner grid is photographed by the render server
(`simctl io screenshot`) at two markers and reduced by `corners.py`.
Committed: `ios-26.1-iphone16.json`, `ios-26.1-ipad-a16.json`,
`corners-ios-26.1-iphone16.json`, `corners-ios-26.1-ipad-a16.json`.

Two probe steps crashed the oracle and were turned into recorded facts:
`UITabBarController` no longer responds to the `UITabBarDelegate` entry
`tabBar(_:didSelect:)` on iOS 26 (unrecognized selector; the tap is now
simulated through `_UITabButton.sendActions`), and `popItem` on a
controller-managed bar raises (`+[NSException raise:format:]` from
`-[UINavigationBar popNavigationItemAnimated:]`).

## 3. Oracle table

### UITab / `UITabBarController.tabs` (iPhone 16 and iPad (A16) identical unless noted)

| measurement | iOS 26.1 | port after |
|---|---|---|
| provider timing | not at init; once, lazily, on first `viewController` read or at `tabs =` (all three ran before the view loaded); argument is the tab; `vc.tab === tab` immediately; never re-run on subset → restore (also for a provider returning a fresh controller each time) | same |
| defaults | badge nil, subtitle nil, placement 0, hidden false, enabled true, allowsHiding false, `hasVisiblePlacement` false → true once in `tabs`, `tabBarController` nil → set → nil when dropped | same |
| `tabs =` before load | `viewControllers` **nil**; `tabBar.items` mirrored (title, badge, tag 0, image a different object); `selectedIndex` 0, `selectedTab` t1, `selectedViewController` t1's controller; `didSelectTab(t1, previousTab: nil)` synchronously; nothing more when shown | same (image shared, not copied) |
| badge / title | tab → item AND `vc.tabBarItem` (one object); item → tab **not** propagated (tab "7", item "9"); tab title → item title, `vc.title` unchanged | same |
| `selectedTab =`, `selectedIndex =`, `selectedViewController =` | `didSelectTab` only (no `shouldSelectTab`, no legacy pair) | same |
| user tap (`_UITabButton`) | `shouldSelectTab` → `didSelectTab`; re-tap fires both again with previous == tab; `false` fires nothing else; legacy `shouldSelect false` changes nothing | same, through `tabBar(_:didSelect:)` |
| subset dropping the selected tab | selection → first tab, `didSelectTab(first, previousTab: dropped)`; restore reports nothing | same |
| `tabs = []` | `selectedIndex` NSNotFound, `tabBar.items` `[]` not nil, `selectedTab` / `selectedViewController` stale | same |
| legacy after tabs / back | `viewControllers = …` → `tabs == []`, tabs detached, legacy items; `tabs = …` again → `viewControllers` nil, legacy children `parent` nil | same |
| legacy-only controller | `tabs == []`, children `tab == nil`, `selectedTab` a private auto-generated tab (UUID id) | `selectedTab` nil (not modelled) |
| iPad | `mode` 0, `sidebar.isHidden` **true**, tree `_UITabContainerView` > `_UIFloatingTabBar` [0, 32, 820, 44]; no `_UITabButton` in the tree (tap rows empty); phone reads `sidebar.isHidden` false | `mode` stored; the floating bar the port already lays out; `sidebar` not modelled |

### UINavigationBarDelegate

| measurement | iOS 26.1 | port after |
|---|---|---|
| standalone `delegate` | nil; `position(for:)` asked once when the bar joins a superview, with the bar as argument; `barPosition` 2 detached, 3 (`.topAttached`) attached | same (`.any` keeps `.top` — inferred from the toolbar's rule, not measured) |
| `pushItem` | `shouldPush(item)` with `items`/`topItem` unchanged → `false` leaves the stack → else `didPush(item)` synchronously, also when animated | same |
| `popItem` | `shouldPop(top)` with the stack unchanged → `false` keeps it and **still returns the item** → else `didPop` synchronously; empty bar asks with a nil item and returns nil | same; the nil-item ask is not representable in Swift (silent nil) |
| `setItems` | no `should*`; animated: `didPop(oldTop)` when the new top was in the old stack, else `didPush(newTop)`; non-animated: nothing; a vetoing delegate does not apply; `nil` → `[]` | same |
| back button on the standalone bar | `shouldPop` → `didPop` | the port's standalone bar draws no back button (pre-existing) |
| controller-managed bar | `delegate === nav` (the subclass); `pushViewController` → `shouldPush(item)` with `viewControllers` grown and bar items not yet, no `didPush`; programmatic pop asks nothing; back tap → `shouldPop(item === top.navigationItem)` with both stacks intact → `false` leaves them → `true` pops then `didPop` with both shortened; `popItem` on the managed bar raises | same (`delegate = self as? UINavigationBarDelegate` in `loadView`, so `UINavigationController` declares NO conformance and Signal's extension compiles); the `shouldPush` answer is not acted on (effect unmeasured) |

### NSIndexPath

`NSIndexPath(item: 3, section: 1)`: length 2, indexes [1, 3], section 1,
item 3, row 3; `(row: 4, section: 2)`: item 4; `as IndexPath` → [1, 3],
count 2, equal to `IndexPath(item: 3, section: 1)`; round trip back keeps
both; `UICollectionViewLayoutAttributes(forCellWith: NSIndexPath(item: 7,
section: 0) as IndexPath)` → [0, 7]. Port: identical (the cast is
Foundation's bridge on Darwin and corelibs' on Linux).

### UICornerConfiguration (iPhone 16 @3x; iPad reductions agree)

| measurement | iOS 26.1 | port after |
|---|---|---|
| layer state after `cornerConfiguration =` | `cornerRadius` stays 0, `maskedCorners` 15, `cornerCurve` continuous; radii land in a private per-corner `cornerRadii` (64 bytes); a later `layer.cornerRadius = 2` / `30` reads back but pixels are unchanged (max diff 0 vs the untouched twin) | `_CACornerRadii` on the layer, wins over `cornerRadius` |
| pixels vs controls | every configured view identical (max diff ≤ 1/255) to `layer.cornerRadius = r` + `.continuous`; differs from `.circular` by up to 97/255 over ~400 px at r = 8 | identical bytes to the port's `cornerRadius = r` (which is circular) — the continuous delta is the port's pre-existing corner-drawing gap, listed in KNOWN_GAPS |
| `.fixed(8)` 100×40 / `.fixed(12)` 60×60 | 8 / 12 (measured 8.07 / 12.10 continuous-equivalent) | 8 / 12 |
| `.fixed(40)` 100×40 | **20** (clamped to min(w,h)/2) | 20 |
| `.capsule()` 100×40, 60×100, resized to 200×60 | 20, 30, 30 | same, re-resolved on every bounds change |
| `.capsule(maximumRadius: 10)` | the configuration describes as `.fixed(radius: 10.0)`; 10 | `.fixed(10)` |
| tl 10 / tr 0 / bl 20 / br 30 (120×80) | 10.1 / 1.0 / 20.2 / 30.2, independent | per-corner path in the render pass; the CQuartz layer backend takes one radius and receives the largest (30) — documented approximation, uniform sets unaffected |
| `uniformEdges(top 16, bottom 4)`, `uniformTopRadius(16)` | 16/16/4/4; 16/16/0/0 (unspecified = square) | same |
| `.containerConcentric(minimum: 8)` inset 4 in a radius-20 container | layer state 16 (= 20 − 4) | 16, floored at the minimum; inset = min(dx, dy) when they differ (unmeasured) |
| `description` | `UICornerConfiguration(topLeftRadius: .fixed(radius: 8.0), …)`, `.unspecified`, `.capsule`, `.containerConcentric(minimumRadius: 8.0)` | same strings |
| fresh `UIView().layer.cornerCurve` | **continuous** | `CALayerCornerCurve` added, stored only, default `.circular` (drawing is circular either way) |

## 4. Gates

```
swift test --filter "UITabTests|UINavigationBarDelegateTests|NSIndexPathTests|UICornerConfigurationTests"
  20 tests, 0 failures (8 + 5 + 1 + 6)
  failing-first: with uikit/Sources stashed the file does not compile —
  "cannot find type 'UITab' in scope", "cannot infer contextual base in
  reference to member 'fixed'", NSIndexPath "incorrect argument labels
  (have 'item:section:', expected 'forItem:inSection:')".
swift test --filter "…the four…|TabBarControllerTests|TabBarControllerDelegateTests|IOSNavigationBarTransitionTests|NavigationControllerTests|MaskedCornersTests|LayerBridgeTests|LayerCacheTests|LayerContextCompatibilityTests|BarItemsTests|ChromeControllerTests|DelegateProtocolTests|IndexPath|Corner"
  94 tests, 0 failures, 1 skipped
full/ladder: type list regenerated from uikit/Sources/OpenUIKit with the
  remeasure regex — 437 names at 488e8bf3 (equal to the 2026-09-10b count),
  444 on this branch (+UITab, UITabPlacement, UINavigationBarDelegate,
  NSIndexPath, UICornerConfiguration, UICornerRadius, CALayerCornerCurve);
  ladder_census.py on a one-symlink mini corpus + classify_gaps.py:
  Signal-iOS blocking 4 types / 8 uses → NO blocking key (0 / 0);
  stub-able unchanged at UILocalizedIndexedCollation 1 / 4.
```

Merge check: see the REAL_APP_TEST.md row (filled after the run).

## 5. Walls left

- Continuous corners: iOS 26.1 draws every `cornerConfiguration` (and a
  fresh layer's `cornerRadius`) with the continuous curve; the port's
  corner drawing is circular. The mapping here is exact against the port's
  own `cornerRadius`, not against the oracle's bytes.
- The CQuartz layer backend has one radius per layer; non-uniform
  configurations get the largest there (the pure-Swift render pass is
  per-corner).
- `UITabBarController.sidebar`, `UITabGroup`, the legacy-mode
  auto-generated `selectedTab`, and `selectedIndex == NSNotFound` before
  any children in legacy mode (measured; the port keeps its 0) are not
  modelled. Signal uses none of them.
- The standalone `UINavigationBar` draws no back button (pre-existing), so
  its `shouldPop` / `didPop` from a tap is only reachable through
  `popItem`; the controller path — Signal's — is wired.
- The empty-bar `popItem` ask with a nil item, and the controller-path
  `shouldPush` answer's effect, are recorded but not modelled / measured.
