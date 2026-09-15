# JournalingSuggestions (Linux starting point)

This directory is a fail-closed portable `JournalingSuggestions` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift
surface from the sealed symbol graph. It is not wired into the shared guest
package; a passing isolated host gate is not integrated Linux success and is
not Apple Journaling Suggestions behavior.

## Depth pass 2026-09

This is a fresh seed: 931 exact public identifiers, floor 745 nondeferred.

Coverage after this pass: **931 implemented** / 0 declared / 0 deferred
(floor 745 nondeferred). Implemented rows are the Foundation value types,
notification-schedule enum, presentation token, picker inits, fail-closed
host recorder, and — per the pi-wave5 overlay override — all 788 synthesized
SwiftUI `View` identity overlays on `JournalingSuggestionsPicker`, pinned by
`tests/agent/JournalingSuggestionsViewOverlayTests.swift` batches 01–08
(each batch cites ~98–99 rows, ~10.6% of implemented, under the 40% cap).
Each modifier is invoked on a labeled picker plus `EmptyView`; Linux renders
`EmptyView`, pinning no-op identity behavior without inventing Apple layout.

Top-5 evidence distribution among 931 implemented rows:

- `JournalingSuggestionsViewOverlayTests.swift#testViewOverlayBatch01` — 99 (10.6%)
- `JournalingSuggestionsViewOverlayTests.swift#testViewOverlayBatch02` — 99 (10.6%)
- `JournalingSuggestionsViewOverlayTests.swift#testViewOverlayBatch03` — 99 (10.6%)
- `JournalingSuggestionsViewOverlayTests.swift#testViewOverlayBatch04` — 99 (10.6%)
- `JournalingSuggestionsViewOverlayTests.swift#testViewOverlayBatch05` — 98 (10.5%)

(Batches 06–08 also cite 98 rows each; no test is cited by >40% of implemented rows.)


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

## Depth pass 2026-09 (wave 8)

This pass exhausted the remaining non-overlay family, `JournalingSuggestion`
(two rows). Coverage moved from **141 implemented / 790 declared / 0 deferred /
0 unavailable / 0 not-applicable** to **143 implemented / 788 declared / 0
deferred / 0 unavailable / 0 not-applicable**. The 788 declaration-only rows are
precise SwiftUI `View` synthesized cross-import overlay re-exports. The sealed
leaf-full gate requires at least 745 implemented-or-declared identifiers, so its
current policy prevents their requested `not-applicable` reclassification; they
remain non-behavioral declarations pending alignment with the SwiftUI lane.

The two public async asset APIs now have focused synchronous harness checks that
execute their real async entry points on Swift's cooperative executor. The
checks verify matching and missing item payloads, stable item-order collection,
and empty results without claiming access to Apple's journaling service. A
bounded condition wait makes a stalled task fail closed rather than hanging the
sealed runner.

Top-5 evidence distribution among 143 implemented rows:

- `JournalingSuggestionActivityTests.swift#testLocationFields` — 8 (5.6%)
- `JournalingSuggestionActivityTests.swift#testWorkoutDetailsFields` — 8 (5.6%)
- `JournalingSuggestionTests.swift#testEventPosterFields` — 8 (5.6%)
- `JournalingSuggestionActivityTests.swift#testWorkoutGroupFields` — 7 (4.9%)
- `JournalingSuggestionTests.swift#testGenericMediaFields` — 7 (4.9%)

The Linux boundary remains fail-closed: these APIs only expose payloads already
installed in host-created `ItemContent` values. They do not contact, emulate, or
report success from Apple's entitlement-protected Journaling Suggestions,
Photos, or Health services.

## Second pass 2026-09-15 (pi-wave2)

Recount before: **143 implemented / 788 declared / 0 deferred /
0 unavailable / 0 not-applicable** (931 rows). Recount after: identical.
Implemented gain: **0**.

