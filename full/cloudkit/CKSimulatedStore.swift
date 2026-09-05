import Foundation

/// In-process CloudKit container. Linux has no iCloud daemon; this store is
/// the local stand-in so app save/fetch/query/modify paths run. Sharing and
/// identity discovery stay fail-closed.
///
/// Default page size when `CKQueryOperation.maximumResults` (0) is used:
/// 100, the documented "server chooses" substitute for this simulator
/// (CloudKitRuntime query-cursor probe).
enum CloudKitSimulation {
    static let defaultQueryLimit = 100
}

struct CKZoneKey: Hashable {
    let zoneName: String
    let ownerName: String

    init(_ zoneID: CKRecordZone.ID) {
        zoneName = zoneID.zoneName
        ownerName = zoneID.ownerName
    }
}

struct CKRecordKey: Hashable {
    let recordName: String
    let zoneName: String
    let ownerName: String

    init(_ recordID: CKRecord.ID) {
        recordName = recordID.recordName
        zoneName = recordID.zoneID.zoneName
        ownerName = recordID.zoneID.ownerName
    }
}

enum CKDatabaseChangeEvent {
    case modified(CKRecordZone.ID)
    case deleted(CKRecordZone.ID, CKDatabase.DatabaseChange.Deletion.Reason)
}

enum CKZoneChangeEvent {
    case modified(CKRecord)
    case deleted(CKRecord.ID, CKRecord.RecordType)
}

final class CKSimulatedContainerState: @unchecked Sendable {
    let identifier: String?
    let lock = NSLock()
    var offline = false
    let publicDatabase: CKSimulatedDatabaseState
    let privateDatabase: CKSimulatedDatabaseState
    let sharedDatabase: CKSimulatedDatabaseState
    let userRecordID: CKRecord.ID

    init(identifier: String?) {
        self.identifier = identifier
        self.userRecordID = CKRecord.ID(
            recordName: "local-user",
            zoneID: .default
        )
        let assets = CKSimulatedDatabaseState.makeAssetDirectory()
        self.publicDatabase = CKSimulatedDatabaseState(assetDirectory: assets)
        self.privateDatabase = CKSimulatedDatabaseState(assetDirectory: assets)
        self.sharedDatabase = CKSimulatedDatabaseState(assetDirectory: assets)
    }

    func database(for scope: CKDatabase.Scope) -> CKSimulatedDatabaseState {
        switch scope {
        case .public: return publicDatabase
        case .private: return privateDatabase
        case .shared: return sharedDatabase
        }
    }
}

final class CKSimulatedDatabaseState: @unchecked Sendable {
    var zones: [CKZoneKey: CKRecordZone] = [:]
    var records: [CKRecordKey: CKRecord] = [:]
    var subscriptions: [CKSubscription.ID: CKSubscription] = [:]
    var databaseLog: [CKDatabaseChangeEvent] = []
    var zoneLogs: [CKZoneKey: [CKZoneChangeEvent]] = [:]
    var nextChangeTag: UInt64 = 1
    let assetDirectory: URL

    init(assetDirectory: URL) {
        self.assetDirectory = assetDirectory
        let defaultZone = CKRecordZone(zoneID: .default)
        defaultZone.ck_setCapabilities([.fetchChanges, .atomic])
        zones[CKZoneKey(.default)] = defaultZone
    }

