import Foundation

// MARK: - Darwin CS_* flag bits (cs_blobs.h)

enum DarwinCodeSigningFlag {
    static let valid: Int64 = 0x0000_0001
    static let adhoc: Int64 = 0x0000_0002
    static let getTaskAllow: Int64 = 0x0000_0004
    static let hard: Int64 = 0x0000_0100
    static let kill: Int64 = 0x0000_0200
    static let checkExpiration: Int64 = 0x0000_0400
    static let restrict: Int64 = 0x0000_0800
    static let enforcement: Int64 = 0x0000_1000
    static let requireLV: Int64 = 0x0000_2000
    static let runtime: Int64 = 0x0001_0000
    static let linkerSigned: Int64 = 0x0002_0000
    static let platformBinary: Int64 = 0x0400_0000
    static let debugged: Int64 = 0x1000_0000
    static let signed: Int64 = 0x2000_0000
}

/// Constraint that the on-disk code-signing flags are a superset of a value set.
public struct OnDiskCodeSigningFlags: OnDiskConstraint, LWCRNodeProviding {
    public typealias OutType = OnDiskCodeSigningFlags
    public typealias DataType = OnDiskCodeSigningFlags.ValueSet

    public var required: ValueSet
    var lwcrNode: ConstraintNode { .onDiskSigningFlags(required.rawValue) }

    public struct ValueSet: OptionSet, Sendable, Codable {
        public typealias RawValue = Int64
        public typealias ArrayLiteralElement = OnDiskCodeSigningFlags.ValueSet
        public typealias Element = OnDiskCodeSigningFlags.ValueSet

        public let rawValue: Int64
        public init(rawValue: Int64) { self.rawValue = rawValue }

        public static let terminatesOnCodeSigningFailure = ValueSet(rawValue: DarwinCodeSigningFlag.kill)
        public static let signalsBusErrorOnCodeSigningFailure = ValueSet(rawValue: DarwinCodeSigningFlag.hard)
        public static let isCodeSignatureRequiredForAllExecutableCode = ValueSet(rawValue: DarwinCodeSigningFlag.enforcement)
        public static let isAdhocSigned = ValueSet(rawValue: DarwinCodeSigningFlag.adhoc)
        public static let isSignedByLinker = ValueSet(rawValue: DarwinCodeSigningFlag.linkerSigned)
        public static let isHardenedRuntimeEnforced = ValueSet(rawValue: DarwinCodeSigningFlag.runtime)
        public static let isLibraryValidationRequired = ValueSet(rawValue: DarwinCodeSigningFlag.requireLV)
        public static let isDynamicLinkerPolicyHardened = ValueSet(rawValue: DarwinCodeSigningFlag.restrict)
        public static let isCertificateExpirationEnforced = ValueSet(rawValue: DarwinCodeSigningFlag.checkExpiration)
    }

    public static func isSuperset(of flags: OnDiskCodeSigningFlags.DataType) -> OnDiskCodeSigningFlags.OutType {
        OnDiskCodeSigningFlags(required: flags)
    }

    init(required: ValueSet) {
        self.required = required
    }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .onDiskSigningFlags(let raw) = node else { throw ConstraintError.malformedConstraint }
        required = ValueSet(rawValue: raw)
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

/// Constraint that a running process's code-signing flags are a superset of a value set.
public struct ProcessCodeSigningFlags: LaunchConstraint, ProcessConstraint, LWCRNodeProviding {
    public typealias OutType = ProcessCodeSigningFlags
    public typealias DataType = ProcessCodeSigningFlags.ValueSet

    public var required: ValueSet
    var lwcrNode: ConstraintNode { .processSigningFlags(required.rawValue) }

    public struct ValueSet: OptionSet, Sendable, Codable {
        public typealias RawValue = Int64
        public typealias ArrayLiteralElement = ProcessCodeSigningFlags.ValueSet
        public typealias Element = ProcessCodeSigningFlags.ValueSet

        public let rawValue: Int64
        public init(rawValue: Int64) { self.rawValue = rawValue }

        public static let terminatesOnCodeSigningFailure = ValueSet(rawValue: DarwinCodeSigningFlag.kill)
        public static let signalsBusErrorOnCodeSigningFailure = ValueSet(rawValue: DarwinCodeSigningFlag.hard)
        public static let isCodeSignatureRequiredForAllExecutableCode = ValueSet(rawValue: DarwinCodeSigningFlag.enforcement)
        public static let isDebugged = ValueSet(rawValue: DarwinCodeSigningFlag.debugged)
        public static let isDebuggable = ValueSet(rawValue: DarwinCodeSigningFlag.getTaskAllow)
        public static let isAdhocSigned = ValueSet(rawValue: DarwinCodeSigningFlag.adhoc)
        public static let isPlatformSigned = ValueSet(rawValue: DarwinCodeSigningFlag.platformBinary)
        public static let isSignedByLinker = ValueSet(rawValue: DarwinCodeSigningFlag.linkerSigned)
        public static let isDynamicallyValid = ValueSet(rawValue: DarwinCodeSigningFlag.valid)
        public static let isHardenedRuntimeEnforced = ValueSet(rawValue: DarwinCodeSigningFlag.runtime)
        public static let isLibraryValidationRequired = ValueSet(rawValue: DarwinCodeSigningFlag.requireLV)
        public static let isDynamicLinkerPolicyHardened = ValueSet(rawValue: DarwinCodeSigningFlag.restrict)
        public static let isCertificateExpirationEnforced = ValueSet(rawValue: DarwinCodeSigningFlag.checkExpiration)
        public static let isSigned = ValueSet(rawValue: DarwinCodeSigningFlag.signed)
    }

