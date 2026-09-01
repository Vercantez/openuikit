# CloudKit

Linux starting point for Apple's public `CloudKit` module, seeded from the
Xcode 26.1 iPhoneOS 26.1 symbol graph. This is a reviewable, fail-closed
host implementation. It is not wired into the shared guest package and it
is not a claim of Apple iCloud behavioral parity.

## What is real

Local value types work without a network:

- `CKRecord`, `CKRecord.ID`, `CKRecord.Reference`, field get/set, `changedKeys()`, parent references, and `CKRecordKeyValueIterator`
- `CKRecordZone` / `CKRecordZone.ID`, including the default zone name `_defaultZone`
- `CKAsset` file URLs, `CKQuery` construction, `CKSubscription` objects
- `CKError` / `CKError.Code` with public numeric codes and `CKErrorDomain`
- `CKContainer` identity (`default()` singleton, named containers, public/private/shared databases)
- `CKUserIdentity.LookupInfo` construction from email, phone, or record ID
- `CKShare` as a local `CKRecord` subclass (`url` stays `nil`; no share link is invented)

Constants such as `CKCurrentUserDefaultName`, `CKOwnerDefaultName`,
`CKRecordTypeUserRecord`, and `CKRecordTypeShare` follow the public headers.

## Fail-closed Apple boundary

Linux has no Apple identity service, iCloud network, or CloudKit database
daemon. The implementation never fabricates:

- an available iCloud account (`accountStatus` completes with `.couldNotDetermine` and `CKError.notAuthenticated`)
- a user record ID, share metadata, web auth token, or change token from Apple
- a successful `save` / `fetch` / `modify` / `query` against iCloud
- a parsed remote-notification payload (`CKNotification(fromRemoteNotificationDictionary:)` returns `nil`)

`CKDatabase.add(_:)` and `CKContainer.add(_:)` start operations, which then
invoke their completion blocks once with `CKError.notAuthenticated`.
Async overlays throw the same error.

## Deferred / unavailable

- **CKSyncEngine** and its event/state types: unpublished Apple sync-engine behavior
- **CKLocationSortDescriptor**: needs `CLLocation` / CoreLocation
- **CKShare.AccessRequester.contact** / **CKShare.BlockedIdentity.contact**: need Contacts
- **CKShareTransferRepresentation**: Transferable / sharing UI, unavailable on this host
- **NSCoder** Apple system-field archives: `encodeSystemFields` is a no-op; coder inits fail closed

`CKSystemSharingUIObserver` is an inert observer: its callbacks never fire
because there is no sharing UI.

## Tests

`tests/agent/CloudKitRuntime.swift` exercises local records/zones/errors and
the fail-closed container/database/operation boundary, then prints
`CLOUDKIT_AGENT_RUNTIME_OK`.

Run the host gate:

```sh
bash full/cloudkit/tests/acceptance/test_host.sh
```
