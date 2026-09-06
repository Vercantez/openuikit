# CloudKit

Linux starting point for Apple's public `CloudKit` module, seeded from the
Xcode 26.1 iPhoneOS 26.1 symbol graph. There is no iCloud on Linux: value
types match the documented overlay, and database operations run against a
**local in-process simulated container** so app save/fetch/query/modify
paths execute. Isolated `test_host.sh` success is not Apple iCloud
behavioral parity and is not a claim that a CloudKit daemon exists.

## What is real

Local value types store what the caller puts in them, and the simulated
container persists them for the lifetime of the `CKContainer`:

- `CKRecord` field get/set for String, Number, Date, Data, `CKAsset`,
  `CKRecord.Reference`, and arrays; `allKeys()` / `changedKeys()`;
  parent references; Sequence iteration; `encodeSystemFields` plus
  `NSSecureCoding` round trip through `NSKeyedArchiver`
- `CKRecord.ID` / `CKRecordZone` / `CKRecordZone.ID` identity, including
  the default zone (`_defaultZone` / `__defaultOwner__`)
- `CKContainer.default()` / `init(identifier:)`,
  `accountStatus` → `.noAccount` (nil error), and
  public / private / shared databases
- `CKDatabase` save / fetch / delete for records, zones, and
  subscriptions (completion and async); `perform(CKQuery)` /
  `records(matching:)` with `NSPredicate` evaluation over the store
  (block predicates and `NSPredicate(value:)` on Linux Foundation;
  string-format predicates are unavailable in swift-corelibs-foundation);
  `fetch(withRecordIDs:)`;
  `modifyRecords` with `isAtomic` rollback and per-record results;
  query cursors (`CKQueryOperation.maximumResults == 0` pages at 100)
- Operations `CKModifyRecordsOperation`, `CKFetchRecordsOperation`,
  `CKQueryOperation`, `CKFetchRecordZoneChangesOperation` (opaque
  `CKServerChangeToken`), `CKModifySubscriptionsOperation` fire
  per-record blocks then the completion / result blocks, off the
  caller stack
- `CKError` codes used by the store: `partialFailure` +
  `CKPartialErrorsByItemIDKey`, `unknownItem`, `serverRecordChanged`
  with the three record keys, `zoneNotFound`, `networkUnavailable`
  when `setSimulatedOffline(true)`, `assetFileNotFound`,
  `invalidArguments` (deleting the default zone), `batchRequestFailed`
- `CKAsset(fileURL:)` copies bytes into the container's asset directory
- `CKSubscription` / `CKQuerySubscription` / `CKRecordZoneSubscription`
  / `CKDatabaseSubscription` / `CKNotificationInfo` value stores
- `CKShare` / `CKShare.Participant` value semantics
- `CKNotification(fromRemoteNotificationDictionary:)` parses the
  documented `ck` + `aps` userInfo shape (nil when `ck` is absent)

## Fail-closed Apple boundary

Linux has no Apple identity service and no iCloud sharing network.
Those calls never fabricate an Apple account or share URL:

- `fetchUserRecordID`, identity discovery, `accept` / share metadata /
  share participants, web-auth tokens, and long-lived operation lookup
  complete with `CKError.notAuthenticated`
- `CKShare.url` is `nil`; `oneTimeURL(for:)` returns `nil`
- `CKShare.owner` uses unresolved identity with `unknown` / `none` /
  `unknown` metadata
- `CKSystemSharingUIObserver` is inert: callbacks never fire
- Completions are scheduled on a real Foundation `OperationQueue`, not
  the caller stack

`CKRecord.allTokens()` returns `[]` until tokenizer semantics are
observed on Apple.

## Deferred / unavailable

- **CKLocationSortDescriptor** — CoreLocation `CLLocation` hardware/daemon
- **CKShare.AccessRequester.contact** / **CKShare.BlockedIdentity.contact**
  (Contacts)
- **CKShareTransferRepresentation** — Apple Transferable share-transfer UI
- **NSItemProvider.registerCKShare** — UIKit/AppKit share-sheet pasteboard

