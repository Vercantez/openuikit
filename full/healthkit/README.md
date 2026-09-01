# Linux HealthKit starting point
#
# This port reconstructs Apple's public HealthKit surface from the pinned
# Xcode 26.1 symbol graph. It is a local, fail-closed Linux module: unit
# conversion, type identifiers, in-memory sample construction, and query
# predicates are real. Nothing here talks to an Apple Health store, Health
# app, Watch session, clinical records service, or entitlement pipeline.
#
# Real on Linux
# -------------
# * `HKUnit` / `HKQuantity` SI conversion (mass, length, energy, temperature,
#   pressure, composite count/time, metric prefixes, formatter bridges).
# * Quantity / category / characteristic / correlation / series type identifiers
#   using the public C export names from `reference/tbd-exports.tsv`.
# * `HKObjectType` factories and sample/workout/correlation construction.
# * `HKQuery` predicates that evaluate against in-memory `HKObject` values.
# * Public enumerations, metadata keys, predicate key paths, and `HKError`.
#
# Fail-closed
# -----------
# * `HKHealthStore.isHealthDataAvailable()` is `false`.
# * Authorization, save/delete, characteristic reads, background delivery,
#   watch-app launch, workout-session recovery, and query execution complete
#   or throw with `HKError.errorHealthDataUnavailable`.
# * `HKWorkoutSession` initialization throws the same error.
# * Clinical records, FHIR, verifiable credentials, ECG voltage streams,
#   attachment stores, and live workout builders are type stubs only.
#
# Deferred
# --------
# Swift async query descriptors, CoreLocation workout routes, NSPredicate
# comparison-operator overloads (unavailable in swift-corelibs-foundation),
# keyed archiving, and Apple-only UI / privacy-sheet behavior.
