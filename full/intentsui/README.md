# Open IntentsUI

`IntentsUI.swift` is the production source for `IntentsUI.swiftmodule` and
`libIntentsUI.dylib`. Isolated host compilation imports Foundation only and
produces a loadable dylib; it does not claim Apple Siri, Shortcuts, or UIKit
presentation behavior.

The add/edit controllers keep the first-party delegate spelling used by
untouched Siri-shortcut screens. A platform host calls `finish(invocationPhrase:)`,
`cancel()`, or `delete()` in response to its controls. Delegates receive the
installed, updated, or deleted stable shortcut identity. Empty phrases and
missing shortcuts report `INUIVoiceShortcutError`. The controllers never pretend
that Apple's Siri account or sheet is available.

## What is real

- `INUIAddVoiceShortcutButtonStyle` raw values are `white = 0` through
  `automaticOutline = 5`, matching the pinned `dotnet/macios` `[Native]` order.
- `INUIHostedViewContext` raw values are `siriSnippet = 0`, `mapsCard = 1`.
- `INUIInteractiveBehavior` raw values are `none = 0`, `nextView = 1`,
  `launch = 2`, `genericAction = 3`.
- `INUIAddVoiceShortcutButton` stores style (get via `style`, mutate via
  `setStyle`), optional `shortcut`, `cornerRadius`, and a weak delegate.
  Isolated Linux subclasses `NSObject` because `UIButton` is UIKit-owned.
- `INUIAddVoiceShortcutViewController.init(shortcut:)` and
  `INUIEditVoiceShortcutViewController.init(voiceShortcut:)` retain the
  caller-provided identity and the weak delegate. Isolated Linux subclasses
  `NSObject` because `UIViewController` is UIKit-owned.
- Host `finish` installs or updates a process-local voice shortcut when the
  phrase contains a non-whitespace character. Empty or whitespace-only phrases
  report `emptyInvocationPhrase` and do not mutate the table. `delete` removes
  by UUID or reports `shortcutNotFound`. `cancel` only notifies the delegate.
- `INUIHostedViewSiriProviding` defaults `displaysMap`, `displaysMessage`, and
  `displaysPaymentTransaction` to `false`. Overrides are visible through an
  existential.
- The current presentation capability is `.hostDriven`.

## Fail-closed / deferred

- `INImage` UIKit/CoreGraphics overlays (`init(UIImage:)`, `init(CGImage:)`,
  `fetchUIImage`, `imageSize(for:)`) are not declared: `INImage`, `UIImage`,
  and `CGImage` are owned by other modules.
- `NSExtensionContext` hosted-view size/description members are not declared:
  `NSExtensionContext` is Foundation-owned and absent from this Linux
  Foundation overlay. A public lookalike is forbidden.
- `INUIHostedViewControlling.configure*` methods are not declared:
  `INParameter` and `INInteraction` are Intents-owned, and Siri snippet
  sizing is unobserved.
- Darwin default `cornerRadius`, add-versus-edit tap mapping, and Apple
  error domains for empty phrases are unobserved.

`INShortcut` and `INVoiceShortcut` on the isolated host are module-local
stand-ins so IntentsUI-owned initializers type-check. They are not an Intents
port. When a real Intents module is on the link line, those stand-ins must be
removed.

## Tests

`tests/agent/IntentsUILoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/IntentsUITests.swift` holds the sealed focused tests.
`tests/agent/IntentsUIRuntime.swift` is a standalone probe
(`INTENTSUI_AGENT_RUNTIME_OK`).
`tests/agent/IntentsUIDependencyIdentity.swift` is prepared for a future
clean EC2 run that builds guest Foundation first.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

## Depth pass 2026-09

Implemented before: 55. Implemented after: 55. Declared: 0. Deferred: 9.
Unavailable: 0. Not-applicable: 0.

The remaining nine identifiers cannot become `implemented` without public
lookalikes for Intents-owned `INImage` / `INParameter` / `INInteraction`,
UIKit-owned `UIImage`, CoreGraphics `CGImage`, or Foundation-owned
`NSExtensionContext`. Those rows stay deferred and fail-closed.

focus-ios (pinned ladder corpus) exercises the add/edit voice-shortcut
controllers and all six delegate methods from
`Blockzilla/Siri/SiriShortcuts.swift`,
`Blockzilla/Siri/SiriFavoriteViewController.swift`, and
`Blockzilla/Settings/Controller/SettingsViewController.swift`. It does not
reference `INUIAddVoiceShortcutButton`. That button remains implemented
because `reference/corpus-summary.json` also names firefox-ios, Signal-iOS,
and pocket-casts-ios sample paths. pocket-casts-ios
`PodcastsIntentsUI/IntentViewController.swift` is the hosted-view family;
`configure*` stays deferred.

This pass split non-enum coverage onto per-identifier tests, made
`INUIVoiceShortcutError` `Equatable`/`Hashable`, proved weak delegates,
empty-phrase fail-closed (no table mutation), second-delete `shortcutNotFound`,
and cancel-does-not-uninstall. Isolated Linux still subclasses `NSObject`
because UIKit is not a declared seed dependency.

Top-5 evidence distribution (implemented rows citing each test):

1. `testAddVoiceShortcutButtonStyleRawValues` — 11 (enum family; members and synthesized `!=` / `hashValue` / `hash(into:)` / `init(rawValue:)` share one table-driven test)
2. `testInteractiveBehaviorRawValues` — 9 (enum family)
3. `testHostedViewContextRawValues` — 7 (enum family)
4. `testAddVoiceShortcutButtonClass` — 1
5. `testAddVoiceShortcutButtonInitStyle` — 1

Every other implemented row cites its own focused `test*` function. Each of
the 28 remaining implemented rows cites a distinct test (max share 1/28 =
3.6%, under the 40% bulk-relabel ceiling).
