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
maximum-count constants compile but are **not** claimed as Apple ABI bytes.

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
  `setText` / `setDetailText` / `setImage`.
- `CPListSection` retains items and returns them from `item(at:)`.
- `CPListTemplate` retains sections; `updateSections` updates `itemCount` /
  `sectionCount` from the supplied arrays.
- `CPInterfaceController` keeps an in-process template stack: `setRootTemplate`,
  `pushTemplate`, `popTemplate`, `popToRootTemplate`, `presentTemplate`, and
  `dismissTemplate` are deterministic and do not talk to a head unit.
- `CPNowPlayingTemplate.shared` is a process-local singleton.
- `CPAlertAction` invokes its handler with `self`.
- `CPSessionConfiguration.limitedUserInterfaces` starts empty (no vehicle
  limited-UI session).

## Fail-closed / deferred

- There is no CarPlay head unit, instrument cluster, or entitlement check.
  Scene connect/disconnect, map panning, navigation session guidance, and
  dashboard windows do not become connected.
- `init?(coder:)` always fails; no NSCoder archive layout was observed.
- Isolated-host UIKit/MapKit/CoreLocation names (`UIImage`, `MKMapItem`,
  `UIWindow`, …) are compile-only stand-ins used when those modules cannot be
  imported. They are not UIKit or MapKit.
- Maximum image sizes and item counts are stable nonzero process-local values,
  not SDK-byte observations. Oracle questions record the missing payloads.

## Tests

`tests/agent/CarPlayRuntime.swift` is the host-gate probe and prints
`CARPLAY_AGENT_RUNTIME_OK`.

Coverage of the 988 sealed precise IDs: 82 implemented, 906 declared,
0 deferred. Numeric size/count constants compile but stay `declared`
because their Apple SDK bytes were not observed. Vehicle/scene types
compile as fail-closed declarations; they are not claimed as a connected
head unit.
