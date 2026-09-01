# EventKitUI (Linux starting point)

`EventKitUI.swift` produces `EventKitUI.swiftmodule` and `libEventKitUI.dylib`.

The isolated host gate compiles this module with Foundation only. Declarations
that require EventKit or UIKit are `#if canImport(EventKit) && canImport(UIKit)`
gated so this module never introduces lookalike `EKEventStore`, `EKCalendar`,
`EKEvent`, `EKEntityType`, `UIViewController`, or `UINavigationController`
types.

## What is real on the isolated host

- `EKCalendarChooserDisplayStyle`, `EKCalendarChooserSelectionStyle`,
  `EKEventEditViewAction` (including the `cancelled` spelling alias), and
  `EKEventViewAction`, including synthesized `Hashable` / `RawRepresentable`
  members. Raw values follow the public `NS_ENUM` order.
- `EKUI_IS_IOS` and `EKUI_IS_SIMULATOR` are `0` on Linux.
- `EventKitUIBundle()` is `nil` (no EventKitUI.framework bundle).
- `EventKitUIHost` SPI flags report that Apple Calendar sheets and EventKit
  writes are unavailable.

## What is real when EventKit and UIKit are linked

- `EKCalendarChooser` and `EKEventViewController` subclass
  `UIKit.UIViewController`.
- `EKEventEditViewController` subclasses `UIKit.UINavigationController`.
- Inits and properties take real `EventKit.EKEventStore`, `EKCalendar`,
  `EKEvent`, and `EKEntityType` values.
- Host Done/Cancel (`finish()`, `cancel()`, viewer `finish()`) is
  `@_spi(OpenUIKitHost)` and notifies at most once. `cancelEditing()` is the
  public Apple cancel path and also notifies `.canceled` at most once.
- Optional Objective-C delegate methods have empty Swift defaults except
  `eventEditViewControllerDefaultCalendar(forNewEvents:)`, whose default does
  not invent a calendar and is not invoked by the edit controller.

## Fail-closed

- No Calendar privacy prompt, EventKit authorization, or store write.
- Delegates are never sent `.saved`, `.deleted`, or `.responded`.
- `selectedCalendars` is stored as assigned. This overlay does not claim
  Apple's single-selection or writable-only filtering, or selection-change
  callback timing.
- `init(coder:)` is unavailable.

The isolated Foundation gate does **not** prove integrated EventKit/UIKit
success. `tests/agent/EventKitUIDependencyIdentity.swift` is the future EC2
client: it imports Combine, DeveloperToolsSupport, EventKit, Foundation,
SwiftUI, UIKit, and EventKitUI; passes real EventKit values through enabled
APIs; checks exact UIKit inheritance; exercises weak delegates, deallocation,
non-reentrant exactly-once callbacks, and omitted optionals; and loads
`libEventKitUI.dylib`.

## Oracle

See `oracle-questions.tsv`.
