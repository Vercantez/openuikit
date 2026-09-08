# Collection controller and invalidation oracle

Measured 2026-09-07 on a private iPhone 16, iOS 26.1 / 23B86, 393×852 @3x.
Run from `uikit/`:

```sh
scripts/collection_blocking_probe_sim.sh /tmp/collection-state
scripts/collection_lifecycle_probe_sim.sh /tmp/collection-lifecycle
```

The state transcript pins invalidation list ordering/deduplication, empty
item and supplementary requests, adjustment values, generated flow flags,
lazy wrapper geometry, delegate wiring and retained initial layout identity.
`../collectionlifecycleprobe/ios-26.1-iphone16.json` adds 106 observations of
nil assignment and first/return appearance, including animated navigation.
The latter is necessary: calling `viewWillAppear` directly retains selection
for both preference values; a real appearance clears it at a later phase.
The port's container transition driver performs that clearing after the
nonanimated `viewWillAppear` or before animated `viewDidAppear`.

The portable layout has a full-invalidation cache; item/kind invalidations
record their exact requested paths but do not implement partial cache updates.
Content-size adjustment is immediate and the next prepare restores layout
size; offset adjustment clamps to the existing scrollable range. The measured
sample uses zero content insets. Self-sizing invalidation, decoration layout,
interactive reordering gestures, layout-to-layout navigation transitions and
nib/archive controller initialization remain open. The controller's two
required data-source methods fail unless a subclass implements them.

No PNG or existing layout golden is modified. Six existing collection scenes
and the complete iOS/Catalyst/app suites are the rendering regression checks.