    public static func isSuperset(of flags: ProcessCodeSigningFlags.DataType) -> ProcessCodeSigningFlags.OutType {
        ProcessCodeSigningFlags(required: flags)
    }

    init(required: ValueSet) {
        self.required = required
    }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .processSigningFlags(let raw) = node else { throw ConstraintError.malformedConstraint }
        required = ValueSet(rawValue: raw)
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

// MARK: - EntitlementsQuery

/// A chain of CoreEntitlements VM operations that tests an entitlements dictionary.
public final class EntitlementsQuery: LaunchConstraint, OnDiskConstraint, ProcessConstraint, LWCRNodeProviding, @unchecked Sendable {
    /// CoreEntitlements `CEType` values used with `matchType` (opcode 11).
    public enum DataType: Int64, Sendable, Equatable, Hashable {
        case dictionary = 1
        case array = 2
        case integer = 3
        case string = 4
        case boolean = 5
    }

    let operations: [LWCRQueryOperation]
    var lwcrNode: ConstraintNode { .entitlements(operations) }

    init(operations: [LWCRQueryOperation]) {
        self.operations = operations
    }

    private func appending(_ operation: LWCRQueryOperation) -> EntitlementsQuery {
        EntitlementsQuery(operations: operations + [operation])
    }

    public static func key(_ keyName: String) -> EntitlementsQuery {
        EntitlementsQuery(operations: [.selectKey(keyName)])
    }

    public func key(_ keyName: String) -> EntitlementsQuery {
        appending(.selectKey(keyName))
    }

    public static func keyPrefix(_ keyPrefix: String) -> EntitlementsQuery {
        EntitlementsQuery(operations: [.selectKeyPrefix(keyPrefix)])
    }

    public func keyPrefix(_ keyPrefix: String) -> EntitlementsQuery {
        appending(.selectKeyPrefix(keyPrefix))
    }

    public func elementAtIndex(_ index: Int64) -> EntitlementsQuery {
        appending(.selectIndex(index))
    }

    public func matchSingle(_ value: String) -> EntitlementsQuery {
        appending(.matchString(value))
    }

    public func matchPrefixSingle(_ value: String) -> EntitlementsQuery {
        appending(.matchStringPrefix(value))
    }

    public func match(_ value: Bool) -> EntitlementsQuery {
        appending(.matchBool(value))
    }

    public func match(_ value: String) -> EntitlementsQuery {
        appending(.stringValueAllowed(value))
    }

    public func matchSingle(_ value: Int64) -> EntitlementsQuery {
        appending(.matchInteger(value))
    }

    public func matchPrefix(_ value: String) -> EntitlementsQuery {
        appending(.stringPrefixValueAllowed(value))
    }

    public func match(_ value: Int64) -> EntitlementsQuery {
        appending(.integerValueAllowed(value))
    }

    public func matchType(_ value: EntitlementsQuery.DataType) -> EntitlementsQuery {
        appending(.matchType(value.rawValue))
    }

    public required init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .entitlements(let ops) = node else { throw ConstraintError.malformedConstraint }
        operations = ops
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

// MARK: - Requirements

struct LWCRRequirementStorage: Equatable, Sendable {
    var node: ConstraintNode
    var domain: RequirementDomain

    func converting(to domain: RequirementDomain) throws -> LWCRRequirementStorage {
        guard node.allowed(in: domain) else {
            throw ConstraintError.unsupportedConstraintForRequirementType
        }
        return LWCRRequirementStorage(node: node, domain: domain)
    }
}

func lwcrBuildRequirement(
    nodes: [ConstraintNode],
    combinator: LWCRSimplifier.Combinator,
    domain: RequirementDomain
) throws -> LWCRRequirementStorage {
    let simplified = try LWCRSimplifier.simplify(nodes, combinator: combinator)
    guard simplified.allowed(in: domain) else {
        throw ConstraintError.unsupportedConstraintForRequirementType
    }
    return LWCRRequirementStorage(node: simplified, domain: domain)
}

/// A launch-time lightweight code requirement. Kernel enforcement is fail-closed
/// on Linux; this type stores and converts the DSL only.
public struct LaunchCodeRequirement: Sendable, Equatable {
    var storage: LWCRRequirementStorage

    init(storage: LWCRRequirementStorage) {
        self.storage = storage
    }

