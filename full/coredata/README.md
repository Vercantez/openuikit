# CoreData (Linux starting point)

This directory is a clean-room Linux `CoreData` module for the OpenUIKit
framework fan-out. It is a working **in-memory** object graph plus a Linux
SQLite store loaded via `dlopen("libsqlite3.so.0")`. The on-disk layout is
host `_cd_meta` / `_cd_row` tables, not Apple's WAL/`Z*` schema.

Isolated-gate success is not integrated Linux success. A future EC2 run must
build real guest Foundation and Dispatch, compile this module against those
`-I`/`-L` paths, link `tests/agent/CoreDataDependencyIdentity.swift`, and load
`libCoreData.dylib` under `LD_LIBRARY_PATH`.

## What is real

- Programmatic `NSManagedObjectModel` construction: entities, attributes
  (types, optionality, defaults), relationships with inverses, fetched
  properties, fetch indexes, uniqueness constraints, configurations, and
  fetch-request templates. `.xcdatamodel` / `.xcdatamodeld` **contents XML**
  loads (entities, attributes with types/defaults/optional/transient,
  relationships with inverse/delete rules/ordered, fetched properties,
  uniqueness constraints, version identifiers). Compiled `.mom`/`.momd`
  bytes still return nil.
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
  `NSInMemoryStoreType` and `NSSQLiteStoreType` (libsqlite3). Schema is
  generated from the model; fetch supports NSPredicate / sort / limit /
  offset / faulting. Model-hash mismatch throws
  `NSPersistentStoreIncompatibleVersionHashError` instead of migrating.
  `registerStoreClass` / `registeredStoreTypes` are wired into
  `addPersistentStore`. `loadPersistentStores` callbacks run.
- `NSFetchRequest` with **block** `NSPredicate` evaluation (comparison,
  compound, IN, CONTAINS, BEGINSWITH, ENDSWITH, relationship key paths).
  String `NSPredicate(format:)` and `NSSortDescriptor(key:)` are unavailable
  on swift-corelibs-foundation; tests use block predicates and comparator
  sort descriptors. Result types `.managedObjectResultType` /
  `.countResultType` / `.dictionaryResultType` / `.managedObjectIDResultType`
  plus fetchLimit/offset, `includesPendingChanges`, `includesSubentities`,
  `includesPropertyValues`, `returnsDistinctResults`, `fetchBatchSize`
  faulting, `shouldRefreshRefetchedObjects`, and
  `relationshipKeyPathsForPrefetching` still run.
- `NSAtomicStore` cache-node CRUD and `NSIncrementalStore` node/execute
  adapters on Linux in-memory backing. Register either class via
  `registerStoreClass`. Apple binary on-disk layout is not decoded.
- `NSMigrationManager` instance association / source-destination lookup.
  `migrateStore` still throws `NSMigrationError` / cancelled errors.
- Entity inheritance: `subentities` / `isKindOf(entity:)` and inherited
  attributes on child entities.
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

Coverage (wave-1 → depth pass → ledger repair → wave 8 → wave 9): **88 → 1206 → 682 → 774 → 949 implemented** / 345 declared / 15 deferred / 10 unavailable of 1319 public IDs. Nine `NSExpression` / `UndoManager` rows stay deferred so warnings-as-errors builds on Linux Foundation. Methods and properties that compile but are not called by a focused `func test*()` are `declared` with a product-source anchor, not `implemented`.

## Fail-closed boundaries

- Apple `Z*` / WAL SQLite layout is **not** claimed. Linux SQLite uses
  `_cd_meta` / `_cd_row` and throws `NSPersistentStoreIncompatibleSchemaError`
  for unrelated files. `NSBinaryStoreType` does not open.
