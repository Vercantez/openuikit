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

Coverage (wave-1 → depth pass → ledger repair → wave 8 → wave 9 → wave 10): **88 → 1206 → 682 → 774 → 949 → 1283 implemented** / 11 declared / 15 deferred / 10 unavailable of 1319 public IDs. Nine `NSExpression` / `UndoManager` rows stay deferred so warnings-as-errors builds on Linux Foundation. Methods and properties that compile but are not called by a focused `func test*()` are `declared` with a product-source anchor, not `implemented`.

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
- Persistent history is a Linux-local log gated by
  `NSPersistentHistoryTrackingKey`. It is not Apple's private history
  entities or transaction schema; `NSPersistentHistoryChange.entityDescription`
  stays nil. Without the tracking option the log stays empty.
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

## Depth pass 2026-09 (wave 10)

Fifth behavioral pass on `cursor/port-coredata-to-linux-6ccb` from expected
start `39dc25a2769fb88a50f0853964137a4f96d50322` (wave-9 ledger). Kept the
in-memory graph, XML model load, SQLite store, inheritance, batch/atomic/
incremental adapters, and every existing synchronous test. Added:

- Linux-local persistent history when `NSPersistentHistoryTrackingKey` is
  set (insert/update/delete, fetch/delete requests, tokens). Apple private
  history entities stay nil.
- `NSPersistentStoreDescription` option merge (`isReadOnly`, timeout,
  sqlite pragmas, migrate/infer flags) and read-only save refusal.
- SQLite `PRAGMA` application after open (sanitized names/values).
- `NSEntityMigrationPolicy.createDestinationInstances` copies matching
  attributes and associates them. `NSManagedObjectModelReference(fileURL:)`
  loads contents XML. Model merge reindexes `entitiesByName`.
- `NSAsynchronousFetchRequest` completion runs **synchronously** on execute
  (no run-loop wait). `performBackgroundTask` uses `performAndWait`.
- Validation / merge-policy errors populate `NSValidationObjectErrorKey`,
  `NSAffectedObjectsErrorKey`, and typed save-conflict userInfo.
- FRC section `indexTitle` / `objects` and synchronous delegate diffs.
- CloudKit event requests stay empty; Spotlight index deletion completes
  synchronously and remains fail-closed.

Async `perform(schedule:)`, async `performBackgroundTask`, and coordinator
async `perform` stay `declared` so the sealed gate cannot hang. Eight
`init(coder:)` rows stay `declared` because the Linux `NSCoder` path does
not round-trip model objects. Nine `NSExpression`/`UndoManager` rows stay
`deferred`. Ten ubiquity/Spotlight daemon rows stay `unavailable`.

`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift
6.2.4 / linux and the sealed gate compiles with a clean product tree
(`products=clean`). Starting commit
`39dc25a2769fb88a50f0853964137a4f96d50322` matched.

**Coverage before / after this wave 10 pass** (1319 public IDs):

| | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before (tree at expected start `39dc25a2`, wave 9) | 949 | 345 | 15 | 10 | 0 |
| After (history + description + focused tests) | 1283 | 11 | 15 | 10 | 0 |

Every `implemented` row cites
`test:full/coredata/tests/agent/<File>Tests.swift#testName` naming a real
top-level synchronous `func testName()`. Enum / option-set members and C
`k…`/`err…`/`NS*Error` constants still share two table-driven value tests
(including OptionSet array-literal init). No other test is cited by more
than 40% of implemented rows (largest non-catalog/error:
`testFailClosedSurfaces` at 49 / 1283 ≈ 3.8%). Tests do not wait on
`DispatchQueue.main`, `DispatchSemaphore`, `RunLoop`, or `Task`.

Top-5 implemented evidence distribution (1283 rows):

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 401 | 31.3% | `CoreDataCatalogTests.swift#testEnumOptionSetAndConstantValues` |
| 218 | 17.0% | `CoreDataErrorCodeTests.swift#testErrorCodes` |
| 49 | 3.8% | `CoreDataFailClosedTests.swift#testFailClosedSurfaces` |
| 38 | 3.0% | `CoreDataDepthPassTests.swift#testContextLifecycleMergeAndExecute` |
| 23 | 1.8% | `CoreDataBatchTests.swift#testBatchRequests` |

New focused tests this pass (`CoreDataWave10Tests.swift`):

