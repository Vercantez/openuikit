# WordPress-iOS / NetNewsWire `UISplitViewController` row

Branch `agent/wordpress-splitview`, 2026-09-09. Task: APP_LADDER §9.6 lists
`UISplitViewController` as the top BLOCKING row for WordPress-iOS (20 uses)
and NetNewsWire (16 uses). Check staleness first, then measure and close what
those uses still lack against the iOS 26.1 oracle on both size classes.

## 1. Stale-row check

| row | in `uikit/Sources/OpenUIKit` at origin/main | landed | in `gap-classes-2026-09-16.json` |
|---|---|---|---|
| `UISplitViewController` | `UISplitViewController.swift` (412 lines, 18 + 1 tests, two probes) | ca711a5e 2026-09-07, dc263432 | absent for both apps; `uikit-union-2026-09-16.json` has `ours: true` (5 apps, 49 uses) |

The §9.6 row was stale prose: the 2026-09-16 classifier lists WordPress-iOS
blocking on `UITextItem` / `UIPopoverPresentationControllerSourceItem` /
`NSTextTab` and NetNewsWire on `NSToolbarItem` / `NSMenuToolbarItem`. What
had NOT been measured were the members the previous READMEs left open:
column frames, `primaryBackgroundStyle` geometry, and the collapse/expand
delegate contract. Those were measured and built here.

**What the two apps touch** (corpus `scratch/ladder-corpus`, read-only;
member counts from a grep over `.swift` / `.m`):

| member | WordPress-iOS | NetNewsWire |
|---|---|---|
| `UISplitViewController(style: .tripleColumn)` / subclass | 1 (root presenter) | 1 (`RootSplitViewController`) |
| `setViewController(_:for:)` primary/compact/supplementary/secondary | 10 | — |
| `viewController(for:)` | 7 | 3 |
| `isCollapsed` | 4 | 2 |
| `displayMode` / `DisplayMode` cases | — | 6 |
| `show(_ column:)` (incl. on iPhone) | — | 6 sites via `showColumn` |
| `hide(.primary)` | 1 | — |
| `preferredDisplayMode` | 1 | 3 |
| `preferredSplitBehavior` / `splitBehavior` | 1 / 2 | 1 |
| preferred/minimum/maximum primary + supplementary widths | 6 | 6 |
| `presentsWithGesture`, `showsSecondaryOnlyButton` | 1 | 2 |
| `UISplitViewController.automaticDimension` | 1 | — |
| delegate: `didCollapse`, `didExpand`, `willHide(column:)` | 3 | — |
| delegate: `topColumnForCollapsingToProposedTopColumn`, `willChangeTo`, `didCollapse`, `didExpand` | — | 4 |
| legacy `viewControllers.first/.last` | 2 | — |
| inspector widths, `displayModeButtonItem` | 3 | — |
| `splitViewItems` / `splitView` (macOS `NSSplitViewController`) | — | 11, not iOS |

Every row above except the inspector widths and `displayModeButtonItem`
(stored) and `presentsWithGesture` (stored) is now behaviour-measured.

## 2. Probe recipe

`Tools/oracle2/splitframesprobe/` (README there): `main.swift` +
`scripts/splitframes_probe_sim.sh`, one app, nine scenes, run twice:

```sh
SIM_DEVICE_SUFFIX=-wordpress-splitview SPLIT_SIM_DEVICE=ipad     scripts/splitframes_probe_sim.sh OUT
SIM_DEVICE_SUFFIX=-wordpress-splitview SPLIT_SIM_DEVICE=iphone16 scripts/splitframes_probe_sim.sh OUT
```

