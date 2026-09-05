# GameKit (Linux starting point)

This directory is a clean-room Linux port of Apple's public `GameKit`
module, reconstructed from the sealed Xcode 26.1 iPhoneOS symbol graphs.
It is not wired into the shared guest package.

The isolated host gate (`bash tests/acceptance/test_host.sh`) compiles
against toolchain Foundation only. It is not evidence of an integrated
Linux guest stack with UIKit.

## Depth pass 2026-09

**829 implemented** / **69 declared** / **21 deferred** (919 IDs).
Nondeferred 898 is above the medium-full floor of 460.

Top-5 implemented evidence (by row count):

1. `GKEnumTests.swift#testGKEnumRawValues` — 204 (24.6%) — table-driven enum raw values
2. `GKErrorTests.swift#testGKErrorRawValues` — 91 (11.0%) — table-driven `GKError.Code`
3. `GKTurnBasedTests.swift#testGKTurnBasedLocalState` — 57 (6.9%)
4. `GKErrorTests.swift#testGKGameSessionErrorRawValues` — 53 (6.4%) — table-driven session errors
5. `GKAchievementTests.swift#testGKLeaderboardLocalState` — 46 (5.5%)

No non-enum / non-constant test exceeds 6.9% of implemented rows (40% cap
of the remaining non-table rows would be 182).

### What is real

- `GKError.Code` / `GKGameSessionError.Code` raw values from the public
  header enumeration (corroborated by pinned dotnet-macios bindings).
- Local `GKAchievement` / `GKScore` state (`percentComplete` ≥ 100 completes
  an achievement; score `formattedValue` tracks `value`).
- `GKMatchRequest` player limits: peer-to-peer max 4, hosted/turn-based 16.
- `GKGameActivity` state machine: initialized → active → paused → active →
  ended, plus in-memory achievement progress and leaderboard scores.
- `GKAccessPoint.shared` stores `isActive` / `location` / `showHighlights`
  without presenting UI (`isVisible` stays false).
- `GKTurnTimeoutDefault` = 1 week, `GKExchangeTimeoutDefault` = 1 day,
  `None` variants = 0, matching public duration comments.
- Friend-request compose recipient cap of 8.
- Fail-closed completions for Game Center loads, reports, matchmaking,
  identity signatures, iCloud saved games, and game sessions.

### Fail-closed boundaries

- No Game Center account, matchmaking daemon, or leaderboard service.
  Completions receive `GKError.notAuthenticated` (or
  `GKGameSessionError.notAuthenticated`) synchronously.
- `GKGameActivity.isValidPartyCode` is false and
  `validPartyCodeAlphabet` is empty until an Apple-oracle records the
  alphabet (`os-service`).
- Voice chat: `isVoIPAllowed()` is false; `start()` does not go active.
- UIKit dashboard types that name `UIImage` / `UIWindow` /
  `UIViewController` are omitted (`deferred`). View-controller classes
  exist as `NSObject` holders of local state and never present.
- Async `async throws` overlays are declared; the isolated runner has no
  run loop and cannot await them.

## Gates and markers

Expected standalone markers:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=GameKit lane=medium-full symbols=919
FRAMEWORK_FANOUT_REFERENCE_OK
GAMEKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=GameKit dylib=libGameKit.dylib
```

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`e76572cf95a4cd2c803c340a1867409c4fc4c6a6` matched.

`origin/agent/fw-gamekit` is published from this Cursor-created work branch.
