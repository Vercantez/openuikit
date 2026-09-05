# CarPlay (Linux starting point)

This directory is a fail-closed portable `CarPlay` module reconstructed from
the sealed Xcode 26.1 iPhoneOS public surface. It is not wired into the shared
guest package. A passing isolated host gate is not integrated Linux success
and is not Apple CarPlay behavioral parity.

The platform fan-out branch `cursor/port-carplay-to-linux-319e` (legacy PR #24)
was not readable from this environment: the GitHub App token is scoped to
`Vercantez/openuikit` only. This deliverable was produced from the monorepo
seed (`full/carplay/reference/` kept as-is; no older branch dossier was
available to compare). Enum raw values that match the pinned `dotnet/macios`
Native annotations are recorded as implemented; numeric image-size and
maximum-count constants compile as documented programming-guide values, not
Apple ABI bytes.

## What is real

- All 24 public enums, nested styles, and OptionSet types compile. Selected
  raw values (`CPAlertAction.Style`, `CPLaneStatus`, `CPManeuverType`,
  `CPJunctionType`, `CPTrafficSide`, `CPNavigationSession.PauseReason`,
  `CPContentStyle`, `CPLimitableUserInterface`, `CPMapTemplate.PanDirection`)
  match the pinned macios Native enums and are exercised by
  `tests/agent/CarPlayRuntime.swift`.
- `NSStringFromCPJunctionType`, `NSStringFromCPLaneStatus`,
  `NSStringFromCPManeuverType`, and `NSStringFromCPTrafficSide` return distinct
  local descriptions (Apple's exact C-string payloads are unobserved).
- `CPListItem` stores text/detail/enabled/userInfo and mutates through
  `setText` / `setDetailText` / `setImage`. Selection handlers run with a
  completion callback via `@_spi(OpenUIKitHost)`.
- `CPListSection` retains items and returns them from `item(at:)`.
- `CPListTemplate` retains sections; `updateSections` caps `itemCount` /
  `sectionCount` at the documented maxima (`maximumItemCount` 12,
  `maximumSectionCount` 12).
- `CPInterfaceController` keeps an in-process template stack after a simulated
  scene connect: `setRootTemplate`, `pushTemplate`, `popTemplate`,
  `popToRootTemplate`, `pop(to:)`, `presentTemplate`, and `dismissTemplate`
  enforce a depth of 5, presentable-template rules, and documented item limits.
  Delegate callbacks fire willDisappear → willAppear → didDisappear → didAppear.
- `CPNowPlayingTemplate.shared` is a process-local singleton. The MediaPlayer
  Now Playing bridge is declared and remain fail-closed (no
  `MPNowPlayingInfoCenter` session).
- `CPAlertAction` invokes its handler with `self`.
- `CPSessionConfiguration.limitedUserInterfaces` starts empty (no vehicle
  limited-UI session) until a host injects a simulated style.

## Fail-closed / deferred

- There is no CarPlay head unit, instrument cluster, or entitlement check.
  `CPDashboardController` and `CPInstrumentClusterController` store values but
  never present to a vehicle (`openuikit_vehiclePresentationActive == false`).
- `init?(coder:)` always fails; no NSCoder archive layout was observed.
- Isolated-host UIKit/MapKit/CoreLocation names (`UIImage`, `MKMapItem`,
  `UIWindow`, …) are compile-only stand-ins used when those modules cannot be
  imported. They are not UIKit or MapKit.
- Maximum image sizes and item counts are documented programming-guide values,
  not SDK-byte observations. Oracle questions record the missing payloads.

## Depth pass 2026-09

SDK depth for `CarPlay` in `full/carplay/` (988 IDs). No car head unit: the
template model and a simulated interface controller are implemented.

Coverage ledger repair after `FW_MERGE REFUSED` at `448e66fa` (988 implemented
rows cited `tests/agent/CarPlayRuntime.swift`, which is not
`test:full/carplay/tests/agent/<File>Tests.swift#testName`):

- Before: 988 implemented / 0 declared. Every implemented row pointed at the
  runtime probe file path, not a named `func test*()`.
- After: 977 implemented / 11 declared. Implemented rows cite a real
  top-level synchronous `func testName()` in `tests/agent/*Tests.swift`.
  The 11 declared rows are async/throws overloads (interface-controller
  completion variants, `dismissNavigationAlert(animated:)`, and async list /
  search delegate requirements) that a no-argument synchronous test cannot
  await.

Top-5 implemented evidence citations (977 implemented rows):

1. `CarPlayEnumTests.swift#testEnumOptionSetAndConstantValues` — 353 (36.1%).
   Table-driven enum / OptionSet / C-constant values (allowed to share).
2. `CarPlayMapTests.swift#testMapTemplateTripPreviewAndPanning` — 51 (5.2%).
3. `CarPlayListImageTests.swift#testListImageRowItemElements` — 48 (4.9%).
4. `CarPlayMapTests.swift#testManeuverLaneAndRouteInformation` — 36 (3.7%).
5. `CarPlayNowPlayingTests.swift#testNowPlayingSportsMode` — 32 (3.3%).

No other single test exceeds 40% of implemented rows (cap 390.8).

- `CPTemplateApplicationScene` / `CPTemplateApplicationSceneDelegate`: the
  documented `@_spi(OpenUIKitHost)` hook `openuikit_connectSimulatedSession`
  wires a simulated `CPInterfaceController` and `CPWindow`, sets
  `carTraitCollection` / `contentStyle`, and delivers connect callbacks.
  Disconnect restores fail-closed stack APIs.
- `CPInterfaceController`: `setRootTemplate` / `pushTemplate` / `popTemplate` /
  `popToRootTemplate` / `pop(to:)` / `presentTemplate` / `dismissTemplate`
  with stack depth 5, `CarPlayErrorDomain` errors, `templates` / `topTemplate` /
  `rootTemplate` / `presentedTemplate`, and ordered appear/disappear callbacks.
- Template validation from documentation: list sections/items via
  `CPListTemplate.maximumItemCount` (12) and `maximumSectionCount` (12);
  `CPGridTemplate` ≤ 8 buttons (`CPGridTemplateMaximumItems`);
  `CPTabBarTemplate.maximumTabCount` = 5 (some units 4, recorded as
  `someVehiclesMaximumTabCount`); `CPAlertTemplate.maximumActionCount` = 2;
  information templates cap 10 items / 3 actions; POI templates cap 12.
- `CPMapTemplate` with `CPMapButton` stores, trip previews, panning, navigation
  alerts, and `CPNavigationSession` state machine (navigating / paused /
  finished / cancelled) plus `CPTrip` / `CPRouteChoice` / `CPManeuver` /
  `CPTravelEstimates` value stores.
- `CPListItem` / `CPListImageRowItem` / `CPMessageListItem` handler invocation
  with completion; images via the port `UIImage`; `CPListItem.maximumImageSize`
  is 90×90.
- `CPNowPlayingTemplate.shared` buttons and observer fan-out; MPNowPlaying
  bridge declared fail-closed.
- `CPSessionConfiguration` `limitedUserInterfaces` / `contentStyle`.
- `CPDashboardController` / `CPInstrumentClusterController` fail closed.

Numeric size/count constants are documented process-local values, not SDK-byte
observations. Dashboard and instrument-cluster types are implemented as
fail-closed surfaces.

## Tests

`tests/agent/CarPlayRuntime.swift` is the sealed host-gate probe and prints
`CARPLAY_AGENT_RUNTIME_OK`. Focused behavioral evidence lives in
`tests/agent/*Tests.swift` as top-level synchronous `func test*()` functions
cited by `coverage.tsv`.

Expected isolated-host markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
CARPLAY_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CarPlay dylib=libCarPlay.dylib
```
