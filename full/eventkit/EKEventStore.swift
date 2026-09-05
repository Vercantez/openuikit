import Foundation

extension Notification.Name {
    /// Posted after a successful `commit` of the local on-disk store.
    public static let EKEventStoreChanged = Notification.Name("EKEventStoreChangedNotification")
}

/// Opaque fetch token. EventKit's header returns `id`; cancel maps onto this object.
final class EKReminderFetchRequest: NSObject, @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false

    func cancel() {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }
}

enum EKStorePredicateKind {
    case events(start: Date, end: Date, calendarIDs: Set<String>?, restrict: Bool)
    case reminders(calendarIDs: Set<String>?, restrict: Bool)
    case incompleteReminders(start: Date?, end: Date?, calendarIDs: Set<String>?, restrict: Bool)
    case completedReminders(start: Date?, end: Date?, calendarIDs: Set<String>?, restrict: Bool)
}

final class EKStorePredicate: NSPredicate {
    let kind: EKStorePredicateKind
    private let body: (Any?) -> Bool

    init(kind: EKStorePredicateKind, body: @escaping (Any?) -> Bool) {
        self.kind = kind
        self.body = body
        #if os(Linux)
        super.init(value: true)
        #else
        super.init()
        #endif
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func evaluate(with object: Any?) -> Bool {
        body(object)
    }

    override func evaluate(with object: Any?, substitutionVariables substitutions: [String: Any]?) -> Bool {
        _ = substitutions
        return body(object)
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        EKStorePredicate(kind: kind, body: body)
    }
}

/// Process-local EventKit store backed by Application Support `/OpenUIKit/EventKit`.
///
/// Authorization starts `.notDetermined`. `requestFullAccessToEvents` /
/// `requestFullAccessToReminders` / `requestAccess(to:)` grant this process-local
/// sandbox (`.fullAccess`); `requestWriteOnlyAccessToEvents` grants `.writeOnly`.
/// `EKEventStore.denyAccessRequests` makes those same APIs persist `.denied`.
/// This is not TCC and not Calendar.app.
open class EKEventStore: NSObject {
    public private(set) var eventStoreIdentifier: String
    public private(set) var sources: [EKSource]
    public var delegateSources: [EKSource] { sources.filter(\.isDelegate) }
    public var defaultCalendarForNewEvents: EKCalendar? {
        calendars(for: .event).first { $0.calendarIdentifier == EKLocalStoreIO.eventCalendarIdentifier }
            ?? calendars(for: .event).first
    }

    private var hostedSources: [EKSource]?
    private var liveSources: [String: EKSource] = [:]
    private var liveCalendars: [String: EKCalendar] = [:]

    public override init() {
        eventStoreIdentifier = UUID().uuidString
        sources = []
        super.init()
        reloadFromDisk(creatingIfNeeded: true)
    }

    public init(sources: [EKSource]) {
        eventStoreIdentifier = UUID().uuidString
        self.hostedSources = sources
        self.sources = sources
        super.init()
        for source in sources {
            source.bind(to: self)
            liveSources[source.sourceIdentifier] = source
        }
        reloadFromDisk(creatingIfNeeded: true)
        if let hostedSources {
            self.sources = hostedSources
        }
    }

    @_spi(OpenUIKitHost)
    public static func useIsolatedStoreDirectory(_ url: URL) {
        EKLocalStoreRoot.useIsolatedDirectory(url)
    }

    @_spi(OpenUIKitHost)
    public static func resetIsolatedStore() {
        EKLocalStoreRoot.resetCache()
    }

    @_spi(OpenUIKitHost)
    public static var denyAccessRequests: Bool {
        get {
            EKLocalStoreRoot.lock.lock()
            defer { EKLocalStoreRoot.lock.unlock() }
            return EKLocalStoreRoot.denyAccess
        }
        set {
            EKLocalStoreRoot.lock.lock()
            EKLocalStoreRoot.denyAccess = newValue
            EKLocalStoreRoot.lock.unlock()
        }
    }

    open class func authorizationStatus(for entityType: EKEntityType) -> EKAuthorizationStatus {
        EKLocalStoreRoot.lock.lock()
        defer { EKLocalStoreRoot.lock.unlock() }
        let snapshot = EKLocalStoreIO.loadLocked()
        switch entityType {
        case .event: return snapshot.eventAuthorization
        case .reminder: return snapshot.reminderAuthorization
        }
    }