| Family | Test |
| --- | --- |
| store description / read-only / objectID store | `testPersistentStoreDescriptionOptionsAndReadOnly` |
| attribute flags / versionHash | `testAttributeDescriptionFlagsAndVersionHash` |
| model merge / configurations / templates | `testManagedObjectModelMergeConfigurationsAndTemplates` |
| local persistent history | `testPersistentHistoryChangeLocalTracking` |
| entity migration policy copy | `testEntityMigrationPolicyCreatesDestinationInstances` |
| FRC delegate diffs / section titles | `testFetchedResultsControllerDelegateDiffAndTitles` |
| CocoaError validation / save conflicts | `testCocoaErrorValidationAndSaveConflictUserInfo` |
| merge conflict snapshots | `testMergeConflictSnapshotProperties` |
| CloudKit event request fail-closed | `testPersistentCloudKitContainerEventRequestFailClosed` |
| container + synchronous background task | `testPersistentContainerSurfaceAndBackgroundTask` |
| async fetch as sync host driver | `testAsynchronousFetchRequestSynchronousHostDriver` |
| Spotlight delegate fail-closed | `testCoreSpotlightDelegateFailClosedSurface` |
| store init / exporter / StoreType | `testPersistentStoreInitReadOnlyAndSpotlightExporter` |
| model reference / custom migration stage | `testManagedObjectModelReferenceAndCustomMigrationStage` |
| mapping model / StoreType migrateStore | `testMappingModelFailClosedAndEntityMappings` |
| atomic / incremental nodes | `testAtomicAndIncrementalNodeProperties` |
| coordinator StoreType overloads | `testCoordinatorSwiftStoreTypeOverloads` |

Isolated-gate markers from this host:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
COREDATA_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreData dylib=libCoreData.dylib
```

## Depth pass local repair (wave 18, 2026-09-06)

Repaired cloud head `f8b0fe33` from
`platform/cursor/port-coredata-to-linux-6ccb` on `agent/fw-coredata-r`,
merging current `origin/main` (`c1973365`) without CoreData conflicts.
The merged diff against main is confined to `full/coredata/`; all existing
implemented rows and tests are retained. The wave-10 success markers above
were reported by the cloud branch; the operator refused that head before
its runtime probe could execute.

The first errors in `/tmp/fw_merge_gate-coredata.log` were at
`CoreDataRuntime.swift:2438`: both option-set literal elements failed to
convert from `T` to `T.ArrayLiteralElement`. On Linux Swift 6.2.4,
`T.Element == T` does not establish `T.ArrayLiteralElement == T`. The
catalog helper now requires both equalities, preserving the array-literal
exercise for all three option-set types. The focused test and its embedded
runtime copy use the same constraint.

The citation review also added explicit catalog calls for the attribute
wrapper's equality/hash operations, context concurrency raw-value
initializer, and the three nonmutating option-set `symmetricDifference`
members, plus a history-result `resultType` assertion in its cited test.
These checks substantiate existing cloud-ledger claims; they do not change
production behavior or reclassify rows.

| Measured tree | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| Current main (`c1973365`) | 949 | 345 | 15 | 10 | 0 |
| Refused cloud head (`f8b0fe33`) | 1283 | 11 | 15 | 10 | 0 |
| Local repair | 1283 | 11 | 15 | 10 | 0 |

The implemented gain over main is **334 rows**. All 1283 implemented rows
cite real synchronous, no-argument functions in `tests/agent/*Tests.swift`.
All 64 distinct cited functions are byte-identical to their embedded
`CoreDataRuntime.swift` definitions and are invoked by that runner. The
largest non-table citation remains `testFailClosedSurfaces`: 49/1283
(3.82%), below 40%. There are no `not-applicable` rows.

Validation in the operator's `uikit-linux` container, at
`/gate-codex-coredata`, with Swift 6.2.4 targeting
`aarch64-unknown-linux-gnu`:

- Unmodified sealed `tests/acceptance/test_host.sh`: reference hashes,
  warnings-as-errors module/dylib compilation, runtime compilation, and
  the complete runtime probe pass. Before repair: two compiler errors;
  after repair: zero errors and the terminal success marker below.
- All 64 cited tests also pass in separate processes, each with a 30-second
  timeout and no preceding tests, using a temporary runner built from the
  same runtime definitions. No test timed out. The normal sealed runner
  executes all 73 existing tests synchronously.
- Coverage citation format, definition/call presence, focused/runtime body
  equality, status totals, and preservation of main's implemented rows
  checked directly from the TSV and Swift sources.

```
FRAMEWORK_FANOUT_REFERENCE_OK
COREDATA_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreData dylib=libCoreData.dylib
```

Local logs: `/tmp/fw-coredata-r-gate.log` and
`/tmp/fw-coredata-r-individual.log`. No sealed files, shared harness files,
vendor pins, or generated products are changed by this repair.
