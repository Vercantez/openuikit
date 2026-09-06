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
- SwiftUI `CameraView` and `_HomeKit_SwiftUI` View modifiers are
  `not-applicable`.

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
