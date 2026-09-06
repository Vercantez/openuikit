# JournalingSuggestions (Linux starting point)

This directory is a fail-closed portable `JournalingSuggestions` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift
surface from the sealed symbol graph. It is not wired into the shared guest
package; a passing isolated host gate is not integrated Linux success and is
not Apple Journaling Suggestions behavior.

## Depth pass 2026-09

This is a fresh seed: 931 exact public identifiers, floor 745 nondeferred.

Coverage after this pass: **141 implemented** / 790 declared / 0 deferred
(floor 745 nondeferred). Implemented rows are the Foundation value types,
notification-schedule enum, presentation token, picker inits, and fail-closed
host recorder. Declared rows are the synthesized SwiftUI `View` modifiers on
`JournalingSuggestionsPicker` plus the two async asset-load overlays (the
sealed runner has no run loop).

Top-5 evidence distribution among 141 implemented rows:

- `JournalingSuggestionActivityTests.swift#testLocationFields` — 8 (5.7%)
- `JournalingSuggestionActivityTests.swift#testWorkoutDetailsFields` — 8 (5.7%)
- `JournalingSuggestionTests.swift#testEventPosterFields` — 8 (5.7%)
- `JournalingSuggestionActivityTests.swift#testWorkoutGroupFields` — 7 (5.0%)
- `JournalingSuggestionTests.swift#testGenericMediaFields` — 7 (5.0%)


## What is real

- `JournalingSuggestion` stores `title`, `date`, and `items`. Equality and
  hashing use title, date, and item UUIDs. There is no public Apple
  initializer; `@_spi(OpenUIKitHost)` constructs values for tests.
- Nested content types (`Photo`, `Video`, `Song`, `Contact`, `Podcast`,
  `LivePhoto`, `GenericMedia`, `Reflection`, `EventPoster`, `MotionActivity`,
  `Workout` / `Workout.Details` / `WorkoutGroup`, `Location` /
  `LocationGroup`, `StateOfMind`) store the graph fields. Host SPI
  constructs them. They conform to `JournalingSuggestionAsset` with
  `JournalingSuggestionContent = Self`.
- `ItemContent.hasContent(ofType:)` is a type-indexed lookup.
  `representations` lists installed asset metatypes. Async
  `content(forType:)` is declared; `_content` / `_contents` are the
  synchronous tested paths.
- `MotionActivity.MovementType` is `Hashable` + `Codable` with host tokens
  `runningWalking`, `running`, `walking`. Unknown strings throw
  `DecodingError`. Darwin bytes are unobserved.
- `JournalingSuggestionsConfiguration.NotificationSchedule` is `off` /
  `smart` / `custom`. `init()` leaves `notificationSchedule` nil (no
  journaling daemon). Host SPI can inject a value for wiring tests.
- `JournalingSuggestionPresentationToken` stores an optional UUID and
  compares it.
- `JournalingSuggestionsPicker` stores a `View` label and records that a
  completion was supplied. It never presents Apple picker chrome.
  `View.journalingSuggestionsPicker` is identity and records the request
  on `JournalingSuggestionsHost`.

## Fail-closed boundaries

Linux has no Journaling Suggestions entitlement, picker UI, Photos/Health
daemon, or notification schedule service.

- Picker `onCompletion` is never invoked.
- `notificationSchedule` is nil unless a host test injects it.
- Asset loads without a host-installed payload return nil / empty.
- HealthKit, CoreLocation, MapKit, and SwiftUI types are lookalikes compiled
  only when those modules are absent. They are not Linux ports of those
  frameworks and are not declared dependencies of this seed (Foundation only).

## Still open

See `oracle-questions.tsv` for Darwin equality, Codable bytes, async load
errors/queues, picker completion when UI cannot present, and HealthKit
sample identity.

Focused checks live in `tests/agent/*Tests.swift` as top-level `func test*()`.
The sealed gate prints `JOURNALINGSUGGESTIONS_AGENT_RUNTIME_OK` after calling
each cited test once.

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=JournalingSuggestions lane=leaf-full symbols=931
FRAMEWORK_FANOUT_REFERENCE_OK
JOURNALINGSUGGESTIONS_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=JournalingSuggestions dylib=libJournalingSuggestions.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 / linux and the sealed gate compiled with a clean product tree (`products=clean`). Starting commit `343270ce44481a5ae11b87a6e0713e396ada1ef2` matched.

Run `bash full/journalingsuggestions/tests/acceptance/test_host.sh` from the
repo root. Keep generated products out of the tree.
