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

## Depth pass 2026-09

Wave-3 depth pass over the wave-2 starting point (1303 implemented / 258
declared / 1084 deferred). Public-surface IDs: 2645.

Coverage ledger repair (merge refused `e265036b` because implemented rows cited
source paths instead of `test:full/healthkit/tests/agent/<File>Tests.swift#testName`):

- **Before repair:** 2606 implemented / 0 declared / 0 deferred / 39 unavailable
- **After repair:** 1663 implemented / 943 declared / 0 deferred / 39 unavailable

Every `implemented` row now cites a real top-level synchronous `func testName()`
in `tests/agent/*Tests.swift`. Enums, option-set members, and C `HK*` constants
share table-driven value tests. Other APIs are split across 28 focused tests;
the largest non-table test is 15.1% of remaining implemented rows (under the 40%
bulk-relabel cap). Rows without a real focused assertion were reclassified to
`declared` with `source:full/healthkit/<file>.swift#Symbol`.

**Top-5 implemented evidence distribution**

| rows | evidence |
| ---: | --- |
| 520 | `test:full/healthkit/tests/agent/HealthKitEnumTests.swift#testEnumRawValues` |
| 407 | `test:full/healthkit/tests/agent/HealthKitConstantTests.swift#testCStringAndIdentifierConstants` |
| 109 | `test:full/healthkit/tests/agent/HealthKitEquatableTests.swift#testEnumEquatableAndHashable1` |
| 85 | `test:full/healthkit/tests/agent/HealthKitEquatableTests.swift#testEnumEquatableAndHashable2` |
| 72 | `test:full/healthkit/tests/agent/HealthKitEquatableTests.swift#testEnumEquatableAndHashable3` |

The first two are the allowed table-driven enum / C-constant tests.

## Depth pass 2026-09 (wave 8)

Second depth pass over the repaired wave-3 ledger. Public-surface IDs: 2645.

- **Before:** 1663 implemented / 943 declared / 0 deferred / 39 unavailable / 0 not-applicable
- **After:** 1876 implemented / 730 declared / 0 deferred / 39 unavailable / 0 not-applicable
- **Gain:** +213 implemented (local query-descriptor behaviour, value types, builders, workout inits)

Every new `implemented` row cites a top-level synchronous `func testName()` in
`tests/agent/HealthKitDepthWave8Tests.swift` or the existing table-driven
`testQuantitySeriesOptionsAlgebra`. Async `result(for:)` / `Sci12_Concurrency`
AsyncSequence combinators stay **declared**. Quantity-series `finishSeries`
and heartbeat `addHeartbeat` / `addMetadata` async entry points stay **declared**.

**Top-5 implemented evidence distribution**

| rows | evidence |
| ---: | --- |
| 520 | `test:full/healthkit/tests/agent/HealthKitEnumTests.swift#testEnumRawValues` |
| 407 | `test:full/healthkit/tests/agent/HealthKitConstantTests.swift#testCStringAndIdentifierConstants` |
| 109 | `test:full/healthkit/tests/agent/HealthKitEquatableTests.swift#testEnumEquatableAndHashable1` |
| 85 | `test:full/healthkit/tests/agent/HealthKitEquatableTests.swift#testEnumEquatableAndHashable2` |
| 72 | `test:full/healthkit/tests/agent/HealthKitEquatableTests.swift#testEnumEquatableAndHashable3` |

Largest non-table test remains under the 40% bulk-relabel cap
(`testUnitFactories` at 10.4% of remaining implemented rows). Largest wave-8
test is `testVerifiableClinicalRecordValueTypes` (28 rows).

### Wave 8 behaviour added

- `HKSamplePredicate` factories (category, correlation, workout/route, clinical,
  scored assessments, heartbeat, ECG, vision, audiogram) plus equality on
  nil vs non-nil `nsPredicate`.
- `HKQuantitySeriesSampleBuilder` sync `insert(_:at:)` / `insert(_:for:)` with
  unit and discarded-state errors; `discard()`.
- `HKQuantitySeriesSampleQueryDescriptor.results(for:)` over the local series
  table, including `.includeSample` and `.orderByQuantitySampleStartDate`.
- `HKHeartbeatSeriesQueryDescriptor` / `HKHeartbeatSeriesBuilder.finishSeries(completion:)`
  / `maximumCount == 100` and synchronous `HKHeartbeatSeriesQuery` delivery.
- `HKElectrocardiogramQueryDescriptor`, voltage `quantity(for:)`,
  `numberOfVoltageMeasurements`, and both Result and ObjC-style ECG query handlers.
