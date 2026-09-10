# Split-view column geometry and collapse/expand delegate-order oracle

Measured 2026-09-09 (local), iOS 26.1 / 23B86, on private simulators:
iPad (A16) 820×1180 @2x (regular width, expanded) and iPhone 16 393×852 @3x
(compact width, collapsed). No PNG goldens were added or edited.

Reproduce from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-wordpress-splitview SPLIT_SIM_DEVICE=ipad     scripts/splitframes_probe_sim.sh /tmp/splitframes-ipad
SIM_DEVICE_SUFFIX=-wordpress-splitview SPLIT_SIM_DEVICE=iphone16 scripts/splitframes_probe_sim.sh /tmp/splitframes-iphone16
```

`main.swift` runs nine scenes as the window root (`double`, `triple`) or as a
child of a plain host controller whose iOS 17 `traitOverrides.horizontalSizeClass`
flips the size class (`transition.*`). Every step mutates one split, waits
0.7 s, and appends a settled record to `splitframes.json`: state, the public
array and children, each column's container (frame, absolute frame, safe
area, whether it is inside the split view, whether the split parents it) and
every delegate / child-lifecycle event in the order it fired, each delegate
event tagged with `isCollapsed`, `displayMode` and the public array at that
moment. `ios26.1-ipad.json` and `ios26.1-iphone16.json` are the raw
transcripts, 79 records each. The first run crashed at the legacy scene:
`preferredSplitBehavior` and `primaryBackgroundStyle` raise
`NSInvalidArgumentException` ("requires -initWithStyle:") on a legacy split,
like `splitBehavior`; the probe reads them only for column styles.

## Measured and implemented (Tests/OpenUIKitTests/UISplitViewFramesTests.swift replays every record)

- **Geometry (iPad, window safe area [32,0,25,0]).** A `.sidebar` primary
  floats at `[10, 32, w, 1133]` with safe-area bottom 10; the column beside it
  is full-frame with safe-area left `w + 10`. `.none` tiles instead:
  primary `[0,0,320,1180]`, secondary `[320.5,0,499.5,1180]`. Tiled
  neighbours are separated by 0.5 pt. Fraction 0.5 resolves 346 (double,
  `820 − 10 − 464`) and 355.5 (triple supplementary, `820 − 0.5 − 464`); the
  cap applies before minimum/maximum (min 375/max 400 → 375, max 300 → 300).
  Triple at 820 cannot tile three columns: twoBeside/twoDisplace resolve
  twoOver with the primary floating over supplementary `[0,0,320,1180]` and
  secondary `[320.5,0,499.5,1180]`; an explicit twoOver widens the
  supplementary to `320 + 280 + 10 = 610` (getter and frame) with safe-area
  left 290 while the secondary is full-frame. oneOver overlays the
  supplementary on a full-frame secondary; secondaryOnly removes the other
  columns from the hierarchy.
- **Expanded delegate order.** A preferred-mode change fires willChangeTo,
  willHide/willShow per changed column, child appearance, then
  didHide/didShow. `show(_:)` / `hide(_:)` fire only willChangeTo.
  showDetail and setViewController replace the secondary without callbacks.
- **Collapse (trait override regular→compact).**
  `topColumnForCollapsingToProposedTopColumn` (2, or 3 with a compact column)
  then, for top secondary: willHide(1), willShow(0), willHide(2), willHide(0),
  willShow(2) · didShow(2), didCollapse, didHide(0), didHide(1); the column
  navigation controllers nest as `nav[A, nav[S], nav[B]]`. A delegate
  answering `.primary` leaves `nav[A]` alone with the other navigation
  controllers detached. A compact column replaces every column controller as
  the only child: willHide(1), willShow(3), willHide(2) · didHide(1),
  didCollapse, didShow(3), didHide(2). `isCollapsed` is true and the public
  array is `[A]` / `[C]` inside every did* callback and false inside will*.
- **Expand.** `displayModeForExpandingToProposedDisplayMode`, willShow of
  columns not on top, willHide of a top that the mode hides, then
  didHide/didExpand/didShow with `isCollapsed` false. willChangeTo precedes
  it when the mode changes (a 393 pt regular window resolves secondaryOnly).
- **Legacy style.** Collapse: `primaryViewController(forCollapsing)`,
  `collapseSecondary(onto:)`; false pushes the secondary onto the primary
  navigation controller (willHide(2), willHide(0), willShow(2) · didHide(0),
  didCollapse, didShow(2)); true drops it (willHide(2) · didCollapse,
  didHide(2)). Expand: `primaryViewController(forExpanding)`,
  `separateSecondaryFrom`; nil pops the top controller as the secondary.
  Collapsed showDetail pushes the raw controller after the delegate hook
  with willHide/didHide of the column on top.
- **iPhone 16 (compact at mount).** willChangeTo(2), topColumn(2)→2,
  willShow(0), willHide(0), willShow(2), didCollapse, didShow(2), didHide(0);
  `show(.primary)` pops with willHide/didHide of the popped column,
  `show(.secondary)` pushes the intermediate columns (triple: willShow(1),
  willHide(0), willHide(1), willShow(2) · didHide(1), didShow(2), didHide(0);
  double: willHide(0) · didHide(0)), `hide(.secondary)` pops with
  willShow(0)/didShow(0). Collapsed showDetail replaces the secondary and, if
  another column was on top, pushes it (willHide(top), willShow(2) ·
  didShow(2), didHide(top)).

## Explicit remaining gaps

The did-phase order varied between runs of the same scene (e.g. double
collapse `didHide(0), didCollapse, didShow(2)` vs triple `didShow(2),
didCollapse, didHide(0), didHide(1)`); the port fixes one order and the test
compares the did-phase as a multiset. The boundary where an expanded width
stops fitting one beside column lies between 393 (secondaryOnly) and 600
(oneBeside) and is unmeasured; the port uses the 464 secondary minimum.
`setViewController(nil, for: .secondary)` while collapsed leaves an empty
navigation controller pushed on iOS; the port pops it (one skipped row).
`show(_:sender:)` on a column-style split loads the controller somewhere the
probe could not see (no child changes); the port does nothing beyond loading
the split view. The floating sidebar material, the display-mode button,
interactive/animated transitions, the inspector column, `.none` tiled
three-column widths, and column frames on other window sizes remain
unmeasured. The split does not claim pixel fidelity.
