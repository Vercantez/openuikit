# fw-coredata — CoreData SDK depth (in-memory, SQLite fail-closed)

Worktree branch `agent/fw-coredata`. No UI chrome: this is the Linux
`CoreData` module under `full/coredata/`. Nothing here changes a scene pixel.

## Before / after

| gate | before | after |
|---|---|---|
| CoreData `coverage.tsv` | 88 implemented / 1200 declared / 21 deferred / 10 unavailable | **1215 implemented** / 88 declared / 6 deferred / 10 unavailable (1319 IDs) |
| Isolated host gate | `COREDATA_AGENT_RUNTIME_OK` (CRUD + queues) | `COREDATA_AGENT_RUNTIME_OK` (relationships, predicates, FRC, batch, merge, catalog, fail-closed) |
| SQLite | fail-closed (no `sqlite3` in tree) | still fail-closed; addPersistentStore does not create a file |
| Catalyst / iOS suite / real-app | unchanged (no render rule) | see verification below |

## Measurement

`grep sqlite3` over `full/` and `uikit/` is empty, so this port is in-memory
only. `NSSQLiteStoreType` stays a platform blocker.

`NSFetchRequestExpressionType.rawValue` was read off Apple CoreData on this
Mac host:

```
swift -e 'import CoreData; print(NSFetchRequestExpressionType.rawValue)'
50
```

Error-code integers match public `CoreDataErrors.h` (for example
`NSManagedObjectValidationError == 1550`, `NSPersistentStoreOpenError == 134080`).
`NSCoreDataVersionNumber` stays **0** (iOS 26.1 numeric value was not in the
Linux-visible seed inputs).

## What landed (one honest in-memory stack)

Guarded only by this module; no iOS-cut render rules.

- Programmatic `NSManagedObjectModel`: entities, attributes (types,
  optionality, defaults), inverse relationships, fetched properties, indexes.
  `.momd` `contentsOf:` returns nil.
- `NSPersistentContainer` / coordinator / `NSPersistentStoreDescription`:
  in-memory load callbacks; SQLite and binary fail closed.
- `NSManagedObjectContext`: concurrency, `perform`/`performAndWait`,
  insert/delete/save with validation codes, snapshots, rollback/reset/refresh,
  undo disabled (`undoManager` always nil), parent save push,
  `mergeChanges(fromContextDidSave:)`, `automaticallyMergesChangesFromParent`,
  documented merge-policy objects.
- `NSManagedObject`: KVC, primitives, faults, temporary→permanent objectID,
  `validateForInsert/Update/Delete`, `validateValue`, to-many
  `willChangeValue`/`didChangeValue`.
- `NSFetchRequest`: host `NSPredicate(format:)` comparison / AND / IN /
  CONTAINS / BEGINSWITH / relationship key paths, sort, limit/offset,
  four result types, `returnsObjectsAsFaults`.
- `NSFetchedResultsController`: sections, indexPath lookups, delegate order
  willChange → section/object edits → didChange (first `performFetch` does
  not emit object inserts).
- Batch insert/update/delete. Persistent history and CloudKit fail closed.

## Open

- Apple SQLite WAL/`Z*` schema (no sqlite3 in this tree).
- Compiled `.mom`/`.momd` bytes (proprietary; fail closed).
- Combine `objectWillChange`, FRC `NSDiffableDataSourceSnapshot` (UIKit),
  `CKDatabase.Scope`, class-var `defaultDirectoryURL`.
- FRC first-fetch vs subsequent insert callback order on iOS 26.1 (oracle row).

## Verification

Isolated `bash tests/acceptance/test_host.sh` from `full/coredata/` prints
`FRAMEWORK_FANOUT_HOST_OK`. Pixel gates (no render rule, scores held):

- Catalyst: **124/124**
- iOS suite `SKIP_CAPTURE=1`: **112/113** (known `corner_radius`)
- Real-app: **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393**
- Linux `swift:6.2-noble` openrender green (234.74 s)