- Anchored / statistics-collection / activity-summary / workout-route
  `results(for:)` snapshots against the local store (`HKWorkoutRouteQueryDescriptor.init(_:)`).
- `HKWorkoutEffortRelationshipQueryDescriptor` and `HKWorkoutEffortRelationshipQuery`
  (`.default` vs `.mostRelevant`) over local effort relations; `.samples` is the
  related sample wrapped as an array.
- `HKVerifiableClinicalRecord` / `Subject` value types and local (not
  Apple-verified) query matching of stored JWS payloads.
- `HKQueryAnchor` / `HKQueryDescriptor` NSSecureCoding, `objectType` /
  `sampleType`, and ECG association predicates.
- `HKVisionPrism` polar ↔ rectangular arithmetic and NSCoding.
- Extra `HKWorkout` convenience factories (device, flights, strokes) plus
  `statistics(for:)` / `allStatistics`; `HKWorkoutActivity` duration, events,
  and empty statistics.

### Public surface implemented

- **HKHealthStore (local store).** `isHealthDataAvailable()` is `true`.
  Persistence is JSON under `Documents/OpenUIKitHealthStore` (override with
  `HKHealthStorePortable._setStoreDirectory`). Per-type share/read
  authorization is stored on disk. `authorizationStatus(for:)` and
  `requestAuthorization(toShare:read:)` honor that map.
- **Test hooks (documented, not Apple API):**
  `_installAuthorizationHandler`, `_setAuthorization(for:share:read:)`,
  `_setCharacteristics(...)`, `_reset()`, `_setRouteLocations`. Without an
  installed authorization handler, `requestAuthorization` fail-closes to
  `.sharingDenied`.
- **save / delete** (single and arrays). Errors:
  `errorAuthorizationNotDetermined`, `errorAuthorizationDenied`,
  `errorInvalidArgument` (quantity unit incompatible with the type).
- **Queries executed against the local store:** `HKSampleQuery`,
  `HKStatisticsQuery`, `HKStatisticsCollectionQuery`, `HKAnchoredObjectQuery`,
  `HKObserverQuery`, `HKSourceQuery`, `HKCorrelationQuery`,
  `HKWorkoutRouteQuery`, `HKActivitySummaryQuery`. Predicates use
  `NSPredicate(block:)` because Linux Foundation has no format/KVC
  predicates. `HKPredicateOperator` mirrors Apple
  `NSComparisonPredicate.Operator` raw values (`equalTo` = 4). Sort
  descriptors, limits, and anchors are applied. Collection intervals use
  `Calendar.current`. `stop(query)` is honored.
- **Statistics:** sum / average / min / max / mostRecentQuantity with
  cumulative vs discrete aggregation and documented unit-compatibility rules.
- **Characteristics:** `dateOfBirthComponents`, `biologicalSex`, `bloodType`,
  `fitzpatrickSkinType`, `wheelchairUse`, `activityMoveMode` from the store.
- **HKQuantity / HKUnit:** unit algebra (`unitMultiplied`, `unitDivided`,
  `unitRaised`, `reciprocal`), conversion with prefixes and constants,
  `unit(_:)` / `init(from:)` parsing of documented strings (`kg`, `count/min`,
  `m/s`, `kcal`, `degC`, …), `is(compatibleWith:)`.
- **Types:** every `HKQuantityTypeIdentifier` / category / characteristic /
  correlation / series / document / clinical identifier as an exact raw
  string. `aggregationStyle` and `is(compatibleWith:)` unit rules.
- **Samples:** `HKQuantitySample`, `HKCategorySample`, `HKWorkout`,
  `HKCorrelation`, `HKWorkoutRoute` value semantics and validation.
- **HKSourceRevision / HKDevice / HKMetadataKey\*** exact strings.
- **HKWorkoutBuilder / HKLiveWorkoutBuilder** state machine (idle →
  collecting → ended → finished/discarded). `HKWorkoutSession` and
  `HKWorkoutRouteBuilder` are local (no Watch pairing).
- **Query descriptors** as `HKAsyncQuery` / `HKAsyncSequenceQuery` with real
  `AsyncSequence` results over the local store.
- **CLLocation** is a HealthKit-module stand-in so workout-route APIs compile
  in the isolated Foundation-only gate.

### Fail-closed boundaries (not invented)

- No Apple Health database, Health app UI, entitlements, or TCC.
- `enableBackgroundDelivery` / `disableBackgroundDelivery` /
  `disableAllBackgroundDelivery` → `errorHealthDataUnavailable`.
