import CoreTelephony
import Foundation

private final class NetworkDelegateProbe: NSObject, CTTelephonyNetworkInfoDelegate {
    var seen: String?
    func dataServiceIdentifierDidChange(_ identifier: String) {
        seen = identifier
    }
}

func testNetworkInfoFailClosedQueries() {
    let info = CTTelephonyNetworkInfo()
    precondition(info.dataServiceIdentifier == nil)
    precondition(info.subscriberCellularProvider == nil)
    precondition(info.serviceSubscriberCellularProviders == nil)
    precondition(info.currentRadioAccessTechnology == nil)
    precondition(info.serviceCurrentRadioAccessTechnology == nil)
    precondition(info.currentRadioAccessTechnology != CTRadioAccessTechnologyLTE)
}

func testNetworkInfoNotifiersAndDelegate() {
    let info = CTTelephonyNetworkInfo()
    var providerFired = false
    var serviceFired = false
    info.subscriberCellularProviderDidUpdateNotifier = { _ in providerFired = true }
    info.serviceSubscriberCellularProvidersDidUpdateNotifier = { _ in serviceFired = true }
    precondition(info.subscriberCellularProviderDidUpdateNotifier != nil)
    precondition(info.serviceSubscriberCellularProvidersDidUpdateNotifier != nil)
    precondition(!providerFired)
    precondition(!serviceFired)

    let override = NetworkDelegateProbe()
    info.delegate = override
    precondition(info.delegate === override)
    let existential: any CTTelephonyNetworkInfoDelegate = override
    existential.dataServiceIdentifierDidChange("probe-id")
    precondition(override.seen == "probe-id")
    info.delegate = nil
    precondition(info.delegate == nil)
}
