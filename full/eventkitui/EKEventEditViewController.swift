import Foundation

/// Event editor. Apple's class inherits `UINavigationController` and presents
/// the system compose/edit sheet; this Linux starting point stores the public
/// configuration, implements `cancelEditing()`, and delivers the required
/// delegate completion through that method and host SPI. It never presents
/// UI and never saves or deletes through EventKit.
@available(iOS 4.0, *)
@MainActor
open class EKEventEditViewController: NSObject {
    private weak var _editViewDelegate: (any EKEventEditViewDelegate)?
    private var _eventStore: EKEventStore?
    private var _event: EKEvent?
    private var _editingCancelled = false

    public override init() {
        super.init()
    }

    open weak var editViewDelegate: (any EKEventEditViewDelegate)? {
        get { _editViewDelegate }
        set { _editViewDelegate = newValue }
    }

    /// Apple's property is an IUO (`EKEventStore!`). Isolation stores an
    /// optional and surfaces it as IUO.
    open var eventStore: EKEventStore! {
        get { _eventStore }
        set { _eventStore = newValue }
    }

    open var event: EKEvent? {
        get { _event }
        set {
            _event = newValue
            _editingCancelled = false
        }
    }

    /// Dismisses the editor without saving. Isolation notifies
    /// `editViewDelegate` with `.canceled` (the American-spelling case, which
    /// is identical to `.cancelled`) each time this is called. Whether Darwin
    /// also calls the delegate, and whether it calls it more than once, is an
    /// oracle question; Linux needs a testable fail-closed path so the
    /// required delegate method can be exercised.
    open func cancelEditing() {
        _editingCancelled = true
        _editViewDelegate?.eventEditViewController(self, didCompleteWith: .canceled)
    }

    /// True after `cancelEditing()` until `event` is reassigned. Not Apple API.
    @_spi(OpenUIKitHost)
    public var hostEditingCancelled: Bool { _editingCancelled }

    /// Stands in for Saved / Deleted / Canceled dismissal from the editor UI.
    /// Isolation still does not write through `eventStore`. A `.saved` action
    /// does not call `EKEventStore.save`.
    @_spi(OpenUIKitHost)
    public func hostComplete(with action: EKEventEditViewAction) {
        if action == .canceled || action == .cancelled {
            _editingCancelled = true
        }
        _editViewDelegate?.eventEditViewController(self, didCompleteWith: action)
    }

    /// Forwards the optional default-calendar probe. Returns `nil` when the
    /// delegate omits the method or returns no calendar. Isolation never
    /// falls back to an invented EventKit default calendar.
    @_spi(OpenUIKitHost)
    public func hostDefaultCalendarForNewEvents() -> EKCalendar? {
        _editViewDelegate?.eventEditViewControllerDefaultCalendar(forNewEvents: self)
    }
}

/// Editor delegate. `eventEditViewController(_:didCompleteWith:)` is required.
/// `eventEditViewControllerDefaultCalendar(forNewEvents:)` is optional on
/// Apple and has a default implementation here that returns `nil`.
public protocol EKEventEditViewDelegate: NSObjectProtocol {
    func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    )

    func eventEditViewControllerDefaultCalendar(forNewEvents controller: EKEventEditViewController) -> EKCalendar
}

extension EKEventEditViewDelegate {
    public func eventEditViewControllerDefaultCalendar(
        forNewEvents controller: EKEventEditViewController
    ) -> EKCalendar {
        _ = controller
        // Apple's method is optional and non-optional-returning. When the
        // client omits it, Darwin uses the event store's default calendar.
        // Isolation has no store default, so this Swift default returns a
        // shared inert marker (immutable, not writable) rather than a
        // fabricated EventKit calendar. Clients that care implement the
        // method themselves.
        return EventKitUIInertDefaultCalendar.calendar
    }
}

/// Shared inert calendar used only as the optional-method default. It is not
/// an EventKit default calendar and is never saved.
enum EventKitUIInertDefaultCalendar {
    static let identifier = "eventkitui.inert-default-calendar"
    static let calendar = EKCalendar(
        title: "",
        calendarIdentifier: identifier,
        entityType: .event,
        isImmutable: true,
        allowsContentModifications: false
    )
}
