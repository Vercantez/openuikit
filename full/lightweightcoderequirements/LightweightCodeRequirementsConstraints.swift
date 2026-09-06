import Foundation

// MARK: - Result builders

/// Builds an array of launch constraints from a result-builder closure.
@resultBuilder
public struct LaunchConstraintBuilder {
    public static func buildBlock(_ components: [any LaunchConstraint]...) -> [any LaunchConstraint] {
        components.flatMap { $0 }
    }

    public static func buildEither(first component: [any LaunchConstraint]) -> [any LaunchConstraint] {
        component
    }

    public static func buildEither(second component: [any LaunchConstraint]) -> [any LaunchConstraint] {
        component
    }

    public static func buildOptional(_ component: [any LaunchConstraint]?) -> [any LaunchConstraint] {
        component ?? []
    }

    public static func buildExpression(_ expression: [any LaunchConstraint]) -> [any LaunchConstraint] {
        expression
    }

    public static func buildExpression(_ expression: any LaunchConstraint) -> [any LaunchConstraint] {
        [expression]
    }
}

/// Builds an array of on-disk constraints from a result-builder closure.
@resultBuilder
public struct OnDiskConstraintBuilder {
    public static func buildBlock(_ components: [any OnDiskConstraint]...) -> [any OnDiskConstraint] {
        components.flatMap { $0 }
    }

    public static func buildEither(first component: [any OnDiskConstraint]) -> [any OnDiskConstraint] {
        component
    }

    public static func buildEither(second component: [any OnDiskConstraint]) -> [any OnDiskConstraint] {
        component
    }

    public static func buildOptional(_ component: [any OnDiskConstraint]?) -> [any OnDiskConstraint] {
        component ?? []
    }

    public static func buildExpression(_ expression: [any OnDiskConstraint]) -> [any OnDiskConstraint] {
        expression
    }

    public static func buildExpression(_ expression: any OnDiskConstraint) -> [any OnDiskConstraint] {
        [expression]
    }
}

/// Builds an array of process constraints from a result-builder closure.
@resultBuilder
public struct ProcessConstraintBuilder {
    public static func buildBlock(_ components: [any ProcessConstraint]...) -> [any ProcessConstraint] {
        components.flatMap { $0 }
    }

    public static func buildEither(first component: [any ProcessConstraint]) -> [any ProcessConstraint] {
        component
    }

    public static func buildEither(second component: [any ProcessConstraint]) -> [any ProcessConstraint] {
        component
    }

    public static func buildOptional(_ component: [any ProcessConstraint]?) -> [any ProcessConstraint] {
        component ?? []
    }

    public static func buildExpression(_ expression: [any ProcessConstraint]) -> [any ProcessConstraint] {
        expression
    }

    public static func buildExpression(_ expression: any ProcessConstraint) -> [any ProcessConstraint] {
        [expression]
    }
}

// MARK: - String identity constraints

/// Tests the team identifier in a code signature.
public struct TeamIdentifier: LaunchConstraint, OnDiskConstraint, ProcessConstraint, LWCRNodeProviding {
    public typealias OutType = TeamIdentifier
    public typealias DataType = String

    public var values: [String]
    var lwcrNode: ConstraintNode { .teamIdentifier(values) }

    public init(_ value: String) {
        values = [value]
    }

    public static func `in`(_ value: TeamIdentifier.DataType...) -> TeamIdentifier.OutType {
        TeamIdentifier(values: value)
    }

    public static func `in`(_ values: [TeamIdentifier.DataType]) -> TeamIdentifier.OutType {
        TeamIdentifier(values: values)
    }

    init(values: [String]) {
        self.values = values
    }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .teamIdentifier(let values) = node, !values.isEmpty else {
            throw ConstraintError.malformedConstraint
        }
        self.values = values
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

/// Tests the signing identifier attached to the code.
public struct SigningIdentifier: LaunchConstraint, OnDiskConstraint, ProcessConstraint, LWCRNodeProviding {
    public typealias OutType = SigningIdentifier
    public typealias DataType = String

    public var values: [String]
    var lwcrNode: ConstraintNode { .signingIdentifier(values) }

    public init(_ value: String) {
        values = [value]
    }

    public static func `in`(_ value: SigningIdentifier.DataType...) -> SigningIdentifier.OutType {
        SigningIdentifier(values: value)
    }

    public static func `in`(_ values: [SigningIdentifier.DataType]) -> SigningIdentifier.OutType {
        SigningIdentifier(values: values)
    }

    init(values: [String]) {
        self.values = values
    }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .signingIdentifier(let values) = node, !values.isEmpty else {
            throw ConstraintError.malformedConstraint
        }
        self.values = values
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

/// Tests a code-directory hash (cdhash) against one or more allowed digests.
public struct CodeDirectoryHash: LaunchConstraint, OnDiskConstraint, ProcessConstraint, LWCRNodeProviding {
    public typealias OutType = CodeDirectoryHash
    public typealias DataType = Data

