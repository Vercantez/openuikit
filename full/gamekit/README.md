# GameKit (Linux starting point)

This directory is a clean-room Linux port of Apple's public `GameKit`
module, reconstructed from the sealed Xcode 26.1 iPhoneOS symbol graphs.
It is not wired into the shared guest package.

The isolated host gate (`bash tests/acceptance/test_host.sh`) compiles
against toolchain Foundation only. It is not evidence of an integrated
Linux guest stack with UIKit.

## Depth pass 2026-09 (wave 8)

**898 implemented** / **0 declared** / **21 deferred** (919 IDs).
Nondeferred 898 is above the medium-full floor of 460. Wave 8 converted
the last 2 declared rows (was 896 / 2 / 21): sync fail-closed
completion-handler companions for the two `async`-only listener
callbacks in `GKProtocols.swift`, covered by
`GKListenerTests.swift#testGKListenerSyncCompletions`.

## Depth pass 2026-09 (wave 2)

Wave 2 reached 896 implemented / 2 declared / 21 deferred (919 IDs).
It converted
67 declared rows: 51 sync fail-closed completion-handler companions in
`GKFailClosedCompletions.swift`, 13 `GKError` NSError-bridging members,
2 duplicate `GKAccessPoint` trigger selectors, and 1
`GKGameActivityPlayStyle.asynchronous` enum member (was 829 / 69 / 21).

Top-5 implemented evidence (by row count):

1. `GKEnumTests.swift#testGKEnumRawValues` — 205 (22.9%) — table-driven enum raw values
2. `GKErrorTests.swift#testGKErrorRawValues` — 91 (10.2%) — table-driven `GKError.Code`
3. `GKTurnBasedTests.swift#testGKTurnBasedLocalState` — 57 (6.4%)
4. `GKErrorTests.swift#testGKGameSessionErrorRawValues` — 53 (5.9%) — table-driven session errors
5. `GKAchievementTests.swift#testGKLeaderboardLocalState` — 46 (5.1%)

No non-enum / non-constant test exceeds 6.4% of implemented rows (40% cap
of the remaining non-table rows would be 208).

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
- Sync completion-handler companions (`GKFailClosedCompletions.swift`)
  for every `async` overlay, plus the two `async`-only listener
  callbacks in `GKProtocols.swift`: achievement/score reports,
  leaderboard loads and entries,
  saved-game CRUD, matchmaking, game sessions, turn-based
  exchanges/matches, cloud-player sign-in, activity-definition loads,
  banner shows, `GKAccessPoint` challenge-definition triggers,
  `GKGameActivityListener.player:wantsToPlay:completionHandler:`
  (synchronously answers `false`), and
  `GKMatchmakerViewControllerDelegate.matchmakerViewController:getMatchPropertiesForRecipient:withCompletionHandler:`
  (synchronously answers `[:]`).
  Each companion invokes its handler synchronously with
  `GKError.notAuthenticated` (or the specific `GKGameSessionError` /
  turn-based / iCloud code, or the inert listener default) and is covered
  by a focused test in `GKFailClosedCompletionsTests.swift` (listener
  callbacks: `GKListenerTests.swift#testGKListenerSyncCompletions`).
- `GKError` NSError bridging (`errorDomain`, `errorCode`,
  `errorUserInfo`, `userInfo`, `code`, `hash`/`hashValue`, `==`/`!=`,
  `init`, `localizedDescription`) exercised by `testGKErrorBehavior`.
- `GKNotificationBanner.show` companions record `portableShowCount`
  and invoke the completion with no error (local presentation only).

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
- Async `async throws` overlays are kept alongside the sync
  fail-closed companions, including the listener callbacks
  (`GKGameActivityListener.player:wantsToPlay:completionHandler:` and
  `GKMatchmakerViewControllerDelegate.matchmakerViewController:getMatchPropertiesForRecipient:withCompletionHandler:`),
  whose sync companions answer `false` / `[:]` synchronously because the isolated runner has no run loop and
  cannot await them.

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