    public static func allOf(
        @LaunchConstraintBuilder requirement: () -> [any LaunchConstraint]
    ) throws -> LaunchCodeRequirement {
        let nodes = try requirement().map(lwcrNode(from:))
        let storage = try lwcrBuildRequirement(nodes: nodes, combinator: .all, domain: .launch)
        return LaunchCodeRequirement(storage: storage)
    }

    public static func anyOf(
        @LaunchConstraintBuilder requirement: () -> [any LaunchConstraint]
    ) throws -> LaunchCodeRequirement {
        let nodes = try requirement().map(lwcrNode(from:))
        let storage = try lwcrBuildRequirement(nodes: nodes, combinator: .any, domain: .launch)
        return LaunchCodeRequirement(storage: storage)
    }

    public init(_ onDiskRequirement: OnDiskCodeRequirement) throws {
        storage = try onDiskRequirement.storage.converting(to: .launch)
    }

    public init(_ processRequirement: ProcessCodeRequirement) throws {
        storage = try processRequirement.storage.converting(to: .launch)
    }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard node.allowed(in: .launch) else {
            throw ConstraintError.unsupportedConstraintForRequirementType
        }
        storage = LWCRRequirementStorage(node: node, domain: .launch)
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(storage.node, to: encoder)
    }

    public static func == (lhs: LaunchCodeRequirement, rhs: LaunchCodeRequirement) -> Bool {
        lhs.storage.node == rhs.storage.node
    }
}

/// An on-disk lightweight code requirement. Signature checking against a
/// `SecStaticCode` is not performed on Linux.
public struct OnDiskCodeRequirement: Sendable, Equatable {
    var storage: LWCRRequirementStorage

    init(storage: LWCRRequirementStorage) {
        self.storage = storage
    }

    public static func allOf(
        @OnDiskConstraintBuilder requirement: () -> [any OnDiskConstraint]
    ) throws -> OnDiskCodeRequirement {
        let nodes = try requirement().map(lwcrNode(from:))
        let storage = try lwcrBuildRequirement(nodes: nodes, combinator: .all, domain: .onDisk)
        return OnDiskCodeRequirement(storage: storage)
    }

    public static func anyOf(
        @OnDiskConstraintBuilder requirement: () -> [any OnDiskConstraint]
    ) throws -> OnDiskCodeRequirement {
        let nodes = try requirement().map(lwcrNode(from:))
        let storage = try lwcrBuildRequirement(nodes: nodes, combinator: .any, domain: .onDisk)
        return OnDiskCodeRequirement(storage: storage)
    }

    public init(_ launchRequirement: LaunchCodeRequirement) throws {
        storage = try launchRequirement.storage.converting(to: .onDisk)
    }

    public init(_ processRequirement: ProcessCodeRequirement) throws {
        storage = try processRequirement.storage.converting(to: .onDisk)
    }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard node.allowed(in: .onDisk) else {
            throw ConstraintError.unsupportedConstraintForRequirementType
        }
        storage = LWCRRequirementStorage(node: node, domain: .onDisk)
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(storage.node, to: encoder)
    }

    public static func == (lhs: OnDiskCodeRequirement, rhs: OnDiskCodeRequirement) -> Bool {
        lhs.storage.node == rhs.storage.node
    }
}

/// A process lightweight code requirement. `SecTaskValidateForRequirement` is
/// not in this public graph; Linux never reports a live-task match.
public struct ProcessCodeRequirement: Sendable, Equatable {
    var storage: LWCRRequirementStorage

    init(storage: LWCRRequirementStorage) {
        self.storage = storage
    }

    public static func allOf(
        @ProcessConstraintBuilder requirement: () -> [any ProcessConstraint]
    ) throws -> ProcessCodeRequirement {
        let nodes = try requirement().map(lwcrNode(from:))
        let storage = try lwcrBuildRequirement(nodes: nodes, combinator: .all, domain: .process)
        return ProcessCodeRequirement(storage: storage)
    }

    public static func anyOf(
        @ProcessConstraintBuilder requirement: () -> [any ProcessConstraint]
    ) throws -> ProcessCodeRequirement {
        let nodes = try requirement().map(lwcrNode(from:))
        let storage = try lwcrBuildRequirement(nodes: nodes, combinator: .any, domain: .process)
        return ProcessCodeRequirement(storage: storage)
    }

    public init(_ launchRequirement: LaunchCodeRequirement) throws {
        storage = try launchRequirement.storage.converting(to: .process)
    }

    public init(_ onDiskRequirement: OnDiskCodeRequirement) throws {
        storage = try onDiskRequirement.storage.converting(to: .process)
    }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard node.allowed(in: .process) else {
            throw ConstraintError.unsupportedConstraintForRequirementType
        }
        storage = LWCRRequirementStorage(node: node, domain: .process)
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(storage.node, to: encoder)
    }

    public static func == (lhs: ProcessCodeRequirement, rhs: ProcessCodeRequirement) -> Bool {
        lhs.storage.node == rhs.storage.node
    }
}

extension LaunchCodeRequirement: Encodable, Decodable {}
extension OnDiskCodeRequirement: Encodable, Decodable {}
extension ProcessCodeRequirement: Encodable, Decodable {}
