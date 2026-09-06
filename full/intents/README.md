# Open Intents and `.intentdefinition` builds

This directory owns two separate pieces of the Linux-hosted iOS platform:

1. `Intents.swift` plus the generated host-safe surface files listed in
   `intents_guest_sources.txt` are the source of the reusable
   `Intents.swiftmodule` and `libIntents.dylib`. The isolated Linux host
   compile imports Foundation only.
2. `intentdefinition_compiler.py` is an independent compiler for the public
   plist schema stored in Xcode `.intentdefinition` build inputs. It emits
   derived Swift outside the application repository, so application and
   vendor sources remain untouched.

`full/intentsui/IntentsUI.swift` is the corresponding controller/delegate
runtime and is packaged as `IntentsUI.swiftmodule` plus
`libIntentsUI.dylib`.

## Linux fan-out deliverable

Wave-5 schema v2 coverage lives in `coverage.tsv`. Before this lane there was
no coverage file (0 implemented / 0 declared / 0 deferred of 4160 public IDs).
The first-pass census was 1507 implemented / 1873 declared / 780
deferred. After the wave-8 depth pass plus coverage-ledger repair it was
1800 implemented / 1583 declared / 777 deferred. After the third behavioral
pass plus merge repair it was **2249 implemented / 1141 declared / 770
deferred**. After the fourth behavioral pass it is **2940 implemented /
751 declared / 469 deferred**. The
in-process donation, voice-shortcut, relevant-shortcut, resolution,
person/image/media/call-record, notebook/payment/photos/climate families,
Siri-denied, and identifier-constant slice is `implemented` with
`tests/agent/*Tests.swift`; the remaining compiling surface is `declared`;
Apple Siri services, CoreLocation/Contacts/EventKit/CGColor/NSExtensionContext
members, and the Swift `INShortcut` enum overlay are `deferred`.

Siri authorization stays fail-closed at `.denied`. Focus stays `.restricted`.
Generated handler protocols default to needs-value / empty / failure responses
rather than inventing Apple handler success. `INShortcut` remains the
pre-existing `NSObject` class used by the Mach-O guest; Apple's Swift enum
overlay is not substituted in.

On the isolated host, corelibs Foundation has no `NSUserActivity`. When
OpenUIKit is unavailable the module provides a lookalike so
`INIntentResponse.userActivity` still compiles. The production guest keeps
OpenUIKit's class identity.

## Generator contract

Generate into a path which does not yet exist:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -B \
  full/intents/intentdefinition_compiler.py generate \
  --input App/Base.lproj/Intents.intentdefinition \
  --output-root build/derived-sources/intents \
  --module-name App
```

The output contains one Swift file per custom enum, object, or intent, a
normalized declaration inventory, and `intentdefinition-manifest.json`.
`verify` rehashes the complete directory and rejects missing, changed,
symlinked, or extra files. Generation refuses existing output roots instead
of accidentally mixing old and new derived sources.

The current compiler accepts model version 1.2 and covers every unique schema
shape in the pinned 20-app corpus: custom enums and class-name overrides,
custom objects, String/Integer/Decimal/Boolean/Object parameters, scalar and
array cardinality, dynamic/search option providers, resolution methods,
response values, custom response codes, and custom response factories.
System intents are not regenerated: the manifest explicitly records them as
owned by the reusable Intents runtime.

The emitted protocols use pure Swift defaults to represent Objective-C
optional requirements. A real application implementation overrides the same
method spelling without needing Objective-C optional dispatch, while an
unimplemented service produces a `.failure`, `.ready`, `.needsValue`, or
empty-options result rather than fabricated success.

## Runtime behavior

The first production runtime slice has real, process-safe state for:

- intent phrases and response user activities;
- interaction donation, enumeration for a host, deletion by identifier and
  group identifier, and NSSecureCoding round trips for INIntent/INInteraction;
- typed resolution outcomes and retained values;
- intent objects, speakable strings, object collections, people, images, media
  items/search, call records, and INParameter key paths;
- shortcut suggestions, relevant-shortcut storage, and stable voice-shortcut
  install/update/delete (a fresh `getAllVoiceShortcuts` is empty; host SPI
  install is local);
- `.denied` Siri authorization and restricted/unavailable Focus-status
  authorization rather than a false account-level success.

`NSUserActivity` Siri overlay properties are stored on the portable guest
path by Intents, while OpenUIKit retains the canonical class identity. This
keeps Foundation → UIKit → Intents dependencies acyclic.

Run the fast generator gate with:

```sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=full/intents \
  python3 -B -m unittest -v full.intents.test_intentdefinition_compiler
