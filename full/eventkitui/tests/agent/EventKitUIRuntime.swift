@_spi(OpenUIKitHost) import EventKitUI
import Foundation

private final class ChooserProbe: NSObject, EKCalendarChooserDelegate {
    var didChange = 0
    var didFinish = 0
    var didCancel = 0

    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        didChange += 1
        _ = calendarChooser
    }

    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        didFinish += 1
        _ = calendarChooser
    }

    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        didCancel += 1
        _ = calendarChooser
    }
}

private final class EditProbe: NSObject, EKEventEditViewDelegate {
    var actions: [EKEventEditViewAction] = []
    let defaultCalendar: EKCalendar

    init(defaultCalendar: EKCalendar) {
        self.defaultCalendar = defaultCalendar
    }

    func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    ) {
        _ = controller
        actions.append(action)
    }

    func eventEditViewControllerDefaultCalendar(
        forNewEvents controller: EKEventEditViewController
    ) -> EKCalendar {
        _ = controller
        return defaultCalendar
    }
}

private final class ViewProbe: NSObject, EKEventViewDelegate {
    var actions: [EKEventViewAction] = []

    func eventViewController(
        _ controller: EKEventViewController,
        didCompleteWith action: EKEventViewAction
    ) {
        _ = controller
        actions.append(action)
    }
}

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("EVENTKITUI_AGENT_RUNTIME_FAIL: \(message)\n", stderr)
        exit(1)
    }
}

await MainActor.run {
    require(EKUI_IS_IOS == 0, "EKUI_IS_IOS must be 0 on Linux")
    require(EKUI_IS_SIMULATOR == 0, "EKUI_IS_SIMULATOR must be 0 on Linux")

    let bundle = EventKitUIBundle()
    require(bundle == nil, "EventKitUIBundle() must be nil without EventKitUI.framework")

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

    let store = EKEventStore()
    let writable = EKCalendar(for: .event, eventStore: store)
    writable.title = "Writable"
    let alsoWritable = EKCalendar(forEntityType: .event, eventStore: store)
    alsoWritable.title = "Also"
    let readOnly = EKCalendar(for: .event, eventStore: store)
    readOnly.title = "ReadOnly"
    readOnly.setAllowsContentModifications(false)

    let chooserProbe = ChooserProbe()
    let chooser = EKCalendarChooser(
        selectionStyle: .single,
        displayStyle: .writableCalendarsOnly,
        entityType: .event,
        eventStore: store
    )
    require(chooser.selectionStyle == .single, "chooser selectionStyle")
    require(chooser.displayStyle == .writableCalendarsOnly, "chooser displayStyle")
    require(chooser.entityType == .event, "chooser entityType")
    require(chooser.eventStore === store, "chooser eventStore")
    require(EKCalendarChooser.presentationCapability == .hostDriven, "chooser capability")
    chooser.delegate = chooserProbe
    chooser.showsDoneButton = true
    chooser.showsCancelButton = true
    require(chooser.showsDoneButton && chooser.showsCancelButton, "chooser button flags")

    chooser.selectedCalendars = [writable, alsoWritable, readOnly]
    require(chooser.selectedCalendars.count == 1, "single selection coerced")
    require(!chooser.selectedCalendars.contains(readOnly), "writable-only dropped read-only")
    require(chooserProbe.didChange == 1, "selection change notified")

    chooser.finish()
    chooser.cancel()
    require(chooserProbe.didFinish == 1, "chooser finish")
    require(chooserProbe.didCancel == 1, "chooser cancel")

    let multi = EKCalendarChooser(
        selectionStyle: .multiple,
        displayStyle: .allCalendars,
        eventStore: store
    )
    require(multi.entityType == .event, "short init defaults to event entity")
    multi.selectedCalendars = [writable, alsoWritable, readOnly]
    require(multi.selectedCalendars.count == 3, "multiple selection keeps all")

    let event = EKEvent(eventStore: store)
    event.title = "Review"
    event.startDate = Date(timeIntervalSince1970: 1_000)
    event.endDate = Date(timeIntervalSince1970: 1_800)
    event.calendar = writable

    let viewProbe = ViewProbe()
    let viewer = EKEventViewController()
    viewer.delegate = viewProbe
    viewer.event = event
    viewer.allowsEditing = true
    viewer.allowsCalendarPreview = true
    require(viewer.event.eventIdentifier == event.eventIdentifier, "viewer event")
    require(viewer.allowsEditing && viewer.allowsCalendarPreview, "viewer flags")
    require(EKEventViewController.presentationCapability == .hostDriven, "viewer capability")
    viewer.finish()
    require(viewProbe.actions == [.done], "viewer finish emits done")

    do {
        try viewer.respondToInvitation()
        require(false, "respondToInvitation must fail closed")
    } catch let error as EKUIError {
        require(error.code == .invitationResponseUnavailable, "respond error code")
    } catch {
        require(false, "respond must throw EKUIError")
    }
    do {
        try viewer.deleteEvent()
        require(false, "deleteEvent must fail closed")
    } catch let error as EKUIError {
        require(error.code == .eventDeletionUnavailable, "delete event error code")
    } catch {
        require(false, "deleteEvent must throw EKUIError")
    }

    let editProbe = EditProbe(defaultCalendar: writable)
    let editor = EKEventEditViewController()
    editor.editViewDelegate = editProbe
    editor.eventStore = store
    editor.event = event
    require(editor.eventStore === store, "editor eventStore")
    require(editor.event?.eventIdentifier == event.eventIdentifier, "editor event")
    require(EKEventEditViewController.presentationCapability == .hostDriven, "editor capability")
    require(
        editor.defaultCalendarForNewEvents()?.calendarIdentifier == writable.calendarIdentifier,
        "delegate default calendar"
    )
    editor.cancelEditing()
    require(editProbe.actions == [.canceled], "cancelEditing emits canceled")
    require(editProbe.actions.first == .cancelled, "cancelled spelling matches canceled")

    do {
        try editor.saveEditing()
        require(false, "saveEditing must fail closed")
    } catch let error as EKUIError {
        require(error.code == .calendarUIUnavailable, "save error code")
    } catch {
        require(false, "saveEditing must throw EKUIError")
    }
    do {
        try editor.deleteEditing()
        require(false, "deleteEditing must fail closed")
    } catch let error as EKUIError {
        require(error.code == .eventDeletionUnavailable, "delete editing error code")
    } catch {
        require(false, "deleteEditing must throw EKUIError")
    }

    print("EVENTKITUI_AGENT_RUNTIME_OK")
}
