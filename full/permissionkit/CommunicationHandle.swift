import Foundation

/// An addressable communication identity (phone, email, or app-specific).
public struct CommunicationHandle: Hashable, Codable, Sendable {
    public enum Kind: String, Codable, Hashable, Sendable {
        case phoneNumber
        case emailAddress
        case custom
    }

    public var value: String
    public var kind: Kind

    public init(value: String, kind: Kind) {
        self.value = value
        self.kind = kind
    }

    public static func == (a: CommunicationHandle, b: CommunicationHandle) -> Bool {
        a.value == b.value && a.kind == b.kind
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
        hasher.combine(kind)
    }
}

extension CommunicationHandle.Kind {
    public static func == (a: CommunicationHandle.Kind, b: CommunicationHandle.Kind) -> Bool {
        switch (a, b) {
        case (.phoneNumber, .phoneNumber),
             (.emailAddress, .emailAddress),
             (.custom, .custom):
            return true
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}
