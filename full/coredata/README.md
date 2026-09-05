# CoreData (Linux starting point)

This directory is a clean-room Linux `CoreData` module for the OpenUIKit
framework fan-out. It is a working **in-memory** object graph. There is no
`sqlite3` under `full/` or `uikit/` (grep), so `NSSQLiteStoreType` is
fail-closed and listed rather than a durable Apple WAL/`Z*` store.

Isolated-gate success is not integrated Linux success. A future EC2 run must
build real guest Foundation and Dispatch, compile this module against those
`-I`/`-L` paths, link `tests/agent/CoreDataDependencyIdentity.swift`, and load
`libCoreData.dylib` under `LD_LIBRARY_PATH`.

## What is real

- Programmatic `NSManagedObjectModel` construction: entities, attributes
  (types, optionality, defaults), relationships with inverses, fetched
  properties, fetch indexes, uniqueness constraints, configurations, and
  fetch-request templates. Compiled `.mom`/`.momd` loading returns nil.
- `NSManagedObject` / `NSManagedObjectID` with `value(forKey:)` /
  `setValue`, primitive accessors, `willAccessValue` / `willChangeValue`
  (including to-many set-mutation), validation, faults, and **complete
  committed snapshots**. Nil is `NSNull`. Temporary objectIDs become
  permanent on save.
- Relationship inverse maintenance, relationship faulting after save, and
  delete rules: cascade, nullify, deny.
- `NSManagedObjectContext`: concurrency types, `perform` / `performAndWait`,
  insert/delete/save with documented validation error codes, `hasChanges`,
  registered/inserted/updated/deleted objects, rollback/reset/refresh,
  **undo disabled** (`undoManager` is always nil), parent-context save
  push, `mergeChanges(fromContextDidSave:)`,
  `automaticallyMergesChangesFromParent`, and merge-policy objects
  (error / rollback / overwrite / store-trump / object-trump).
- `NSPersistentStoreCoordinator` + `NSPersistentContainer` against
  `NSInMemoryStoreType`. `registerStoreClass` / `registeredStoreTypes` are
  wired into `addPersistentStore`. `loadPersistentStores` callbacks run.
- `NSFetchRequest` with **block** `NSPredicate` evaluation (comparison,
  compound, IN, CONTAINS, BEGINSWITH, ENDSWITH, relationship key paths).
  String `NSPredicate(format:)` and `NSSortDescriptor(key:)` are unavailable
  on swift-corelibs-foundation; tests use block predicates and comparator
  sort descriptors. Result types `.managedObjectResultType` /
  `.countResultType` / `.dictionaryResultType` / `.managedObjectIDResultType`
  and fetchLimit/offset still run.
- `NSFetchedResultsController`: sections, indexPath lookups, and delegate
  callbacks in willChange → section/object edits → didChange order.
- In-memory `NSBatchInsertRequest` / `NSBatchUpdateRequest` /
  `NSBatchDeleteRequest`.
- Public error codes with documented raw values (CoreDataErrors.h) and
  `NSFetchRequestExpressionType.rawValue == 50` (measured on Apple CoreData
  via `swift -e` on this host).

The isolated runtime probe `tests/agent/CoreDataRuntime.swift` prints
`COREDATA_AGENT_RUNTIME_OK`. The standalone EC2 client
`tests/agent/CoreDataDependencyIdentity.swift` prints
`COREDATA_DEPENDENCY_IDENTITY_OK` and is not executed by the isolated gate.

Coverage (wave-1 → depth pass → ledger repair): **88 → 1206 → 682 implemented** / 612 declared / 15 deferred / 10 unavailable of 1319 public IDs. Nine `NSExpression` / `UndoManager` rows stay deferred so warnings-as-errors builds on Linux Foundation. Methods and properties that compile but are not called by a focused `func test*()` are `declared` with a product-source anchor, not `implemented`.

## Fail-closed boundaries

- `NSSQLiteStoreType` is a **platform blocker**. No `sqlite3` exists in this
  tree. Unregistered SQLite `addPersistentStore` throws and does not create
  a file. `NSBinaryStoreType` also does not open.
- `NSManagedObjectModel(contentsOf:)` returns nil: compiled `.mom`/`.momd`
  bytes are proprietary and are not parsed.
- `NSPersistentCloudKitContainer.initializeCloudKitSchema` throws. Sharing
  and CloudKit record mutation APIs return false / fail.
- Ubiquity / iCloud store options are unavailable.
  `removeUbiquitousContentAndPersistentStore` throws.
- `NSMappingModel.inferredMappingModel` and `NSMigrationManager.migrateStore`
  throw. Staged/lightweight migration does not rewrite stores.
- Persistent history tokens are not produced; history fetch requests compile
  but do not invent transactions.
- `NSCoreDataCoreSpotlightDelegate` does not index. `CSSearchableIndex`
  methods are unavailable.
