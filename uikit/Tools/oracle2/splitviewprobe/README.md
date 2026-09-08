# Split-view programmatic oracle

Measured 2026-09-07 (local), iOS 26.1 / 23B86, on private iPad A16
820×1180 @2x and iPhone SE (3rd generation) 375×667 @2x simulators.
The source writes its transcript after every observation, including before
intentional invalid-argument probes. No PNG goldens were added or edited.

Reproduce from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-uikit-blocking-types-split SPLIT_SIM_DEVICE=ipad scripts/splitview_probe_sim.sh /tmp/split-ipad
SIM_DEVICE_SUFFIX=-uikit-blocking-types-split SPLIT_SIM_DEVICE=2x scripts/splitview_probe_sim.sh /tmp/split-se
SIM_DEVICE_SUFFIX=-uikit-blocking-types-split SPLIT_PROBE_CASE=detail-routing scripts/splitview_probe_sim.sh /tmp/split-detail
```

`SPLIT_PROBE_CASE=legacy-splitBehavior`, `double-supplementaryWidth`, or
`duplicate-column` reproduces the intentional exception cases in separate
processes; their messages are in `ios26.1-exceptions.txt`. The detail-routing
case presents a modal in its own process and exits without running any later
scene, respecting the modal capture hazard.

## Measured and implemented

- All seven public enum families, the negative greatest finite **Float**
  automatic-dimension sentinel, lazy construction, configuration defaults,
  and primary width preference/absolute/minimum/maximum relationships.
- Legacy and column assignment retain original controllers, without loading
  views or adding children before appearance. The compact column is excluded
  from the public expanded array. Clearing a slot releases it. A controller
  already occupying another column is rejected.
- Legacy appearance contains direct children; column styles wrap plain
  controllers in navigation controllers. The SE collapses the public array
  to the primary, retains column queries, nests secondary navigation inside
  primary navigation, and gives primary/supplementary widths the full 375 pt.
- Compact display mode remains 2 through all six requested display modes;
  requested modes still change preferred split behavior. `show(.primary)`
  pops the compact navigation stack; `hide(.primary)` leaves it unchanged.
- Legacy `show`/`showDetail` consult a weak delegate; column styles bypass
  these legacy hooks. Descendant `showDetail` routes to the split delegate.
  Standalone `showDetail` presents the supplied controller.
- `UIViewController.splitViewController` walks ancestors, excluding self.

## Explicit remaining gaps

This is programmatic API/containment coverage, **not split-view pixel
fidelity**. Expanded child views currently use a basic container. The iOS 26
floating primary chrome, safe-area propagation, backdrop, and supplementary
separator are not reproduced. The oracle records primary absolute frames
`[10,32,320,1133]` and `[10,32,280,1133]` with a full-frame secondary in the
820×1180 double-column sample; those numbers were not fitted into a rule.

The triple-column mode sweep at 820 pt is carried, but wider buckets,
transitions across size classes, full display-mode resolution, exact child
callback order, display-mode button rendering/action, inspector presentation,
compact-controller presentation, supplementary width changes in overlays,
and the full show/hide-column transition matrix remain open. The delegate
protocol exposes compatibility callbacks, but only measured mode, collapse,
and legacy show/detail callbacks are dispatched by this implementation.
Do not read a census type becoming present as proof those remaining members
or every app using the type now work.

Validation: `swift test -j 4 --filter UISplitViewControllerTests` covers the
public observations; integration/Catalyst/iOS/Linux gates are recorded by
the parent branch report.
