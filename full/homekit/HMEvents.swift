import Foundation

open class HMEvent: NSObject {
    public let uniqueIdentifier: UUID

    public override init() {
        self.uniqueIdentifier = UUID()
        super.init()
    }

    public class func `new`() -> HMEvent {
        HMEvent()
    }

    open class func isSupported(for home: HMHome) -> Bool {
        _ = home
        return false
    }
}

open class HMTimeEvent: HMEvent {}

open class HMDurationEvent: HMTimeEvent {
    var storedDuration: TimeInterval

    public var duration: TimeInterval { storedDuration }

    public init(duration: TimeInterval) {
        self.storedDuration = duration
        super.init()
    }
}

open class HMMutableDurationEvent: HMDurationEvent {
    public override var duration: TimeInterval {
        get { storedDuration }
        set { storedDuration = newValue }
    }
}

open class HMCalendarEvent: HMTimeEvent {
    var storedFireDateComponents: DateComponents

    public var fireDateComponents: DateComponents { storedFireDateComponents }

    public init(fireDateComponents: DateComponents) {
        self.storedFireDateComponents = fireDateComponents
        super.init()
    }

    public convenience init(fire fireDateComponents: DateComponents) {
        self.init(fireDateComponents: fireDateComponents)
    }
}

open class HMMutableCalendarEvent: HMCalendarEvent {
    public override var fireDateComponents: DateComponents {
        get { storedFireDateComponents }
        set { storedFireDateComponents = newValue }
    }
}

open class HMPresenceEvent: HMEvent {
    var storedPresenceEventType: HMPresenceEventType
    var storedPresenceUserType: HMPresenceEventUserType

    public var presenceEventType: HMPresenceEventType { storedPresenceEventType }
    public var presenceUserType: HMPresenceEventUserType { storedPresenceUserType }

    public init(presenceEventType: HMPresenceEventType, presenceUserType: HMPresenceEventUserType) {
        self.storedPresenceEventType = presenceEventType
        self.storedPresenceUserType = presenceUserType
        super.init()
    }
}

open class HMMutablePresenceEvent: HMPresenceEvent {
    public override var presenceEventType: HMPresenceEventType {
        get { storedPresenceEventType }
        set { storedPresenceEventType = newValue }
    }

    public override var presenceUserType: HMPresenceEventUserType {
        get { storedPresenceUserType }
        set { storedPresenceUserType = newValue }
    }
}

open class HMSignificantTimeEvent: HMTimeEvent {
    var storedSignificantEvent: HMSignificantEvent
    var storedOffset: DateComponents?

    public var significantEvent: HMSignificantEvent { storedSignificantEvent }
    public var offset: DateComponents? { storedOffset }

    public init(significantEvent: HMSignificantEvent, offset: DateComponents?) {
        self.storedSignificantEvent = significantEvent
        self.storedOffset = offset
        super.init()
    }
}

open class HMMutableSignificantTimeEvent: HMSignificantTimeEvent {
    public override var significantEvent: HMSignificantEvent {
        get { storedSignificantEvent }
        set { storedSignificantEvent = newValue }
    }

    public override var offset: DateComponents? {
        get { storedOffset }
        set { storedOffset = newValue }
    }
}

open class HMLocationEvent: HMEvent {
    // CLRegion APIs are unavailable (CoreLocation is not a declared dependency).
}

open class HMMutableLocationEvent: HMLocationEvent {}

open class HMCharacteristicEvent<TriggerValueType: NSCopying>: HMEvent {
    var storedCharacteristic: HMCharacteristic
    var storedTriggerValue: TriggerValueType?

    public var characteristic: HMCharacteristic { storedCharacteristic }
    public var triggerValue: TriggerValueType? { storedTriggerValue }

    public init(characteristic: HMCharacteristic, triggerValue: TriggerValueType?) {
        self.storedCharacteristic = characteristic
        self.storedTriggerValue = triggerValue
        super.init()
    }

    public func updateTriggerValue(
        _ triggerValue: TriggerValueType?,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        completion(HMFailClosed(.operationNotSupported))
    }
}

open class HMMutableCharacteristicEvent<TriggerValueType: NSCopying>: HMCharacteristicEvent<TriggerValueType> {
    public override var characteristic: HMCharacteristic {
        get { storedCharacteristic }
        set { storedCharacteristic = newValue }
    }

    public override var triggerValue: TriggerValueType? {
        get { storedTriggerValue }
        set { storedTriggerValue = newValue }
    }
}

open class HMCharacteristicThresholdRangeEvent: HMEvent {
    var storedCharacteristic: HMCharacteristic
    var storedThresholdRange: HMNumberRange

    public var characteristic: HMCharacteristic { storedCharacteristic }
    public var thresholdRange: HMNumberRange { storedThresholdRange }

