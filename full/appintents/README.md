# Portable AppIntents

This directory is a clean-room Linux starting point for Apple's public
`AppIntents` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, and TBD exports. It is not wired into the shared guest package;
that integration is a later central-review step.

The earlier portable module remains: intents execute in-process through
`AppIntentRuntime`, shortcut phrases keep their interpolation templates, and
the guest never reports that a system Shortcuts registrar accepted a
registration (`AppIntentsPortable.supportsSystemRegistration == false`).

Wave-6 adds schema-v2 coverage for the sealed 6586-ID public surface. The
isolated Linux host compiles these sources with `swiftc` and Foundation only.

## Depth pass 2026-09 (wave 8)

SDK depth for `AppIntents` in `full/appintents/` (6,586 exact IDs). This is
a second pass: the first-pass sources and tests stay green; this round adds
host-driven property-wrapper, resolution, summary, and AssistantSchemas
machinery with focused synchronous tests.

Coverage this round:

| | implemented | declared | deferred | unavailable | not-applicable | nondeferred |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Before | 299 | 4552 | 1735 | 0 | 0 | 4851 |
| After | 348 | 3126 | 1524 | 0 | 1588 | 3474 |

Floor is 3293. SwiftUI `s:7SwiftUI…` View / Button / Toggle / ModifiedContent
overlay re-exports (1,588 rows) are `not-applicable` with
`SwiftUI cross-import overlay; owned by the SwiftUI lane`.

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 29 | 8.3% | `AppIntentsCorpusTests.swift#testIntentFilePersonAndItemCollection` |
| 28 | 8.0% | `AppIntentsCorpusTests.swift#testAppShortcutBuilderUpdateAndApplicationNameToken` |
| 21 | 6.0% | `AppIntentsCorpusTests.swift#testDisplayRepresentationImagesAndSynonyms` |
| 19 | 5.5% | `AppIntentsCorpusTests.swift#testParameterControlStyleAndInclusiveRange` |
| 18 | 5.2% | `AppIntentsCorpusTests.swift#testAppIntentStaticRequirements` |

No non-enum test is cited by more than 8.3% of implemented rows (well under
the 40% bulk-relabel line). Depth-pass tests are synchronous; they do not
wait on `DispatchSemaphore` or `RunLoop`.

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`dd4c8bca7e8735289928bbd1abd44f4b35815308` matched.