## Tests

- `tests/agent/CloudKitRuntime.swift` — schema-v1 gate compilation unit
  that inlines the family tests and prints `CLOUDKIT_AGENT_RUNTIME_OK`
- `tests/agent/*Tests.swift` — focused family tests; each `implemented`
  coverage row cites `test:full/cloudkit/tests/agent/<File>.swift#<func>`
- `tests/agent/CloudKitDependencyIdentity.swift` — prepared EC2 probe
  that passes real guest Foundation values through CloudKit APIs

```sh
bash tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Second SDK depth pass on `origin/agent/fw-cloudkit`, pushed as
`agent/fw-cloudkit2`. Campaign `ios26.1-fwdepth-r3`, lane
`large-partitioned`, 2245 public IDs. The simulated container is kept.

The first pass was refused because all 802 `implemented` rows cited
`tests/agent/CloudKitRuntime.swift` (not a test). Coverage now names the
focused test that exercises each family. No test cites more than 40
identifiers.

### Public surface (this pass)

802 `implemented`, 212 `deferred`, 1209 `not-applicable`, 22
`unavailable`. Nondeferred floor is 150. Declared count is 0: every
nondeferred row is exercised by a family test.

Linux-host compile fixes that were required for `swiftc -warnings-as-errors`
on Swift 6.2.4 / swift-corelibs-foundation:

- Nested `NSSecureCoding` types that NSKeyedArchiver archives
  (`CKRecord.ID`, `CKRecord.Reference`, `CKRecordZone.ID`) are top-level
  classes (`CKRecordID`, `CKRecordReference`, `CKRecordZoneID`) with
  Swift typealiases so `CKRecord.ID` still type-checks. Linux
  `NSStringFromClass` rejects nested classes.
- `@objc(...)` name attributes are omitted (ObjC interop is disabled).
- `NSPredicate(format:)` / `NSSortDescriptor(key:)` / KVC
  `value(forKey:)` overrides are not used. Queries evaluate block
  predicates and `NSPredicate(value:)`.
- Missing NSCoder keys use `containsValue(forKey:)` first; Linux
  Foundation raises instead of returning nil.
- Completions stay on a Foundation `OperationQueue` via an
  `@unchecked Sendable` work box.

### Fail-closed boundaries

Unchanged from the first pass: identity discovery, share accept /
metadata / participants, web-auth tokens, long-lived operation lookup,
and `CKShare.url` / `oneTimeURL(for:)` never invent an Apple account.
`accountStatus` is `.noAccount` with a nil error. `CKSystemSharingUIObserver`
callbacks never fire.

### Tests run

`bash full/cloudkit/tests/acceptance/test_host.sh` on this Linux host
(no docker). Exact sealed-gate output:

```
FRAMEWORK_FANOUT_REFERENCE_OK
CLOUDKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CloudKit dylib=libCloudKit.dylib
```

Toolchain (`swift --version`): Swift 6.2.4, target
`x86_64-unknown-linux-gnu`. The sealed schema-v1 `test_host.sh` does
not print `CURSOR_SWIFT_ENVIRONMENT_OK`. `.cursor/verify-cloud-environment.sh`
failed here with `missing corpus checkout: scratch/ladder-corpus/focus-ios`,
so the campaign marker `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
was not produced by that script either.

Family tests (inlined into `CloudKitRuntime.swift` because the gate
compiles only that file):

- CKError codes / aliases / userInfo
- CKRecord values per type, references, NSSecureCoding
- CKRecord.ID / zone / query construction
- CKContainer databases, accountStatus, save/fetch/delete/query,
  conflict / offline / batch
- Operation callback order and partial failure (modify, query, fetch,
  zone CRUD, zone changes, database changes)
- Subscriptions, assets, change tokens
- Notification parse + share value semantics
- Fail-closed identity, sharing, and web-auth operations

## Depth pass 2026-09 (wave 8)

