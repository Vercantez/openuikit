# HealthKit (Linux starting point)

This directory is a clean-room Linux starting implementation of Apple's public
`HealthKit` module. Isolated host compilation produces `libHealthKit.dylib`.
It is not a claim of Apple Health store parity.

The canonical monorepo `reference/` dossier was kept (schema v1, generator
`2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`, Xcode 26.1).
The legacy `openuikit-linux-platform` branch could not be fetched from this
environment (GitHub App installation scope is `Vercantez/openuikit` only), so
this lane is implemented from the pinned seed, public-surface graph, and the
pinned `dotnet/macios` HealthKit bindings under `$OPENUIKIT_MACIOS_ROOT`.

## What is real

- String constants (`HKErrorDomain` is `com.apple.healthkit`; other `HK*`
  strings equal their C identifier names). `HKObjectQueryNoLimit` is `0`.
- Enums and option sets. Raw values use the pinned macios Native enums where
  present (`HKAuthorizationStatus`, `HKMetricPrefix`, `HKError.Code`,
  `HKWorkoutActivityType` including `other = 3000`, and others).
- Quantity and category type identifiers whose `rawValue` is the graph C name
  (`HKQuantityTypeIdentifierHeartRate`, …).
- `HKUnit` SI conversion: metric prefixes, mass/length/time/energy/temperature
  affine conversion, multiply/divide/raise.
- `HKQuantity` compatible conversion and comparison.
- Local `HKObject` / `HKSample` / `HKQuantitySample` / `HKCategorySample` /
  `HKWorkout` / `HKSource` / `HKDevice` construction.
- `HKObjectType` factories and quantity aggregation style for a closed
  cumulative identifier set.
- `HKQuery` predicate factories that return `NSPredicate(value: false)`
  (no Health store, so they never match).
- `HKHealthStore`: `isHealthDataAvailable()` is `false`; authorization stays
  `.notDetermined`; save/delete/execute/requestAuthorization fail closed with
  `HKError.Code.errorHealthDataUnavailable`.

## Fail-closed / not invented

- No Apple Health database, no Health app UI, no entitlement grant, no Watch
  workout session, no clinical records / FHIR, no CoreLocation workout routes.
- Query descriptors and async sequences are type shells only.
- `HKUnit.unit(_:)` does not reverse-engineer arbitrary Apple unit strings.

## Deferred

See `coverage.tsv`. Query descriptors, attachments, ECG voltage streams,
clinical/FHIR, vision prescriptions, live workout builders, and CoreLocation
route APIs remain deferred. `CoreLocation` and `UniformTypeIdentifiers` are
not importable in this isolated `swiftc` gate. Predicates that take
`NSComparisonPredicate.Operator` are deferred because that type is unavailable
on Linux Foundation. Medication-dose, user-annotated-medication, and
verifiable-clinical-record predicate factories are also deferred.
