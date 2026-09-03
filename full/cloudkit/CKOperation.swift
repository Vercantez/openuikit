import Foundation

open class CKOperation: Operation, @unchecked Sendable {
    public typealias ID = String

    open class Configuration: NSObject, NSCopying, @unchecked Sendable {
        open var allowsCellularAccess: Bool = true
        open var container: CKContainer?
        open var isLongLived: Bool = false
        open var qualityOfService: QualityOfService = .default
        open var timeoutIntervalForRequest: TimeInterval = 60
        open var timeoutIntervalForResource: TimeInterval = 7 * 24 * 60 * 60

        public override init() {
            super.init()
        }

        open func copy(with zone: NSZone? = nil) -> Any {
            let copied = CKOperation.Configuration()
            copied.allowsCellularAccess = allowsCellularAccess
            copied.container = container
            copied.isLongLived = isLongLived
            copied.qualityOfService = qualityOfService
            copied.timeoutIntervalForRequest = timeoutIntervalForRequest
            copied.timeoutIntervalForResource = timeoutIntervalForResource
            return copied
        }
    }

    open var allowsCellularAccess: Bool = true
    open var configuration: CKOperation.Configuration! = CKOperation.Configuration()
    open var container: CKContainer?
    open var group: CKOperationGroup?
    open var isLongLived: Bool = false
    open var longLivedOperationWasPersistedBlock: (() -> Void)?
    open var timeoutIntervalForRequest: TimeInterval = 60
    open var timeoutIntervalForResource: TimeInterval = 7 * 24 * 60 * 60
    open private(set) var operationID: CKOperation.ID

    public override init() {
        self.operationID = UUID().uuidString
        super.init()
    }

    open override func main() {
        finishFailClosed()
    }

    func finishFailClosed() {
        // Subclasses fire typed completion blocks. The base class is inert.
    }
}

open class CKDatabaseOperation: CKOperation, @unchecked Sendable {
    open var database: CKDatabase?
}

open class CKOperationGroup: NSObject, NSSecureCoding, @unchecked Sendable {
    public enum TransferSize: Int, Sendable, Hashable {
        case unknown = 0
        case kilobytes = 1
        case megabytes = 2
        case tensOfMegabytes = 3
        case hundredsOfMegabytes = 4
        case gigabytes = 5
        case tensOfGigabytes = 6
        case hundredsOfGigabytes = 7
    }

    open var defaultConfiguration: CKOperation.Configuration! = CKOperation.Configuration()
    open var expectedReceiveSize: TransferSize = .unknown
    open var expectedSendSize: TransferSize = .unknown
    open var name: String?
    open private(set) var operationGroupID: String
    open var quantity: Int = 0

    public static var supportsSecureCoding: Bool { true }

    public override init() {
        self.operationGroupID = UUID().uuidString
        super.init()
    }

    public required init(coder aDecoder: NSCoder) {
        _ = aDecoder
        self.operationGroupID = UUID().uuidString
        super.init()
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }
}

open class CKModifyRecordsOperation: CKDatabaseOperation, @unchecked Sendable {
    public enum RecordSavePolicy: Int, Sendable, Hashable {
        case ifServerRecordUnchanged = 0
        case changedKeys = 1
        case allKeys = 2
    }

    open var isAtomic: Bool = true
    open var clientChangeTokenData: Data?
    open var modifyRecordsCompletionBlock: (([CKRecord]?, [CKRecord.ID]?, (any Error)?) -> Void)?
    open var perRecordCompletionBlock: ((CKRecord, (any Error)?) -> Void)?
    open var perRecordProgressBlock: ((CKRecord, Double) -> Void)?
    open var recordIDsToDelete: [CKRecord.ID]?
    open var recordsToSave: [CKRecord]?
    open var savePolicy: RecordSavePolicy = .ifServerRecordUnchanged
    open var modifyRecordsResultBlock: ((Result<Void, any Error>) -> Void)?
    open var perRecordSaveBlock: ((CKRecord.ID, Result<CKRecord, any Error>) -> Void)?
    open var perRecordDeleteBlock: ((CKRecord.ID, Result<Void, any Error>) -> Void)?

    public override init() {
        super.init()
    }

    public convenience init(
        recordsToSave: [CKRecord]? = nil,
        recordIDsToDelete: [CKRecord.ID]? = nil
    ) {
        self.init()
        self.recordsToSave = recordsToSave
        self.recordIDsToDelete = recordIDsToDelete
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        recordsToSave?.forEach { record in
            perRecordCompletionBlock?(record, error)
            perRecordSaveBlock?(record.recordID, .failure(error))
        }
        recordIDsToDelete?.forEach { recordID in
            perRecordDeleteBlock?(recordID, .failure(error))
        }
        modifyRecordsCompletionBlock?(nil, nil, error)
        modifyRecordsResultBlock?(.failure(error))
    }
}

open class CKQueryOperation: CKDatabaseOperation, @unchecked Sendable {
    public static let maximumResults: Int = 0

    open class Cursor: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
        public static var supportsSecureCoding: Bool { true }

        public required init?(coder: NSCoder) {
            _ = coder
            return nil
        }

        public override init() {
            super.init()
        }

        open func encode(with coder: NSCoder) {
            _ = coder
        }

