# fw-swiftdata — SwiftData SDK depth (in-memory)

Worktree branch `fw-swiftdata`, push `agent/fw-swiftdata`. No scene pixel
rule: this is the `full/swiftdata` corpus surface (884 IDs). Isolated
Linux host compilation still uses Foundation only; `full/coredata` was
not edited.

## Before / after

| gate | before | after |
|---|---|---|
| SwiftData coverage implemented | 109 | **616** |
| declared | 516 | 29 (macros, `init(backingData:)`, isolated `ModelActor` members, `hashValue` name-only) |
| deferred | 69 | 49 (SwiftUI overlay 45 + `NSManagedObjectModel` CoreData helpers 4) |
| ModelContainer / ModelConfiguration / ModelContext / FetchDescriptor / Schema | mixed deferred `hashValue`/`RawValue` | **nondeferred** (implemented or declared) |
| Isolated host gate | `SWIFTDATA_AGENT_RUNTIME_OK` | `SWIFTDATA_AGENT_RUNTIME_OK` (`swift:6.2-noble`) |
| Catalyst | 124/124 | **124/124** |
| iOS suite | 112/113 (`corner_radius`) | **112/113** (`corner_radius`) |
| Real-app floors | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393 | unchanged |
| Linux `swift:6.2-noble` openrender | green | **green** (214.00 s) |

## What was measured

Host gate `bash full/swiftdata/tests/acceptance/test_host.sh` inside
`docker run swift:6.2-noble` after `apt-get install git python3`:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=SwiftData lane=medium-full symbols=884
FRAMEWORK_FANOUT_REFERENCE_OK
SWIFTDATA_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=SwiftData dylib=libSwiftData.dylib
```

Behavioral checks in `tests/agent/SwiftDataSurfaceTests.swift` plus the
pre-existing `SwiftDataTests.swift`:

- Container → context → insert → save → fetch. Durable URL /
  `isStoredInMemoryOnly: false` throws `unsupportedPersistentStore`.
  `allowsSave: false` throws on `save()`. `SchemaMigrationPlan` on
  container init throws `backwardMigration`.
- Fetch sort/limit/offset/count. Predicate *shapes* (comparison, `&&` /
  `||`, Character `contains`, key paths) run as an in-memory filter
  after fetch. Foundation `#Predicate` over class KeyPath is still the
  open oracle question (traps on this Linux Foundation).
- Schema Attribute / Relationship (delete rules, unique/externalStorage
  options as value stores) / Entity / Index / Unique / CompositeAttribute
  construct, hash, and JSON round-trip.
- `DefaultStore` save/fetch/erase/batch-delete against in-memory
  snapshots. History fetch remains empty.
- Tests adopt `PersistentModel` directly. `@Model` is protocol-based:
  `OBSERVATION_MACRO_PLUGIN` is the toolchain Observation plugin, not a
  SwiftData SwiftSyntax plugin. `SwiftDataMacros.swift` is not in the
  guest manifest.

## Rules that are not Apple's on-disk store

- No CoreData SQLite. `NSManagedObjectModel.makeManagedObjectModel`
  stays deferred.
- `ModelConfiguration.validate()` rejects `/` via Character `contains`
  (`name.contains("/" as Character)`), not String `contains` — guest
  GATE_B (`libswift_StringProcessing.dylib`, measured at 54be0035).
- `Hashable.hashValue` is not redeclared (deprecated under
  `-warnings-as-errors`). Coverage cites `_SwiftDataHashable.hashValue`.
- Unsaved insert + delete does not appear in `deletedModelsArray`
  (cleared from `inserted` instead). `isDeleted` is true after save then
  delete. Apple's timing was not captured.

## Open

- `#Predicate` evaluation on class key paths (existing oracle row).
- `Schema.save(to:)` portable JSON vs Apple's encoding.
- `ModelContext.save` notification payload / queue.
- CloudKit handshake for in-memory configurations.
- SwiftUI Query / DocumentGroup / environment timing.
