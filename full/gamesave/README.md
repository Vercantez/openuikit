# GameSave (Linux starting point)

This directory is a clean-room Linux port of Apple's public `GameSave`
module, reconstructed from the sealed Xcode 26.1 iPhoneOS symbol graphs.
It is not wired into the shared guest package.

The isolated host gate (`bash tests/acceptance/test_host.sh`) compiles
against toolchain Foundation only. It is not evidence of an integrated
Linux guest stack with UIKit, SwiftUI, or iCloud Drive.

## Depth pass 2026-09

**57 implemented** / **2 declared** / **3 deferred** (62 IDs).
Nondeferred 59 is above the leaf-full floor of 50.

Top-5 implemented evidence (by row count):

1. `GSSyncStateTests.swift#testGSSyncStateRawValues` — 7 (12.3%) — table-driven enum raw values
2. `GSSyncStateTests.swift#testGSSyncStateType` — 1 (1.8%)
3. `GSSyncStateTests.swift#testGSSyncStateInitRawValue` — 1 (1.8%)
4. `GSSyncStateTests.swift#testGSSyncStateInequality` — 1 (1.8%)
5. `GSSyncStateTests.swift#testGSSyncStateHashValue` — 1 (1.8%)

No non-enum / non-constant test exceeds 1 implemented row (40% of the
remaining 50 non-table rows would be 20). Enum cases share one
table-driven raw-value test.

### What is real

- `GSSyncState` raw values Ready=0 … Closed=6 from pinned macios
  `[Native]` order, plus `init?(rawValue:)` and synthesized
  `Hashable` / `Equatable`.
- `GameSaveErrorDomain` is the string `"GameSaveErrorDomain"`.
- `GameSaveSyncedDirectory.State` cases (`ready`, `offline`, `local`,
  `syncing`, `conflicted`, `error`, `closed`) and a case-name
  `description`.
- `GameSaveSyncedDirectory.Version` identity (`id` == `url`), stored
  `isLocal` / `localizedNameOfSavingComputer` / settable `modifiedDate`.
- `openDirectory(containerIdentifier:)` creates a real local directory
  under Application Support and returns `.local(url)`. Nil identifier
  uses Linux default `"GameSave.local"`. Equality is by container id.
- `close()` records `.closed`. `resolveConflicts(with:)` no-ops unless
  conflicted, then settles on `.local(chosen.url)`.
- ObjC overlays (`GSSyncedDirectory`, `GSSyncedDirectoryState`,
  `GSSyncedDirectoryVersion`) wrap the Swift types. Completion handlers
  run synchronously.

### Fail-closed boundaries

- No iCloud Drive daemon, container entitlements, or conflict sheet.
  `triggerPendingUpload` reports `false`. The directory never claims
  `.ready` (fully synced) from `openDirectory`.
- `finishSyncing(statusDisplay:)` / `GSSyncedDirectory.finishSyncing(_:)`
  that take `UIWindow` are deferred (UIKit is not a dependency).
- `View.gameSaveSyncingAlert` is deferred (SwiftUI is not a dependency).
- Async `finishSyncing()` / `triggerPendingUpload()` are declared; the
  isolated runner has no run loop and cannot await them. The ObjC
  completion-handler settle is the tested path.
- Observation.Observable / `@MainActor` overlays are omitted.

## Gates and markers

Expected standalone markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=GameSave lane=leaf-full symbols=62
FRAMEWORK_FANOUT_REFERENCE_OK
GAMESAVE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=GameSave dylib=libGameSave.dylib
```

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`343270ce44481a5ae11b87a6e0713e396ada1ef2` matched.

`origin/agent/fw-gamesave` is published from this Cursor-created work branch.