- `NSCoreDataVersionNumber` is exported as `0` because the current iOS 26.1
  numeric value was not in the Linux-visible seed inputs. Historical
  `NSCoreDataVersionNumber*` header constants are exported from public
  headers.
- `NSPersistentContainer.defaultDirectoryURL()` returns the conventional
  Application Support path and does **not** eagerly create directories or
  sqlite files.

## Deferred

- Combine `objectWillChange` on `NSManagedObject` (no Combine import in this
  isolated module).
- `NSFetchedResultsControllerDelegate` snapshot callback
  (`NSDiffableDataSourceSnapshot` is a UIKit type).
- `CKDatabase.Scope` on `NSPersistentCloudKitContainerOptions`.
- The class-var spelling of `defaultDirectoryURL` (Swift cannot declare it
  alongside the implemented class function).
- `NSExpression`-typed members (`derivationExpression`, mapping
  `sourceExpression` / `valueExpression`, `NSFetchRequestExpression`
  fetch/context expressions, entity spotlight display-name expression).
  swift-corelibs-foundation deprecates `NSExpression` under warnings-as-errors.
- `NSManagedObjectContext.undoManager` as Foundation `UndoManager` (the type
  is missing; undo stays disabled and `undo()` / `redo()` are no-ops).

See `oracle-questions.tsv` for Apple-oracle probes that must land before any
of those paths can claim success.

## Depth pass 2026-09

Second-pass work on `origin/agent/fw-coredata`, then a ledger repair after
merge-gate refusal at `24912ca7`. The in-memory store and fail-closed
SQLite/CloudKit/history/momd/migration boundaries are unchanged. Nine
`NSExpression`/`UndoManager` rows stay `deferred` so the module builds with
warnings-as-errors on this Linux Foundation.

**Coverage before / after this ledger repair** (1319 public IDs):

| | implemented | declared | deferred | unavailable |
| --- | ---: | ---: | ---: | ---: |
| Before (`24912ca7`, refused) | 1206 | 88 | 15 | 10 |
| After (focused `test:` evidence) | 682 | 612 | 15 | 10 |

Every `implemented` row now cites
`test:full/coredata/tests/agent/<File>Tests.swift#testName` naming a real
top-level synchronous `func testName()`. Rows without that observation are
`declared` as `source:full/coredata/<file>.swift#Symbol`. Enum / option-set
members and C `k…`/`err…`/`NS*Error` constants share two table-driven value
tests; no other test is cited by more than 40% of the remaining implemented
rows (largest: `testFailClosedSurfaces` at 49 / 207 ≈ 24%).

Top-5 implemented evidence distribution (682 rows):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 257 | 37.7% | `CoreDataCatalogTests.swift#testEnumOptionSetAndConstantValues` |
| 218 | 32.0% | `CoreDataErrorCodeTests.swift#testErrorCodes` |
| 49 | 7.2% | `CoreDataFailClosedTests.swift#testFailClosedSurfaces` |
| 23 | 3.4% | `CoreDataBatchTests.swift#testBatchRequests` |
| 20 | 2.9% | `CoreDataModelTests.swift#testModelMetadataAndStoreCoordinator` |

Focused tests live in `tests/agent/*Tests.swift` (also concatenated into
`CoreDataRuntime.swift` for the sealed v1 host probe):

| Family | Test |
| --- | --- |
| model construction | `testModelConstruction` |
| entity / attribute / relationship descriptions | `testEntityAttributeRelationshipDescriptions` |
| context insert / save / fetch | `testContextInsertSaveFetch` |
| faulting | `testFaulting` |
| predicates by operator | `testPredicatesByOperator` (`==`, `!=`, `<`, `>`, `>=`, `<=`, `CONTAINS`, `BEGINSWITH`, `ENDSWITH`, `IN`, `AND`, `OR`, `NOT`) |
| sort / limit / result types | `testSortLimitResultTypes` |
| FRC sections and change notifications | `testFRCSectionsAndChangeNotifications` |
| batch requests | `testBatchRequests` (count, objectIDs, statusOnly) |
| merge policies | `testMergePolicies` |
| error / CocoaError integers | `testErrorCodes` |
| enum / option-set / C constants | `testEnumOptionSetAndConstantValues` |

Queue, snapshot, child-isolation, store-registry, directory, version, and
fail-closed tests remain and are cited only by the identifiers they call.

Isolated-gate markers from this host:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
COREDATA_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreData dylib=libCoreData.dylib
```

Unresolved behavioral questions stay in `oracle-questions.tsv` (SQLite schema
errors, compiled `.momd` layout, lightweight migration, `perform(schedule:)`
reentrancy, CloudKit entitlement errors, `NSCoreDataVersionNumber` on iOS 26.1,
committed-snapshot nil boxing, child-save instance identity, FRC first-fetch
callback order).
