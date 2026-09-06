import Foundation

/// Linux starting point for Apple's public `LightweightCodeRequirements` DSL.
///
/// Leaf constraints, result builders, `allOf`/`anyOf` simplification, option-set
/// arithmetic, and CoreEntitlements query opcodes are implemented from the pinned
/// Xcode 26.1 graph plus documented Darwin / LWCR / CoreEntitlements constants.
/// Kernel AMFI evaluation, `SecTask` / `SecCode` checking, and SIP / trust-cache
/// inspection are not part of this module's public graph and stay fail-closed:
/// this port never invents a successful code-signing verdict.

// MARK: - Errors

/// Errors thrown while constructing or converting lightweight code requirements.
public enum ConstraintError: Error, Sendable, Equatable, Hashable {
    /// The same fact type appears twice in one `allOf`/`anyOf` after flattening.
    case duplicateKey
    /// A requirement or `in` list is empty, or a constraint cannot be represented.
    case malformedConstraint
    /// A constraint is not valid for the destination requirement domain.
    case unsupportedConstraintForRequirementType
    /// A process/task vanished before evaluation. This module has no evaluation
    /// API; the case exists so callers can match the public error surface.
    case taskIsNoLongerValid
}

// MARK: - Constraint protocols

/// A constraint that may appear in a `LaunchCodeRequirement`.
public protocol LaunchConstraint: Decodable, Encodable, Sendable {}

/// A constraint that may appear in an `OnDiskCodeRequirement`.
public protocol OnDiskConstraint: Decodable, Encodable, Sendable {}

/// A constraint that may appear in a `ProcessCodeRequirement`.
public protocol ProcessConstraint: Decodable, Encodable, Sendable {}

/// Domains a constraint fact may apply to, matching the graph's protocol
/// conformances.
enum RequirementDomain: String, Sendable, Equatable {
    case launch
    case onDisk
    case process
}

// MARK: - Internal node + query opcodes (documented CoreEntitlements)

/// CoreEntitlements VM opcodes from xnu `Entitlements.h` (`CEQueryOpOpcode`).
enum LWCRQueryOpcode: Int64, Sendable, Equatable {
    case selectKey = 1
    case selectIndex = 2
    case matchString = 3
    case matchStringPrefix = 4
    case matchBool = 5
    case stringValueAllowed = 6
    case matchInteger = 7
    case stringPrefixValueAllowed = 8
    case selectKeyPrefix = 9
    case integerValueAllowed = 10
    case matchType = 11
}

enum LWCRQueryOperation: Equatable, Sendable {
    case selectKey(String)
    case selectIndex(Int64)
    case matchString(String)
    case matchStringPrefix(String)
    case matchBool(Bool)
    case stringValueAllowed(String)
    case matchInteger(Int64)
    case stringPrefixValueAllowed(String)
    case selectKeyPrefix(String)
    case integerValueAllowed(Int64)
    case matchType(Int64)

    var opcode: Int64 {
        switch self {
        case .selectKey: return LWCRQueryOpcode.selectKey.rawValue
        case .selectIndex: return LWCRQueryOpcode.selectIndex.rawValue
        case .matchString: return LWCRQueryOpcode.matchString.rawValue
        case .matchStringPrefix: return LWCRQueryOpcode.matchStringPrefix.rawValue
        case .matchBool: return LWCRQueryOpcode.matchBool.rawValue
        case .stringValueAllowed: return LWCRQueryOpcode.stringValueAllowed.rawValue
        case .matchInteger: return LWCRQueryOpcode.matchInteger.rawValue
        case .stringPrefixValueAllowed: return LWCRQueryOpcode.stringPrefixValueAllowed.rawValue
        case .selectKeyPrefix: return LWCRQueryOpcode.selectKeyPrefix.rawValue
        case .integerValueAllowed: return LWCRQueryOpcode.integerValueAllowed.rawValue
        case .matchType: return LWCRQueryOpcode.matchType.rawValue
        }
    }
}

enum LWCRFactKind: String, Equatable, Sendable {
    case teamIdentifier
    case signingIdentifier
    case codeDirectoryHash
    case infoPlistHash
    case platformType
    case validationCategory
    case onDiskSigningFlags
    case processSigningFlags
    case isSIPProtected
    case isInitProcess
    case isMainBinary
    case teamIdentifierMatchesCurrentProcess
    case entitlements
}

