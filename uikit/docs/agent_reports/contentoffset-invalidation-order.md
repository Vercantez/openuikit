# contentOffset entry points: the invalidation order per path

Branch `agent/contentoffset-invalidation-order`, 2026-09-10. Task: the
signal-blocking-rows report (2026-09-09) fixed UICollectionView's
bounds-change invalidation chain and left one ordering wall — on iOS
`setContentOffset(_:animated: false)` invalidates the layout BEFORE the bounds
move while the port moved first. Measure every way the offset can move and
fix the port's order to the measured one.

## 1. Probe recipe

`Tools/oracle2/signalrowsprobe/offset.swift` +
`scripts/contentoffset_order_probe_sim.sh` (iPhone 16 / iOS 26.1 / 23B86).
A 200×300 collection view (40 items of 200×40 at a 50 pt pitch, content
2000 tall) with a tracing base layout and a tracing flow layout, a tracing
`UICollectionView` subclass (layoutSubviews enter/exit), a tracing data
source (cellForItem) and delegate (scrollViewDidScroll, willBeginDragging,
didEndScrollingAnimation); the same for a 100-row 44 pt table. Every
callback records a sequence number, milliseconds since the entry point, the
view's `bounds` at the moment of the call, the `newBounds` argument or the
query rect, and a phase: `sync` (inside the entry point), `after` (after it
returned, before the first display-link tick), `frameN`, or `touchK.phase`
(inside the K-th synthetic touch delivery — KIF-style private `UITouch`
delivery, as in `scrollshared.swift`). Entry points, each on a fresh view:
`setContentOffset(animated: false/true)`, `contentOffset =`, `bounds =`,
`scrollRectToVisible(animated: false/true)`, `scrollToItem(.top,
animated: false/true)`, a finger drag (down, three 15 pt moves, a 250 ms
hold, lift — the hold kills the release velocity, but iOS still decelerates
from the last move's velocity, so ~60 deceleration frames follow), and for
the table `setContentOffset`, `contentOffset`, `scrollRectToVisible`,
`scrollToRow` and the drag. Committed transcript:
`Tools/oracle2/signalrowsprobe/offset-order-ios-26.1-iphone16.json`
(compact JSON, 27 scenarios, every callback row; `python3 -m json.tool`
pretty-prints it).

## 2. Oracle table (iPhone 16 / iOS 26.1)

Bounds shown as the y origin the callback observed; `H` is the view height.

| entry point | inside the call | after the call |
|---|---|---|
| `bounds = (0,40)` | shouldInvalidate(**0**, arg 40) → boundsContext(**0**) → invalidateLayout(**40**) → invalidateLayout(with: same ctx, **40**) — **no scrollViewDidScroll** | layoutSubviews → prepare(40) → layoutAttributesForElements(rect) → cellForItem 6 |
| `contentOffset = (0,40)` | the same chain, then **scrollViewDidScroll(40)** after invalidateLayout(with:) | the same layout pass |
| `setContentOffset((0,40), animated: false)` | shouldInvalidate(**0**, arg 40) → boundsContext(**0**) → invalidateLayout(**0**) → invalidateLayout(with:, **0**) → bounds move → scrollViewDidScroll(40) | the same layout pass |
| `scrollRectToVisible((0,300,200,40), false)` | identical to setContentOffset; target 40 = maxY − H (table: (0,300,200,44) → 44) | same |
| `scrollToItem(6, .top, false)` | identical; target 300 | prepare(300) → layoutAttributesForElements((0,300,200,300)) → cellForItem 6…11 |
| `setContentOffset(true)` / `scrollRectToVisible(true)` / `scrollToItem(true)` | shouldInvalidate(**0**, arg **TARGET**) → boundsContext(**0**) → invalidateLayout(**0**) → invalidateLayout(with:, **0**); bounds still 0 at return, no didScroll | a layout pass on the old bounds (prepare, layoutAttributesForElements(visible rect)); then per frame: shouldInvalidate(prev, arg this frame) → boundsContext → invalidateLayout(new) → invalidateLayout(with:) → scrollViewDidScroll → layoutSubviews/prepare/layoutAttributesForElements (+ one dequeue); 18 model steps over 0.3 s (0.67, 1.67, 3.33, 5.67 … 40); didEndScrollingAnimation on frame 18 |
| drag, first move (15 pt, 10 pt slop) | willBeginDragging(0) → shouldInvalidate(0, arg 5) → boundsContext(0) → invalidateLayout(5) → invalidateLayout(with:, 5) → scrollViewDidScroll(5) | — |
| drag, further moves with no layout pass in between | **scrollViewDidScroll only** (20, 35): the layout is already invalid, the question is not asked again | after the lift a layout pass prepares; then EVERY deceleration frame runs the full chain (64 chains for 66 didScrolls) followed by its own layout pass |
| table: `setContentOffset(false)` / `contentOffset =` / `scrollRectToVisible` / `scrollToRow(false)` | scrollViewDidScroll(new) only; `indexPathsForVisibleRows` already answers the new rows | layoutSubviews → cellForRow → willDisplay, with the new bounds; one row past the visible set is dequeued afterwards (row 8 at offset 35, outside layoutSubviews) |
| table: animated variants, drag | nothing synchronous (the animated ones dequeue the next row before the first frame); per frame scrollViewDidScroll then layoutSubviews | — |

Also measured, not modelled:

- **Query rect**: `layoutAttributesForElements(in:)` receives tiles of `H`
  — `(0,0,200,600)` for any y in (0, 300), `(0,300,200,300)` at exactly 300,
  `(0,300,200,600)` in (300, 376], and from y ≈ 377 a second query
  `(0,600,200,600)` on most frames; the first layout at 0 asks `(0,0,200,300)`.
  Only cells whose frame intersects the actual bounds are dequeued.
- **Prefetch**: one cell beyond the visible rect in the scroll direction is
  dequeued per frame (item 7 at offset 39, whose frame starts at 350; table
  row 8 at 35).
- A layout pass with nothing changed does not re-query
  `layoutAttributesForElements` (the second layoutSubviews pair per frame is
  empty).

## 3. Port before / after

Before: `UICollectionView.bounds` `willSet` asked and fetched the context,
the superclass setter moved the bounds AND sent `scrollViewDidScroll`, and
`didSet` invalidated — so every path invalidated after the move and the
delegate heard before `invalidateLayout(with:)`; `setContentOffset(animated:
false)` was just the direct set; a direct `bounds` set notified the delegate;
a second scroll before the layout pass asked again; `scrollRectToVisible`
did not exist (a comment referred to it).

After (`UIScrollView.swift`, `UICollectionView.swift`):

- `UIScrollView.setContentOffset` calls `_willSetContentOffset(offset,
  animated:)` with the final target before either branch; UICollectionView
  runs the whole chain there on the OLD bounds (with the target as the
  argument), then the bounds set that follows asks nothing and invalidates
  nothing more. `scrollRectToVisible` / `scrollToItem` route through it.
- `UIScrollView.bounds` `didSet` delegates its origin-change tail to
  `_boundsOriginDidChange(from:)`; UICollectionView overrides it to
  invalidate with the pending context BEFORE calling super (the delegate),
  and to retile after — so `invalidateLayout(with:)` precedes
  `scrollViewDidScroll` on the direct, drag and deceleration paths.
- `scrollViewDidScroll` (delegate and `_scrollObserver`) is sent only for a
  bounds change that came through `contentOffset`; a direct `bounds` set
  still runs the chain but stays silent.
- A bounds-driven invalidation that no `prepare()` has consumed silences
  the question (`boundsInvalidationPending`, cleared when the layout is
  prepared again; only when a layout pass can actually prepare — data
  source set, non-empty bounds); the change still waits for the layout pass.
- `UIScrollView.scrollRectToVisible(_:animated:)`: minimal scroll that
  brings the rect into the inset-adjusted visible area, clamped to the
  content, through `setContentOffset`.

The port's animated `setContentOffset` keeps its UIView animation block:
the synchronous chain is identical to iOS (old bounds, target argument), but
the model then jumps to the target inside the block (iOS steps the model per
frame) — recorded below.

## 4. Gates

```
swift test --filter ContentOffsetInvalidationOrderTests
  10 tests, 0 failures
  failing-first (UIScrollView.swift + UICollectionView.swift stashed, an
  empty scrollRectToVisible stub so the file compiles): 9 of 10 fail,
  22 assertion failures; only the animated-prefix test passes (its prefix
  already matched).
swift test --filter "CollectionBoundsInvalidationTests|CollectionViewTests|CollectionViewControllerTests|CollectionViewControllerCoderTests|FlowLayout|Compositional|TableView|ScrollView|UIScrollEdgeElementContainerInteractionTests"
  124 tests, 0 failures
```

Merge check: see the REAL_APP_TEST.md row.

## 5. Walls left

- **Animated model timing.** iOS steps `contentOffset` per frame (18 steps
  over 0.3 s, a chain + layout pass each); the port animates the
  presentation and jumps the model once, so a layout sees one chain and
  tiles the target immediately. Changing that means moving the animated
  scroll onto the host-clock stepper the deceleration already uses, and
  re-validating the Pager fling / page-view-controller goldens that are
  built on the presentation animation.
- **Tiling timing.** iOS dequeues at the layout pass after the entry point
  returns; the port tiles inside the setter for a scroll the layout did not
  invalidate (collection view) and always for the table — the same cells,
  one run-loop turn earlier. Eleven table and twelve collection tests, and
  the host's event loop (no layout pass inside `tick`), rely on it.
- The tile-aligned query rect and the one-cell prefetch (above) are not
  modelled; the port asks for the visible rect and dequeues visible cells.
- The port re-queries `layoutAttributesForElements` on every layout pass.
- `scrollRectToVisible` with non-zero insets and `bounds =` on a table were
  not measured.
