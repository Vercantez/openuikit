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
  phrase contains a non-whitespace character. `delete` removes by UUID or
  reports `shortcutNotFound`. `cancel` only notifies the delegate.
- `INUIHostedViewSiriProviding` defaults `displaysMap`, `displaysMessage`, and
  `displaysPaymentTransaction` to `false`.
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
