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
a next pass: earlier sources and tests stay green. This round implements
the remaining `@Property` specializations the ledger called out
(`EntityProperty` where `Value` is `URL` / `Date` / `DateComponents` /
`AttributedString` / `Calendar.RecurrenceRule` / `IntentFile` /
`IntentPerson` / `IntentPaymentMethod` / `IntentCurrencyAmount` /
`AppEntity` / `CLPlacemark`), plus typed `@Parameter` inits for DateComponents (`kind`),
IntentCurrencyAmount (`currencyCodes` / Decimal `inclusiveRange`),
IntentPerson (`parameterMode`), IntentPaymentMethod, and CLPlacemark
(`displayStyle`). `asyncGetter` stays declared (no run loop). Sample
`PropertyPayIntent` / `Wave9PlaceIntent` evaluate `hostResult()` in-process.

Coverage this round (ledger at start of this increment, then after):

| | implemented | declared | deferred | unavailable | not-applicable | nondeferred |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Before | 1738 | 2052 | 1208 | 0 | 1588 | 3790 |
| After | 2088 | 1702 | 1208 | 0 | 1588 | 3790 |

Prior increment on this tree was 1234 / 2548 / 1216 → 1526 / 2257 / 1215.
Floor is 3293. SwiftUI `s:7SwiftUI…` View / Button / Toggle / ModifiedContent
overlay re-exports (1,588 rows) are `not-applicable` with
`SwiftUI cross-import overlay; owned by the SwiftUI lane`.

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 176 | 8.4% | `AppIntentsWave10Tests.swift#testEntityPropertyConcreteAccessorMatrix` |
| 174 | 8.3% | `AppIntentsWave10Tests.swift#testEntityPropertyConcreteStorageAndMetadataMatrix` |
| 53 | 2.5% | `AppIntentsWaveTests.swift#testAssistantSchemasNamespaceStatics` |
| 42 | 2.0% | `AppIntentsWave9Tests.swift#testIntentResultActionButtonAndSnippetFactories` |
| 41 | 2.0% | `AppIntentsMeasurementTests.swift#testIntentParameterInformationStorageUnitTable` |

No test is cited by more than 8.4% of implemented rows (well under the
40% bulk-relabel line). New depth-pass tests are synchronous; they do not
wait on `DispatchSemaphore` or `RunLoop`. Existing first-pass `wait()` helpers
remain for `perform()` only.