- Watch pairing, `HKWorkoutSession` hardware, Apple clinical-record / FHIR
  network verification, medication dose logging, live vision-prescription
  capture, Watch ECG hardware, and `splitTotalEnergy` stay fail-closed
  (`errorHealthDataUnavailable` or empty hardware streams). Local ECG
  voltage tables and locally stored JWS clinical records are queryable; they
  are not Apple-verified credentials.
- Attachment APIs that take `UTType` stay **unavailable** (isolated gate cannot
  import UniformTypeIdentifiers).
- APIs whose signatures require `NSComparisonPredicate.Operator` stay
  **unavailable**; use `HKPredicateOperator` instead.
- `preferredUnits(for:)` throws `errorHealthDataUnavailable`.
- Workout-activity quantity predicates currently match all (Linux NSPredicate
  cannot inspect nested `HKWorkoutActivity` via KVC).

### Tests

Sealed gate (unmodified): `bash full/healthkit/tests/acceptance/test_host.sh`

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
HEALTHKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=HealthKit dylib=libHealthKit.dylib
```

Agent probe: `full/healthkit/tests/agent/HealthKitRuntime.swift` (store CRUD,
auth hook, predicates, statistics, collection, anchored/observer/source/
route/correlation, characteristics, builder, background fail-closed).

Focused coverage tests (cited by `coverage.tsv`): `HealthKitEnumTests.swift`,
`HealthKitConstantTests.swift`, `HealthKitOptionSetTests.swift`,
`HealthKitEquatableTests.swift`, `HealthKitUnitTests.swift`,
`HealthKitStoreTests.swift`, `HealthKitQueryTests.swift`,
`HealthKitStatisticsTests.swift`, `HealthKitSampleTests.swift`,
`HealthKitWorkoutTests.swift`, `HealthKitDescriptorTests.swift`,
`HealthKitSurfaceTests.swift`, `HealthKitDepthWave8Tests.swift`.

### Unresolved behavioral questions

See `oracle-questions.tsv`. Remaining Apple-oracle items: kilocalorie
definition, `NSComparisonPredicate` when the type exists, CoreLocation /
UTType when those modules are linked in the guest package, TCC vs the
documented test hook, and whether `isHealthDataAvailable` should stay true
when no store directory is writable.

## What is real

- String constants (`HKErrorDomain` is `com.apple.healthkit`; other `HK*`
  strings equal their C identifier names). `HKObjectQueryNoLimit` is `0`.
  `HKUnitMolarMassBloodGlucose` is `180.15588`. `HKSourceRevisionAnyOperatingSystem`
  is `OperatingSystemVersion`. `HKAnchoredObjectQueryNoAnchor` is `Int32(0)`.
- Enums and option sets. Raw values use the pinned macios Native enums where
  present (`HKAuthorizationStatus`, `HKMetricPrefix`, `HKError.Code`,
  `HKWorkoutActivityType` including `other = 3000`, and others).
- Quantity and category type identifiers whose `rawValue` is the graph C name
  (`HKQuantityTypeIdentifierHeartRate`, …).
- `HKUnit` SI conversion: metric prefixes, mass/length/time/energy/temperature
  affine conversion, multiply/divide/raise, documented `unit(_:)` strings.
- `HKQuantity` compatible conversion and comparison.
- Local `HKObject` / `HKSample` / `HKQuantitySample` / `HKCategorySample` /
  `HKWorkout` / `HKSource` / `HKDevice` construction.
- `HKObjectType` factories and quantity aggregation style from the identifier
  catalog (cumulative vs discreteEquivalentContinuousLevel vs discreteArithmetic).
- `HKQuery` predicate factories that return `NSPredicate(block:)` filters
  over local samples.
- `HKHealthStore` local on-disk store as described under Depth pass 2026-09.

## Fail-closed / not invented

- No Apple Health database, no Health app UI, no entitlement grant, no Watch
  workout session, no Apple-verified clinical credentials / FHIR network.
- Attachment `UTType` and `NSComparisonPredicate.Operator` signatures remain
  unavailable on this isolated Linux gate.
- `HKUnit.unit(_:)` parses the documented SI/compound strings used in tests;
  arbitrary Apple unit strings that are not in that set are not claimed.

## Coverage

See `coverage.tsv`. Implemented 1876, declared 730, unavailable 39, deferred 0.
Unavailable rows are `NSComparisonPredicate.Operator` and `UTType` APIs only.
Declared rows compile but lack a focused `*Tests.swift` assertion. Wave-8
async `result(for:)` / `Sci12_Concurrency` combinators remain declared.
