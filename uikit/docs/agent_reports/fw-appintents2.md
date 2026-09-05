# AppIntents SDK depth, second pass (agent/fw-appintents2)

Base: `origin/agent/fw-appintents` (first pass, refused for coverage honesty).
Scope: `full/appintents/` plus this report and one fidelity-table row. No
uikit sources, no `reference/` or `tests/acceptance/` edits, no pin files.

## What was refused

`coverage.tsv` marked **1575** identifiers `implemented`, but **771** of
1416 non-enum implemented rows cited one test
(`tests/agent/AppIntentsTests.swift#testIntentPerformEcho`) — a bulk
relabel of unrelated types (ShortcutsUIButton, FocusFilterAppContext,
AttributedStringFromStringResolver, …) as “perform() implemented”.
Invented success is worse than a marked gap. `implemented` evidence must
be a focused test of that identifier’s behaviour. Only enum/option-set
members may share one table-driven raw-value test.

## Coverage before / after

| | implemented | declared | deferred | nondeferred |
|---|---:|---:|---:|---:|
| main (pre first pass) | 49 | 4077 | 2460 | 4126 |
| first pass (refused) | 1575 | 3280 | 1731 | 4855 |
| this pass | **299** | **4552** | 1735 | 4851 |

Public surface is still 6586 precise IDs. The medium-full floor is 3293
nondeferred; 4851 remains well above it.

Every row whose only evidence was `testIntentPerformEcho` is `declared`
again with a product-source `#identifier` (or `deferred` when the member
is still absent). Four formerly-implemented IDs have no host source
(`EntityQuerySort.by`, two `ConfirmationActionName` cases, one Assistant
schema member) and stay `deferred`.

The original 49 implemented IDs and their tests are unchanged.
`testIntentPerformEcho` cites **one** ID: `AppIntent.perform()`.

No implemented test is cited by more than 29 rows or 9.7% of implemented
rows.

## Evidence distribution (top 5 tests by row count)

1. `testIntentFilePersonAndItemCollection` — 29
2. `testAppShortcutBuilderUpdateAndApplicationNameToken` — 28
3. `testDisplayRepresentationImagesAndSynonyms` — 21
4. `testParameterControlStyleAndInclusiveRange` — 19
5. `testAppIntentStaticRequirements` — 18

35 distinct cited tests. 299 implemented rows.

## Behaviour this pass actually tests

Cited in-process Linux measurements (and one Darwin Foundation
`LocalizedStringResource` key), not a comparison-score search.

1. **`AppIntent.perform()` result shapes.** `.result(value:)` /
   `.result(value:dialog:)` / `.result(opensIntent:)` /
   `.result(view:)` / `.result(content:)` return `IntentResultContainer`.
   Bare `.result()` / `.result(dialog:)` stay on `IntentResultValue` so
   `EchoIntent` still infers that type (Apple’s Container overloads for
   those two spellings are not substituted in).
2. **`@Parameter`.** Default `"search"` is returned until assigned;
   Int `(1, 9)` / `.field` and Double `(0.0, 5.0)` / `.slider` round-trip.
   `requestValueDialog` is stored on metadata. `optionsProvider:` is
   accepted and not consulted for `wrappedValue`. Sync `requestValue`
   returns `unsupportedOnDevice`.
3. **AppEntity / AppEnum / queries.** `SiteQuery.suggestedEntities` is
   one `hn` row; `entities(matching: "Hack")` matches; `"zzz"` is empty;
   `entities(for: ["hn"])` matches; `entities(for: ["nope"])` is empty.
   `EntityPropertyQuery` default delegates to `suggestedEntities`.
   `UniqueFeed.defaultQuery.uniqueEntity().id == "unique"`.
4. **DisplayRepresentation / TypeDisplayRepresentation / IntentDialog.**
   Image systemName/named/data/url inits; synonyms count 1; type
   `numericFormat` key `"%lld feeds"`. Dialog interpolation
   `"added=\("feed")" == "added=feed"`.
5. **AppShortcut `${applicationName}`.** `"Add feed with \(.applicationName)"`
   → `"Add feed with ${applicationName}"`. `updateAppShortcutParameters()`
   is a no-op.
6. **AppDependencyManager.** `add(key: "clock", dependency: "tick")` then
   `get(String.self, key: "clock") == "tick"`. Missing key throws
   `failedToRetrieveDependency`. `AppDependency` with default `"fallback"`
   and unused key returns `"fallback"`.
7. **AppIntentsHost.** `registerShortcuts` enumerates one phrase;
   `applyParameters` strips a leading `_` on `@Parameter` Mirror labels;
   `perform(identifier:parameters:)` with `url` returns that string as
   the container value.
8. **Darwin `LocalizedStringResource.key`.**
   `LocalizedStringResource("Adds a feed").key == "Adds a feed"` on
   Foundation; `"\(resource)"` is a debug dump. `appIntentsString`
   now reads `.key` on both Darwin and the Linux lookalike
   (`testAppIntentStaticRequirements`).

## Open (not guessed)

- `EntityIdentifier.init?(activityIdentifier:)` packing vs NSUserActivity.
- Whether missing `AppDependency.wrappedValue` crashes or throws
  `failedToRetrieveDependency` on Apple (Linux `get()` throws).
- `updateAppShortcutParameters` queue / Shortcuts database refresh.
- Whether Apple’s `IntentParameter` consults `optionsProvider` when
  resolving `wrappedValue` without a metadata extract.
- No public `ResolvedValue` in the 26.1 graph.

## Verify

- Darwin `swiftc -warnings-as-errors` of `appintents_guest_sources.txt`
  and 36 `test*` functions: stdout `APPINTENTS_DARWIN_TESTS_OK`.
- Isolated Linux runner (35 cited tests): library + `tests/agent/*Tests.swift`
  compiled with `swiftc` on `swift:6.2-noble`; stdout
  `APPINTENTS_AGENT_RUNTIME_OK`.
- Sealed `tests/acceptance/test_host.sh` still refuses at the
  deliverable validator: provenance digest mismatch for
  `scripts/framework-fanout/generate_seed_v2.py` (seed expects
  `e44f6bde…`, this worktree's main has `e56ee6e70…`). That file is
  outside this framework and was not edited. Coverage accounting and
  Linux tests are otherwise green.
- No uikit render rule. Catalyst / iOS suite / real-app floors unchanged.
