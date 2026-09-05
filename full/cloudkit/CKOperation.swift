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
        if isCancelled {
            finishCancelled()
            return
        }
        runSimulated()
    }

    func runSimulated() {
        finishFailClosed()
    }

    func finishCancelled() {
        finishFailClosed()
    }

    func finishFailClosed() {
        // Subclasses fire typed completion blocks. Sharing/identity stay fail-closed.
    }
}

open class CKDatabaseOperation: CKOperation, @unchecked Sendable {
    open var database: CKDatabase?

    func runWithStore(_ body: (CKSimulatedDatabaseState) throws -> Void) {
        guard let database else {
            finishFailClosed()
            return
        }
        do {
            try database.withStore(body)
        } catch {
            finishFailClosed()
        }
    }
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

    override func runSimulated() {
        guard let database else {
            finishFailClosed()
            return
        }
        do {
            let outcome = try database.withStore {
                $0.modifyRecords(
                    saving: recordsToSave ?? [],
                    deleting: recordIDsToDelete ?? [],
                    policy: savePolicy,
                    atomically: isAtomic
                )
            }
            // Documented order: per-record progress/completion, then modify
            // completion, then result block (CloudKitRuntime modify-order probe).
            for record in recordsToSave ?? [] {
                perRecordProgressBlock?(record, 1.0)
                if let result = outcome.saveResults[record.recordID] {
                    switch result {
                    case .success(let saved):
                        perRecordCompletionBlock?(saved, nil)
                        perRecordSaveBlock?(record.recordID, .success(saved))
                    case .failure(let error):
                        perRecordCompletionBlock?(record, error)
                        perRecordSaveBlock?(record.recordID, .failure(error))
                    }
                }
            }
            for recordID in recordIDsToDelete ?? [] {
                if let result = outcome.deleteResults[recordID] {
                    perRecordDeleteBlock?(recordID, result)
                }
            }
            if let error = outcome.error {
                modifyRecordsCompletionBlock?(nil, nil, error)
                modifyRecordsResultBlock?(.failure(error))
            } else {
                modifyRecordsCompletionBlock?(outcome.saved, outcome.deleted, nil)
                modifyRecordsResultBlock?(.success(()))
            }
        } catch {
            finishFailClosed()
        }
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
    public static let maximumResults: Int = CKQueryOperationMaximumResults

    open class Cursor: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
        public static var supportsSecureCoding: Bool { true }

        var ck_recordType: CKRecord.RecordType = ""
        var ck_predicate: NSPredicate = NSPredicate(value: true)
        var ck_zoneID: CKRecordZone.ID?
        var ck_sortDescriptors: [NSSortDescriptor]?
        var ck_desiredKeys: [CKRecord.FieldKey]?
        var ck_offset: Int = 0

        public required init?(coder: NSCoder) {
            ck_recordType = coder.decodeObject(of: NSString.self, forKey: "ck.cursor.recordType") as String? ?? ""
            // Linux Foundation NSPredicate is not NSCoding; restore a TRUEPREDICATE.
            ck_predicate = NSPredicate(value: true)
            ck_zoneID = coder.decodeObject(of: CKRecordZoneID.self, forKey: "ck.cursor.zoneID")
            ck_offset = coder.decodeInteger(forKey: "ck.cursor.offset")
            super.init()
        }

        public override init() {
            super.init()
        }

        static func ck_make(
            recordType: CKRecord.RecordType,
            predicate: NSPredicate,
            zoneID: CKRecordZone.ID?,
            sortDescriptors: [NSSortDescriptor]?,
            desiredKeys: [CKRecord.FieldKey]?,
            offset: Int
        ) -> CKQueryOperation.Cursor {
            let cursor = CKQueryOperation.Cursor()
            cursor.ck_recordType = recordType
            cursor.ck_predicate = predicate
            cursor.ck_zoneID = zoneID
            cursor.ck_sortDescriptors = sortDescriptors
            cursor.ck_desiredKeys = desiredKeys
            cursor.ck_offset = offset
            return cursor
        }

        open func encode(with coder: NSCoder) {
            coder.encode(ck_recordType as NSString, forKey: "ck.cursor.recordType")
            coder.encode(ck_zoneID, forKey: "ck.cursor.zoneID")
            coder.encode(ck_offset, forKey: "ck.cursor.offset")
        }

        open func copy(with zone: NSZone? = nil) -> Any {
            CKQueryOperation.Cursor.ck_make(
                recordType: ck_recordType,
                predicate: ck_predicate,
                zoneID: ck_zoneID,
                sortDescriptors: ck_sortDescriptors,
                desiredKeys: ck_desiredKeys,
                offset: ck_offset
            )
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

    override func runSimulated() {
        guard let database else {
            finishFailClosed()
            return
        }
        do {
            let page = try database.withStore { state -> (matches: [CKRecord], cursor: CKQueryOperation.Cursor?) in
                if let cursor {
                    return state.queryRecords(
                        type: cursor.ck_recordType,
                        predicate: cursor.ck_predicate,
                        zoneID: cursor.ck_zoneID ?? zoneID,
                        sortDescriptors: cursor.ck_sortDescriptors,
                        desiredKeys: desiredKeys ?? cursor.ck_desiredKeys,
                        offset: cursor.ck_offset,
                        limit: resultsLimit
                    )
                }
                guard let query else {
                    throw CKSimulatedStore.error(.invalidArguments)
                }
                if let zoneID, state.zone(for: zoneID) == nil {
                    throw CKSimulatedStore.error(.zoneNotFound)
                }
                return state.queryRecords(
                    type: query.recordType,
                    predicate: query.predicate,
                    zoneID: zoneID,
                    sortDescriptors: query.sortDescriptors,
                    desiredKeys: desiredKeys,
                    offset: 0,
                    limit: resultsLimit
                )
            }
            for record in page.matches {
                recordFetchedBlock?(record)
                recordMatchedBlock?(record.recordID, .success(record))
            }
            queryCompletionBlock?(page.cursor, nil)
            queryResultBlock?(.success(page.cursor))
        } catch {
            let ckError = (error as? CKError) ?? CKSimulatedStore.error(.internalError)
            queryCompletionBlock?(nil, ckError)
            queryResultBlock?(.failure(ckError))
        }
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
    open var desiredKeys: [CKRecord.FieldKey]?
    open var fetchRecordsResultBlock: ((Result<Void, any Error>) -> Void)?
    open var perRecordResultBlock: ((CKRecord.ID, Result<CKRecord, any Error>) -> Void)?

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

    override func runSimulated() {
        guard let database else {
            finishFailClosed()
            return
        }
        var fetched: [CKRecord.ID: CKRecord] = [:]
        var failed = false
        let ids: [CKRecord.ID]
        if let recordIDs {
            ids = recordIDs
        } else {
            ids = []
        }
        do {
            try database.withStore { state in
                for recordID in ids {
                    perRecordProgressBlock?(recordID, 1.0)
                    let result = state.fetchRecord(recordID, desiredKeys: desiredKeys)
                    switch result {
                    case .success(let record):
                        fetched[recordID] = record
                        perRecordCompletionBlock?(record, recordID, nil)
                        perRecordResultBlock?(recordID, .success(record))
                    case .failure(let error):
                        failed = true
                        perRecordCompletionBlock?(nil, recordID, error)
                        perRecordResultBlock?(recordID, .failure(error))
                    }
                }
            }
            if failed {
                var partial: [AnyHashable: any Error] = [:]
                for recordID in ids where fetched[recordID] == nil {
                    partial[recordID] = CKSimulatedStore.error(.unknownItem)
                }
                let error = CKSimulatedStore.partialFailure(partial)
                fetchRecordsCompletionBlock?(fetched.isEmpty ? nil : fetched, error)
                fetchRecordsResultBlock?(.failure(error))
            } else {
                fetchRecordsCompletionBlock?(fetched, nil)
                fetchRecordsResultBlock?(.success(()))
            }
        } catch {
            finishFailClosed()
        }
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        recordIDs?.forEach { recordID in
            perRecordCompletionBlock?(nil, recordID, error)
            perRecordResultBlock?(recordID, .failure(error))
        }
        fetchRecordsCompletionBlock?(nil, error)
        fetchRecordsResultBlock?(.failure(error))
    }
}

open class CKFetchRecordZonesOperation: CKDatabaseOperation, @unchecked Sendable {
    open var fetchRecordZonesCompletionBlock: (([CKRecordZone.ID: CKRecordZone]?, (any Error)?) -> Void)?
    open var recordZoneIDs: [CKRecordZone.ID]?
    open var perRecordZoneResultBlock: ((CKRecordZone.ID, Result<CKRecordZone, any Error>) -> Void)?
    open var fetchRecordZonesResultBlock: ((Result<Void, any Error>) -> Void)?

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

    override func runSimulated() {
        guard let database else {
            finishFailClosed()
            return
        }
        do {
            var fetched: [CKRecordZone.ID: CKRecordZone] = [:]
            try database.withStore { state in
                let ids = recordZoneIDs ?? Array(state.zones.values.map { $0.zoneID })
                for zoneID in ids {
                    if let zone = state.zone(for: zoneID) {
                        let copy = zone.ck_copyZone()
                        fetched[zoneID] = copy
                        perRecordZoneResultBlock?(zoneID, .success(copy))
                    } else {
                        let error = CKSimulatedStore.error(.zoneNotFound)
                        perRecordZoneResultBlock?(zoneID, .failure(error))
                    }
                }
            }
            fetchRecordZonesCompletionBlock?(fetched, nil)
            fetchRecordZonesResultBlock?(.success(()))
        } catch {
            finishFailClosed()
        }
    }

    override func finishFailClosed() {
        let error = CloudKitHost.unsupportedError()
        fetchRecordZonesCompletionBlock?(nil, error)
        fetchRecordZonesResultBlock?(.failure(error))
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

    override func runSimulated() {
        guard let database else {
            finishFailClosed()
            return
        }
        do {
            var saved: [CKRecordZone] = []
            var deleted: [CKRecordZone.ID] = []
            var failed = false
            var partial: [AnyHashable: any Error] = [:]
            try database.withStore { state in
                for zone in recordZonesToSave ?? [] {
                    switch state.saveZone(zone) {
                    case .success(let stored):
                        saved.append(stored)
                        perRecordZoneSaveBlock?(zone.zoneID, .success(stored))
                    case .failure(let error):
                        failed = true
                        partial[zone.zoneID] = error
                        perRecordZoneSaveBlock?(zone.zoneID, .failure(error))
                    }
                }
                for zoneID in recordZoneIDsToDelete ?? [] {
                    switch state.deleteZone(zoneID) {
                    case .success(let deletedID):
                        deleted.append(deletedID)
                        perRecordZoneDeleteBlock?(zoneID, .success(()))
                    case .failure(let error):
                        failed = true
                        partial[zoneID] = error
                        perRecordZoneDeleteBlock?(zoneID, .failure(error))
                    }
                }
            }
            if failed {
                let error = CKSimulatedStore.partialFailure(partial)
                modifyRecordZonesCompletionBlock?(nil, nil, error)
                modifyRecordZonesResultBlock?(.failure(error))
            } else {
                modifyRecordZonesCompletionBlock?(saved, deleted, nil)
                modifyRecordZonesResultBlock?(.success(()))
            }
        } catch {
            finishFailClosed()
        }
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

    override func runSimulated() {
        guard let database else {
            finishFailClosed()
            return
        }
        do {
            var saved: [CKSubscription] = []
            var deleted: [CKSubscription.ID] = []
            var failed = false
            var partial: [AnyHashable: any Error] = [:]
            try database.withStore { state in
                for subscription in subscriptionsToSave ?? [] {
                    switch state.saveSubscription(subscription) {
                    case .success(let stored):
                        saved.append(stored)
                        perSubscriptionSaveBlock?(subscription.subscriptionID, .success(stored))
                    case .failure(let error):
                        failed = true
                        partial[subscription.subscriptionID] = error
                        perSubscriptionSaveBlock?(subscription.subscriptionID, .failure(error))
                    }
                }
                for subscriptionID in subscriptionIDsToDelete ?? [] {
                    switch state.deleteSubscription(subscriptionID) {
                    case .success:
                        deleted.append(subscriptionID)
                        perSubscriptionDeleteBlock?(subscriptionID, .success(()))
                    case .failure(let error):
                        failed = true
                        partial[subscriptionID] = error
                        perSubscriptionDeleteBlock?(subscriptionID, .failure(error))
                    }
                }
            }
            if failed {
                let error = CKSimulatedStore.partialFailure(partial)
                modifySubscriptionsCompletionBlock?(nil, nil, error)
                modifySubscriptionsResultBlock?(.failure(error))
            } else {
                modifySubscriptionsCompletionBlock?(saved, deleted, nil)
                modifySubscriptionsResultBlock?(.success(()))
            }
        } catch {
            finishFailClosed()
        }
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
