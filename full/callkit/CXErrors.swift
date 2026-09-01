import Foundation

private func nsEqual(_ lhs: [String: Any], _ rhs: [String: Any]) -> Bool {
    NSDictionary(dictionary: lhs).isEqual(to: rhs)
}

/// Bridged `NS_ERROR_ENUM(CXErrorDomain, CXErrorCode)`.
public struct CXError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case unknownError = 0
        case unentitled = 1
        case invalidArgument = 2
        case missingVoIPBackgroundMode = 3
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { CXErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var unknownError: Code { .unknownError }
    public static var unentitled: Code { .unentitled }
    public static var invalidArgument: Code { .invalidArgument }
    public static var missingVoIPBackgroundMode: Code { .missingVoIPBackgroundMode }

    public static func == (lhs: CXError, rhs: CXError) -> Bool {
        lhs.code == rhs.code && nsEqual(lhs.userInfo, rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension CXError.Code {
    public static func ~= (match: CXError.Code, error: any Error) -> Bool {
        (error as? CXError)?.code == match
    }
}

/// Bridged `NS_ERROR_ENUM(CXErrorDomainIncomingCall, CXErrorCodeIncomingCallError)`.
public struct CXErrorCodeIncomingCallError: Error, CustomNSError, Hashable, Equatable,
    @unchecked Sendable
{
    public enum Code: Int, Hashable, Sendable {
        case unknown = 0
        case unentitled = 1
        case callUUIDAlreadyExists = 2
        case filteredByDoNotDisturb = 3
        case filteredByBlockList = 4
        case filteredDuringRestrictedSharingMode = 5
        case callIsProtected = 6
        case filteredBySensitiveParticipants = 7
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { CXErrorDomainIncomingCall }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var unknown: Code { .unknown }
    public static var unentitled: Code { .unentitled }
    public static var callUUIDAlreadyExists: Code { .callUUIDAlreadyExists }
    public static var filteredByDoNotDisturb: Code { .filteredByDoNotDisturb }
    public static var filteredByBlockList: Code { .filteredByBlockList }
    public static var filteredDuringRestrictedSharingMode: Code {
        .filteredDuringRestrictedSharingMode
    }
    public static var callIsProtected: Code { .callIsProtected }
    public static var filteredBySensitiveParticipants: Code { .filteredBySensitiveParticipants }

    public static func == (
        lhs: CXErrorCodeIncomingCallError,
        rhs: CXErrorCodeIncomingCallError
    ) -> Bool {
        lhs.code == rhs.code && nsEqual(lhs.userInfo, rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension CXErrorCodeIncomingCallError.Code {
    public static func ~= (
        match: CXErrorCodeIncomingCallError.Code,
        error: any Error
    ) -> Bool {
        (error as? CXErrorCodeIncomingCallError)?.code == match
    }
}

/// Bridged `NS_ERROR_ENUM(CXErrorDomainRequestTransaction, CXErrorCodeRequestTransactionError)`.
public struct CXErrorCodeRequestTransactionError: Error, CustomNSError, Hashable, Equatable,
    @unchecked Sendable
{
    public enum Code: Int, Hashable, Sendable {
        case unknown = 0
        case unentitled = 1
        case unknownCallProvider = 2
        case emptyTransaction = 3
        case unknownCallUUID = 4
        case callUUIDAlreadyExists = 5
        case invalidAction = 6
        case maximumCallGroupsReached = 7
        case callIsProtected = 8
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { CXErrorDomainRequestTransaction }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var unknown: Code { .unknown }
    public static var unentitled: Code { .unentitled }
    public static var unknownCallProvider: Code { .unknownCallProvider }
    public static var emptyTransaction: Code { .emptyTransaction }
    public static var unknownCallUUID: Code { .unknownCallUUID }
    public static var callUUIDAlreadyExists: Code { .callUUIDAlreadyExists }
    public static var invalidAction: Code { .invalidAction }
    public static var maximumCallGroupsReached: Code { .maximumCallGroupsReached }
    public static var callIsProtected: Code { .callIsProtected }

    public static func == (
        lhs: CXErrorCodeRequestTransactionError,
        rhs: CXErrorCodeRequestTransactionError
    ) -> Bool {
        lhs.code == rhs.code && nsEqual(lhs.userInfo, rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension CXErrorCodeRequestTransactionError.Code {
    public static func ~= (
        match: CXErrorCodeRequestTransactionError.Code,
        error: any Error
    ) -> Bool {
        (error as? CXErrorCodeRequestTransactionError)?.code == match
    }
}

/// Bridged `NS_ERROR_ENUM(CXErrorDomainCallDirectoryManager, CXErrorCodeCallDirectoryManagerError)`.
public struct CXErrorCodeCallDirectoryManagerError: Error, CustomNSError, Hashable, Equatable,
    @unchecked Sendable
{
    public enum Code: Int, Hashable, Sendable {
        case unknown = 0
        case noExtensionFound = 1
        case loadingInterrupted = 2
        case entriesOutOfOrder = 3
        case duplicateEntries = 4
        case maximumEntriesExceeded = 5
        case extensionDisabled = 6
        case currentlyLoading = 7
        case unexpectedIncrementalRemoval = 8
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { CXErrorDomainCallDirectoryManager }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var unknown: Code { .unknown }
    public static var noExtensionFound: Code { .noExtensionFound }
    public static var loadingInterrupted: Code { .loadingInterrupted }
    public static var entriesOutOfOrder: Code { .entriesOutOfOrder }
    public static var duplicateEntries: Code { .duplicateEntries }
    public static var maximumEntriesExceeded: Code { .maximumEntriesExceeded }
    public static var extensionDisabled: Code { .extensionDisabled }
    public static var currentlyLoading: Code { .currentlyLoading }
    public static var unexpectedIncrementalRemoval: Code { .unexpectedIncrementalRemoval }

    public static func == (
        lhs: CXErrorCodeCallDirectoryManagerError,
        rhs: CXErrorCodeCallDirectoryManagerError
    ) -> Bool {
        lhs.code == rhs.code && nsEqual(lhs.userInfo, rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension CXErrorCodeCallDirectoryManagerError.Code {
    public static func ~= (
        match: CXErrorCodeCallDirectoryManagerError.Code,
        error: any Error
    ) -> Bool {
        (error as? CXErrorCodeCallDirectoryManagerError)?.code == match
    }
}

/// Bridged `NS_ERROR_ENUM(CXErrorDomainNotificationServiceExtension, CXErrorCodeNotificationServiceExtensionError)`.
public struct CXErrorCodeNotificationServiceExtensionError: Error, CustomNSError, Hashable,
    Equatable, @unchecked Sendable
{
    public enum Code: Int, Hashable, Sendable {
        case unknown = 0
        case invalidClientProcess = 1
        case missingNotificationFilteringEntitlement = 2
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { CXErrorDomainNotificationServiceExtension }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public static var unknown: Code { .unknown }
    public static var invalidClientProcess: Code { .invalidClientProcess }
    public static var missingNotificationFilteringEntitlement: Code {
        .missingNotificationFilteringEntitlement
    }

    public static func == (
        lhs: CXErrorCodeNotificationServiceExtensionError,
        rhs: CXErrorCodeNotificationServiceExtensionError
    ) -> Bool {
        lhs.code == rhs.code && nsEqual(lhs.userInfo, rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension CXErrorCodeNotificationServiceExtensionError.Code {
    public static func ~= (
        match: CXErrorCodeNotificationServiceExtensionError.Code,
        error: any Error
    ) -> Bool {
        (error as? CXErrorCodeNotificationServiceExtensionError)?.code == match
    }
}
