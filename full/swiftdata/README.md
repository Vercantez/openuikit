# SwiftData (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`SwiftData` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and pinned `dotnet/macios` bindings. It is not
wired into the shared guest package; that integration is a later
central-review step.

The portable runtime is an in-memory object-identity store:
`ModelContainer` / `ModelContext` insert/delete/save/rollback, Foundation
`FetchDescriptor` sort/limit/offset, Schema / DataStore / history /
ModelActor surface, and fail-closed durable stores. Isolated host
compilation still imports Foundation only — `full/coredata` is a parallel
lane and is not linked here.

Unchanged application source continues to import `SwiftData`. Linux has no
CoreData SQLite store, no CloudKit, and no Apple schema-migration engine.

Coverage (884 public precise IDs): **616 implemented** / 29 declared /
49 deferred / 2 unavailable / 188 not-applicable. The
ModelContainer, ModelConfiguration, ModelContext, FetchDescriptor, and
Schema families are nondeferred (implemented or declared).

## What is real

- In-memory insert, delete, save, rollback, identity lookup, and change sets.
- `FetchDescriptor` sort, offset, limit, and fetch counts against registered
  models. Corpus predicate *shapes* (comparison, `&&`/`||`, Character
  `contains`, key paths) are evaluated after fetch; Foundation `#Predicate`
  over class key paths is not used (it traps on this Linux Foundation).
- `FetchResultsCollection` wrapping an in-memory fetch when a batch size is
  supplied (`includePendingChanges` combined with a batch size throws).
- `Schema` construction from entities, model types, or a `VersionedSchema`,
  including Attribute / Relationship / Entity / Index / Unique /
  CompositeAttribute, equality, version ordering, and a portable JSON
  `save`/`load` round-trip (not Apple's on-disk encoding).
- `DefaultStore` as an in-memory snapshot store; durable configurations
  throw `SwiftDataError.unsupportedPersistentStore`.
- `PersistentIdentifier` Codable round-trip and
  `identifier(for:entityName:primaryKey:)`.
- `ModelConfiguration.validate()` rejects `/` and overlong names with the
  matching `SwiftDataError` tokens. The `/` check uses Character
  `contains`, not String `contains` (guest GATE_B / `_StringProcessing`).
- `allowsSave: false` refuses `ModelContext.save()`.
- CloudKit database tokens (`.automatic` / `.none` / `.private(_:)`) are
  stored and never synchronized.
- History fetches return an empty list; history types construct and
  compare but do not invent transactions.
- `DefaultSerialModelExecutor` and a `ModelActor` conforming actor expose
  the nonisolated container / executor / unownedExecutor path.

Tests adopt `PersistentModel` directly. `@Model` is a protocol-based
replacement: the isolated Linux compile has no SwiftSyntax macro plugin
(`OBSERVATION_MACRO_PLUGIN` is the toolchain Observation plugin, not a
SwiftData plugin). `SwiftDataMacros.swift` remains a Darwin/SwiftSyntax
sketch and is not in `swiftdata_guest_sources.txt`.

## Fail-closed boundaries

- Durable `ModelConfiguration` / `DefaultStore` construction throws. There
  is no disk-backed SwiftData store. CoreData's SQLite is absent; this
  module does not import CoreData (not a declared seed dependency).
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
- `NSManagedObjectModel.makeManagedObjectModel` helpers are deferred:
  they need CoreData.
- Foundation `#Predicate` over class KeyPath traps on this Linux
  Foundation revision; focused tests do not use `#Predicate`.
- `PersistentModel.init(backingData:)` still fatalErrors without `@Model`
  generated storage. `Hashable.hashValue` is not redeclared (deprecated
  under `-warnings-as-errors`); coverage cites the internal helper name.

## Existing Darwin host gate

The IceCubes consumer script remains Darwin-only (`xcrun`):

```sh
bash full/swiftdata/tests/test_swiftdata_host.sh
python3 -B full/swiftdata/tests/test_predicate_keypath_backport.py
```

It is unchanged and is not the Linux deliverable gate.

## Deliverable gate

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/swiftdata --phase deliverable
bash full/swiftdata/tests/acceptance/test_host.sh
```

`tests/agent/SwiftDataRuntime.swift` records the runtime contract the
focused tests exercise. `tests/agent/SwiftDataLoadSmoke.swift` is the
canonical schema-v2 import/marker source.
`tests/agent/SwiftDataSurfaceTests.swift` is the depth pass over Schema,
container, context, fetch, store, history, and actor surface.
