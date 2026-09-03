@_spi(OpenUIKitHost) import EventKitUI
import Foundation

private func runOnMain<T>(_ body: @MainActor () -> T) -> T {
    if Thread.isMainThread {
        return MainActor.assumeIsolated(body)
    }
    return DispatchQueue.main.sync {
        MainActor.assumeIsolated(body)
    }
}

private func assertEnumSurface() {
    precondition(EKCalendarChooserDisplayStyle.allCalendars.rawValue == 0)
    precondition(EKCalendarChooserDisplayStyle.writableCalendarsOnly.rawValue == 1)
    precondition(EKCalendarChooserDisplayStyle(rawValue: 0) == .allCalendars)
    precondition(EKCalendarChooserDisplayStyle(rawValue: 1) == .writableCalendarsOnly)
    precondition(EKCalendarChooserDisplayStyle(rawValue: 2) == nil)
    precondition(EKCalendarChooserDisplayStyle.allCalendars != .writableCalendarsOnly)
    precondition(EKCalendarChooserDisplayStyle.allCalendars.hashValue == EKCalendarChooserDisplayStyle.allCalendars.hashValue)
    var displayHasher = Hasher()
    EKCalendarChooserDisplayStyle.allCalendars.hash(into: &displayHasher)
    var displayHasher2 = Hasher()
    EKCalendarChooserDisplayStyle.allCalendars.hash(into: &displayHasher2)
    precondition(displayHasher.finalize() == displayHasher2.finalize())

    precondition(EKCalendarChooserSelectionStyle.single.rawValue == 0)
    precondition(EKCalendarChooserSelectionStyle.multiple.rawValue == 1)
    precondition(EKCalendarChooserSelectionStyle(rawValue: 0) == .single)
    precondition(EKCalendarChooserSelectionStyle(rawValue: 1) == .multiple)
    precondition(EKCalendarChooserSelectionStyle(rawValue: -1) == nil)
    precondition(EKCalendarChooserSelectionStyle.single != .multiple)
    var selectionHasher = Hasher()
    EKCalendarChooserSelectionStyle.multiple.hash(into: &selectionHasher)
    _ = selectionHasher.finalize()
    precondition(EKCalendarChooserSelectionStyle.single.hashValue != EKCalendarChooserSelectionStyle.multiple.hashValue)

    precondition(EKEventEditViewAction.canceled.rawValue == 0)
    precondition(EKEventEditViewAction.saved.rawValue == 1)
    precondition(EKEventEditViewAction.deleted.rawValue == 2)
    precondition(EKEventEditViewAction.cancelled == .canceled)
    precondition(EKEventEditViewAction.cancelled.rawValue == EKEventEditViewAction.canceled.rawValue)
    precondition(EKEventEditViewAction(rawValue: 0) == .canceled)
    precondition(EKEventEditViewAction(rawValue: 1) == .saved)
    precondition(EKEventEditViewAction(rawValue: 2) == .deleted)
    precondition(EKEventEditViewAction(rawValue: 3) == nil)
    precondition(EKEventEditViewAction.canceled != .saved)
    precondition(EKEventEditViewAction.saved != .deleted)
    var editHasher = Hasher()
    EKEventEditViewAction.cancelled.hash(into: &editHasher)
    var editHasherCanceled = Hasher()
    EKEventEditViewAction.canceled.hash(into: &editHasherCanceled)
    precondition(editHasher.finalize() == editHasherCanceled.finalize())
    precondition(EKEventEditViewAction.canceled.hashValue == EKEventEditViewAction.cancelled.hashValue)

    precondition(EKEventViewAction.done.rawValue == 0)
    precondition(EKEventViewAction.responded.rawValue == 1)
    precondition(EKEventViewAction.deleted.rawValue == 2)
    precondition(EKEventViewAction(rawValue: 0) == .done)
    precondition(EKEventViewAction(rawValue: 1) == .responded)
    precondition(EKEventViewAction(rawValue: 2) == .deleted)
    precondition(EKEventViewAction(rawValue: 99) == nil)
    precondition(EKEventViewAction.done != .deleted)
    precondition(EKEventViewAction.responded != .done)
    var viewHasher = Hasher()
    EKEventViewAction.done.hash(into: &viewHasher)
    _ = viewHasher.finalize()
    precondition(EKEventViewAction.done.hashValue == EKEventViewAction.done.hashValue)
}

