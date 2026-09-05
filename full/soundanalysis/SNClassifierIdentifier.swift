import Foundation

/// String newtype for Apple's built-in sound classifier identifiers.
/// The CFString payload of `SNClassifierIdentifierVersion1` is unobserved;
/// Linux uses the exported C symbol name as the raw value.
public struct SNClassifierIdentifier: RawRepresentable, Hashable, Sendable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let version1 = SNClassifierIdentifier(
        rawValue: "SNClassifierIdentifierVersion1"
    )

    public static func != (lhs: SNClassifierIdentifier, rhs: SNClassifierIdentifier) -> Bool {
        lhs.rawValue != rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
