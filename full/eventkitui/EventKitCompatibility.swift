#if canImport(EventKit)
@_exported import EventKit
#else
import Foundation

// EventKit is a declared dependency of EventKitUI but is not on the isolated
// fan-out compiler search path. These types exist only so EventKitUI's public
// signatures can compile and be exercised. They are in-memory placeholders:
// they do not read the host calendar database, request privacy permission, or
// persist events. When a real EventKit module is linked, this file is a
// re-export and these placeholders are not compiled.

public enum EKEntityType: UInt, Hashable, Sendable {
    case event = 0
    case reminder = 1
}

open class EKEventStore: NSObject {
    public let eventStoreIdentifier: String

    public override init() {
        self.eventStoreIdentifier = UUID().uuidString
        super.init()
    }
}

open class EKCalendar: NSObject {
    public let calendarIdentifier: String
    public var title: String
    public private(set) var allowsContentModifications: Bool
    public let entityType: EKEntityType
    public private(set) weak var eventStore: EKEventStore?

    public init(for entityType: EKEntityType, eventStore: EKEventStore) {
        self.calendarIdentifier = UUID().uuidString
        self.title = ""
        self.allowsContentModifications = true
        self.entityType = entityType
        self.eventStore = eventStore
        super.init()
    }

    public convenience init(forEntityType entityType: EKEntityType, eventStore: EKEventStore) {
        self.init(for: entityType, eventStore: eventStore)
    }

    @_spi(OpenUIKitHost)
    public func setAllowsContentModifications(_ value: Bool) {
        allowsContentModifications = value
    }

    open override var hash: Int {
        calendarIdentifier.hashValue
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? EKCalendar else { return false }
        return calendarIdentifier == other.calendarIdentifier
    }
}

open class EKEvent: NSObject {
    public private(set) var eventStore: EKEventStore
    public var eventIdentifier: String!
    public var title: String = ""
    public var startDate: Date!
    public var endDate: Date!
    public var calendar: EKCalendar?
    public var isAllDay = false

    public init(eventStore: EKEventStore) {
        self.eventStore = eventStore
        self.eventIdentifier = UUID().uuidString
        super.init()
    }
}
#endif