    public init(characteristic: HMCharacteristic, thresholdRange: HMNumberRange) {
        self.storedCharacteristic = characteristic
        self.storedThresholdRange = thresholdRange
        super.init()
    }
}

open class HMMutableCharacteristicThresholdRangeEvent: HMCharacteristicThresholdRangeEvent {
    public override var characteristic: HMCharacteristic {
        get { storedCharacteristic }
        set { storedCharacteristic = newValue }
    }

    public override var thresholdRange: HMNumberRange {
        get { storedThresholdRange }
        set { storedThresholdRange = newValue }
    }
}

open class HMAction: NSObject {
    public let uniqueIdentifier: UUID = UUID()

    public class func `new`() -> HMAction {
        HMAction()
    }
}

open class HMCharacteristicWriteAction<TargetValueType: NSCopying>: HMAction {
    public private(set) var characteristic: HMCharacteristic
    public private(set) var targetValue: TargetValueType

    public init(characteristic: HMCharacteristic, targetValue: TargetValueType) {
        self.characteristic = characteristic
        self.targetValue = targetValue
        super.init()
    }

    public func updateTargetValue(_ targetValue: TargetValueType) async throws {
        throw HMFailClosed(.operationNotSupported)
    }
}

open class HMTrigger: NSObject {
    public internal(set) var name: String
    public internal(set) var isEnabled: Bool
    public internal(set) var actionSets: [HMActionSet]
    public internal(set) var lastFireDate: Date?
    public let uniqueIdentifier: UUID

    public override init() {
        self.name = ""
        self.isEnabled = false
        self.actionSets = []
        self.lastFireDate = nil
        self.uniqueIdentifier = UUID()
        super.init()
    }

    public func enable(_ enable: Bool) async throws {
        throw HMFailClosed()
    }

    public func updateName(_ name: String) async throws {
        throw HMFailClosed()
    }

    public func addActionSet(_ actionSet: HMActionSet) async throws {
        _ = actionSet
        throw HMFailClosed()
    }

    public func removeActionSet(_ actionSet: HMActionSet) async throws {
        _ = actionSet
        throw HMFailClosed()
    }
}

open class HMTimerTrigger: HMTrigger {
    public internal(set) var fireDate: Date
    public internal(set) var timeZone: TimeZone?
    public internal(set) var recurrence: DateComponents?
    public internal(set) var recurrenceCalendar: Calendar?

    public init(name: String, fireDate: Date, recurrence: DateComponents?) {
        self.fireDate = fireDate
        self.timeZone = nil
        self.recurrence = recurrence
        self.recurrenceCalendar = nil
        super.init()
        self.name = name
    }

    public init(
        name: String,
        fireDate: Date,
        timeZone: TimeZone?,
        recurrence: DateComponents?,
        recurrenceCalendar: Calendar?
    ) {
        self.fireDate = fireDate
        self.timeZone = timeZone
        self.recurrence = recurrence
        self.recurrenceCalendar = recurrenceCalendar
        super.init()
        self.name = name
    }

    public func updateFireDate(_ fireDate: Date) async throws {
        _ = fireDate
        throw HMFailClosed()
    }

    public func updateRecurrence(_ recurrence: DateComponents?) async throws {
        _ = recurrence
        throw HMFailClosed()
    }

    public func updateTimeZone(_ timeZone: TimeZone?) async throws {
        _ = timeZone
        throw HMFailClosed()
    }
}

open class HMEventTrigger: HMTrigger {
    public internal(set) var events: [HMEvent]
    public internal(set) var endEvents: [HMEvent]
    public internal(set) var recurrences: [DateComponents]?
    public internal(set) var predicate: NSPredicate?
    public internal(set) var executeOnce: Bool
    public internal(set) var triggerActivationState: HMEventTriggerActivationState

    public init(name: String, events: [HMEvent], predicate: NSPredicate?) {
        self.events = events
        self.endEvents = []
        self.recurrences = nil
        self.predicate = predicate
        self.executeOnce = false
        self.triggerActivationState = .disabledNoHomeHub
        super.init()
        self.name = name
    }

    public init(
        name: String,
        events: [HMEvent],
        end endEvents: [HMEvent]?,
        recurrences: [DateComponents]?,
        predicate: NSPredicate?
    ) {
        self.events = events
        self.endEvents = endEvents ?? []
        self.recurrences = recurrences
        self.predicate = predicate
        self.executeOnce = false
        self.triggerActivationState = .disabledNoHomeHub
        super.init()
        self.name = name
    }

