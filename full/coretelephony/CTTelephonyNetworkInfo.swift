import Foundation

/// Deprecated carrier snapshot. Linux has no baseband, so every identifier
/// is `nil` and `allowsVOIP` is `false`.
open class CTCarrier: NSObject {
    public override init() {
        super.init()
    }

    open var carrierName: String? { nil }
    open var mobileCountryCode: String? { nil }
    open var mobileNetworkCode: String? { nil }
    open var isoCountryCode: String? { nil }
    open var allowsVOIP: Bool { false }
}

/// Optional ObjC requirement is a real protocol member here so existential
/// dispatch reaches conformer overrides. The default is a no-op; Linux never
/// fabricates a data-service identifier change.
public protocol CTTelephonyNetworkInfoDelegate: NSObjectProtocol {
    func dataServiceIdentifierDidChange(_ identifier: String)
}

extension CTTelephonyNetworkInfoDelegate {
    public func dataServiceIdentifierDidChange(_ identifier: String) {
        _ = identifier
    }
}

/// Radio / subscriber provider queries are fail-closed (`nil`). Stored
/// notifiers and the weak delegate are never invoked with invented updates.
open class CTTelephonyNetworkInfo: NSObject {
    public override init() {
        super.init()
    }

    open var dataServiceIdentifier: String? { nil }

    public weak var delegate: (any CTTelephonyNetworkInfoDelegate)?

    open var serviceSubscriberCellularProviders: [String: CTCarrier]? { nil }

    open var subscriberCellularProvider: CTCarrier? { nil }

    open var serviceSubscriberCellularProvidersDidUpdateNotifier: ((String) -> Void)?

    open var subscriberCellularProviderDidUpdateNotifier: ((CTCarrier) -> Void)?

    open var serviceCurrentRadioAccessTechnology: [String: String]? { nil }

    open var currentRadioAccessTechnology: String? { nil }
}