indirect enum ConstraintNode: Equatable, Sendable {
    case allOf([ConstraintNode])
    case anyOf([ConstraintNode])
    case teamIdentifier([String])
    case signingIdentifier([String])
    case codeDirectoryHash([Data])
    case infoPlistHash([Data])
    case platformType([Int64])
    case validationCategory([Int64])
    case onDiskSigningFlags(Int64)
    case processSigningFlags(Int64)
    case isSIPProtected(Bool)
    case isInitProcess(Bool)
    case isMainBinary(Bool)
    case teamIdentifierMatchesCurrentProcess(Bool)
    case entitlements([LWCRQueryOperation])

    var factKind: LWCRFactKind? {
        switch self {
        case .allOf, .anyOf: return nil
        case .teamIdentifier: return .teamIdentifier
        case .signingIdentifier: return .signingIdentifier
        case .codeDirectoryHash: return .codeDirectoryHash
        case .infoPlistHash: return .infoPlistHash
        case .platformType: return .platformType
        case .validationCategory: return .validationCategory
        case .onDiskSigningFlags: return .onDiskSigningFlags
        case .processSigningFlags: return .processSigningFlags
        case .isSIPProtected: return .isSIPProtected
        case .isInitProcess: return .isInitProcess
        case .isMainBinary: return .isMainBinary
        case .teamIdentifierMatchesCurrentProcess: return .teamIdentifierMatchesCurrentProcess
        case .entitlements: return .entitlements
        }
    }

    func allowed(in domain: RequirementDomain) -> Bool {
        switch self {
        case .allOf(let children), .anyOf(let children):
            return children.allSatisfy { $0.allowed(in: domain) }
        case .isMainBinary:
            return domain == .onDisk
        case .isInitProcess:
            return domain == .launch || domain == .process
        case .teamIdentifierMatchesCurrentProcess, .processSigningFlags:
            return domain == .launch || domain == .process
        case .onDiskSigningFlags:
            return domain == .onDisk
        default:
            return true
        }
    }
}

protocol LWCRNodeProviding: Sendable {
    var lwcrNode: ConstraintNode { get }
}

enum LWCRSimplifier {
    static func simplify(_ nodes: [ConstraintNode], combinator: Combinator) throws -> ConstraintNode {
        var flattened: [ConstraintNode] = []
        for node in nodes {
            switch (combinator, node) {
            case (.all, .allOf(let inner)), (.any, .anyOf(let inner)):
                flattened.append(contentsOf: inner)
            default:
                flattened.append(node)
            }
        }
        guard !flattened.isEmpty else { throw ConstraintError.malformedConstraint }
        var seen: Set<LWCRFactKind> = []
        for node in flattened {
            guard let kind = node.factKind else { continue }
            if kind == .entitlements { continue }
            if seen.contains(kind) { throw ConstraintError.duplicateKey }
            seen.insert(kind)
        }
        if flattened.count == 1 { return flattened[0] }
        switch combinator {
        case .all: return .allOf(flattened)
        case .any: return .anyOf(flattened)
        }
    }

    enum Combinator { case all, any }
}

enum LWCRNodeCoder {
    static func encode(_ node: ConstraintNode, to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch node {
        case .allOf(let children):
            try container.encode(children.map(Box.init), forKey: .allOf)
        case .anyOf(let children):
            try container.encode(children.map(Box.init), forKey: .anyOf)
        case .teamIdentifier(let values):
            try encodeList(values, key: .teamIdentifier, into: &container)
        case .signingIdentifier(let values):
            try encodeList(values, key: .signingIdentifier, into: &container)
        case .codeDirectoryHash(let values):
            try encodeList(values, key: .cdhash, into: &container)
        case .infoPlistHash(let values):
            try encodeList(values, key: .infoPlistHash, into: &container)
        case .platformType(let values):
            try encodeList(values, key: .platform, into: &container)
        case .validationCategory(let values):
            try encodeList(values, key: .validationCategory, into: &container)
        case .onDiskSigningFlags(let raw):
            try container.encode(raw, forKey: .onDiskCodeSigningFlags)
        case .processSigningFlags(let raw):
            try container.encode(raw, forKey: .processCodeSigningFlags)
        case .isSIPProtected(let value):
            try container.encode(value, forKey: .isSIPProtected)
        case .isInitProcess(let value):
            try container.encode(value, forKey: .isInitProcess)
        case .isMainBinary(let value):
            try container.encode(value, forKey: .isMainBinary)
        case .teamIdentifierMatchesCurrentProcess(let value):
            try container.encode(value, forKey: .teamIdentifierMatchesCurrentProcess)
        case .entitlements(let ops):
            try container.encode(ops.map(EncodedOp.init), forKey: .entitlements)
        }
    }

