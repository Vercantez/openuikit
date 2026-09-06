import Foundation

/// Process-local stack used by `UserIdentity.scope`. Apple's thread/task
/// isolation for scoped identity is unobserved; this is a host-only nest.
enum AssignablesUserIdentityScope {
    nonisolated(unsafe) static var stack: [AnyUserIdentity] = []

    static var current: AnyUserIdentity? { stack.last }
}

/// Educational user identity for assignment and scoring.
///
/// Conforming types must be `Codable` so `AnyUserIdentity` can round-trip
/// through `UserIdentityTypeRegistry`.
public protocol UserIdentity: Decodable, Encodable, Hashable, Sendable {
    var stringRepresentation: String { get }
    var typeID: String { get }
    func eraseToAnyUserIdentity() -> AnyUserIdentity
}

extension UserIdentity {
    public typealias As = UserIdentityFactory

    public func eraseToAnyUserIdentity() -> AnyUserIdentity {
        AnyUserIdentity(self)
    }

    @discardableResult
    public func scope<R>(_ access: () throws -> R) rethrows -> R {
        AssignablesUserIdentityScope.stack.append(AnyUserIdentity(self))
        defer { _ = AssignablesUserIdentityScope.stack.popLast() }
        return try access()
    }

    @discardableResult
    public func scope<R>(_ access: () async throws -> R) async rethrows -> R {
        AssignablesUserIdentityScope.stack.append(AnyUserIdentity(self))
        defer { _ = AssignablesUserIdentityScope.stack.popLast() }
        return try await access()
    }
}

/// Type-erased `UserIdentity`. Equality is `typeID` plus `stringRepresentation`.
public struct AnyUserIdentity: UserIdentity, Sendable {
    public enum Error: Swift.Error, Hashable, Sendable {
        case cannotDecode
    }

    public let typeID: String
    public let stringRepresentation: String
    private let payload: Data

    public init<T: UserIdentity>(_ userIdentity: T) {
        if let already = userIdentity as? AnyUserIdentity {
            self = already
            return
        }
        self.typeID = userIdentity.typeID
        self.stringRepresentation = userIdentity.stringRepresentation
        self.payload = (try? JSONEncoder().encode(userIdentity)) ?? Data()
    }

    public func eraseToAnyUserIdentity() -> AnyUserIdentity { self }

    @discardableResult
    public func scope<R>(_ access: () throws -> R) rethrows -> R {
        AssignablesUserIdentityScope.stack.append(self)
        defer { _ = AssignablesUserIdentityScope.stack.popLast() }
        return try access()
    }

    @discardableResult
    public func scope<R>(_ access: () async throws -> R) async rethrows -> R {
        AssignablesUserIdentityScope.stack.append(self)
        defer { _ = AssignablesUserIdentityScope.stack.popLast() }
        return try await access()
    }

    public static func == (lhs: AnyUserIdentity, rhs: AnyUserIdentity) -> Bool {
        lhs.typeID == rhs.typeID && lhs.stringRepresentation == rhs.stringRepresentation
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(typeID)
        hasher.combine(stringRepresentation)
    }

    private enum CodingKeys: String, CodingKey {
        case typeID
        case stringRepresentation
        case payload
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeID = try container.decode(String.self, forKey: .typeID)
        let stringRepresentation = try container.decode(String.self, forKey: .stringRepresentation)
        let payload = try container.decodeIfPresent(Data.self, forKey: .payload) ?? Data()
        if let decoded = UserIdentityTypeRegistry.decode(typeID: typeID, payload: payload) {
            self = decoded
            return
        }
        if typeID == StringUserIdentity.typeID {
            self = AnyUserIdentity(StringUserIdentity(value: stringRepresentation))
            return
        }
        if typeID == AnonymousUserIdentity.typeID {
            self = AnyUserIdentity(AnonymousUserIdentity())
            return
        }
        throw Error.cannotDecode
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(typeID, forKey: .typeID)
        try container.encode(stringRepresentation, forKey: .stringRepresentation)
        try container.encode(payload, forKey: .payload)
    }
}

/// String-backed identity. Linux `typeID` is `Assignables.StringUserIdentity`
/// pending an Apple-oracle dump of the Darwin type identifier.
public struct StringUserIdentity: UserIdentity, Sendable {
    public static var typeID: String { "Assignables.StringUserIdentity" }

    public var value: String
    public var typeID: String { Self.typeID }
    public var stringRepresentation: String { value }

    public init(value: String) {
        self.value = value
    }

    public static func == (a: StringUserIdentity, b: StringUserIdentity) -> Bool {
        a.value == b.value
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }

    private enum CodingKeys: String, CodingKey {
        case value
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = try container.decode(String.self, forKey: .value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
    }
}

/// Anonymous identity. All instances compare equal. Linux `typeID` is
/// `Assignables.AnonymousUserIdentity` pending an Apple-oracle dump.
public struct AnonymousUserIdentity: UserIdentity, Sendable {
    public static var typeID: String { "Assignables.AnonymousUserIdentity" }

    public var typeID: String { Self.typeID }
    public var stringRepresentation: String { "anonymous" }

    public init() {}

    public static func == (a: AnonymousUserIdentity, b: AnonymousUserIdentity) -> Bool {
        true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(Self.typeID)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        _ = try container.decode(String.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("anonymous")
    }
}

/// Factory namespace matching `UserIdentity.As`.
public enum UserIdentityFactory {
    public static var anonymous: AnonymousUserIdentity { AnonymousUserIdentity() }

    public static func string(_ value: String) -> StringUserIdentity {
        StringUserIdentity(value: value)
    }
}

/// Process-local registry for decoding type-erased identities.
public final class UserIdentityTypeRegistry: @unchecked Sendable {
    private static let lock = NSLock()
    private static var decoders: [String: (Data) throws -> AnyUserIdentity] = [:]

    public static func registerUserIdentityType<UI: UserIdentity>(
        typeID: String,
        type: UI.Type
    ) {
        lock.lock()
        decoders[typeID] = { data in
            AnyUserIdentity(try JSONDecoder().decode(type, from: data))
        }
        lock.unlock()
    }

    static func decode(typeID: String, payload: Data) -> AnyUserIdentity? {
        lock.lock()
        let decoder = decoders[typeID]
        lock.unlock()
        guard let decoder, !payload.isEmpty else { return nil }
        return try? decoder(payload)
    }
}
