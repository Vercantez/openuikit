import Foundation

public struct FullyQualifiedOrderIdentifier: Hashable, Sendable, Codable, CustomStringConvertible {
    public var orderTypeIdentifier: String
    public var orderIdentifier: String

    public init(orderTypeIdentifier: String, orderIdentifier: String) {
        self.orderTypeIdentifier = orderTypeIdentifier
        self.orderIdentifier = orderIdentifier
    }

    public var description: String {
        "\(orderTypeIdentifier)/\(orderIdentifier)"
    }
}
