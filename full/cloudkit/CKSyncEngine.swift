import Foundation

// MARK: - C enumerations
//
// Integer values follow the public CloudKit header NS_ENUM order. They are
// not a claim that an Apple CKSyncEngine daemon exists on Linux.

public enum CKSyncEngineEventType: Int, Sendable, Hashable {
    case stateUpdate = 0
    case accountChange = 1
    case fetchedDatabaseChanges = 2
    case fetchedRecordZoneChanges = 3
    case sentDatabaseChanges = 4
    case sentRecordZoneChanges = 5
    case willFetchChanges = 6
    case willFetchRecordZoneChanges = 7
    case didFetchRecordZoneChanges = 8
    case willSendChanges = 9
    case didFetchChanges = 10
    case didSendChanges = 11
}

public enum CKSyncEngineAccountChangeType: Int, Sendable, Hashable {
    case signIn = 0
    case signOut = 1
    case switchAccounts = 2
}

public enum CKSyncEnginePendingDatabaseChangeType: Int, Sendable, Hashable {
    case saveZone = 0
    case deleteZone = 1
}

public enum CKSyncEnginePendingRecordZoneChangeType: Int, Sendable, Hashable {
    case saveRecord = 0
    case deleteRecord = 1
}

public enum CKSyncEngineSyncReason: Int, Sendable, Hashable {
    case scheduled = 0
    case manual = 1
}

public enum CKSyncEngineZoneDeletionReason: Int, Sendable, Hashable {
    case deleted = 0
    case purged = 1
    case encryptedDataReset = 2
}

// MARK: - Delegate

public protocol CKSyncEngineDelegate: AnyObject, Sendable {
    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async
    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch?
    func nextFetchChangesOptions(
        _ context: CKSyncEngine.FetchChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.FetchChangesOptions
}

extension CKSyncEngineDelegate {
    public func nextFetchChangesOptions(
        _ context: CKSyncEngine.FetchChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.FetchChangesOptions {
        _ = syncEngine
        return context.options
    }
}

// MARK: - Engine

public final class CKSyncEngine: CustomStringConvertible, @unchecked Sendable {
    public enum SyncReason: Hashable, Sendable, CustomStringConvertible {
        case manual
        case scheduled

        public var description: String {
            switch self {
            case .manual: return "manual"
            case .scheduled: return "scheduled"
            }
        }

        var cValue: CKSyncEngineSyncReason {
            switch self {
            case .scheduled: return .scheduled
            case .manual: return .manual
            }
        }
    }

    public struct Configuration: CustomStringConvertible {
        public var database: CKDatabase
        public var stateSerialization: CKSyncEngine.State.Serialization?
        public var delegate: any CKSyncEngineDelegate
        public var automaticallySync: Bool
        public var subscriptionID: CKSubscription.ID?

        public init(
            database: CKDatabase,
            stateSerialization: CKSyncEngine.State.Serialization?,
            delegate: any CKSyncEngineDelegate
        ) {
            self.database = database
            self.stateSerialization = stateSerialization
            self.delegate = delegate
            self.automaticallySync = true
            self.subscriptionID = nil
        }

        public var description: String {
            "CKSyncEngine.Configuration(databaseScope: \(database.databaseScope.rawValue), automaticallySync: \(automaticallySync), subscriptionID: \(subscriptionID ?? "nil"))"
        }
    }

    public struct SendChangesOptions: CustomStringConvertible {
        public enum Scope: Hashable, Sendable, CustomStringConvertible {
            case all
            case allExcluding([CKRecordZone.ID])
            case zoneIDs([CKRecordZone.ID])
            case recordIDs([CKRecord.ID])

            public var description: String {
                switch self {
                case .all: return "all"
                case .allExcluding(let ids): return "allExcluding(\(ids.count))"
                case .zoneIDs(let ids): return "zoneIDs(\(ids.count))"
                case .recordIDs(let ids): return "recordIDs(\(ids.count))"
                }
            }

            public static func == (a: Scope, b: Scope) -> Bool {
                switch (a, b) {
                case (.all, .all):
                    return true
                case (.allExcluding(let lhs), .allExcluding(let rhs)):
                    return ck_zoneIDListsEqual(lhs, rhs)
                case (.zoneIDs(let lhs), .zoneIDs(let rhs)):
                    return ck_zoneIDListsEqual(lhs, rhs)
                case (.recordIDs(let lhs), .recordIDs(let rhs)):
                    return ck_recordIDListsEqual(lhs, rhs)
                default:
                    return false
                }
            }

            public func hash(into hasher: inout Hasher) {
                switch self {
                case .all:
                    hasher.combine(0)
                case .allExcluding(let ids):
                    hasher.combine(1)
                    hasher.combine(ids.count)
                case .zoneIDs(let ids):
                    hasher.combine(2)
                    hasher.combine(ids.count)
                case .recordIDs(let ids):
                    hasher.combine(3)
                    hasher.combine(ids.count)
                }
            }

            public func contains(_ pendingChange: CKSyncEngine.PendingRecordZoneChange) -> Bool {
                contains(pendingChange.recordID)
            }

            public func contains(_ recordID: CKRecord.ID) -> Bool {
                contains(zoneID: recordID.zoneID) && containsRecordIdentity(recordID)
            }

