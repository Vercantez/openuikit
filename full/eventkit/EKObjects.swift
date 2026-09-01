import Foundation

/// Shared dirty-state base for EventKit model objects.
open class EKObject: NSObject {
    private var _isNew = true
    private var _hasChanges = false

    /// Not a public EventKit constructor. NSObject's inherited `init` is hidden
    /// so callers cannot mint bare `EKObject` instances.
    internal override init() {
        super.init()
    }

    open var hasChanges: Bool { _hasChanges }
    open var isNew: Bool { _isNew }

    open func refresh() -> Bool {
        false
    }

    open func reset() {
        restoreCommittedState()
        _hasChanges = false
    }

    open func rollback() {
        reset()
    }

    func markChanged() {
        _hasChanges = true
    }

    func markSaved() {
        _isNew = false
        _hasChanges = false
        captureCommittedState()
    }

    func captureCommittedState() {}

    func restoreCommittedState() {}

    func finishInitialization() {
        captureCommittedState()
        _hasChanges = false
    }
}

/// Named location attached to an event or geofenced alarm. Core Location /
/// MapKit coordinates are not part of this Foundation-only starting point.
open class EKStructuredLocation: EKObject, NSCopying {
    public var title: String? {
        get { _title }
        set {
            _title = newValue
            markChanged()
        }
    }
    public var radius: Double {
        get { _radius }
        set {
            _radius = newValue
            markChanged()
        }
    }

    private var _title: String?
    private var _radius: Double = 0
    private var _committedTitle: String?
    private var _committedRadius: Double = 0

    internal override init() {
        super.init()
        finishInitialization()
    }

    public convenience init(title: String) {
        self.init()
        _title = title
        finishInitialization()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = EKStructuredLocation()
        copy._title = _title
        copy._radius = _radius
        copy.captureCommittedState()
        return copy
    }

    override func captureCommittedState() {
        _committedTitle = _title
        _committedRadius = _radius
    }

    override func restoreCommittedState() {
        _title = _committedTitle
        _radius = _committedRadius
    }
}

/// Relative or absolute alarm on a calendar item.
open class EKAlarm: EKObject, NSCopying {
    public var relativeOffset: TimeInterval {
        get { _relativeOffset }
        set {
            _relativeOffset = newValue
            _absoluteDate = nil
            markChanged()
        }
    }
    public var absoluteDate: Date? {
        get { _absoluteDate }
        set {
            _absoluteDate = newValue
            if newValue != nil {
                _relativeOffset = 0
            }
            markChanged()
        }
    }
    public var proximity: EKAlarmProximity {
        get { _proximity }
        set {
            _proximity = newValue
            markChanged()
        }
    }
    public var structuredLocation: EKStructuredLocation? {
        get { _structuredLocation }
        set {
            _structuredLocation = newValue.flatMap { $0.copy() as? EKStructuredLocation }
            markChanged()
        }
    }

    private var _relativeOffset: TimeInterval = 0
    private var _absoluteDate: Date?
    private var _proximity: EKAlarmProximity = .none
    private var _structuredLocation: EKStructuredLocation?
    private var _committedRelativeOffset: TimeInterval = 0
    private var _committedAbsoluteDate: Date?
    private var _committedProximity: EKAlarmProximity = .none
    private var _committedStructuredLocation: EKStructuredLocation?

    internal override init() {
        super.init()
        finishInitialization()
    }

    public init(absoluteDate date: Date) {
        _absoluteDate = date
        super.init()
        finishInitialization()
    }

    public init(relativeOffset offset: TimeInterval) {
        _relativeOffset = offset
        super.init()
        finishInitialization()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = EKAlarm()
        copy._relativeOffset = _relativeOffset
        copy._absoluteDate = _absoluteDate
        copy._proximity = _proximity
        copy._structuredLocation = _structuredLocation.flatMap { $0.copy() as? EKStructuredLocation }
        copy.captureCommittedState()
        return copy
    }

    override func captureCommittedState() {
        _committedRelativeOffset = _relativeOffset
        _committedAbsoluteDate = _absoluteDate
        _committedProximity = _proximity
        _committedStructuredLocation = _structuredLocation.flatMap { $0.copy() as? EKStructuredLocation }
    }

    override func restoreCommittedState() {
        _relativeOffset = _committedRelativeOffset
        _absoluteDate = _committedAbsoluteDate
        _proximity = _committedProximity
        _structuredLocation = _committedStructuredLocation.flatMap { $0.copy() as? EKStructuredLocation }
    }
}

