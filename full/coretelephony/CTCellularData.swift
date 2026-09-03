import Foundation

/// Linux has no cellular-data restriction daemon. `restrictedState` is
/// always `.restrictedStateUnknown`. Assigning a non-nil notifier for the
/// first time asynchronously delivers that honest state exactly once; later
/// baseband updates are never fabricated.
open class CTCellularData: NSObject {
    private var notifier: CellularDataRestrictionDidUpdateNotifier?

    public override init() {
        super.init()
    }

    open var restrictedState: CTCellularDataRestrictedState {
        .restrictedStateUnknown
    }

    open var cellularDataRestrictionDidUpdateNotifier:
        CellularDataRestrictionDidUpdateNotifier?
    {
        get { notifier }
        set {
            let isFirstNonNilAssignment = notifier == nil && newValue != nil
            notifier = newValue
            if isFirstNonNilAssignment, let handler = newValue {
                coreTelephonyHop {
                    handler(.restrictedStateUnknown)
                }
            }
        }
    }
}