        open func copy(with zone: NSZone? = nil) -> Any {
            CKQueryOperation.Cursor()
        }
    }

    open var cursor: CKQueryOperation.Cursor?
    open var query: CKQuery?
    open var queryCompletionBlock: ((CKQueryOperation.Cursor?, (any Error)?) -> Void)?
    open var recordFetchedBlock: ((CKRecord) -> Void)?
    open var resultsLimit: Int = CKQueryOperation.maximumResults
    open var zoneID: CKRecordZone.ID?
    open var desiredKeys: [CKRecord.FieldKey]?
    open var queryResultBlock: ((Result<CKQueryOperation.Cursor?, any Error>) -> Void)?
    open var recordMatchedBlock: ((CKRecord.ID, Result<CKRecord, any Error>) -> Void)?

    public override init() {
        super.init()
    }

    public convenience init(cursor: CKQueryOperation.Cursor) {
        self.init()
        self.cursor = cursor
    }

    public convenience init(query: CKQuery) {
        self.init()
        self.query = query
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        queryCompletionBlock?(nil, error)
        queryResultBlock?(.failure(error))
    }
}

open class CKFetchRecordsOperation: CKDatabaseOperation, @unchecked Sendable {
    open var fetchRecordsCompletionBlock: (([CKRecord.ID: CKRecord]?, (any Error)?) -> Void)?
    open var perRecordCompletionBlock: ((CKRecord?, CKRecord.ID?, (any Error)?) -> Void)?
    open var perRecordProgressBlock: ((CKRecord.ID, Double) -> Void)?
    open var recordIDs: [CKRecord.ID]?

    public override required init() {
        super.init()
    }

    public convenience init(recordIDs: [CKRecord.ID]) {
        self.init()
        self.recordIDs = recordIDs
    }

    open class func fetchCurrentUserRecordOperation() -> Self {
        Self.init()
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        recordIDs?.forEach { recordID in
            perRecordCompletionBlock?(nil, recordID, error)
        }
        fetchRecordsCompletionBlock?(nil, error)
    }
}

open class CKFetchRecordZonesOperation: CKDatabaseOperation, @unchecked Sendable {
    open var fetchRecordZonesCompletionBlock: (([CKRecordZone.ID: CKRecordZone]?, (any Error)?) -> Void)?
    open var recordZoneIDs: [CKRecordZone.ID]?

    public override required init() {
        super.init()
    }

    public convenience init(recordZoneIDs zoneIDs: [CKRecordZone.ID]) {
        self.init()
        self.recordZoneIDs = zoneIDs
    }

    open class func fetchAllRecordZonesOperation() -> Self {
        Self.init()
    }

    override func finishFailClosed() {
        fetchRecordZonesCompletionBlock?(nil, CloudKitHost.unsupportedError())
    }
}

open class CKModifyRecordZonesOperation: CKDatabaseOperation, @unchecked Sendable {
    open var modifyRecordZonesCompletionBlock: (([CKRecordZone]?, [CKRecordZone.ID]?, (any Error)?) -> Void)?
    open var recordZoneIDsToDelete: [CKRecordZone.ID]?
    open var recordZonesToSave: [CKRecordZone]?
    open var perRecordZoneSaveBlock: ((CKRecordZone.ID, Result<CKRecordZone, any Error>) -> Void)?
    open var perRecordZoneDeleteBlock: ((CKRecordZone.ID, Result<Void, any Error>) -> Void)?
    open var modifyRecordZonesResultBlock: ((Result<Void, any Error>) -> Void)?

    public override init() {
        super.init()
    }

    public convenience init(
        recordZonesToSave: [CKRecordZone]? = nil,
        recordZoneIDsToDelete: [CKRecordZone.ID]? = nil
    ) {
        self.init()
        self.recordZonesToSave = recordZonesToSave
        self.recordZoneIDsToDelete = recordZoneIDsToDelete
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        recordZonesToSave?.forEach { zone in
            perRecordZoneSaveBlock?(zone.zoneID, .failure(error))
        }
        recordZoneIDsToDelete?.forEach { zoneID in
            perRecordZoneDeleteBlock?(zoneID, .failure(error))
        }
        modifyRecordZonesCompletionBlock?(nil, nil, error)
        modifyRecordZonesResultBlock?(.failure(error))
    }
}

open class CKModifySubscriptionsOperation: CKDatabaseOperation, @unchecked Sendable {
    open var subscriptionsToSave: [CKSubscription]?
    open var modifySubscriptionsResultBlock: ((Result<Void, any Error>) -> Void)?
    open var modifySubscriptionsCompletionBlock: (([CKSubscription]?, [CKSubscription.ID]?, (any Error)?) -> Void)?
    open var subscriptionIDsToDelete: [CKSubscription.ID]?
    open var perSubscriptionSaveBlock: ((CKSubscription.ID, Result<CKSubscription, any Error>) -> Void)?
    open var perSubscriptionDeleteBlock: ((CKSubscription.ID, Result<Void, any Error>) -> Void)?

    public override init() {
        super.init()
    }

    public convenience init(
        subscriptionsToSave: [CKSubscription]? = nil,
        subscriptionIDsToDelete: [CKSubscription.ID]? = nil
    ) {
        self.init()
        self.subscriptionsToSave = subscriptionsToSave
        self.subscriptionIDsToDelete = subscriptionIDsToDelete
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        subscriptionsToSave?.forEach { subscription in
            perSubscriptionSaveBlock?(subscription.subscriptionID, .failure(error))
        }
        subscriptionIDsToDelete?.forEach { subscriptionID in
            perSubscriptionDeleteBlock?(subscriptionID, .failure(error))
        }
        modifySubscriptionsCompletionBlock?(nil, nil, error)
        modifySubscriptionsResultBlock?(.failure(error))
    }
}
