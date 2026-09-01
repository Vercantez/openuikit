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
  exercised by the agent runtime.
- `UNNotificationContentExtension` is an `NSObjectProtocol` with the required
  `@MainActor didReceive(_: UNNotification)` method. Objective-C optional
  members are protocol-extension defaults so ordinary Swift classes can
  conform while `@objc optional` is unavailable.
- `NSExtensionContext` stores `notificationActions` locally and records
  dismiss, default-action, and media play/pause requests for a Linux host.

## Fail-closed boundaries

Linux has no Apple notification content-extension host, SpringBoard banner,
or notification media session. `UserNotificationsUIHost` reports those
capabilities as `false`.

- `didReceive(_ response:)` defaults to `.doNotDismiss`. This port does not
  dismiss or forward a system notification action.
- `dismissNotificationContentExtension()` and
  `performNotificationDefaultAction()` set local flags only. They do not
  complete an extension request, remove a banner, or launch an app.
- `mediaPlayingStarted()` / `mediaPlayingPaused()` toggle a local flag only.
- Optional `mediaPlay()` / `mediaPause()` defaults are no-ops.
- Private TBD symbols (`_UNNotificationContentExtensionHost*`, logging
  hooks, `__UNNotificationExtensionActionsKey`) are not part of this module.

## Dependency stand-ins

The isolated host gate compiles this module alone. When `UIKit` or
`UserNotifications` cannot be imported, the module provides minimal
`UIColor`, `UNNotification`, `UNNotificationResponse`, and
`UNNotificationAction` stand-ins so the public signatures typecheck. They are
not Apple service objects. When those modules are later linked, the
`canImport` branches use the real types.

Foundation on this toolchain has no `NSExtensionContext`; UserNotificationsUI
owns that class until a later integration replaces it with an extension of
Foundation's type.

## Deferred / oracle

See `oracle-questions.tsv` for Apple-runtime questions (async vs
completion-handler bridging, unimplemented tint color, host-side dismiss and
default-action behavior, and `notificationActions` delivery).