```

The core-package gate additionally compiles both modules, links the dylibs,
checks their install names and dependency closure, compiles generated Focus
sources against `Intents.swiftmodule`, and executes the runtime probe as an
ARM64 Mach-O guest.

## Deliberate boundary

Siri speech recognition, Apple-account synchronization, and Apple's Siri
sheet are proprietary OS services. The open runtime does not claim those
services exist. IntentsUI exposes explicit host-driven finish/cancel/delete
actions so a Linux host can supply UI and still drive the real shortcut
store. Expanding that host UI and the standardized messaging/call/media
intent families is the next runtime layer; it does not require changing app
source or generated custom-intent source.

## Depth pass 2026-09 (wave 8)

Second behavioral pass on the existing first-pass tree. Before: **1507
implemented / 1873 declared / 780 deferred / 0 unavailable / 0
not-applicable**. After the depth runtime plus coverage-ledger repair:
**1800 implemented / 1583 declared / 777 deferred / 0 unavailable / 0
not-applicable**. Nondeferred (3383) stays above the medium-full floor of
2080. The +2 implemented rows versus the previous 1798 census are
`INNote`'s convenience init and `identifier` property, now actually
constructed and asserted in `testNotesAndTasksValueCoding`.

Top-5 implemented evidence distribution after the ledger repair:

| Citations | Evidence |
| ---: | --- |
| 1106 | `IntentsSurfaceTests.swift#testEnumRawValues` |
| 80 | `IntentsSurfaceTests.swift#testOptionSetFamilies` |
| 64 | `IntentsSurfaceTests.swift#testIntentErrorCodesCatalog` |
| 38 | `IntentsSurfaceTests.swift#testPersonRelationshipAndWorkoutIdentifiers` |
| 28 | `IntentsDepthTests.swift#testTravelValueCoding` |

`testEnumRawValues`, option-set families, the error-code catalog, intent
identifier constants, and person/workout identifier strings are the
allowed shared table-driven value tests. The previous bulk
`testNSCodingRoundTrips` (146 citations) is split into travel, payment,
call/car, notes/tasks, restaurant/reservation, ride, file/card, and misc
coding tests; mixed dispatcher/intent/car-ride tests are split the same
way. The largest remaining non-table test is 28/486 (5.8%), under the
40% bulk-relabel bound. No SwiftUI cross-import overlay rows exist in
this census.

### Third behavioral pass (wave 8 continue)

Keeps the first- and second-pass sources and tests. Before this pass:
**1800 implemented / 1583 declared / 777 deferred / 0 unavailable / 0
not-applicable**. After the third-pass runtime (pre-merge repair):
**2252 implemented / 1141 declared / 767 deferred**. Implemented gain
is +452, from property-retaining intent/response families, host
dispatcher routing, resolution-result exact codes, and Swift climate
overlays — not a relabel of `testEnumRawValues`.

### Merge repair (overload + ledger)

The operator merge gate refused `a27394e3` for ambiguous
`resolveTargetTaskList` / `resolveTemporalEventTrigger` calls through
`any INAddTasksIntentHandling` / `any INSetTaskAttributeIntentHandling`.
The dispatcher now opens those existentials into generic helpers and
selects each overload with an explicitly typed completion function.