    /// Swift overlay of `requestAccessToEntityType:completion:`. Denied access
    /// returns `false` without throwing (`granted == NO`, `error == nil`).
    open func requestAccess(to entityType: EKEntityType) async throws -> Bool {
        await withCheckedContinuation { continuation in
            EKCallbackDelivery.asynchronously {
                continuation.resume(returning: self.grantAccess(to: entityType, status: .fullAccess))
            }
        }
    }

    open func requestFullAccessToEvents(
        completion: @escaping EKEventStoreRequestAccessCompletionHandler
    ) {
        let granted = grantAccess(to: .event, status: .fullAccess)
        EKCallbackDelivery.asynchronously {
            completion(granted, nil)
        }
    }

    open func requestFullAccessToReminders(
        completion: @escaping EKEventStoreRequestAccessCompletionHandler
    ) {
        let granted = grantAccess(to: .reminder, status: .fullAccess)
        EKCallbackDelivery.asynchronously {
            completion(granted, nil)
        }
    }

    open func requestWriteOnlyAccessToEvents(
        completion: @escaping EKEventStoreRequestAccessCompletionHandler
    ) {
        let granted = grantAccess(to: .event, status: .writeOnly)
        EKCallbackDelivery.asynchronously {
            completion(granted, nil)
        }
    }

    open func defaultCalendarForNewReminders() -> EKCalendar? {
        calendars(for: .reminder).first { $0.calendarIdentifier == EKLocalStoreIO.reminderCalendarIdentifier }
            ?? calendars(for: .reminder).first
    }

    open func calendars(for entityType: EKEntityType) -> [EKCalendar] {
        guard canSeeCalendars(for: entityType) else { return [] }
        return Array(liveCalendars.values.filter { calendar in
            switch entityType {
            case .event: return calendar.allowedEntityTypes.contains(.event)
            case .reminder: return calendar.allowedEntityTypes.contains(.reminder)
            }
        }).sorted { $0.calendarIdentifier < $1.calendarIdentifier }
    }

    open func calendar(withIdentifier identifier: String) -> EKCalendar? {
        liveCalendars[identifier]
    }

    open func source(withIdentifier identifier: String) -> EKSource? {
        sources.first { $0.sourceIdentifier == identifier }
    }

    open func calendarItem(withIdentifier identifier: String) -> EKCalendarItem? {
        EKLocalStoreRoot.lock.lock()
        let snapshot = EKLocalStoreIO.loadLocked()
        EKLocalStoreRoot.lock.unlock()
        if canRead(.event) {
            if let record = snapshot.events.first(where: {
                $0.calendarItemIdentifier == identifier || $0.eventIdentifier == identifier
            }) {
                return materializeEvent(record)
            }
        }
        if canRead(.reminder) {
            if let record = snapshot.reminders.first(where: {
                $0.calendarItemIdentifier == identifier
                    || $0.calendarItemExternalIdentifier == identifier
            }) {
                return materializeReminder(record)
            }
        }
        return nil
    }

    open func calendarItems(withExternalIdentifier externalIdentifier: String) -> [EKCalendarItem] {
        var items: [EKCalendarItem] = []
        EKLocalStoreRoot.lock.lock()
        let snapshot = EKLocalStoreIO.loadLocked()
        EKLocalStoreRoot.lock.unlock()
        if canRead(.event) {
            for record in snapshot.events where record.calendarItemExternalIdentifier == externalIdentifier {
                items.append(materializeEvent(record))
            }
        }
        if canRead(.reminder) {
            for record in snapshot.reminders where record.calendarItemExternalIdentifier == externalIdentifier {
                items.append(materializeReminder(record))
            }
        }
        return items
    }

    open func event(withIdentifier identifier: String) -> EKEvent? {
        guard canRead(.event) else { return nil }
        EKLocalStoreRoot.lock.lock()
        let snapshot = EKLocalStoreIO.loadLocked()
        EKLocalStoreRoot.lock.unlock()
        if let record = snapshot.events.first(where: { $0.eventIdentifier == identifier }) {
            return materializeEvent(record)
        }
        return nil
    }

