# CloudKit SDK depth (agent/fw-cloudkit)

Local in-process simulated CloudKit container for the Linux `CloudKit`
module in `full/cloudkit/`. No iCloud, no Apple identity: documented
value types plus database operations against a process-local store so
app save/fetch/query/modify paths run. Sharing and identity discovery
stay fail-closed.

## Before / after (coverage.tsv, 2245 public IDs)

| status | before (wave-1 seed) | after |
|---|---|---|
| implemented | 130 | **802** |
| declared | 672 | 0 |
| deferred | 212 | 212 (CKSyncEngine, CLLocation sort, Contacts `.contact`) |
| unavailable | 22 | 22 (CKShareTransferRepresentation) |
| not-applicable | 1209 | 1209 |

Non-not-applicable nondeferred surface is 802 (implemented). Target was
implemented ≥ 700.

## What was measured (`tests/agent/CloudKitRuntime.swift`)

Host gate: `bash tests/acceptance/test_host.sh` →
`CLOUDKIT_AGENT_RUNTIME_OK` / `FRAMEWORK_FANOUT_HOST_OK`.

- `accountStatus` → `.noAccount`, error `nil` (no iCloud account).
- Default zone `_defaultZone` / `__defaultOwner__` exists; deleting it
  returns `CKError.invalidArguments`. Missing zone → `zoneNotFound`.
- Record save/fetch/delete (async + completion). `CKAsset(fileURL:)`
  copies bytes; missing file → `assetFileNotFound`. Returned asset URL
  is not the caller path.
- `NSPredicate(format: "title == %@", "Hello")` matches over the store
  via `CKRecord.value(forKey:)`. `resultsLimit` 0 (`maximumResults`)
  pages at **100**; cursor continues the remainder.
- `modifyRecords` atomic: one `zoneNotFound` rolls back the sibling
  insert; completion is `partialFailure` with
  `CKPartialErrorsByItemIDKey`; per-record progress/save blocks fire
  before the completion, then `modifyRecordsResultBlock`. Completions
  are not inline on `CKDatabase.add`.
- `ifServerRecordUnchanged` after an intervening save →
  `serverRecordChanged` with client / server / ancestor records.
- `setSimulatedOffline(true)` → `networkUnavailable`.
- `encodeSystemFields` + `NSKeyedArchiver` round trip restores
  `recordType` / `recordID`. Notification parse: missing `ck` → nil;
  documented `ck`+`aps` fills `notificationType`,
  `containerIdentifier`, `subscriptionID`, `alertBody`.
- Identity/sharing (`fetchUserRecordID`, discover, accept, share
  metadata) remain `notAuthenticated`.

Open questions stay in `oracle-questions.tsv` (Apple string bytes,
tokenizer, callback queue identity, Apple's chosen page size for
`maximumResults == 0`).