            func contains(zoneID: CKRecordZone.ID) -> Bool {
                switch self {
                case .all:
                    return true
                case .allExcluding(let ids):
                    return !ids.contains(where: { $0.isEqual(zoneID) })
                case .zoneIDs(let ids):
                    return ids.contains(where: { $0.isEqual(zoneID) })
                case .recordIDs(let ids):
                    return ids.contains(where: { $0.zoneID.isEqual(zoneID) })
                }
            }

            private func containsRecordIdentity(_ recordID: CKRecord.ID) -> Bool {
                switch self {
                case .recordIDs(let ids):
                    return ids.contains(where: { $0.isEqual(recordID) })
                case .all, .allExcluding, .zoneIDs:
                    return true
                }
            }
        }

        public var scope: Scope
        public var operationGroup: CKOperationGroup

        public init(scope: Scope = .all, operationGroup: CKOperationGroup? = nil) {
            self.scope = scope
            self.operationGroup = operationGroup ?? CKOperationGroup()
        }

        public var description: String {
            "CKSyncEngine.SendChangesOptions(scope: \(scope))"
        }
    }

    public struct SendChangesContext: CustomStringConvertible {
        public let reason: CKSyncEngine.SyncReason
        public let options: CKSyncEngine.SendChangesOptions

        public init(reason: CKSyncEngine.SyncReason, options: CKSyncEngine.SendChangesOptions) {
            self.reason = reason
            self.options = options
        }

        public var description: String {
            "CKSyncEngine.SendChangesContext(reason: \(reason), options: \(options))"
        }
    }

    public struct FetchChangesOptions: CustomStringConvertible {
        public enum Scope: Hashable, Sendable, CustomStringConvertible {
            case all
            case allExcluding([CKRecordZone.ID])
            case zoneIDs([CKRecordZone.ID])

            public var description: String {
                switch self {
                case .all: return "all"
                case .allExcluding(let ids): return "allExcluding(\(ids.count))"
                case .zoneIDs(let ids): return "zoneIDs(\(ids.count))"
                }
            }

            public static func == (a: Scope, b: Scope) -> Bool {
                switch (a, b) {
                case (.all, .all):
                    return true
                case (.allExcluding(let lhs), .allExcluding(let rhs)):
                    return ck_zoneIDListsEqual(lhs, rhs)
                case (.zoneIDs(let lhs), .zoneIDs(let rhs)):
                    return ck_zoneIDListsEqual(lhs, rhs)
                default:
                    return false
                }
            }

            public func hash(into hasher: inout Hasher) {
                switch self {
                case .all:
                    hasher.combine(0)
                case .allExcluding(let ids):
                    hasher.combine(1)
                    hasher.combine(ids.count)
                case .zoneIDs(let ids):
                    hasher.combine(2)
                    hasher.combine(ids.count)
                }
            }

            public func contains(_ zoneID: CKRecordZone.ID) -> Bool {
                switch self {
                case .all:
                    return true
                case .allExcluding(let ids):
                    return !ids.contains(where: { $0.isEqual(zoneID) })
                case .zoneIDs(let ids):
                    return ids.contains(where: { $0.isEqual(zoneID) })
                }
            }
        }

        public var scope: Scope
        public var operationGroup: CKOperationGroup
        public var prioritizedZoneIDs: [CKRecordZone.ID]

        public init(scope: Scope = .all, operationGroup: CKOperationGroup? = nil) {
            self.scope = scope
            self.operationGroup = operationGroup ?? CKOperationGroup()
            self.prioritizedZoneIDs = []
        }

        public var description: String {
            "CKSyncEngine.FetchChangesOptions(scope: \(scope), prioritized: \(prioritizedZoneIDs.count))"
        }
    }

    public struct FetchChangesContext: CustomStringConvertible {
        public let reason: CKSyncEngine.SyncReason
        public let options: CKSyncEngine.FetchChangesOptions

        public init(reason: CKSyncEngine.SyncReason, options: CKSyncEngine.FetchChangesOptions) {
            self.reason = reason
            self.options = options
        }

        public var description: String {
            "CKSyncEngine.FetchChangesContext(reason: \(reason), options: \(options))"
        }
    }

    public enum PendingDatabaseChange: Hashable, Sendable, CustomStringConvertible {
        case saveZone(CKRecordZone)
        case deleteZone(CKRecordZone.ID)

        public var description: String {
            switch self {
            case .saveZone(let zone):
                return "saveZone(\(zone.zoneID.zoneName))"
            case .deleteZone(let zoneID):
                return "deleteZone(\(zoneID.zoneName))"
            }
        }

        public var type: CKSyncEnginePendingDatabaseChangeType {
            switch self {
            case .saveZone: return .saveZone
            case .deleteZone: return .deleteZone
            }
        }

        public var zoneID: CKRecordZone.ID {
            switch self {
            case .saveZone(let zone): return zone.zoneID
            case .deleteZone(let zoneID): return zoneID
            }
        }

        public static func == (lhs: PendingDatabaseChange, rhs: PendingDatabaseChange) -> Bool {
            switch (lhs, rhs) {
            case (.saveZone(let a), .saveZone(let b)):
                return a.zoneID.isEqual(b.zoneID)
            case (.deleteZone(let a), .deleteZone(let b)):
                return a.isEqual(b)
            default:
                return false
            }
        }

