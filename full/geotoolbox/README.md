# GeoToolbox (Linux starting point)

Clean-room Linux starting point for Apple's public `GeoToolbox` module,
seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph, API digester, TBD
exports, and the pinned external-evidence lock. This directory is not wired
into the shared guest package.

`libGeoToolbox.dylib` compiles with `-warnings-as-errors` under the sealed
host gate.

## What is real

- `PlaceDescriptor` stores `representations`, `commonName`, and
  `supportingRepresentations`. The public initializer defaults
  `supportingRepresentations` to `[]`.
- `PlaceRepresentation` cases `.address(String)`, `.coordinate(CLLocationCoordinate2D)`,
  and `.deviceLocation(CLLocation)` are constructible and `Equatable`.
- `SupportingPlaceRepresentation.serviceIdentifiers([String: String])`
  stores mapping-provider bundle-id keys.
- `address` returns the first `.address` payload in array order, or `nil`.
- `coordinate` returns the first `.coordinate` or `.deviceLocation` snapshot
  in array order, or `nil`.
- `serviceIdentifier(for:)` returns the first matching dictionary value in
  `supportingRepresentations` order.
- `Equatable` / `!=` for the struct and both enums compare stored payloads.
  `.deviceLocation` compares coordinate, altitude, accuracies, and
  timestamp (not NSObject identity).
- `Codable` round-trips a Linux-local JSON layout named after the public
  properties (`representations`, `commonName`, `supportingRepresentations`,
  and case keys `address` / `coordinate` / `deviceLocation` /
  `serviceIdentifiers`). This is not claimed as Apple's on-wire format.
- `UnwrappedType` and `ValueType` alias `PlaceDescriptor`.
- `persistentIdentifier` returns `"PlaceDescriptor"` (Linux type-name
  stand-in for the App Intents default).

Isolated-host `CLLocationCoordinate2D` / `CLLocation` lookalikes live in
`GeoToolbox.swift` and compile out when `CoreLocation` is importable.

## Fail-closed boundaries

- No MapKit `MKMapItem` conversion (`init(item:)` is not in the 34-symbol
  census). Linux does not invent Apple Maps lookup or place cards.
- `.deviceLocation` only stores a `CLLocation` the caller already has. There
  is no GPS, Core Location daemon, or live device fix.
- App Intents `DisplayRepresentation`, `TypeDisplayRepresentation`,
  `ResolverSpecification` / `Specification`, `defaultResolverSpecification`,
  and `localizedStringResource` are deferred: App Intents is not a
  declared dependency and `LocalizedStringResource` is absent from
  Linux Foundation 6.2.4.
- Ambiguous or empty `PlaceRepresentation` JSON throws `DecodingError`
  instead of guessing a case.
- TBD-only names (`wellKnownName`, `placeRepresentations`,
  `_placemarkData`) are not published.

## Deferred / oracle

See `oracle-questions.tsv` for Apple Codable keys, empty-`representations`
init policy, `coordinate` vs `.deviceLocation`, `serviceIdentifier` collisions,
`persistentIdentifier` string, and App Intents presentation.

## Tests

- `tests/agent/GeoToolboxLoadSmoke.swift` — canonical schema-v2 marker
- `tests/agent/*Tests.swift` — focused `test*` probes (no stdout)
- `tests/agent/GeoToolboxDependencyIdentity.swift` — Foundation `String` and
  `Date` through public `PlaceDescriptor` APIs

Keep generated products out of the tree. Run
`bash tests/acceptance/test_host.sh` from this directory or
`bash full/geotoolbox/tests/acceptance/test_host.sh` from the repo root.

## Depth pass 2026-09

This is a fresh seed: the directory had `AGENTS.md`, `FANOUT_TASK.md`, and
`reference/` only. This pass implements **29** exact public identifiers as
`implemented` (0 declared / 5 deferred / 0 unavailable / 0 not-applicable).
Nondeferred count is 29 (floor 28).

Top-5 evidence distribution after this pass (of 29 implemented rows):

1. `testPlaceRepresentationCases` — 3 rows (10.3%) (table-driven enum cases)
2. `testPlaceDescriptorType` — 1 row (3.4%)
3. `testPlaceDescriptorInit` — 1 row (3.4%)
4. `testPlaceDescriptorAddress` — 1 row (3.4%)
5. `testPlaceDescriptorCoordinate` — 1 row (3.4%)

Row 1 is the enum-member table. No other single test is cited by more than
40% of the remaining implemented rows.

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`343270ce44481a5ae11b87a6e0713e396ada1ef2` matched.

`bash full/geotoolbox/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=GeoToolbox lane=leaf-full symbols=34
FRAMEWORK_FANOUT_REFERENCE_OK
GEOTOOLBOX_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=GeoToolbox dylib=libGeoToolbox.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.