    public var values: [Data]
    var lwcrNode: ConstraintNode { .codeDirectoryHash(values) }

    public init(_ value: Data) {
        values = [value]
    }

    public static func `in`(_ value: CodeDirectoryHash.DataType...) -> CodeDirectoryHash.OutType {
        CodeDirectoryHash(values: value)
    }

    public static func `in`(_ values: [CodeDirectoryHash.DataType]) -> CodeDirectoryHash.OutType {
        CodeDirectoryHash(values: values)
    }

    init(values: [Data]) {
        self.values = values
    }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .codeDirectoryHash(let values) = node, !values.isEmpty else {
            throw ConstraintError.malformedConstraint
        }
        self.values = values
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

/// Tests the Info.plist hash stored in the code signature.
public struct InfoPlistHash: LaunchConstraint, OnDiskConstraint, ProcessConstraint, LWCRNodeProviding {
    public typealias OutType = InfoPlistHash
    public typealias DataType = Data

    public var values: [Data]
    var lwcrNode: ConstraintNode { .infoPlistHash(values) }

    public init(_ value: Data) {
        values = [value]
    }

    public static func `in`(_ value: InfoPlistHash.DataType...) -> InfoPlistHash.OutType {
        InfoPlistHash(values: value)
    }

    public static func `in`(_ values: [InfoPlistHash.DataType]) -> InfoPlistHash.OutType {
        InfoPlistHash(values: values)
    }

    init(values: [Data]) {
        self.values = values
    }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .infoPlistHash(let values) = node, !values.isEmpty else {
            throw ConstraintError.malformedConstraint
        }
        self.values = values
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

// MARK: - Boolean facts

/// Tests whether the code file is a main binary (`CS_EXECSEG_MAIN_BINARY`).
public struct IsMainBinary: OnDiskConstraint, LWCRNodeProviding {
    public var value: Bool
    var lwcrNode: ConstraintNode { .isMainBinary(value) }

    public init() { value = true }
    public init(_ value: Bool) { self.value = value }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .isMainBinary(let value) = node else { throw ConstraintError.malformedConstraint }
        self.value = value
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

/// Tests whether the process is the operating system's initial process (`launchd`).
public struct IsInitProcess: LaunchConstraint, ProcessConstraint, LWCRNodeProviding {
    public var value: Bool
    var lwcrNode: ConstraintNode { .isInitProcess(value) }

    public init() { value = true }
    public init(_ value: Bool) { self.value = value }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .isInitProcess(let value) = node else { throw ConstraintError.malformedConstraint }
        self.value = value
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

/// Tests whether the code is on a volume covered by System Integrity Protection.
public struct IsSIPProtected: LaunchConstraint, OnDiskConstraint, ProcessConstraint, LWCRNodeProviding {
    public var value: Bool
    var lwcrNode: ConstraintNode { .isSIPProtected(value) }

    public init() { value = true }
    public init(_ value: Bool) { self.value = value }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .isSIPProtected(let value) = node else { throw ConstraintError.malformedConstraint }
        self.value = value
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

/// Tests whether a process has the same team identifier as the calling process.
///
/// Linux has no Apple team-id for the current process. The constraint is stored
/// as a fact; evaluation against a live `SecTask` is not in this module.
public struct TeamIdentifierMatchesCurrentProcess: ProcessConstraint, LWCRNodeProviding {
    public var value: Bool
    var lwcrNode: ConstraintNode { .teamIdentifierMatchesCurrentProcess(value) }

    public init() { value = true }
    public init(_ value: Bool) { self.value = value }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .teamIdentifierMatchesCurrentProcess(let value) = node else {
            throw ConstraintError.malformedConstraint
        }
        self.value = value
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

// MARK: - PlatformType (Mach-O PLATFORM_* constants)

/// Tests the Mach-O platform the code was built for.
public struct PlatformType: LaunchConstraint, OnDiskConstraint, ProcessConstraint, LWCRNodeProviding {
    public typealias OutType = PlatformType
    public typealias DataType = PlatformType.Value

    /// Mach-O `LC_BUILD_VERSION` platform identifiers from Darwin `<mach-o/loader.h>`.
    public struct Value: RawRepresentable, Hashable, Sendable, Codable {
        public typealias RawValue = Int64
        public let rawValue: Int64

        public init?(rawValue: Int64) {
            switch rawValue {
            case 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12:
                self.rawValue = rawValue
            default:
                return nil
            }
        }

        init(known: Int64) { rawValue = known }

