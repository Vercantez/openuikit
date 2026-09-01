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

/// App cellular-data restriction probe. Linux has no WWAN preference pane,
/// so `restrictedState` stays `.restrictedStateUnknown` and the notifier is
/// stored but never invoked.
open class CTCellularData: NSObject {
    public override init() {
        super.init()
    }

    open var cellularDataRestrictionDidUpdateNotifier: CellularDataRestrictionDidUpdateNotifier?

    /// Always unknown: this host cannot observe Apple's cellular restriction.
    open var restrictedState: CTCellularDataRestrictedState { .restrictedStateUnknown }
}
