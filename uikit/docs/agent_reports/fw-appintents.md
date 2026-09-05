# AppIntents SDK-depth (agent/fw-appintents)

SDK-depth port of Apple's public `AppIntents` surface for the Linux guest.
No iOS pixel rule. Work stayed in `full/appintents/`.

## Before → after

| | implemented | declared | deferred | nondeferred |
|---|---|---|---|---|
| before | 49 | 4077 | 2460 | 4126 |
| after | **1575** | 3280 | 1731 | 4855 |

Target was implemented ≥ 1200 with AppIntent / `@Parameter` / AppEntity /
AppEnum / queries / DisplayRepresentation / AppShortcut families nondeferred
except operators, synthesized witnesses, and hashValue (no valid coverage
anchor). Floor 3293 nondeferred already held.

## What was measured

In-process Linux tests in `tests/agent/AppIntentsCorpusTests.swift` and
`AppIntentsTests.swift`, not simulator pixels.

- `AddFeedIntent` statics: title `"Add Feed"`, description category/search
  keywords, `openAppWhenRun == false`, `isDiscoverable == true`.
- `.result()` / `.result(dialog:)` stay on `IntentResultValue` so
  `EchoIntent` still infers that type. `.result(value:)` /
  `.result(value:dialog:)` / `.result(opensIntent:)` /
  `.result(view:)` return `IntentResultContainer`.
- `@Parameter(title:default:controlStyle:inclusiveRange:)` for Int: default
  3, `.field`, range (1, 9). Double slider/field/stepper cases exist.
- `SiteQuery` `suggestedEntities` / `entities(matching:)` / `entities(for:)`
  and `UniqueFeed.defaultQuery.uniqueEntity()`.
- Shortcut phrase `"Add feed with \(.applicationName)"` →
  `"Add feed with ${applicationName}"`.
  `updateAppShortcutParameters()` is a no-op.
- `AppIntentsHost.perform(identifier:parameters:)` applies `"url"` onto
  `@Parameter var url` and returns the container value.
- `AppDependencyManager.get` missing key throws
  `failedToRetrieveDependency` (Apple crash-on-missing).

## Open (not guessed)

- `EntityIdentifier.init?(activityIdentifier:)` packing vs NSUserActivity.
- Whether missing `AppDependency.wrappedValue` crashes or throws
  `failedToRetrieveDependency` on Apple.
- `updateAppShortcutParameters` queue / Shortcuts database refresh.
- No public `ResolvedValue` in the 26.1 graph.

## Verify

- Darwin `swiftc -warnings-as-errors` of `appintents_guest_sources.txt` and
  typecheck of `tests/agent/*Tests.swift`.
- Isolated Linux runner (27 tests): library + `tests/agent/*Tests.swift`
  compiled with `swiftc` on `swift:6.2-noble`; stdout
  `APPINTENTS_AGENT_RUNTIME_OK`.
- Sealed `tests/acceptance/test_host.sh` currently refuses at the
  deliverable validator: provenance digest mismatch for
  `scripts/framework-fanout/generate_seed_v2.py` (seed expects
  `e44f6bde…`, this worktree's main has `e56ee6e70…`). That file is
  outside this framework and was not edited. Coverage accounting and
  Linux tests are otherwise green.
- No uikit render rule. Catalyst / iOS suite / real-app floors unchanged.

