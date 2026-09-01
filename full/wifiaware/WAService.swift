import Foundation

/// A service a device can publish or subscribe to over Wi-Fi Aware.
///
/// Service names follow RFC 6763 / RFC 6335. On Linux, ``allServices`` is
/// empty because Info.plist Wi-Fi Aware service declarations are not loaded
/// from an Apple bundle. Public construction of a service value is
/// `init(from:)`.
public protocol WAService: CustomStringConvertible, Codable, Hashable, Identifiable, Sendable
where ID == String {
    static var allServices: [String: Self] { get }
    var name: String { get }
}

/// A service this app can publish.
public struct WAPublishableService: WAService, Sendable {
    public typealias ID = String

    public static var allServices: [ID: WAPublishableService] { [:] }

    public let name: String

    public var id: ID { name }

    public var description: String {
        "WAPublishableService(\(name))"
    }
}

/// A service this app can subscribe to.
public struct WASubscribableService: WAService, Sendable {
    public typealias ID = String

    public static var allServices: [ID: WASubscribableService] { [:] }

    public let name: String

    public var id: ID { name }

    public var description: String {
        "WASubscribableService(\(name))"
    }
}
