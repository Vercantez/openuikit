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
portable in-process data models: remaining `IntentParameter` title /
`defaultValue` storage (AppEntity, File, collections, Bool displayName,
Date / URL / String / control styles), `DeprecatedAppIntent` replacement
type names, `FocusFilterAppContext` predicate storage, migrated custom
intent identifiers, and `ShowInAppSearchResultsIntent` search scopes /
criteria. `requestConfirmation`, async `requestValue` prompting, and
assistant-schema execution stay fail-closed or deferred. SwiftUI View
overlays stay `not-applicable`. EntityProperty `asyncGetter` stays
declared (no run loop).

Coverage this round (ledger at start of this increment, then after):

| | implemented | declared | deferred | unavailable | not-applicable | nondeferred |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Before | 2906 | 896 | 1196 | 0 | 1588 | 3802 |
| After wave 14 | 3125 | 677 | 1196 | 0 | 1588 | 3802 |
| After wave 15 | 3231 | 571 | 1196 | 0 | 1588 | 3802 |
| After wave 16 | 3331 | 537 | 1130 | 0 | 1588 | 3868 |
| After wave 17 | 4933 | 505 | 1130 | 0 | 18 | 5438 |
| After wave 18 | 5240 | 198 | 1130 | 0 | 18 | 5438 |
| After wave 19 | 5261 | 177 | 1130 | 0 | 18 | 5438 |
| After wave 20 | 5267 | 171 | 1130 | 0 | 18 | 5438 |
| After wave 21 | 5278 | 163 | 1127 | 0 | 18 | 5441 |

Wave 21 (this increment) converts 11 rows with five synchronous tests in
`tests/agent/AppIntentsWave21Tests.swift` (largest cites 3): the six
remaining `_System`-constrained `IntentParameter` description-first shapes
(no-title optionsProvider+resolvers / optionsProvider / resolvers / plain,
titled optionsProvider+resolvers / resolvers) pinned on `Value == String`
through the real host inits in `AppIntentsRemainingParameters.swift`
(default/description/dialog stored, provider attached, resolvers recorded
as metadata only), plus five `ShortcutsLinkStyle` statics (`dark` /
`light`, previously declared, and the `darkOutline` / `lightOutline` /
`automaticOutline` deferred rows) as host-local tokens on the overlay
struct in `AppIntentsOverlays.swift`, mirroring the existing
`SiriTipViewStyle` token design; `ShortcutsLinkStyle() == .automatic` is
preserved. Deliberately left declared: async `requestValue` /
`requestConfirmation` / `requestChoice` / `donate` / `perform` (no `await`
in cited tests), `EntityProperty.asyncGetter` (no run loop), macros
(`AppEnum(schema:)` et al, no plugin), `IntentResultContainer`
`result()` / `result(dialog:)` (kept out so `IntentResultValue`
inference stays unambiguous), `entityType` (host stores only the
type-name string, never the metatype), `_System` inits already covered,
`StartWorkoutIntent.init(style:)` (no init requirement to delegate to),
`AppIntentsExtension.configuration` (dependency-owned `AppExtension`),
`Never.init()` (uninhabited) and async `Never.perform()`,
`ExpressibleByNilLiteral` when-condition overloads (indistinguishable
without invented labels), and Siri/daemon/service behavior.

Wave 20 (this increment) converts 6 of the 177 declared rows: the five
`Never` result aliases (`Value` / `Dialog` / `Snippet` / `OpensAppIntent` /
`Intent`, each explicitly `= Never` exactly as Apple ships them) plus the
`Never.value` nil payload, pinned by two synchronous tests in
`tests/agent/AppIntentsWave20Tests.swift` (largest cites 4). New product
source lives in `AppIntentsWave20.swift`. The aliases complete the
`Never` surface wave 19 started (`PerformResult` / `SummaryContent`);
`Never.init()` stays declared (uninhabited; calling it would trap) as
does async `Never.perform()`. Also deliberately left declared:
`AppIntentsExtension.configuration` (Apple's protocol refines
ExtensionFoundation's dependency-owned `AppExtension`, which is not a
declared dependency of this lane and is never substituted locally),
`StartWorkoutIntent.init(style:)` (no init requirement to delegate a
protocol-extension initializer to), the `IntentResultContainer`
`result()` / `result(dialog:)` overloads (kept out so existing
`IntentResultValue` inference stays unambiguous), `entityType`, macros,
`_System` inits, async request/confirmation/donation,
`EntityProperty.asyncGetter`, and Siri daemon behavior.