        public func hash(into hasher: inout Hasher) {
            switch self {
            case .saveZone(let zone):
                hasher.combine(0)
                hasher.combine(zone.zoneID.hash)
            case .deleteZone(let zoneID):
                hasher.combine(1)
                hasher.combine(zoneID.hash)
            }
        }
    }

    public enum PendingRecordZoneChange: Hashable, Sendable, CustomStringConvertible {
        case saveRecord(CKRecord.ID)
        case deleteRecord(CKRecord.ID)

        public var description: String {
            switch self {
            case .saveRecord(let id):
                return "saveRecord(\(id.recordName))"
            case .deleteRecord(let id):
                return "deleteRecord(\(id.recordName))"
            }
        }

        public var type: CKSyncEnginePendingRecordZoneChangeType {
            switch self {
            case .saveRecord: return .saveRecord
            case .deleteRecord: return .deleteRecord
            }
        }

        public var recordID: CKRecord.ID {
            switch self {
            case .saveRecord(let id), .deleteRecord(let id):
                return id
            }
        }

        public static func == (a: PendingRecordZoneChange, b: PendingRecordZoneChange) -> Bool {
            switch (a, b) {
            case (.saveRecord(let lhs), .saveRecord(let rhs)),
                 (.deleteRecord(let lhs), .deleteRecord(let rhs)):
                return lhs.isEqual(rhs)
            default:
                return false
            }
        }

        public func hash(into hasher: inout Hasher) {
            switch self {
            case .saveRecord(let id):
                hasher.combine(0)
                hasher.combine(id.hash)
            case .deleteRecord(let id):
                hasher.combine(1)
                hasher.combine(id.hash)
            }
        }
    }

    public struct RecordZoneChangeBatch: CustomStringConvertible {
        public var atomicByZone: Bool
        public var recordsToSave: [CKRecord]
        public var recordIDsToDelete: [CKRecord.ID]

        public init(
            recordsToSave: [CKRecord],
            recordIDsToDelete: [CKRecord.ID],
            atomicByZone: Bool
        ) {
            self.recordsToSave = recordsToSave
            self.recordIDsToDelete = recordIDsToDelete
            self.atomicByZone = atomicByZone
        }

        public init?(
            pendingChanges: [CKSyncEngine.PendingRecordZoneChange],
            recordProvider: (CKRecord.ID) async -> CKRecord?
        ) async {
            guard !pendingChanges.isEmpty else { return nil }
            var saves: [CKRecord] = []
            var deletes: [CKRecord.ID] = []
            for change in pendingChanges {
                switch change {
                case .saveRecord(let recordID):
                    if let record = await recordProvider(recordID) {
                        saves.append(record)
                    }
                case .deleteRecord(let recordID):
                    deletes.append(recordID)
                }
            }
            if saves.isEmpty && deletes.isEmpty { return nil }
            self.recordsToSave = saves
            self.recordIDsToDelete = deletes
            self.atomicByZone = false
        }

        public var description: String {
            "CKSyncEngine.RecordZoneChangeBatch(save: \(recordsToSave.count), delete: \(recordIDsToDelete.count), atomicByZone: \(atomicByZone))"
        }
    }

    public enum Event: CustomStringConvertible {
        public struct StateUpdate: CustomStringConvertible {
            public let stateSerialization: CKSyncEngine.State.Serialization

            public init(stateSerialization: CKSyncEngine.State.Serialization) {
                self.stateSerialization = stateSerialization
            }

            public var description: String { "StateUpdate" }
        }

        public struct AccountChange: CustomStringConvertible {
            public enum ChangeType: Hashable, Sendable {
                case signIn(currentUser: CKRecord.ID)
                case signOut(previousUser: CKRecord.ID)
                case switchAccounts(previousUser: CKRecord.ID, currentUser: CKRecord.ID)

                public static func == (a: ChangeType, b: ChangeType) -> Bool {
                    switch (a, b) {
                    case (.signIn(let lhs), .signIn(let rhs)):
                        return lhs.isEqual(rhs)
                    case (.signOut(let lhs), .signOut(let rhs)):
                        return lhs.isEqual(rhs)
                    case (.switchAccounts(let lp, let lc), .switchAccounts(let rp, let rc)):
                        return lp.isEqual(rp) && lc.isEqual(rc)
                    default:
                        return false
                    }
                }

                public func hash(into hasher: inout Hasher) {
                    switch self {
                    case .signIn(let currentUser):
                        hasher.combine(0)
                        hasher.combine(currentUser.hash)
                    case .signOut(let previousUser):
                        hasher.combine(1)
                        hasher.combine(previousUser.hash)
                    case .switchAccounts(let previousUser, let currentUser):
                        hasher.combine(2)
                        hasher.combine(previousUser.hash)
                        hasher.combine(currentUser.hash)
                    }
                }
            }

            public let changeType: ChangeType

            public init(changeType: ChangeType) {
                self.changeType = changeType
            }

            public var description: String { "AccountChange(\(changeType))" }
        }

        public struct DidSendChanges: CustomStringConvertible {
            public let context: CKSyncEngine.SendChangesContext

