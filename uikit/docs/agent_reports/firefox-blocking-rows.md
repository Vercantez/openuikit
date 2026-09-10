# firefox-ios: the §9.6 blocking rows, measured

Branch `agent/firefox-blocking-rows`, 2026-09-09. Task: the three top
BLOCKING UIKit rows APP_LADDER §9.6 lists for firefox-ios —
`UISwipeGestureRecognizer` (10), `UIToolbarDelegate` (2),
`NSCollectionLayoutAnchor` (2) — checked for staleness first, then the real
ones implemented from the iOS 26.1 simulator.

## Stale-row check

| row | verdict | evidence |
| --- | --- | --- |
| `UISwipeGestureRecognizer` 10 | **stale prose** | `Sources/OpenUIKit/UISwipeGestureRecognizer.swift` landed in `a1c0c6b9` ("Implement iOS-measured swipe recognition for 54 blocking uses") with `Tools/oracle2/swipeprobe/ios-26.1.txt` and 10 tests. `full/ladder/gap-classes-2026-09-16.json` (commit `6c38af9f`, the same checkout as the prose) has **zero** occurrences of the name; its firefox-ios blocking list is `UIToolbarDelegate 2 · NSCollectionLayoutAnchor 2 · UIMenuBuilder 2 · UICommandAlternate 1 · UITextItem 1` = 5 types / 8 uses, while §9.6 prints "6 / 18". The table row is the JSON plus the swipe row. firefox's 10 uses (`TabTraySelectorView`, `SwipeUpTabPreviewGestureHandler`, `SummarizeController`) need `init(target:action:)`, `.direction` with `.Direction` up/down/left/right, and a `#selector` handler — all present. |
| `UIToolbarDelegate` 2 | **real** | no declaration anywhere under `uikit/Sources`; neither `UIBarPosition` nor `UIBarPositioning` existed. Uses: `TabTrayViewController` conforms (implements nothing) and assigns `toolbar.delegate = self`; `TestableUIToolbar` exposes `var delegate: UIToolbarDelegate?` forwarded to a real `UIToolbar`. |
| `NSCollectionLayoutAnchor` 2 | **real** | no declaration; `NSCollectionLayoutSupplementaryItem` had only `layoutSize:elementKind:` and `NSCollectionLayoutItem` had no `supplementaryItems`. Uses: `TabsSectionManager` ×2 — `NSCollectionLayoutSupplementaryItem(layoutSize: fractionalWidth(1) × absolute(h), elementKind:, containerAnchor: NSCollectionLayoutAnchor(edges: [.bottom]))` inside `NSCollectionLayoutItem(layoutSize:supplementaryItems:)`, in a `horizontal(layoutSize:subitem:count:)` group. |

Corpus read from `~/openuikit/scratch/ladder-corpus/firefox-ios` (present,
read-only).

## Probe recipe

`Tools/oracle2/firefoxrowsprobe/main.swift`, one file, no Xcode project.
From `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-firefox-blocking-rows scripts/firefox_rows_probe_sim.sh /tmp/ff
```

`swiftc -target arm64-apple-ios26.0-simulator`, minimal Info.plist, an
iPhone 16 / iOS 26.1 device `OpenUIKit-FirefoxRows<suffix>` (created,
booted, deleted afterwards), `simctl launch --console-pty`, JSON copied out
of `Documents/`. Each phase rewrites the JSON so a late crash keeps earlier
rows — which mattered: the first anchor phase threw (below). The unedited
transcript is `ios-26.1-iphone16.json`; the README lists every row.
`probe --hold <position>` keeps one toolbar on screen for `simctl io
screenshot`, because `drawHierarchy` does not capture iOS 26 bars.

## Oracle table

### UIToolbarDelegate / UIBarPosition