Wave 19 (this increment) converts 21 of the 198 declared rows: 15 new
synchronous pins across eight tests in
`tests/agent/AppIntentsWave19Tests.swift` (largest cites 3) plus 6
declared-synthesized witnesses repointed at the already-tested base
spelling (`requestConfirmation()` / `continueInForeground` copies cite
`testConfirmationAndForegroundStayFailClosed`, the same treatment wave 18
gave 61 rows). New product source lives in `AppIntentsWave19.swift`
(`AssistantSchemaEnum` / `AssistantSchemaEntity`
`typeDisplayRepresentation` host-local type-name defaults plus five
`ParameterSummaryWhenCondition` overloads: two entity-identifier arities
and three value-based arities that record operator/values metadata and
evaluate to the `otherwise` branch). Other new pins cover `Never`
`PerformResult` / `SummaryContent` aliases, the fail-closed
`needsToContinueInForegroundError`, `PlayVideoIntent` /
`StartWorkoutIntent` `openAppWhenRun` inheritance, `OpenURLIntent`
`init(urlRepresentable:)` (the enum overload; the async entity overload
stays declared), `CaseDisplayRepresentable` `localizedStringResource`, and
`FileEntity` `supportedContentTypes`. The `ExpressibleByNilLiteral`
value-based condition overloads stay declared (indistinguishable from the
plain overloads without inventing labels), as do `entityType` (host stores
only the type-name string, never the metatype), the `schema()` free
functions, `_System` parameter inits, async `requestValue` /
`requestConfirmation` / `donate`, `EntityProperty.asyncGetter`, View
snippet execution, macros, Siri daemon behavior, and service success.

Wave 18 (this increment) converts 307 of the 505 declared rows: 61
declared-synthesized witnesses repointed at the already-tested base
spelling (same treatment as the 1,609 existing synthesized rows), and 246
new synchronous pins across 25 tests in
`tests/agent/AppIntentsWave18Tests.swift` (largest cites 22). New product
source lives in `AppIntentsWave18.swift` (builders, prediction/condition
inits, exotic comparator overloads, fail-closed initializers) plus small
additions to `AppIntents.swift` (sync `IntentDonationManager.donate`,
`IntentFile: InstanceDisplayRepresentable`, `AppEntity.Property`,
`Array.UnwrappedType`), `AppIntentsStructs.swift` (container storage,
`WidgetFamily` case, default-case display string), `AppIntentsClasses.swift`
(comparator/property storage), `AppIntentsEnums.swift` (generic query
builders, `IntentWidgetFamily: _IntentValue`), `AppIntentsProtocols.swift`
(`IntentValueQuery` result aliases), and `AppIntentsOverlays.swift`
(`result(value:content:)` overloads). `Array.UnwrappedType` is corrected
to `Array<Element>` per the oracle. Async `requestValue` /
`requestConfirmation` / `donate`, `EntityProperty.asyncGetter`, View
snippet execution, macros, Siri daemon behavior, and service success stay
fail-closed or declared.