            public init(context: CKSyncEngine.SendChangesContext) {
                self.context = context
            }

            public var description: String { "DidSendChanges(\(context.reason))" }
        }

        public struct DidFetchChanges: CustomStringConvertible {
            public let context: CKSyncEngine.FetchChangesContext

            public init(context: CKSyncEngine.FetchChangesContext) {
                self.context = context
            }

            public var description: String { "DidFetchChanges(\(context.reason))" }
        }

        public struct WillSendChanges: CustomStringConvertible {
            public let context: CKSyncEngine.SendChangesContext

            public init(context: CKSyncEngine.SendChangesContext) {
                self.context = context
            }

            public var description: String { "WillSendChanges(\(context.reason))" }
        }

        public struct WillFetchChanges: CustomStringConvertible {
            public let context: CKSyncEngine.FetchChangesContext

            public init(context: CKSyncEngine.FetchChangesContext) {
                self.context = context
            }

            public var description: String { "WillFetchChanges(\(context.reason))" }
        }

        public struct SentDatabaseChanges: CustomStringConvertible {
            public struct FailedZoneSave: CustomStringConvertible {
                public let zone: CKRecordZone
                public let error: CKError

                public init(zone: CKRecordZone, error: CKError) {
                    self.zone = zone
                    self.error = error
                }

                public var description: String {
                    "FailedZoneSave(\(zone.zoneID.zoneName), \(error.code.rawValue))"
                }
            }

            public let savedZones: [CKRecordZone]
            public let deletedZoneIDs: [CKRecordZone.ID]
            public let failedZoneSaves: [FailedZoneSave]
            public let failedZoneDeletes: [CKRecordZone.ID: CKError]

            public init(
                savedZones: [CKRecordZone],
                deletedZoneIDs: [CKRecordZone.ID],
                failedZoneSaves: [FailedZoneSave],
                failedZoneDeletes: [CKRecordZone.ID: CKError]
            ) {
                self.savedZones = savedZones
                self.deletedZoneIDs = deletedZoneIDs
                self.failedZoneSaves = failedZoneSaves
                self.failedZoneDeletes = failedZoneDeletes
            }

            public var description: String {
                "SentDatabaseChanges(saved: \(savedZones.count), deleted: \(deletedZoneIDs.count))"
            }
        }

        public struct SentRecordZoneChanges: CustomStringConvertible {
            public struct FailedRecordSave: CustomStringConvertible {
                public let record: CKRecord
                public let error: CKError

                public init(record: CKRecord, error: CKError) {
                    self.record = record
                    self.error = error
                }

                public var description: String {
                    "FailedRecordSave(\(record.recordID.recordName), \(error.code.rawValue))"
                }
            }

            public let savedRecords: [CKRecord]
            public let deletedRecordIDs: [CKRecord.ID]
            public let failedRecordSaves: [FailedRecordSave]
            public let failedRecordDeletes: [CKRecord.ID: CKError]

            public init(
                savedRecords: [CKRecord],
                deletedRecordIDs: [CKRecord.ID],
                failedRecordSaves: [FailedRecordSave],
                failedRecordDeletes: [CKRecord.ID: CKError]
            ) {
                self.savedRecords = savedRecords
                self.deletedRecordIDs = deletedRecordIDs
                self.failedRecordSaves = failedRecordSaves
                self.failedRecordDeletes = failedRecordDeletes
            }

            public var description: String {
                "SentRecordZoneChanges(saved: \(savedRecords.count), deleted: \(deletedRecordIDs.count))"
            }
        }

        public struct FetchedDatabaseChanges: CustomStringConvertible {
            public let modifications: [CKDatabase.DatabaseChange.Modification]
            public let deletions: [CKDatabase.DatabaseChange.Deletion]

            public init(
                modifications: [CKDatabase.DatabaseChange.Modification],
                deletions: [CKDatabase.DatabaseChange.Deletion]
            ) {
                self.modifications = modifications
                self.deletions = deletions
            }

            public var description: String {
                "FetchedDatabaseChanges(modifications: \(modifications.count), deletions: \(deletions.count))"
            }
        }

        public struct FetchedRecordZoneChanges: CustomStringConvertible {
            public let modifications: [CKDatabase.RecordZoneChange.Modification]
            public let deletions: [CKDatabase.RecordZoneChange.Deletion]

            public init(
                modifications: [CKDatabase.RecordZoneChange.Modification],
                deletions: [CKDatabase.RecordZoneChange.Deletion]
            ) {
                self.modifications = modifications
                self.deletions = deletions
            }

            public var description: String {
                "FetchedRecordZoneChanges(modifications: \(modifications.count), deletions: \(deletions.count))"
            }
        }

        public struct DidFetchRecordZoneChanges: CustomStringConvertible {
            public let zoneID: CKRecordZone.ID
            public let error: CKError?

            public init(zoneID: CKRecordZone.ID, error: CKError?) {
                self.zoneID = zoneID
                self.error = error
            }

            public var description: String {
                "DidFetchRecordZoneChanges(\(zoneID.zoneName))"
            }
        }

        public struct WillFetchRecordZoneChanges: CustomStringConvertible {
            public let zoneID: CKRecordZone.ID

