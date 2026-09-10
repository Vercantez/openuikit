# UIScrollEdgeEffect oracle

Measured 2026-09-10 on a private iPhone 16, iOS 26.1 / 23B86, 393×852 @3x.
Run from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-x scripts/scroll_edge_effect_probe_sim.sh /tmp/edge-effect
python3 Tools/oracle2/scrolledgeeffectprobe/profiles.py /tmp/edge-effect profiles.json
```

One app, 96 phases, each left idle for a `simctl io screenshot` (the
render server — `drawHierarchy` never shows the effect) and continued on
an `.ack` file; the app writes the phase list to `phases.txt` so the
script needs no copy of it. Content is 75 black/red 40 pt bands (3000 pt)
so a 1 pt column reads the effect's alpha directly.

- `scroll.*` / `table.*` / `collection.*` — a UITabBarController holding
  three UINavigationControllers (inline titles) whose roots are a plain
  UIScrollView, a UITableViewController and a UICollectionViewController:
  rest, a content-offset sweep past the top safe edge (0.5…64 pt) and short
  of the bottom rest, 100 pt under, `.hard` / `.soft` / `.automatic` on each
  edge, `isHidden` per edge and both.
- `toolbar.*` — window-root navigation controller with a toolbar (items).
- `large.*` — `prefersLargeTitles` table: 12 / 40 / 160 pt, hard, hidden.
- `interaction.*` — navigation bar + a 100 pt label-holding container with
  a `UIScrollEdgeElementContainerInteraction` on the same scroll view.

Committed outputs:

- `ios-26.1-iphone16.json` — per phase: offset, insets, safe area, the
  four `UIScrollEdgeEffect`s (style identity, hidden, object pointer,
  class), and at the rest / mid / hard / hidden phases the window tree
  filtered to scroll views, bars and Apple's `ScrollEdgeEffectView`
  subtree (frames, alpha, hidden, filters). `fresh` holds the unattached
  read-back and the style singletons.
- `profiles-ios-26.1-iphone16.json` — RGB per point row at x = 380 pt,
  rows 0–259 and 620–851, for 77 phases (table / collection kept where the
  port encodes them; `kind_vs_scroll_differing_rows` records that every
  table / collection phase equals the scroll view's except the unstable
  untouched-automatic material).

What the port took from it is written above the code:
`UIScrollEdgeEffect.swift` (state, geometry, the hard plate, thresholds),
`UIScrollEdgeElementContainerInteraction.swift` (hidden / hard routing),
`UINavigationBar.updatePocket`, `UITabBar.layoutBottomEdgeEffect`. Report:
`docs/agent_reports/scroll-edge-effect.md`.
