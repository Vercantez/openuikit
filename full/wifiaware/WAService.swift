import Foundation

/// A service a device can publish or subscribe to over Wi-Fi Aware.
public protocol WAService: CustomStringConvertible, Decodable, Encodable,
    Hashable, Identifiable, Sendable
{
    static var allServices: [String: Self] { get }
    var name: String { get }
}

/// A service hosted by this app that remote devices can connect to.
///
/// Populated from `Info.plist` `WiFiAwareServices` on Apple. Linux has no
/// such inventory, so `allServices` is empty. Instances are constructed
/// through public `Codable`.
public struct WAPublishableService: WAService {
    public typealias ID = String

    public let name: String

    public var id: ID { name }

    public var description: String {
        "WAPublishableService(\(name))"
    }

    public static var allServices: [ID: WAPublishableService] { [:] }

    enum CodingKeys: String, CodingKey {
        case name
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }

    @_spi(OpenUIKitHost)
    public init(name: String) {
        self.name = name
    }
}

/// A service this app discovers on remote devices.
public struct WASubscribableService: WAService {
    public typealias ID = String

    public let name: String

    public var id: ID { name }

    public var description: String {
        "WASubscribableService(\(name))"
    }

    public static var allServices: [ID: WASubscribableService] { [:] }

    enum CodingKeys: String, CodingKey {
        case name
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }

    @_spi(OpenUIKitHost)
    public init(name: String) {
        self.name = name
    }
}