`bash full/appintents/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AppIntents lane=medium-full symbols=6586
FRAMEWORK_FANOUT_REFERENCE_OK
APPINTENTS_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AppIntents dylib=libAppIntents.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

`bash full/appintents/tests/test_appintents_host.sh` compiled the host runtime probe (`APPINTENTS_HOST_RUNTIME_OK`) and skipped exact ButtonKit/SFSafeSymbols consumers (`APPINTENTS_EXACT_CONSUMERS_SKIPPED`) because those caches are not on this VM.

### What this pass added

- `@Property` (`EntityProperty`) stores `title` / `identifier`, applies a
  `getter` when unset, and returns `nil` for optional unset values instead
  of trapping.
- `@Parameter` accepts `inputOptions` (`String.IntentInputOptions`) and
  records that an `optionsProvider` was attached. Dynamic options are
  resolved from host-attached snapshots or `EntityResolutionEngine`,
  never by inventing a Shortcuts extract.
- `EntityResolutionEngine` is a process-local catalog for
  `suggestedEntities`, `entities(for:)`, `entities(matching:)`,
  `defaultResult`, and `allEntities`.
- `TransientAppEntity` uses UUID ids and `_TransientAppEntityQuery`.
- `ParameterSummary` / `IntentParameterSummary` / `Summary("… \(\.$url)")`
  evaluate to display strings (`${parameter}`). `Switch` / `Case` / `When`
  condition structs store the evaluated branch string.
- AppShortcut phrases expand both `${applicationName}` and `${parameter}`.
- `OpenIntent` has `Value: AppEntity` and `target`. Sample open/foreground
  intents compile as `SystemIntent` / `ForegroundContinuableIntent`.
- `AssistantSchemas` protocols carry the required parameter catalog; a
  table test checks every family's parameter set. There is no Apple
  Intelligence runtime on this host.

## Coverage honesty (second pass)

The first pass marked **1575** identifiers `implemented`, but **771** of them
(713 non-enum) cited only `testIntentPerformEcho` — a bulk relabel.
`implemented` evidence must be a focused test of that identifier. This pass
keeps the original 49 implemented IDs, adds focused family tests, and
reclassifies the bulk rows to `declared` (or `deferred` when there is still
no host source). **299** implemented / **4552** declared / **1735** deferred.
Nondeferred **4851** remains above the medium-full floor of 3293.

No implemented test is cited by more than 29 rows (9.7% of implemented).
`testIntentPerformEcho` cites **one** ID: `AppIntent.perform()`.

## What is real

- `AppIntent.perform()` runs in-process. `AppIntentRuntime` records an
  execution count for hosts that need deterministic lifecycle evidence.
  Static requirements (`title`, `description`, `openAppWhenRun`,
  `isDiscoverable`) are stored on the type.
- `.result()` / `.result(dialog:)` on `IntentResultValue` return the portable
  dialog payload used by existing host probes. Apple's
  `IntentResultContainer` factories that would collide with that inference
  are not substituted in. `.result(value:)`, `.result(value:dialog:)`,
  `.result(opensIntent:)`, and `.result(view:)` / `.result(content:)` live
  on `IntentResult` / the SwiftUI overlay and return `IntentResultContainer`.
- `@IntentParameter` (typealias `Parameter`) stores supplied values and
  applies a `default` when the wrapper is still unset. Int/Double inits
  keep `controlStyle` and `inclusiveRange` (Int `(1, 9)` round-trips as
  1…9). Reading an unset non-optional parameter with no default traps
  rather than inventing a value. `requestValueDialog` is stored on
  metadata. An `optionsProvider` argument is accepted and not consulted
  for `wrappedValue` (no Shortcuts metadata extractor). `requestValue` /
  `requestDisambiguation` throw or return `unsupportedOnDevice`.
- `AppEntity` / `AppEnum` / `EntityStringQuery` / `EntityPropertyQuery` /
  `UniqueAppEntityProvider` run in-process: `entities(for:)`,
  `suggestedEntities()`, `entities(matching:)`, and `uniqueEntity()`.
- `DisplayRepresentation` / `TypeDisplayRepresentation` / `IntentDialog`
  (`full`/`supporting`/`systemImageName`) are value types. Dialog string
  interpolation is process-local. `LocalizedStringResource.key` is the
  portable text (Darwin Foundation string-literal key equals the literal).
- `AppShortcut` phrases interpolate `.applicationName` to
  `${applicationName}`. `AppShortcutsBuilder` concatenates shortcut lists.
  `AppShortcutsProvider.updateAppShortcutParameters()` is a documented
  no-op.
- `AppIntentsHost` is a Linux registry: a widget/host can
  `registerShortcuts`, `registerIntent`, `applyParameters` (Mirror, `_`
  prefix strip via `hasPrefix`), and `perform(identifier:parameters:)`.
- `AppDependencyManager.add` stores a sync value. `get` throws
  `failedToRetrieveDependency` instead of Apple's crash-on-missing.
  Async `add` providers register nothing. `AppDependency` with a default
  uses the default when `get` misses.
- `IntentDonationManager` records process-local identifiers. It never claims
  that the Shortcuts daemon persisted a donation.
- `AppIntentError` is a fail-closed catalog (`unsupportedOnDevice`,
  permission, user-action). Confirmation, choice, and foreground-continue
  APIs throw `unsupportedOnDevice` rather than inventing UI success.
- Option sets (`IntentModes`, `ConfirmationConditions`), tile colors,
  authentication policy, widget families, and display representations are
  source-compatible declarations with focused tests for the in-process
  slice.
- SwiftUI `SiriTipView` / `ShortcutsLink` exist as inert host types. View
  method names from the synthesized overlay live in
  `AppIntentsViewStubs.swift` so those precise IDs have source anchors
  without a SwiftUI module.

## Fail-closed boundaries

- No Shortcuts / Siri / App Intents metadata extractor, daemon, or
  entitlements.
- Request confirmation, request choice (empty), continue-in-foreground,
  and `IntentParameter.requestValue` throw
  `AppIntentError.Unrecoverable.unsupportedOnDevice`.
- `EntityProperty` traps only when a non-optional value was never stored
  and no getter was supplied. Optional unset properties return `nil`.
  CoreSpotlight indexing keys are lookalikes on the isolated host.
- `EntityResolutionEngine` is process-local. It never claims Shortcuts
  or Apple Intelligence resolved an entity.
- UIKit `ShortcutsUIButton` / `SiriTipUIView` are NSObject subclasses on
  Linux; they do not present system UI.
- Macros (`AppIntent(schema:)`, `ComputedProperty`, …) are deferred: there
  is no macro plugin on this host.
- `EntityIdentifier.init?(activityIdentifier:)` accepts a non-empty string
  and stores type `"activity"`. Apple's encoding is unobserved.
- `AppDependencyManager.Error` cases have no associated values on Linux
  (Sendable/metatype). Apple's cases carry key and type payloads.

## Deferred / unavailable

Operators (`==`, `!=`) have no valid coverage identifier anchor and stay
`deferred`. Synthesized SetAlgebra / Sequence / stdlib witnesses without a
host source anchor stay `deferred`. Apple result factories that return
`IntentResultContainer` for the simple `result()` / `result(dialog:)`
spellings are not declared, so existing `IntentResultValue` inference used
by the Mach-O host probe remains unambiguous.

Generic `IntentParameter` / `EntityProperty` catch-all inits in
`AppIntentsMembers.swift` stay `declared` stubs unless a test calls that
shape. Measurement `defaultUnit` specializations on
`IntentParameterContext` stay deferred: UniformTypeIdentifiers / unit
nested types are not a declared dependency.

There is no public `ResolvedValue` symbol in the 26.1 graph.
`IntentParameterDependency.wrappedValue` is an `IntentProjection`.

`tests/agent/AppIntentsDependencyIdentity.swift` imports Foundation and
passes genuine `URL` / `Data` / `Date` values through AppIntents APIs. The
isolated host gate does not compile that probe.

The wave-6 deliverable gate is:

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/appintents --phase deliverable
bash full/appintents/tests/acceptance/test_host.sh
```
