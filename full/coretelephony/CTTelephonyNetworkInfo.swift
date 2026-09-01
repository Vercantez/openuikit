import Foundation

/// Optional radio-service callbacks. The method is optional on Apple via ObjC;
/// Linux supplies an empty default because there is no `@objc` optional.
public protocol CTTelephonyNetworkInfoDelegate: NSObjectProtocol {
    func dataServiceIdentifierDidChange(_ identifier: String)
}

extension CTTelephonyNetworkInfoDelegate {
    public func dataServiceIdentifierDidChange(_ identifier: String) {}
}

/// Radio and subscriber-provider snapshot. Linux has no cellular interface,
/// so every radio/provider query returns `nil` and notifiers never fire.
open class CTTelephonyNetworkInfo: NSObject {
    public override init() {
        super.init()
    }

    /// Identifier of the current data service. `nil` without cellular service.
    open var dataServiceIdentifier: String? { nil }

    open weak var delegate: (any CTTelephonyNetworkInfoDelegate)?

    /// Per-service carrier map. `nil` when no providers exist.
    open var serviceSubscriberCellularProviders: [String: CTCarrier]? { nil }

    /// Primary carrier. `nil` when no provider exists.
    open var subscriberCellularProvider: CTCarrier? { nil }

    /// Invoked by Apple when a service's carrier changes. Never invoked here.
    open var serviceSubscriberCellularProvidersDidUpdateNotifier: ((String) -> Void)?

    /// Invoked by Apple when the primary carrier changes. Never invoked here.
    open var subscriberCellularProviderDidUpdateNotifier: ((CTCarrier) -> Void)?

    /// Per-service radio access technology. `nil` without a radio.
    open var serviceCurrentRadioAccessTechnology: [String: String]? { nil }

    /// Primary radio access technology. `nil` without a radio.
    open var currentRadioAccessTechnology: String? { nil }
}
