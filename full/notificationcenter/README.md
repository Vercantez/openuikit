# NotificationCenter (Linux starting point)

This directory is an isolated clean-room port of Apple's public
`NotificationCenter` module from the Xcode 26.1 iPhoneOS SDK seed. The sealed
standalone gate produces `libNotificationCenter.dylib` against toolchain
Foundation only. The platform identity gate stages Foundation and UIKit first
and rebuilds the same sources with no fallback path.

The public seed contains 28 precise identifiers. Today View extensions were
deprecated in iOS 14 in favor of WidgetKit; the types remain because the
20-app corpus still lists Telegram, Wikipedia, and DuckDuckGo files that
import this module.

## What is real

- `NCUpdateResult` (`UInt`: `newData` 0, `noData` 1, `failed` 2) and
  `NCWidgetDisplayMode` (`Int`: `compact` 0, `expanded` 1), including
  synthesized `Equatable` / `Hashable` and failable `init(rawValue:)`.
- `NCWidgetProviding` as an `NSObjectProtocol` with Swift defaults. The default
  update completes with `.noData`. The async overlay resumes the
  completion-handler form.
- `NCWidgetController.setHasContent(_:forWidgetWithBundleIdentifier:)` records
  process-local flags. A host can read them through SPI.
- With staged UIKit/Foundation: `widgetMarginInsets` uses
  `UIKit.UIEdgeInsets`; `UIVibrancyEffect` factories return
  `UIKit.UIVibrancyEffect`; widget geometry is an extension of
  `Foundation.NSExtensionContext`.

## Fail-closed boundaries

Linux has no SpringBoard, Today View extension host, or Notification Center
visual-effect compositor.

- `NCWidgetController.systemWidgetHostAvailable` is `false`.
- Default `widgetPerformUpdate` does not report `.newData`.
- `widgetMaximumSize(for:)` is `CGSize.zero` until a host injects sizes.
- Vibrancy factories return inert UIKit instances; they do not apply Apple
  blur or vibrancy.

This module does not declare `UIEdgeInsets`, `UIVibrancyEffect`, or
`NSExtensionContext`. Those identities belong to UIKit and Foundation so
UserNotificationsUI can extend the same `NSExtensionContext`.

The sealed `tests/acceptance/test_host.sh` dylib is standalone-only: UIKit is
not importable, so the Foundation/UIKit extensions are compiled out. That
dylib is not a platform-compatible UIKit/Foundation product. The platform
gate in `tests/agent/test_platform_identities.sh` stages Foundation+UIKit,
builds with those modules visible, and proves no NotificationCenter-owned
fallback nominals are emitted.

## Still deferred / for the Apple oracle

See `oracle-questions.tsv`. Open questions include compact/expanded metrics,
`+widgetController` identity, entitlement failure mode, default-margin
constants, `UIVibrancyEffectStyle` raw values, and whether the three corpus
apps still call this deprecated surface.