/// Calendar account/source. Linux has no host CalDAV/Exchange/iCloud accounts.
open class EKSource: EKObject {
    public private(set) var sourceIdentifier: String
    public private(set) var sourceType: EKSourceType
    public private(set) var title: String
    public private(set) var isDelegate: Bool
    private weak var store: EKEventStore?

    @_spi(OpenUIKitHost)
    public override init() {
        sourceIdentifier = UUID().uuidString
        sourceType = .local
        title = ""
        isDelegate = false
        super.init()
        finishInitialization()
    }

    func bind(to store: EKEventStore) {
        self.store = store
    }

    open func calendars(for entityType: EKEntityType) -> Set<EKCalendar> {
        guard let store else { return [] }
        return Set(store.calendars(for: entityType).filter { calendar in
            calendar.source === self
        })
    }
}

/// A named calendar that can hold events and/or reminders.
open class EKCalendar: EKObject {
    public private(set) var calendarIdentifier: String
    public var title: String {
        get { _title }
        set {
            _title = newValue
            markChanged()
        }
    }
    public var source: EKSource! {
        get { _source }
        set {
            _source = newValue
            markChanged()
        }
    }
    public private(set) var type: EKCalendarType
    public private(set) var allowedEntityTypes: EKEntityMask
    public private(set) var allowsContentModifications: Bool
    public private(set) var isImmutable: Bool
    public private(set) var isSubscribed: Bool
    public private(set) var supportedEventAvailabilities: EKCalendarEventAvailabilityMask

    private var _title: String = ""
    private var _source: EKSource?
    private var _committedTitle: String = ""
    private var _committedSource: EKSource?
    private weak var eventStore: EKEventStore?

    internal override init() {
        calendarIdentifier = UUID().uuidString
        type = .local
        allowedEntityTypes = [.event, .reminder]
        allowsContentModifications = true
        isImmutable = false
        isSubscribed = false
        supportedEventAvailabilities = [.busy, .free]
        super.init()
        finishInitialization()
    }

    public init(for entityType: EKEntityType, eventStore: EKEventStore) {
        calendarIdentifier = UUID().uuidString
        type = .local
        switch entityType {
        case .event:
            allowedEntityTypes = [.event]
        case .reminder:
            allowedEntityTypes = [.reminder]
        }
        allowsContentModifications = true
        isImmutable = false
        isSubscribed = false
        supportedEventAvailabilities = entityType == .event ? [.busy, .free] : []
        self.eventStore = eventStore
        super.init()
        finishInitialization()
    }

    public init(forEntityType entityType: EKEntityType, eventStore: EKEventStore) {
        calendarIdentifier = UUID().uuidString
        type = .local
        switch entityType {
        case .event:
            allowedEntityTypes = [.event]
        case .reminder:
            allowedEntityTypes = [.reminder]
        }
        allowsContentModifications = true
        isImmutable = false
        isSubscribed = false
        supportedEventAvailabilities = entityType == .event ? [.busy, .free] : []
        self.eventStore = eventStore
        super.init()
        finishInitialization()
    }

    override func captureCommittedState() {
        _committedTitle = _title
        _committedSource = _source
    }

    override func restoreCommittedState() {
        _title = _committedTitle
        _source = _committedSource
    }
}

/// Shared fields of events and reminders.
open class EKCalendarItem: EKObject {
    public private(set) var calendarItemIdentifier: String
    public private(set) var calendarItemExternalIdentifier: String!
    public var calendar: EKCalendar! {
        get { _calendar }
        set {
            _calendar = newValue
            markChanged()
        }
    }
    public var title: String! {
        get { _title }
        set {
            _title = newValue
            markChanged()
        }
    }
    public var location: String? {
        get { _location }
        set {
            _location = newValue
            markChanged()
        }
    }
    public var notes: String? {
        get { _notes }
        set {
            _notes = newValue
            markChanged()
        }
    }
    public var url: URL? {
        get { _url }
        set {
            _url = newValue
            markChanged()
        }
    }
    public var timeZone: TimeZone? {
        get { _timeZone }
        set {
            _timeZone = newValue
            markChanged()
        }
    }
    public var alarms: [EKAlarm]? {
        get { _alarms.isEmpty ? nil : _alarms }
        set {
            _alarms = newValue ?? []
            markChanged()
        }
    }
    public var recurrenceRules: [EKRecurrenceRule]? {
        get { _recurrenceRules.isEmpty ? nil : _recurrenceRules }
        set {
            _recurrenceRules = newValue ?? []
            markChanged()
        }
    }
    public private(set) var attendees: [EKParticipant]?
    public private(set) var creationDate: Date?
    public private(set) var lastModifiedDate: Date?