Environment: `.cursor/verify-cloud-environment.sh` emitted
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=scratch-corpus evidence=dotnet-macios`. Starting commit
`5a351db2038abca71a1b943af3a86963f403f724` matched the campaign invariant.

`bash full/appintents/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AppIntents lane=medium-full symbols=6586
FRAMEWORK_FANOUT_REFERENCE_OK
APPINTENTS_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=AppIntents dylib=libAppIntents.dylib
```

`bash full/appintents/tests/test_appintents_host.sh` compiled the host runtime probe (`APPINTENTS_HOST_RUNTIME_OK`) and skipped exact ButtonKit/SFSafeSymbols consumers (`APPINTENTS_EXACT_CONSUMERS_SKIPPED`) because those caches are not on this VM.

### What this pass added

- Wave 10 adds a synchronous concrete `EntityProperty<Int>` matrix covering stored values, projected wrapper identity, title / identifier, Spotlight metadata, and every synchronous getter / writable-getter combination. The getter matrix resolves an actual default `AppEntity` through `EntityResolutionEngine`; async getters remain declared rather than being driven with a blocking run loop. This moves 350 exact `EntityProperty` rows from declared to implemented with two focused tests.

- `@Property` (`EntityProperty`) `CLPlacemark` identifier / title /
  KeyPath getter / getSetter / indexingKey / customIndexingKey inits
  resolve from `EntityResolutionEngine.defaultResult`. `asyncGetter`
  stays declared. Host-local `CLPlacemark` stores `name` / `locality` /
  `thoroughfare`; there is no `CLGeocoder`.
- `@Parameter` `CLPlacemark` stores `displayStyle` (`.name` / `.city` /
  `.address`) on the wrapper and `IntentParameterContext`. Options
  providers are attached and not consulted. Linux never formats a
  Maps address card.
- `EnumURLRepresentation` interpolates `${rawValue}` / per-case maps.
  There is no system URL handler.
- `ResolverSpecificationBuilder` concatenates `buildBlock` arities 0–15.
  Concrete resolvers expose synchronous `hostResolve` (radix / rounding).
  Protocol `resolve(from:context:)` stays async and is not waited on in
  the sealed gate.
- `IntentResult` / `IntentResultContainer` action-button, snippet-intent,
  and `value:opensIntent:` factories store the payload. Overlay
  `opensIntent` + `view` / `content` discards the `View` (fail-closed UI).
  Empty `.result()` / `.result(dialog:)` stay on `IntentResultValue`.
- `IntentFile.hostData` / `hostFile` read stored bytes or a path. Codable
  round-trips `removedOnCompletion`. UTI daemons and security-scoped
  bookmarks are unobserved; async `data` / `file` stay declared.
- `Wave9PlaceIntent.hostResult()` returns the stored placemark name.

- `@Property` (`EntityProperty`) specializations for `URL`, `Date`,
  `DateComponents`, `AttributedString`, `Calendar.RecurrenceRule`,
  `IntentFile`, `IntentPerson`, `IntentPaymentMethod`,
  `IntentCurrencyAmount`, and `AppEntity` resolve identifier / title /
  KeyPath getter / getSetter / indexingKey / customIndexingKey inits from
  `EntityResolutionEngine.defaultResult`. `asyncGetter` stays declared.
- `@Parameter` DateComponents stores `kind` (`date` / `time` / `dateTime`)
  and accepts host `optionsProvider` / `resolvers` metadata.
- `@Parameter` IntentCurrencyAmount stores `currencyCodes` and a Decimal
  `inclusiveRange`. `IntentParameterContext.currencyCodes` is host-local.
- `@Parameter` IntentPerson stores `parameterMode`. There is no Contacts
  picker.
- `@Parameter` IntentPaymentMethod applies defaults the same way as
  String. Options providers are attached and not consulted.
- `Calendar.RecurrenceRule` conforms to `_IntentValue`. EventKit
  occurrence expansion is not claimed.
- `PropertyPayIntent.hostResult()` returns the stored currency code. Linux
  never claims a Shortcuts payment sheet.

Earlier wave-8 additions that remain:

- `IntentParameter.Volume` / `Length` / `InformationStorage` (and the
  other 19 Foundation measurement unit enums) are `CaseIterable`. A table
  test checks `allCases` uniqueness and `foundationUnit.symbol == rawValue`.
  Linux uses `UnitType(symbol:converter:)` with an identity converter; it
  does not invent Apple locale conversion.
- `@Parameter` measurement inits for Volume / Length / InformationStorage
  store `defaultValue` + `defaultUnit` / `unit`, `supportsNegativeNumbers`,
  and `unitAdjustForLocale`. `makeContext()` copies those onto
  `IntentParameterContext`. Resolver and optionsProvider overloads attach
  metadata only; they do not consult Shortcuts.
- `EntityProperty<File>` identifier / title / KeyPath getter / getSetter /
  indexingKey / customIndexingKey inits resolve from
  `EntityResolutionEngine.defaultResult`. `asyncGetter` stays declared
  (no run loop). `File` is an in-process URL+data value; bookmarks are
  unobserved.
- `IntentPerson` identifier / name / handle Codable round-trips. `image`
  is stored and not encoded (`DisplayRepresentation.Image` is not Codable).
- `@Parameter` AppEnum stores `supportedValues` and
  `requestDisambiguationDialog`. AppEntity accepts a host `query`.

Earlier wave-8 additions that remain:

- AssistantSchemas family protocols (`CameraEnum`, `MailIntent`, …) now
  have default implementations that return named `EnumSchema` /
  `EntitySchema` / `IntentSchema` tokens. Empty probe types plus a table
  test per family check every required parameter name. There is still no
  Apple Intelligence extract.
- `@Property` stores `indexingKey`
  (`PartialKeyPath<CSSearchableItemAttributeSet>`), `customIndexingKey`
  (`CSCustomAttributeKey`), and a `KeyPath` getter resolved from
  `EntityResolutionEngine.defaultResult`. Spotlight is not claimed.
- `@Parameter` Date inits store `kind` (`date` / `time` / `dateTime`).
  Bool, URL, and `IntentFile` (`supportedContentTypes`) inits apply
  defaults the same way as String.
- `FileEntityIdentifier.file(url:)` / `.draft(identifier:)` /
  `.entityIdentifier(for:)` round-trip `draft:` tokens and path URLs.
- `IntentPaymentMethod` / `IntentCurrencyAmount` / `IntentCollectionSize`
  / titled `IntentItem` are value types with display strings.
- `ConfirmationActionName` catalog, remaining `ShortcutTileColor` /
  `IntentWidgetFamily` cases, and comparison-operator tables.
- `ProgressReportingIntent.progress` is a process-local `Foundation.Progress`.
  `RelevantIntentManager` records `widgetKind` + score; it does not reload
  WidgetKit.
- `DeleteIntent.entities` / `SetValueIntent.value` / `OpenIntent.target`
  compile on sample intents. `EntityQuerySort` stores `by` + `order`;
  `EntityPropertyQuery.entities(matching:mode:sortedBy:limit:)` applies
  string comparators, descending reverse, and `limit`.

Earlier second-pass additions that remain:

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
- EntityProperty `indexingKey` / `customIndexingKey` are stored metadata.
  Linux never writes `CSSearchableIndex`.
- `ProgressReportingIntent.progress` is a host-owned `Progress` object.
  `RelevantIntentManager` is a process-local list (no WidgetKit reload).
- `FileEntityIdentifier` draft tokens use the `draft:` prefix. Apple's
  bookmark / security-scope encoding is unobserved.
- Measurement `@Parameter` values use `UnitType(symbol: rawValue)`. Linux
  never claims a locale-adjusted Foundation unit or Shortcuts unit picker.
- `File` entity-property values store URL and bytes in-process. They are
  not security-scoped bookmarks.
- `EntityProperty` URL / Date / DateComponents / AttributedString /
  RecurrenceRule / IntentFile / IntentPerson / IntentPaymentMethod /
  IntentCurrencyAmount / AppEntity / CLPlacemark inits are process-local. Spotlight
  indexing keys are stored and never written to `CSSearchableIndex`.
- `CLPlacemark` is a host-local name/locality/thoroughfare value. There is
  no `CLGeocoder` or Maps address card. `displayStyle` is stored metadata.
- `IntentFile.hostData` / `hostFile` do not consult a UTI daemon or
  security-scoped bookmarks. Async `data` / `file` stay declared.
- `result(opensIntent:view:)` / `content:` discard the `View`. Snippet
  UI and action-button presentation are unobserved.
  `asyncGetter` is not invoked.
- IntentCurrencyAmount `currencyCodes` is a stored string list. Linux
  does not validate ISO 4217 or format a locale amount.
- IntentPerson `parameterMode` is stored metadata. There is no Contacts
  picker or CNContact hydration.
- `Calendar.RecurrenceRule` is a Foundation value. EventKit occurrence
  expansion is unobserved.
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
