import Foundation

// MARK: - EventKit isolation stand-ins
//
// The isolated host gate compiles `EventKitUI` as a single Swift module. It
// does not link Apple `EventKit`. The public EventKitUI surface still names
// `EKEventStore`, `EKEvent`, `EKCalendar`, and `EKEntityType`, so this file
// provides process-local stand-ins of those types.
//
// These are not a Linux EventKit port. They do not read a calendar database,
// request TCC, or invent events. When a real `EventKit` module is on the
// link line, this file should be deleted and EventKitUI should import it.

/// Bridged `NS_ENUM(NSUInteger, EKEntityType)` from EventKit. Declaration
/// order is event, then reminder.
public enum EKEntityType: UInt, Hashable, Sendable {
    case event = 0
    case reminder = 1
}

/// Process-local calendar identity. Apple's `EKCalendar` is an EventKit
/// object backed by a store; this stand-in only carries a title and a
/// host-assigned identifier so `Set<EKCalendar>` and delegate default-calendar
/// callbacks type-check.
open class EKCalendar: NSObject, @unchecked Sendable {
    public var title: String
    public let calendarIdentifier: String
    public var isImmutable: Bool
    public var allowsContentModifications: Bool
    public var entityType: EKEntityType

    public init(
        title: String,
        calendarIdentifier: String,
        entityType: EKEntityType = .event,
        isImmutable: Bool = false,
        allowsContentModifications: Bool = true
    ) {
        self.title = title
        self.calendarIdentifier = calendarIdentifier
        self.entityType = entityType
        self.isImmutable = isImmutable
        self.allowsContentModifications = allowsContentModifications
        super.init()
    }

    @_spi(OpenUIKitHost)
    public static func hostCalendar(
        title: String,
        identifier: String,
        entityType: EKEntityType = .event,
        writable: Bool = true
    ) -> EKCalendar {
        EKCalendar(
            title: title,
            calendarIdentifier: identifier,
            entityType: entityType,
            isImmutable: !writable,
            allowsContentModifications: writable
        )
    }
}

/// Empty EventKit store handle. Linux never lists, creates, or saves
/// calendar items through this object.
open class EKEventStore: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }

    /// Always empty. A real EventKit store would consult the calendar
    /// database; this isolation stand-in does not invent calendars.
    open func calendars(for entityType: EKEntityType) -> [EKCalendar] {
        _ = entityType
        return []
    }

    /// Always empty. Same fail-closed rule as `calendars(for:)`.
    open var calendars: [EKCalendar] { [] }

    /// Always `nil`. Nothing is persisted, so nothing can be fetched.
    open func calendar(withIdentifier identifier: String) -> EKCalendar? {
        _ = identifier
        return nil
    }

    /// Always `nil`. Events are not materialized from a database.
    open func event(withIdentifier identifier: String) -> EKEvent? {
        _ = identifier
        return nil
    }

    /// Fail-closed: never writes. Returns `false` and does not throw an
    /// invented EventKit error domain (EventKit's save error codes are
    /// unobserved in this seed).
    open func save(_ event: EKEvent, span: EKSpan, commit: Bool) throws -> Bool {
        _ = (event, span, commit)
        return false
    }

    /// Fail-closed: never removes.
    open func remove(_ event: EKEvent, span: EKSpan, commit: Bool) throws -> Bool {
        _ = (event, span, commit)
        return false
    }
}

/// Bridged `NS_ENUM(NSInteger, EKSpan)` used by EventKit save/remove. Included
/// so the stand-in store API can be called without inventing EventKit's
/// broader surface.
public enum EKSpan: Int, Hashable, Sendable {
    case thisEvent = 0
    case futureEvents = 1
}

/// Process-local event object. Apple's `EKEvent(eventStore:)` is the public
/// initializer; this stand-in records the store pointer and a handful of
/// fields so EventKitUI controllers can hold an `EKEvent` without talking
/// to Calendar.
open class EKEvent: NSObject, @unchecked Sendable {
    public unowned(unsafe) let eventStore: EKEventStore
    public var title: String?
    public var notes: String?
    public var calendar: EKCalendar?
    public var startDate: Date?
    public var endDate: Date?
    public var isAllDay: Bool
    public var eventIdentifier: String?

    public init(eventStore: EKEventStore) {
        self.eventStore = eventStore
        self.isAllDay = false
        super.init()
    }

    /// Always `false`. Isolation never commits to a store.
    open var isDetached: Bool { false }

    /// Always `false`. Isolation never has a calendar database row.
    open var hasAlarms: Bool { false }

    /// Always `false`. Isolation never has recurrence.
    open var hasRecurrenceRules: Bool { false }
}
