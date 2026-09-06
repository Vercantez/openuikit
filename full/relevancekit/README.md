# RelevanceKit

Linux starting point for Apple's public `RelevanceKit` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph and API digester. This
directory is not wired into the shared guest package. A passing isolated host
gate is not integrated Linux success with guest Foundation, WidgetKit, HealthKit,
CoreLocation, or MapKit.

`dotnet/macios` has no RelevanceKit bindings in the pinned evidence checkout.
Apple graphs are the only declaration authority.

## Depth pass 2026-09

This is a fresh seed: 29 exact public identifiers, floor 24 nondeferred.

Coverage after this pass: **27 implemented / 0 declared / 0 deferred /
2 unavailable / 0 not-applicable**.

Top-5 evidence distribution (share of the 27 implemented rows):

1. `RelevantContextTests.swift#testRelevantContextValueType` — 1 (3.7%)
2. `RelevantContextTests.swift#testSleepConditionType` — 1 (3.7%)
3. `RelevantContextTests.swift#testFitnessConditionType` — 1 (3.7%)
4. `RelevantContextTests.swift#testInferredLocationType` — 1 (3.7%)
5. `RelevantContextTests.swift#testHeadphonesConditionType` — 1 (3.7%)

Every implemented row cites its own top-level `test*` function. Nested
condition members are structs with static properties, not enum cases, so they
do not share a table-driven value test. No test is cited by more than 40% of
implemented rows.

## What is real

- `RelevantContext` is a value type. Factory methods store the documented clue
  kind plus associated Foundation dates (`Date`, `DateInterval`,
  `ClosedRange<Date>`) or nested condition tokens.
- `SleepCondition` (`wakeup`, `bedtime`), `FitnessCondition`
  (`workoutActive`, `activityRingsIncomplete`), `InferredLocation`
  (`home`, `work`, `school`, `commute`), `HeadphonesCondition` (`connected`),
  and `DateKind` (`informational`, `default`, `scheduled`) are distinct
  nested structs. Internal discriminators are a port choice; Apple does not
  publish raw values for these types.
- `date(from:to:)` stores both bounds as given, including inverted pairs.
- Linux `Equatable`/`Hashable` compare the stored payload. That conformance is
  not in the public graph (Copyable/Escapable only) and is not an Apple
  observation. `date(_:)` is not treated as equal to `date(_:kind: .default)`.
- `@_spi(OpenUIKitHost)` inspection exposes the stored payload for focused
  tests. Those symbols are not Apple API.

## Fail-closed boundaries

Apple documents that RelevanceKit only affects Smart Stacks on watchOS;
calling the API elsewhere has no widget effect. Linux never ranks widgets,
never reads HealthKit sleep/fitness data, never infers a live place, and never
probes headphone hardware. Construction of a clue is local and is not service
success.

- `location(_:)` taking `CLRegion` is **unavailable**. CoreLocation is not a
  declared dependency; a module-local lookalike is forbidden.
- `location(category:)` taking `MKPointOfInterestCategory` is **unavailable**.
  It lives on the `_RelevanceKit_MapKit` bystander overlay; MapKit is not a
  declared dependency.

There is no RelevanceKit error type in the public surface. Fail-closed means
omitting Apple-owned foreign types and keeping clues inert, not throwing a
fabricated code.

## Still open

See `oracle-questions.tsv` for inverted `date(from:to:)` bounds, factory
equivalence, CoreLocation/MapKit overlays, HealthKit/location authorization
timing, and whether Darwin synthesizes Equatable.

Focused checks live in `tests/agent/*Tests.swift` as top-level `func test*()`.
The sealed gate prints `RELEVANCEKIT_AGENT_RUNTIME_OK` after calling each
cited test once.

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=RelevanceKit lane=leaf-full symbols=29
FRAMEWORK_FANOUT_REFERENCE_OK
RELEVANCEKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=RelevanceKit dylib=libRelevanceKit.dylib
```

Run `bash full/relevancekit/tests/acceptance/test_host.sh` from the repo
root. Keep generated products out of the tree.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 / linux and the sealed gate compiled with a clean product tree (`products=clean`).
