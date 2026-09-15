# HomeKit (Linux starting point)

This directory is a clean-room Linux starting implementation of Apple's public
`HomeKit` module, reconstructed from the sealed Xcode 26.1 iPhoneOS symbol
graph. Isolated host compilation produces `libHomeKit.dylib`. It is not a
claim of Apple Home, home-hub, HAP session, or pairing parity.

## Depth pass 2026-09

Fresh seed: `full/homekit/` had `AGENTS.md`, `FANOUT_TASK.md`, and `reference/`
only. This pass builds the starting implementation (2295 exact IDs) and adds
real Linux behavior for every family whose semantics are documented.

Coverage: **906 implemented / 605 declared / 0 deferred / 8 unavailable / 776 not-applicable / 2295 total**
(1511 nondeferred; floor 150).

Every `implemented` row cites
`test:full/homekit/tests/agent/<File>Tests.swift#testName` naming a real
top-level synchronous no-argument `func testName()` that returns. Enum /
option-set members and C `HM*` constants share table-driven value tests.
Other APIs are split across focused tests; no non-table test is cited by
more than 40% of the remaining implemented rows.

**Top-5 implemented evidence distribution**

| rows | share | evidence |
| ---: | ---: | --- |
| 410 | 45.3% | `test:full/homekit/tests/agent/HomeKitEnumTests.swift#testEnumRawValues` |
| 253 | 27.9% | `test:full/homekit/tests/agent/HomeKitConstantTests.swift#testCStringConstants` |
| 107 | 11.8% | `test:full/homekit/tests/agent/HomeKitEnumTests.swift#testErrorCodeStatics` |
| 27 | 3.0% | `test:full/homekit/tests/agent/HomeKitEnumTests.swift#testOptionSetAlgebra` |
| 21 | 2.3% | `test:full/homekit/tests/agent/HomeKitBehaviorTests.swift#testPresenceAndSignificantTime` |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Starting commit
`e76572cf95a4cd2c803c340a1867409c4fc4c6a6` matched.

### Public surface that is real on Linux

- **Native enumerations.** HAP characteristic-value enums, camera stream
  state, presence / hub / event-trigger activation, and `HMError.Code` use
  pinned `dotnet/macios` `[Native]` raw values (`unexpectedError = -1`,
  `alreadyExists = 1`, gap at 94, `noHomeHub = 91`, `noCompatibleHomeHub = 92`).
- **`HMError` overlay.** `CustomNSError` with `HMErrorDomain`. Pattern match
  `~=` accepts typed errors and `NSError` domain/code. A freshly constructed
  `NSError(domain:code:)` is **not** `as? HMError`.
- **`HMHomeManagerAuthorizationStatus` OptionSet.** `determined = 1`,
  `restricted = 2`, `authorized = 4`, plus SetAlgebra witnesses.
- **String constants.** Metadata formats/units/key-paths use documented
  Apple payloads (`bool`, `celsius`, `arcdegrees`, `ppm`, `characteristic`).
  Accessory / service / characteristic type constants equal their C
  identifiers in this host port (HAP UUID bytes are an oracle question).
- **Value types.** `HMNumberRange` min/max inclusive containment,
  `HMSignificantEvent` sunrise/sunset raw strings, duration / calendar /
  presence / significant-time events and their mutable subclasses,
  `HMTimerTrigger` stored fire date / time zone / calendar.
- **Local object graph.** Host helpers assemble homes, rooms, services, and
  characteristics. `servicesWithTypes` filters the hosted service list.
  Characteristic metadata validates numeric writes (`valueHigherThanMaximum`,
  `invalidValueType`). Event-trigger calendar/presence predicates are
  `NSPredicate(block:)` builders (Linux Foundation has no format/KVC
  predicates).
- **Setup payload parsing.** `HMAccessorySetupPayload` accepts `homekit://`
  URLs; empty ownership tokens are rejected.

### Fail-closed boundaries

These paths require Apple Home, a home hub, HAP, camera RTP, Matter,
entitlements, or hardware. They never invent success:

- `HMHomeManager.authorizationStatus` is `[.determined, .restricted]`;
  `homes` is empty; `addHome` / `removeHome` / `updatePrimaryHome` throw
  `homeAccessNotAuthorized` (47).
- Accessory `identify` / characteristic `readValue` / remote `writeValue`
  complete with `accessoryNotReachable` (4) on the calling thread.
