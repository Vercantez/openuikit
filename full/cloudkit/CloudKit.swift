@_exported import Foundation

// MARK: - Public constants
//
// String values follow the public CloudKit headers and well-known Apple
// runtime constants. They are not a claim that iCloud services exist here.

public let CKErrorDomain = "CKErrorDomain"
public let CKErrorRetryAfterKey = "CKRetryAfterSeconds"
public let CKErrorUserDidResetEncryptedDataKey = "CKErrorUserDidResetEncryptedData"
public let CKPartialErrorsByItemIDKey = "CKPartialErrors"
public let CKRecordChangedErrorAncestorRecordKey = "CKAncestorRecord"
public let CKRecordChangedErrorClientRecordKey = "CKClientRecord"
public let CKRecordChangedErrorServerRecordKey = "CKServerRecord"

public let CKCurrentUserDefaultName = "__defaultOwner__"
public let CKOwnerDefaultName = "__defaultOwner__"
public let CKRecordZoneDefaultName = "_defaultZone"
public let CKRecordNameZoneWideShare = "cloudkit.zoneshare"

public let CKRecordTypeUserRecord = "Users"
public let CKRecordTypeShare = "cloudkit.share"
public let CKRecordParentKey = "___parent"
public let CKRecordShareKey = "___share"
public let CKShareTitleKey = "cloudkit.share.title"
public let CKShareTypeKey = "cloudkit.share.type"
public let CKShareThumbnailImageDataKey = "cloudkit.share.thumbnailImageData"

extension NSNotification.Name {
    public static let CKAccountChanged = NSNotification.Name("CKAccountChangedNotification")
}

// MARK: - Compatibility aliases (Swift overlay)

public typealias CKRecord_Reference_Action = CKRecord.ReferenceAction
public typealias CKShare_Participant_Role = CKShare.ParticipantRole
public typealias CKShare_Participant_Permission = CKShare.ParticipantPermission
public typealias CKShare_Participant_AcceptanceStatus = CKShare.ParticipantAcceptanceStatus
public typealias CKContainer_Application_Permissions = CKContainer.ApplicationPermissions
public typealias CKContainer_Application_PermissionBlock = CKContainer.ApplicationPermissionBlock
public typealias CKContainer_Application_PermissionStatus = CKContainer.ApplicationPermissionStatus

// MARK: - Linux fail-closed host
//
// Linux has no Apple identity, iCloud network, or CloudKit database daemon.
// Callers that would contact Apple services receive a typed CKError and never
// a fabricated success payload.

enum CloudKitHost {
    static let unsupportedDescription =
        "CloudKit Apple identity, network, and database services are unavailable on this Linux host."

    static func unsupportedError(
        _ code: CKError.Code = .notAuthenticated
    ) -> CKError {
        CKError(
            code,
            userInfo: [NSLocalizedDescriptionKey: unsupportedDescription]
        )
    }

    static func completeUnsupported<Value>(
        _ completion: @escaping (Value?, (any Error)?) -> Void
    ) {
        completion(nil, unsupportedError())
    }

    static func completeUnsupportedPair<A, B>(
        _ completion: @escaping (A?, B?, (any Error)?) -> Void
    ) {
        completion(nil, nil, unsupportedError())
    }

    static func fail<T>() throws -> T {
        throw unsupportedError()
    }
}
