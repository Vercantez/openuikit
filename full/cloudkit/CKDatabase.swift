import Foundation

open class CKDatabase: NSObject, @unchecked Sendable {
    public enum Scope: Int, Sendable, Hashable {
        case `public` = 1
        case `private` = 2
        case shared = 3
    }

    public enum DatabaseChange: Sendable {
        public struct Modification: Hashable, Sendable {
            public let zoneID: CKRecordZone.ID

            public static func == (a: Modification, b: Modification) -> Bool {
                a.zoneID.isEqual(b.zoneID)
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(zoneID.hash)
            }
        }

        public struct Deletion: Hashable, Sendable {
            public enum Reason: Hashable, Sendable {
                case deleted
                case purged
                case encryptedDataReset
            }

            public let zoneID: CKRecordZone.ID
            public let reason: Reason

            public var purged: Bool { reason == .purged }

            public static func == (a: Deletion, b: Deletion) -> Bool {
                a.zoneID.isEqual(b.zoneID) && a.reason == b.reason
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(zoneID.hash)
                hasher.combine(reason)
            }
        }
    }

    public enum RecordZoneChange: Sendable {
        public struct Modification: Hashable, @unchecked Sendable {
            public let record: CKRecord

            public static func == (a: Modification, b: Modification) -> Bool {
                a.record.recordID.isEqual(b.record.recordID)
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(record.recordID.hash)
            }
        }

        public struct Deletion: Hashable, Sendable {
            public let recordID: CKRecord.ID
            public let recordType: CKRecord.RecordType

            public static func == (a: Deletion, b: Deletion) -> Bool {
                a.recordID.isEqual(b.recordID) && a.recordType == b.recordType
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(recordID.hash)
                hasher.combine(recordType)
            }
        }
    }

    open private(set) var databaseScope: CKDatabase.Scope
    weak var container: CKContainer?

    init(scope: CKDatabase.Scope) {
        self.databaseScope = scope
        super.init()
    }

    func attach(container: CKContainer) {
        self.container = container
    }

    open func add(_ operation: CKDatabaseOperation) {
        operation.database = self
        operation.container = container
        CloudKitHost.schedule(operation)
    }

