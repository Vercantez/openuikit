# Signal-iOS last-four blocking-row oracle

Measured 2026-09-10 on private simulators, iOS 26.1 / 23B86: iPhone 16
(393×852 @3x) and iPad (A16) (820×1180 @2x). Run from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-x scripts/signal_last_rows_probe_sim.sh /tmp/signal-last        # iPhone 16
SIM_DEVICE_SUFFIX=-x scripts/signal_last_rows_probe_sim.sh /tmp/signal-last-pad ipad
python3 Tools/oracle2/signallastrowsprobe/corners.py /tmp/signal-last corners.json
```

`main.swift` is one app with four sections; the script takes two
render-server screenshots (`simctl io screenshot`) of the corner grid on
`corners1` / `corners2` markers and continues on `.ack` files. Committed
outputs:

- `ios-26.1-iphone16.json`, `ios-26.1-ipad-a16.json` — the transcript:
  - `tabs.*` — `UITab` defaults and provider timing; `UITabBarController.tabs`
    set before view load, shown, badge/title propagation both ways,
    programmatic `selectedTab` / `selectedIndex` / `selectedViewController`,
    a simulated tap (`_UITabButton.sendActions` on the phone; no such
    control in the iPad tree, so the tap rows are empty there), vetoes by
    each delegate pair, subset → restore, a fresh-controller provider,
    legacy `viewControllers` after `tabs` and back, a legacy-only
    controller, `tabs = []`; `mode`, `sidebar.isHidden`, the view tree.
  - `nav.*` — a standalone `UINavigationBar` with a logging
    `UINavigationBarDelegate`: `position(for:)` timing, push / vetoed push /
    animated push, pop / vetoed pop / animated pop / last / empty,
    `setItems` non-animated, animated (pop-shaped and push-shaped), with a
    vetoing delegate, and nil; a back-button tap. Then a
    `UINavigationController` subclass conforming to the protocol: the bar's
    `delegate` identity, push, programmatic pop, back-button tap vetoed and
    allowed. `popItem` on the managed bar raises (crash report in the
    source) and is recorded as such.
  - `indexPath` — `NSIndexPath(item:section:)` / `(row:section:)`
    components, `as IndexPath` both ways, equality, description.
  - `corners.*` — a fresh view's configuration and layer; 20 views (12
    configurations at 5 sizes plus circular / continuous `cornerRadius`
    controls): `layer.cornerRadius` / `cornerCurve` / `maskedCorners`, the
    CALayer property list filtered to corner names and their values
    (`cornerRadii` is the private per-corner store), `description`, frame;
    then after a capsule resize and a `layer.cornerRadius = 30` write.
- `corners-ios-26.1-iphone16.json`, `corners-ios-26.1-ipad-a16.json` —
  `corners.py` over the screenshots: per view and corner the white area,
  the equivalent circular / continuous radius, the edge-row profile, and
  max channel differences between configured views and the same-size
  control views (0–1 against `.continuous`, up to 255 against `.circular`).
  The `uniform.concentricMin8` pixel row is not meaningful (its blue
  container reads as "covered" to the red/white reducer); the layer-state
  row (16) is the fact for that case.

What the port took from it is written above the code: `UITab.swift`,
`UITabBarController.swift` (file header), `UINavigationBar.swift`
(`delegate`, `barPosition`, `pushItem` / `popItem` / `setItems`),
`UINavigationController.swift` (`_backButtonTapped`, `pushViewController`),
`FoundationTypes.swift` (`NSIndexPath`), `UICornerConfiguration.swift`.
Report: `docs/agent_reports/signal-last-rows.md`.