iPad (A16) 820×1180 @2x (regular, expanded) and iPhone 16 393×852 @3x
(compact, collapsed). Scenes `double` and `triple` mount the split as the
window root and step through every display mode, `.none` / `.sidebar`
backgrounds, primary fraction 0.3 / 0.5, max 300, WordPress's
`preferred 320 / min 375 / max 400` and `supplementary 320 + tile`,
NetNewsWire's `min 300 / max 500` + `min 280 / max 440` + `twoBeside`,
supplementary fraction 0.5, `show` / `hide` of every column,
`showDetailViewController`, `show(_:sender:)`, `setViewController`. Scenes
`transition.*` put the split under a host controller whose iOS 17
`traitOverrides.horizontalSizeClass` flips compact ↔ regular twice: triple
plain, triple with a compact column (WordPress's tab-bar pattern), a delegate
answering `.primary` for `topColumnForCollapsing`, legacy splits with
`collapseSecondary` false/true + `separateSecondaryFrom` nil/new, and double
with collapsed show/hide/showDetail. Each step waits 0.7 s and writes one
settled record: state, public array, children, per-column container frame
+ absolute frame + safe area + hierarchy membership, and every delegate and
child-lifecycle event in order, each delegate event tagged with
`isCollapsed`, `displayMode` and the public array at that moment. The first
run crashed on the legacy scene: `preferredSplitBehavior` and
`primaryBackgroundStyle` raise `NSInvalidArgumentException` on a legacy
split (like `splitBehavior`). Transcripts: `ios26.1-ipad.json`,
`ios26.1-iphone16.json`, 79 records each. Both simulators were deleted.

## 3. Oracle table

### iPad (A16) regular, window safe area [32, 0, 25, 0]

| row | iOS 26.1 | port before | port after |
|---|---|---|---|
| double mounted (auto → oneBeside) | primary `[10, 32, 320, 1133]` SA `[0,0,10,0]`; secondary `[0,0,820,1180]` SA `[32,330,25,0]` | both `[0,0,820,1180]`, SA inherited | equal |
| double `.none` | primary `[0,0,320,1180]`; secondary `[320.5,0,499.5,1180]` | full | equal |
| double fraction 0.3 / 0.5 / 0.5+max300 / WP 320+375+400 | 246 / **346** (= 820−10−464) / 300 / 375; secondary SA-left = width+10 | 246 / 410 / 300 / 375; no SA | equal |
| double secondaryOnly / oneOver | primary out of hierarchy / floating over a full secondary (SA-left 0) | out / full | equal |
| triple mounted at 820 (auto → oneBeside) | supplementary `[0,0,320,1180]`; secondary `[320.5,0,499.5,1180]`; primary a child but out of hierarchy | full | equal |
| triple twoBeside/twoDisplace request → twoOver | primary `[10,32,280,1133]` floating; supp 320; secondary at 320.5 | full | equal |
| triple explicit twoOver | supplementary **610** (320+280+10) SA-left 290, getter 610; secondary full | 320 | equal |
| triple oneOver | supplementary 320 over a full secondary | full | equal |
| triple supp fraction 0.5 | **355.5** (= 820−0.5−464); secondary `[356,0,464,1180]` | 410 | equal |
| triple NNW widths (pref 300, min 300/500, supp 320, tile, twoBeside) | primary 300 floating, twoOver | – | equal |
| expanded preferredDisplayMode change | willChangeTo → willHide/willShow → appearance → didHide/didShow | willChangeTo only | equal |
| expanded `show(.primary)` / `hide(.primary)` / `show(.supplementary)` | willChangeTo only (no column callbacks); `show` with automatic preference records twoBeside/oneBeside as the preference | willChangeTo only, no preference write | equal |
| showDetail / setViewController(secondary) expanded | replace, no delegate callbacks | same | same |
| collapse (trait override), triple, top secondary | `topColumnForCollapsing(2)` → willHide(1), willShow(0), willHide(2), willHide(0), willShow(2) → didShow(2), didCollapse, didHide(0), didHide(1); `nav[A, nav[S], nav[B]]`; primary width 820 | nothing fired; no restructure | equal |
| collapse with compact column | `topColumn(3)` → willHide(1), willShow(3), willHide(2) → didHide(1), didCollapse, didShow(3), didHide(2); array `[C]`, children `[C]` | nothing | equal |
| collapse, delegate answers `.primary` | willHide(1), willShow(0), willHide(2) → didShow(0), didCollapse, didHide(1), didHide(2); `nav[A]` alone | nothing | equal |
| expand, triple | `displayModeForExpanding(2)` → willShow(1) → didExpand, didShow(1); children `[nav[A], nav[S], nav[B]]` | nothing | equal |
| legacy collapse, `collapseSecondary` false / true | `primaryViewController(forCollapsing)`, `collapseSecondary` → willHide(2), willHide(0), willShow(2) → didHide(0), didCollapse, didShow(2) (pushes `nav[B]`) / willHide(2) → didCollapse, didHide(2) | nothing | equal |
| legacy expand, `separateSecondaryFrom` nil / new | `primaryViewController(forExpanding)`, `separate…` → willShow(0), willShow(2) → didShow(0), didExpand, didShow(2); nil pops the top as the secondary | nothing | equal |
| legacy collapsed showDetail | delegate hook, then push of the raw controller with willHide/didHide of the top column | replaced the secondary slot | equal |

### iPhone 16 compact, window safe area [59, 0, 34, 0]

| row | iOS 26.1 | port before | port after |
|---|---|---|---|
| double / triple mounted | willChangeTo(2), `topColumn(2)`, willShow(0), willHide(0), willShow(2) (isCollapsed false inside), didCollapse, didShow(2), didHide(0) (true, array `[A]`); `nav[A, nav[B]]` / `nav[A, nav[S], nav[B]]` full-frame, SA `[59,0,34,0]` | didCollapse only | equal |
| compact column mounted | `topColumn(3)`, willShow(3), didShow(3), didCollapse; array `[C]`, no column navigation controllers exist | array `[A]`, navs created | equal |
| mode sweep | mode stays 2, preferred behaviour 1/2/3 | same | same |
| `show(.primary)` | pops with willHide(2) … didHide(2) | popped, no callbacks | equal |
| `show(.secondary)` double / triple from `nav[A]` | willHide(0) … didHide(0) / willShow(1), willHide(0), willHide(1), willShow(2) … didHide(1), didShow(2), didHide(0) | ignored | equal |
| `show(.supplementary)` from `nav[A,nav[S],nav[B]]` | pops B: willHide(2) … didHide(2) | ignored | equal |
| `hide(.secondary)` | pops with willShow(0) … didShow(0); `hide(.primary)` ignored | ignored | equal |
| collapsed showDetail from `nav[A]` | replace + push: willHide(0), willShow(2) … didShow(2), didHide(0) | replaced slot only | equal |
| collapsed `setViewController(F, secondary)` | replaced in place, no callbacks | same | same |
| collapsed `setViewController(nil, secondary)` | leaves an empty navigation controller pushed, willHide/didHide(2) | pops | **not reproduced** (1 skipped row) |
| expand into 393 pt regular | willChangeTo(1) then `displayModeForExpanding(1)` → secondaryOnly, secondary full-frame, getters 320/320 | mode 2, getters negative | equal |
| legacy mounted / expand | `collapseSecondary` false: willShow(0), willHide(0), willShow(2), didCollapse, didShow(2), didHide(0) / willChangeTo(1), `separate…`, willShow(2), didExpand, didShow(2) | didCollapse only | equal |

The did-phase order varied between runs of the same scene on iOS (e.g.
double collapse `didHide(0), didCollapse, didShow(2)` vs triple
`didShow(2), didCollapse, didHide(0), didHide(1)`); the port fixes one order
and the test compares the did-phase as a multiset, the will-phase as an
exact sequence, and `isCollapsed` / the public array inside every callback.

## 4. Implementation

`Sources/OpenUIKit/UISplitViewController.swift` (412 → 830 lines):

- Column geometry in `_layoutColumns`: floating `.sidebar` primary
  (x 10, y safe-top, bottom margin 15 at window safe-bottom 25, safe-area
  bottom 10), full-frame beside column with safe-area left `width + 10`
  via `_setSafeAreaInsets`, `.none` tiled with the 0.5 pt separator,
  triple twoBeside/explicit-twoOver widening the supplementary by
  `primary + 10`, overlays on a full secondary. Width getters cap at the
  464 pt secondary minimum before minimum/maximum (only while positive).
- Containers (column navigation wrappers) are created lazily and retained
  across transitions; `_setStack` rebuilds the collapsed navigation stack
  through the port's push/pop (no `setViewControllers` exists).
- `traitCollectionDidChange` drives `_collapse` / `_expand`; both fire the
  measured delegate order, keep `isCollapsed` false inside will* and true
  inside did* (and the reverse on expand), nest the columns up to the
  chosen top, install the compact column, and re-parent on expand. Legacy
  splits go through `primaryViewController(for…)`, `collapseSecondary`,
  `separateSecondaryFrom`.
- Collapsed `show` / `hide` / `showDetailViewController` push and pop with
  their callbacks; `show` with an automatic preference records the natural
  preference without a behaviour write; expanded `show`/`hide` suppress
  the column callbacks; explicit preference changes fire them.
- The split now drives its containers' appearance transitions itself (the
  port does not forward appearance to children).