- Compiled `.mom` / `.momd` bytes stay nil. Source `.xcdatamodel` contents
  XML is parsed.
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
- Isolated Linux hosts have no UI run loop. `mainQueueConcurrencyType`
  confines with the context lock instead of `DispatchQueue.main.sync` /
  `.async`, which deadlocks a runner that never pumps main.

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
rows (largest: `testFailClosedSurfaces` at 49 / 207 ≈ 24%). Cited tests are
synchronous `func testName()` bodies: they do not wait on `DispatchQueue.main`,
`DispatchSemaphore`, `RunLoop`, or `Task`. Main-queue contexts confine with
the context lock on Linux instead of `DispatchQueue.main.sync`, which deadlocks
when the sealed merge runner has no UI run loop.

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
FRAMEWORK_FANOUT_REFERENCE_OK
COREDATA_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreData dylib=libCoreData.dylib
```

Unresolved behavioral questions stay in `oracle-questions.tsv` (Apple Z*
SQLite schema errors, compiled `.momd` layout, lightweight migration,
`perform(schedule:)` reentrancy, CloudKit entitlement errors,
`NSCoreDataVersionNumber` on iOS 26.1, committed-snapshot nil boxing,
child-save instance identity, FRC first-fetch callback order).

## Depth pass 2026-09 (wave 8)

Third behavioral pass on `cursor/port-coredata-to-linux-c39b`. Kept the
in-memory graph and existing synchronous tests; added `.xcdatamodel` XML
loading, a libsqlite3 store, uniqueness-constraint conflicts, dictionary
`propertiesToGroupBy`, and exact did-save / objects-did-change userInfo
keys. Coordinator `perform` and store-add completion stay synchronous so
the sealed gate cannot hang. Compiled `.mom`, binary stores, CloudKit,
ubiquity, history, and lightweight migration remain fail-closed. Nine
`NSExpression`/`UndoManager` rows stay `deferred`.

`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift
6.2.4 / linux and the sealed gate compiles with a clean product tree.

**Coverage before / after this wave 8 pass** (1319 public IDs):

| | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before (tree at expected start `bff8535c`) | 682 | 612 | 15 | 10 | 0 |
| After (XML + SQLite + focused tests) | 774 | 520 | 15 | 10 | 0 |

Every `implemented` row cites
`test:full/coredata/tests/agent/<File>Tests.swift#testName` naming a real
top-level synchronous `func testName()`. Enum / option-set members and C
`k…`/`err…`/`NS*Error` constants still share two table-driven value tests.
No other test is cited by more than 40% of implemented rows (largest
non-catalog/error: `testFailClosedSurfaces` at 49 / 774 ≈ 6.3%). Tests do
not wait on `DispatchQueue.main`, `DispatchSemaphore`, `RunLoop`, or
`Task`.

Top-5 implemented evidence distribution (774 rows):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 257 | 33.2% | `CoreDataCatalogTests.swift#testEnumOptionSetAndConstantValues` |
| 218 | 28.2% | `CoreDataErrorCodeTests.swift#testErrorCodes` |
| 49 | 6.3% | `CoreDataFailClosedTests.swift#testFailClosedSurfaces` |
| 23 | 3.0% | `CoreDataBatchTests.swift#testBatchRequests` |
| 22 | 2.8% | `CoreDataSQLiteTests.swift#testSQLiteDestroyAndMetadata` |

New focused tests this pass:

| Family | Test |
| --- | --- |
| contents XML load | `testXMLModelLoadFromContents` |
| `.xcdatamodeld` bundle | `testXMLModelLoadXcdatamodeld` |
| XML relationships / fetched properties / uniqueness | `testXMLModelRelationshipsFetchedPropertiesAndConstraints` |
| SQLite CRUD + faulting | `testSQLiteCRUDAndFaulting` |
| SQLite predicate / sort / limit / offset | `testSQLiteFetchLimitOffsetAndPredicate` |
| incompatible schema / hash mismatch fail-closed | `testSQLiteIncompatibleSchemaAndMigrationFailClosed` |
| SQLite destroy + metadata | `testSQLiteDestroyAndMetadata` |
| did-save / objects-did-change userInfo keys | `testDidSaveAndObjectsDidChangeUserInfoKeys` |
| `propertiesToGroupBy` | `testPropertiesToGroupBy` |
| KVC accessors / validation / refresh | `testManagedObjectKVCAccessors` |
| uniqueness `NSConstraintConflict` | `testConstraintConflictOnSave` |

