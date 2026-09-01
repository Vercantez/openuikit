# EventKitUI Linux starting point

This directory is a clean-room Linux starting point for Apple's public
`EventKitUI` module. It is not Apple Calendar, it is not a claim of sheet
parity, and it is not wired into the shared guest package. Central review still
owns EventKit integration, ABI, and any later sysroot packaging.

## What is real

The public EventKitUI enums, view-controller types, and delegate protocols from
the pinned Xcode 26.1 graph compile and are exercised by
`tests/agent/EventKitUIRuntime.swift`:

- `EKCalendarChooserDisplayStyle`, `EKCalendarChooserSelectionStyle`,
  `EKEventEditViewAction` (including the `cancelled` spelling alias), and
  `EKEventViewAction`, including synthesized `Hashable` / `RawRepresentable`
  members.
- `EKCalendarChooser` stores selection/display style, entity type, the event
  store identity, Done/Cancel button flags, and an in-memory
  `selectedCalendars` set. Hosts call `finish()` / `cancel()`.
- `EKEventViewController` stores the event and the editing/preview flags.
  Hosts call `finish()` to emit `.done`.
- `EKEventEditViewController.cancelEditing()` emits `.canceled` and does not
  write a store.
- `EKUI_IS_IOS` and `EKUI_IS_SIMULATOR` are `0` on this Linux host.
- `EventKitUIBundle()` is `nil` because Linux has no EventKitUI.framework
  bundle and `Bundle(for:)` is unsafe in this Foundation overlay.

The isolated fan-out compiler has Foundation only. `EventKitCompatibility.swift`
therefore supplies in-memory `EKEventStore`, `EKCalendar`, `EKEvent`, and
`EKEntityType` so EventKitUI signatures type-check. When a real `EventKit`
module is on the search path, that file becomes `@_exported import EventKit`.
Controllers subclass `NSObject` in this isolated Foundation-only compile.
`UIViewController` / `UINavigationController` subclassing waits for UIKit
linkage.

## Fail-closed boundaries

- No Calendar privacy prompt, entitlement, or EventKit authorization call.
- No read of the host calendar database and no write/save/delete through Apple
  Calendar. `saveEditing()`, `deleteEditing()`, `deleteEvent()`, and
  `respondToInvitation()` throw `EKUIError`.
- `.saved`, `.deleted` (edit and view), and `.responded` are never sent to
  delegates. Only `.canceled` / `.done` are emitted, and only from explicit
  host/cancel paths.
- Single-selection and writable-only filtering of `selectedCalendars` are a
  Linux policy (keep the lexicographically first identifier; drop calendars
  with `allowsContentModifications == false`). Apple's exact coercion is still
  an oracle question.
- `init(coder:)` is unavailable. There is no storyboard EventKitUI sheet.
- Combine, DeveloperToolsSupport, and SwiftUI are declared seed dependencies
  but have no identifiers in this 61-symbol public surface, so they are not
  imported.

## Deferred / integration

- Real `UIViewController` presentation, navigation-stack edit UI, and Calendar
  preview chrome wait for UIKit linkage.
- Replacing the EventKit placeholders with the EventKit fan-out module.
- Apple's localized EventKitUI resource bundle and exact `EventKitUIBundle()`
  identity.
- Objective-C optional delegate dispatch vs this Swift overlay, where
  `eventEditViewControllerDefaultCalendar(forNewEvents:)` is a protocol
  requirement.
