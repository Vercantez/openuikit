// EventKitUI dependency-identity client for a future clean EC2 run.
//
// Isolated `tests/acceptance/test_host.sh` compiles this module with Foundation
// only and must not be treated as integrated Linux success.
//
// Expected EC2 recipe (no local Docker):
//   1. Build real Combine, DeveloperToolsSupport, EventKit, Foundation,
//      SwiftUI, and UIKit modules/dylibs.
//   2. Build EventKitUI against those -I/-L paths:
//        swiftc -parse-as-library -emit-library -emit-module \
//          -module-name EventKitUI \
//          -I "$EVENTKIT_MOD" -I "$UIKIT_MOD" \
//          full/eventkitui/EventKitUI.swift -o libEventKitUI.dylib
//   3. Link this client importing Combine, DeveloperToolsSupport, EventKit,
//      Foundation, SwiftUI, UIKit, and EventKitUI, passing real EKEventStore,
//      EKCalendar, and EKEvent values through every enabled API.
//   4. Run with LD_LIBRARY_PATH including libEventKitUI.dylib and confirm that
//      dylib is loaded (for example /proc/self/maps) and that NEEDED/symbol
//      inspection names EventKit and UIKit rather than EventKitUI-local fakes.
//   5. Confirm the exact marker EVENTKITUI_DEPENDENCY_IDENTITY_OK.

import Combine
import DeveloperToolsSupport
import EventKit
@_spi(OpenUIKitHost) import EventKitUI
import Foundation
import SwiftUI
import UIKit

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

@MainActor
private final class IdentityChooserFull: NSObject, EKCalendarChooserDelegate {
    var finishes = 0
    var cancels = 0
    var changes = 0

    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        _ = calendarChooser
        changes += 1
    }

    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        finishes += 1
        calendarChooser.finish()
    }

    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        cancels += 1
        calendarChooser.cancel()
    }
}

@MainActor
private final class IdentityChooserMinimal: NSObject, EKCalendarChooserDelegate {}

@MainActor
private final class IdentityViewFull: NSObject, EKEventViewDelegate {
    var actions: [EKEventViewAction] = []

    func eventViewController(
        _ controller: EKEventViewController,
        didCompleteWith action: EKEventViewAction
    ) {
        actions.append(action)
        controller.finish()
    }
}

@MainActor
private final class IdentityEditFull: NSObject, EKEventEditViewDelegate {
    var actions: [EKEventEditViewAction] = []

    func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    ) {
        actions.append(action)
        controller.cancelEditing()
    }
}

@MainActor
private final class IdentityEditMinimal: NSObject, EKEventEditViewDelegate {
    var actions: [EKEventEditViewAction] = []

    func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    ) {
        _ = controller
        actions.append(action)
    }
}

enum EventKitUIDependencyIdentity {
    static func requireLoadedEventKitUIImage() {
        #if os(Linux)
        let maps: String
        if let handle = FileHandle(forReadingAtPath: "/proc/self/maps"),
           let data = try? handle.readToEnd()
        {
            maps = String(decoding: data, as: UTF8.self)
        } else {
            maps = ""
        }
        precondition(
            maps.contains("libEventKitUI"),
            "libEventKitUI.dylib/so must be mapped; isolated host is not integrated proof"
        )
        #endif
    }

    static func requireDependencySymbols() {
        #if os(Linux)
        let handle = dlopen("libEventKitUI.dylib", RTLD_NOW)
        precondition(handle != nil, "libEventKitUI.dylib must be loadable")
        #endif
        let eventKitName = String(reflecting: EKEventStore.self)
        precondition(!eventKitName.hasPrefix("EventKitUI."), "EKEventStore must not be module-local")
        precondition(eventKitName.contains("EKEventStore"), "EKEventStore identity")
        let calendarName = String(reflecting: EKCalendar.self)
        precondition(!calendarName.hasPrefix("EventKitUI."), "EKCalendar must not be module-local")
        let eventName = String(reflecting: EKEvent.self)
        precondition(!eventName.hasPrefix("EventKitUI."), "EKEvent must not be module-local")
        let entityName = String(reflecting: EKEntityType.self)
        precondition(!entityName.hasPrefix("EventKitUI."), "EKEntityType must not be module-local")
        let viewName = String(reflecting: UIViewController.self)
        precondition(!viewName.hasPrefix("EventKitUI."), "UIViewController must not be module-local")
        let navigationName = String(reflecting: UINavigationController.self)
        precondition(
            !navigationName.hasPrefix("EventKitUI."),
            "UINavigationController must not be module-local"
        )
        let chooserName = String(reflecting: EKCalendarChooser.self)
        precondition(chooserName.hasPrefix("EventKitUI."), "EKCalendarChooser lives in EventKitUI")
        let viewerName = String(reflecting: EKEventViewController.self)
        precondition(viewerName.hasPrefix("EventKitUI."), "EKEventViewController lives in EventKitUI")
        let editorName = String(reflecting: EKEventEditViewController.self)
        precondition(
            editorName.hasPrefix("EventKitUI."),
            "EKEventEditViewController lives in EventKitUI"
        )
    }