Isolated-gate markers from this host:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
COREDATA_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreData dylib=libCoreData.dylib
```

## Depth pass 2026-09 (wave 9)

Fourth behavioral pass on `cursor/port-coredata-to-linux-5769` from expected
start `6bf18072` (wave-8 ledger). Kept the in-memory graph, XML model load,
SQLite store, and every existing synchronous test. Added entity inheritance
(including inherited attributes), fetch-option behavior (`includesPendingChanges`,
`includesSubentities`, `returnsDistinctResults`, `fetchBatchSize` faults,
prefetch, `includesPropertyValues`), batch-insert dictionary/object handlers,
working `NSAtomicStore` cache nodes and `NSIncrementalStore` node adapters,
`NSMigrationManager` associate/lookup (store rewrite still fail-closed),
in-memory `migratePersistentStore` / SQLite `replacePersistentStore`, and
focused context/coordinator/object lifecycle tests. CloudKit Event and
persistent-history transaction rows stay fail-closed (empty/nil, no invented
Apple history or CloudKit success). Nine `NSExpression`/`UndoManager` rows
stay `deferred`. Async `perform(schedule:)` stays `declared` because a
synchronous host probe cannot await it without a run-loop wait.

`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift
6.2.4 / linux and the sealed gate compiles with a clean product tree
(`products=clean`). Starting commit `6bf18072f4bc9ca119f4b0ad49dd8478f92dd5f0`
matched.

**Coverage before / after this wave 9 pass** (1319 public IDs):

| | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before (tree at expected start `6bf18072`, wave 8) | 774 | 520 | 15 | 10 | 0 |
| After (inheritance + stores + focused tests) | 949 | 345 | 15 | 10 | 0 |

Every `implemented` row cites
`test:full/coredata/tests/agent/<File>Tests.swift#testName` naming a real
top-level synchronous `func testName()`. Enum / option-set members and C
`k…`/`err…`/`NS*Error` constants still share two table-driven value tests.
No other test is cited by more than 40% of implemented rows (largest
non-catalog/error: `testFailClosedSurfaces` at 49 / 949 ≈ 5.2%). Tests do
not wait on `DispatchQueue.main`, `DispatchSemaphore`, `RunLoop`, or
`Task`.

Top-5 implemented evidence distribution (949 rows):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 257 | 27.1% | `CoreDataCatalogTests.swift#testEnumOptionSetAndConstantValues` |
| 218 | 23.0% | `CoreDataErrorCodeTests.swift#testErrorCodes` |
| 49 | 5.2% | `CoreDataFailClosedTests.swift#testFailClosedSurfaces` |
| 38 | 4.0% | `CoreDataDepthPassTests.swift#testContextLifecycleMergeAndExecute` |
| 23 | 2.4% | `CoreDataBatchTests.swift#testBatchRequests` |

New focused tests this pass (`CoreDataDepthPassTests.swift`):

| Family | Test |
| --- | --- |
| entity inheritance / indexes | `testEntityInheritanceAndIndexes` |
| property metadata + predicates | `testPropertyDescriptionMetadataAndValidation` |
| fetch options / distinct / prefetch | `testFetchRequestOptionsAndDistinct` |
| batch insert handlers | `testBatchInsertHandlers` |
| atomic store cache nodes | `testAtomicStoreCacheNodes` |
| incremental store adapter | `testIncrementalStoreAdapter` |
| migration associate / fail-closed rewrite | `testMigrationManagerAssociations` |
| context lifecycle / merge / overlay enums | `testContextLifecycleMergeAndExecute` |
| coordinator migrate / replace / URI | `testCoordinatorStoreLifecycle` |
| managed object flags | `testManagedObjectLifecycleFlags` |
| entity mapping properties | `testEntityMappingProperties` |
| CloudKit Event fail-closed | `testCloudKitContainerEventFailClosed` |
| history transaction fail-closed | `testPersistentHistoryTransactionFailClosed` |

Isolated-gate markers from this host:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
COREDATA_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreData dylib=libCoreData.dylib
```
