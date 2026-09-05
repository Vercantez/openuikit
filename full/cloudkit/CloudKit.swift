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
public let CKQueryOperationMaximumResults = 0
public let CKAccountChangedNotification = "CKAccountChangedNotification"

public let CKRecordTypeUserRecord = "Users"
public let CKRecordTypeShare = "cloudkit.share"
public let CKRecordParentKey = "___parent"
public let CKRecordShareKey = "___share"
public let CKShareTitleKey = "cloudkit.share.title"
public let CKShareTypeKey = "cloudkit.share.type"
public let CKShareThumbnailImageDataKey = "cloudkit.share.thumbnailImageData"

extension NSNotification.Name {
    public static let CKAccountChanged = NSNotification.Name(CKAccountChangedNotification)
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
        "CloudKit Apple identity and sharing services are unavailable on this Linux host."

    /// Real Foundation queue used to run simulated `CKOperation` instances.
    /// Completions are not invoked inline on the caller stack (CloudKitRuntime
    /// add-operation probe).
    static let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "CloudKit.SimulatedContainer"
        queue.maxConcurrentOperationCount = 4
        queue.qualityOfService = .utility
        return queue
    }()

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
        schedule {
            completion(nil, unsupportedError())
        }
    }

    static func completeUnsupportedPair<A, B>(
        _ completion: @escaping (A?, B?, (any Error)?) -> Void
    ) {
        schedule {
            completion(nil, nil, unsupportedError())
        }
    }

    static func fail<T>() throws -> T {
        throw unsupportedError()
    }

    static func schedule(_ operation: Operation) {
        operationQueue.addOperation(operation)
    }

    static func schedule(_ work: @escaping () -> Void) {
        let boxed = CloudKitUncheckedWork(work)
        operationQueue.addOperation {
            boxed.run()
        }
    }
}

final class CloudKitUncheckedWork: @unchecked Sendable {
    private let body: () -> Void

    init(_ body: @escaping () -> Void) {
        self.body = body
    }

    func run() {
        body()
    }
}

extension NSCoder {
    /// Linux NSKeyedUnarchiver raises on a missing key; Apple returns nil.
    func ck_decodeIfPresent<T: NSObject & NSCoding>(_ type: T.Type, forKey key: String) -> T? {
        guard containsValue(forKey: key) else { return nil }
        return decodeObject(of: type, forKey: key)
    }

    func ck_decodeIfPresent(classes: [AnyClass], forKey key: String) -> Any? {
        guard containsValue(forKey: key) else { return nil }
        return decodeObject(of: classes, forKey: key)
    }

    func ck_decodeIfPresent(forKey key: String) -> Any? {
        guard containsValue(forKey: key) else { return nil }
        return decodeObject(forKey: key)
    }
}
