# EnergyKit (Linux starting point)

This is a clean-room Linux starting implementation of Apple's public
`EnergyKit` surface for OpenUIKit, seeded from the Xcode 26.1 iPhoneOS 26.1
symbol graph and API digester. Isolated host compilation produces
`libEnergyKit.dylib`. It is not Apple Home energy, electricity guidance, or
vehicle/HVAC telemetry, and it is not wired into the shared guest package.

Host-compiled sources import **Foundation only**. CoreLocation is named by the
digester import list but is not a declared fan-out dependency; home matching
fails closed instead of importing a lookalike.

## What is real

- **Value types.** `EnergyVenue`, `ElectricityGuidance` (including `Query`,
  `Value`, `SuggestedAction`, `Options`), HVAC and vehicle load events (session
  snapshots, guidance state, measurements), `ElectricityInsightQuery`, and
  `ElectricityInsightRecord` store the documented fields. Codable types
  round-trip through property-name keys.
- **Enums / option set.** `EnergyKitError`, session `State` (`begin` / `end` /
  `active` in digester order), `SuggestedAction`, `ElectricityGuidance.Options`
  (`CaseIterable`), `ElectricityFlowDirection`, and
  `ElectricityInsightQuery.Granularity` are hashable. Insight query `Options` is
  an `OptionSet` with `cleanliness = 1 << 0` and `tariff = 1 << 1`.
- **Protocols.** `ElectricalLoadEventProtocol` and `ElectricityInsightMeasure`
  are empty marker protocols. `Duration` and Foundation `Measurement` conform
  to the insight measure protocol; HVAC and vehicle events adopt the load
  event protocol.
- **Units.** `UnitEnergy.EnergyKit.milliwattHours` is `1 mWh = 3.6 J`. Linux
  `UnitEnergy` is final, so the nested type subclasses `Dimension`.
- **Errors.** `EnergyKitError` is `LocalizedError` + `Equatable` + `Hashable`.
  Help anchors are `nil`. Descriptions are host-honest, not Apple copy.

`libEnergyKit.dylib` compiles with `-warnings-as-errors`.

## Fail-closed boundaries

- `EnergyVenue.venues()` throws `serviceUnavailable`.
- `EnergyVenue.venue(for:)` throws `venueUnavailable`.
- `EnergyVenue.venue(matchingHomeUniqueIdentifier:)` throws
  `locationServicesDenied`.
- `submitEvents` throws `invalidLoadEvent` for an empty batch or empty
  `deviceID`, otherwise `serviceUnavailable`.
- `ElectricityGuidance.Service.guidance(using:at:)` returns a sequence whose
  first `next()` throws `guidanceUnavailable`.
- `ElectricityInsightService.energyInsights` / `runtimeInsights` throw
  `serviceUnavailable` and never yield invented records.

## Deferred / unobserved

- Actor `assertIsolated` / `assumeIsolated` / `preconditionIsolated` are
  **declared**: they trap unless the caller is already isolated to the insight
  actor, and the sealed runner has no run loop.
- Apple's exact error strings, option-set bits, Codable keys, guidance stream
  timing, and `UnitEnergy.EnergyKit` subclass identity (see
  `oracle-questions.tsv`).

## Tests

- `tests/agent/EnergyKitLoadSmoke.swift` — canonical schema-v2 marker
- `tests/agent/EnergyKitDependencyIdentity.swift` — Foundation `UUID` /
  `Date` / `DateInterval` / `Measurement` through public APIs
- Focused `tests/agent/*Tests.swift` — top-level synchronous `test*` probes
  (no stdout, no run-loop waits)

Sealed gate: `bash full/energykit/tests/acceptance/test_host.sh`

## Depth pass 2026-09

Coverage: **253 implemented / 3 declared / 0 deferred / 0 unavailable /
0 not-applicable** (256 exact IDs).

Top-5 implemented evidence distribution:

1. `EnergyKitErrorTests.swift#testEnergyKitErrorCases` — 10 rows (error cases)
2. `ElectricityInsightQueryTests.swift#testInsightQueryGranularityCases` — 6
3. `ElectricityGuidanceTests.swift#testGuidanceOptionsCases` — 4
4. `ElectricHVACLoadEventTests.swift#testHVACSessionStateCases` — 4
5. `ElectricVehicleLoadEventTests.swift#testVehicleSessionStateCases` — 4

No non-enum test is cited by more than 40% of the remaining implemented rows.
The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this
snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`;
Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 /
linux and the sealed gate compiles with a clean product tree.