            public init(zoneID: CKRecordZone.ID) {
                self.zoneID = zoneID
            }

            public var description: String {
                "WillFetchRecordZoneChanges(\(zoneID.zoneName))"
            }
        }

        case stateUpdate(StateUpdate)
        case accountChange(AccountChange)
        case fetchedDatabaseChanges(FetchedDatabaseChanges)
        case fetchedRecordZoneChanges(FetchedRecordZoneChanges)
        case sentDatabaseChanges(SentDatabaseChanges)
        case sentRecordZoneChanges(SentRecordZoneChanges)
        case willFetchChanges(WillFetchChanges)
        case willFetchRecordZoneChanges(WillFetchRecordZoneChanges)
        case didFetchRecordZoneChanges(DidFetchRecordZoneChanges)
        case willSendChanges(WillSendChanges)
        case didFetchChanges(DidFetchChanges)
        case didSendChanges(DidSendChanges)

        public var type: CKSyncEngineEventType {
            switch self {
            case .stateUpdate: return .stateUpdate
            case .accountChange: return .accountChange
            case .fetchedDatabaseChanges: return .fetchedDatabaseChanges
            case .fetchedRecordZoneChanges: return .fetchedRecordZoneChanges
            case .sentDatabaseChanges: return .sentDatabaseChanges
            case .sentRecordZoneChanges: return .sentRecordZoneChanges
            case .willFetchChanges: return .willFetchChanges
            case .willFetchRecordZoneChanges: return .willFetchRecordZoneChanges
            case .didFetchRecordZoneChanges: return .didFetchRecordZoneChanges
            case .willSendChanges: return .willSendChanges
            case .didFetchChanges: return .didFetchChanges
            case .didSendChanges: return .didSendChanges
            }
        }

        public var description: String {
            switch self {
            case .stateUpdate(let value): return value.description
            case .accountChange(let value): return value.description
            case .fetchedDatabaseChanges(let value): return value.description
            case .fetchedRecordZoneChanges(let value): return value.description
            case .sentDatabaseChanges(let value): return value.description
            case .sentRecordZoneChanges(let value): return value.description
            case .willFetchChanges(let value): return value.description
            case .willFetchRecordZoneChanges(let value): return value.description
            case .didFetchRecordZoneChanges(let value): return value.description
            case .willSendChanges(let value): return value.description
            case .didFetchChanges(let value): return value.description
            case .didSendChanges(let value): return value.description
            }
        }
    }

    public final class State: @unchecked Sendable {
        public struct Serialization: Codable, Equatable, Sendable {
            var snapshot: Snapshot

            public init() {
                snapshot = Snapshot()
            }

            init(snapshot: Snapshot) {
                self.snapshot = snapshot
            }

            public init(from decoder: Decoder) throws {
                snapshot = try Snapshot(from: decoder)
            }

            public func encode(to encoder: Encoder) throws {
                try snapshot.encode(to: encoder)
            }
        }

        struct Snapshot: Codable, Equatable, Sendable {
            struct RecordChange: Codable, Equatable, Sendable {
                var kind: String
                var recordName: String
                var zoneName: String
                var ownerName: String
            }

            struct ZoneChange: Codable, Equatable, Sendable {
                var kind: String
                var zoneName: String
                var ownerName: String
            }

            struct ZoneToken: Codable, Equatable, Sendable {
                var zoneName: String
                var ownerName: String
                var sequence: UInt64
            }

            var pendingRecords: [RecordChange] = []
            var pendingZones: [ZoneChange] = []
            var hasPendingUntrackedChanges: Bool = false
            var unfetchedZones: [ZoneChange] = []
            var databaseToken: UInt64 = 0
            var zoneTokens: [ZoneToken] = []
        }

        private let lock = NSLock()
        private var recordChanges: [CKSyncEngine.PendingRecordZoneChange] = []
        private var databaseChanges: [CKSyncEngine.PendingDatabaseChange] = []
        public var hasPendingUntrackedChanges: Bool = false
        private var unfetchedZoneIDs: [CKRecordZone.ID] = []
        private var databaseToken: CKServerChangeToken?
        private var zoneTokens: [CKZoneKey: CKServerChangeToken] = [:]

        public var pendingDatabaseChanges: [CKSyncEngine.PendingDatabaseChange] {
            lock.lock()
            defer { lock.unlock() }
            return databaseChanges
        }

        public var pendingRecordZoneChanges: [CKSyncEngine.PendingRecordZoneChange] {
            lock.lock()
            defer { lock.unlock() }
            return recordChanges
        }

        public var zoneIDsWithUnfetchedServerChanges: [CKRecordZone.ID] {
            lock.lock()
            defer { lock.unlock() }
            return unfetchedZoneIDs
        }

        public func add(pendingDatabaseChanges changes: [CKSyncEngine.PendingDatabaseChange]) {
            lock.lock()
            defer { lock.unlock() }
            for change in changes where !databaseChanges.contains(change) {
                databaseChanges.append(change)
            }
        }

        public func add(pendingRecordZoneChanges changes: [CKSyncEngine.PendingRecordZoneChange]) {
            lock.lock()
            defer { lock.unlock() }
            for change in changes where !recordChanges.contains(change) {
                recordChanges.append(change)
            }
        }