    open func events(matching predicate: NSPredicate) -> [EKEvent] {
        guard canRead(.event) else { return [] }
        EKLocalStoreRoot.lock.lock()
        let snapshot = EKLocalStoreIO.loadLocked()
        EKLocalStoreRoot.lock.unlock()
        var results: [EKEvent] = []
        if let storePredicate = predicate as? EKStorePredicate,
           case let .events(start, end, _, _) = storePredicate.kind
        {
            let masters = snapshot.events.filter { !$0.isDetached }
            let orphans = snapshot.events.filter { record in
                record.isDetached && !snapshot.events.contains {
                    !$0.isDetached && $0.calendarItemExternalIdentifier == record.calendarItemExternalIdentifier
                }
            }
            for record in masters + orphans {
                results.append(contentsOf: expandedEvents(record, rangeStart: start, rangeEnd: end, snapshot: snapshot))
            }
            return results.filter { predicate.evaluate(with: $0) }
                .sorted { $0.compareStartDate(with: $1) == .orderedAscending }
        }
        for record in snapshot.events {
            let event = materializeEvent(record)
            if predicate.evaluate(with: event) {
                results.append(event)
            }
        }
        return results.sorted { $0.compareStartDate(with: $1) == .orderedAscending }
    }

    open func enumerateEvents(
        matching predicate: NSPredicate,
        using block: @escaping EKEventSearchCallback
    ) {
        var stop = ObjCBool(false)
        for event in events(matching: predicate) {
            block(event, &stop)
            if stop.boolValue { break }
        }
    }

    open func fetchReminders(
        matching predicate: NSPredicate,
        completion: @escaping ([EKReminder]?) -> Void
    ) -> Any {
        let request = EKReminderFetchRequest()
        let allowed = canRead(.reminder)
        EKLocalStoreRoot.lock.lock()
        let snapshot = EKLocalStoreIO.loadLocked()
        EKLocalStoreRoot.lock.unlock()
        let reminders: [EKReminder]?
        if allowed {
            reminders = snapshot.reminders.map { materializeReminder($0) }.filter {
                predicate.evaluate(with: $0)
            }
        } else {
            reminders = nil
        }
        EKCallbackDelivery.asynchronously {
            if request.isCancelled {
                completion(nil)
            } else {
                completion(reminders)
            }
        }
        return request
    }

    open func cancelFetchRequest(_ fetchIdentifier: Any) {
        (fetchIdentifier as? EKReminderFetchRequest)?.cancel()
    }

    open func predicateForEvents(
        withStart startDate: Date,
        end endDate: Date,
        calendars: [EKCalendar]?
    ) -> NSPredicate {
        let calendarFilter = Self.calendarFilter(calendars)
        return EKStorePredicate(
            kind: .events(
                start: startDate,
                end: endDate,
                calendarIDs: calendarFilter.restrict ? calendarFilter.identifiers : nil,
                restrict: calendarFilter.restrict
            )
        ) { object in
            guard let event = object as? EKEvent else { return false }
            guard let eventStart = event.startDate, let eventEnd = event.endDate else {
                return false
            }
            if eventEnd <= startDate || eventStart >= endDate {
                return false
            }
            return calendarFilter.matches(event.calendar)
        }
    }

    open func predicateForReminders(in calendars: [EKCalendar]?) -> NSPredicate {
        let calendarFilter = Self.calendarFilter(calendars)
        return EKStorePredicate(
            kind: .reminders(
                calendarIDs: calendarFilter.restrict ? calendarFilter.identifiers : nil,
                restrict: calendarFilter.restrict
            )
        ) { object in
            guard let reminder = object as? EKReminder else { return false }
            return calendarFilter.matches(reminder.calendar)
        }
    }

    open func predicateForIncompleteReminders(
        withDueDateStarting startDate: Date?,
        ending endDate: Date?,
        calendars: [EKCalendar]?
    ) -> NSPredicate {
        let calendarFilter = Self.calendarFilter(calendars)
        return EKStorePredicate(
            kind: .incompleteReminders(
                start: startDate,
                end: endDate,
                calendarIDs: calendarFilter.restrict ? calendarFilter.identifiers : nil,
                restrict: calendarFilter.restrict
            )
        ) { object in
            guard let reminder = object as? EKReminder, !reminder.isCompleted else {
                return false
            }
            if !Self.dueDate(reminder.dueDateComponents, starts: startDate, ends: endDate) {
                return false
            }
            return calendarFilter.matches(reminder.calendar)
        }
    }

