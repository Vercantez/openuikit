# CoreData (Linux starting point)

This directory is a clean-room Linux `CoreData` module for the OpenUIKit
framework fan-out. It is a working in-memory object graph, not Apple behavioral
parity and not a production SQLite stack.

Isolated-gate success is not integrated Linux success. A future EC2 run must
build real guest Foundation and Dispatch, compile this module against those
`-I`/`-L` paths, link `tests/agent/CoreDataDependencyIdentity.swift`, and load
`libCoreData.dylib` under `LD_LIBRARY_PATH`.

## What is real

- `NSManagedObjectModel`, `NSEntityDescription`, attributes, relationships,
  fetch indexes, and uniqueness-constraint metadata.
- `NSManagedObject` / `NSManagedObjectID` with key-value accessors and
  **complete committed snapshots**. Nil is represented as `NSNull`.
  `changedValues()` drops a key that returns to its original committed value;
  `hasPersistentChangedValues` follows remaining persistent diffs;
  `committedValues(forKeys:)` returns the last fetched or saved snapshot;
  rollback restores that snapshot and detaches unsaved inserts.
- `NSManagedObjectContext` fetch (block `NSPredicate`), save, rollback, reset,
  and did-save/did-change notifications.
- **Context executors:** `mainQueueConcurrencyType` uses `DispatchQueue.main`;
  `privateQueueConcurrencyType` uses a dedicated serial queue. Void and generic
  `perform` / `performAndWait` share that confinement path.
  `perform(schedule:)` honors `.immediate` versus `.enqueued` ordering.
- **Child saves** copy `objectID` plus attribute snapshots onto **distinct**
  parent-context instances. The child object's `managedObjectContext` is never
  retargeted; the same `NSManagedObject` instance is never inserted into the
  parent.
- `NSPersistentStoreCoordinator` + `NSPersistentContainer` against
  `NSInMemoryStoreType`. `registerStoreClass` / `registeredStoreTypes` are
  wired into `addPersistentStore`.
- `NSFetchRequest`, `NSFetchedResultsController`, and in-memory batch
  insert/update/delete.
- Merge-policy objects, error codes, store-type names, and historical
  `NSCoreDataVersionNumber*` constants from public headers.

The isolated runtime probe `tests/agent/CoreDataRuntime.swift` prints
`COREDATA_AGENT_RUNTIME_OK`. The standalone EC2 client
`tests/agent/CoreDataDependencyIdentity.swift` prints
`COREDATA_DEPENDENCY_IDENTITY_OK` and is not executed by the isolated gate.

## Fail-closed boundaries

- `NSSQLiteStoreType` is a **platform blocker**, not a deferred implementation
  detail. Linux does not decode Apple's SQLite WAL/`Z*` schema. Unregistered
  SQLite `addPersistentStore` throws. Do not treat isolated-gate success as
  durable SQLite success. `NSBinaryStoreType` also does not open.
- `NSManagedObjectModel(contentsOf:)` returns nil: compiled `.mom`/`.momd`
  bytes are proprietary and are not parsed.
- `NSPersistentCloudKitContainer.initializeCloudKitSchema` throws. Sharing
  and CloudKit record mutation APIs return false / fail.
- Ubiquity / iCloud store options and
  `removeUbiquitousContentAndPersistentStore` throw.
- `NSMappingModel.inferredMappingModel` and `NSMigrationManager.migrateStore`
  throw. Staged/lightweight migration does not rewrite stores.
- Persistent history tokens are not produced; history fetch requests compile
  but do not invent transactions.
- `NSCoreDataCoreSpotlightDelegate` does not index. Core Spotlight types are
  not available on this toolchain.
- `NSCoreDataVersionNumber` is exported as `0` because the current iOS 26.1
  numeric value was not in the Linux-visible seed inputs. That is unknown, not
  Apple parity. Historical `NSCoreDataVersionNumber*` header constants remain
  as compile-only exports.
- `NSPersistentContainer.defaultDirectoryURL()` returns the conventional
  Application Support path and does **not** eagerly create directories or
  sqlite files.
- String `NSPredicate(format:)` and `NSSortDescriptor(key:)` remain unavailable
  because swift-corelibs-foundation has no KVC predicate parser. Block
  predicates and in-memory fetches still work.

## Deferred

Combine `objectWillChange`, `UndoManager`, `NSExpression` members,
`CKDatabase.Scope`, `CSSearchableIndex` methods, and
`NSDiffableDataSourceSnapshot` FRC callbacks are omitted so the module builds
with warnings-as-errors on Linux Foundation. The class-var spelling of
`defaultDirectoryURL` is omitted because Swift cannot declare it alongside the
implemented class function.

See `oracle-questions.tsv` for Apple-oracle probes that must land before any
of those paths can claim success.