    public var hasAlarms: Bool { !_alarms.isEmpty }
    public var hasRecurrenceRules: Bool { !_recurrenceRules.isEmpty }
    public var hasAttendees: Bool { !(attendees?.isEmpty ?? true) }
    public var hasNotes: Bool { !(notes?.isEmpty ?? true) }

    var _calendar: EKCalendar?
    var _title: String!
    var _location: String?
    var _notes: String?
    var _url: URL?
    var _timeZone: TimeZone?
    var _alarms: [EKAlarm] = []
    var _recurrenceRules: [EKRecurrenceRule] = []
    weak var owningStore: EKEventStore?

    private var _committedCalendar: EKCalendar?
    private var _committedTitle: String!
    private var _committedLocation: String?
    private var _committedNotes: String?
    private var _committedURL: URL?
    private var _committedTimeZone: TimeZone?
    private var _committedAlarms: [EKAlarm] = []
    private var _committedRecurrenceRules: [EKRecurrenceRule] = []

    internal override init() {
        calendarItemIdentifier = UUID().uuidString
        calendarItemExternalIdentifier = calendarItemIdentifier
        creationDate = Date()
        lastModifiedDate = creationDate
        super.init()
        finishInitialization()
    }

    open func addAlarm(_ alarm: EKAlarm) {
        _alarms.append(alarm)
        markChanged()
    }

    open func removeAlarm(_ alarm: EKAlarm) {
        _alarms.removeAll { $0 === alarm }
        markChanged()
    }

    open func addRecurrenceRule(_ rule: EKRecurrenceRule) {
        _recurrenceRules.append(rule)
        markChanged()
    }

    open func removeRecurrenceRule(_ rule: EKRecurrenceRule) {
        _recurrenceRules.removeAll { $0 === rule }
        markChanged()
    }

    override func captureCommittedState() {
        _committedCalendar = _calendar
        _committedTitle = _title
        _committedLocation = _location
        _committedNotes = _notes
        _committedURL = _url
        _committedTimeZone = _timeZone
        _committedAlarms = _alarms
        _committedRecurrenceRules = _recurrenceRules
    }

    override func restoreCommittedState() {
        _calendar = _committedCalendar
        _title = _committedTitle
        _location = _committedLocation
        _notes = _committedNotes
        _url = _committedURL
        _timeZone = _committedTimeZone
        _alarms = _committedAlarms
        _recurrenceRules = _committedRecurrenceRules
    }
}

/// Calendar event. Persistence is fail-closed until a host store exists.
open class EKEvent: EKCalendarItem {
    public private(set) var eventIdentifier: String!
    public var startDate: Date! {
        get { _startDate }
        set {
            _startDate = newValue
            if !isDetached {
                occurrenceDate = newValue
            }
            markChanged()
        }
    }
    public var endDate: Date! {
        get { _endDate }
        set {
            _endDate = newValue
            markChanged()
        }
    }
    public var isAllDay: Bool {
        get { _isAllDay }
        set {
            _isAllDay = newValue
            markChanged()
        }
    }
    public var availability: EKEventAvailability {
        get { _availability }
        set {
            _availability = newValue
            markChanged()
        }
    }
    public var structuredLocation: EKStructuredLocation? {
        get { _structuredLocation }
        set {
            _structuredLocation = newValue.flatMap { $0.copy() as? EKStructuredLocation }
            if let title = _structuredLocation?.title {
                location = title
            }
            markChanged()
        }
    }
    public private(set) var status: EKEventStatus
    public private(set) var organizer: EKParticipant?
    public private(set) var isDetached: Bool
    public private(set) var occurrenceDate: Date!
    public private(set) var birthdayContactIdentifier: String?
    public private(set) var birthdayPersonID: Int

    private var _startDate: Date!
    private var _endDate: Date!
    private var _isAllDay = false
    private var _availability: EKEventAvailability = .busy
    private var _structuredLocation: EKStructuredLocation?
    private var _committedStartDate: Date!
    private var _committedEndDate: Date!
    private var _committedIsAllDay = false
    private var _committedAvailability: EKEventAvailability = .busy
    private var _committedStructuredLocation: EKStructuredLocation?
    private var _committedOccurrenceDate: Date!

    internal override init() {
        eventIdentifier = UUID().uuidString
        status = .none
        isDetached = false
        birthdayPersonID = -1
        super.init()
        finishInitialization()
    }

