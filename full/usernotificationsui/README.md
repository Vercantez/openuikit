# UserNotificationsUI

Linux starting point for Apple's public `UserNotificationsUI` module (iPhoneOS
26.1 / Xcode 26.1 seed). It rebuilds the 29 exact public identifiers from
`reference/public-surface.tsv` as a loadable `libUserNotificationsUI.dylib`.
It is not wired into the shared guest package.

## What is real

- `UNNotificationContentExtensionMediaPlayPauseButtonType` and
  `UNNotificationContentExtensionResponseOption` are `UInt` enumerations with
  Apple `NS_ENUM` raw values (`none`/`doNotDismiss` = 0). `Hashable`,
  `Equatable`, `init?(rawValue:)`, `hashValue`, `hash(into:)`, and `!=` are
  exercised by the sealed agent runtime.
- When UIKit and UserNotifications are importable, `UNNotificationContentExtension`
  is an `NSObjectProtocol` whose Apple-optional members are **protocol
  requirements** with defaults. Existential (`any UNNotificationContentExtension`)
  dispatch uses the conformer's witness, not the default.
- `NSExtensionContext` notification APIs are an extension of the staged
  Foundation identity. This module does not declare `NSExtensionContext`,
  `UIColor`, or `UNNotification`.

## Fail-closed boundaries

Linux has no Apple notification content-extension host, SpringBoard banner,
or notification media session. `UserNotificationsUIHost` reports those
capabilities as `false`.

- `didReceive(_ response:)` defaults to `.doNotDismiss`.
- `dismissNotificationContentExtension()` and
  `performNotificationDefaultAction()` set sidecar flags only.
- `mediaPlayingStarted()` / `mediaPlayingPaused()` toggle a sidecar flag only.
- Optional `mediaPlay()` / `mediaPause()` defaults are no-ops.
- Private TBD symbols are not part of this module.

## Standalone vs staged

The sealed host gate compiles this module alone. UIKit and UserNotifications
are not on that import path, so the protocol and `NSExtensionContext`
extension are compiled out. The sealed runtime exercises enumerations only
and prints `USERNOTIFICATIONSUI_STANDALONE_ONLY`. That result does not
substantiate integration-compatible coverage for UIKit/UserNotifications
identities.

EC2 staging (`tests/agent/stage_real_modules_and_probe.sh`) builds UIKit,
UserNotifications, and a Foundation `NSExtensionContext` overlay first, then
compiles UserNotificationsUI with **no fallback branch**. An identity
consumer imports all four modules; an existential-dispatch probe would fail
if overrides were statically dispatched. The emitted interface/symbol graph
must not contain `UserNotificationsUI.UIColor`,
`UserNotificationsUI.UNNotification`, or
`UserNotificationsUI.NSExtensionContext`.

## Deferred / oracle

See `oracle-questions.tsv` for Apple-runtime questions (async vs
completion-handler bridging, unimplemented tint color, host-side dismiss and
default-action behavior, and `notificationActions` delivery).