    public init(
        name: String,
        events: [HMEvent],
        endEvents: [HMEvent]?,
        recurrences: [DateComponents]?,
        predicate: NSPredicate?
    ) {
        self.events = events
        self.endEvents = endEvents ?? []
        self.recurrences = recurrences
        self.predicate = predicate
        self.executeOnce = false
        self.triggerActivationState = .disabledNoHomeHub
        super.init()
        self.name = name
    }

    public func addEvent(_ event: HMEvent, completionHandler completion: @escaping ((any Error)?) -> Void) {
        _ = event
        completion(HMFailClosed())
    }

    public func removeEvent(_ event: HMEvent, completionHandler completion: @escaping ((any Error)?) -> Void) {
        _ = event
        completion(HMFailClosed())
    }

    public func updateEvents(_ events: [HMEvent]) async throws {
        _ = events
        throw HMFailClosed()
    }

    public func updateEndEvents(_ endEvents: [HMEvent]) async throws {
        _ = endEvents
        throw HMFailClosed()
    }

    public func updatePredicate(_ predicate: NSPredicate?) async throws {
        _ = predicate
        throw HMFailClosed()
    }

    public func updateRecurrences(_ recurrences: [DateComponents]?) async throws {
        _ = recurrences
        throw HMFailClosed()
    }

    public func updateExecuteOnce(_ executeOnce: Bool) async throws {
        _ = executeOnce
        throw HMFailClosed()
    }

    open class func predicateForEvaluatingTrigger(occurringAfter dateComponents: DateComponents) -> NSPredicate {
        let captured = dateComponents
        return NSPredicate { _, _ in captured.hour != nil || captured.minute != nil }
    }

    open class func predicateForEvaluatingTrigger(occurringBefore dateComponents: DateComponents) -> NSPredicate {
        let captured = dateComponents
        return NSPredicate { _, _ in captured.hour != nil || captured.minute != nil }
    }

    open class func predicateForEvaluatingTrigger(occurringOn dateComponents: DateComponents) -> NSPredicate {
        let captured = dateComponents
        return NSPredicate { _, _ in captured.hour != nil || captured.day != nil }
    }

    open class func predicateForEvaluatingTriggerOccurringBetweenDate(
        with firstDateComponents: DateComponents,
        secondDateWith secondDateWithComponents: DateComponents
    ) -> NSPredicate {
        _ = (firstDateComponents, secondDateWithComponents)
        return NSPredicate { _, _ in true }
    }

    open class func predicateForEvaluatingTrigger(
        occurringAfter significantEvent: String,
        applyingOffset offset: DateComponents?
    ) -> NSPredicate {
        _ = (significantEvent, offset)
        return NSPredicate { _, _ in true }
    }

    open class func predicateForEvaluatingTrigger(
        occurringBefore significantEvent: String,
        applyingOffset offset: DateComponents?
    ) -> NSPredicate {
        _ = (significantEvent, offset)
        return NSPredicate { _, _ in true }
    }

    open class func predicateForEvaluatingTriggerOccurring(
        afterSignificantEvent significantEvent: HMSignificantTimeEvent
    ) -> NSPredicate {
        _ = significantEvent
        return NSPredicate { _, _ in true }
    }

    open class func predicateForEvaluatingTriggerOccurring(
        beforeSignificantEvent significantEvent: HMSignificantTimeEvent
    ) -> NSPredicate {
        _ = significantEvent
        return NSPredicate { _, _ in true }
    }

    open class func predicate(
        forEvaluatingTriggerOccurringBetweenSignificantEvent firstSignificantEvent: HMSignificantTimeEvent,
        secondSignificantEvent: HMSignificantTimeEvent
    ) -> NSPredicate {
        _ = (firstSignificantEvent, secondSignificantEvent)
        return NSPredicate { _, _ in true }
    }

    open class func predicateForEvaluatingTrigger(withPresence presenceEvent: HMPresenceEvent) -> NSPredicate {
        let captured = presenceEvent.presenceEventType
        return NSPredicate { _, _ in captured == .atHome || captured == .firstEntry || true }
    }
}

open class HMNumberRange: NSObject {
    public let minValue: NSNumber?
    public let maxValue: NSNumber?

    public convenience init(minValue: NSNumber, maxValue: NSNumber) {
        self.init(minimum: minValue, maximum: maxValue)
    }

    public convenience init(minValue: NSNumber) {
        self.init(minimum: minValue, maximum: nil)
    }

    public convenience init(maxValue: NSNumber) {
        self.init(minimum: nil, maximum: maxValue)
    }

    private init(minimum: NSNumber?, maximum: NSNumber?) {
        self.minValue = minimum
        self.maxValue = maximum
        super.init()
    }

    public func contains(_ value: NSNumber) -> Bool {
        if let minValue, value.compare(minValue) == .orderedAscending { return false }
        if let maxValue, value.compare(maxValue) == .orderedDescending { return false }
        return true
    }
}
