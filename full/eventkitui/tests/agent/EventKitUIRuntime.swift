@_spi(OpenUIKitHost) import EventKitUI
import Foundation

#if canImport(EventKit) && canImport(UIKit)
import EventKit
import UIKit
#endif

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("EVENTKITUI_AGENT_RUNTIME_FAIL: \(message)\n", stderr)
        exit(1)
    }
}

private func runFoundationSurface() {
    require(!EventKitUIHost.calendarSheetAvailable, "calendar sheet must be unavailable")
    require(!EventKitUIHost.eventStoreWriteAvailable, "event store writes must be unavailable")
    require(
        EventKitUIHostError(.calendarUIUnavailable).code == .calendarUIUnavailable,
        "host error calendar UI"
    )
    require(
        EventKitUIHostError(.invitationResponseUnavailable).code == .invitationResponseUnavailable,
        "host error invitation"
    )
    require(
        EventKitUIHostError(.eventDeletionUnavailable).code == .eventDeletionUnavailable,
        "host error deletion"
    )
    require(
        EventKitUIHostError(.calendarUIUnavailable)
            != EventKitUIHostError(.eventDeletionUnavailable),
        "host errors unequal"
    )

    require(EKUI_IS_IOS == 0, "EKUI_IS_IOS must be 0 on Linux")
    require(EKUI_IS_SIMULATOR == 0, "EKUI_IS_SIMULATOR must be 0 on Linux")
    require(EventKitUIBundle() == nil, "EventKitUIBundle() must be nil without EventKitUI.framework")

    require(EKCalendarChooserDisplayStyle.allCalendars.rawValue == 0, "display allCalendars raw value")
    require(EKCalendarChooserDisplayStyle.writableCalendarsOnly.rawValue == 1, "display writable raw value")
    require(EKCalendarChooserDisplayStyle(rawValue: 0) == .allCalendars, "display init(rawValue:)")
    require(EKCalendarChooserDisplayStyle(rawValue: 99) == nil, "display init(rawValue:) reject")
    require(EKCalendarChooserDisplayStyle.allCalendars != .writableCalendarsOnly, "display !=")
    require(
        EKCalendarChooserDisplayStyle.allCalendars.hashValue
            == EKCalendarChooserDisplayStyle.allCalendars.hashValue,
        "display hashValue"
    )
    var displayHasher = Hasher()
    EKCalendarChooserDisplayStyle.writableCalendarsOnly.hash(into: &displayHasher)
    _ = displayHasher.finalize()

    require(EKCalendarChooserSelectionStyle.single.rawValue == 0, "selection single raw value")
    require(EKCalendarChooserSelectionStyle.multiple.rawValue == 1, "selection multiple raw value")
    require(EKCalendarChooserSelectionStyle(rawValue: 1) == .multiple, "selection init(rawValue:)")
    require(EKCalendarChooserSelectionStyle.single != .multiple, "selection !=")
    require(
        EKCalendarChooserSelectionStyle.single.hashValue
            == EKCalendarChooserSelectionStyle.single.hashValue,
        "selection hashValue"
    )
    var selectionHasher = Hasher()
    EKCalendarChooserSelectionStyle.multiple.hash(into: &selectionHasher)
    _ = selectionHasher.finalize()

    require(EKEventEditViewAction.canceled.rawValue == 0, "edit canceled raw value")
    require(EKEventEditViewAction.saved.rawValue == 1, "edit saved raw value")
    require(EKEventEditViewAction.deleted.rawValue == 2, "edit deleted raw value")
    require(EKEventEditViewAction.cancelled == .canceled, "cancelled alias")
    require(EKEventEditViewAction.cancelled != .saved, "cancelled !=")
    require(EKEventEditViewAction(rawValue: 2) == .deleted, "edit init(rawValue:)")
    require(
        EKEventEditViewAction.canceled.hashValue == EKEventEditViewAction.cancelled.hashValue,
        "edit hashValue"
    )
    var editHasher = Hasher()
    EKEventEditViewAction.saved.hash(into: &editHasher)
    _ = editHasher.finalize()

    require(EKEventViewAction.done.rawValue == 0, "view done raw value")
    require(EKEventViewAction.responded.rawValue == 1, "view responded raw value")
    require(EKEventViewAction.deleted.rawValue == 2, "view deleted raw value")
    require(EKEventViewAction(rawValue: 0) == .done, "view init(rawValue:)")
    require(EKEventViewAction.done != .deleted, "view !=")
    require(EKEventViewAction.done.hashValue == EKEventViewAction.done.hashValue, "view hashValue")
    var viewHasher = Hasher()
    EKEventViewAction.responded.hash(into: &viewHasher)
    _ = viewHasher.finalize()
}