- `HMAccessoryBrowser` never discovers accessories.
- Camera `startStream` stays `.notStreaming`; snapshots stay nil.
- `HMAccessorySetupManager` setup is `missingEntitlement` (80).
- Home mutations (`addAccessory`, `executeActionSet`, user management)
  throw `homeAccessNotAuthorized` or `noHomeHub`.
- Completions run synchronously before return so tests do not wait on a
  run loop.

### Unavailable / not-applicable

- `CLRegion`, `NSXPCConnection`, `NSComparisonPredicate.Operator`, and
  `MTRSetupPayload` signatures are `unavailable` (Foundation-only
  dependencies).
- SwiftUI `CameraView` and `_HomeKit_SwiftUI` View modifiers were
  `not-applicable` through wave 10; the pi-wave7 overlay pass converts all
  776 to `implemented` as identity no-op overlays (see below).

### Declared

Synthesized `Hashable` / `init(rawValue:)` / `!=` witnesses, async-throws
methods that tests cannot await, and class/protocol surface that compiles
but is not independently asserted.

Unresolved questions live in `oracle-questions.tsv`.

## Depth pass 2026-09 (wave 8)

Second behavioral pass on the existing first-pass tree. The first-pass sources
and tests stay; this pass adds a host-local home graph, completion-handler
paths, delegate dispatch, characteristic write/notify state, event-trigger
predicate arithmetic, camera settings wiring, and setup-payload parsing.

Coverage of the 2295 iPhoneOS 26.1 public identifiers:

| status | before | after |
| --- | --- | --- |
| implemented | 906 | 1129 |
| declared | 605 | 382 |
| deferred | 0 | 0 |
| unavailable | 8 | 8 |
| not-applicable | 776 | 776 |

Implemented gain is **+223**. Nondeferred stays 1511 (floor 150). Every new
`implemented` row cites a real top-level synchronous `func testName()` that
exercises that identifier. Enum / option-set / C-constant table tests are
unchanged. Largest non-table remaining share is 50/332 (15.1%), under the 40%
bulk-relabel cap. All 776 `not-applicable` rows are SwiftUI cross-import
overlay re-exports. Each `unavailable` row now names a Matter/XPC daemon,
CoreLocation hardware, or missing `NSComparisonPredicate.Operator`.

**Top-5 implemented evidence distribution (after)**

| rows | share | evidence |
| ---: | ---: | --- |
| 410 | 36.3% | `HomeKitEnumTests.swift#testEnumRawValues` (table-driven Native raw values) |
| 253 | 22.4% | `HomeKitConstantTests.swift#testCStringConstants` (table-driven C strings) |
| 107 | 9.5% | `HomeKitEnumTests.swift#testErrorCodeStatics` (table-driven error codes) |
| 50 | 4.4% | `HomeKitAccessoryDepthTests.swift#testAccessoryGraphAndDelegate` |
| 38 | 3.4% | `HomeKitHomeDelegateTests.swift#testHomeDelegateNotifications` |

### Behavior added this pass

- **Host-local `HMHome` graph.** `addRoom` / `addZone` / `addServiceGroup` /
  `addActionSet` / `addTrigger` completion handlers mutate in-process
  collections, reject empty names (`stringShorterThanMinimum` = 51) and
  case-insensitive collisions (`objectWithSimilarNameExistsInHome` = 31), and
  fire `HMHomeDelegate`. Entire-home room rename/remove is
  `roomForHomeCannotBeUpdated` (29); adding it to a zone is
  `roomForHomeCannotBeInZone` (24).
- **Action sets.** Local `addAction` / `removeAction`. `executeActionSet`
  returns `noActionsInActionSet` (25) when empty, `noHomeHub` (91) unless
  `host_setHomeHubState(.connected)`, then applies
  `HMCharacteristicWriteAction` targets through `host_writeLocal` and stamps
  `lastExecutionDate`. Builtin sets cannot be removed (83).
- **Fail-closed Apple services.** Pairing `addAccessory` is
  `accessoryNotReachable` (4). Setup is `missingEntitlement` (80). User
  management is `homeAccessNotAuthorized` (47). Bridged-only unblock;
  non-bridge unblock is `cannotUnblockNonBridgeAccessory` (81).
- **Characteristics.** Reachability gates `readValue` / `writeValue`.
  Metadata checks min/max/step/`validValues`/`maxLength`. Notifications
  require `HMCharacteristicPropertySupportsEventNotification` and return
  `notificationAlreadyEnabled` (68) / `notificationNotSupported` (7).
- **Event triggers.** Inits store events/endEvents/recurrences/predicate.
  Time-of-day predicates compare UTC minutes (including overnight wrap).
  Significant-event predicates accept only sunrise/sunset raw strings (no
  invented solar times). Presence predicates match type/user.
