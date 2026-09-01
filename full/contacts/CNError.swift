import Foundation

/// Portable `NS_ERROR_ENUM(CNErrorDomain, CNErrorCode)` overlay.
///
/// Attested numeric codes follow the public `CNError.h` layout: communication
/// and data-access (1–2), authorization (100–104), record errors (200–206),
/// validation (300–302), predicate 400, and policy 500. Newer cases exist in
/// the public graph (`parentContainerNotWritable`, client-identifier, change
/// history, vCard) but their Darwin raw values are unattested and must not be
/// treated as ABI until an Apple oracle dump.
public struct CNError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case communicationError = 1
        case dataAccessError = 2
        case authorizationDenied = 100
        case noAccessableWritableContainers = 101
        case unauthorizedKeys = 102
        case featureDisabledByUser = 103
        case featureNotAvailable = 104
        case recordDoesNotExist = 200
        case insertedRecordAlreadyExists = 201
        case containmentCycle = 202
        case containmentScope = 203
        case recordIdentifierInvalid = 204
        case recordNotWritable = 205
        case parentRecordDoesNotExist = 206
        case parentContainerNotWritable = 207
        case validationMultipleErrors = 300
        case validationTypeMismatch = 301
        case validationConfigurationError = 302
        case predicateInvalid = 400
        case policyViolation = 500
        case clientIdentifierInvalid = 600
        case clientIdentifierDoesNotExist = 601
        case clientIdentifierCollision = 602
        case changeHistoryExpired = 700
        case changeHistoryInvalidAnchor = 701
        case changeHistoryInvalidFetchRequest = 702
        case vCardMalformed = 800
        case vCardSummarizationError = 801
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { CNErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public var affectedRecords: [AnyObject]? {
        userInfo[CNErrorUserInfoAffectedRecordsKey] as? [AnyObject]
    }

    public var affectedRecordIdentifiers: [String]? {
        userInfo[CNErrorUserInfoAffectedRecordIdentifiersKey] as? [String]
    }

    public var keyPaths: [String]? {
        userInfo[CNErrorUserInfoKeyPathsKey] as? [String]
    }

    public static let communicationError = Code.communicationError
    public static let dataAccessError = Code.dataAccessError
    public static let authorizationDenied = Code.authorizationDenied
    public static let noAccessableWritableContainers = Code.noAccessableWritableContainers
    public static let unauthorizedKeys = Code.unauthorizedKeys
    public static let featureDisabledByUser = Code.featureDisabledByUser
    public static let featureNotAvailable = Code.featureNotAvailable
    public static let recordDoesNotExist = Code.recordDoesNotExist
    public static let insertedRecordAlreadyExists = Code.insertedRecordAlreadyExists
    public static let containmentCycle = Code.containmentCycle
    public static let containmentScope = Code.containmentScope
    public static let recordIdentifierInvalid = Code.recordIdentifierInvalid
    public static let recordNotWritable = Code.recordNotWritable
    public static let parentRecordDoesNotExist = Code.parentRecordDoesNotExist
    public static let parentContainerNotWritable = Code.parentContainerNotWritable
    public static let validationMultipleErrors = Code.validationMultipleErrors
    public static let validationTypeMismatch = Code.validationTypeMismatch
    public static let validationConfigurationError = Code.validationConfigurationError
    public static let predicateInvalid = Code.predicateInvalid
    public static let policyViolation = Code.policyViolation
    public static let clientIdentifierInvalid = Code.clientIdentifierInvalid
    public static let clientIdentifierDoesNotExist = Code.clientIdentifierDoesNotExist
    public static let clientIdentifierCollision = Code.clientIdentifierCollision
    public static let changeHistoryExpired = Code.changeHistoryExpired
    public static let changeHistoryInvalidAnchor = Code.changeHistoryInvalidAnchor
    public static let changeHistoryInvalidFetchRequest = Code.changeHistoryInvalidFetchRequest
    public static let vCardMalformed = Code.vCardMalformed
    public static let vCardSummarizationError = Code.vCardSummarizationError

    public static func == (lhs: CNError, rhs: CNError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

extension CNError.Code {
    public static func ~= (match: CNError.Code, error: any Error) -> Bool {
        (error as? CNError)?.code == match
    }
}
