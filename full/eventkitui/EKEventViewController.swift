import Foundation

/// Event inspector. Apple's class inherits `UIViewController` and presents
/// the system event UI; this Linux starting point stores the public
/// configuration and delivers the required delegate completion through host
/// SPI. It never presents a calendar preview, never opens an editor, and
/// never writes through EventKit.
@available(iOS 4.0, *)
@MainActor
open class EKEventViewController: NSObject {
    private weak var _delegate: (any EKEventViewDelegate)?
    private var _event: EKEvent?
    private var _allowsEditing = false
    private var _allowsCalendarPreview = false

    public override init() {
        super.init()
    }

    @available(iOS 4.2, *)
    open weak var delegate: (any EKEventViewDelegate)? {
        get { _delegate }
        set { _delegate = newValue }
    }

    /// Apple's property is an IUO (`EKEvent!`). Isolation stores an optional
    /// and surfaces it as IUO. Reading before assignment yields `nil`.
    open var event: EKEvent! {
        get { _event }
        set { _event = newValue }
    }

    /// Public default is `false`. Apple's documentation records the Darwin
    /// default as NO; Linux also fail-closes so callers cannot treat editing
    /// as available.
    open var allowsEditing: Bool {
        get { _allowsEditing }
        set { _allowsEditing = newValue }
    }

    /// Linux default is `false` (fail-closed: no calendar month view).
    /// Apple's documentation records YES as the Darwin default; that runtime
    /// default is an oracle question and is not copied here, because there
    /// is no calendar preview to show.
    open var allowsCalendarPreview: Bool {
        get { _allowsCalendarPreview }
        set { _allowsCalendarPreview = newValue }
    }

    /// Stands in for the Darwin Done / Delete / Responded dismissal. Does not
    /// mutate the event or the store.
    @_spi(OpenUIKitHost)
    public func hostComplete(with action: EKEventViewAction) {
        _delegate?.eventViewController(self, didCompleteWith: action)
    }
}

/// Event-view delegate. `eventViewController(_:didCompleteWith:)` is required
/// on Apple; the optional-method pattern is not used here.
public protocol EKEventViewDelegate: NSObjectProtocol {
    func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction)
}
