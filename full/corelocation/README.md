# CoreLocation (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`CoreLocation` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, and TBD exports. It is not wired into the shared guest package;
that integration is a later central-review step.

The original portable boundary (`CoreLocation.swift`, `CoreLocationObjC.m`,
`include/`) remains. Darwin mixed Clang/Swift consumers still use those files.
The isolated Linux host gate compiles only the Swift guest manifest.

## What is real

- Coordinates, WGS-84 ellipsoidal distance (Vincenty on WGS-84 with a haversine
  fallback), and `CLCircularRegion.contains` match the existing Apple Xcode 26.1
  geometry transcript (`nyc-london=5585234`, `equator-degree=111319`).
- `CLLocationManager.locationServicesEnabled()` is false unless
  `@_spi(OpenUIKitHost) _portableSetLocationServicesEnabled(true)`.
- Authorization requests without a host grant fail closed to `.denied`.
- Location, heading, and circular-region delivery are host-injected through
  `@_spi(OpenUIKitHost)` and are synchronous. Injected coordinates drive
  `didEnterRegion` / `didExitRegion` as well as `didDetermineState`.
- `headingAvailable()` is false; `startUpdatingHeading` reports
  `CLError.headingFailure` unless a later host inject supplies a `CLHeading`.
- `CLGeocoder` fail-closes to `geocodeFoundNoResult` unless a host handler is
  installed. Completions run on the calling thread.
- `CLMonitor` stores conditions and records; `events` stays empty until a host
  inject evaluates a `CircularGeographicCondition` (satisfied / unsatisfied).
- `CLError` / `CLLocationPushServiceError` are `Foundation._BridgedStoredNSError`
  wrappers. Raw values follow the public overlay and pinned `dotnet/macios`
  annotations (`PromptDeclined = 18`, push-service unknown=0 through
  unsupportedPlatform=4).
- Ranging, visits, deferred updates, temporary full-accuracy, and location
  pushes fail closed (no BLE, no visit daemon, no push extension).
- `CLLocationUpdate.liveUpdates` yields one diagnostic update (`location == nil`,
  `authorizationDenied`, `locationUnavailable`) and finishes.

`Date`, `UUID`, `NSNumber`, `NSCoder`, and `Locale` values are toolchain
Foundation types. On a later EC2 integration build they are the real guest
Foundation types.

## Fail-closed boundaries

Linux has no CoreLocation daemon, GNSS, compass, iBeacon radio, or geocoder.

- `locationServicesEnabled()` is false until the host grant.
- Unauthorized `requestLocation` / `startUpdatingLocation` reports `denied`.
- Authorized `requestLocation` without a cached host location reports
  `locationUnknown`.
- `headingAvailable()` is false; `startUpdatingHeading` reports `headingFailure`.
- Unauthorized `startMonitoring(for:)` reports `regionMonitoringDenied`.
- `isRangingAvailable()` is false; `startRangingBeacons` still records the
  request and fail-closes with `rangingUnavailable`.
- `init(coder:)` on `CLBeacon` / `CLHeading` / `CLPlacemark` / `CLRegion` /
  `CLVisit` returns nil. Apple's archive keys are unobserved.
- `CLBeaconRegion.peripheralData(withMeasuredPower:)` returns an overlay
  dictionary, not a claimed Apple CoreBluetooth advertisement payload.

## Deferred

- `geocodePostalAddress` and `CLPlacemark.postalAddress` need
  `Contacts.CNPostalAddress`. Substituting a local lookalike is forbidden.
- Swift.AsyncSequence protocol extensions (`map`, `filter`, …) and synthesized
  `!=` / `Hashable` witnesses are `not-applicable`; they are not redeclared here.

`tests/test_corelocation_host.sh` remains a Darwin/xcrun mixed-ABI gate and is
not runnable on this Linux VM.

Coverage on this branch: **435 implemented** / 3 deferred (Contacts
`CNPostalAddress` bridging) / 100 not-applicable. Isolated host cannot import
Contacts; those three rows stay deferred rather than shipping a local lookalike.
