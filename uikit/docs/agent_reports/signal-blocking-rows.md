# Signal-iOS top-3 blocking UIKit rows

Branch `agent/signal-blocking-rows`, 2026-09-09. Task: APP_LADDER §9.6 lists
Signal-iOS with three BLOCKING rows — `UICoordinateSpace` (13 uses),
`UIScrollEdgeElementContainerInteraction` (12), and
`UICollectionViewLayoutInvalidationContext` (6). Check staleness first, then
implement what is really missing against the iOS 26.1 oracle.

## 1. Stale-row check

| row | in `uikit/Sources/OpenUIKit` at origin/main | landed | in `gap-classes-2026-09-16.json` Signal blocking list |
|---|---|---|---|
| `UICoordinateSpace` | `UICoordinateSpace.swift` (57 lines, 5 tests) | 1244733d, 2026-09-07 | absent |
| `UICollectionViewLayoutInvalidationContext` | `UICollectionViewLayoutInvalidationContext.swift` (55 lines, 10 tests) | c781adea, 2026-09-07 | absent |
| `UIScrollEdgeElementContainerInteraction` | not present | — | present, 12 uses |

Two of the three rows are stale prose in §9.6: the 2026-09-16 classifier
already lists only `UIScrollEdgeElementContainerInteraction` for Signal.

**What Signal's uses need** (corpus `scratch/ladder-corpus/Signal-iOS`,
read-only):

- `UICoordinateSpace` — 13 protocol-typed parameters
  `mediaPresentationContext(item:in coordinateSpace:)`, each ending in
  `coordinateSpace.convert(view.frame, from: superview)`. Covered by the
  existing UIView conformance. The two `translation(in: coordinateSpace)`
  sites pass a `UIView`. Nothing uses `UIScreen.coordinateSpace`; it was
  still absent from the port (UIScreen was not an NSObject), so it was
  measured and added as the completion of the type's surface.
- `UICollectionViewLayoutInvalidationContext` — 6 layout subclasses
  override `invalidateLayout(with:)` calling super and
  `shouldInvalidateLayout(forBoundsChange:)` (ConversationViewLayout
  returns true always; StickerHorizontalListView compares heights);
  ConversationViewLayout builds a context with `contentOffsetAdjustment`
  and calls `invalidateLayout(with:)`, and overrides `invalidateLayout()`
  noting "this method will call invalidateLayout(with:)". The class and
  adjustments were already measured; the port's collection view only asked
  `shouldInvalidateLayout` on a SIZE change, ignored scrolls, and called
  a plain `invalidateLayout()` without the bounds context. That ordering
  is what was measured and fixed.
- `UIScrollEdgeElementContainerInteraction` — 12 sites, all
  `init()`, `edge = .top|.bottom`, `scrollView = tableView|collectionView|
  scrollView`, `container.addInteraction(_:)` under `#available(iOS 26)`,
  with the scroll view inset by the container heights.

## 2. Probe recipe

`Tools/oracle2/signalrowsprobe/` (README there). `main.swift` +
`scripts/signal_rows_probe_sim.sh`: one app, three sections, phases marked
by files so the script can take `simctl io screenshot` between them:

- **invalidate.\*** — a tracing `UICollectionViewLayout` and
  `UICollectionViewFlowLayout` attached to a 200×300 collection view with 2
  items, then: frame size change, same frame, frame move, bounds set,
  `contentOffset`, `setContentOffset(animated: false)`, each with
  `shouldInvalidateLayout` answering true and false. Every callback logs
  the collection view's bounds at that moment, the `newBounds` argument,
  the context flags, and whether the context object handed to
  `invalidateLayout(with:)` is the one `invalidationContext(forBoundsChange:)`
  produced.
- **screen.\*** — `UIScreen.main.coordinateSpace` / `fixedCoordinateSpace`
  identity, type, bounds; the coordinatespaceprobe hierarchy under a window
  converted to and from the screen space, rotated; an offset window.
- **edge.\*** — interaction defaults, edge storage, weak scroll view;
  container/scroll tree before and after attach; window snapshot pixels;
  trigger isolation (label, glass, plain strip, opaque background).

`edge.swift` + `scripts/signal_edge_probe_sim.sh`: Signal's exact order
(containers with labels, interactions attached in `viewDidLoad`, insets
160/120), phases rest → under 60/0/100 → bottom under/rest → re-attach →
`.hard` → `.automatic` → hidden/shown edge → dark style → elements removed.
`profiles.py` reduces the screenshots to 1 pt columns (committed).

## 3. Oracle table

### Bounds-change invalidation (iPhone 16 / iOS 26.1)

| scenario | callbacks, in order (cv.bounds at the call) |
|---|---|
| frame 200×300 → 220×300, answer true | shouldInvalidate(OLD) → boundsContext(OLD) → invalidateLayout(NEW) → invalidateLayout(with: SAME ctx, NEW) → **prepare synchronously** |
| same, answer false | shouldInvalidate(OLD) only |
| contentOffset (0,0) → (0,40), answer true | shouldInvalidate(OLD) → boundsContext(OLD) → invalidateLayout(NEW) → invalidateLayout(with: SAME) → **prepare on the layout pass** |
| same, answer false | shouldInvalidate(OLD) only |
| bounds (5,6,200,300), answer true | full chain, prepare on layout |
| setContentOffset(animated:false), true | full chain; cv.bounds still OLD at invalidateLayout (not modelled) |
| frame set to the same rect | nothing |
| flow: context flags | everything/counts false, metrics false; attributes TRUE for a size change or a cross-axis move ((0,-59)→(5,6)), FALSE for an along-axis scroll ((0,-59)→(0,40)) |

