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
- `NSFetchRequest` with `NSPredicate` evaluation (comparison, compound, IN,
  CONTAINS, BEGINSWITH, relationship key paths on the host Foundation
  parser), `NSSortDescriptor(key:)`, fetchLimit/offset, propertiesToFetch,
  and result types `.managedObjectResultType` / `.countResultType` /
  `.dictionaryResultType` / `.managedObjectIDResultType`.
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

Coverage (wave-1 → this branch): **88 → 1215 implemented** / 88 declared /
6 deferred / 10 unavailable of 1319 public IDs. The model, coordinator,
context, managed-object, fetch-request, and FRC families are nondeferred
except Combine `objectWillChange` on `NSManagedObject` and the FRC
`NSDiffableDataSourceSnapshot` callback (UIKit type).

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

See `oracle-questions.tsv` for Apple-oracle probes that must land before any
of those paths can claim success.