        /// `PLATFORM_MACOS` = 1
        public static let macOS = Value(known: 1)
        /// `PLATFORM_IOS` = 2
        public static let iOS = Value(known: 2)
        /// `PLATFORM_TVOS` = 3
        public static let tvOS = Value(known: 3)
        /// `PLATFORM_WATCHOS` = 4
        public static let watchOS = Value(known: 4)
        /// `PLATFORM_MACCATALYST` = 6
        public static let macCatalyst = Value(known: 6)
        /// `PLATFORM_IOSSIMULATOR` = 7
        public static let iOSSimulator = Value(known: 7)
        /// `PLATFORM_TVOSSIMULATOR` = 8
        public static let tvOSSimulator = Value(known: 8)
        /// `PLATFORM_WATCHOSSIMULATOR` = 9
        public static let watchOSSimulator = Value(known: 9)
        /// `PLATFORM_DRIVERKIT` = 10
        public static let driverKit = Value(known: 10)
        /// `PLATFORM_VISIONOS` = 11
        public static let visionOS = Value(known: 11)
        /// `PLATFORM_VISIONOSSIMULATOR` = 12
        public static let visionOSSimulator = Value(known: 12)
    }

    public var values: [Value]
    var lwcrNode: ConstraintNode { .platformType(values.map(\.rawValue)) }

    public init(_ value: PlatformType.Value) {
        values = [value]
    }

    public static func `in`(_ value: PlatformType.DataType...) -> PlatformType.OutType {
        PlatformType(values: value)
    }

    public static func `in`(_ values: [PlatformType.DataType]) -> PlatformType.OutType {
        PlatformType(values: values)
    }

    init(values: [Value]) {
        self.values = values
    }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .platformType(let raws) = node, !raws.isEmpty else {
            throw ConstraintError.malformedConstraint
        }
        let decoded = raws.compactMap(Value.init(rawValue:))
        guard decoded.count == raws.count else { throw ConstraintError.malformedConstraint }
        values = decoded
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}

// MARK: - ValidationCategory (CS_VALIDATION_CATEGORY_*)

/// Tests the code-signature validation category.
public struct ValidationCategory: LaunchConstraint, OnDiskConstraint, ProcessConstraint, LWCRNodeProviding {
    public typealias OutType = ValidationCategory
    public typealias DataType = ValidationCategory.Value

    /// Values from Darwin `CS_VALIDATION_CATEGORY_*` and Apple's launch-constraint table.
    public struct Value: RawRepresentable, Hashable, Sendable, Codable {
        public typealias RawValue = Int64
        public let rawValue: Int64

        public init?(rawValue: Int64) {
            switch rawValue {
            case 1, 2, 3, 4, 5, 6, 10:
                self.rawValue = rawValue
            default:
                return nil
            }
        }

        init(known: Int64) { rawValue = known }

        /// `CS_VALIDATION_CATEGORY_PLATFORM` = 1
        public static let platform = Value(known: 1)
        /// `CS_VALIDATION_CATEGORY_TESTFLIGHT` = 2
        public static let testflight = Value(known: 2)
        /// `CS_VALIDATION_CATEGORY_DEVELOPMENT` = 3
        public static let development = Value(known: 3)
        /// `CS_VALIDATION_CATEGORY_APP_STORE` = 4
        public static let appStore = Value(known: 4)
        /// `CS_VALIDATION_CATEGORY_ENTERPRISE` = 5
        public static let enterprise = Value(known: 5)
        /// `CS_VALIDATION_CATEGORY_DEVELOPER_ID` = 6
        public static let developerID = Value(known: 6)
        /// `CS_VALIDATION_CATEGORY_NONE` = 10
        public static let none = Value(known: 10)
    }

    public var values: [Value]
    var lwcrNode: ConstraintNode { .validationCategory(values.map(\.rawValue)) }

    public init(_ value: ValidationCategory.Value) {
        values = [value]
    }

    public static func `in`(_ value: ValidationCategory.DataType...) -> ValidationCategory.OutType {
        ValidationCategory(values: value)
    }

    public static func `in`(_ values: [ValidationCategory.DataType]) -> ValidationCategory.OutType {
        ValidationCategory(values: values)
    }

    init(values: [Value]) {
        self.values = values
    }

    public init(from decoder: Decoder) throws {
        let node = try LWCRNodeCoder.decode(from: decoder)
        guard case .validationCategory(let raws) = node, !raws.isEmpty else {
            throw ConstraintError.malformedConstraint
        }
        let decoded = raws.compactMap(Value.init(rawValue:))
        guard decoded.count == raws.count else { throw ConstraintError.malformedConstraint }
        values = decoded
    }

    public func encode(to encoder: Encoder) throws {
        try LWCRNodeCoder.encode(lwcrNode, to: encoder)
    }
}
