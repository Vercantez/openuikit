import Foundation

/// An error in Wi-Fi Aware.
///
/// Linux uses ``wifiAwareUnsupported(_:)`` as the fail-closed result for any
/// operation that would require a radio, pairing daemon, entitlement, or
/// Apple Network listener/browser. Detail structs have no public memberwise
/// constructor in the exact graph; construct them with `init(from:)`.
public enum WAError: Error, Sendable, Codable {
    case error(ErrorDetails)
    case wifiAwareUnsupported(WiFiAwareUnsupportedDetails)
    case entitlementMissing(EntitlementMissingDetails)
    case noRadioResources(NoRadioResourcesDetails)
    case serviceNotDeclared(ServiceNotDeclaredDetails)
    case serviceAlreadySubscribing(ServiceAlreadySubscribingDetails)
    case serviceAlreadyPublishing(ServiceAlreadyPublishingDetails)
    case noPairedDevices(NoPairedDevicesDetails)
    case deviceInvalid(DeviceInvalidDetails)
    case deviceNoLongerAvailable(DeviceNoLongerAvailableDetails)
    case publisherTimeout(PublisherTimeoutDetails)
    case subscriberTimeout(SubscriberTimeoutDetails)
    case connectionFailed(ConnectionFailedDetails)
    case connectionIdleTimeout(ConnectionIdleTimeoutDetails)
    case connectionTerminated(ConnectionTerminatedDetails)

    public struct ErrorDetails: Sendable, Codable {}
    public struct WiFiAwareUnsupportedDetails: Sendable, Codable {}
    public struct EntitlementMissingDetails: Sendable, Codable {}
    public struct NoRadioResourcesDetails: Sendable, Codable {}
    public struct ServiceNotDeclaredDetails: Sendable, Codable {}
    public struct ServiceAlreadySubscribingDetails: Sendable, Codable {}
    public struct ServiceAlreadyPublishingDetails: Sendable, Codable {}
    public struct NoPairedDevicesDetails: Sendable, Codable {}
    public struct DeviceInvalidDetails: Sendable, Codable {}
    public struct DeviceNoLongerAvailableDetails: Sendable, Codable {}
    public struct PublisherTimeoutDetails: Sendable, Codable {}
    public struct SubscriberTimeoutDetails: Sendable, Codable {}
    public struct ConnectionFailedDetails: Sendable, Codable {}
    public struct ConnectionIdleTimeoutDetails: Sendable, Codable {}
    public struct ConnectionTerminatedDetails: Sendable, Codable {}
}

extension WAError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .error:
            "A Wi-Fi Aware error occurred."
        case .wifiAwareUnsupported:
            "Wi-Fi Aware is not supported on this host."
        case .entitlementMissing:
            "A required Wi-Fi Aware entitlement is missing."
        case .noRadioResources:
            "Wi-Fi Aware radio resources are not available."
        case .serviceNotDeclared:
            "The Wi-Fi Aware service is not declared."
        case .serviceAlreadySubscribing:
            "The Wi-Fi Aware service is already subscribing."
        case .serviceAlreadyPublishing:
            "The Wi-Fi Aware service is already publishing."
        case .noPairedDevices:
            "No paired Wi-Fi Aware devices are available."
        case .deviceInvalid:
            "The Wi-Fi Aware device is invalid."
        case .deviceNoLongerAvailable:
            "The Wi-Fi Aware device is no longer available."
        case .publisherTimeout:
            "The Wi-Fi Aware publisher timed out."
        case .subscriberTimeout:
            "The Wi-Fi Aware subscriber timed out."
        case .connectionFailed:
            "The Wi-Fi Aware connection failed."
        case .connectionIdleTimeout:
            "The Wi-Fi Aware connection idle timeout elapsed."
        case .connectionTerminated:
            "The Wi-Fi Aware connection was terminated."
        }
    }

    public var failureReason: String? { errorDescription }

    public var recoverySuggestion: String? {
        switch self {
        case .wifiAwareUnsupported:
            "Use a device and OS that provide Wi-Fi Aware hardware and pairing."
        default:
            nil
        }
    }

    public var helpAnchor: String? { nil }
}
