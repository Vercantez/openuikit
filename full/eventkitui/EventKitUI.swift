@_exported import Foundation

/// Linux presentation capability for EventKitUI controllers. Apple's Calendar
/// sheets are not available; hosts may drive Done/Cancel themselves.
public enum EKUIPresentationCapability: Int, Hashable, Sendable {
    case unavailable = 0
    case hostDriven = 1
}

/// Fail-closed errors for Calendar UI paths that would require Apple's event
/// store, entitlements, or system sheet.
public struct EKUIError: Error, Equatable, Hashable, Sendable {
    public enum Code: Int, Hashable, Sendable {
        case calendarUIUnavailable = 1
        case eventMissing = 2
        case invitationResponseUnavailable = 3
        case eventDeletionUnavailable = 4
    }

    public let code: Code

    public init(_ code: Code) {
        self.code = code
    }
}

#if os(iOS)
public var EKUI_IS_IOS: Int32 { 1 }
#else
public var EKUI_IS_IOS: Int32 { 0 }
#endif

#if targetEnvironment(simulator)
public var EKUI_IS_SIMULATOR: Int32 { 1 }
#else
public var EKUI_IS_SIMULATOR: Int32 { 0 }
#endif

/// Linux has no `EventKitUI.framework` resource bundle. Returning `nil` is
/// fail-closed: `Bundle(for:)` crashes in this Foundation overlay, and
/// `Bundle.main` would misidentify the process executable as EventKitUI.
public func EventKitUIBundle() -> Bundle! {
    nil
}

public enum EKCalendarChooserDisplayStyle: Int, Hashable, Sendable {
    case allCalendars = 0
    case writableCalendarsOnly = 1
}

public enum EKCalendarChooserSelectionStyle: Int, Hashable, Sendable {
    case single = 0
    case multiple = 1
}

public enum EKEventEditViewAction: Int, Hashable, Sendable {
    case canceled = 0
    case saved = 1
    case deleted = 2

    public static var cancelled: EKEventEditViewAction { .canceled }
}

public enum EKEventViewAction: Int, Hashable, Sendable {
    case done = 0
    case responded = 1
    case deleted = 2
}

@MainActor
public protocol EKCalendarChooserDelegate: NSObjectProtocol {
    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser)
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser)
    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser)
}

extension EKCalendarChooserDelegate {
    public func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {}
    public func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {}
    public func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {}
}

@MainActor
public protocol EKEventEditViewDelegate: NSObjectProtocol {
    func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    )
    /// Optional on Apple via Objective-C. This overlay keeps the Apple
    /// return type; Swift conformers that present a new-event editor must
    /// supply an in-memory calendar. There is no EventKit default calendar.
    func eventEditViewControllerDefaultCalendar(
        forNewEvents controller: EKEventEditViewController
    ) -> EKCalendar
}

@MainActor
public protocol EKEventViewDelegate: NSObjectProtocol {
    func eventViewController(
        _ controller: EKEventViewController,
        didCompleteWith action: EKEventViewAction
    )
}

/// Isolated compile has no UIKit module. Controllers inherit `NSObject` here;
/// UIViewController / UINavigationController subclassing waits for UIKit linkage.
@MainActor
open class EKCalendarChooser: NSObject {
    public static let presentationCapability: EKUIPresentationCapability = .hostDriven

    public let selectionStyle: EKCalendarChooserSelectionStyle
    public let displayStyle: EKCalendarChooserDisplayStyle
    public let entityType: EKEntityType
    public let eventStore: EKEventStore

    open weak var delegate: (any EKCalendarChooserDelegate)?
    open var showsDoneButton = false
    open var showsCancelButton = false

    private var storedCalendars: Set<EKCalendar> = []

    public init(
        selectionStyle style: EKCalendarChooserSelectionStyle,
        displayStyle: EKCalendarChooserDisplayStyle,
        entityType: EKEntityType,
        eventStore: EKEventStore
    ) {
        self.selectionStyle = style
        self.displayStyle = displayStyle
        self.entityType = entityType
        self.eventStore = eventStore
        super.init()
    }

    public convenience init(
        selectionStyle: EKCalendarChooserSelectionStyle,
        displayStyle: EKCalendarChooserDisplayStyle,
        eventStore: EKEventStore
    ) {
        self.init(
            selectionStyle: selectionStyle,
            displayStyle: displayStyle,
            entityType: .event,
            eventStore: eventStore
        )
    }

    open var selectedCalendars: Set<EKCalendar> {
        get { storedCalendars }
        set {
            let next = Self.normalizedSelection(
                newValue,
                selectionStyle: selectionStyle,
                displayStyle: displayStyle
            )
            let changed = next != storedCalendars
            storedCalendars = next
            if changed {
                delegate?.calendarChooserSelectionDidChange(self)
            }
        }
    }

    /// Host action for the chooser's Done control. Selection is in-memory only.
    open func finish() {
        delegate?.calendarChooserDidFinish(self)
    }

    /// Host action for the chooser's Cancel control.
    open func cancel() {
        delegate?.calendarChooserDidCancel(self)
    }

    static func normalizedSelection(
        _ calendars: Set<EKCalendar>,
        selectionStyle: EKCalendarChooserSelectionStyle,
        displayStyle: EKCalendarChooserDisplayStyle
    ) -> Set<EKCalendar> {
        var next = calendars
        if displayStyle == .writableCalendarsOnly {
            next = Set(next.filter(\.allowsContentModifications))
        }
        if selectionStyle == .single, next.count > 1 {
            if let kept = next.sorted(by: { $0.calendarIdentifier < $1.calendarIdentifier }).first {
                next = [kept]
            }
        }
        return next
    }
}

@MainActor
open class EKEventViewController: NSObject {
    public static let presentationCapability: EKUIPresentationCapability = .hostDriven

    open weak var delegate: (any EKEventViewDelegate)?
    open var event: EKEvent!
    open var allowsEditing = false
    open var allowsCalendarPreview = false

    public override init() {
        super.init()
    }

    /// Host action for dismissing the viewer. Does not mutate EventKit.
    open func finish() {
        delegate?.eventViewController(self, didCompleteWith: .done)
    }

    /// Invitation replies require Apple Calendar. Always fail closed.
    open func respondToInvitation() throws {
        throw EKUIError(.invitationResponseUnavailable)
    }

    /// Deleting an event requires Apple Calendar persistence. Always fail closed.
    open func deleteEvent() throws {
        throw EKUIError(.eventDeletionUnavailable)
    }
}

@MainActor
open class EKEventEditViewController: NSObject {
    public static let presentationCapability: EKUIPresentationCapability = .hostDriven

    open weak var editViewDelegate: (any EKEventEditViewDelegate)?
    open var eventStore: EKEventStore!
    open var event: EKEvent?

    public override init() {
        super.init()
    }

    /// Apple's cancel path: dismiss without claiming a store mutation.
    open func cancelEditing() {
        editViewDelegate?.eventEditViewController(self, didCompleteWith: .canceled)
    }

    /// Saving would persist through EventKit. Linux has no Calendar store write.
    open func saveEditing() throws {
        throw EKUIError(.calendarUIUnavailable)
    }

    /// Deleting would persist through EventKit. Linux has no Calendar store write.
    open func deleteEditing() throws {
        throw EKUIError(.eventDeletionUnavailable)
    }

    open func defaultCalendarForNewEvents() -> EKCalendar? {
        editViewDelegate?.eventEditViewControllerDefaultCalendar(forNewEvents: self)
    }
}
