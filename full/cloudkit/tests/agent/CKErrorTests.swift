import CloudKit
import Foundation

func testCKErrorCodeRawValues() {
    let codes: [(CKError.Code, Int)] = [
        (.internalError, 1), (.partialFailure, 2), (.networkUnavailable, 3),
        (.networkFailure, 4), (.badContainer, 5), (.serviceUnavailable, 6),
        (.requestRateLimited, 7), (.missingEntitlement, 8), (.notAuthenticated, 9),
        (.permissionFailure, 10), (.unknownItem, 11), (.invalidArguments, 12),
        (.resultsTruncated, 13), (.serverRecordChanged, 14), (.serverRejectedRequest, 15),
        (.assetFileNotFound, 16), (.assetFileModified, 17), (.incompatibleVersion, 18),
        (.constraintViolation, 19), (.operationCancelled, 20), (.changeTokenExpired, 21),
        (.batchRequestFailed, 22), (.zoneBusy, 23), (.badDatabase, 24),
        (.quotaExceeded, 25), (.zoneNotFound, 26), (.limitExceeded, 27),
        (.userDeletedZone, 28), (.tooManyParticipants, 29), (.alreadyShared, 30),
        (.referenceViolation, 31), (.managedAccountRestricted, 32),
        (.participantMayNeedVerification, 33), (.serverResponseLost, 34),
        (.assetNotAvailable, 35), (.accountTemporarilyUnavailable, 36),
        (.participantAlreadyInvited, 37),
    ]
    precondition(codes.count == 37)
    for (code, raw) in codes {
        precondition(code.rawValue == raw)
        precondition(CKError.Code(rawValue: raw) == code)
    }
}

func testCKErrorStaticAliases() {
    precondition(CKError.internalError == .internalError)
    precondition(CKError.partialFailure == .partialFailure)
    precondition(CKError.networkUnavailable == .networkUnavailable)
    precondition(CKError.networkFailure == .networkFailure)
    precondition(CKError.badContainer == .badContainer)
    precondition(CKError.serviceUnavailable == .serviceUnavailable)
    precondition(CKError.requestRateLimited == .requestRateLimited)
    precondition(CKError.missingEntitlement == .missingEntitlement)
    precondition(CKError.notAuthenticated == .notAuthenticated)
    precondition(CKError.permissionFailure == .permissionFailure)
    precondition(CKError.unknownItem == .unknownItem)
    precondition(CKError.invalidArguments == .invalidArguments)
    precondition(CKError.resultsTruncated == .resultsTruncated)
    precondition(CKError.serverRecordChanged == .serverRecordChanged)
    precondition(CKError.serverRejectedRequest == .serverRejectedRequest)
    precondition(CKError.assetFileNotFound == .assetFileNotFound)
    precondition(CKError.assetFileModified == .assetFileModified)
    precondition(CKError.incompatibleVersion == .incompatibleVersion)
    precondition(CKError.constraintViolation == .constraintViolation)
    precondition(CKError.operationCancelled == .operationCancelled)
    precondition(CKError.changeTokenExpired == .changeTokenExpired)
    precondition(CKError.batchRequestFailed == .batchRequestFailed)
    precondition(CKError.zoneBusy == .zoneBusy)
    precondition(CKError.badDatabase == .badDatabase)
    precondition(CKError.quotaExceeded == .quotaExceeded)
    precondition(CKError.zoneNotFound == .zoneNotFound)
    precondition(CKError.limitExceeded == .limitExceeded)
    precondition(CKError.userDeletedZone == .userDeletedZone)
    precondition(CKError.tooManyParticipants == .tooManyParticipants)
    precondition(CKError.alreadyShared == .alreadyShared)
    precondition(CKError.referenceViolation == .referenceViolation)
    precondition(CKError.managedAccountRestricted == .managedAccountRestricted)
    precondition(CKError.participantMayNeedVerification == .participantMayNeedVerification)
    precondition(CKError.serverResponseLost == .serverResponseLost)
    precondition(CKError.assetNotAvailable == .assetNotAvailable)
    precondition(CKError.accountTemporarilyUnavailable == .accountTemporarilyUnavailable)
    precondition(CKError.participantAlreadyInvited == .participantAlreadyInvited)
}

func testCKErrorUserInfoAndPatternMatch() {
    precondition(CKErrorDomain == "CKErrorDomain")
    precondition(CKError.errorDomain == CKErrorDomain)
    precondition(CKErrorRetryAfterKey == "CKRetryAfterSeconds")
    precondition(CKErrorUserDidResetEncryptedDataKey == "CKErrorUserDidResetEncryptedData")
    precondition(CKPartialErrorsByItemIDKey == "CKPartialErrors")
    precondition(CKRecordChangedErrorAncestorRecordKey == "CKAncestorRecord")
    precondition(CKRecordChangedErrorClientRecordKey == "CKClientRecord")
    precondition(CKRecordChangedErrorServerRecordKey == "CKServerRecord")

    let bare = CKError(.notAuthenticated)
    precondition(bare.code == .notAuthenticated)
    precondition(bare.errorCode == CKError.Code.notAuthenticated.rawValue)
    precondition(bare.retryAfterSeconds == nil)
    precondition(bare.partialErrorsByItemID == nil)
    precondition(bare.clientRecord == nil)
    precondition(bare.serverRecord == nil)
    precondition(bare.ancestorRecord == nil)
    precondition(bare == CKError(.notAuthenticated))
    precondition(bare.hashValue == CKError(.notAuthenticated).hashValue)

    let retry = CKError(.zoneBusy, userInfo: [CKErrorRetryAfterKey: 1.5])
    precondition(retry.retryAfterSeconds == 1.5)
    let retryNumber = CKError(.zoneBusy, userInfo: [CKErrorRetryAfterKey: NSNumber(value: 2.0)])
    precondition(retryNumber.retryAfterSeconds == 2.0)

    let item = CKRecord.ID(recordName: "missing")
    let nested = CKError(.unknownItem)
    let partial = CKError(
        .partialFailure,
        userInfo: [CKPartialErrorsByItemIDKey: [item as AnyHashable: nested as any Error]]
    )
    precondition(partial.partialErrorsByItemID?[item] is CKError)

    let client = CKRecord(recordType: "Article")
    let server = CKRecord(recordType: "Article", recordID: client.recordID)
    let changed = CKError(
        .serverRecordChanged,
        userInfo: [
            CKRecordChangedErrorClientRecordKey: client,
            CKRecordChangedErrorServerRecordKey: server,
            CKRecordChangedErrorAncestorRecordKey: server,
        ]
    )
    precondition(changed.clientRecord?.recordID.isEqual(client.recordID) == true)
    precondition(changed.serverRecord?.recordID.isEqual(server.recordID) == true)
    precondition(changed.ancestorRecord?.recordID.isEqual(server.recordID) == true)

    let caught: any Error = CKError(.unknownItem)
    precondition(CKError.Code.unknownItem ~= caught)
    precondition(!(CKError.Code.zoneNotFound ~= caught))
    _ = CKError.Code.self
}