Port before: asked only on size change, never on scroll; called
`invalidateLayout()` with a fresh context; flow attributes true for any
origin change. After: `UICollectionView.bounds` `willSet` asks and fetches
the context on the old bounds, `didSet` stashes it in
`UICollectionViewLayout._pendingBoundsContext` so `invalidateLayout()` →
`invalidateLayout(with:)` receives it (Signal's `invalidateLayout()`
override calling super sees UIKit's chain), prepares synchronously for a
size change, and leaves scroll tiling to the layout pass the invalidation
queued.

### UIScreen coordinate spaces

| measurement | iOS 26.1 | port after |
|---|---|---|
| `coordinateSpace` | the `UIScreen` object, stable, not a view, not the window | same |
| `fixedCoordinateSpace` | `_UIScreenFixedCoordinateSpace`, distinct, bounds (0,0,393,852) | same class name, distinct, screen bounds |
| child (8,9) → screen / back | (55,85) / (−39,−67); rects (55,85,30,40) / (−39,−67,30,40) | equal |
| screen (8,9) → child / from child | (−39,−67) / (55,85) | equal |
| rotated child → screen | (135,95); rect (95,95,40,30); back (−78,106,40,30) | equal (1e-9) |
| window at (10,20), inner (5,6): (8,9) → screen / main window / nil | (23,35) / (23,35) / (13,15); screen → inner (−7,−17) | equal; `UIView.convert(to:)` now adds window frame origins across hierarchies |
| screen → fixed | identity | identity |

### UIScrollEdgeElementContainerInteraction

| measurement | iOS 26.1 | port after |
|---|---|---|
| `init()` | NSObject; `edge` rawValue 0; `scrollView` nil, weak; `view` nil | same |
| `edge` storage | .bottom 4, [.top,.bottom] 5, .left 2 | same |
| attach to empty container | container frame/subviews/sublayers/mask/filters/background unchanged; superview subviews unchanged; `interactions` gains a private `_UIScrollPocketInteraction`; scroll subviews unchanged | tree unchanged; private interaction not added; no pocket |
| attach with a label (or glass) inside | scroll view gains two `_UITouchPassthroughView`s (one per edge); a plain `UIView` strip or an opaque background does not | one `_UITouchPassthroughView` pocket per attached edge, element rule: any descendant not exactly `UIView` |
| pixels at rest (offset −160 == −inset) | raw content | pocket hidden |
| pixels 60/100 pt under, x 380 (Signal order) | black scrim: red (255,0,0) → (192,0,0) (α 0.247) flat from the outer edge to ~60 pt before the inner edge, then to 232 at 139 pt, ~0 twenty points past the edge; ~6 pt content blur at band boundaries; footer mirrored (192–195 over the band, 229 at 16 pt inside, 246 at the edge, 254 sixteen points past) | scrim from the alpha table (−20:0, −16:.004, −8:.016, 0:.035, 8:.063, 16:.10, 56:.235, 60:.247), no blur |
| `drawHierarchy` snapshot | never shows the effect | n/a |
| `.hard` | flat LIGHT scrim (230 over black) to 30 pt before the inner edge, then hard cut | recorded only |
| `.automatic` after `.hard`, or attach to an empty container then add elements | light scrim (213 over black) + strong blur, fades to 1 at ~180 pt | recorded only |
| `topEdgeEffect.isHidden = true` | raw content | not modelled (no `UIScrollEdgeEffect` in the port) |
| elements removed | raw content; pockets remain in the tree | pocket hidden (removed on detach) |

## 4. Gates

```
swift test --filter "CollectionBoundsInvalidationTests|UIScrollEdgeElementContainerInteractionTests|UIScreenCoordinateSpaceTests"
  17 tests, 0 failures (8 + 5 + 4)
  failing-first: with UICollectionView/Layout/FlowLayout sources stashed,
  CollectionBoundsInvalidationTests: first assertion fails ("[]" vs the
  5-event chain), suite aborts; the other two suites do not compile
  without the new types.
swift test --filter "UICoordinateSpaceTests|CollectionBlockingTypesTests|CollectionViewTests|CollectionViewControllerTests|CollectionViewControllerCoderTests|UIPointerInteractionTests|SheetInteractionTests|UIEditMenuInteractionTests|FlowLayoutMeasured|CompositionalLayout|TableView|ScrollView"
  159 tests, 0 failures
full/ladder/classify_gaps.py (census regenerated from Sources at this branch)
  Signal-iOS blocking: 6 types / 21 uses → 5 types / 9 uses
  (UITab 3, UINavigationBarDelegate 2, NSIndexPath 2, UICornerConfiguration 1, UIBarPositioning 1)
```

Merge check (`CHECK_ONLY=1 agent_merge.sh agent/signal-blocking-rows`):
first run stopped in the Foundation-hidden guest route — `import class
ObjectiveC.NSCoder` does not exist there (NSCoder is the module's own) —
after 124/124 Catalyst; fixed in d8900660. Second run: 124/124 Catalyst,
guest route, test bundle, real-app screens, conformance apps, Linux build,
`checks passed (CHECK_ONLY)`.

## 5. Walls left

- Content blur under the scrim (no blur in the renderer,
  `docs/KNOWN_GAPS.md`); the light material variants; left/right edges.
- `UIScrollEdgeEffect` (`topEdgeEffect.style/isHidden`) does not exist in
  the port, so an app hiding the effect keeps the scrim.
- `setContentOffset(animated: false)` invalidates before the bounds move on
  iOS; the port moves first.
- The synchronous `prepare()` after a size change is guarded like `retile`
  (data source set, non-empty bounds).