    static func decode(from decoder: Decoder) throws -> ConstraintNode {
        let container = try decoder.container(keyedBy: Key.self)
        if container.contains(.allOf) {
            let boxes = try container.decode([Box].self, forKey: .allOf)
            return try LWCRSimplifier.simplify(boxes.map(\.node), combinator: .all)
        }
        if container.contains(.anyOf) {
            let boxes = try container.decode([Box].self, forKey: .anyOf)
            return try LWCRSimplifier.simplify(boxes.map(\.node), combinator: .any)
        }
        if container.contains(.teamIdentifier) {
            return .teamIdentifier(try decodeList(String.self, key: .teamIdentifier, from: container))
        }
        if container.contains(.signingIdentifier) {
            return .signingIdentifier(try decodeList(String.self, key: .signingIdentifier, from: container))
        }
        if container.contains(.cdhash) {
            return .codeDirectoryHash(try decodeList(Data.self, key: .cdhash, from: container))
        }
        if container.contains(.infoPlistHash) {
            return .infoPlistHash(try decodeList(Data.self, key: .infoPlistHash, from: container))
        }
        if container.contains(.platform) {
            return .platformType(try decodeList(Int64.self, key: .platform, from: container))
        }
        if container.contains(.validationCategory) {
            return .validationCategory(try decodeList(Int64.self, key: .validationCategory, from: container))
        }
        if container.contains(.onDiskCodeSigningFlags) {
            return .onDiskSigningFlags(try container.decode(Int64.self, forKey: .onDiskCodeSigningFlags))
        }
        if container.contains(.processCodeSigningFlags) {
            return .processSigningFlags(try container.decode(Int64.self, forKey: .processCodeSigningFlags))
        }
        if container.contains(.isSIPProtected) {
            return .isSIPProtected(try container.decode(Bool.self, forKey: .isSIPProtected))
        }
        if container.contains(.isInitProcess) {
            return .isInitProcess(try container.decode(Bool.self, forKey: .isInitProcess))
        }
        if container.contains(.isMainBinary) {
            return .isMainBinary(try container.decode(Bool.self, forKey: .isMainBinary))
        }
        if container.contains(.teamIdentifierMatchesCurrentProcess) {
            return .teamIdentifierMatchesCurrentProcess(
                try container.decode(Bool.self, forKey: .teamIdentifierMatchesCurrentProcess)
            )
        }
        if container.contains(.entitlements) {
            let ops = try container.decode([EncodedOp].self, forKey: .entitlements)
            return .entitlements(try ops.map { try $0.makeOperation() })
        }
        throw ConstraintError.malformedConstraint
    }

    private static func encodeList<T: Encodable>(
        _ values: [T], key: Key, into container: inout KeyedEncodingContainer<Key>
    ) throws {
        if values.count == 1 {
            try container.encode(values[0], forKey: key)
        } else {
            try container.encode(EncodedIn<T>(values: values), forKey: key)
        }
    }

    private static func decodeList<T: Decodable>(
        _ type: T.Type, key: Key, from container: KeyedDecodingContainer<Key>
    ) throws -> [T] {
        if let single = try? container.decode(T.self, forKey: key) {
            return [single]
        }
        if let wrapper = try? container.decode(DecodedIn<T>.self, forKey: key) {
            guard !wrapper.values.isEmpty else { throw ConstraintError.malformedConstraint }
            return wrapper.values
        }
        if let array = try? container.decode([T].self, forKey: key) {
            guard !array.isEmpty else { throw ConstraintError.malformedConstraint }
            return array
        }
        throw ConstraintError.malformedConstraint
    }