Mixed Wave-9 tests are split per family so each `implemented` row cites
the focused test that actually constructs or dispatches that identifier.
Three `INRideStatus` CLPlacemark properties (`dropOffLocation`,
`pickupLocation`, `waypoints`) were relabeled `deferred`: they are not
present on the Linux class and depend on CoreLocation.

After this repair: **2249 implemented / 1141 declared / 770 deferred /
0 unavailable / 0 not-applicable**. Nondeferred (3390) stays above the
medium-full floor of 2080. Net versus the second-pass 1800 census is
+449 implemented.

Top-5 implemented evidence distribution after this repair:

| Citations | Evidence |
| ---: | --- |
| 1106 | `IntentsSurfaceTests.swift#testEnumRawValues` |
| 80 | `IntentsSurfaceTests.swift#testOptionSetFamilies` |
| 64 | `IntentsSurfaceTests.swift#testIntentErrorCodesCatalog` |
| 38 | `IntentsSurfaceTests.swift#testPersonRelationshipAndWorkoutIdentifiers` |
| 28 | `IntentsDepthTests.swift#testTravelValueCoding` |

Allowed shared table-driven tests remain enum/option-set/error-code/
identifier catalogs. The largest remaining non-table test is 28/1143
(2.4%), under the 40% bulk-relabel bound. Seven climate Swift overlays
moved from `deferred` to `implemented` with a real
`init(enableFan:enableAirConditioner:…)` and stored Bool/Int/Double
properties. No SwiftUI cross-import overlay rows exist in this census.

This pass adds:

- property-retaining construction and response `code`/`userActivity` for
  add-tasks, pay-bill, transfer-money, notebook search, set-task,
  search-call-history, book-restaurant, search-photos, start-photo-playback,
  search-accounts, and search-bills
- `INSetClimateSettingsInCarIntent` Swift overlays (`enableFan`,
  `enableAirConditioner`, `enableClimateControl`, `enableAutoMode`,
  `fanSpeedIndex`, `fanSpeedPercentage`) plus the documented convenience
  init
- `INPaymentAccount` now stores `accountNumber` from the `number:`
  argument; `INTask`/`INTaskList`/`INRideDriver`/`INRestaurantGuest`
  NSSecureCoding overlays round-trip identifiers and phone fields
- `INHostIntentDispatcher` synchronous handle/confirm/resolve routing for
  those families (defaults remain needsValue/failure; no Apple Siri success)
- additional `INPerson` convenience inits, `INMessage` attachment/reaction/
  sticker/link-metadata constructors, ride option/status remaining
  properties, and car-power remaining Measurement fields
- resolution-result success/disambiguation/confirmationRequired for
  payment-account, bill-payee, task, task-list, message-attribute,
  currency-amount, note, object, restaurant-guest, speakable-string, and
  the `INBooleanResolutionResult.confirmationRequired(with: Bool?)`
  overlay

Linux keyed archives use the top-level `INCarHeadUnit` class (Apple's
nested `INCar.HeadUnit` spelling is a typealias). Generic
`INObjectCollection` / `INObjectSection` still only check construction
and `supportsSecureCoding`; they are not archived as root objects.

This pass keeps the first-pass sources and tests and adds:

- property-retaining convenience inits and Linux NSSecureCoding overlays
  for INMessage, INAirline, ride/car value types, and related classes
- `INVocabulary.shared()` process store
- `INHostIntentDispatcher` synchronous handle/confirm/resolve routing
  for search/send/start-call/car-power/ride families
- `INExtension.handler(for:)` host-handler override
- `INIntegerResolutionResult.confirmationRequired(with: Int?)` overlay
- `INGetCarPowerLevelStatusIntentResponse` charge/fuel/charging Swift
  overlays (nil by default; host-settable)
- fail-closed Siri authorization, empty voice-shortcut center on a
  fresh process, and in-process relevant-shortcut storage