    open func predicateForCompletedReminders(
        withCompletionDateStarting startDate: Date?,
        ending endDate: Date?,
        calendars: [EKCalendar]?
    ) -> NSPredicate {
        let calendarFilter = Self.calendarFilter(calendars)
        return EKStorePredicate(
            kind: .completedReminders(
                start: startDate,
                end: endDate,
                calendarIDs: calendarFilter.restrict ? calendarFilter.identifiers : nil,
                restrict: calendarFilter.restrict
            )
        ) { object in
            guard let reminder = object as? EKReminder, reminder.isCompleted else {
                return false
            }
            if let completion = reminder.completionDate {
                if let startDate, completion < startDate { return false }
                if let endDate, completion > endDate { return false }
            } else if startDate != nil || endDate != nil {
                return false
            }
            return calendarFilter.matches(reminder.calendar)
        }
    }

    open func saveCalendar(_ calendar: EKCalendar, commit: Bool) throws {
        try requireWrite(for: entityTypes(of: calendar))
        if calendar.source == nil {
            throw EKMakeError(.calendarHasNoSource)
        }
        if calendar.isImmutable {
            throw EKMakeError(.calendarIsImmutable)
        }
        if !calendar.allowsContentModifications {
            throw EKMakeError(.calendarReadOnly)
        }
        EKLocalStoreRoot.lock.lock()
        defer { EKLocalStoreRoot.lock.unlock() }
        var snapshot = EKLocalStoreIO.loadLocked()
        upsert(&snapshot.calendars, calendar.persistRecord()) { $0.identifier == calendar.calendarIdentifier }
        liveCalendars[calendar.calendarIdentifier] = calendar
        calendar.markSaved()
        try finishMutation(snapshot, commit: commit)
    }

    open func removeCalendar(_ calendar: EKCalendar, commit: Bool) throws {
        try requireWrite(for: entityTypes(of: calendar))
        if calendar.isImmutable {
            throw EKMakeError(.calendarIsImmutable)
        }
        EKLocalStoreRoot.lock.lock()
        defer { EKLocalStoreRoot.lock.unlock() }
        var snapshot = EKLocalStoreIO.loadLocked()
        snapshot.calendars.removeAll { $0.identifier == calendar.calendarIdentifier }
        snapshot.events.removeAll { $0.calendarIdentifier == calendar.calendarIdentifier }
        snapshot.reminders.removeAll { $0.calendarIdentifier == calendar.calendarIdentifier }
        liveCalendars.removeValue(forKey: calendar.calendarIdentifier)
        try finishMutation(snapshot, commit: commit)
    }

    open func save(_ event: EKEvent, span: EKSpan) throws {
        try save(event, span: span, commit: true)
    }

    open func save(_ event: EKEvent, span: EKSpan, commit: Bool) throws {
        try validateEvent(event)
        EKLocalStoreRoot.lock.lock()
        defer { EKLocalStoreRoot.lock.unlock() }
        var snapshot = EKLocalStoreIO.loadLocked()
        try applyEventSave(event, span: span, snapshot: &snapshot)
        event.stampModification()
        event.markSaved()
        try finishMutation(snapshot, commit: commit)
    }

    open func remove(_ event: EKEvent, span: EKSpan) throws {
        try remove(event, span: span, commit: true)
    }

    open func remove(_ event: EKEvent, span: EKSpan, commit: Bool) throws {
        try requireWrite(for: .event)
        guard event.owningStore == nil || event.owningStore === self else {
            throw EKMakeError(.objectBelongsToDifferentStore)
        }
        EKLocalStoreRoot.lock.lock()
        defer { EKLocalStoreRoot.lock.unlock() }
        var snapshot = EKLocalStoreIO.loadLocked()
        try applyEventRemove(event, span: span, snapshot: &snapshot)
        try finishMutation(snapshot, commit: commit)
    }

    open func save(_ reminder: EKReminder, commit: Bool) throws {
        try requireWrite(for: .reminder)
        guard reminder.owningStore == nil || reminder.owningStore === self else {
            throw EKMakeError(.objectBelongsToDifferentStore)
        }
        guard reminder.calendar != nil else {
            throw EKMakeError(.noCalendar)
        }
        if !reminder.calendar.allowedEntityTypes.contains(.reminder) {
            throw EKMakeError(.calendarDoesNotAllowReminders)
        }
        if !reminder.isPriorityValid {
            throw EKMakeError(.priorityIsInvalid)
        }
        if reminder.hasRecurrenceRules && reminder.dueDateComponents == nil {
            throw EKMakeError(.recurringReminderRequiresDueDate)
        }
        reminder.owningStore = self
        reminder.stampModification()
        EKLocalStoreRoot.lock.lock()
        defer { EKLocalStoreRoot.lock.unlock() }
        var snapshot = EKLocalStoreIO.loadLocked()
        upsert(&snapshot.reminders, reminder.persistRecord()) {
            $0.calendarItemIdentifier == reminder.calendarItemIdentifier
        }
        reminder.markSaved()
        try finishMutation(snapshot, commit: commit)
    }

