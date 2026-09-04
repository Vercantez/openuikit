# SwiftData (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`SwiftData` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and pinned `dotnet/macios` bindings. It is not
wired into the shared guest package; that integration is a later
central-review step.

The pre-existing portable runtime is kept: in-memory `ModelContainer` /
`ModelContext` object identity, insert/delete/save/rollback, Foundation
`FetchDescriptor` sort/limit/offset, live `@Query`, and fail-closed durable
stores. This wave-7 pass adds source-compatible Schema, DataStore,
history, and ModelActor surface around that runtime.

Unchanged application source continues to import `SwiftData`. Linux has no
CoreData SQLite store, no CloudKit, and no Apple schema-migration engine.

## What is real

- In-memory insert, delete, save, rollback, identity lookup, and change sets.
- `FetchDescriptor` sort, offset, limit, and fetch counts against registered
  models.
- `FetchResultsCollection` wrapping an in-memory fetch when a batch size is
  supplied (`includePendingChanges` combined with a batch size throws).
- `Schema` construction from entities or model types, equality, version
  ordering, and a portable JSON `save`/`load` round-trip (not Apple's
  on-disk encoding).
- `DefaultStore` as an in-memory snapshot store; durable configurations
  throw `SwiftDataError.unsupportedPersistentStore`.
- `PersistentIdentifier` Codable round-trip and
  `identifier(for:entityName:primaryKey:)`.
- `ModelConfiguration.validate()` rejects `/` and overlong names with the
  matching `SwiftDataError` tokens.
- History fetches return an empty list; history is not invented.

The isolated Linux host gate compiles these sources with `swiftc` and
Foundation only. `tests/agent/SwiftDataDependencyIdentity.swift` imports
the real Foundation module for the later clean integration build.

## Fail-closed boundaries

- Durable `ModelConfiguration` / `DefaultStore` construction throws. There
  is no disk-backed SwiftData store.
- CloudKit database tokens are stored but never synchronized.
- `SchemaMigrationPlan` construction of a container throws
  `SwiftDataError.backwardMigration`. Apple lightweight/custom migration
  is unobserved.
- `ModelContext.undoManager` is unavailable: Linux Foundation has no
  `UndoManager`.
- `Schema.Attribute.Option.transformable(by: ValueTransformer.Type)` is
  unavailable: Linux Foundation has no `ValueTransformer`.
- SwiftUI `Query` macros, `View`/`Scene`/`DocumentGroup` containers, and
  `AppStorage` overlays are deferred. The portable `@Query` property
  wrapper remains for the pre-existing host runtime.
- Foundation `#Predicate` over class key paths traps on this Linux
  Foundation revision; focused tests do not use `#Predicate`.

## Existing Darwin host gate

The IceCubes consumer script remains Darwin-only (`xcrun`):

```sh
bash full/swiftdata/tests/test_swiftdata_host.sh
python3 -B full/swiftdata/tests/test_predicate_keypath_backport.py
```

It is unchanged and is not the wave-7 Linux deliverable gate.

## Wave-7 deliverable gate

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/swiftdata --phase deliverable
bash full/swiftdata/tests/acceptance/test_host.sh
```

`tests/agent/SwiftDataRuntime.swift` records the runtime contract the
focused tests exercise. `tests/agent/SwiftDataLoadSmoke.swift` is the
canonical schema-v2 import/marker source.
