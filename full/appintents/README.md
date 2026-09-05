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
  keep `controlStyle` and `inclusiveRange`. Reading an unset non-optional
  parameter with no default traps rather than inventing a value.
  `requestValue` / `requestDisambiguation` throw `unsupportedOnDevice`.
- `AppEntity` / `AppEnum` / `EntityStringQuery` / `EntityPropertyQuery` /
  `UniqueAppEntityProvider` run in-process: `entities(for:)`,
  `suggestedEntities()`, `entities(matching:)`, and `uniqueEntity()`.
- `DisplayRepresentation` / `TypeDisplayRepresentation` / `IntentDialog`
  (`full`/`supporting`/`systemImageName`) are value types. Dialog string
  interpolation is process-local.
- `AppShortcut` phrases interpolate `.applicationName` to
  `${applicationName}`. `AppShortcutsBuilder` concatenates shortcut lists.
  `AppShortcutsProvider.updateAppShortcutParameters()` is a documented
  no-op.
- `AppIntentsHost` is a Linux registry: a widget/host can
  `registerShortcuts`, `registerIntent`, `applyParameters` (Mirror, `_`
  prefix strip via `hasPrefix`), and `perform(identifier:parameters:)`.
- `AppDependencyManager.add` stores a sync value. `get` throws
  `failedToRetrieveDependency` instead of Apple's crash-on-missing.
  Async `add` providers register nothing.
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
- `EntityProperty` getters trap until a value is supplied. CoreSpotlight
  indexing keys are lookalikes on the isolated host.
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
