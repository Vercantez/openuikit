# CarPlay (Linux starting point)

This is a **large-partitioned** starting implementation of Apple's public
`CarPlay` module for OpenUIKit on Linux. It is sourced from the pinned
Xcode 26.1 iPhoneOS symbol graphs. It is not Apple behavioral parity and it
does not claim a vehicle, CarPlay daemon, or entitlement grant.

This module **does not redefine UIKit or MapKit types**. When those modules are
staged, CarPlay imports their real identities (`UIImage`, `UIColor`, `UIWindow`,
`UIScene`, `MKMapItem`, and related types). On the isolated Swift 6.2.4 Linux
host those modules are absent, so UIKit- and MapKit-typed members are compiled
out with `canImport`.

## What is real

- Foundation-typed template, list, tab, alert, information, search, now-playing,
  and map **object models** are constructible and inspectable in-process.
- `@_spi(OpenUIKitHost)` `connectHostVehicleSession` / `disconnectHostVehicleSession`
  injects a process-local vehicle session. Template-stack mutation runs only
  while that session is connected.
- Enumerations and option sets (`CPContentStyle`, `CPLimitableUserInterface`,
  `CPManeuverDisplayStyle`, `CPMapTemplate.PanDirection`) are implemented.
- `CPNowPlayingTemplate.shared` is a process-local singleton; observers are
  stored weakly.
- `CarPlayErrorDomain` is the public error-domain string.

## What is fail-closed

- **Vehicle session**: disconnected by default. Void presentation APIs no-op.
  Async/completion stack APIs throw `CarPlayHostError.vehicleSessionDisconnected`
  (or return `false` for `dismissNavigationAlert`). They do not claim a
  successful vehicle presentation.
- **UIKit / MapKit**: imported when present; never recreated locally.
- **Instrument cluster / dashboard windows**:
  `instrumentClusterWindow` is always `nil` on this host.
- **UI / map rendering**: no CarPlay display or map renderer is presented.
  Panning and navigation-alert APIs only update in-memory flags while a host
  session is connected.
- **`init?(coder:)`**: returns `nil`. This port does not advertise
  `NSSecureCoding` and does not round-trip archives.
- **Constants / limits / `NSStringFrom*`**: identifiers compile, but values are
  unattested zeros or `String(describing:)` placeholders until an Apple oracle
  attests them. Templates do not truncate to guessed maximums.

`CarPlayPortable`, `CarPlayPortableError`, `CarPlayCodingObject`, and
`portable*` members are not part of the public API.

Host SPI (`@_spi(OpenUIKitHost)`) also exposes handler invocation, a
Foundation-only navigation-alert fixture, and synthetic UIKit/MapKit fixtures
for integrated hosts.

## Still deferred / oracle-owned

Exact Apple point sizes, list/tab/action ceilings, `NSStringFromCP*` payloads,
NSCoder layouts, and vehicle-side limited-UI transitions are recorded in
`oracle-questions.tsv`.

`tests/agent/CarPlayDependencyIdentity.swift` is an integrated-client probe for
a future EC2 run that stages real guest Foundation, UIKit, and MapKit. The
isolated `test_host.sh` gate does not compile or run that file and is not
evidence of integrated Linux success.