| observation | iOS 26.1 | port before | port after |
| --- | --- | --- | --- |
| `UIBarPosition` any/bottom/top/topAttached | 0/1/2/3 | type absent | 0/1/2/3 |
| `UIToolbar.delegate` | `UIToolbarDelegate?`, nil, weak | absent | same |
| `barPosition`, no delegate, detached and in window | bottom / bottom | absent | bottom / bottom |
| `position(for:)` calls after set / detached read / add / layout / 2nd layout | 0 / 0 / 1 / 1 / 1 | — | 0 / 0 / 1 / 1 / 1 |
| `barPosition` in window for answer any / bottom / top / topAttached | bottom / bottom / top / topAttached | — | same |
| delegate conforming without `position(for:)` | 0 calls, bottom | — | same |
| bar passed to the delegate | the toolbar | — | the toolbar |
| pixel effect of the position (opaque red bg, blue shadow, render-server screenshot, x 5 and x 196, y 290–350) | none: platters only, no red, no blue, identical for every position | n/a | nothing painted differently |
| `sizeThatFits` / `intrinsicContentSize` height | 48 / 48 | 54 / 54 | unchanged — not this row; noted |
| `UINavigationBar` default | top | no `barPosition` | unchanged — not a firefox row |

### NSCollectionLayoutAnchor (item `[30, y, 125, 100]`, badge 20×20)

| case | iOS 26.1 | port before | port after |
| --- | --- | --- | --- |
| `[.bottom]` fractionalWidth(1) × 30 (firefox) | `[30, y+70, 125, 30]` | no supplementary emitted | `[30, y+70, 125, 30]` |
| `[.top, .trailing]` | `[135, y]` | — | `[135, y]` |
| … fractionalOffset (0.5, −0.5) | `[145, y−10]` | — | same |
| … absoluteOffset (10, −10) | `[145, y−10]` | — | same |
| `[]` / `.all` / `[.leading, .trailing]` | `[82.667, y+40]` | — | same (3x) |
| `[.leading]` abs (5, 5) | `[35, y+45]` | — | same |
| `[.bottom]` fractional (0, 0.5) | y+90 | — | same |
| `[.top]` abs (0, −7) | y−7 | — | same |
| item anchor `[.bottom, .leading]` on corner | `[155, y−20]` | — | same |
| … + abs (3, 4) | `[158, y−16]` | — | same |
| item anchor `[]` fractional (0.5, 0.5) | `[155, y]` | — | same |
| item contentInsets 10 | container = inset item `[40, y+10, 105, 80]`, badge `[125, y+10]` | — | same |
| fractionalWidth(0.5) × fractionalHeight(0.25), bottom-trailing | `[92.667, y+75, 62.333, 25]` | — | same (origin snapped, far edge kept) |
| zIndex badge / cell; index path | 1 / 0; (section, item) | — | same |
| `subitem:count: 2` of an absolute-100 item in a 270 pt group | two 125 pt items | two 100 pt items (equal split only for fractional widths) | two 125 pt items |
| `subitems: [item, item]` with a supplementary | throws `NSInternalInconsistencyException` "Every supplementary must have a unique elementKind" | silently laid out | unchanged (no throw); recorded |
| contentSize, 15 sections | 300 × 2660 | — | 300 × 2660 |

Not measured: RTL anchors — the oracle's `forceRightToLeft` collection view
mirrored nothing at all (items included), so the `anchors.rtl` rows equal
the LTR rows and prove nothing; the port mirrors leading/trailing and the
x offset by its existing `_layoutIsRTL` convention, labelled unmeasured.

## What changed (all under `uikit/`)

- `Sources/OpenUIKit/UIBarPositioning.swift` (new): `UIBarPosition`,
  `UIBarPositioning`, `UIBarPositioningDelegate` (+ default `.any`),
  `UIToolbarDelegate`.
- `Sources/OpenUIKit/UIToolbar.swift`: `delegate` (weak), `barPosition`,
  one `position(for:)` call in `didMoveToSuperview`.
- `Sources/OpenUIKit/UICollectionViewCompositionalLayout.swift`:
  `NSCollectionLayoutAnchor`; `NSCollectionLayoutItem.supplementaryItems`
  and its initializer; `NSCollectionLayoutSupplementaryItem`
  `containerAnchor` / `itemAnchor` / `zIndex` and both initializers; per-item
  supplementary placement (scrolls and clips with its item in orthogonal
  sections); repeating-count equal split; `zIndex` on attributes;
  `layoutAttributesForSupplementaryView` matches per-item index paths.