    open func delete(
        withRecordID recordID: CKRecord.ID,
        completionHandler: @escaping (CKRecord.ID?, (any Error)?) -> Void
    ) {
        _ = recordID
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func delete(
        withRecordZoneID zoneID: CKRecordZone.ID,
        completionHandler: @escaping (CKRecordZone.ID?, (any Error)?) -> Void
    ) {
        _ = zoneID
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func allRecordZones() async throws -> [CKRecordZone] {
        try CloudKitHost.fail()
    }

    open func allSubscriptions() async throws -> [CKSubscription] {
        try CloudKitHost.fail()
    }

    open func fetch(
        withRecordID recordID: CKRecord.ID,
        completionHandler: @escaping (CKRecord?, (any Error)?) -> Void
    ) {
        _ = recordID
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func fetch(
        withRecordZoneID zoneID: CKRecordZone.ID,
        completionHandler: @escaping (CKRecordZone?, (any Error)?) -> Void
    ) {
        _ = zoneID
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?) async throws -> [CKRecord] {
        _ = (query, zoneID)
        return try CloudKitHost.fail()
    }

    open func save(_ record: CKRecord) async throws -> CKRecord {
        _ = record
        return try CloudKitHost.fail()
    }

    open func save(_ zone: CKRecordZone) async throws -> CKRecordZone {
        _ = zone
        return try CloudKitHost.fail()
    }

    open func save(_ subscription: CKSubscription) async throws -> CKSubscription {
        _ = subscription
        return try CloudKitHost.fail()
    }

    open func recordZones(
        for ids: [CKRecordZone.ID]
    ) async throws -> [CKRecordZone.ID: Result<CKRecordZone, any Error>] {
        _ = ids
        throw CloudKitHost.unsupportedError()
    }

    open func subscription(for subscriptionID: CKSubscription.ID) async throws -> CKSubscription {
        _ = subscriptionID
        return try CloudKitHost.fail()
    }

    open func modifyRecords(
        saving recordsToSave: [CKRecord],
        deleting recordIDsToDelete: [CKRecord.ID],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy,
        atomically: Bool,
        completionHandler: @escaping (
            Result<(
                saveResults: [CKRecord.ID: Result<CKRecord, any Error>],
                deleteResults: [CKRecord.ID: Result<Void, any Error>]
            ), any Error>
        ) -> Void
    ) {
        _ = (recordsToSave, recordIDsToDelete, savePolicy, atomically)
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func modifyRecords(
        saving recordsToSave: [CKRecord],
        deleting recordIDsToDelete: [CKRecord.ID],
        savePolicy: CKModifyRecordsOperation.RecordSavePolicy,
        atomically: Bool
    ) async throws -> (
        saveResults: [CKRecord.ID: Result<CKRecord, any Error>],
        deleteResults: [CKRecord.ID: Result<Void, any Error>]
    ) {
        _ = (recordsToSave, recordIDsToDelete, savePolicy, atomically)
        throw CloudKitHost.unsupportedError()
    }

    open func subscriptions(
        for ids: [CKSubscription.ID]
    ) async throws -> [CKSubscription.ID: Result<CKSubscription, any Error>] {
        _ = ids
        throw CloudKitHost.unsupportedError()
    }

    open func databaseChanges(
        since changeToken: CKServerChangeToken?,
        resultsLimit: Int? = nil
    ) async throws -> (
        modifications: [CKDatabase.DatabaseChange.Modification],
        deletions: [CKDatabase.DatabaseChange.Deletion],
        changeToken: CKServerChangeToken,
        moreComing: Bool
    ) {
        _ = (changeToken, resultsLimit)
        throw CloudKitHost.unsupportedError()
    }

    open func modifyRecordZones(
        saving recordZonesToSave: [CKRecordZone],
        deleting recordZoneIDsToDelete: [CKRecordZone.ID],
        completionHandler: @escaping (
            Result<(
                saveResults: [CKRecordZone.ID: Result<CKRecordZone, any Error>],
                deleteResults: [CKRecordZone.ID: Result<Void, any Error>]
            ), any Error>
        ) -> Void
    ) {
        _ = (recordZonesToSave, recordZoneIDsToDelete)
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func modifyRecordZones(
        saving recordZonesToSave: [CKRecordZone],
        deleting recordZoneIDsToDelete: [CKRecordZone.ID]
    ) async throws -> (
        saveResults: [CKRecordZone.ID: Result<CKRecordZone, any Error>],
        deleteResults: [CKRecordZone.ID: Result<Void, any Error>]
    ) {
        _ = (recordZonesToSave, recordZoneIDsToDelete)
        throw CloudKitHost.unsupportedError()
    }

    open func recordZoneChanges(
        inZoneWith zoneID: CKRecordZone.ID,
        since changeToken: CKServerChangeToken?,
        desiredKeys: [CKRecord.FieldKey]? = nil,
        resultsLimit: Int? = nil
    ) async throws -> (
        modificationResultsByID: [CKRecord.ID: Result<CKDatabase.RecordZoneChange.Modification, any Error>],
        deletions: [CKDatabase.RecordZoneChange.Deletion],
        changeToken: CKServerChangeToken,
        moreComing: Bool
    ) {
        _ = (zoneID, changeToken, desiredKeys, resultsLimit)
        throw CloudKitHost.unsupportedError()
    }

    @discardableResult
    open func deleteSubscription(withID subscriptionID: CKSubscription.ID) async throws -> CKSubscription.ID {
        _ = subscriptionID
        return try CloudKitHost.fail()
    }

    open func modifySubscriptions(
        saving subscriptionsToSave: [CKSubscription],
        deleting subscriptionIDsToDelete: [CKSubscription.ID],
        completionHandler: @escaping (
            Result<(
                saveResults: [CKSubscription.ID: Result<CKSubscription, any Error>],
                deleteResults: [CKSubscription.ID: Result<Void, any Error>]
            ), any Error>
        ) -> Void
    ) {
        _ = (subscriptionsToSave, subscriptionIDsToDelete)
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func modifySubscriptions(
        saving subscriptionsToSave: [CKSubscription],
        deleting subscriptionIDsToDelete: [CKSubscription.ID]
    ) async throws -> (
        saveResults: [CKSubscription.ID: Result<CKSubscription, any Error>],
        deleteResults: [CKSubscription.ID: Result<Void, any Error>]
    ) {
        _ = (subscriptionsToSave, subscriptionIDsToDelete)
        throw CloudKitHost.unsupportedError()
    }

    open func fetchDatabaseChanges(
        since changeToken: CKServerChangeToken?,
        resultsLimit: Int? = nil,
        completionHandler: @escaping (
            Result<(
                modifications: [CKDatabase.DatabaseChange.Modification],
                deletions: [CKDatabase.DatabaseChange.Deletion],
                changeToken: CKServerChangeToken,
                moreComing: Bool
            ), any Error>
        ) -> Void
    ) {
        _ = (changeToken, resultsLimit)
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func fetchRecordZoneChanges(
        inZoneWith zoneID: CKRecordZone.ID,
        since changeToken: CKServerChangeToken?,
        desiredKeys: [CKRecord.FieldKey]? = nil,
        resultsLimit: Int? = nil,
        completionHandler: @escaping (
            Result<(
                modificationResultsByID: [CKRecord.ID: Result<CKDatabase.RecordZoneChange.Modification, any Error>],
                deletions: [CKDatabase.RecordZoneChange.Deletion],
                changeToken: CKServerChangeToken,
                moreComing: Bool
            ), any Error>
        ) -> Void
    ) {
        _ = (zoneID, changeToken, desiredKeys, resultsLimit)
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func fetch(
        withCursor queryCursor: CKQueryOperation.Cursor,
        desiredKeys: [CKRecord.FieldKey]? = nil,
        resultsLimit: Int = CKQueryOperation.maximumResults,
        completionHandler: @escaping (
            Result<(
                matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)],
                queryCursor: CKQueryOperation.Cursor?
            ), any Error>
        ) -> Void
    ) {
        _ = (queryCursor, desiredKeys, resultsLimit)
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func fetch(
        withRecordIDs recordIDs: [CKRecord.ID],
        desiredKeys: [CKRecord.FieldKey]? = nil,
        completionHandler: @escaping (Result<[CKRecord.ID: Result<CKRecord, any Error>], any Error>) -> Void
    ) {
        _ = (recordIDs, desiredKeys)
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func fetch(
        withRecordZoneIDs zoneIDs: [CKRecordZone.ID],
        completionHandler: @escaping (Result<[CKRecordZone.ID: Result<CKRecordZone, any Error>], any Error>) -> Void
    ) {
        _ = zoneIDs
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func fetch(
        withSubscriptionID subscriptionID: CKSubscription.ID,
        completionHandler: @escaping (CKSubscription?, (any Error)?) -> Void
    ) {
        _ = subscriptionID
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func fetch(
        withSubscriptionIDs subscriptionIDs: [CKSubscription.ID],
        completionHandler: @escaping (Result<[CKSubscription.ID: Result<CKSubscription, any Error>], any Error>) -> Void
    ) {
        _ = subscriptionIDs
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func fetch(
        withQuery query: CKQuery,
        inZoneWith zoneID: CKRecordZone.ID? = nil,
        desiredKeys: [CKRecord.FieldKey]? = nil,
        resultsLimit: Int = CKQueryOperation.maximumResults,
        completionHandler: @escaping (
            Result<(
                matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)],
                queryCursor: CKQueryOperation.Cursor?
            ), any Error>
        ) -> Void
    ) {
        _ = (query, zoneID, desiredKeys, resultsLimit)
        completionHandler(.failure(CloudKitHost.unsupportedError()))
    }

    open func delete(
        withSubscriptionID subscriptionID: CKSubscription.ID,
        completionHandler: @escaping (String?, (any Error)?) -> Void
    ) {
        _ = subscriptionID
        CloudKitHost.completeUnsupported(completionHandler)
    }

    open func records(
        continuingMatchFrom queryCursor: CKQueryOperation.Cursor,
        desiredKeys: [CKRecord.FieldKey]? = nil,
        resultsLimit: Int = CKQueryOperation.maximumResults
    ) async throws -> (
        matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)],
        queryCursor: CKQueryOperation.Cursor?
    ) {
        _ = (queryCursor, desiredKeys, resultsLimit)
        throw CloudKitHost.unsupportedError()
    }

    open func records(
        for ids: [CKRecord.ID],
        desiredKeys: [CKRecord.FieldKey]? = nil
    ) async throws -> [CKRecord.ID: Result<CKRecord, any Error>] {
        _ = (ids, desiredKeys)
        throw CloudKitHost.unsupportedError()
    }

    open func records(
        matching query: CKQuery,
        inZoneWith zoneID: CKRecordZone.ID? = nil,
        desiredKeys: [CKRecord.FieldKey]? = nil,
        resultsLimit: Int = CKQueryOperation.maximumResults
    ) async throws -> (
        matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)],
        queryCursor: CKQueryOperation.Cursor?
    ) {
        _ = (query, zoneID, desiredKeys, resultsLimit)
        throw CloudKitHost.unsupportedError()
    }

    open func records(
        matching query: CKQuery,
        inZoneWith zoneID: CKRecordZone.ID?
    ) async throws -> [CKRecord] {
        _ = (query, zoneID)
        return try CloudKitHost.fail()
    }

    @discardableResult
    open func configuredWith<R>(
        configuration: CKOperation.Configuration? = nil,
        group: CKOperationGroup? = nil,
        body: (CKDatabase) throws -> R
    ) rethrows -> R {
        _ = (configuration, group)
        return try body(self)
    }

    @discardableResult
    open func configuredWith<R>(
        configuration: CKOperation.Configuration? = nil,
        group: CKOperationGroup? = nil,
        body: (CKDatabase) async throws -> R
    ) async rethrows -> R {
        _ = (configuration, group)
        return try await body(self)
    }
}