Still fail-closed / deferred: CoreLocation placemark members, Apple
archive byte compatibility, Siri daemon/account sync, live car-power
observer updates, INGetRideStatusIntent’s unavailable designated init,
and the Swift `INShortcut` enum overlay.
`INMediaDestination` NSCoding stays `declared` because the Mach-O guest
uses the Swift enum overlay, not an NSObject coder. Generic
`INObjectCollection` / `INObjectSection` NSCoding stays `declared` because
Linux `NSStringFromClass` cannot keyed-archive generic classes as roots.

### Fourth behavioral pass (wave 8 continue)

Keeps the first-, second-, and third-pass sources and tests. Before this
pass: **2249 implemented / 1141 declared / 770 deferred / 0 unavailable /
0 not-applicable**. After: **2940 implemented / 751 declared / 469
deferred / 0 unavailable / 0 not-applicable**. Implemented gain is +691
from property-retaining construction, NSSecureCoding, host dispatcher
routing, and per-type OptionSet/SetAlgebra — not a relabel of
`testEnumRawValues`. Nondeferred (3691) stays above the medium-full floor
of 2080.

Top-5 implemented evidence distribution after this pass:

| Citations | Evidence |
| ---: | --- |
| 1178 | `IntentsSurfaceTests.swift#testEnumRawValues` |
| 186 | `IntentsWave10Tests.swift#testOptionSetAlgebraMessageAttribute` |
| 80 | `IntentsSurfaceTests.swift#testOptionSetFamilies` |
| 64 | `IntentsSurfaceTests.swift#testIntentErrorCodesCatalog` |
| 41 | `IntentsWave10Tests.swift#testReservationDefaultsAndAvailabilityIntents` |

Allowed shared table-driven tests remain enum/option-set/error-code catalogs.
`testOptionSetAlgebraMessageAttribute` covers generic OptionSet/SetAlgebra
protocol witnesses plus `INMessageAttributeOptions` members. The largest
remaining non-table test is 41/1762 (2.3%), under the 40% bulk-relabel
bound. No SwiftUI cross-import overlay rows exist in this census.

This pass adds:

- `INObject` subtitle/displayImage storage and labeled Apple inits with
  NSSecureCoding
- `INRestaurantReservationBooking` flags/date/partySize round trips
- remaining `INSearchForMessagesIntent` dateTimeRange/groupNames inits and
  speakable-group/recipient/sender resolve via the host dispatcher
- `INSetProfileInCarIntent` overlay inits, response, and dispatcher routing
- `INDailyRoutineSituation` cases through `INDailyRoutineRelevanceProvider`
- `INMediaDestinationReference` library/playlist factories, resolution,
  and Swift `description`/`debugDescription` (NSCoding on the enum overlay
  stays declared)
- `INRideCompletionStatus` outstanding feedback/payment factories
- `INCar` charging connectors, `maximumPower`, display fields (`CGColor`
  init stays deferred)
- remaining call-record, play/add-media, payment-record, price-range,
  parameter, note/task/delete, restaurant defaults/availability/current
  bookings, seat/radio/workout/defroster, request/send payment, and
  recurrence-rule properties
- completion-based handle/confirm/resolve on those handling protocols and
  host dispatcher routing (defaults remain needsValue/failure)
- per-type OptionSet algebra for message/call/car/photo/ride/shortcut/
  temporal-trigger options

Still fail-closed / deferred: CoreLocation placemark members, Apple
archive byte compatibility, Siri daemon/account sync, live car-power
observer updates, `INCar` `CGColor` init, INGetRideStatusIntent’s
unavailable designated init, and the Swift `INShortcut` enum overlay.

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). That campaign token
is expected from the sealed host inventory, not from the framework gate.

The sealed host gate `bash full/intents/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Intents lane=medium-full symbols=4160
FRAMEWORK_FANOUT_REFERENCE_OK
INTENTS_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Intents dylib=libIntents.dylib
```
