import Foundation

/// Calendar-set picker. Apple's class inherits `UIViewController` and presents
/// a chooser UI; this Linux starting point is an `@MainActor` `NSObject` that
/// stores the public configuration and delivers delegate callbacks through
/// host SPI. It never presents UI, never reads `EKEventStore` calendars, and
/// never invents a selection from the (empty) store.
@available(iOS 4.0, *)
@MainActor
open class EKCalendarChooser: NSObject {
    private let _selectionStyle: EKCalendarChooserSelectionStyle
    private let _displayStyle: EKCalendarChooserDisplayStyle
    private let _entityType: EKEntityType
    private let _eventStore: EKEventStore
    private var _selectedCalendars: Set<EKCalendar>
    private var _showsDoneButton = false
    private var _showsCancelButton = false
    private weak var _delegate: (any EKCalendarChooserDelegate)?

    /// Equivalent to `init(selectionStyle:displayStyle:entityType:eventStore:)`
    /// with `entityType` `.event`, matching Apple's three-argument initializer.
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

    public init(
        selectionStyle style: EKCalendarChooserSelectionStyle,
        displayStyle: EKCalendarChooserDisplayStyle,
        entityType: EKEntityType,
        eventStore: EKEventStore
    ) {
        _selectionStyle = style
        _displayStyle = displayStyle
        _entityType = entityType
        _eventStore = eventStore
        _selectedCalendars = []
        super.init()
    }

    open var selectionStyle: EKCalendarChooserSelectionStyle { _selectionStyle }

    /// Stored display style. Linux does not filter a calendar list against
    /// `.writableCalendarsOnly` because the store is empty.
    open var displayStyle: EKCalendarChooserDisplayStyle { _displayStyle }

    /// Stored entity type. Linux does not query the store for matching
    /// calendars.
    open var entityType: EKEntityType { _entityType }

    /// The store passed at init. Isolation never reads it.
    open var eventStore: EKEventStore { _eventStore }

    open weak var delegate: (any EKCalendarChooserDelegate)? {
        get { _delegate }
        set { _delegate = newValue }
    }

    /// Public default is `false` (Apple: showsDoneButton defaults to NO).
    open var showsDoneButton: Bool {
        get { _showsDoneButton }
        set { _showsDoneButton = newValue }
    }

    /// Public default is `false` (Apple: showsCancelButton defaults to NO).
    open var showsCancelButton: Bool {
        get { _showsCancelButton }
        set { _showsCancelButton = newValue }
    }

    /// Copied on get and set. Isolation does not consult `selectionStyle` to
    /// truncate a multi-calendar assignment: Apple's UI would not offer that
    /// path, and silently dropping calendars would invent a selection.
    open var selectedCalendars: Set<EKCalendar> {
        get { _selectedCalendars }
        set { _selectedCalendars = newValue }
    }

    // MARK: Host SPI
    //
    // These methods stand in for user gestures the Linux host cannot present.
    // They are not Apple API. Ordinary `import EventKitUI` clients do not see
    // them.

    /// Assigns `calendars` and, when the set identity changes, calls
    /// `calendarChooserSelectionDidChange`.
    @_spi(OpenUIKitHost)
    public func hostSelectCalendars(_ calendars: Set<EKCalendar>) {
        let previous = _selectedCalendars
        _selectedCalendars = calendars
        if previous != calendars {
            _delegate?.calendarChooserSelectionDidChange(self)
        }
    }

    /// Stands in for the Done control. Does not mutate `selectedCalendars`.
    @_spi(OpenUIKitHost)
    public func hostFinish() {
        _delegate?.calendarChooserDidFinish(self)
    }

    /// Stands in for the Cancel control. Does not clear `selectedCalendars`.
    @_spi(OpenUIKitHost)
    public func hostCancel() {
        _delegate?.calendarChooserDidCancel(self)
    }
}

/// Chooser delegate. Apple's protocol inherits `NSObjectProtocol` and marks
/// every method `@objc optional`. Linux models optionality with empty
/// default implementations instead of the Objective-C runtime.
public protocol EKCalendarChooserDelegate: NSObjectProtocol {
    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser)
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser)
    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser)
}

extension EKCalendarChooserDelegate {
    public func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        _ = calendarChooser
    }

    public func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        _ = calendarChooser
    }

    public func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        _ = calendarChooser
    }
}
