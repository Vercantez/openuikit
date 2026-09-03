# NotificationCenter (Linux starting point)

This directory is an isolated clean-room port of Apple's public
`NotificationCenter` module from the Xcode 26.1 iPhoneOS SDK seed. The sealed
standalone gate produces `libNotificationCenter.dylib` against toolchain
Foundation only. Integration-labelled probes consume actual staged guest
Foundation and UIKit module/dylib outputs from this repository. They do not
manufacture a module named Foundation.

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
  process-local flags. A host can read them through `@_spi(OpenUIKitHost)`.
- File-scoped `#if canImport(UIKit)` selects UIKit for `widgetMarginInsets` and
  the `UIVibrancyEffect` factories. Those signatures are compile-only until a
  real guest UIKit dylib exercises them.
- `NSExtensionContext` widget geometry is an extension of
  `Foundation.NSExtensionContext`, compiled only when a real staged Foundation
  module exposes that type and the integration probe passes
  `-D NOTIFICATIONCENTER_HAS_FOUNDATION_EXTENSION_CONTEXT`.

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

## Gates and markers

The sealed `tests/acceptance/test_host.sh` dylib is standalone-only: UIKit is
not importable, so the Foundation/UIKit extensions are compiled out. Expected
standalone markers include:

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
NOTIFICATIONCENTER_AGENT_RUNTIME_OK
NOTIFICATIONCENTER_STANDALONE_DYLIB_ONLY
FRAMEWORK_FANOUT_HOST_OK module=NotificationCenter dylib=libNotificationCenter.dylib
```

`tests/agent/test_platform_identities.sh` is the integration-labelled probe. It
requires real `Foundation.swiftmodule` / `libFoundation.dylib` and
`UIKit.swiftmodule` / `libUIKit.dylib`, typechecks
`Foundation.NSExtensionContext`, compiles a client that accepts
`UIKit.UIEdgeInsets` / `UIKit.UIVibrancyEffect` and assigns
`Foundation.NSExtensionContext`, inspects NotificationCenter for the absence of
NotificationCenter-owned nominals, and links `libNotificationCenter.dylib`.
If `Foundation.NSExtensionContext` is unavailable it prints
`NOTIFICATIONCENTER_PLATFORM_BLOCKED dependency=Foundation.NSExtensionContext`
and `NOTIFICATIONCENTER_PLATFORM_IDENTITY_NOT_CLAIMED` and does not emit
`NOTIFICATIONCENTER_PLATFORM_STAGE_OK` or `NOTIFICATIONCENTER_IDENTITY_PROBE_OK`.

A synthetic unit fixture exists only behind `NOTIFICATIONCENTER_UNIT_FIXTURE=1`
in `tests/agent/test_unit_fixture.sh`. That path prints
`NOTIFICATIONCENTER_UNIT_FIXTURE_STANDALONE_ONLY` and
`NOTIFICATIONCENTER_UNIT_FIXTURE_NOT_PLATFORM_IDENTITY_EVIDENCE`. It is not
coverage evidence.

## Coverage honesty

Twenty identifiers are `implemented` from the standalone runtime (enums,
controller, protocol core, `widgetPerformUpdate`,
`widgetActiveDisplayModeDidChange`, synthesized Equatable/Hashable/rawValue).
Four `UIVibrancyEffect` factories and `widgetMarginInsets` are `declared`
compile-only UIKit surface. Three `NSExtensionContext` rows are `deferred`
because guest Foundation does not expose `Foundation.NSExtensionContext`.
Nondeferred count is 25 (lane floor 23). All 28 exact IDs remain.

## Still deferred / for the Apple oracle

See `oracle-questions.tsv`. Open questions include compact/expanded metrics,
`+widgetController` identity, entitlement failure mode, default-margin
constants, `UIVibrancyEffectStyle` raw values, whether corpus apps still call
this surface, and whether guest Foundation will expose `NSExtensionContext`.