    open func remove(_ reminder: EKReminder, commit: Bool) throws {
        try requireWrite(for: .reminder)
        EKLocalStoreRoot.lock.lock()
        defer { EKLocalStoreRoot.lock.unlock() }
        var snapshot = EKLocalStoreIO.loadLocked()
        snapshot.reminders.removeAll { $0.calendarItemIdentifier == reminder.calendarItemIdentifier }
        try finishMutation(snapshot, commit: commit)
    }

    open func commit() throws {
        let eventStatus = Self.authorizationStatus(for: .event)
        let reminderStatus = Self.authorizationStatus(for: .reminder)
        let canWrite = eventStatus == .fullAccess || eventStatus == .writeOnly
            || reminderStatus == .fullAccess
        if !canWrite {
            throw EKMakeError(.eventStoreNotAuthorized)
        }
        EKLocalStoreRoot.lock.lock()
        defer { EKLocalStoreRoot.lock.unlock() }
        let snapshot = EKLocalStoreIO.loadLocked()
        try EKLocalStoreIO.saveLocked(snapshot)
        postChanged()
    }

    open func refreshSourcesIfNecessary() {
        EKLocalStoreRoot.lock.lock()
        let changed = EKLocalStoreIO.fileChanged()
        EKLocalStoreRoot.lock.unlock()
        if changed {
            EKLocalStoreRoot.resetCache()
            reloadFromDisk(creatingIfNeeded: false)
        }
    }

    open func reset() {
        EKLocalStoreRoot.resetCache()
        reloadFromDisk(creatingIfNeeded: false)
    }

    func refreshEvent(_ event: EKEvent) -> Bool {
        guard let identifier = event.eventIdentifier, let fresh = self.event(withIdentifier: identifier) else {
            return false
        }
        if let record = fresh.persistRecord() {
            event.applyRecord(record, calendar: fresh.calendar, store: self)
            return true
        }
        return false
    }

    func refreshReminder(_ reminder: EKReminder) -> Bool {
        guard let fresh = calendarItem(withIdentifier: reminder.calendarItemIdentifier) as? EKReminder else {
            return false
        }
        reminder.applyRecord(fresh.persistRecord(), calendar: fresh.calendar, store: self)
        return true
    }

    private func grantAccess(to entityType: EKEntityType, status requested: EKAuthorizationStatus) -> Bool {
        EKLocalStoreRoot.lock.lock()
        var snapshot = EKLocalStoreIO.loadLocked()
        let deny = EKLocalStoreRoot.denyAccess
        let current: EKAuthorizationStatus = {
            switch entityType {
            case .event: return snapshot.eventAuthorization
            case .reminder: return snapshot.reminderAuthorization
            }
        }()
        if current == .denied {
            EKLocalStoreRoot.lock.unlock()
            return false
        }
        if deny {
            switch entityType {
            case .event: snapshot.eventAuthorization = .denied
            case .reminder: snapshot.reminderAuthorization = .denied
            }
            do {
                try EKLocalStoreIO.saveLocked(snapshot)
            } catch {
                EKLocalStoreRoot.lock.unlock()
                return false
            }
            EKLocalStoreRoot.lock.unlock()
            reloadFromDisk(creatingIfNeeded: false)
            return false
        }
        if current == .fullAccess {
            EKLocalStoreRoot.lock.unlock()
            return true
        }
        if current == .writeOnly && requested == .writeOnly {
            EKLocalStoreRoot.lock.unlock()
            return true
        }
        let next: EKAuthorizationStatus = {
            if current == .writeOnly && requested == .fullAccess { return .fullAccess }
            if current == .fullAccess { return .fullAccess }
            return requested
        }()
        switch entityType {
        case .event:
            snapshot.eventAuthorization = next
            EKLocalStoreIO.ensureLocalCalendars(&snapshot, events: true, reminders: false)
        case .reminder:
            snapshot.reminderAuthorization = next
            EKLocalStoreIO.ensureLocalCalendars(&snapshot, events: false, reminders: true)
        }
        do {
            try EKLocalStoreIO.saveLocked(snapshot)
        } catch {
            EKLocalStoreRoot.lock.unlock()
            return false
        }
        EKLocalStoreRoot.lock.unlock()
        reloadFromDisk(creatingIfNeeded: false)
        return next == .fullAccess || next == .writeOnly
    }