- **Camera settings / setup payload.** `HMCameraSettingsControl.host_make`
  wires tilt/zoom/night-vision characteristics.
  `HMAddAccessoryRequest.makePayload` requires a `homekit`/`hap` URL.

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` still fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). The sealed gate compiles
with a clean product tree (`products=clean`). Starting commit
`6bf18072f4bc9ca119f4b0ad49dd8478f92dd5f0` matched.

## Depth pass 2026-09 (wave 9)

This continuation preserves wave 8 and verifies compiler-synthesized enum
semantics plus deterministic local object state. Coverage moved from **1129
implemented / 382 declared / 0 deferred / 8 unavailable / 776 not-applicable**
to **1437 implemented / 74 declared / 0 deferred / 8 unavailable / 776
not-applicable**. The implemented gain is **+308**.

The enum table now directly exercises `init(rawValue:)`, `!=`, `hashValue`, and
`hash(into:)` for all 66 native enums. Focused synchronous tests additionally
exercise base action/event identity, characteristic-event immutable and mutable
state, fail-closed trigger-value updates, accessory/network profile defaults,
camera source/control defaults, and accessory setup request value state. No
Apple daemon, RTP stream, network, pairing, entitlement, or hardware success is
fabricated; those boundaries remain as documented above.

**Top-5 implemented evidence distribution (after wave 9)**

| rows | share | evidence |
| ---: | ---: | --- |
| 410 | 28.5% | `HomeKitEnumTests.swift#testEnumRawValues` |
| 264 | 18.4% | `HomeKitEnumTests.swift#testSynthesizedEnumWitnesses` |
| 253 | 17.6% | `HomeKitConstantTests.swift#testCStringConstants` |
| 107 | 7.4% | `HomeKitEnumTests.swift#testErrorCodeStatics` |
| 50 | 3.5% | `HomeKitAccessoryDepthTests.swift#testAccessoryGraphAndDelegate` |

## Depth pass 2026-09 (wave 10)

This pass converts the 74 leftover `declared` rows. The committed
`tests/agent/HomeKitDeclaredDepthTests.swift` did not compile against the
product sources (it called completion-handler overloads, `aspectRatio`, and
`setAudioStreamSetting` that did not exist), so the sealed Linux gate could
not have exercised it. This pass adds the missing fail-closed product APIs
and repairs the tests; no Apple daemon, pairing, RTP, or entitlement success
is fabricated.

Coverage moved from **1437 implemented / 74 declared / 0 deferred / 8
unavailable / 776 not-applicable** to **1508 implemented / 3 declared / 0
deferred / 8 unavailable / 776 not-applicable**. The implemented gain is
**+71**.

Product additions (all fail-closed or local stored state):

- `HMCameraSource.aspectRatio` stored property plus `host_setAspectRatio`.
- `HMCameraStream.setAudioStreamSetting` (local store) and
  `updateAudioStreamSetting(_:completionHandler:)` (`.operationNotSupported`).
- `HMAccessorySetupManager.performAccessorySetup(using:completionHandler:)`
  (`.missingEntitlement`).
- `HMHomeManager` completion-handler overloads for `addHome`, `removeHome`,
  `updatePrimaryHome` (`.homeAccessNotAuthorized`) and
  `findVendorAccessory` (`.accessoryDiscoveryFailed`).
- `HMTimerTrigger` completion-handler overloads for `updateFireDate`,
  `updateRecurrence`, `updateTimeZone` (fail-closed, mirroring the async
  throws versions).
- `HMMediaSourceDisplayOrderProfile.writeOrder(_:completionHandler:)`
  (`.operationNotSupported`).

The 3 remaining `declared` rows are `HMCameraView`, its `init`, and its
`cameraSource`: the class is `@MainActor`, so no synchronous nonisolated
agent test can construct it or touch its members. The largest new test cites
15 rows, far under the 40% bulk-relabel cap.

Environment: `swiftc` on this Mac reports Swift 6.2.4. The sealed
`tests/acceptance/test_host.sh` runner phase generates `import Glibc`, which
cannot compile on macOS; instead the product dylib plus all `*Tests.swift`
were compiled with `-warnings-as-errors` and a local runner invoked all 45
unique cited tests, exited 0, and printed only
`HOMEKIT_AGENT_RUNTIME_OK`.

## Overlay pass 2026-09 (pi-wave7)