        public func remove(pendingDatabaseChanges changes: [CKSyncEngine.PendingDatabaseChange]) {
            lock.lock()
            defer { lock.unlock() }
            databaseChanges.removeAll { existing in
                changes.contains(existing)
            }
        }

        public func remove(pendingRecordZoneChanges changes: [CKSyncEngine.PendingRecordZoneChange]) {
            lock.lock()
            defer { lock.unlock() }
            recordChanges.removeAll { existing in
                changes.contains(existing)
            }
        }

        func apply(_ serialization: Serialization) {
            lock.lock()
            defer { lock.unlock() }
            let snap = serialization.snapshot
            recordChanges = snap.pendingRecords.map { row in
                let id = CKRecord.ID(
                    recordName: row.recordName,
                    zoneID: CKRecordZone.ID(zoneName: row.zoneName, ownerName: row.ownerName)
                )
                return row.kind == "delete" ? .deleteRecord(id) : .saveRecord(id)
            }
            databaseChanges = snap.pendingZones.map { row in
                let zoneID = CKRecordZone.ID(zoneName: row.zoneName, ownerName: row.ownerName)
                if row.kind == "delete" {
                    return .deleteZone(zoneID)
                }
                return .saveZone(CKRecordZone(zoneID: zoneID))
            }
            hasPendingUntrackedChanges = snap.hasPendingUntrackedChanges
            unfetchedZoneIDs = snap.unfetchedZones.map {
                CKRecordZone.ID(zoneName: $0.zoneName, ownerName: $0.ownerName)
            }
            databaseToken = snap.databaseToken == 0 ? nil : CKServerChangeToken.ck_make(sequence: snap.databaseToken)
            zoneTokens = [:]
            for token in snap.zoneTokens {
                let zoneID = CKRecordZone.ID(zoneName: token.zoneName, ownerName: token.ownerName)
                zoneTokens[CKZoneKey(zoneID)] = CKServerChangeToken.ck_make(sequence: token.sequence)
            }
        }

        func makeSerialization() -> Serialization {
            lock.lock()
            defer { lock.unlock() }
            var snap = Snapshot()
            snap.pendingRecords = recordChanges.map { change in
                Snapshot.RecordChange(
                    kind: change.type == .deleteRecord ? "delete" : "save",
                    recordName: change.recordID.recordName,
                    zoneName: change.recordID.zoneID.zoneName,
                    ownerName: change.recordID.zoneID.ownerName
                )
            }
            snap.pendingZones = databaseChanges.map { change in
                Snapshot.ZoneChange(
                    kind: change.type == .deleteZone ? "delete" : "save",
                    zoneName: change.zoneID.zoneName,
                    ownerName: change.zoneID.ownerName
                )
            }
            snap.hasPendingUntrackedChanges = hasPendingUntrackedChanges
            snap.unfetchedZones = unfetchedZoneIDs.map {
                Snapshot.ZoneChange(kind: "unfetched", zoneName: $0.zoneName, ownerName: $0.ownerName)
            }
            snap.databaseToken = databaseToken?.ck_sequence ?? 0
            snap.zoneTokens = zoneTokens.map { key, token in
                Snapshot.ZoneToken(
                    zoneName: key.zoneName,
                    ownerName: key.ownerName,
                    sequence: token.ck_sequence
                )
            }
            return Serialization(snapshot: snap)
        }

        func noteUnfetched(zoneIDs: [CKRecordZone.ID]) {
            lock.lock()
            defer { lock.unlock() }
            for zoneID in zoneIDs where !unfetchedZoneIDs.contains(where: { $0.isEqual(zoneID) }) {
                unfetchedZoneIDs.append(zoneID)
            }
        }

        func clearUnfetched(_ zoneID: CKRecordZone.ID) {
            lock.lock()
            defer { lock.unlock() }
            unfetchedZoneIDs.removeAll { $0.isEqual(zoneID) }
        }

        func databaseChangeToken() -> CKServerChangeToken? {
            lock.lock()
            defer { lock.unlock() }
            return databaseToken
        }

        func setDatabaseChangeToken(_ token: CKServerChangeToken) {
            lock.lock()
            defer { lock.unlock() }
            databaseToken = token
        }

        func zoneChangeToken(for zoneID: CKRecordZone.ID) -> CKServerChangeToken? {
            lock.lock()
            defer { lock.unlock() }
            return zoneTokens[CKZoneKey(zoneID)]
        }

        func setZoneChangeToken(_ token: CKServerChangeToken, for zoneID: CKRecordZone.ID) {
            lock.lock()
            defer { lock.unlock() }
            zoneTokens[CKZoneKey(zoneID)] = token
        }
    }

    public let database: CKDatabase
    public let state: State
    public var description: String {
        "CKSyncEngine(scope: \(database.databaseScope.rawValue), pendingRecords: \(state.pendingRecordZoneChanges.count), pendingZones: \(state.pendingDatabaseChanges.count), automaticallySync: \(automaticallySync))"
    }

    private let delegate: any CKSyncEngineDelegate
    private let automaticallySync: Bool
    private let lock = NSLock()
    private var cancelled = false

