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
- `.result()` / `.result(dialog:)` on `IntentResultValue` return the portable
  dialog payload used by existing host probes. Apple's
  `IntentResultContainer` factories that would collide with that inference
  are not substituted in.
- `@IntentParameter` (typealias `Parameter`) stores supplied values. Reading
  an unset non-optional parameter traps rather than inventing a value.
- `AppShortcut` phrases interpolate `.applicationName` to
  `${applicationName}`. `AppShortcutsBuilder` concatenates shortcut lists.
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
- Request confirmation, request choice (empty), and continue-in-foreground
  throw `AppIntentError.Unrecoverable.unsupportedOnDevice`.
- `EntityProperty` getters trap until a value is supplied. CoreSpotlight
  indexing keys are lookalikes on the isolated host.
- UIKit `ShortcutsUIButton` / `SiriTipUIView` are NSObject subclasses on
  Linux; they do not present system UI.
- Macros (`AppIntent(schema:)`, `ComputedProperty`, …) are deferred: there
  is no macro plugin on this host.

## Deferred / unavailable

Operators (`==`, `!=`) have no valid coverage identifier anchor and stay
`deferred`. Synthesized SetAlgebra / Sequence / stdlib witnesses without a
host source anchor stay `deferred`. Apple result factories that return
`IntentResultContainer` for the simple `result()` / `result(dialog:)`
spellings are not declared, so existing `IntentResultValue` inference used
by the Mach-O host probe remains unambiguous.

`tests/agent/AppIntentsDependencyIdentity.swift` imports Foundation and
passes genuine `URL` / `Data` / `Date` values through AppIntents APIs. The
isolated host gate does not compile that probe.

The wave-6 deliverable gate is:

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/appintents --phase deliverable
bash full/appintents/tests/acceptance/test_host.sh
```
