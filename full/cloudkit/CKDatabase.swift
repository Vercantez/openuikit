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

            public init(zoneID: CKRecordZone.ID) {
                self.zoneID = zoneID
            }

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

            public init(zoneID: CKRecordZone.ID, reason: Reason) {
                self.zoneID = zoneID
                self.reason = reason
            }

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

            public init(record: CKRecord) {
                self.record = record
            }

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

            public init(recordID: CKRecord.ID, recordType: CKRecord.RecordType) {
                self.recordID = recordID
                self.recordType = recordType
            }

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

    func enqueue(_ work: @escaping () -> Void) {
        CloudKitHost.schedule(work)
    }

    func withStore<T>(_ body: (CKSimulatedDatabaseState) throws -> T) throws -> T {
        guard let container else {
            throw CKSimulatedStore.error(.internalError)
        }
        return try container.simulatedState.withDatabase(databaseScope, body)
    }

    func resumeCompletion<T>(_ value: T?, _ error: (any Error)?, _ continuation: CheckedContinuation<T, any Error>) {
        if let error {
            continuation.resume(throwing: error)
        } else if let value {
            continuation.resume(returning: value)
        } else {
            continuation.resume(throwing: CKSimulatedStore.error(.internalError))
        }
    }

    open func delete(
        withRecordID recordID: CKRecord.ID,
        completionHandler: @escaping (CKRecord.ID?, (any Error)?) -> Void
    ) {
        enqueue {
            do {
                let deleted = try self.withStore { try $0.deleteRecord(recordID).get() }
                completionHandler(deleted, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    open func delete(
        withRecordZoneID zoneID: CKRecordZone.ID,
        completionHandler: @escaping (CKRecordZone.ID?, (any Error)?) -> Void
    ) {
        enqueue {
            do {
                let deleted = try self.withStore { try $0.deleteZone(zoneID).get() }
                completionHandler(deleted, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    open func allRecordZones() async throws -> [CKRecordZone] {
        try await withCheckedThrowingContinuation { continuation in
            enqueue {
                do {
                    let zones = try self.withStore { state in
                        state.zones.values.map { $0.ck_copyZone() }
                    }
                    continuation.resume(returning: zones)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    open func allSubscriptions() async throws -> [CKSubscription] {
        try await withCheckedThrowingContinuation { continuation in
            enqueue {
                do {
                    let subscriptions = try self.withStore { state in
                        state.subscriptions.values.map { $0.ck_copySubscription() }
                    }
                    continuation.resume(returning: subscriptions)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    open func fetch(
        withRecordID recordID: CKRecord.ID,
        completionHandler: @escaping (CKRecord?, (any Error)?) -> Void
    ) {
        enqueue {
            do {
                let record = try self.withStore { try $0.fetchRecord(recordID, desiredKeys: nil).get() }
                completionHandler(record, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    open func fetch(
        withRecordZoneID zoneID: CKRecordZone.ID,
        completionHandler: @escaping (CKRecordZone?, (any Error)?) -> Void
    ) {
        enqueue {
            do {
                let zone = try self.withStore { state -> CKRecordZone in
                    guard let zone = state.zone(for: zoneID) else {
                        throw CKSimulatedStore.error(.zoneNotFound)
                    }
                    return zone.ck_copyZone()
                }
                completionHandler(zone, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    open func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?) async throws -> [CKRecord] {
        let result = try await records(matching: query, inZoneWith: zoneID)
        return result
    }

    open func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, (any Error)?) -> Void) {
        enqueue {
            do {
                let saved = try self.withStore {
                    try $0.saveRecord(record, policy: .ifServerRecordUnchanged).get()
                }
                completionHandler(saved, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    open func save(_ record: CKRecord) async throws -> CKRecord {
        try await withCheckedThrowingContinuation { continuation in
            save(record) { saved, error in
                self.resumeCompletion(saved, error, continuation)
            }
        }
    }

    open func save(_ zone: CKRecordZone, completionHandler: @escaping (CKRecordZone?, (any Error)?) -> Void) {
        enqueue {
            do {
                let saved = try self.withStore { try $0.saveZone(zone).get() }
                completionHandler(saved, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    open func save(_ zone: CKRecordZone) async throws -> CKRecordZone {
        try await withCheckedThrowingContinuation { continuation in
            save(zone) { saved, error in
                self.resumeCompletion(saved, error, continuation)
            }
        }
    }

    open func save(_ subscription: CKSubscription, completionHandler: @escaping (CKSubscription?, (any Error)?) -> Void) {
        enqueue {
            do {
                let saved = try self.withStore { try $0.saveSubscription(subscription).get() }
                completionHandler(saved, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    open func save(_ subscription: CKSubscription) async throws -> CKSubscription {
        try await withCheckedThrowingContinuation { continuation in
            save(subscription) { saved, error in
                self.resumeCompletion(saved, error, continuation)
            }
        }
    }

    open func recordZones(
        for ids: [CKRecordZone.ID]
    ) async throws -> [CKRecordZone.ID: Result<CKRecordZone, any Error>] {
        try await withCheckedThrowingContinuation { continuation in
            fetch(withRecordZoneIDs: ids) { result in
                continuation.resume(with: result)
            }
        }
    }

    open func subscription(for subscriptionID: CKSubscription.ID) async throws -> CKSubscription {
        try await withCheckedThrowingContinuation { continuation in
            fetch(withSubscriptionID: subscriptionID) { subscription, error in
                self.resumeCompletion(subscription, error, continuation)
            }
        }
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
        enqueue {
            do {
                let outcome = try self.withStore {
                    $0.modifyRecords(
                        saving: recordsToSave,
                        deleting: recordIDsToDelete,
                        policy: savePolicy,
                        atomically: atomically
                    )
                }
                if let error = outcome.error {
                    completionHandler(.failure(error))
                } else {
                    completionHandler(.success((outcome.saveResults, outcome.deleteResults)))
                }
            } catch {
                completionHandler(.failure(error))
            }
        }
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
        try await withCheckedThrowingContinuation { continuation in
            modifyRecords(
                saving: recordsToSave,
                deleting: recordIDsToDelete,
                savePolicy: savePolicy,
                atomically: atomically
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    open func subscriptions(
        for ids: [CKSubscription.ID]
    ) async throws -> [CKSubscription.ID: Result<CKSubscription, any Error>] {
        try await withCheckedThrowingContinuation { continuation in
            fetch(withSubscriptionIDs: ids) { result in
                continuation.resume(with: result)
            }
        }
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
        try await withCheckedThrowingContinuation { continuation in
            fetchDatabaseChanges(since: changeToken, resultsLimit: resultsLimit) { result in
                continuation.resume(with: result)
            }
        }
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
        enqueue {
            do {
                var saveResults: [CKRecordZone.ID: Result<CKRecordZone, any Error>] = [:]
                var deleteResults: [CKRecordZone.ID: Result<Void, any Error>] = [:]
                try self.withStore { state in
                    for zone in recordZonesToSave {
                        saveResults[zone.zoneID] = state.saveZone(zone).mapError { $0 as any Error }
                    }
                    for zoneID in recordZoneIDsToDelete {
                        deleteResults[zoneID] = state.deleteZone(zoneID).map { _ in () }.mapError { $0 as any Error }
                    }
                }
                completionHandler(.success((saveResults, deleteResults)))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    open func modifyRecordZones(
        saving recordZonesToSave: [CKRecordZone],
        deleting recordZoneIDsToDelete: [CKRecordZone.ID]
    ) async throws -> (
        saveResults: [CKRecordZone.ID: Result<CKRecordZone, any Error>],
        deleteResults: [CKRecordZone.ID: Result<Void, any Error>]
    ) {
        try await withCheckedThrowingContinuation { continuation in
            modifyRecordZones(saving: recordZonesToSave, deleting: recordZoneIDsToDelete) { result in
                continuation.resume(with: result)
            }
        }
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
        try await withCheckedThrowingContinuation { continuation in
            fetchRecordZoneChanges(
                inZoneWith: zoneID,
                since: changeToken,
                desiredKeys: desiredKeys,
                resultsLimit: resultsLimit
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    @discardableResult
    open func deleteSubscription(withID subscriptionID: CKSubscription.ID) async throws -> CKSubscription.ID {
        try await withCheckedThrowingContinuation { continuation in
            delete(withSubscriptionID: subscriptionID) { deleted, error in
                self.resumeCompletion(deleted, error, continuation)
            }
        }
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
        enqueue {
            do {
                var saveResults: [CKSubscription.ID: Result<CKSubscription, any Error>] = [:]
                var deleteResults: [CKSubscription.ID: Result<Void, any Error>] = [:]
                try self.withStore { state in
                    for subscription in subscriptionsToSave {
                        saveResults[subscription.subscriptionID] =
                            state.saveSubscription(subscription).mapError { $0 as any Error }
                    }
                    for subscriptionID in subscriptionIDsToDelete {
                        deleteResults[subscriptionID] =
                            state.deleteSubscription(subscriptionID).map { _ in () }.mapError { $0 as any Error }
                    }
                }
                completionHandler(.success((saveResults, deleteResults)))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    open func modifySubscriptions(
        saving subscriptionsToSave: [CKSubscription],
        deleting subscriptionIDsToDelete: [CKSubscription.ID]
    ) async throws -> (
        saveResults: [CKSubscription.ID: Result<CKSubscription, any Error>],
        deleteResults: [CKSubscription.ID: Result<Void, any Error>]
    ) {
        try await withCheckedThrowingContinuation { continuation in
            modifySubscriptions(saving: subscriptionsToSave, deleting: subscriptionIDsToDelete) { result in
                continuation.resume(with: result)
            }
        }
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
        enqueue {
            do {
                let page = try self.withStore {
                    $0.databaseChanges(since: changeToken, limit: resultsLimit)
                }
                completionHandler(.success((page.modifications, page.deletions, page.token, page.moreComing)))
            } catch {
                completionHandler(.failure(error))
            }
        }
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
        enqueue {
            do {
                let page = try self.withStore {
                    try $0.zoneChanges(
                        in: zoneID,
                        since: changeToken,
                        desiredKeys: desiredKeys,
                        limit: resultsLimit
                    ).get()
                }
                completionHandler(.success((page.modifications, page.deletions, page.token, page.moreComing)))
            } catch {
                completionHandler(.failure(error))
            }
        }
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
        enqueue {
            do {
                let page = try self.withStore {
                    $0.queryRecords(
                        type: queryCursor.ck_recordType,
                        predicate: queryCursor.ck_predicate,
                        zoneID: queryCursor.ck_zoneID,
                        sortDescriptors: queryCursor.ck_sortDescriptors,
                        desiredKeys: desiredKeys ?? queryCursor.ck_desiredKeys,
                        offset: queryCursor.ck_offset,
                        limit: resultsLimit
                    )
                }
                let matchResults = page.matches.map { record in (record.recordID, Result<CKRecord, any Error>.success(record)) }
                completionHandler(.success((matchResults, page.cursor)))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    open func fetch(
        withRecordIDs recordIDs: [CKRecord.ID],
        desiredKeys: [CKRecord.FieldKey]? = nil,
        completionHandler: @escaping (Result<[CKRecord.ID: Result<CKRecord, any Error>], any Error>) -> Void
    ) {
        enqueue {
            do {
                let results = try self.withStore { state in
                    var map: [CKRecord.ID: Result<CKRecord, any Error>] = [:]
                    for recordID in recordIDs {
                        map[recordID] = state.fetchRecord(recordID, desiredKeys: desiredKeys).mapError { $0 as any Error }
                    }
                    return map
                }
                completionHandler(.success(results))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    open func fetch(
        withRecordZoneIDs zoneIDs: [CKRecordZone.ID],
        completionHandler: @escaping (Result<[CKRecordZone.ID: Result<CKRecordZone, any Error>], any Error>) -> Void
    ) {
        enqueue {
            do {
                let results = try self.withStore { state in
                    var map: [CKRecordZone.ID: Result<CKRecordZone, any Error>] = [:]
                    for zoneID in zoneIDs {
                        if let zone = state.zone(for: zoneID) {
                            map[zoneID] = .success(zone.ck_copyZone())
                        } else {
                            map[zoneID] = .failure(CKSimulatedStore.error(.zoneNotFound))
                        }
                    }
                    return map
                }
                completionHandler(.success(results))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    open func fetch(
        withSubscriptionID subscriptionID: CKSubscription.ID,
        completionHandler: @escaping (CKSubscription?, (any Error)?) -> Void
    ) {
        enqueue {
            do {
                let subscription = try self.withStore { try $0.fetchSubscription(subscriptionID).get() }
                completionHandler(subscription, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    open func fetch(
        withSubscriptionIDs subscriptionIDs: [CKSubscription.ID],
        completionHandler: @escaping (Result<[CKSubscription.ID: Result<CKSubscription, any Error>], any Error>) -> Void
    ) {
        enqueue {
            do {
                let results = try self.withStore { state in
                    var map: [CKSubscription.ID: Result<CKSubscription, any Error>] = [:]
                    for subscriptionID in subscriptionIDs {
                        map[subscriptionID] = state.fetchSubscription(subscriptionID).mapError { $0 as any Error }
                    }
                    return map
                }
                completionHandler(.success(results))
            } catch {
                completionHandler(.failure(error))
            }
        }
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
        enqueue {
            do {
                let page = try self.withStore { state -> (matches: [CKRecord], cursor: CKQueryOperation.Cursor?) in
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
                let matchResults = page.matches.map { record in (record.recordID, Result<CKRecord, any Error>.success(record)) }
                completionHandler(.success((matchResults, page.cursor)))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    open func delete(
        withSubscriptionID subscriptionID: CKSubscription.ID,
        completionHandler: @escaping (String?, (any Error)?) -> Void
    ) {
        enqueue {
            do {
                let deleted = try self.withStore { try $0.deleteSubscription(subscriptionID).get() }
                completionHandler(deleted, nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    open func records(
        continuingMatchFrom queryCursor: CKQueryOperation.Cursor,
        desiredKeys: [CKRecord.FieldKey]? = nil,
        resultsLimit: Int = CKQueryOperation.maximumResults
    ) async throws -> (
        matchResults: [(CKRecord.ID, Result<CKRecord, any Error>)],
        queryCursor: CKQueryOperation.Cursor?
    ) {
        try await withCheckedThrowingContinuation { continuation in
            fetch(withCursor: queryCursor, desiredKeys: desiredKeys, resultsLimit: resultsLimit) { result in
                continuation.resume(with: result)
            }
        }
    }

    open func records(
        for ids: [CKRecord.ID],
        desiredKeys: [CKRecord.FieldKey]? = nil
    ) async throws -> [CKRecord.ID: Result<CKRecord, any Error>] {
        try await withCheckedThrowingContinuation { continuation in
            fetch(withRecordIDs: ids, desiredKeys: desiredKeys) { result in
                continuation.resume(with: result)
            }
        }
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
        try await withCheckedThrowingContinuation { continuation in
            fetch(withQuery: query, inZoneWith: zoneID, desiredKeys: desiredKeys, resultsLimit: resultsLimit) { result in
                continuation.resume(with: result)
            }
        }
    }

    open func records(
        matching query: CKQuery,
        inZoneWith zoneID: CKRecordZone.ID?
    ) async throws -> [CKRecord] {
        let page = try await records(
            matching: query,
            inZoneWith: zoneID,
            desiredKeys: nil,
            resultsLimit: CKQueryOperation.maximumResults
        )
        return try page.matchResults.map { _, result in try result.get() }
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
