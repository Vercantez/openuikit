# CoreData (Linux starting point)

This directory is a clean-room Linux `CoreData` module for the OpenUIKit
framework fan-out. It is a working in-memory object graph, not Apple behavioral
parity and not a production SQLite stack.

## What is real

- `NSManagedObjectModel`, `NSEntityDescription`, attributes, relationships,
  fetch indexes, and uniqueness-constraint metadata.
- `NSManagedObject` / `NSManagedObjectID` with key-value accessors, change
  tracking, insert/update/delete flags, and required-attribute validation.
- `NSManagedObjectContext` fetch (including block `NSPredicate`), save,
  rollback, reset, child-context push, `perform` / `performAndWait`, and
  did-save/did-change notifications.
- `NSPersistentStoreCoordinator` + `NSPersistentContainer` against
  `NSInMemoryStoreType`.
- `NSFetchRequest`, `NSFetchedResultsController`, and in-memory batch
  insert/update/delete.
- Merge-policy objects, error codes, store-type names, and historical
  `NSCoreDataVersionNumber*` constants.

The runtime probe `tests/agent/CoreDataRuntime.swift` exercises the in-memory
path and prints `COREDATA_AGENT_RUNTIME_OK`.

## Fail-closed boundaries

- `NSSQLiteStoreType` and `NSBinaryStoreType` do not open. Linux does not
  decode Apple's SQLite WAL/`Z*` schema or binary store format.
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
- String `NSPredicate(format:)` and `NSSortDescriptor(key:)` remain unavailable
  because swift-corelibs-foundation has no KVC predicate parser. Block
  predicates and in-memory fetches still work.

## Deferred

Combine `objectWillChange`, `UndoManager`, `NSExpression` members,
`CKDatabase.Scope`, `CSSearchableIndex` methods, and
`NSDiffableDataSourceSnapshot` FRC callbacks are omitted so the module builds
with warnings-as-errors on Linux Foundation.

See `oracle-questions.tsv` for Apple-oracle probes that must land before any
of those paths can claim success.
