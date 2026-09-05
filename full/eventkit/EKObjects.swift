import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif
#if canImport(MapKit)
import MapKit
#endif

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
    #if canImport(CoreLocation)
    public var geoLocation: CLLocation? {
        get {
            guard let latitude = _latitude, let longitude = _longitude else { return nil }
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        set {
            _latitude = newValue?.coordinate.latitude
            _longitude = newValue?.coordinate.longitude
            markChanged()
        }
    }
    #endif

    private var _title: String?
    private var _radius: Double = 0
    var _latitude: Double?
    var _longitude: Double?
    private var _committedTitle: String?
    private var _committedRadius: Double = 0
    private var _committedLatitude: Double?
    private var _committedLongitude: Double?

    internal override init() {
        super.init()
        finishInitialization()
    }

    public convenience init(title: String) {
        self.init()
        _title = title
        finishInitialization()
    }

    #if canImport(MapKit) && canImport(CoreLocation)
    public convenience init(mapItem: MKMapItem) {
        self.init(title: mapItem.name ?? "")
        geoLocation = mapItem.location
        finishInitialization()
    }
    #endif

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = EKStructuredLocation()
        copy._title = _title
        copy._radius = _radius
        copy._latitude = _latitude
        copy._longitude = _longitude
        copy.captureCommittedState()
        return copy
    }

    override func captureCommittedState() {
        _committedTitle = _title
        _committedRadius = _radius
        _committedLatitude = _latitude
        _committedLongitude = _longitude
    }

    override func restoreCommittedState() {
        _title = _committedTitle
        _radius = _committedRadius
        _latitude = _committedLatitude
        _longitude = _committedLongitude
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

    func persistRecord() -> EKAlarmRecord {
        EKAlarmRecord(
            relativeOffset: relativeOffset,
            absoluteDate: absoluteDate?.timeIntervalSince1970,
            proximity: proximity.rawValue,
            locationTitle: structuredLocation?.title,
            locationRadius: structuredLocation?.radius ?? 0,
            latitude: structuredLocation?._latitude,
            longitude: structuredLocation?._longitude
        )
    }

    static func fromRecord(_ record: EKAlarmRecord) -> EKAlarm {
        let alarm: EKAlarm
        if let absolute = record.absoluteDate {
            alarm = EKAlarm(absoluteDate: Date(timeIntervalSince1970: absolute))
        } else {
            alarm = EKAlarm(relativeOffset: record.relativeOffset)
        }
        alarm.proximity = EKAlarmProximity(rawValue: record.proximity) ?? .none
        if let title = record.locationTitle {
            let location = EKStructuredLocation(title: title)
            location.radius = record.locationRadius
            location._latitude = record.latitude
            location._longitude = record.longitude
            alarm.structuredLocation = location
        }
        alarm.finishInitialization()
        return alarm
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

    func applyRecord(_ record: EKSourceRecord) {
        sourceIdentifier = record.identifier
        sourceType = EKSourceType(rawValue: record.sourceType) ?? .local
        title = record.title
        isDelegate = record.isDelegate
        finishInitialization()
    }

    func persistRecord() -> EKSourceRecord {
        EKSourceRecord(
            identifier: sourceIdentifier,
            sourceType: sourceType.rawValue,
            title: title,
            isDelegate: isDelegate
        )
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
    var colorRed: Double = EKLocalStoreIO.defaultRed
    var colorGreen: Double = EKLocalStoreIO.defaultGreen
    var colorBlue: Double = EKLocalStoreIO.defaultBlue
    var colorAlpha: Double = EKLocalStoreIO.defaultAlpha
    #if canImport(CoreGraphics)
    public var cgColor: CGColor! {
        get {
            CGColor(
                red: CGFloat(colorRed),
                green: CGFloat(colorGreen),
                blue: CGFloat(colorBlue),
                alpha: CGFloat(colorAlpha)
            )
        }
        set {
            if let components = newValue?.components, components.count >= 3 {
                colorRed = Double(components[0])
                colorGreen = Double(components[1])
                colorBlue = Double(components[2])
                colorAlpha = components.count > 3 ? Double(components[3]) : 1
            }
            markChanged()
        }
    }
    #endif

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

    func applyRecord(_ record: EKCalendarRecord, source: EKSource?, store: EKEventStore) {
        calendarIdentifier = record.identifier
        _title = record.title
        _source = source
        type = EKCalendarType(rawValue: record.type) ?? .local
        allowedEntityTypes = EKEntityMask(rawValue: record.allowedEntityTypes)
        allowsContentModifications = record.allowsContentModifications
        isImmutable = record.isImmutable
        isSubscribed = record.isSubscribed
        supportedEventAvailabilities = EKCalendarEventAvailabilityMask(
            rawValue: record.supportedEventAvailabilities
        )
        colorRed = record.colorRed
        colorGreen = record.colorGreen
        colorBlue = record.colorBlue
        colorAlpha = record.colorAlpha
        eventStore = store
        finishInitialization()
    }

    func persistRecord() -> EKCalendarRecord {
        EKCalendarRecord(
            identifier: calendarIdentifier,
            title: title,
            sourceIdentifier: source?.sourceIdentifier ?? EKLocalStoreIO.localSourceIdentifier,
            type: type.rawValue,
            allowedEntityTypes: allowedEntityTypes.rawValue,
            allowsContentModifications: allowsContentModifications,
            isImmutable: isImmutable,
            isSubscribed: isSubscribed,
            supportedEventAvailabilities: supportedEventAvailabilities.rawValue,
            colorRed: colorRed,
            colorGreen: colorGreen,
            colorBlue: colorBlue,
            colorAlpha: colorAlpha
        )
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

    func applyItemIdentity(
        identifier: String,
        externalIdentifier: String,
        creationDate: Date?,
        lastModifiedDate: Date?
    ) {
        calendarItemIdentifier = identifier
        calendarItemExternalIdentifier = externalIdentifier
        self.creationDate = creationDate
        self.lastModifiedDate = lastModifiedDate
    }

    func setExternalIdentifier(_ identifier: String) {
        calendarItemExternalIdentifier = identifier
    }

    func persistAlarms() -> [EKAlarmRecord] {
        _alarms.map { $0.persistRecord() }
    }

    func persistRecurrence() -> [EKRecurrenceRecord] {
        _recurrenceRules.map { $0.persistRecord() }
    }

    func installAlarms(_ records: [EKAlarmRecord]) {
        _alarms = records.map { EKAlarm.fromRecord($0) }
    }

    func installRecurrence(_ records: [EKRecurrenceRecord]) {
        _recurrenceRules = records.map { EKRecurrenceRule.fromRecord($0) }
    }

    func stampModification() {
        lastModifiedDate = Date()
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
        guard let store = owningStore else { return false }
        return store.refreshEvent(self)
    }

    func applyRecord(_ record: EKEventRecord, calendar: EKCalendar?, store: EKEventStore) {
        applyItemIdentity(
            identifier: record.calendarItemIdentifier,
            externalIdentifier: record.calendarItemExternalIdentifier,
            creationDate: record.creationDate.map { Date(timeIntervalSince1970: $0) },
            lastModifiedDate: record.lastModifiedDate.map { Date(timeIntervalSince1970: $0) }
        )
        eventIdentifier = record.eventIdentifier
        _calendar = calendar
        _title = record.title
        _location = record.location
        _notes = record.notes
        _url = record.url.flatMap { URL(string: $0) }
        _timeZone = record.timeZone.flatMap { TimeZone(identifier: $0) }
        _startDate = Date(timeIntervalSince1970: record.start)
        _endDate = Date(timeIntervalSince1970: record.end)
        _isAllDay = record.isAllDay
        _availability = EKEventAvailability(rawValue: record.availability) ?? .busy
        status = EKEventStatus(rawValue: record.status) ?? .none
        isDetached = record.isDetached
        occurrenceDate = record.occurrenceDate.map { Date(timeIntervalSince1970: $0) } ?? _startDate
        birthdayContactIdentifier = record.birthdayContactIdentifier
        birthdayPersonID = record.birthdayPersonID
        installAlarms(record.alarms)
        installRecurrence(record.recurrence)
        if let title = record.structuredTitle {
            let location = EKStructuredLocation(title: title)
            location.radius = record.structuredRadius
            location._latitude = record.structuredLatitude
            location._longitude = record.structuredLongitude
            _structuredLocation = location
        } else {
            _structuredLocation = nil
        }
        owningStore = store
        finishInitialization()
    }

    func persistRecord() -> EKEventRecord? {
        guard let start = startDate, let end = endDate else { return nil }
        return EKEventRecord(
            calendarItemIdentifier: calendarItemIdentifier,
            calendarItemExternalIdentifier: calendarItemExternalIdentifier ?? calendarItemIdentifier,
            eventIdentifier: eventIdentifier ?? calendarItemIdentifier,
            calendarIdentifier: calendar?.calendarIdentifier ?? "",
            title: title,
            location: location,
            notes: notes,
            url: url?.absoluteString,
            timeZone: timeZone?.identifier,
            start: start.timeIntervalSince1970,
            end: end.timeIntervalSince1970,
            isAllDay: isAllDay,
            availability: availability.rawValue,
            status: status.rawValue,
            isDetached: isDetached,
            occurrenceDate: occurrenceDate?.timeIntervalSince1970,
            birthdayContactIdentifier: birthdayContactIdentifier,
            birthdayPersonID: birthdayPersonID,
            creationDate: creationDate?.timeIntervalSince1970,
            lastModifiedDate: lastModifiedDate?.timeIntervalSince1970,
            alarms: persistAlarms(),
            recurrence: persistRecurrence(),
            structuredTitle: structuredLocation?.title,
            structuredRadius: structuredLocation?.radius ?? 0,
            structuredLatitude: structuredLocation?._latitude,
            structuredLongitude: structuredLocation?._longitude
        )
    }

    func occurrenceCopy(at date: Date, duration: TimeInterval, store: EKEventStore) -> EKEvent {
        let copy = EKEvent(eventStore: store)
        copy.applyRecord(
            persistRecord() ?? EKEventRecord(
                calendarItemIdentifier: calendarItemIdentifier,
                calendarItemExternalIdentifier: calendarItemExternalIdentifier ?? calendarItemIdentifier,
                eventIdentifier: eventIdentifier ?? calendarItemIdentifier,
                calendarIdentifier: calendar?.calendarIdentifier ?? "",
                title: title,
                location: location,
                notes: notes,
                url: url?.absoluteString,
                timeZone: timeZone?.identifier,
                start: date.timeIntervalSince1970,
                end: (date + duration).timeIntervalSince1970,
                isAllDay: isAllDay,
                availability: availability.rawValue,
                status: status.rawValue,
                isDetached: false,
                occurrenceDate: date.timeIntervalSince1970,
                birthdayContactIdentifier: birthdayContactIdentifier,
                birthdayPersonID: birthdayPersonID,
                creationDate: creationDate?.timeIntervalSince1970,
                lastModifiedDate: lastModifiedDate?.timeIntervalSince1970,
                alarms: persistAlarms(),
                recurrence: persistRecurrence(),
                structuredTitle: structuredLocation?.title,
                structuredRadius: structuredLocation?.radius ?? 0,
                structuredLatitude: structuredLocation?._latitude,
                structuredLongitude: structuredLocation?._longitude
            ),
            calendar: calendar,
            store: store
        )
        copy._startDate = date
        copy._endDate = date.addingTimeInterval(duration)
        copy.occurrenceDate = date
        copy.isDetached = false
        copy.finishInitialization()
        return copy
    }

    func detachOccurrence(at date: Date) {
        isDetached = true
        occurrenceDate = date
        eventIdentifier = UUID().uuidString
        _recurrenceRules = []
    }

    func reidentify(eventIdentifier: String, calendarItemIdentifier: String) {
        self.eventIdentifier = eventIdentifier
        applyItemIdentity(
            identifier: calendarItemIdentifier,
            externalIdentifier: calendarItemExternalIdentifier ?? calendarItemIdentifier,
            creationDate: creationDate,
            lastModifiedDate: lastModifiedDate
        )
    }

    func setOccurrenceDate(_ date: Date) {
        occurrenceDate = date
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

    /// RFC 5545 bands used by Reminders: 0 none, 1–4 high, 5 medium, 6–9 low.
    var priorityBand: EKReminderPriority {
        switch _priority {
        case 0: return .none
        case 1...4: return .high
        case 5: return .medium
        case 6...9: return .low
        default: return .none
        }
    }

    var isPriorityValid: Bool { (0...9).contains(_priority) }
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

    open override func refresh() -> Bool {
        guard let store = owningStore else { return false }
        return store.refreshReminder(self)
    }

    func applyRecord(_ record: EKReminderRecord, calendar: EKCalendar?, store: EKEventStore) {
        applyItemIdentity(
            identifier: record.calendarItemIdentifier,
            externalIdentifier: record.calendarItemExternalIdentifier,
            creationDate: record.creationDate.map { Date(timeIntervalSince1970: $0) },
            lastModifiedDate: record.lastModifiedDate.map { Date(timeIntervalSince1970: $0) }
        )
        _calendar = calendar
        _title = record.title
        _notes = record.notes
        _url = record.url.flatMap { URL(string: $0) }
        _timeZone = record.timeZone.flatMap { TimeZone(identifier: $0) }
        _priority = record.priority
        _completionDate = record.completionDate.map { Date(timeIntervalSince1970: $0) }
        _startDateComponents = EKDecodeDateComponents(record.startComponents)
        _dueDateComponents = EKDecodeDateComponents(record.dueComponents)
        installAlarms(record.alarms)
        installRecurrence(record.recurrence)
        owningStore = store
        finishInitialization()
    }

    func persistRecord() -> EKReminderRecord {
        EKReminderRecord(
            calendarItemIdentifier: calendarItemIdentifier,
            calendarItemExternalIdentifier: calendarItemExternalIdentifier ?? calendarItemIdentifier,
            calendarIdentifier: calendar?.calendarIdentifier ?? "",
            title: title,
            notes: notes,
            url: url?.absoluteString,
            timeZone: timeZone?.identifier,
            priority: priority,
            completionDate: completionDate?.timeIntervalSince1970,
            startComponents: EKEncodeDateComponents(startDateComponents),
            dueComponents: EKEncodeDateComponents(dueDateComponents),
            creationDate: creationDate?.timeIntervalSince1970,
            lastModifiedDate: lastModifiedDate?.timeIntervalSince1970,
            alarms: persistAlarms(),
            recurrence: persistRecurrence()
        )
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