    enum Key: String, CodingKey {
        case allOf = "$and"
        case anyOf = "$or"
        case teamIdentifier = "team-identifier"
        case signingIdentifier = "signing-identifier"
        case cdhash
        case infoPlistHash = "info-plist-hash"
        case platform
        case validationCategory = "validation-category"
        case onDiskCodeSigningFlags = "on-disk-code-signing-flags"
        case processCodeSigningFlags = "process-code-signing-flags"
        case isSIPProtected = "is-sip-protected"
        case isInitProcess = "is-init-proc"
        case isMainBinary = "is-main-binary"
        case teamIdentifierMatchesCurrentProcess = "team-identifier-matches-current-process"
        case entitlements
        case `in` = "$in"
    }

    struct EncodedIn<T: Encodable>: Encodable {
        var values: [T]
        enum CodingKeys: String, CodingKey { case values = "$in" }
    }

    struct DecodedIn<T: Decodable>: Decodable {
        var values: [T]
        enum CodingKeys: String, CodingKey { case values = "$in" }
    }

    struct EncodedOp: Codable, Equatable {
        var opcode: Int64
        var string: String?
        var integer: Int64?
        var boolean: Bool?

        init(_ op: LWCRQueryOperation) {
            opcode = op.opcode
            switch op {
            case .selectKey(let value), .matchString(let value), .matchStringPrefix(let value),
                 .stringValueAllowed(let value), .stringPrefixValueAllowed(let value),
                 .selectKeyPrefix(let value):
                string = value
            case .selectIndex(let value), .matchInteger(let value), .integerValueAllowed(let value),
                 .matchType(let value):
                integer = value
            case .matchBool(let value):
                boolean = value
            }
        }

        func makeOperation() throws -> LWCRQueryOperation {
            switch opcode {
            case LWCRQueryOpcode.selectKey.rawValue:
                guard let string else { throw ConstraintError.malformedConstraint }
                return .selectKey(string)
            case LWCRQueryOpcode.selectIndex.rawValue:
                guard let integer else { throw ConstraintError.malformedConstraint }
                return .selectIndex(integer)
            case LWCRQueryOpcode.matchString.rawValue:
                guard let string else { throw ConstraintError.malformedConstraint }
                return .matchString(string)
            case LWCRQueryOpcode.matchStringPrefix.rawValue:
                guard let string else { throw ConstraintError.malformedConstraint }
                return .matchStringPrefix(string)
            case LWCRQueryOpcode.matchBool.rawValue:
                guard let boolean else { throw ConstraintError.malformedConstraint }
                return .matchBool(boolean)
            case LWCRQueryOpcode.stringValueAllowed.rawValue:
                guard let string else { throw ConstraintError.malformedConstraint }
                return .stringValueAllowed(string)
            case LWCRQueryOpcode.matchInteger.rawValue:
                guard let integer else { throw ConstraintError.malformedConstraint }
                return .matchInteger(integer)
            case LWCRQueryOpcode.stringPrefixValueAllowed.rawValue:
                guard let string else { throw ConstraintError.malformedConstraint }
                return .stringPrefixValueAllowed(string)
            case LWCRQueryOpcode.selectKeyPrefix.rawValue:
                guard let string else { throw ConstraintError.malformedConstraint }
                return .selectKeyPrefix(string)
            case LWCRQueryOpcode.integerValueAllowed.rawValue:
                guard let integer else { throw ConstraintError.malformedConstraint }
                return .integerValueAllowed(integer)
            case LWCRQueryOpcode.matchType.rawValue:
                guard let integer else { throw ConstraintError.malformedConstraint }
                return .matchType(integer)
            default:
                throw ConstraintError.malformedConstraint
            }
        }
    }

    struct Box: Codable {
        var node: ConstraintNode
        init(_ node: ConstraintNode) { self.node = node }
        init(from decoder: Decoder) throws { node = try LWCRNodeCoder.decode(from: decoder) }
        func encode(to encoder: Encoder) throws { try LWCRNodeCoder.encode(node, to: encoder) }
    }
}

func lwcrNode(from constraint: any LaunchConstraint) throws -> ConstraintNode {
    guard let provider = constraint as? any LWCRNodeProviding else {
        throw ConstraintError.malformedConstraint
    }
    return provider.lwcrNode
}

func lwcrNode(from constraint: any OnDiskConstraint) throws -> ConstraintNode {
    guard let provider = constraint as? any LWCRNodeProviding else {
        throw ConstraintError.malformedConstraint
    }
    return provider.lwcrNode
}