    public init(_ configuration: Configuration) {
        self.database = configuration.database
        self.delegate = configuration.delegate
        self.automaticallySync = configuration.automaticallySync
        self.state = State()
        if let serialization = configuration.stateSerialization {
            self.state.apply(serialization)
        }
        // automaticallySync is stored but never schedules an Apple iCloud
        // background sync on Linux. Callers must invoke sendChanges/fetchChanges.
        _ = configuration.subscriptionID
    }

    public func cancelOperations() async {
        lock.lock()
        cancelled = true
        lock.unlock()
    }

    public func sendChanges(
        _ options: CKSyncEngine.SendChangesOptions = .init()
    ) async throws {
        try throwIfCancelled()
        let context = CKSyncEngine.SendChangesContext(reason: .manual, options: options)
        await delegate.handleEvent(.willSendChanges(.init(context: context)), syncEngine: self)

        let pendingZones = state.pendingDatabaseChanges.filter { options.scope.contains(zoneID: $0.zoneID) }
        var savedZones: [CKRecordZone] = []
        var deletedZoneIDs: [CKRecordZone.ID] = []
        var failedSaves: [Event.SentDatabaseChanges.FailedZoneSave] = []
        var failedDeletes: [CKRecordZone.ID: CKError] = [:]
        if !pendingZones.isEmpty {
            let zonesToSave = pendingZones.compactMap { change -> CKRecordZone? in
                if case .saveZone(let zone) = change { return zone }
                return nil
            }
            let zonesToDelete = pendingZones.compactMap { change -> CKRecordZone.ID? in
                if case .deleteZone(let zoneID) = change { return zoneID }
                return nil
            }
            do {
                let outcome = try await database.modifyRecordZones(
                    saving: zonesToSave,
                    deleting: zonesToDelete
                )
                for (zoneID, result) in outcome.saveResults {
                    switch result {
                    case .success(let zone):
                        savedZones.append(zone)
                    case .failure(let error):
                        if let zone = zonesToSave.first(where: { $0.zoneID.isEqual(zoneID) }) {
                            failedSaves.append(.init(zone: zone, error: ck_asCKError(error)))
                        }
                    }
                }
                for (zoneID, result) in outcome.deleteResults {
                    switch result {
                    case .success:
                        deletedZoneIDs.append(zoneID)
                    case .failure(let error):
                        failedDeletes[zoneID] = ck_asCKError(error)
                    }
                }
            } catch {
                let typed = ck_asCKError(error)
                for zone in zonesToSave {
                    failedSaves.append(.init(zone: zone, error: typed))
                }
                for zoneID in zonesToDelete {
                    failedDeletes[zoneID] = typed
                }
            }
            state.remove(pendingDatabaseChanges: pendingZones.filter { change in
                switch change {
                case .saveZone(let zone):
                    return savedZones.contains(where: { $0.zoneID.isEqual(zone.zoneID) })
                case .deleteZone(let zoneID):
                    return deletedZoneIDs.contains(where: { $0.isEqual(zoneID) })
                }
            })
        }
        await delegate.handleEvent(
            .sentDatabaseChanges(
                .init(
                    savedZones: savedZones,
                    deletedZoneIDs: deletedZoneIDs,
                    failedZoneSaves: failedSaves,
                    failedZoneDeletes: failedDeletes
                )
            ),
            syncEngine: self
        )

        var batches = 0
        while batches < 64 {
            try throwIfCancelled()
            guard let batch = await delegate.nextRecordZoneChangeBatch(context, syncEngine: self) else {
                break
            }
            batches += 1
            if batch.recordsToSave.isEmpty && batch.recordIDsToDelete.isEmpty {
                break
            }
            var savedRecords: [CKRecord] = []
            var deletedIDs: [CKRecord.ID] = []
            var failedSaves: [Event.SentRecordZoneChanges.FailedRecordSave] = []
            var failedDeletes: [CKRecord.ID: CKError] = [:]
            do {
                let outcome = try await database.modifyRecords(
                    saving: batch.recordsToSave,
                    deleting: batch.recordIDsToDelete,
                    savePolicy: .ifServerRecordUnchanged,
                    atomically: batch.atomicByZone
                )
                for (recordID, result) in outcome.saveResults {
                    switch result {
                    case .success(let record):
                        savedRecords.append(record)
                    case .failure(let error):
                        if let record = batch.recordsToSave.first(where: { $0.recordID.isEqual(recordID) }) {
                            failedSaves.append(.init(record: record, error: ck_asCKError(error)))
                        }
                    }
                }
                for (recordID, result) in outcome.deleteResults {
                    switch result {
                    case .success:
                        deletedIDs.append(recordID)
                    case .failure(let error):
                        failedDeletes[recordID] = ck_asCKError(error)
                    }
                }
            } catch {
                let typed = ck_asCKError(error)
                for record in batch.recordsToSave {
                    failedSaves.append(.init(record: record, error: typed))
                }
                for recordID in batch.recordIDsToDelete {
                    failedDeletes[recordID] = typed
                }
            }
            var consumed: [PendingRecordZoneChange] = []
            consumed.append(contentsOf: savedRecords.map { .saveRecord($0.recordID) })
            consumed.append(contentsOf: deletedIDs.map { .deleteRecord($0) })
            state.remove(pendingRecordZoneChanges: consumed)
            await delegate.handleEvent(
                .sentRecordZoneChanges(
                    .init(
                        savedRecords: savedRecords,
                        deletedRecordIDs: deletedIDs,
                        failedRecordSaves: failedSaves,
                        failedRecordDeletes: failedDeletes
                    )
                ),
                syncEngine: self
            )
        }

        await delegate.handleEvent(.didSendChanges(.init(context: context)), syncEngine: self)
        await delegate.handleEvent(.stateUpdate(.init(stateSerialization: state.makeSerialization())), syncEngine: self)
    }