    private func reloadFromDisk(creatingIfNeeded: Bool) {
        EKLocalStoreRoot.lock.lock()
        var snapshot = EKLocalStoreIO.loadLocked()
        if creatingIfNeeded && snapshot.eventStoreIdentifier.isEmpty {
            snapshot.eventStoreIdentifier = UUID().uuidString
        }
        eventStoreIdentifier = snapshot.eventStoreIdentifier
        EKLocalStoreRoot.lock.unlock()

        var nextSources: [EKSource] = []
        for record in snapshot.sources {
            let source = liveSources[record.identifier] ?? EKSource()
            source.applyRecord(record)
            source.bind(to: self)
            liveSources[record.identifier] = source
            nextSources.append(source)
        }
        if hostedSources == nil {
            sources = nextSources
        }

        var nextCalendars: [String: EKCalendar] = [:]
        for record in snapshot.calendars {
            let calendar = liveCalendars[record.identifier] ?? EKCalendar()
            let source = liveSources[record.sourceIdentifier]
            calendar.applyRecord(record, source: source, store: self)
            nextCalendars[record.identifier] = calendar
        }
        liveCalendars = nextCalendars
    }

    private func materializeEvent(_ record: EKEventRecord) -> EKEvent {
        let event = EKEvent(eventStore: self)
        event.applyRecord(record, calendar: liveCalendars[record.calendarIdentifier], store: self)
        return event
    }

    private func materializeReminder(_ record: EKReminderRecord) -> EKReminder {
        let reminder = EKReminder(eventStore: self)
        reminder.applyRecord(record, calendar: liveCalendars[record.calendarIdentifier], store: self)
        return reminder
    }

