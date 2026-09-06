import Foundation

/// A participant identity used by conversations, actions, and recents.
///
/// `Handle.Kind` raw values follow Swift `Int` sequential assignment from
/// the API-digester child order (`generic = 0`). CallKit's `CXHandleType`
/// starts at 1; that ObjC enum is a different type. See oracle-questions.tsv.
public struct Handle: Hashable, Codable, Sendable {
    public enum Kind: Int, Hashable, Codable, Sendable {
        case generic = 0
        case phoneNumber = 1
        case emailAddress = 2
    }

    public var type: Kind
    public var value: String
    public var displayName: String

    /// `displayName` defaults to `value` when the caller passes `nil`.
    /// Apple's exact nil-coalescing policy is unobserved.
    public init(type: Kind, value: String, displayName: String? = nil) {
        self.type = type
        self.value = value
        self.displayName = displayName ?? value
    }
}
