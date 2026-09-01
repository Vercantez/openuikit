import Dispatch
import Foundation

/// Restriction state for the app's cellular data preference.
public enum CTCellularDataRestrictedState: UInt, Sendable {
    case restrictedStateUnknown = 0
    case restricted = 1
    case notRestricted = 2
}

/// Callback invoked when `CTCellularData.restrictedState` changes.
public typealias CellularDataRestrictionDidUpdateNotifier =
    (CTCellularDataRestrictedState) -> Void

/// Holds an ObjC-style notifier so the first assignment can hop threads.
private final class CTCellularDataNotifierBox: @unchecked Sendable {
    let handler: CellularDataRestrictionDidUpdateNotifier

    init(_ handler: @escaping CellularDataRestrictionDidUpdateNotifier) {
        self.handler = handler
    }
}

/// App cellular-data restriction probe. Linux has no WWAN preference pane,
/// so `restrictedState` stays `.restrictedStateUnknown`.
///
/// Apple's header documents that assigning the notifier also delivers the
/// current value. This port does that **exactly once**, asynchronously, with
/// the honest Linux state `.restrictedStateUnknown`. Later assignments do not
/// fabricate restriction changes.
open class CTCellularData: NSObject {
    private let lock = NSLock()
    private var storedNotifier: CellularDataRestrictionDidUpdateNotifier?
    private var didScheduleInitialCallback = false

    public override init() {
        super.init()
    }

    open var cellularDataRestrictionDidUpdateNotifier: CellularDataRestrictionDidUpdateNotifier? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedNotifier
        }
        set {
            let pending: CellularDataRestrictionDidUpdateNotifier?
            lock.lock()
            storedNotifier = newValue
            if !didScheduleInitialCallback, let handler = newValue {
                didScheduleInitialCallback = true
                pending = handler
            } else {
                pending = nil
            }
            lock.unlock()
            if let pending {
                let box = CTCellularDataNotifierBox(pending)
                DispatchQueue.global().async {
                    box.handler(.restrictedStateUnknown)
                }
            }
        }
    }

    /// Always unknown: this host cannot observe Apple's cellular restriction.
    open var restrictedState: CTCellularDataRestrictedState { .restrictedStateUnknown }
}
