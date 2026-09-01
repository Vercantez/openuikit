# UserNotificationsUI

Linux starting point for Apple's public `UserNotificationsUI` module (iPhoneOS
26.1 / Xcode 26.1 seed). It rebuilds the 29 exact public identifiers from
`reference/public-surface.tsv` as a loadable `libUserNotificationsUI.dylib`.
It is not wired into the shared guest package.

## What is real

- `UNNotificationContentExtensionMediaPlayPauseButtonType` and
  `UNNotificationContentExtensionResponseOption` are `UInt` enumerations with
  Apple `NS_ENUM` raw values (`none`/`doNotDismiss` = 0). The sealed agent
  runtime exercises `Hashable`, `Equatable`, `init?(rawValue:)`, `hashValue`,
  `hash(into:)`, and `!=`.
- When UIKit and UserNotifications are importable, `UNNotificationContentExtension`
  is an `NSObjectProtocol` whose Apple-optional members are **protocol
  requirements** with defaults. Existential (`any UNNotificationContentExtension`)
  dispatch uses the conformer's witness. Isolated unit-fixture execution proves
  that dispatch; it does not prove platform UIKit identity.
- This module does not declare `NSExtensionContext`, `UIColor`, or
  `UNNotification`. Notification APIs are an extension of
  `Foundation.NSExtensionContext` when that nominal exists.

## Fail-closed boundaries

Linux has no Apple notification content-extension host, SpringBoard banner,
or notification media session. `UserNotificationsUIHost` reports those
capabilities as `false`. `didReceive(_ response:)` defaults to `.doNotDismiss`.
Dismiss / default-action / media APIs only record sidecar flags.

## Standalone, unit-fixture, real integration

The sealed host gate compiles this module alone. UIKit and UserNotifications
are not on that import path, so the protocol and `NSExtensionContext`
extension are compiled out. The sealed runtime prints
`USERNOTIFICATIONSUI_STANDALONE_ONLY`.

Isolated unit-fixture mode (`tests/agent/run_unit_fixture.sh`) compiles a
lookalike `NSExtensionContext` and a test-owned module named UIKit only so
`#if canImport(UIKit)` can build the protocol. It compiles the repository
`UserNotifications` sources, runs existential dispatch, and prints
`USERNOTIFICATIONSUI_UNIT_FIXTURE_OK`. That is not platform identity and does
not substantiate `Foundation.NSExtensionContext` or `UIKit.UIColor` coverage.

Real integration (`tests/agent/run_real_integration.sh`) must consume platform
Foundation, UIKit, and UserNotifications modules/dylibs, compile
`let _: Foundation.NSExtensionContext = context`, pass `UIKit.UIColor` and
`UserNotifications.UNNotification` through the protocol, and emit
`USERNOTIFICATIONSUI_REAL_INTEGRATION_OK`. Platform Foundation currently lacks
`NSExtensionContext`; the probe reports
`USERNOTIFICATIONSUI_REAL_INTEGRATION_BLOCKED missing=Foundation.NSExtensionContext`
and does not emit the success marker.

## Deferred / oracle

See `oracle-questions.tsv`. The five `NSExtensionContext` rows are deferred on
the Foundation nominal blocker. `mediaPlayPauseButtonTintColor` is declared
until a platform UIKit.UIColor integration run exists.