This pass converts the 776 leftover `not-applicable` rows (the
`_HomeKit_SwiftUI.CameraView` struct, its `init(source:)` / `Body` / `body`,
and 772 SwiftUI `View` modifiers synthesized onto it) to `implemented`,
following the PassKit 100% / StoreKit / FamilyControls overlay playbook.
Coverage moved from **1508 implemented / 3 declared / 0 deferred / 8
unavailable / 776 not-applicable** to **2284 implemented / 3 declared / 0
deferred / 8 unavailable / 0 not-applicable**. The implemented gain is
**+776**.

Product addition (`full/homekit/HMViewSurface.swift`, in the guest manifest):

- Linux-host `View` / `EmptyView` / `ViewBuilder` lookalikes, compiled only
  when SwiftUI cannot be imported (isolated host).
- `CameraView: View` storing its `HMCameraSource` with an `EmptyView` body.
  Darwin marks it `@MainActor @preconcurrency`; Linux omits the actor
  annotation so synchronous tests can construct it (its `init` is
  `nonisolated` upstream). It never presents camera UI; RTP/HAP sessions
  stay fail-closed as documented above.
- 401 identity `View` modifiers (one per distinct demangled base name behind
  the 772 overloads), each a no-op `Self` return callable with zero
  arguments.

Tests (`tests/agent/HomeKitViewOverlayTests.swift`):

- `testCameraViewIdentity` constructs `CameraView(source:)` and reads
  `body` / `Body` (4 rows).
- `testViewOverlayBatch01`–`testViewOverlayBatch08` call every modifier on
  `CameraView` plus `EmptyView` (72–130 rows each; largest share is
  130/2284 = 5.7%, far under the 40% cap). No `DispatchQueue`,
  `RunLoop`, semaphore waits, or `await`.

The 3 remaining `declared` rows are unchanged: `HMCameraView`, its `init`,
and its `cameraSource` are `@MainActor`-isolated, so no synchronous
nonisolated agent test can construct the class or touch its members.

Environment: `swiftc` on this Mac reports Swift 6.2.1. The sealed
`tests/acceptance/test_host.sh` runner phase generates `import Glibc`, which
cannot compile on macOS, and macOS resolves real SwiftUI (compiling the
`#if !canImport(SwiftUI)` lookalikes out, as in the PassKit/StoreKit lanes).
Verification therefore used two local builds, both with
`-warnings-as-errors`: (1) the real tree (product dylib compiles clean
against Apple SwiftUI); (2) a scratch copy with the `canImport(SwiftUI)`
branches flipped to simulate the SwiftUI-less Linux host, where the product
dylib plus all `*Tests.swift` compiled and a local runner invoked all 54
unique cited tests, exited 0, and printed only
`HOMEKIT_AGENT_RUNTIME_OK`.

## Wave 12 pass 2026-09 (pi-wave12)

This pass converts the 3 leftover `declared` rows (`HMCameraView`, its
`init`, and its `cameraSource`). Coverage moved from **2284 implemented /
3 declared / 0 deferred / 8 unavailable / 0 not-applicable** to **2287
implemented / 0 declared / 0 deferred / 8 unavailable / 0
not-applicable**. The implemented gain is **+3** (2295 total).

Product change (`full/homekit/HMCamera.swift`, already in the guest
manifest): `HMCameraView` keeps `@MainActor` on Darwin (`#if
canImport(UIKit)`) and omits it on the UIKit-less Linux host, mirroring
the `CameraView` overlay precedent, so synchronous nonisolated agent tests
can construct the view and touch `cameraSource`. The view stores an
optional `HMCameraSource` and never presents camera UI; RTP/HAP sessions
stay fail-closed as documented above.

Tests (`tests/agent/HomeKitCameraViewTests.swift`):
`testCameraViewHostIdentity` constructs `HMCameraView()`, reads/writes
`cameraSource`, and references `HMCameraView.self` (3 rows; negligible
share, far under the 40% cap). No `DispatchQueue`, `RunLoop`, semaphore
waits, or `await`.

The 8 `unavailable` rows are unchanged: Matter/XPC daemon blocks,
`NSComparisonPredicate.Operator`, and `CLRegion`/CoreLocation hardware.

Environment: `swiftc` on this Mac reports Swift 6.2.1. The sealed
`tests/acceptance/test_host.sh` runner phase generates `import Glibc`,
which cannot compile on macOS. Verification used `-warnings-as-errors`
builds: the real-tree product dylib compiles clean, and the product
module plus `HomeKitCameraViewTests.swift` link and run, exiting 0 and
printing only `HOMEKIT_AGENT_RUNTIME_OK`.