private func assertMacrosAndBundle() {
    precondition(EKUI_IS_IOS == 0)
    precondition(EKUI_IS_SIMULATOR == 0)
    let bundle: Bundle! = EventKitUIBundle()
    precondition(bundle == nil)
}

private func assertEventKitStandIns() {
    let store = EKEventStore()
    precondition(store.calendars.isEmpty)
    precondition(store.calendars(for: .event).isEmpty)
    precondition(store.calendars(for: .reminder).isEmpty)
    precondition(store.calendar(withIdentifier: "any") == nil)
    precondition(store.event(withIdentifier: "any") == nil)
    precondition(EKEntityType.event.rawValue == 0)
    precondition(EKEntityType.reminder.rawValue == 1)

    let event = EKEvent(eventStore: store)
    precondition(event.eventStore === store)
    precondition(event.title == nil)
    precondition(event.calendar == nil)
    precondition(event.isAllDay == false)
    precondition(event.isDetached == false)
    precondition(event.hasAlarms == false)
    precondition(event.hasRecurrenceRules == false)

    event.title = "Probe"
    event.startDate = Date(timeIntervalSince1970: 0)
    event.endDate = Date(timeIntervalSince1970: 3600)
    do {
        let saved = try store.save(event, span: .thisEvent, commit: true)
        precondition(saved == false)
    } catch {
        fatalError("isolation save must not throw an invented EventKit error: \(error)")
    }
    do {
        let removed = try store.remove(event, span: .futureEvents, commit: false)
        precondition(removed == false)
    } catch {
        fatalError("isolation remove must not throw an invented EventKit error: \(error)")
    }
}

private final class ChooserProbe: NSObject, EKCalendarChooserDelegate {
    var selectionCount = 0
    var finishCount = 0
    var cancelCount = 0
    weak var lastChooser: EKCalendarChooser?

    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        selectionCount += 1
        lastChooser = calendarChooser
    }

    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        finishCount += 1
        lastChooser = calendarChooser
    }

    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        cancelCount += 1
        lastChooser = calendarChooser
    }
}

private final class SilentChooserProbe: NSObject, EKCalendarChooserDelegate {}

@MainActor
private func assertChooser() {
    let store = EKEventStore()
    let threeArg = EKCalendarChooser(
        selectionStyle: .single,
        displayStyle: .allCalendars,
        eventStore: store
    )
    precondition(threeArg.selectionStyle == .single)
    precondition(threeArg.displayStyle == .allCalendars)
    precondition(threeArg.entityType == .event)
    precondition(threeArg.eventStore === store)
    precondition(threeArg.selectedCalendars.isEmpty)
    precondition(threeArg.showsDoneButton == false)
    precondition(threeArg.showsCancelButton == false)
    precondition(threeArg.delegate == nil)

    let fourArg = EKCalendarChooser(
        selectionStyle: .multiple,
        displayStyle: .writableCalendarsOnly,
        entityType: .reminder,
        eventStore: store
    )
    precondition(fourArg.selectionStyle == .multiple)
    precondition(fourArg.displayStyle == .writableCalendarsOnly)
    precondition(fourArg.entityType == .reminder)
    fourArg.showsDoneButton = true
    fourArg.showsCancelButton = true
    precondition(fourArg.showsDoneButton)
    precondition(fourArg.showsCancelButton)

    let writable = EKCalendar.hostCalendar(title: "Writable", identifier: "cal.writable", writable: true)
    let locked = EKCalendar.hostCalendar(title: "Locked", identifier: "cal.locked", writable: false)
    precondition(writable.allowsContentModifications)
    precondition(locked.isImmutable)

    let probe = ChooserProbe()
    threeArg.delegate = probe
    precondition(threeArg.delegate === probe)

    threeArg.hostSelectCalendars([writable])
    precondition(threeArg.selectedCalendars.count == 1)
    precondition(threeArg.selectedCalendars.contains(writable))
    precondition(probe.selectionCount == 1)
    precondition(probe.lastChooser === threeArg)

    threeArg.hostSelectCalendars([writable])
    precondition(probe.selectionCount == 1)

    threeArg.selectedCalendars = [writable, locked]
    precondition(threeArg.selectedCalendars.count == 2)
    precondition(threeArg.selectionStyle == .single)

    threeArg.hostFinish()
    threeArg.hostCancel()
    precondition(probe.finishCount == 1)
    precondition(probe.cancelCount == 1)

    let silent = SilentChooserProbe()
    fourArg.delegate = silent
    fourArg.hostSelectCalendars([locked])
    fourArg.hostFinish()
    fourArg.hostCancel()
    precondition(fourArg.selectedCalendars.contains(locked))
}