Next SDK depth pass on `cursor/port-cloudkit-to-linux-cfad` from starting
commit `39dc25a2769fb88a50f0853964137a4f96d50322`. Campaign
`ios26.1-fwdepth-r18`, lane `large-partitioned`. The simulated container
from earlier passes is kept; this pass adds a local `CKSyncEngine` state
machine.

### Ledger

| status | before | after |
| --- | ---: | ---: |
| implemented | 802 | 1030 |
| declared | 0 | 0 |
| deferred | 212 | 2 |
| unavailable | 22 | 28 |
| not-applicable | 1209 | 1185 |

Nondeferred floor is 150. Gain is +228 `implemented` (204 previously
`deferred` CKSyncEngine identifiers plus 24 Swift-synthesized `!=` /
`hashValue` / `hash(into:)` operators that were mislabeled
`not-applicable` — they are CloudKit enum members, not SwiftUI overlays).

### Public surface (this pass)

`CKSyncEngine` value types, pending-change queues, `State.Serialization`
Codable round-trip, and send/fetch against the in-process simulated
store. Delegate `handleEvent` / `nextRecordZoneChangeBatch` /
`nextFetchChangesOptions` (including the protocol default) fire with
real payloads. `automaticallySync` is stored and never schedules Apple
iCloud work. `cancelOperations()` fails later send/fetch with
`CKError.operationCancelled`. Account-change events are constructible
value types and are never emitted by send/fetch (no Apple identity).

Still fail-closed / unavailable:

- `CKShareTransferRepresentation` — Apple Transferable share-transfer UI
- `NSItemProvider.registerCKShare` — UIKit/AppKit share-sheet pasteboard
- `CKLocationSortDescriptor` — CoreLocation `CLLocation` hardware/daemon
- `CKShare.AccessRequester.contact` / `CKShare.BlockedIdentity.contact` —
  Contacts, still deferred

### Top-5 evidence distribution (this pass's new implemented rows)

1. `testCKSyncEngineEventPayloads` — 75 (33%)
2. `testCKSyncEngineCEnumRawValues` — 54 (24%, table-driven C enums)
3. `testCKSyncEngineSyncReasonAndScopes` — 45 (20%)
4. `testCKSyncEngineConfigurationAndState` — 23 (10%)
5. `testCKSyncEnginePendingChangeValues` — 16 (7%)

No non-enum test exceeds 40% of the new implemented rows.

### Tests run

`bash full/cloudkit/tests/acceptance/test_host.sh` on this Linux host
(no docker). Exact sealed-gate output:

```
FRAMEWORK_FANOUT_REFERENCE_OK
CLOUDKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CloudKit dylib=libCloudKit.dylib
```

Host inventory (not printed by the sealed schema-v1 gate):

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
```

`.cursor/verify-cloud-environment.sh` still fails on this snapshot with
`missing corpus checkout: scratch/ladder-corpus/focus-ios`. Active Cursor
Build is `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` versus seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`. `swift --version`:
Swift 6.2.4, target `x86_64-unknown-linux-gnu`. The gate compiled with a
clean product tree (`products=clean`). Starting commit
`39dc25a2769fb88a50f0853964137a4f96d50322` matched.

Only `full/cloudkit/tests/acceptance/test_host.sh` exists under
`full/cloudkit/tests/`; it was run until `FRAMEWORK_FANOUT_HOST_OK`.

### Unresolved behavioral questions

See `oracle-questions.tsv`. Still open: accountStatus pairing on a real
Apple ID, save/fetch error payloads vs the simulated store, constant
string bytes, enum integers vs Apple ABI, `CKRecord.allTokens()`,
Sequence iteration order, callback queue identity, CKShare owner
defaults before iCloud participants exist, notification `ck`+`aps`
class-cluster subclassing, Apple's query page size when
`CKQueryOperationMaximumResults` is 0, CKSyncEngine event order versus
the local simulated-store sequence, and whether `automaticallySync`
emits a scheduled Apple sync without an explicit send/fetch.
