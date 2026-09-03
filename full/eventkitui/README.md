# EventKitUI (Linux starting point)

This directory is a fail-closed portable `EventKitUI` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph. It is not wired into the shared guest package;
that integration is a separate central review step.

The isolated host gate compiles this module alone. Apple `EventKit`, `UIKit`,
`SwiftUI`, `Combine`, and `DeveloperToolsSupport` are not on the link line.

## What is real

- `EKCalendarChooserDisplayStyle`, `EKCalendarChooserSelectionStyle`,
  `EKEventEditViewAction`, and `EKEventViewAction` are `Int` enums with
  NS_ENUM declaration-order raw values. `Hashable` / `Equatable` / `Sendable`
  and `init?(rawValue:)` are Swift-synthesized. `EKEventEditViewAction.cancelled`
  is the British-spelling alias of `.canceled`.
- `EKUI_IS_IOS` and `EKUI_IS_SIMULATOR` are `0` (this compile is neither
  iPhone OS nor the iOS Simulator).
- `EventKitUIBundle()` returns `nil`. There is no Apple EventKitUI framework
  bundle on Linux.
- `EKCalendarChooser`, `EKEventViewController`, and `EKEventEditViewController`
  store their public configuration, including the EventKit types they name.
  `cancelEditing()` notifies the edit delegate with `.canceled`.
- Host SPI (`@_spi(OpenUIKitHost)`) stands in for Done / Cancel / Complete
  gestures that Darwin would present as UI. Delegate callbacks are delivered
  on the calling `@MainActor` context, not on an invented queue.
- Optional Objective-C delegate methods are modeled with Swift default
  implementations (no `@objc` runtime).

## Fail-closed boundaries

- The three controllers do **not** inherit `UIViewController` /
  `UINavigationController`. UIKit is unavailable in this isolated compile.
  They inherit `NSObject`.
- `EventKitStandIns.swift` provides process-local `EKEventStore`, `EKEvent`,
  `EKCalendar`, and `EKEntityType` so the EventKitUI surface type-checks.
  Those types are **not** a Linux EventKit port. `EKEventStore` lists nothing
  and `save` / `remove` return `false` without inventing EventKit error codes.
- The chooser never populates `selectedCalendars` from the store. Display
  style `.writableCalendarsOnly` is stored and not applied to a calendar list
  that does not exist.
- `EKEventViewController.allowsCalendarPreview` defaults to `false` on Linux
  (no month view). Apple's documented Darwin default is an oracle question.
- `EKEventEditViewController.hostComplete(with: .saved)` does not write
  through `EKEventStore`.
- The optional `eventEditViewControllerDefaultCalendar(forNewEvents:)`
  default returns a shared inert immutable calendar
  (`eventkitui.inert-default-calendar`), not an EventKit default calendar.

## Tests

`tests/agent/EventKitUIRuntime.swift` is the host-gate probe and prints
`EVENTKITUI_AGENT_RUNTIME_OK`.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
