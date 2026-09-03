import Foundation

/// An error in Wi-Fi Aware. Detail payloads have no public stored properties
/// in the canonical graph; they Codable-round-trip as empty keyed containers.
public enum WAError: Error, Sendable, Codable, LocalizedError {
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

    public struct ErrorDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct WiFiAwareUnsupportedDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct EntitlementMissingDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct NoRadioResourcesDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct ServiceNotDeclaredDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct ServiceAlreadySubscribingDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct ServiceAlreadyPublishingDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct NoPairedDevicesDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct DeviceInvalidDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct DeviceNoLongerAvailableDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct PublisherTimeoutDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct SubscriberTimeoutDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct ConnectionFailedDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct ConnectionIdleTimeoutDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }

    public struct ConnectionTerminatedDetails: Sendable, Codable {
        public init(from decoder: any Decoder) throws {
            try WAEmptyDetails.decode(decoder)
        }

        public func encode(to encoder: any Encoder) throws {
            try WAEmptyDetails.encode(encoder)
        }
    }
}

/// Empty keyed-container Codable used by every public `WAError` details type.
/// Apple documents that a details value that encodes nothing writes an empty
/// keyed container.
enum WAEmptyDetails {
    enum Keys: CodingKey {}

    static func decode(_ decoder: any Decoder) throws {
        _ = try decoder.container(keyedBy: Keys.self)
    }

    static func encode(_ encoder: any Encoder) throws {
        _ = encoder.container(keyedBy: Keys.self)
    }
}