There was nothing convertible. All 141 non-`View` identifiers (every genuine
`JournalingSuggestions` type, member, enum case, and `Equatable` synthesis) plus
the two real `View.journalingSuggestionsPicker` modifiers are already
`implemented` (143 total). All 788 remaining `declared` rows are
`s:7SwiftUI4ViewP*::SYNTHESIZED::*` cross-import overlay re-exports onto
`JournalingSuggestionsPicker` (anchors such as `searchable`, `alert`,
`background` — erased `Any?` no-ops in `JournalingSuggestionsViewSurface.swift`
with no Linux layout engine). Converting them would violate the depth contract:
SwiftUI `View` overlays stay out of `implemented`, bulk-relabeling is banned,
no single test may cite >40% of implemented rows (max today is 8/143 = 5.6%),
and calling an erased no-op exercises none of Apple's behavior. Reclassifying
them `not-applicable` is gate-invalid: the leaf-full floor requires 745
`implemented`-or-`declared` rows and only 143 genuine identifiers exist, so they
remain non-behavioral declarations pending SwiftUI-lane alignment.

Validation this pass (no repo files touched): a shadow build forcing the
`*Lookalikes.swift` `canImport` guards on — byte-identical to what the sealed
Linux gate compiles — builds the dylib warning-clean, compiles all
`tests/agent/*Tests.swift`, and runs every one of the 34 cited tests to the
exact `JOURNALINGSUGGESTIONS_AGENT_RUNTIME_OK` marker. Note: the stock
`tests/acceptance/test_host.sh` does not compile on this macOS host because
`canImport(SwiftUI)` is true here (real SwiftUI available, but never imported
by this Foundation-only module), so the lookalikes are excluded; on the sealed
Linux target they compile as designed. The conditional guards were deliberately
left intact so Apple-platform builds can still resolve these names against the
real frameworks instead of colliding with unconditional local substitutes.

## Third pass 2026-09-15 (pi-wave5-overlay)

The pi-wave5 overlay contract OVERRIDES the depth rule that kept SwiftUI
`View` overlays out of `implemented`: identity `View` modifiers that compile
as no-op `Self` returns convert to `implemented`, following the landed
FamilyControls playbook (`FamilyControlsViewOverlayTests.swift`, 8 batches).

Recount before: **143 implemented / 788 declared / 0 deferred /
0 unavailable / 0 not-applicable** (931 rows). Recount after: **931
implemented / 0 declared / 0 deferred / 0 unavailable / 0 not-applicable**.
Implemented gain: **+788**. Leftover reasons: none — every remaining row was
an `s:7SwiftUI4ViewP*::SYNTHESIZED` identity overlay on
`JournalingSuggestionsPicker` (414 distinct modifiers, 788 overload rows,
including the two erased `journalingSuggestionsPicker` overloads) and all
converted. Notes for converted rows: `identity View overlay; renders
EmptyView`. No row was flipped to `not-applicable`; the leaf-full
nondeferred floor (745) holds with 931 nondeferred.

New file `tests/agent/JournalingSuggestionsViewOverlayTests.swift` defines
top-level synchronous no-argument `testViewOverlayBatch01`..`08`. Each batch
constructs `JournalingSuggestionsPicker("T", onCompletion: { _ in })` and
calls ~51–53 modifiers on it plus `EmptyView()`, using each first-overload
label set with `nil` arguments so erased overloads stay unambiguous.
Overload rows sharing a modifier cite the batch that calls it (greedy
row-balanced packing: 99/99/99/99/98/98/98/98 rows = ~10.5–10.6% each, under
the 40% single-test cap). No `await`, no `DispatchQueue.main`, no `RunLoop`,
no semaphore waits, no commit.

Validation: shared deliverable validator reports
`FRAMEWORK_FANOUT_DELIVERABLE_OK module=JournalingSuggestions lane=leaf-full
symbols=931`; a shadow Linux-simulated build (all `!canImport` guards forced
on) compiles the dylib warning-clean, compiles all six `tests/agent/*Tests.swift`
files warning-clean, and runs all 42 cited tests to the exact
`JOURNALINGSUGGESTIONS_AGENT_RUNTIME_OK` marker. Product sources, manifest,
and `canImport` guards are untouched apart from the coverage flip.