    static func makeAssetDirectory() -> URL {
        let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("openuikit-cloudkit-assets", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    func zone(for id: CKRecordZone.ID) -> CKRecordZone? {
        zones[CKZoneKey(id)]
    }

    func ensureDefaultZone() {
        if zones[CKZoneKey(.default)] == nil {
            let zone = CKRecordZone(zoneID: .default)
            zone.ck_setCapabilities([.fetchChanges, .atomic])
            zones[CKZoneKey(.default)] = zone
        }
    }
}

enum CKSimulatedStore {
    static func error(_ code: CKError.Code, userInfo: [String: Any] = [:]) -> CKError {
        CKError(code, userInfo: userInfo)
    }

    static func partialFailure(_ items: [AnyHashable: any Error]) -> CKError {
        error(.partialFailure, userInfo: [CKPartialErrorsByItemIDKey: items])
    }

    static func serverRecordChanged(client: CKRecord, server: CKRecord) -> CKError {
        error(
            .serverRecordChanged,
            userInfo: [
                CKRecordChangedErrorClientRecordKey: client.ck_copy(),
                CKRecordChangedErrorServerRecordKey: server.ck_copy(),
                CKRecordChangedErrorAncestorRecordKey: server.ck_copy(),
            ]
        )
    }

    static func resolvedLimit(_ requested: Int) -> Int {
        requested > 0 ? requested : CloudKitSimulation.defaultQueryLimit
    }
}

// MARK: - Zone / record / subscription mutation

extension CKSimulatedDatabaseState {
    func saveZone(_ zone: CKRecordZone) -> Result<CKRecordZone, CKError> {
        if zone.zoneID.zoneName.isEmpty {
            return .failure(CKSimulatedStore.error(.invalidArguments))
        }
        let key = CKZoneKey(zone.zoneID)
        let stored = zone.ck_copyZone()
        stored.ck_setCapabilities([.fetchChanges, .atomic, .sharing])
        zones[key] = stored
        databaseLog.append(.modified(zone.zoneID))
        return .success(stored.ck_copyZone())
    }

    func deleteZone(_ zoneID: CKRecordZone.ID) -> Result<CKRecordZone.ID, CKError> {
        if zoneID.isEqual(CKRecordZone.ID.default) {
            return .failure(CKSimulatedStore.error(.invalidArguments))
        }
        let key = CKZoneKey(zoneID)
        guard zones[key] != nil else {
            return .failure(CKSimulatedStore.error(.zoneNotFound))
        }
        zones.removeValue(forKey: key)
        let doomed = records.keys.filter { $0.zoneName == key.zoneName && $0.ownerName == key.ownerName }
        for recordKey in doomed {
            records.removeValue(forKey: recordKey)
        }
        zoneLogs[key] = []
        databaseLog.append(.deleted(zoneID, .deleted))
        return .success(zoneID)
    }

    func ingestAsset(_ asset: CKAsset) throws -> CKAsset {
        guard let url = asset.fileURL else {
            throw CKSimulatedStore.error(.assetNotAvailable)
        }
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        if !exists || isDirectory.boolValue {
            throw CKSimulatedStore.error(.assetFileNotFound)
        }
        let dest = assetDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        do {
            try FileManager.default.copyItem(at: url, to: dest)
        } catch {
            throw CKSimulatedStore.error(.assetFileNotFound)
        }
        return CKAsset(fileURL: dest)
    }

    func ingestValue(_ value: any CKRecordValue) throws -> any CKRecordValue {
        if let asset = value as? CKAsset {
            return try ingestAsset(asset)
        }
        if let assets = value as? [CKAsset] {
            return try assets.map { try ingestAsset($0) }
        }
        return value
    }

    func saveRecord(
        _ client: CKRecord,
        policy: CKModifyRecordsOperation.RecordSavePolicy
    ) -> Result<CKRecord, CKError> {
        let zoneID = client.recordID.zoneID
        guard zone(for: zoneID) != nil else {
            return .failure(CKSimulatedStore.error(.zoneNotFound))
        }
        let key = CKRecordKey(client.recordID)
        let existing = records[key]
        if policy == .ifServerRecordUnchanged, let existing {
            let clientTag = client.recordChangeTag
            let serverTag = existing.recordChangeTag
            if clientTag == nil || clientTag != serverTag {
                return .failure(CKSimulatedStore.serverRecordChanged(client: client, server: existing))
            }
        }
        let stored: CKRecord
        if let existing, policy == .changedKeys {
            stored = existing.ck_copy()
            stored.ck_mergeChanged(from: client)
        } else {
            stored = client.ck_copy()
        }
        do {
            try stored.ck_ingestAssets(using: self)
        } catch let ckError as CKError {
            return .failure(ckError)
        } catch {
            return .failure(CKSimulatedStore.error(.assetFileNotFound))
        }
        let now = Date()
        let tag = "e\(nextChangeTag)"
        nextChangeTag += 1
        let created = existing?.creationDate ?? now
        let creator = existing?.creatorUserRecordID ?? CKRecord.ID(
            recordName: CKRecordTypeUserRecord,
            zoneID: .default
        )
        stored.ck_setSystemFields(
            changeTag: tag,
            creationDate: created,
            modificationDate: now,
            creator: creator,
            lastModified: creator,
            share: existing?.share ?? client.share
        )
        stored.ck_clearChangedKeys()
        records[key] = stored
        zoneLogs[CKZoneKey(zoneID), default: []].append(.modified(stored.ck_copy()))
        databaseLog.append(.modified(zoneID))
        return .success(stored.ck_copy())
    }

    func deleteRecord(_ recordID: CKRecord.ID) -> Result<CKRecord.ID, CKError> {
        let key = CKRecordKey(recordID)
        guard let existing = records.removeValue(forKey: key) else {
            return .failure(CKSimulatedStore.error(.unknownItem))
        }
        zoneLogs[CKZoneKey(recordID.zoneID), default: []].append(
            .deleted(recordID, existing.recordType)
        )
        databaseLog.append(.modified(recordID.zoneID))
        return .success(recordID)
    }

    func fetchRecord(_ recordID: CKRecord.ID, desiredKeys: [CKRecord.FieldKey]?) -> Result<CKRecord, CKError> {
        guard zone(for: recordID.zoneID) != nil else {
            return .failure(CKSimulatedStore.error(.zoneNotFound))
        }
        guard let stored = records[CKRecordKey(recordID)] else {
            return .failure(CKSimulatedStore.error(.unknownItem))
        }
        return .success(stored.ck_copy(desiredKeys: desiredKeys))
    }

    func saveSubscription(_ subscription: CKSubscription) -> Result<CKSubscription, CKError> {
        let stored = subscription.ck_copySubscription()
        subscriptions[stored.subscriptionID] = stored
        return .success(stored.ck_copySubscription())
    }

    func deleteSubscription(_ subscriptionID: CKSubscription.ID) -> Result<CKSubscription.ID, CKError> {
        guard subscriptions.removeValue(forKey: subscriptionID) != nil else {
            return .failure(CKSimulatedStore.error(.unknownItem))
        }
        return .success(subscriptionID)
    }

    func fetchSubscription(_ subscriptionID: CKSubscription.ID) -> Result<CKSubscription, CKError> {
        guard let stored = subscriptions[subscriptionID] else {
            return .failure(CKSimulatedStore.error(.unknownItem))
        }
        return .success(stored.ck_copySubscription())
    }

    struct RecordModifyOutcome {
        var saved: [CKRecord] = []
        var deleted: [CKRecord.ID] = []
        var saveResults: [CKRecord.ID: Result<CKRecord, any Error>] = [:]
        var deleteResults: [CKRecord.ID: Result<Void, any Error>] = [:]
        var error: CKError?
    }

    func modifyRecords(
        saving recordsToSave: [CKRecord],
        deleting recordIDsToDelete: [CKRecord.ID],
        policy: CKModifyRecordsOperation.RecordSavePolicy,
        atomically: Bool
    ) -> RecordModifyOutcome {
        var outcome = RecordModifyOutcome()
        if atomically {
            let snapshotRecords = records
            let snapshotZones = zones
            let snapshotLogs = zoneLogs
            let snapshotDatabaseLog = databaseLog
            let snapshotTag = nextChangeTag
            var failed = false
            for record in recordsToSave {
                let result = saveRecord(record, policy: policy)
                outcome.saveResults[record.recordID] = result.mapError { $0 as any Error }
                switch result {
                case .success(let saved):
                    outcome.saved.append(saved)
                case .failure:
                    failed = true
                }
            }
            for recordID in recordIDsToDelete {
                let result = deleteRecord(recordID)
                outcome.deleteResults[recordID] = result.map { _ in () }.mapError { $0 as any Error }
                switch result {
                case .success(let deleted):
                    outcome.deleted.append(deleted)
                case .failure:
                    failed = true
                }
            }
            if failed {
                records = snapshotRecords
                zones = snapshotZones
                zoneLogs = snapshotLogs
                databaseLog = snapshotDatabaseLog
                nextChangeTag = snapshotTag
                var partial: [AnyHashable: any Error] = [:]
                for record in recordsToSave {
                    if case .failure(let error) = outcome.saveResults[record.recordID] {
                        partial[record.recordID] = error
                    } else {
                        let batch = CKSimulatedStore.error(.batchRequestFailed)
                        outcome.saveResults[record.recordID] = .failure(batch)
                        partial[record.recordID] = batch
                    }
                }
                for recordID in recordIDsToDelete {
                    if case .failure(let error) = outcome.deleteResults[recordID] {
                        partial[recordID] = error
                    } else {
                        let batch = CKSimulatedStore.error(.batchRequestFailed)
                        outcome.deleteResults[recordID] = .failure(batch)
                        partial[recordID] = batch
                    }
                }
                outcome.saved = []
                outcome.deleted = []
                outcome.error = CKSimulatedStore.partialFailure(partial)
            }
            return outcome
        }
        var partial: [AnyHashable: any Error] = [:]
        for record in recordsToSave {
            let result = saveRecord(record, policy: policy)
            outcome.saveResults[record.recordID] = result.mapError { $0 as any Error }
            switch result {
            case .success(let saved):
                outcome.saved.append(saved)
            case .failure(let error):
                partial[record.recordID] = error
            }
        }
        for recordID in recordIDsToDelete {
            let result = deleteRecord(recordID)
            outcome.deleteResults[recordID] = result.map { _ in () }.mapError { $0 as any Error }
            switch result {
            case .success(let deleted):
                outcome.deleted.append(deleted)
            case .failure(let error):
                partial[recordID] = error
            }
        }
        if !partial.isEmpty {
            outcome.error = CKSimulatedStore.partialFailure(partial)
        }
        return outcome
    }
}

// MARK: - Query

extension CKSimulatedDatabaseState {
    func queryRecords(
        type recordType: CKRecord.RecordType,
        predicate: NSPredicate,
        zoneID: CKRecordZone.ID?,
        sortDescriptors: [NSSortDescriptor]?,
        desiredKeys: [CKRecord.FieldKey]?,
        offset: Int,
        limit: Int
    ) -> (matches: [CKRecord], cursor: CKQueryOperation.Cursor?) {
        if let zoneID, zone(for: zoneID) == nil {
            return ([], nil)
        }
        var matches: [CKRecord] = []
        for record in records.values {
            if record.recordType != recordType { continue }
            if let zoneID, !record.recordID.zoneID.isEqual(zoneID) { continue }
            if predicate.evaluate(with: record) {
                matches.append(record.ck_copy(desiredKeys: desiredKeys))
            }
        }
        if let sortDescriptors, !sortDescriptors.isEmpty {
            matches.sort { lhs, rhs in
                for descriptor in sortDescriptors {
                    let result = descriptor.compare(lhs, to: rhs)
                    if result == .orderedSame { continue }
                    return result == .orderedAscending
                }
                return false
            }
        } else {
            matches.sort { $0.recordID.recordName < $1.recordID.recordName }
        }
        let pageLimit = CKSimulatedStore.resolvedLimit(limit)
        let start = min(max(offset, 0), matches.count)
        let end = min(start + pageLimit, matches.count)
        let page = Array(matches[start..<end])
        let cursor: CKQueryOperation.Cursor?
        if end < matches.count {
            cursor = CKQueryOperation.Cursor.ck_make(
                recordType: recordType,
                predicate: predicate,
                zoneID: zoneID,
                sortDescriptors: sortDescriptors,
                desiredKeys: desiredKeys,
                offset: end
            )
        } else {
            cursor = nil
        }
        return (page, cursor)
    }

    func databaseChanges(
        since token: CKServerChangeToken?,
        limit: Int?
    ) -> (
        modifications: [CKDatabase.DatabaseChange.Modification],
        deletions: [CKDatabase.DatabaseChange.Deletion],
        token: CKServerChangeToken,
        moreComing: Bool
    ) {
        let start = Int(token?.ck_sequence ?? 0)
        if start > databaseLog.count {
            return ([], [], CKServerChangeToken.ck_make(sequence: UInt64(databaseLog.count)), false)
        }
        let pageLimit = limit ?? databaseLog.count
        let sliceEnd = min(start + max(pageLimit, 0), databaseLog.count)
        var modifications: [CKDatabase.DatabaseChange.Modification] = []
        var deletions: [CKDatabase.DatabaseChange.Deletion] = []
        var seenZones = Set<CKZoneKey>()
        for event in databaseLog[start..<sliceEnd] {
            switch event {
            case .modified(let zoneID):
                let key = CKZoneKey(zoneID)
                if seenZones.contains(key) { continue }
                seenZones.insert(key)
                modifications.append(CKDatabase.DatabaseChange.Modification(zoneID: zoneID))
            case .deleted(let zoneID, let reason):
                deletions.append(CKDatabase.DatabaseChange.Deletion(zoneID: zoneID, reason: reason))
            }
        }
        return (
            modifications,
            deletions,
            CKServerChangeToken.ck_make(sequence: UInt64(sliceEnd)),
            sliceEnd < databaseLog.count
        )
    }

    func zoneChanges(
        in zoneID: CKRecordZone.ID,
        since token: CKServerChangeToken?,
        desiredKeys: [CKRecord.FieldKey]?,
        limit: Int?
    ) -> Result<(
        modifications: [CKRecord.ID: Result<CKDatabase.RecordZoneChange.Modification, any Error>],
        deletions: [CKDatabase.RecordZoneChange.Deletion],
        token: CKServerChangeToken,
        moreComing: Bool
    ), CKError> {
        guard zone(for: zoneID) != nil else {
            return .failure(CKSimulatedStore.error(.zoneNotFound))
        }
        let log = zoneLogs[CKZoneKey(zoneID)] ?? []
        let start = Int(token?.ck_sequence ?? 0)
        if start > log.count {
            return .failure(CKSimulatedStore.error(.changeTokenExpired))
        }
        let pageLimit = limit ?? log.count
        let sliceEnd = min(start + max(pageLimit, 0), log.count)
        var modifications: [CKRecord.ID: Result<CKDatabase.RecordZoneChange.Modification, any Error>] = [:]
        var deletions: [CKDatabase.RecordZoneChange.Deletion] = []
        for event in log[start..<sliceEnd] {
            switch event {
            case .modified(let record):
                let copy = record.ck_copy(desiredKeys: desiredKeys)
                modifications[copy.recordID] = .success(
                    CKDatabase.RecordZoneChange.Modification(record: copy)
                )
            case .deleted(let recordID, let recordType):
                deletions.append(
                    CKDatabase.RecordZoneChange.Deletion(recordID: recordID, recordType: recordType)
                )
            }
        }
        return .success((
            modifications,
            deletions,
            CKServerChangeToken.ck_make(sequence: UInt64(sliceEnd)),
            sliceEnd < log.count
        ))
    }
}

final class CKRecordPredicateTarget: NSObject {
    private let values: [String: Any]

    init(_ record: CKRecord) {
        var map: [String: Any] = [:]
        for key in record.allKeys() {
            if let value = record.object(forKey: key) {
                map[key] = CKRecordPredicateTarget.boxed(value)
            }
        }
        self.values = map
        super.init()
    }

    func value(forUndefinedKey key: String) -> Any? {
        nil
    }

    static func boxed(_ value: any CKRecordValue) -> Any {
        if let number = value as? NSNumber { return number }
        if let text = value as? String { return text }
        if let text = value as? NSString { return text }
        if let date = value as? Date { return date }
        if let data = value as? Data { return data }
        if let asset = value as? CKAsset { return asset }
        if let reference = value as? CKRecord.Reference { return reference }
        if let values = value as? [any CKRecordValue] {
            return values.map { boxed($0) }
        }
        return value
    }
}

extension CKSimulatedContainerState {
    func withDatabase<T>(
        _ scope: CKDatabase.Scope,
        _ body: (CKSimulatedDatabaseState) throws -> T
    ) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        if offline {
            throw CKSimulatedStore.error(.networkUnavailable)
        }
        return try body(database(for: scope))
    }
}