#if canImport(EventKit) && canImport(UIKit)

@MainActor
private final class ChooserProbe: NSObject, EKCalendarChooserDelegate {
    var didFinish = 0
    var didCancel = 0
    var didChange = 0

    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        _ = calendarChooser
        didChange += 1
    }

    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        didFinish += 1
        calendarChooser.finish()
    }

    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        didCancel += 1
        calendarChooser.cancel()
    }
}

@MainActor
private final class MinimalChooserProbe: NSObject, EKCalendarChooserDelegate {}

@MainActor
private final class EditProbe: NSObject, EKEventEditViewDelegate {
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
private final class MinimalEditProbe: NSObject, EKEventEditViewDelegate {
    var actions: [EKEventEditViewAction] = []

    func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    ) {
        _ = controller
        actions.append(action)
    }
}

@MainActor
private final class ViewProbe: NSObject, EKEventViewDelegate {
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
private func runEventKitUIKitSurface() {
    let store = EKEventStore()
    let calendar = EKCalendar(for: .event, eventStore: store)
    calendar.title = "Work"
    let event = EKEvent(eventStore: store)
    event.title = "Review"
    event.calendar = calendar

    require(
        !String(reflecting: type(of: store)).hasPrefix("EventKitUI."),
        "EKEventStore must come from EventKit"
    )
    require(
        !String(reflecting: type(of: calendar)).hasPrefix("EventKitUI."),
        "EKCalendar must come from EventKit"
    )
    require(
        !String(reflecting: type(of: event)).hasPrefix("EventKitUI."),
        "EKEvent must come from EventKit"
    )

    let chooser = EKCalendarChooser(
        selectionStyle: .single,
        displayStyle: .allCalendars,
        entityType: .event,
        eventStore: store
    )
    require(chooser is UIKit.UIViewController, "EKCalendarChooser must inherit UIKit.UIViewController")
    require(
        EKCalendarChooser.self is UIKit.UIViewController.Type,
        "EKCalendarChooser metatype must be UIKit.UIViewController.Type"
    )
    require(!(chooser is UIKit.UINavigationController), "chooser is not a navigation controller")
    require(chooser.selectionStyle == .single, "chooser selectionStyle")
    require(chooser.eventStore === store, "chooser retains EventKit store")
    require(chooser.entityType == .event, "chooser entityType")
    chooser.showsDoneButton = true
    chooser.showsCancelButton = true
    let chooserProbe = ChooserProbe()
    chooser.delegate = chooserProbe
    chooser.selectedCalendars = [calendar]
    require(chooser.selectedCalendars.contains(calendar), "selectedCalendars stores EventKit calendars")
    require(
        chooserProbe.didChange == 0,
        "selectedCalendars setter does not claim selectionDidChange timing"
    )

    let short = EKCalendarChooser(
        selectionStyle: .multiple,
        displayStyle: .writableCalendarsOnly,
        eventStore: store
    )
    require(short.entityType == .event, "short init uses event entity type")
    require(short is UIKit.UIViewController, "short chooser inherits UIViewController")

    let chooserExistential: any EKCalendarChooserDelegate = chooserProbe
    chooser.delegate = chooserExistential
    chooser.finish()
    chooser.finish()
    require(chooserProbe.didFinish == 1, "chooser finish is exactly once and non-reentrant")
    chooser.cancel()
    chooser.cancel()
    require(chooserProbe.didCancel == 1, "chooser cancel is exactly once and non-reentrant")

    let minimalChooser = EKCalendarChooser(
        selectionStyle: .single,
        displayStyle: .allCalendars,
        eventStore: store
    )
    let omittedOptionals: any EKCalendarChooserDelegate = MinimalChooserProbe()
    minimalChooser.delegate = omittedOptionals
    minimalChooser.finish()
    minimalChooser.cancel()

    weak var weakChooserDelegate: ChooserProbe? = chooserProbe
    chooser.delegate = nil
    require(weakChooserDelegate != nil, "probe still held by test")
    chooser.delegate = chooserProbe
    require(chooser.delegate != nil, "weak delegate is set")

    weak var deadChooser: EKCalendarChooser?
    do {
        let transient = EKCalendarChooser(
            selectionStyle: .single,
            displayStyle: .allCalendars,
            eventStore: store
        )
        deadChooser = transient
        require(deadChooser != nil, "transient chooser is alive inside scope")
    }
    require(deadChooser == nil, "chooser deallocated when unretained")

    do {
        let holder = EKCalendarChooser(
            selectionStyle: .single,
            displayStyle: .allCalendars,
            eventStore: store
        )
        weak var deadDelegate: ChooserProbe?
        do {
            let probe = ChooserProbe()
            holder.delegate = probe
            deadDelegate = probe
            require(holder.delegate != nil, "holder has delegate")
        }
        require(deadDelegate == nil, "chooser delegate deallocates when unretained")
        require(holder.delegate == nil, "weak delegate is nil after probe release")
        _ = holder
    }

    let viewer = EKEventViewController()
    require(viewer is UIKit.UIViewController, "EKEventViewController must inherit UIKit.UIViewController")
    require(
        EKEventViewController.self is UIKit.UIViewController.Type,
        "EKEventViewController metatype must be UIKit.UIViewController.Type"
    )
    viewer.event = event
    viewer.allowsEditing = true
    viewer.allowsCalendarPreview = false
    require(viewer.event === event, "viewer holds EventKit event")
    let viewProbe = ViewProbe()
    let viewExistential: any EKEventViewDelegate = viewProbe
    viewer.delegate = viewExistential
    viewer.finish()
    viewer.finish()
    require(viewProbe.actions == [.done], "viewer finish is exactly once and non-reentrant")

    weak var deadViewer: EKEventViewController?
    do {
        let transient = EKEventViewController()
        deadViewer = transient
        require(deadViewer != nil, "transient viewer is alive inside scope")
    }
    require(deadViewer == nil, "viewer deallocated when unretained")

    do {
        let holder = EKEventViewController()
        weak var deadDelegate: ViewProbe?
        do {
            let probe = ViewProbe()
            holder.delegate = probe
            deadDelegate = probe
            require(holder.delegate != nil, "viewer holder has delegate")
        }
        require(deadDelegate == nil, "viewer delegate deallocates when unretained")
        require(holder.delegate == nil, "viewer weak delegate is nil after probe release")
        _ = holder
    }

    let editor = EKEventEditViewController()
    require(
        editor is UIKit.UINavigationController,
        "EKEventEditViewController must inherit UIKit.UINavigationController"
    )
    require(
        EKEventEditViewController.self is UIKit.UINavigationController.Type,
        "EKEventEditViewController metatype must be UIKit.UINavigationController.Type"
    )
    require(editor is UIKit.UIViewController, "navigation controller is a view controller")
    editor.eventStore = store
    editor.event = event
    require(editor.eventStore === store, "editor holds EventKit store")
    require(editor.event === event, "editor holds EventKit event")

    let editProbe = EditProbe()
    let editExistential: any EKEventEditViewDelegate = editProbe
    editor.editViewDelegate = editExistential
    editor.cancelEditing()
    editor.cancelEditing()
    require(editProbe.actions == [.canceled], "cancelEditing is exactly once and non-reentrant")
    require(editProbe.actions.first == .cancelled, "cancelled spelling matches canceled")
    require(!editProbe.actions.contains(.saved), "cancel path must not claim save")
    require(!editProbe.actions.contains(.deleted), "cancel path must not claim delete")

    let minimalEditor = EKEventEditViewController()
    let minimalEdit = MinimalEditProbe()
    let omittedDefaultCalendar: any EKEventEditViewDelegate = minimalEdit
    minimalEditor.editViewDelegate = omittedDefaultCalendar
    minimalEditor.eventStore = store
    minimalEditor.cancelEditing()
    require(
        minimalEdit.actions == [.canceled],
        "optional default-calendar method may be omitted"
    )

    weak var weakEditDelegate: EditProbe? = editProbe
    editor.editViewDelegate = nil
    require(weakEditDelegate != nil, "edit probe still held by test")
    editor.editViewDelegate = editProbe
    require(editor.editViewDelegate != nil, "weak edit delegate is set")

    weak var deadEditor: EKEventEditViewController?
    do {
        let transient = EKEventEditViewController()
        deadEditor = transient
        require(deadEditor != nil, "transient editor is alive inside scope")
    }
    require(deadEditor == nil, "editor deallocated when unretained")

    do {
        let holder = EKEventEditViewController()
        weak var deadDelegate: EditProbe?
        do {
            let probe = EditProbe()
            holder.editViewDelegate = probe
            deadDelegate = probe
            require(holder.editViewDelegate != nil, "editor holder has delegate")
        }
        require(deadDelegate == nil, "editor delegate deallocates when unretained")
        require(holder.editViewDelegate == nil, "editor weak delegate is nil after probe release")
        _ = holder
    }
}

#endif

runFoundationSurface()
#if canImport(EventKit) && canImport(UIKit)
await MainActor.run {
    runEventKitUIKitSurface()
}
#endif
print("EVENTKITUI_AGENT_RUNTIME_OK")