    public init(eventStore: EKEventStore) {
        eventIdentifier = UUID().uuidString
        status = .none
        isDetached = false
        birthdayPersonID = -1
        super.init()
        owningStore = eventStore
        _calendar = eventStore.defaultCalendarForNewEvents
        finishInitialization()
    }

    open func compareStartDate(with other: EKEvent) -> ComparisonResult {
        let left = startDate ?? Date.distantPast
        let right = other.startDate ?? Date.distantPast
        return left.compare(right)
    }

    open override func refresh() -> Bool {
        false
    }

    override func captureCommittedState() {
        super.captureCommittedState()
        _committedStartDate = _startDate
        _committedEndDate = _endDate
        _committedIsAllDay = _isAllDay
        _committedAvailability = _availability
        _committedStructuredLocation = _structuredLocation.flatMap { $0.copy() as? EKStructuredLocation }
        _committedOccurrenceDate = occurrenceDate
    }

    override func restoreCommittedState() {
        super.restoreCommittedState()
        _startDate = _committedStartDate
        _endDate = _committedEndDate
        _isAllDay = _committedIsAllDay
        _availability = _committedAvailability
        _structuredLocation = _committedStructuredLocation.flatMap { $0.copy() as? EKStructuredLocation }
        occurrenceDate = _committedOccurrenceDate
    }
}

/// Reminder. Persistence is fail-closed until a host store exists.
open class EKReminder: EKCalendarItem {
    public var startDateComponents: DateComponents? {
        get { _startDateComponents }
        set {
            _startDateComponents = newValue
            markChanged()
        }
    }
    public var dueDateComponents: DateComponents? {
        get { _dueDateComponents }
        set {
            _dueDateComponents = newValue
            markChanged()
        }
    }
    public var priority: Int {
        get { _priority }
        set {
            _priority = newValue
            markChanged()
        }
    }
    public var isCompleted: Bool {
        get { _completionDate != nil }
        set {
            if newValue {
                if _completionDate == nil {
                    _completionDate = Date()
                }
            } else {
                _completionDate = nil
            }
            markChanged()
        }
    }
    public var completionDate: Date? {
        get { _completionDate }
        set {
            _completionDate = newValue
            markChanged()
        }
    }

    private var _startDateComponents: DateComponents?
    private var _dueDateComponents: DateComponents?
    private var _priority: Int = Int(EKReminderPriority.none.rawValue)
    private var _completionDate: Date?
    private var _committedStartDateComponents: DateComponents?
    private var _committedDueDateComponents: DateComponents?
    private var _committedPriority: Int = Int(EKReminderPriority.none.rawValue)
    private var _committedCompletionDate: Date?

    internal override init() {
        super.init()
        finishInitialization()
    }

    public init(eventStore: EKEventStore) {
        super.init()
        owningStore = eventStore
        _calendar = eventStore.defaultCalendarForNewReminders()
        finishInitialization()
    }

    override func captureCommittedState() {
        super.captureCommittedState()
        _committedStartDateComponents = _startDateComponents
        _committedDueDateComponents = _dueDateComponents
        _committedPriority = _priority
        _committedCompletionDate = _completionDate
    }

    override func restoreCommittedState() {
        super.restoreCommittedState()
        _startDateComponents = _committedStartDateComponents
        _dueDateComponents = _committedDueDateComponents
        _priority = _committedPriority
        _completionDate = _committedCompletionDate
    }
}

/// Attendee on an event. AddressBook/Contacts lookup is fail-closed.
open class EKParticipant: EKObject, NSCopying {
    public private(set) var url: URL
    public private(set) var name: String?
    public private(set) var participantStatus: EKParticipantStatus
    public private(set) var participantRole: EKParticipantRole
    public private(set) var participantType: EKParticipantType
    public private(set) var isCurrentUser: Bool
    public var contactPredicate: NSPredicate {
        NSPredicate { _, _ in false }
    }

    @_spi(OpenUIKitHost)
    public override init() {
        url = URL(string: "mailto:")!
        participantStatus = .unknown
        participantRole = .unknown
        participantType = .unknown
        isCurrentUser = false
        super.init()
        finishInitialization()
    }

    open func abRecord(with addressBook: ABAddressBook) -> ABRecord? {
        _ = addressBook
        return nil
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = EKParticipant()
        copy.url = url
        copy.name = name
        copy.participantStatus = participantStatus
        copy.participantRole = participantRole
        copy.participantType = participantType
        copy.isCurrentUser = isCurrentUser
        return copy
    }
}
