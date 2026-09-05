@_spi(OpenUIKitHost) import WiFiAware
import Foundation

private func waExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private func emptyDetails<T: Decodable>(_ type: T.Type) -> T {
    try! JSONDecoder().decode(type, from: Data("{}".utf8))
}

func testErrorCasesTableDriven() {
    let rows: [(WAError, String, (WAError) -> Bool)] = [
        (
            .wifiAwareUnsupported(emptyDetails(WAError.WiFiAwareUnsupportedDetails.self)),
            "wifiAwareUnsupported",
            { if case .wifiAwareUnsupported = $0 { return true }; return false }
        ),
        (
            .entitlementMissing(emptyDetails(WAError.EntitlementMissingDetails.self)),
            "entitlementMissing",
            { if case .entitlementMissing = $0 { return true }; return false }
        ),
        (
            .noRadioResources(emptyDetails(WAError.NoRadioResourcesDetails.self)),
            "noRadioResources",
            { if case .noRadioResources = $0 { return true }; return false }
        ),
        (
            .serviceNotDeclared(emptyDetails(WAError.ServiceNotDeclaredDetails.self)),
            "serviceNotDeclared",
            { if case .serviceNotDeclared = $0 { return true }; return false }
        ),
        (
            .serviceAlreadySubscribing(emptyDetails(WAError.ServiceAlreadySubscribingDetails.self)),
            "serviceAlreadySubscribing",
            { if case .serviceAlreadySubscribing = $0 { return true }; return false }
        ),
        (
            .serviceAlreadyPublishing(emptyDetails(WAError.ServiceAlreadyPublishingDetails.self)),
            "serviceAlreadyPublishing",
            { if case .serviceAlreadyPublishing = $0 { return true }; return false }
        ),
        (
            .noPairedDevices(emptyDetails(WAError.NoPairedDevicesDetails.self)),
            "noPairedDevices",
            { if case .noPairedDevices = $0 { return true }; return false }
        ),
        (
            .deviceInvalid(emptyDetails(WAError.DeviceInvalidDetails.self)),
            "deviceInvalid",
            { if case .deviceInvalid = $0 { return true }; return false }
        ),
        (
            .deviceNoLongerAvailable(emptyDetails(WAError.DeviceNoLongerAvailableDetails.self)),
            "deviceNoLongerAvailable",
            { if case .deviceNoLongerAvailable = $0 { return true }; return false }
        ),
        (
            .publisherTimeout(emptyDetails(WAError.PublisherTimeoutDetails.self)),
            "publisherTimeout",
            { if case .publisherTimeout = $0 { return true }; return false }
        ),
        (
            .subscriberTimeout(emptyDetails(WAError.SubscriberTimeoutDetails.self)),
            "subscriberTimeout",
            { if case .subscriberTimeout = $0 { return true }; return false }
        ),
        (
            .connectionFailed(emptyDetails(WAError.ConnectionFailedDetails.self)),
            "connectionFailed",
            { if case .connectionFailed = $0 { return true }; return false }
        ),
        (
            .connectionIdleTimeout(emptyDetails(WAError.ConnectionIdleTimeoutDetails.self)),
            "connectionIdleTimeout",
            { if case .connectionIdleTimeout = $0 { return true }; return false }
        ),
        (
            .connectionTerminated(emptyDetails(WAError.ConnectionTerminatedDetails.self)),
            "connectionTerminated",
            { if case .connectionTerminated = $0 { return true }; return false }
        ),
        (
            .error(emptyDetails(WAError.ErrorDetails.self)),
            "error",
            { if case .error = $0 { return true }; return false }
        ),
    ]
    waExpect(rows.count == 15, "every public WAError case")
    for (error, name, match) in rows {
        waExpect(match(error), "expected \(name)")
        let _: WAError = error
    }
}

func testErrorDetailsEmptyCodable() {
    func roundTripEmpty<T: Codable>(_ type: T.Type, _ name: String) {
        let value = emptyDetails(type)
        let data = try! JSONEncoder().encode(value)
        _ = try! JSONDecoder().decode(type, from: data)
        let text = String(data: data, encoding: .utf8) ?? ""
        waExpect(text == "{}", "\(name) encodes as empty keyed container, got \(text)")
    }
    roundTripEmpty(WAError.ErrorDetails.self, "ErrorDetails")
    roundTripEmpty(WAError.WiFiAwareUnsupportedDetails.self, "WiFiAwareUnsupportedDetails")
    roundTripEmpty(WAError.EntitlementMissingDetails.self, "EntitlementMissingDetails")
    roundTripEmpty(WAError.NoRadioResourcesDetails.self, "NoRadioResourcesDetails")
    roundTripEmpty(WAError.ServiceNotDeclaredDetails.self, "ServiceNotDeclaredDetails")
    roundTripEmpty(WAError.ServiceAlreadySubscribingDetails.self, "ServiceAlreadySubscribingDetails")
    roundTripEmpty(WAError.ServiceAlreadyPublishingDetails.self, "ServiceAlreadyPublishingDetails")
    roundTripEmpty(WAError.NoPairedDevicesDetails.self, "NoPairedDevicesDetails")
    roundTripEmpty(WAError.DeviceInvalidDetails.self, "DeviceInvalidDetails")
    roundTripEmpty(WAError.DeviceNoLongerAvailableDetails.self, "DeviceNoLongerAvailableDetails")
    roundTripEmpty(WAError.PublisherTimeoutDetails.self, "PublisherTimeoutDetails")
    roundTripEmpty(WAError.SubscriberTimeoutDetails.self, "SubscriberTimeoutDetails")
    roundTripEmpty(WAError.ConnectionFailedDetails.self, "ConnectionFailedDetails")
    roundTripEmpty(WAError.ConnectionIdleTimeoutDetails.self, "ConnectionIdleTimeoutDetails")
    roundTripEmpty(WAError.ConnectionTerminatedDetails.self, "ConnectionTerminatedDetails")
}

func testWAErrorCodableRoundTrip() {
    let original = WAError.wifiAwareUnsupported(
        emptyDetails(WAError.WiFiAwareUnsupportedDetails.self)
    )
    let encoded = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(WAError.self, from: encoded)
    if case .wifiAwareUnsupported = decoded {
        return
    }
    preconditionFailure("WAError Codable lost wifiAwareUnsupported")
}

func testLocalizedErrorSurface() {
    let error: any LocalizedError = WAError.wifiAwareUnsupported(
        emptyDetails(WAError.WiFiAwareUnsupportedDetails.self)
    )
    waExpect(error.errorDescription == nil, "errorDescription unobserved")
    waExpect(error.failureReason == nil, "failureReason unobserved")
    waExpect(error.helpAnchor == nil, "helpAnchor unobserved")
    waExpect(error.recoverySuggestion == nil, "recoverySuggestion unobserved")
    let nsError: any Error = error
    waExpect(!nsError.localizedDescription.isEmpty, "Foundation localizedDescription")
}
