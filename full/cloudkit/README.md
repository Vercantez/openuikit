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
  (documented comparison / compound / TRUEPREDICATE subset via
  Foundation KVC on the record); `fetch(withRecordIDs:)`;
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

- **CKSyncEngine** and event/state types
- **CKLocationSortDescriptor** (`CLLocation` is not a declared
  CloudKit seed dependency)
- **CKShare.AccessRequester.contact** / **CKShare.BlockedIdentity.contact**
  (Contacts)
- **CKShareTransferRepresentation** (Transferable / sharing UI)

## Tests

- `tests/agent/CloudKitRuntime.swift` — simulated store + fail-closed
  sharing/identity; prints `CLOUDKIT_AGENT_RUNTIME_OK`
- `tests/agent/CloudKitDependencyIdentity.swift` — prepared EC2 probe
  that passes real guest Foundation values through CloudKit APIs

```sh
bash tests/acceptance/test_host.sh
```
