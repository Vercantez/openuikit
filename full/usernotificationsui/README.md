# UserNotificationsUI (Linux)

Leaf-full starting implementation of Apple's public `UserNotificationsUI`
surface for Linux. The module is `UserNotificationsUI`; the host gate produces
`libUserNotificationsUI.dylib`.

This promotion could not fetch `github.com/Vercantez/openuikit-linux-platform`
(`git fetch` / `gh` → 404). The lane was reconstructed from the sealed monorepo
seed, the wave-1 repair notes for platform PR #6, and pinned `dotnet/macios`
`Native` enum case order. It is not a byte-copy of the 549 Swift lines on
`cursor/port-usernotificationsui-to-linux-4b9e`.

## What is real

- `UNNotificationContentExtensionMediaPlayPauseButtonType` and
  `UNNotificationContentExtensionResponseOption` as `UInt` enums (`none`/`default`/`overlay`
  = 0/1/2; `doNotDismiss`/`dismiss`/`dismissAndForwardAction` = 0/1/2).
- Synthesized `Hashable` / `Equatable` / `init?(rawValue:)`.
- `UNNotificationContentExtension` as a real protocol. Optional-style members
  are protocol requirements with defaults so existential dispatch reaches a
  conformer's override (the PR #6 protocol-dispatch bug).
- Fail-closed defaults: response handling returns `.doNotDismiss`; media
  play/pause are no-ops; button type is `.none`; frame is `.zero`.

## Fail-closed / not invented

- No notification content-extension host, SpringBoard, banner, or containing-app
  launch.
- No successful Apple media playback.
- `UIColor`, `UNNotification`, and `UNNotificationResponse` are
  `UIKit` / `UserNotifications` types when those modules can be imported.
  The sealed host gate cannot import them, so `UserNotificationsUIHostShims.swift`
  provides `#if !canImport` stand-ins. Those stand-ins are not UIKit or
  UserNotifications ABI.

## Deferred

Five `NSExtensionContext` category members are **deferred**. Linux Foundation
has no `NSExtensionContext`. This module does not introduce a second
`UserNotificationsUI.NSExtensionContext` identity (the PR #6 repair blocker
shared with NotificationCenter). When a canonical `Foundation.NSExtensionContext`
exists, the `#if os(iOS) || …` extension in `UserNotificationsUI.swift` can be
compiled against it.

## Coverage

24 of 29 public IDs are `implemented` (lane floor 24). 5 are `deferred`.
See `coverage.tsv`.