- `Sources/OpenUIKit/UICollectionView.swift`:
  `layoutAttributesForSupplementaryElement(ofKind:at:)`,
  `visibleSupplementaryViews(ofKind:)`; `supplementaryView(forElementKind:at:)`
  finds a per-item view at its own index path.
- `Tests/OpenUIKitTests/FirefoxBlockingRowsTests.swift`:
  `ToolbarDelegateTests` (6) and `CollectionLayoutAnchorTests` (7), every
  number a transcript row. Failing-first: the whole file failed to compile
  against main (the types did not exist); one expectation I wrote wrong
  (inset item y) was corrected FROM the transcript row, not the port.
- `Tools/oracle2/firefoxrowsprobe/` (probe, README, transcript),
  `scripts/firefox_rows_probe_sim.sh`.

## Gates

```
swift test --filter "ToolbarDelegateTests|CollectionLayoutAnchorTests"
  13 tests, 0 failures
swift test --filter "ToolbarDelegateTests|CollectionLayoutAnchorTests|BarButtonItemTests|BarItemLayoutTests|NavigationItemTests|BarButtonActionTests|BarAppearanceTests|NavigationToolbarTests|CompositionalLayoutTests|FlowLayoutMeasuredTests|CollectionViewReuseTests|CollectionViewBehaviourTests|ListCellDiffable|TapGestureTests|PanGestureTests|LongPressGestureTests|UISwipeGestureRecognizerTests|CollectionViewControllerTests|CollectionBlockingTypesTests"
  135 tests, 0 failures (13 new + 122 existing; swipe 10, tap 4, pan 4, long-press 4, toolbar/bars 44, compositional 7, collection 49)
```

Ladder classifier re-run for the worktree's declared types (`remeasure`
scan regex over `Sources/OpenUIKit`, frozen corpus and SDK list,
`ladder_census.py` → `union_and_imports.py` → `classify_gaps.py`; the
scripts take the whole corpus, so all 20 apps were re-classified and
firefox-ios read out):

| firefox-ios | before (`gap-classes-2026-09-16.json`) | after |
| --- | --- | --- |
| blocking | 5 types / 8 uses: `UIToolbarDelegate 2 · NSCollectionLayoutAnchor 2 · UIMenuBuilder 2 · UICommandAlternate 1 · UITextItem 1` | **3 / 4**: `UIMenuBuilder 2 · UICommandAlternate 1 · UITextItem 1` |
| stub-able | 9 / 24 | 9 / 24, unchanged |

Merge check: `CHECK_ONLY=1 uikit/scripts/agent_merge.sh agent/firefox-blocking-rows`
run twice. On `8427d5a0` it went `LINUX BUILD RED`: the new test file
carried a bare `@MainActor` on the XCTestCase, so `setUp` could not touch
an instance property on Linux; `8daa9778` gates the isolation with the
neighbouring suites' `#if !os(Linux)`. On `8daa9778`:

```
checks passed (CHECK_ONLY)
```

(Catalyst goldens, real-app floors, conformance re-render and the Linux
`openrender` build all inside the script; no REFUSED.)

## Walls and leftovers

- firefox's remaining blocking rows are `UIMenuBuilder` (2),
  `UICommandAlternate` (1), `UITextItem` (1); a browser engine stays outside
  the declaration score (§9.6).
- `UIToolbar` intrinsic height: the oracle reads 48 for a 44 pt-framed bar
  with three items; the port carries 54 from `golden/toolbar_basic`. Not
  this task's row; left for the bars owner.
- The compositional layout does not raise on duplicate supplementary kinds
  the way iOS does; recorded in the probe README, not reproduced.
- §9.6's prose is stale for firefox-ios (and its "shared reach" line still
  counts `UISwipeGestureRecognizer` 10 apps / 54 uses); `full/` is outside
  this branch's write scope, so the ladder text was not edited.
