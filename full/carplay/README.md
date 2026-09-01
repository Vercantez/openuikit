# Portable CarPlay (Linux starting point)

This is a **large-partitioned** starting implementation of Apple's public
`CarPlay` module for OpenUIKit on Linux. It is sourced from the pinned
Xcode 26.1 iPhoneOS symbol graphs. It is not Apple behavioral parity and it
does not claim a vehicle, CarPlay daemon, or entitlement grant.

## What is real

- Template, list, grid, tab, alert, information, contact, search, voice,
  now-playing, map, and point-of-interest **object models** are constructible
  and inspectable in-process.
- `CPInterfaceController` keeps an in-memory navigation stack and a separate
  presented-template slot. Push, pop, present, and dismiss mutate that stack
  and notify `CPInterfaceControllerDelegate`.
- Enumerations, option sets (`CPContentStyle`, `CPLimitableUserInterface`,
  `CPManeuverDisplayStyle`, `CPMapTemplate.PanDirection`), public size/count
  constants, and `NSStringFromCP*` helpers are implemented.
- Navigation types (`CPTrip`, `CPManeuver`, `CPTravelEstimates`,
  `CPNavigationSession`, `CPNavigationAlert`) store guidance state locally.
  Pause/finish/cancel change an explicit portable trip state; they never talk
  to a head unit.
- `CPNowPlayingTemplate.shared` is a process-local singleton.

When UIKit or MapKit are not imported, the module provides fail-closed stand-ins
for `UIImage`, `UIColor`, `UIWindow`, `UIScene`, `MKMapItem`, and related types
so the CarPlay surface compiles on the Linux Swift 6.2.4 toolchain.

## What is fail-closed

- **Vehicle session**: `CarPlayPortable.supportsVehicleSession` is `false`.
  `CPInterfaceController.portableConnectedToVehicle` starts `false`. No scene
  delegate `didConnect` callback is fired by this module.
- **Entitlements**: template, audio, maps, and communication entitlements are
  reported false. There is no path that pretends the process is CarPlay-signed.
- **Instrument cluster / dashboard windows**:
  `CPInstrumentClusterController.instrumentClusterWindow` is always `nil`.
  Dashboard and cluster scenes exist as objects only.
- **UI / map rendering**: no CarPlay display, map renderer, or Now Playing
  system UI is presented. Panning and trip preview APIs only flip in-memory
  flags.
- **`NSSecureCoding`**: `init?(coder:)` returns `nil`. Apple archives are not
  reconstituted.

Host SPI (`@_spi(OpenUIKitHost)`) exposes `CPInterfaceController(portableRoot:)`
and button/list invoke helpers so a Linux shell can drive the stack without
claiming a car accepted it.

## Still deferred / oracle-owned

Exact Apple point sizes, `NSStringFromCPManeuverType` string payloads, raw
`NS_ENUM` integer assignments for newer maneuver cases, NSCoder layouts,
and vehicle-side limited-UI transitions are recorded in
`oracle-questions.tsv`.
