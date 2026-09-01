# CloudKit

Linux starting point for Apple's public `CloudKit` module, seeded from the
Xcode 26.1 iPhoneOS 26.1 symbol graph. This is a reviewable, fail-closed
host implementation. Isolated `test_host.sh` success is not integrated
Linux success and is not Apple iCloud behavioral parity.

## What is real

Local value types store what the caller puts in them:

- `CKRecord` field get/set (including Foundation `Data` and `Date`), `allKeys()`, `changedKeys()`, parent references, and iteration of set keys
- `CKRecord.ID` / `CKRecord.Reference` / `CKAsset` / `CKQuery` construction
- `CKRecordZone` / `CKRecordZone.ID` identity as constructed
- `CKError` as a typed bag (`code`, `userInfo`, `retryAfterSeconds` from that bag)
- `CKContainer.default()` singleton, named containers, and public/private/shared database wiring
- `CKUserIdentity.LookupInfo` stores the email/phone/record ID it was given
- `CKShare.url` is `nil`; `oneTimeURL(for:)` returns `nil`
- `CKShare.owner` uses unresolved identity with `unknown` / `none` / `unknown` metadata (not a fabricated accepted Apple participant)

Exact Apple constant string bytes and NS_ENUM raw integers remain oracle questions. The declarations exist so the module compiles; they are not claimed implemented.

## Fail-closed Apple boundary

Linux has no Apple identity service, iCloud network, or CloudKit database
daemon. Service calls never fabricate success:

- `accountStatus` completes with `.couldNotDetermine` and `CKError.notAuthenticated`
- save / fetch / identity discovery fail closed with the same error
- `CKDatabase.add(_:)` and `CKContainer.add(_:)` schedule the operation on a real Foundation `OperationQueue`; fail-closed completions are not invoked inline on the caller stack
- `CKNotification(fromRemoteNotificationDictionary:)` returns `nil`
- `CKRecord.init(coder:)` returns `nil`; `encodeSystemFields` does not emit an Apple archive
- `CKRecord.allTokens()` returns `[]` until tokenizer semantics are observed

## Deferred / unavailable

- **CKSyncEngine** and event/state types
- **CKLocationSortDescriptor** (`CLLocation`)
- **CKShare.AccessRequester.contact** / **CKShare.BlockedIdentity.contact** (Contacts)
- **CKShareTransferRepresentation** (Transferable / sharing UI)

`CKSystemSharingUIObserver` is inert: callbacks never fire.

## Tests

- `tests/agent/CloudKitRuntime.swift` — focused local + fail-closed probes; prints `CLOUDKIT_AGENT_RUNTIME_OK`
- `tests/agent/CloudKitDependencyIdentity.swift` — prepared EC2 probe that passes real guest Foundation `Data`, `Date`, `URL`, `NSPredicate`, `OperationQueue`, `NSCoder`, and `Sequence` values through CloudKit APIs. A future clean EC2 run must build guest Foundation first, build `libCloudKit.dylib` against those `-I/-L` paths, link a client importing both modules, run with `LD_LIBRARY_PATH`, and confirm the runtime marker plus that `libCloudKit.dylib` is loaded.

```sh
bash tests/acceptance/test_host.sh
```
