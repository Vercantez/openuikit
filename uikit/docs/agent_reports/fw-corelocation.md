# CoreLocation SDK depth — agent/fw-corelocation

Isolated Linux module `full/corelocation/`. No scene pixel rule.

## Before / after

| census | before | after |
|---|---|---|
| implemented | 345 | **435** |
| declared | 90 | **0** |
| deferred | 3 | 3 (Contacts `CNPostalAddress`) |
| not-applicable | 100 | 100 |
| total | 538 | 538 |

Target was implemented ≥ 430. Host gate: `FRAMEWORK_FANOUT_HOST_OK`, marker `CORELOCATION_AGENT_RUNTIME_OK`.

Geometry already on the seed, re-checked: NYC→London `Int(distance.rounded()) == 5_585_234`; equator 1° `== 111_319`.

## What changed

Every previously `declared` row now has a focused `test*` in
`tests/agent/CoreLocationTests.swift`. Three Contacts rows stay `deferred`:
the isolated host may import Foundation only and must not ship a local
`CNPostalAddress`.

Fail-closed rules (comments next to the code cite the tests):

- `locationServicesEnabled()` is **false** unless
  `@_spi(OpenUIKitHost) _portableSetLocationServicesEnabled(true)`.
- `headingAvailable()` is **false**; `startUpdatingHeading` reports
  `CLError.headingFailure`. A later host inject can still deliver a heading.
- Unauthorized / services-off `startUpdatingLocation` and `requestLocation`
  report `denied`. Authorized one-shot with no cached sample reports
  `locationUnknown`.
- Unauthorized `startMonitoring(for:)` reports `regionMonitoringDenied`.
- Host-injected coordinates drive `didEnterRegion` / `didExitRegion` as well
  as `didDetermineState`.
- `CLMonitor.events` stays empty until `_portableInject(location:)` evaluates
  a `CircularGeographicCondition` (Vincenty distance ≤ radius → `.satisfied`,
  else `.unsatisfied`).

`CLGeocoder` without a host handler still completes with
`geocodeFoundNoResult` (already recorded). The operator brief suggested
`CLError.network`; that swap is an open question, not a measurement.

`CLLocationSourceInformation` / `ellipsoidalAltitude` are not in the 538-ID
public-surface census (`LocationEssentials` extract is empty). Not declared.

Authorization callbacks stay synchronous on the calling thread. Linux has no
main runloop in the isolated host; dispatching to main would hang the gate.

## Open

- Contacts overlay for `geocodePostalAddress` / `CLPlacemark.postalAddress`
  on the EC2 integration build.
- Whether Apple's geocoder fail-closed code is `network` or
  `geocodeFoundNoResult` when no daemon exists.
- Queue for `locationManagerDidChangeAuthorization` on a real process with a
  main runloop.

## Pixel gates

No OpenUIKit render rule.

| gate | result |
|---|---|
| Isolated host | `FRAMEWORK_FANOUT_HOST_OK` / `CORELOCATION_AGENT_RUNTIME_OK` |
| Catalyst | **124/124** |
| iOS suite `SKIP_CAPTURE=1` | **112/113** (`corner_radius` 99.411, known) |
| Real-app floors | **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393** |
| Linux `swift:6.2-noble` openrender | green (225.40 s) |