    private func expandedEvents(
        _ record: EKEventRecord,
        rangeStart: Date,
        rangeEnd: Date,
        snapshot: EKLocalSnapshot
    ) -> [EKEvent] {
        let master = materializeEvent(record)
        guard let start = master.startDate, let end = master.endDate else { return [] }
        let duration = end.timeIntervalSince(start)
        let exceptions = Set(snapshot.exceptionDates[record.eventIdentifier] ?? [])
        let detached = snapshot.events.filter {
            $0.isDetached && $0.calendarItemExternalIdentifier == record.calendarItemExternalIdentifier
        }
        if record.isDetached {
            if exceptions.contains(record.occurrenceDate ?? record.start) { return [] }
            return [master]
        }
        guard let rule = master.recurrenceRules?.first else {
            return [master]
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = master.timeZone ?? TimeZone(secondsFromGMT: 0)!
        let starts = EKRecurrenceExpansion.occurrenceStarts(
            rule: rule,
            seriesStart: start,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            calendar: calendar
        )
        var results: [EKEvent] = []
        for occ in starts {
            let key = occ.timeIntervalSince1970
            if let detachedRecord = detached.first(where: {
                abs(($0.occurrenceDate ?? $0.start) - key) < 0.5
            }) {
                results.append(materializeEvent(detachedRecord))
                continue
            }
            if exceptions.contains(where: { abs($0 - key) < 0.5 }) { continue }
            results.append(master.occurrenceCopy(at: occ, duration: duration, store: self))
        }
        return results
    }

    private func validateEvent(_ event: EKEvent) throws {
        try requireWrite(for: .event)
        guard event.owningStore == nil || event.owningStore === self else {
            throw EKMakeError(.objectBelongsToDifferentStore)
        }
        guard event.calendar != nil else {
            throw EKMakeError(.noCalendar)
        }
        if !event.calendar.allowedEntityTypes.contains(.event) {
            throw EKMakeError(.calendarDoesNotAllowEvents)
        }
        if event.calendar.isImmutable {
            throw EKMakeError(.calendarIsImmutable)
        }
        if !event.calendar.allowsContentModifications {
            throw EKMakeError(.calendarReadOnly)
        }
        guard event.startDate != nil else {
            throw EKMakeError(.noStartDate)
        }
        guard event.endDate != nil else {
            throw EKMakeError(.noEndDate)
        }
        if event.endDate < event.startDate {
            throw EKMakeError(.datesInverted)
        }
        event.owningStore = self
        if event.calendar.source == nil {
            event.calendar.source = source(withIdentifier: EKLocalStoreIO.localSourceIdentifier)
                ?? sources.first
        }
        if event.calendar.source == nil {
            throw EKMakeError(.calendarHasNoSource)
        }
    }

    private func applyEventSave(
        _ event: EKEvent,
        span: EKSpan,
        snapshot: inout EKLocalSnapshot
    ) throws {
        let identifier = event.eventIdentifier ?? event.calendarItemIdentifier
        let existing = snapshot.events.first { $0.eventIdentifier == identifier }
        let isRecurring = event.hasRecurrenceRules || (existing.map { !$0.recurrence.isEmpty } ?? false)
        if !isRecurring || existing == nil {
            guard let record = event.persistRecord() else { return }
            upsert(&snapshot.events, record) { $0.eventIdentifier == record.eventIdentifier }
            return
        }
        switch span {
        case .thisEvent:
            if event.occurrenceDate == nil || event.occurrenceDate == event.startDate,
               existing?.start == event.startDate?.timeIntervalSince1970,
               !event.isDetached
            {
                guard let record = event.persistRecord() else { return }
                upsert(&snapshot.events, record) { $0.eventIdentifier == record.eventIdentifier }
                return
            }
            let occurrence = event.occurrenceDate ?? event.startDate
            event.detachOccurrence(at: occurrence ?? Date())
            if let external = existing?.calendarItemExternalIdentifier {
                event.setExternalIdentifier(external)
            }
            if let occurrence {
                var dates = snapshot.exceptionDates[identifier] ?? []
                dates.append(occurrence.timeIntervalSince1970)
                snapshot.exceptionDates[identifier] = dates
            }
            guard let record = event.persistRecord() else { return }
            snapshot.events.append(record)
        case .futureEvents:
            guard let occurrence = event.occurrenceDate ?? event.startDate,
                  let existing
            else {
                guard let record = event.persistRecord() else { return }
                upsert(&snapshot.events, record) { $0.eventIdentifier == record.eventIdentifier }
                return
            }
            if occurrence.timeIntervalSince1970 <= existing.start {
                guard let record = event.persistRecord() else { return }
                upsert(&snapshot.events, record) { $0.eventIdentifier == record.eventIdentifier }
                return
            }
            var master = existing
            if master.recurrence.indices.first != nil {
                master.recurrence[0].endDate = occurrence.addingTimeInterval(-1).timeIntervalSince1970
                master.recurrence[0].occurrenceCount = 0
            }
            upsert(&snapshot.events, master) { $0.eventIdentifier == master.eventIdentifier }
            event.reidentify(eventIdentifier: UUID().uuidString, calendarItemIdentifier: UUID().uuidString)
            event.setOccurrenceDate(occurrence)
            event.startDate = occurrence
            guard let record = event.persistRecord() else { return }
            snapshot.events.append(record)
        }
    }

    private func applyEventRemove(
        _ event: EKEvent,
        span: EKSpan,
        snapshot: inout EKLocalSnapshot
    ) throws {
        let identifier = event.eventIdentifier ?? event.calendarItemIdentifier
        let existing = snapshot.events.first { $0.eventIdentifier == identifier }
        let isRecurring = (existing.map { !$0.recurrence.isEmpty } ?? false) || event.hasRecurrenceRules
        if !isRecurring {
            snapshot.events.removeAll { $0.eventIdentifier == identifier }
            return
        }
        switch span {
        case .thisEvent:
            if let occurrence = event.occurrenceDate ?? event.startDate {
                var dates = snapshot.exceptionDates[identifier] ?? []
                dates.append(occurrence.timeIntervalSince1970)
                snapshot.exceptionDates[identifier] = dates
            }
            snapshot.events.removeAll {
                $0.isDetached
                    && $0.calendarItemExternalIdentifier == existing?.calendarItemExternalIdentifier
                    && $0.occurrenceDate == (event.occurrenceDate ?? event.startDate)?.timeIntervalSince1970
            }
        case .futureEvents:
            guard let occurrence = event.occurrenceDate ?? event.startDate, var master = existing else {
                snapshot.events.removeAll { $0.eventIdentifier == identifier }
                return
            }
            if occurrence.timeIntervalSince1970 <= master.start {
                snapshot.events.removeAll { $0.eventIdentifier == identifier }
                snapshot.exceptionDates.removeValue(forKey: identifier)
                return
            }
            if !master.recurrence.isEmpty {
                master.recurrence[0].endDate = occurrence.addingTimeInterval(-1).timeIntervalSince1970
                master.recurrence[0].occurrenceCount = 0
                upsert(&snapshot.events, master) { $0.eventIdentifier == master.eventIdentifier }
            } else {
                snapshot.events.removeAll { $0.eventIdentifier == identifier }
            }
        }
    }

    private func finishMutation(_ snapshot: EKLocalSnapshot, commit: Bool) throws {
        EKLocalStoreRoot.snapshot = snapshot
        if commit {
            try EKLocalStoreIO.saveLocked(snapshot)
            postChanged()
        }
    }

    private func postChanged() {
        NotificationCenter.default.post(name: .EKEventStoreChanged, object: self)
    }

    private func canSeeCalendars(for entityType: EKEntityType) -> Bool {
        let status = Self.authorizationStatus(for: entityType)
        switch status {
        case .fullAccess, .writeOnly: return true
        default: return false
        }
    }

    private func canRead(_ entityType: EKEntityType) -> Bool {
        Self.authorizationStatus(for: entityType) == .fullAccess
    }

    private func requireWrite(for entityType: EKEntityType) throws {
        let status = Self.authorizationStatus(for: entityType)
        switch status {
        case .fullAccess:
            return
        case .writeOnly where entityType == .event:
            return
        default:
            throw EKMakeError(.eventStoreNotAuthorized)
        }
    }

    private func entityTypes(of calendar: EKCalendar) -> EKEntityType {
        calendar.allowedEntityTypes.contains(.event) ? .event : .reminder
    }

    private func upsert<T>(
        _ items: inout [T],
        _ item: T,
        matches: (T) -> Bool
    ) {
        if let index = items.firstIndex(where: matches) {
            items[index] = item
        } else {
            items.append(item)
        }
    }

    private struct CalendarFilter {
        let restrict: Bool
        let identifiers: Set<String>

        func matches(_ calendar: EKCalendar?) -> Bool {
            guard restrict else { return true }
            guard let calendar, identifiers.contains(calendar.calendarIdentifier) else {
                return false
            }
            return true
        }
    }

    private static func calendarFilter(_ calendars: [EKCalendar]?) -> CalendarFilter {
        CalendarFilter(
            restrict: calendars != nil,
            identifiers: Set((calendars ?? []).map(\.calendarIdentifier))
        )
    }

    private static func dueDate(
        _ components: DateComponents?,
        starts startDate: Date?,
        ends endDate: Date?
    ) -> Bool {
        if startDate == nil && endDate == nil {
            return true
        }
        guard let components else { return false }
        var calendar = components.calendar ?? Calendar.current
        if let timeZone = components.timeZone {
            calendar.timeZone = timeZone
        }
        guard let due = calendar.date(from: components) else {
            return false
        }
        if let startDate, due < startDate { return false }
        if let endDate, due > endDate { return false }
        return true
    }
}

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS)
extension EKEventStore {
    public struct EventStoreChanged: NotificationCenter.MainActorMessage {
        public typealias Subject = EKEventStore