## 5. Gates

| gate | result |
|---|---|
| `swift test --filter UISplitViewFramesTests` on the previous source | **731 assertion failures** (2 tests) |
| `swift test --filter 'UISplitViewFramesTests\|UISplitViewControllerTests\|UISplitViewWidthTests'` | **21/21**; `SPLIT_FRAMES ipad compared 79 skipped 0`, `iphone16 compared 78 skipped 1`; `SPLIT_WIDTH_MATCHED 805/805` |
| `--filter 'TabBarControllerTests\|TabBarControllerDelegateTests\|ViewControllerLayoutTests\|ViewControllerLifecycleTests\|UIPageViewControllerTests\|UISplitView'` | **65/65** (TabBar 4, TabBarDelegate 1, ViewControllerLayout 8, ViewControllerLifecycle — the `NavigationControllerTests.swift` suite — 15, UIPageViewController 16, split 21) |
| classifier re-run (`ladder_census.py` + `union_and_imports.py` + `classify_gaps.py` on a two-app corpus with the current type list, 433 names) | WordPress-iOS blocking **5 / 26** (`UITextItem` 12, `UIPopoverPresentationControllerSourceItem` 10, `NSTextTab` 2, …), NetNewsWire **2 / 50** (`NSToolbarItem` 48, `NSMenuToolbarItem` 2); no split row; union `UISplitViewController` ours, 2 apps / 36 uses |
| merge check `CHECK_ONLY=1 agent_merge.sh agent/wordpress-splitview` | see §7 |

## 6. Store-only / unmeasured

- `presentsWithGesture`, `showsSecondaryOnlyButton`, `displayModeButtonVisibility`,
  inspector widths, `primaryEdge`: stored, no behaviour.
- `show(_:sender:)` on a column-style split: iOS loaded and appeared the
  controller somewhere the probe could not see (no child change); the port
  only loads the split view.
- Collapsed `setViewController(nil, for: .secondary)` (empty pushed nav).
- The oneBeside-fits boundary between 393 (secondaryOnly) and 600
  (oneBeside): the port uses 464.
- `.none` background in a three-column tiled layout, other window sizes,
  animated/interactive transitions, sidebar material, the display-mode
  button, and the inspector column. No pixel claim.

## 7. Merge check

Recorded below once the CHECK_ONLY run reports.
