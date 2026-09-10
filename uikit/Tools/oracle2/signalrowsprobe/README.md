# Signal-iOS blocking-row oracle

Measured 2026-09-09 on a private iPhone 16, iOS 26.1 / 23B86, 393×852 @3x.
Run from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-x scripts/signal_rows_probe_sim.sh /tmp/signal-rows   # main.swift
SIM_DEVICE_SUFFIX=-x scripts/signal_edge_probe_sim.sh /tmp/signal-edge   # edge.swift
python3 Tools/oracle2/signalrowsprobe/profiles.py /tmp/signal-edge /tmp/signal-rows profiles.json
```

Both scripts leave the app idle at named phases, take `simctl io screenshot`
(the render server; `drawHierarchy` snapshots never show the scroll-edge
effect) and continue on an `.ack` file. Committed outputs:

- `ios-26.1-iphone16.json` — `main.swift`: `invalidate.*` (bounds-change
  invalidation ordering for a base and a flow layout, 8 scenarios each),
  `screen.*` (UIScreen coordinate spaces, offset window), `edge.*`
  (interaction state, container/scroll tree before and after attach,
  trigger isolation: label, glass, plain strip, opaque background).
- `edge-ios-26.1-iphone16.json` — `edge.swift`: Signal's setup order
  (containers with labels, interaction attached at `viewDidLoad`, insets
  160/120), 13 phases from rest through re-attach, `.hard`, `.automatic`,
  hidden edge effect, dark style and element removal.
- `profiles-ios-26.1-iphone16.json` — RGB per point row at x = 380 pt for
  the screenshot phases the port encodes (scrim alpha table) and the
  light-variant evidence. Regenerable from the PNGs with `profiles.py`.

What the port took from it is written above the code:
`UICollectionView.bounds` (ordering), `UICollectionViewFlowLayout
.invalidationContext(forBoundsChange:)` (attribute flag axis rule),
`UIScrollEdgeElementContainerInteraction.swift` (state, pocket, scrim
profile, recorded-but-unmodelled variants), `UIScreen.coordinateSpace` and
`UIView.convert` across windows. Report:
`docs/agent_reports/signal-blocking-rows.md`.