func lwcrNode(from constraint: any ProcessConstraint) throws -> ConstraintNode {
    guard let provider = constraint as? any LWCRNodeProviding else {
        throw ConstraintError.malformedConstraint
    }
    return provider.lwcrNode
}

// MARK: - Combinator constraints returned by free allOf/anyOf

struct LWCRLaunchCombinator: LaunchConstraint, LWCRNodeProviding {
    var lwcrNode: ConstraintNode
    init(node: ConstraintNode) { lwcrNode = node }
    init(from decoder: Decoder) throws { lwcrNode = try LWCRNodeCoder.decode(from: decoder) }
    func encode(to encoder: Encoder) throws { try LWCRNodeCoder.encode(lwcrNode, to: encoder) }
}

struct LWCROnDiskCombinator: OnDiskConstraint, LWCRNodeProviding {
    var lwcrNode: ConstraintNode
    init(node: ConstraintNode) { lwcrNode = node }
    init(from decoder: Decoder) throws { lwcrNode = try LWCRNodeCoder.decode(from: decoder) }
    func encode(to encoder: Encoder) throws { try LWCRNodeCoder.encode(lwcrNode, to: encoder) }
}

struct LWCRProcessCombinator: ProcessConstraint, LWCRNodeProviding {
    var lwcrNode: ConstraintNode
    init(node: ConstraintNode) { lwcrNode = node }
    init(from decoder: Decoder) throws { lwcrNode = try LWCRNodeCoder.decode(from: decoder) }
    func encode(to encoder: Encoder) throws { try LWCRNodeCoder.encode(lwcrNode, to: encoder) }
}

func lwcrCombineFree(_ nodes: [ConstraintNode], same: LWCRSimplifier.Combinator) -> ConstraintNode {
    var flattened: [ConstraintNode] = []
    for node in nodes {
        switch (same, node) {
        case (.all, .allOf(let inner)), (.any, .anyOf(let inner)):
            flattened.append(contentsOf: inner)
        default:
            flattened.append(node)
        }
    }
    if flattened.count == 1 { return flattened[0] }
    switch same {
    case .all: return .allOf(flattened)
    case .any: return .anyOf(flattened)
    }
}

/// Creates a constraint that requires a launching process to satisfy every child.
public func allOf(
    @LaunchConstraintBuilder requirement: () -> [any LaunchConstraint]
) -> any LaunchConstraint {
    let nodes = (try? requirement().map(lwcrNode(from:))) ?? []
    return LWCRLaunchCombinator(node: lwcrCombineFree(nodes, same: .all))
}

/// Creates a constraint that requires on-disk code to satisfy every child.
public func allOf(
    @OnDiskConstraintBuilder requirement: () -> [any OnDiskConstraint]
) -> any OnDiskConstraint {
    let nodes = (try? requirement().map(lwcrNode(from:))) ?? []
    return LWCROnDiskCombinator(node: lwcrCombineFree(nodes, same: .all))
}

/// Creates a constraint that requires a running process to satisfy every child.
public func allOf(
    @ProcessConstraintBuilder requirement: () -> [any ProcessConstraint]
) -> any ProcessConstraint {
    let nodes = (try? requirement().map(lwcrNode(from:))) ?? []
    return LWCRProcessCombinator(node: lwcrCombineFree(nodes, same: .all))
}

/// Creates a constraint that requires a launching process to satisfy any child.
public func anyOf(
    @LaunchConstraintBuilder requirement: () -> [any LaunchConstraint]
) -> any LaunchConstraint {
    let nodes = (try? requirement().map(lwcrNode(from:))) ?? []
    return LWCRLaunchCombinator(node: lwcrCombineFree(nodes, same: .any))
}

/// Creates a constraint that requires on-disk code to satisfy any child.
public func anyOf(
    @OnDiskConstraintBuilder requirement: () -> [any OnDiskConstraint]
) -> any OnDiskConstraint {
    let nodes = (try? requirement().map(lwcrNode(from:))) ?? []
    return LWCROnDiskCombinator(node: lwcrCombineFree(nodes, same: .any))
}

/// Creates a constraint that requires a running process to satisfy any child.
public func anyOf(
    @ProcessConstraintBuilder requirement: () -> [any ProcessConstraint]
) -> any ProcessConstraint {
    let nodes = (try? requirement().map(lwcrNode(from:))) ?? []
    return LWCRProcessCombinator(node: lwcrCombineFree(nodes, same: .any))
}
