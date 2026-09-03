import Foundation

/// Portable counterpart of CloudKit's bridged `NS_ERROR_ENUM(CKErrorDomain, CKErrorCode)`.
/// Numeric codes follow the public CloudKit header enumeration.
public struct CKError: Error, CustomNSError, Hashable, Equatable, @unchecked Sendable {
    public enum Code: Int, Hashable, Sendable {
        case internalError = 1
        case partialFailure = 2
        case networkUnavailable = 3
        case networkFailure = 4
        case badContainer = 5
        case serviceUnavailable = 6
        case requestRateLimited = 7
        case missingEntitlement = 8
        case notAuthenticated = 9
        case permissionFailure = 10
        case unknownItem = 11
        case invalidArguments = 12
        case resultsTruncated = 13
        case serverRecordChanged = 14
        case serverRejectedRequest = 15
        case assetFileNotFound = 16
        case assetFileModified = 17
        case incompatibleVersion = 18
        case constraintViolation = 19
        case operationCancelled = 20
        case changeTokenExpired = 21
        case batchRequestFailed = 22
        case zoneBusy = 23
        case badDatabase = 24
        case quotaExceeded = 25
        case zoneNotFound = 26
        case limitExceeded = 27
        case userDeletedZone = 28
        case tooManyParticipants = 29
        case alreadyShared = 30
        case referenceViolation = 31
        case managedAccountRestricted = 32
        case participantMayNeedVerification = 33
        case serverResponseLost = 34
        case assetNotAvailable = 35
        case accountTemporarilyUnavailable = 36
        case participantAlreadyInvited = 37
    }

    public let code: Code
    public let userInfo: [String: Any]

    public init(_ code: Code, userInfo: [String: Any] = [:]) {
        self.code = code
        self.userInfo = userInfo
    }

    public static var errorDomain: String { CKErrorDomain }
    public var errorCode: Int { code.rawValue }
    public var errorUserInfo: [String: Any] { userInfo }

    public var retryAfterSeconds: Double? {
        if let value = userInfo[CKErrorRetryAfterKey] as? Double {
            return value
        }
        if let number = userInfo[CKErrorRetryAfterKey] as? NSNumber {
            return number.doubleValue
        }
        return nil
    }

    public var partialErrorsByItemID: [AnyHashable: any Error]? {
        userInfo[CKPartialErrorsByItemIDKey] as? [AnyHashable: any Error]
    }

    public var ancestorRecord: CKRecord? {
        userInfo[CKRecordChangedErrorAncestorRecordKey] as? CKRecord
    }

    public var clientRecord: CKRecord? {
        userInfo[CKRecordChangedErrorClientRecordKey] as? CKRecord
    }

    public var serverRecord: CKRecord? {
        userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord
    }

    public static func == (lhs: CKError, rhs: CKError) -> Bool {
        guard lhs.code == rhs.code else { return false }
        return NSDictionary(dictionary: lhs.userInfo).isEqual(to: rhs.userInfo)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }

    public static let internalError = Code.internalError
    public static let partialFailure = Code.partialFailure
    public static let networkUnavailable = Code.networkUnavailable
    public static let networkFailure = Code.networkFailure
    public static let badContainer = Code.badContainer
    public static let serviceUnavailable = Code.serviceUnavailable
    public static let requestRateLimited = Code.requestRateLimited
    public static let missingEntitlement = Code.missingEntitlement
    public static let notAuthenticated = Code.notAuthenticated
    public static let permissionFailure = Code.permissionFailure
    public static let unknownItem = Code.unknownItem
    public static let invalidArguments = Code.invalidArguments
    public static let resultsTruncated = Code.resultsTruncated
    public static let serverRecordChanged = Code.serverRecordChanged
    public static let serverRejectedRequest = Code.serverRejectedRequest
    public static let assetFileNotFound = Code.assetFileNotFound
    public static let assetFileModified = Code.assetFileModified
    public static let incompatibleVersion = Code.incompatibleVersion
    public static let constraintViolation = Code.constraintViolation
    public static let operationCancelled = Code.operationCancelled
    public static let changeTokenExpired = Code.changeTokenExpired
    public static let batchRequestFailed = Code.batchRequestFailed
    public static let zoneBusy = Code.zoneBusy
    public static let badDatabase = Code.badDatabase
    public static let quotaExceeded = Code.quotaExceeded
    public static let limitExceeded = Code.limitExceeded
    public static let userDeletedZone = Code.userDeletedZone
    public static let tooManyParticipants = Code.tooManyParticipants
    public static let alreadyShared = Code.alreadyShared
    public static let referenceViolation = Code.referenceViolation
    public static let managedAccountRestricted = Code.managedAccountRestricted
    public static let participantMayNeedVerification = Code.participantMayNeedVerification
    public static let serverResponseLost = Code.serverResponseLost
    public static let assetNotAvailable = Code.assetNotAvailable
    public static let accountTemporarilyUnavailable = Code.accountTemporarilyUnavailable
    public static let participantAlreadyInvited = Code.participantAlreadyInvited
    public static let zoneNotFound = Code.zoneNotFound
}

extension CKError.Code {
    public static func ~= (match: CKError.Code, error: any Error) -> Bool {
        (error as? CKError)?.code == match
    }
}