    public func fetchChanges(
        _ options: CKSyncEngine.FetchChangesOptions = .init()
    ) async throws {
        try throwIfCancelled()
        let requested = CKSyncEngine.FetchChangesContext(reason: .manual, options: options)
        let resolvedOptions = await delegate.nextFetchChangesOptions(requested, syncEngine: self)
        let context = CKSyncEngine.FetchChangesContext(reason: .manual, options: resolvedOptions)
        await delegate.handleEvent(.willFetchChanges(.init(context: context)), syncEngine: self)

        let dbPage = try await database.databaseChanges(
            since: state.databaseChangeToken(),
            resultsLimit: nil
        )
        let modifications = dbPage.modifications.filter { context.options.scope.contains($0.zoneID) }
        let deletions = dbPage.deletions.filter { context.options.scope.contains($0.zoneID) }
        state.setDatabaseChangeToken(dbPage.changeToken)
        state.noteUnfetched(zoneIDs: modifications.map(\.zoneID))
        for deletion in deletions {
            state.clearUnfetched(deletion.zoneID)
        }
        await delegate.handleEvent(
            .fetchedDatabaseChanges(.init(modifications: modifications, deletions: deletions)),
            syncEngine: self
        )

        var zoneIDs = modifications.map(\.zoneID)
        for pending in state.zoneIDsWithUnfetchedServerChanges where context.options.scope.contains(pending) {
            if !zoneIDs.contains(where: { $0.isEqual(pending) }) {
                zoneIDs.append(pending)
            }
        }
        if zoneIDs.isEmpty {
            // First fetch with an empty change log still visits the default zone
            // so the event sequence is observable without Apple's servers.
            let fallback = CKRecordZone.ID.default
            if context.options.scope.contains(fallback) {
                zoneIDs = [fallback]
            }
        }
        let prioritized = context.options.prioritizedZoneIDs
        zoneIDs.sort { lhs, rhs in
            let li = prioritized.firstIndex(where: { $0.isEqual(lhs) }) ?? Int.max
            let ri = prioritized.firstIndex(where: { $0.isEqual(rhs) }) ?? Int.max
            if li != ri { return li < ri }
            return lhs.zoneName < rhs.zoneName
        }

        for zoneID in zoneIDs {
            try throwIfCancelled()
            await delegate.handleEvent(
                .willFetchRecordZoneChanges(.init(zoneID: zoneID)),
                syncEngine: self
            )
            do {
                let page = try await database.recordZoneChanges(
                    inZoneWith: zoneID,
                    since: state.zoneChangeToken(for: zoneID),
                    desiredKeys: nil,
                    resultsLimit: nil
                )
                var mods: [CKDatabase.RecordZoneChange.Modification] = []
                for (_, result) in page.modificationResultsByID {
                    if case .success(let modification) = result {
                        mods.append(modification)
                    }
                }
                state.setZoneChangeToken(page.changeToken, for: zoneID)
                state.clearUnfetched(zoneID)
                await delegate.handleEvent(
                    .fetchedRecordZoneChanges(.init(modifications: mods, deletions: page.deletions)),
                    syncEngine: self
                )
                await delegate.handleEvent(
                    .didFetchRecordZoneChanges(.init(zoneID: zoneID, error: nil)),
                    syncEngine: self
                )
            } catch {
                let typed = ck_asCKError(error)
                await delegate.handleEvent(
                    .fetchedRecordZoneChanges(.init(modifications: [], deletions: [])),
                    syncEngine: self
                )
                await delegate.handleEvent(
                    .didFetchRecordZoneChanges(.init(zoneID: zoneID, error: typed)),
                    syncEngine: self
                )
            }
        }

        await delegate.handleEvent(.didFetchChanges(.init(context: context)), syncEngine: self)
        await delegate.handleEvent(.stateUpdate(.init(stateSerialization: state.makeSerialization())), syncEngine: self)
    }

    private func throwIfCancelled() throws {
        lock.lock()
        let isCancelled = cancelled
        lock.unlock()
        if isCancelled {
            throw CKError(.operationCancelled)
        }
    }
}

private func ck_asCKError(_ error: any Error) -> CKError {
    if let typed = error as? CKError {
        return typed
    }
    return CKError(
        .internalError,
        userInfo: [NSLocalizedDescriptionKey: String(describing: error)]
    )
}

private func ck_zoneIDListsEqual(_ lhs: [CKRecordZone.ID], _ rhs: [CKRecordZone.ID]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    return zip(lhs, rhs).allSatisfy { $0.isEqual($1) }
}

private func ck_recordIDListsEqual(_ lhs: [CKRecord.ID], _ rhs: [CKRecord.ID]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    return zip(lhs, rhs).allSatisfy { $0.isEqual($1) }
}
