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
deferred. After the wave-8 depth pass it is 1799 implemented / 1584
declared / 777 deferred. The in-process donation, voice-shortcut, relevant-shortcut,
resolution, person/image/media/call-record, Siri-denied, and identifier-constant
slice is `implemented` with `tests/agent/*Tests.swift`; the remaining compiling
surface is `declared`; Apple Siri services, CoreLocation/Contacts/EventKit/
CGColor/NSExtensionContext members, and the Swift `INShortcut` enum overlay are
`deferred`.

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
not-applicable**. After: **1799 implemented / 1584 declared / 777
deferred / 0 unavailable / 0 not-applicable**. Nondeferred (3383) stays
above the medium-full floor of 2080.

Top-5 implemented evidence distribution after this pass:

| Citations | Evidence |
| ---: | --- |
| 1106 | `IntentsSurfaceTests.swift#testEnumRawValues` |
| 147 | `IntentsDepthTests.swift#testNSCodingRoundTrips` |
| 80 | `IntentsTests.swift#testOptionSetFamilies` |
| 64 | `IntentsTests.swift#testIntentErrorCodesCatalog` |
| 38 | `IntentsTests.swift#testPersonRelationshipAndWorkoutIdentifiers` |

`testEnumRawValues` is the table-driven imported-enum raw-value test
(allowed to be shared). `testNSCodingRoundTrips` covers the generated
NSSecureCoding family and is 21% of the remaining implemented rows
(under the 40% bulk-relabel bound). No SwiftUI cross-import overlay rows
exist in this census.

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
archive byte compatibility, Siri daemon/account sync, INGetRideStatusIntent’s
unavailable designated init, and the Swift `INShortcut` enum overlay.
`INMediaDestination` NSCoding stays `declared` because the Mach-O guest
uses the Swift enum overlay, not an NSObject coder.

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing). That campaign token
is expected from the sealed host inventory, not from the framework gate.

The sealed host gate is `bash full/intents/tests/acceptance/test_host.sh`.
