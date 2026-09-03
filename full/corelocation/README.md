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
- Authorization requests without a host grant fail closed to `.denied`.
- Location, heading, and circular-region delivery are host-injected through
  `@_spi(OpenUIKitHost)` and are synchronous.
- `CLGeocoder` fail-closes to `geocodeFoundNoResult` unless a host handler is
  installed. Completions run on the calling thread.
- `CLError` / `CLLocationPushServiceError` are `Foundation._BridgedStoredNSError`
  wrappers. Raw values follow the public overlay and pinned `dotnet/macios`
  annotations (`PromptDeclined = 18`, push-service unknown=0 through
  unsupportedPlatform=4).
- Ranging, visits, deferred updates, temporary full-accuracy, and location
  pushes are declared and fail closed (no BLE, no visit daemon, no push
  extension).
- `CLLocationUpdate.liveUpdates` yields one diagnostic update (`location == nil`,
  `authorizationDenied`, `locationUnavailable`) and finishes.
- `CLMonitor` stores conditions and records; its `events` stream never invents
  hardware transitions.

`Date`, `UUID`, `NSNumber`, `NSCoder`, and `Locale` values are toolchain
Foundation types. On a later EC2 integration build they are the real guest
Foundation types.

## Fail-closed boundaries

Linux has no CoreLocation daemon, GNSS, compass, iBeacon radio, or geocoder.

- Unauthorized `requestLocation` reports `denied`.
- Authorized `requestLocation` without a cached host location reports
  `locationUnknown`.
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