private final class EventViewProbe: NSObject, EKEventViewDelegate {
    var actions: [EKEventViewAction] = []
    weak var lastController: EKEventViewController?

    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
        actions.append(action)
        lastController = controller
    }
}

@MainActor
private func assertEventView() {
    let store = EKEventStore()
    let event = EKEvent(eventStore: store)
    event.title = "Viewed"
    let controller = EKEventViewController()
    precondition(controller.delegate == nil)
    precondition(controller.event == nil)
    precondition(controller.allowsEditing == false)
    precondition(controller.allowsCalendarPreview == false)

    let probe = EventViewProbe()
    controller.delegate = probe
    controller.event = event
    controller.allowsEditing = true
    controller.allowsCalendarPreview = true
    precondition(controller.delegate === probe)
    precondition(controller.event === event)
    precondition(controller.allowsEditing)
    precondition(controller.allowsCalendarPreview)

    controller.hostComplete(with: .done)
    controller.hostComplete(with: .responded)
    controller.hostComplete(with: .deleted)
    precondition(probe.actions == [.done, .responded, .deleted])
    precondition(probe.lastController === controller)
    precondition(controller.event.title == "Viewed")
}

private final class EditProbe: NSObject, EKEventEditViewDelegate {
    var actions: [EKEventEditViewAction] = []
    let defaultCalendar: EKCalendar
    weak var lastController: EKEventEditViewController?

    init(defaultCalendar: EKCalendar) {
        self.defaultCalendar = defaultCalendar
    }

    func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    ) {
        actions.append(action)
        lastController = controller
    }

    func eventEditViewControllerDefaultCalendar(
        forNewEvents controller: EKEventEditViewController
    ) -> EKCalendar {
        _ = controller
        return defaultCalendar
    }
}

private final class EditProbeWithoutDefault: NSObject, EKEventEditViewDelegate {
    var actions: [EKEventEditViewAction] = []

    func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    ) {
        actions.append(action)
    }
}

@MainActor
private func assertEventEdit() {
    let store = EKEventStore()
    let calendar = EKCalendar.hostCalendar(title: "Work", identifier: "cal.work")
    let event = EKEvent(eventStore: store)
    event.calendar = calendar
    event.title = "Draft"

    let controller = EKEventEditViewController()
    precondition(controller.editViewDelegate == nil)
    precondition(controller.eventStore == nil)
    precondition(controller.event == nil)
    precondition(controller.hostEditingCancelled == false)

    let probe = EditProbe(defaultCalendar: calendar)
    controller.editViewDelegate = probe
    controller.eventStore = store
    controller.event = event
    precondition(controller.editViewDelegate === probe)
    precondition(controller.eventStore === store)
    precondition(controller.event === event)
    precondition(controller.hostDefaultCalendarForNewEvents() === calendar)

    controller.cancelEditing()
    precondition(controller.hostEditingCancelled)
    precondition(probe.actions == [.canceled])
    precondition(probe.lastController === controller)
    precondition(probe.actions.first == .cancelled)

    controller.hostComplete(with: .saved)
    controller.hostComplete(with: .deleted)
    controller.hostComplete(with: .cancelled)
    precondition(probe.actions == [.canceled, .saved, .deleted, .canceled])
    precondition((try? store.save(event, span: .thisEvent, commit: true)) == false)
    precondition(store.event(withIdentifier: "missing") == nil)

    let withoutDefault = EditProbeWithoutDefault()
    let second = EKEventEditViewController()
    second.editViewDelegate = withoutDefault
    let fallback = second.hostDefaultCalendarForNewEvents()
    precondition(fallback?.calendarIdentifier == "eventkitui.inert-default-calendar")
    precondition(fallback?.isImmutable == true)
    precondition(fallback?.allowsContentModifications == false)
    second.cancelEditing()
    precondition(withoutDefault.actions == [.canceled])
}

assertEnumSurface()
assertMacrosAndBundle()
assertEventKitStandIns()
runOnMain {
    assertChooser()
    assertEventView()
    assertEventEdit()
}

print("EVENTKITUI_AGENT_RUNTIME_OK")