    @MainActor
    static func runControllers() {
        _ = Combine.Just(false)
        _ = SwiftUI.EmptyView()
        _ = String(reflecting: DeveloperToolsSupport.Preview.self)

        let store = EKEventStore()
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "Identity"
        let event = EKEvent(eventStore: store)
        event.title = "Identity Event"
        event.calendar = calendar
        event.startDate = Date(timeIntervalSince1970: 1_700_000_000)
        event.endDate = Date(timeIntervalSince1970: 1_700_003_600)

        let chooser = EKCalendarChooser(
            selectionStyle: .multiple,
            displayStyle: .allCalendars,
            entityType: .event,
            eventStore: store
        )
        precondition(chooser is UIKit.UIViewController)
        precondition(EKCalendarChooser.self is UIKit.UIViewController.Type)
        precondition(!(chooser is UIKit.UINavigationController))
        precondition(chooser.eventStore === store)
        let chooserFull = IdentityChooserFull()
        chooser.delegate = chooserFull
        chooser.selectedCalendars = [calendar]
        precondition(chooser.selectedCalendars.contains(calendar))
        precondition(chooserFull.changes == 0)

        let short = EKCalendarChooser(
            selectionStyle: .single,
            displayStyle: .writableCalendarsOnly,
            eventStore: store
        )
        precondition(short is UIKit.UIViewController)
        precondition(short.entityType == .event)

        let chooserExistential: any EKCalendarChooserDelegate = chooserFull
        chooser.delegate = chooserExistential
        chooser.finish()
        chooser.finish()
        precondition(chooserFull.finishes == 1)
        chooser.cancel()
        chooser.cancel()
        precondition(chooserFull.cancels == 1)

        let omitted = EKCalendarChooser(
            selectionStyle: .single,
            displayStyle: .allCalendars,
            eventStore: store
        )
        let omittedExistential: any EKCalendarChooserDelegate = IdentityChooserMinimal()
        omitted.delegate = omittedExistential
        omitted.finish()
        omitted.cancel()

        do {
            let holder = EKCalendarChooser(
                selectionStyle: .single,
                displayStyle: .allCalendars,
                eventStore: store
            )
            weak var deadDelegate: IdentityChooserFull?
            do {
                let probe = IdentityChooserFull()
                holder.delegate = probe
                deadDelegate = probe
                precondition(holder.delegate != nil)
            }
            precondition(deadDelegate == nil)
            precondition(holder.delegate == nil)
            _ = holder
        }

        weak var deadChooser: EKCalendarChooser?
        do {
            let transient = EKCalendarChooser(
                selectionStyle: .single,
                displayStyle: .allCalendars,
                eventStore: store
            )
            deadChooser = transient
            precondition(deadChooser != nil)
        }
        precondition(deadChooser == nil)

        let viewer = EKEventViewController()
        precondition(viewer is UIKit.UIViewController)
        precondition(EKEventViewController.self is UIKit.UIViewController.Type)
        viewer.event = event
        viewer.allowsEditing = true
        viewer.allowsCalendarPreview = true
        precondition(viewer.event === event)

        let viewFull = IdentityViewFull()
        let viewExistential: any EKEventViewDelegate = viewFull
        viewer.delegate = viewExistential
        viewer.finish()
        viewer.finish()
        precondition(viewFull.actions == [.done])

        do {
            let holder = EKEventViewController()
            weak var deadDelegate: IdentityViewFull?
            do {
                let probe = IdentityViewFull()
                holder.delegate = probe
                deadDelegate = probe
                precondition(holder.delegate != nil)
            }
            precondition(deadDelegate == nil)
            precondition(holder.delegate == nil)
            _ = holder
        }

        weak var deadViewer: EKEventViewController?
        do {
            let transient = EKEventViewController()
            deadViewer = transient
            precondition(deadViewer != nil)
        }
        precondition(deadViewer == nil)

        let editor = EKEventEditViewController()
        precondition(editor is UIKit.UINavigationController)
        precondition(EKEventEditViewController.self is UIKit.UINavigationController.Type)
        precondition(editor is UIKit.UIViewController)
        editor.eventStore = store
        editor.event = event
        precondition(editor.eventStore === store)
        precondition(editor.event === event)

        let editFull = IdentityEditFull()
        let editExistential: any EKEventEditViewDelegate = editFull
        editor.editViewDelegate = editExistential
        editor.cancelEditing()
        editor.cancelEditing()
        precondition(editFull.actions == [.canceled])
        precondition(editFull.actions.first == .cancelled)
        precondition(!editFull.actions.contains(.saved))
        precondition(!editFull.actions.contains(.deleted))

        let minimalEditor = EKEventEditViewController()
        let editMinimal = IdentityEditMinimal()
        let omittedCalendar: any EKEventEditViewDelegate = editMinimal
        minimalEditor.editViewDelegate = omittedCalendar
        minimalEditor.eventStore = store
        minimalEditor.cancelEditing()
        precondition(editMinimal.actions == [.canceled])

        do {
            let holder = EKEventEditViewController()
            weak var deadDelegate: IdentityEditFull?
            do {
                let probe = IdentityEditFull()
                holder.editViewDelegate = probe
                deadDelegate = probe
                precondition(holder.editViewDelegate != nil)
            }
            precondition(deadDelegate == nil)
            precondition(holder.editViewDelegate == nil)
        }

        weak var deadEditor: EKEventEditViewController?
        do {
            let transient = EKEventEditViewController()
            deadEditor = transient
            precondition(deadEditor != nil)
        }
        precondition(deadEditor == nil)

        precondition(!EventKitUIHost.calendarSheetAvailable)
        precondition(!EventKitUIHost.eventStoreWriteAvailable)
        precondition(
            EventKitUIHostError(.calendarUIUnavailable).code == .calendarUIUnavailable
        )
    }

    static func main() async {
        requireLoadedEventKitUIImage()
        requireDependencySymbols()
        await MainActor.run {
            runControllers()
        }
        print("EVENTKITUI_DEPENDENCY_IDENTITY_OK")
    }
}

await EventKitUIDependencyIdentity.main()