        public static var name: Notification.Name { .EKEventStoreChanged }

        public init() {}

        @MainActor
        public static func makeMessage(
            _ notification: Notification
        ) -> EKEventStore.EventStoreChanged? {
            guard notification.name == name else { return nil }
            return EventStoreChanged()
        }

        @MainActor
        public static func makeNotification(
            _ message: EKEventStore.EventStoreChanged
        ) -> Notification {
            _ = message
            return Notification(name: name)
        }
    }
}

extension NotificationCenter.MessageIdentifier
where Self == NotificationCenter.BaseMessageIdentifier<EKEventStore.EventStoreChanged> {
    public static var changed: NotificationCenter.BaseMessageIdentifier<EKEventStore.EventStoreChanged> {
        .init()
    }
}
#else
extension EKEventStore {
    public struct EventStoreChanged {
        public typealias Subject = EKEventStore
        public static var name: Notification.Name { .EKEventStoreChanged }
        public init() {}

        public static func makeMessage(
            _ notification: Notification
        ) -> EKEventStore.EventStoreChanged? {
            guard notification.name == name else { return nil }
            return EventStoreChanged()
        }

        public static func makeNotification(
            _ message: EKEventStore.EventStoreChanged
        ) -> Notification {
            _ = message
            return Notification(name: name)
        }
    }
}
#endif