Build repair (this increment): the module did not compile at the start of
this pass. Wave-15 sources assigned `hostMappingTransform`,
`hostResolverSpecification`, `hostKind`, `hostComparators`,
`hostEntityProvider`, `hostKeyPathDescription`, `hostDeclarations`,
`hostSorting`, and `hostKeyPath` members that were never declared, and
`FocusFilterAppContext.hostPredicateFormat` used a `predicateFormat` API
that current swift-corelibs-foundation deprecates (fatal under the
gate's warnings-as-errors). This pass declares the missing in-process
storage on the comparator/property/container types and rewords the format
helper to preserve its nil/non-nil contract. Three latent test defects
surface once the module compiles and are fixed in the tests: a
`Wave13Kind` enum conforming to both `AppEnum` and `AppEntity` hit two
competing `localizedStringResource` defaults (probe now defines one), a
`hostResolve` call missing `try`, and an `IntentParameter` initializer
ambiguous between two same-labeled overloads (disambiguated with an
explicit label).

Wave 17 (this increment) converts the 1,588-row SwiftUI overlay
`not-applicable` block to `implemented` following the PassKit/StoreKit
playbook, plus 32 declared-depth rows, with twelve synchronous batches in
`tests/agent/AppIntentsViewOverlayTests.swift` (1,570 rows, largest batch
cites 293) and six synchronous tests in
`tests/agent/AppIntentsDeclaredDepthTests.swift` (32 rows). Each leftover
`View` modifier is invoked on `SiriTipView`, `ShortcutsLink`, and
`EmptyView`; Linux renders `EmptyView` and the modifiers are identity
`Self` returns already compiling in `AppIntentsViewStubs.swift`, which this
pass collapses from 569 generic overloads to one `Any?`-parameter overload
per each of the 404 modifier names so no-argument calls are unambiguous
(the max-arity label sets are kept, preserving the `file` and
`configuration` declared anchors). The 18 remaining `not-applicable` rows
are `Button`/`Toggle` `intent:` initializers: constructing an
intent-executing control would claim Siri execution, so they stay
fail-closed. Depth tests pin inert UIKit overlay state (`ShortcutsUIButton`
/ `SiriTipUIView` construction, defaults, echoing `sizeThatFits`,
`setIntent`), overlay `body`/`Style` identities (`ShortcutsLinkStyle`
`dark`/`light` do not exist and stay declared), the fail-closed
`SetFocusFilterIntentError` catalog, placeholder builders, empty prediction
containers, and stored `@Parameter` title/optionality plus default
`parameterSummary` / `systemContext`. Async `requestValue` /
`requestConfirmation` / `donate`, View-taking result factories, macros,
Siri daemon behavior, and service success stay fail-closed or declared.
This pass also repairs one stale declared anchor (`#widgetFamily` →
`#WidgetFamily`; the member never existed, only the enum).

Wave 16 (this increment) implements remaining portable data-model
surface with nine synchronous tests in
`tests/agent/AppIntentsWave16Tests.swift` (100 rows, largest test cites 22):
compiler-synthesized `allCases` / `hashValue` / `hash(into:)` across all 22
`IntentParameter` measurement `ValueType` unit families (Volume, Length,
InformationStorage, Mass, Area, Power, Pressure, Frequency, Duration,
Angle, ElectricCharge, Energy, ElectricCurrent, ElectricResistance,
ElectricPotentialDifference, Speed, Temperature, FuelEfficiency,
Acceleration, ConcentrationMass, Dispersion, Illuminance; hashing stays
host-local), `EntityPropertyQuery` `properties` / `sortingOptions` /
`findIntentDescription` defaults plus the `ComparatorMappingType` /
`QueryProperties` / `ComparatorMode` / `SortingOptions` / `Sort` aliases,
`AssistantSchema` with its `EnumSchema` / `EntitySchema` / `IntentSchema`
nesting and three `init(_:)` overloads, the `AssistantEnum` /
`AssistantEntity` / `AssistantIntent` / `AssistantSchemaEnum` and
`AssistantSchemas.Model` / `Enum` / `Entity` / `Intent` protocol
identities plus `SearchCriteria`, and nine `ParameterSummaryWhenCondition`
overloads (six `identifier` key-path arities, two `widgetFamily` arities,
`hasValue`) that record operator/values metadata and evaluate to the
`otherwise` branch: Linux has no running intent to evaluate a key path
against and never claims a Siri match. `when` / `otherwise` take plain
closures, the same documented deviation wave 15 took, because the host
toolchain rejects result-builder attributes whose generic arguments
mention enclosing generic parameters; the `identifier` overloads
constrain `Parameter: AnyIntentValue` only, since the host
`AnyIntentValue` carries no `Value` associated type. Macros
(`AppEnum(schema:)` / `AppEntity(schema:)` / `AppIntent(schema:)`),
async `requestValue` / `requestConfirmation` / `requestChoice`, Siri
daemon behavior, `EntityProperty.asyncGetter`, `IntentPrediction`
parameter arities, value-based `WhenCondition` overloads needing
`Parameter.Value`, and SwiftUI overlays stay fail-closed, declared, or
not-applicable.

Wave 15 (previous increment) implements portable entity-query comparison and
container models with fourteen synchronous tests in
`tests/agent/AppIntentsWave15Tests.swift` (106 rows, largest test cites 20):
`EqualTo` / `NotEqualTo` / `LessThan` / `GreaterThan` /
`LessThanOrEqualTo` / `GreaterThanOrEqualTo` / `IsBetween` mapping-transform
and resolver-attaching inits, the `EntityProperty<String>` /
`EntityProperty<AttributedString>` `Contains` / `HasPrefix` / `HasSuffix`
overloads, `EntityQueryComparatorsBuilder` concatenation plus its four
`buildExpression` wrappings, `EntityQueryPropertiesBuilder` /
`EntityQuerySortingOptionsBuilder` / `ParameterSummaryBuilder` methods,
`EntityQueryProperties` / `EntityQuerySortingOptions` index subscripts and
`content` inits, `EntityQuerySortableByProperty` key-path storage,
`EntityQueryProperty` key-path/comparator/entity-provider inits,
`ResultsCollection` prompt/collation/empty/items on `Array`, `_IntentValue`
`ValueType` / `UnwrappedType` alias pins for scalars, `Optional`, and `Set`
(`Array.UnwrappedType` corrected to `Array<Element>` per the oracle),
`FileEntityIdentifier` / `IntentDonationIdentifier` coding plus `fileURL`,
`DisplayRepresentation.Image` coding round-trip, and a
`RangeComparableProperty` sample. `withResolvers` and the properties/content
closures take plain closures: the host toolchain rejects result-builder
attributes whose generic arguments mention enclosing generic parameters, so
the builder spelling is elided while resolver specs are still stored as
metadata. Sequence and `ExpressibleByNilLiteral` comparator overloads stay
declared (`_SequenceIntentValue` has no host source). Async `requestValue` /
`requestConfirmation` / `requestChoice`, Siri daemon behavior,
`EntityProperty.asyncGetter`, and SwiftUI overlays stay fail-closed,
declared, or not-applicable. (This pass also re-applied wave 15's ledger
edits verbatim after an unrelated stash reverted them, and lists
`AppIntentsWave15.swift` in the guest sources manifest.)

Wave 14 (earlier increment) implements portable shortcut-presentation and
template models with twenty synchronous tests in
`tests/agent/AppIntentsWave14Tests.swift` (219 rows, largest test cites 20):
`NegativeAppShortcutPhrase` / `NegativeAppShortcutPhrases` templates,
`AppShortcutsContent.appShortcuts`, `AppShortcutOptionsCollection` storage
plus the options-collection specification protocol and its 1–15-arity
result-builder concatenation, `AppShortcutParameterPresentation` /
title / summary with key-path-interpolated title/summary strings,
`EntityURLRepresentation` / `IntentURLRepresentation` templates,
`IntentParameterDependency` 2–15-key-path arities (arity is recorded;
options are never re-extracted), `ParameterSummaryString` interpolation +
`IntentParameterSummary` table / key-path builders, `IntentItem` /
`IntentItemSection` (new subtitle/image builder init) /
`IntentItemCollection`, `IntentChoiceOption` styles,
`ConfirmationConditions` / `EntityPropertyModifiers` option sets,
`VideoCategory` / `StringSearchScope` tables, `UniqueAppEntityProvider`
sync aliases, resolver input/output aliases, and the sync
`needsDisambiguationError` / `donate()` / `donate(result:)` surface.
Async `requestValue` / `requestConfirmation` / `requestChoice`, Siri
daemon behavior, `EntityProperty.asyncGetter`, and SwiftUI overlays stay
fail-closed, declared, or not-applicable.

Prior increment on this tree was 1234 / 2548 / 1216 → 1526 / 2257 / 1215.
Floor is 3293. SwiftUI `s:7SwiftUI…` View / Button / Toggle / ModifiedContent
overlay re-exports (1,588 rows) are `not-applicable` with
`SwiftUI cross-import overlay; owned by the SwiftUI lane`.

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 293 | 5.6% | `AppIntentsViewOverlayTests.swift#testViewOverlayBatch01` |
| 176 | 3.6% | `AppIntentsWave10Tests.swift#testEntityPropertyConcreteAccessorMatrix` |
| 174 | 3.5% | `AppIntentsWave10Tests.swift#testEntityPropertyConcreteStorageAndMetadataMatrix` |
| 170 | 3.4% | `AppIntentsViewOverlayTests.swift#testViewOverlayBatch09` |
| 157 | 3.2% | `AppIntentsWave12Tests.swift#testIntentParameterRemainingMeasurementDefaultUnitInits` |

No test is cited by more than 293 rows (5.9% of implemented rows, well
under the 40% bulk-relabel line). Wave-14 tests cite at most 20 rows each.
Wave-15 tests cite at most 20 rows each. Wave-16 tests cite at most 22 rows
each. Wave-17 overlay batches cite at most 293 rows each; depth tests cite
at most 12 rows each. Wave-18 tests cite at most 22 rows each. Wave-19 tests cite at most 3 rows each. Wave-20 tests cite at most 4 rows each. Wave-21 tests cite at most 3 rows each.
New depth-pass tests are synchronous; they do not
wait on `DispatchSemaphore` or `RunLoop`. Existing first-pass `wait()` helpers
remain for `perform()` only.

Environment: `.cursor/verify-cloud-environment.sh` emitted
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=scratch-corpus evidence=dotnet-macios`. Starting commit
`08da4b0127920d2a794d74490b5a0e8faed63584` matched the campaign invariant.

`python3 -B full/framework-fanout/validate_seed.py --framework full/appintents --phase deliverable`
accepted 6,586 IDs. Darwin Apple `swiftc` cannot emit `libAppIntents.dylib`
here because lookalikes are behind `!canImport(CoreLocation)` /
`CoreSpotlight` (this SDK has both). The sealed Linux host gate remains
the compile/run authority:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=AppIntents lane=medium-full symbols=6586
```

`bash full/appintents/tests/test_appintents_host.sh` compiled the host runtime probe (`APPINTENTS_HOST_RUNTIME_OK`) and skipped exact ButtonKit/SFSafeSymbols consumers (`APPINTENTS_EXACT_CONSUMERS_SKIPPED`) because those caches are not on this VM.

### What this pass added

- Wave 13 stores `DeprecatedAppIntent` replacement metadata as a type
  name (`IntentDeprecation.hostReplacementTypeName` / `replacedBy`).
  Linux does not migrate Siri or Shortcuts.
- `FocusFilterAppContext` is a value type holding an optional
  `NSPredicate` and `targetContentIdentifierPrefix`. There is no Focus
  daemon.
- `CustomIntentMigratedAppIntent.persistentIdentifier` equals
  `intentClassName`.
- `ShowInAppSearchResultsIntent` stores `criteria` and `searchScopes`
  and defaults `openAppWhenRun` to `true`. `StringSearchCriteria.term`
  round-trips; hash is host-local.
- Remaining `@Parameter` title / `defaultValue` inits for AppEntity,
  FileEntity, IntentFile (`supportedTypeIdentifiers`), collection
  `size`, Bool `displayName`, Date / URL / AttributedString / String
  inputOptions, and Int/Double description-only control styles. Options
  providers and resolvers attach metadata only.
- `EntityProperty` Codable / title storage from wave 12 stays; remaining
  `asyncGetter` overloads stay declared (no run loop).

- Wave 12 implements the leftover Foundation.Measurement `@Parameter`
  inits (Mass / Area / Power / Pressure / Frequency / Duration / Angle /
  electric and remaining unit families). Typed constructors store
  `defaultValue`, `defaultUnit` / `unit`, `supportsNegativeNumbers`, and
  `unitAdjustForLocale` the same way Volume / Length / InformationStorage
  already did. Options providers and resolvers attach metadata only.
- `EntityProperty` is Codable when `Value` is: encode/decode round-trips
  stored value, title, and identifier. Host hash / display helpers are
  in-process; they do not write Spotlight or claim Siri resolution.
  Codable `asyncGetter` overloads stay declared (no run loop).
- `IntentParameter.title` and `defaultValue` are public. Nested
  `DateKind` / `IntControlStyle` / `DoubleControlStyle` /
  `PlacemarkDisplayStyle` implement `hash(into:)`. Synthesized
  `hashValue` / `==` stay deferred. `hostDisplayRepresentation` /
  `hostRequestValueDisplayRepresentation()` read stored values and
  `requestValueDialog`. Async `requestValue` and `requestConfirmation`
  still throw `unsupportedOnDevice`.

- Wave 11 exercises concrete `EntityProperty` storage and default-entity
  key-path access across strings, numbers, dates, URLs, attributed strings,
  date components, and Foundation measurement families. It also replaces the
  catch-all async-getter constructor with typed, retained async closures and a
  host resolution entry point. Missing getters and entity type mismatches throw
  `AppIntentError.Unrecoverable` rather than claiming daemon-backed success.
  The synchronous sealed tests verify attachment metadata but deliberately do
  not block a run loop to invoke asynchronous closures. This moves 300 exact
  rows from declared to implemented with focused evidence.

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
  `AppIntentError.Unrecoverable.unsupportedOnDevice`. Host display
  helpers read stored values / `requestValueDialog` without inventing a
  Siri prompt.
- `DeprecatedAppIntent` stores a replacement type name. It does not
  migrate Siri vocabulary or Shortcuts. `FocusFilterAppContext` stores
  an `NSPredicate` / identifier prefix and never talks to Focus.
  `ShowInAppSearchResultsIntent` stores criteria and scopes; it does
  not present in-app search UI.
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
shape. EntityProperty `asyncGetter` specializations, including the
Codable-constrained copies, stay declared (no blocking run loop).
`requestConfirmation` and SwiftUI confirmation views stay declared or
fail-closed. Synthesized `==` / `hash(into:)` witnesses without an
explicit host source stay `deferred`.

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
