# NotificationCenter (Linux starting point)

This directory is an isolated clean-room port of Apple's public
`NotificationCenter` module from the Xcode 26.1 iPhoneOS SDK seed. It produces
`NotificationCenter.swiftmodule` and `libNotificationCenter.dylib` for a
Foundation-only Linux toolchain. It is not wired into the shared guest package;
that integration is a later central-review step.

The public seed contains 28 precise identifiers. This tranche implements all of
them as a source-compatible Linux surface. Today View extensions were
deprecated in iOS 14 in favor of WidgetKit; the types remain because the
20-app corpus still lists Telegram, Wikipedia, and DuckDuckGo files that
import this module.

## What is real

- `NCUpdateResult` (`UInt`: `newData` 0, `noData` 1, `failed` 2) and
  `NCWidgetDisplayMode` (`Int`: `compact` 0, `expanded` 1), including
  synthesized `Equatable` / `Hashable` and failable `init(rawValue:)`.
- `NCWidgetProviding` as an `NSObjectProtocol` with Swift defaults for the
  Objective-C optional methods. The default update completes with `.noData`.
  The async `widgetPerformUpdate()` overlay resumes the completion-handler
  form (the raw graph's conflicting duplicate of the same precise ID).
- `NCWidgetController.setHasContent(_:forWidgetWithBundleIdentifier:)` records
  process-local flags. A host can read them through SPI.
- `NSExtensionContext` widget properties: largest available mode is get/set
  (default compact), active mode is get-only (default compact), and
  `widgetMaximumSize(for:)` returns `CGSize.zero` until a host injects sizes.
- `UIVibrancyEffect` factories return distinguishable inert placeholders.

## Fail-closed boundaries

Linux has no SpringBoard, Today View extension host, or Notification Center
visual-effect compositor.

- `NCWidgetController.systemWidgetHostAvailable` is `false`. Setting a content
  flag never claims that the system hid or showed a widget. Entitlement-gated
  XPC (`NCWidgetControllerHasContentEntitlement`) is not simulated.
- Widget maximum sizes are not invented (no 110pt compact height).
- Vibrancy factories do not apply Apple blur or vibrancy.
- Default `widgetPerformUpdate` does not report `.newData`.

On this Foundation-only host, `NSExtensionContext`, `UIVibrancyEffect`,
`UIVibrancyEffectStyle`, and `UIEdgeInsets` are NotificationCenter-owned
stand-ins so the isolated gate can compile. When UIKit is present, the
vibrancy factories become extensions of UIKit's type.

## Still deferred / for the Apple oracle

See `oracle-questions.tsv`. Open questions include compact/expanded metrics,
`+widgetController` identity, entitlement failure mode, default-margin
constants, `UIVibrancyEffectStyle` raw values, and whether the three corpus
apps still call this deprecated surface.

Private TBD symbols (`NCWidgetMetrics`, extension-item user-info keys,
`_NCIsValidWidgetDisplayMode`, and friends) are not part of the public Swift
graph and are not declared here.
