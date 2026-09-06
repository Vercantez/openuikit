import CloudKit
import Foundation

final class CKSyncEngineRecordingDelegate: CKSyncEngineDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var storedEvents: [CKSyncEngine.Event] = []
    var fetchOverride: CKSyncEngine.FetchChangesOptions?

    var events: [CKSyncEngine.Event] {
        lock.lock()
        defer { lock.unlock() }
        return storedEvents
    }

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        _ = syncEngine
        record(event)
    }

    private func record(_ event: CKSyncEngine.Event) {
        lock.lock()
        storedEvents.append(event)
        lock.unlock()
    }

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let pending = syncEngine.state.pendingRecordZoneChanges.filter {
            context.options.scope.contains($0)
        }
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pending) { recordID in
            await withCheckedContinuation { continuation in
                syncEngine.database.fetch(withRecordID: recordID) { record, _ in
                    continuation.resume(returning: record)
                }
            }
        }
    }

    func nextFetchChangesOptions(
        _ context: CKSyncEngine.FetchChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.FetchChangesOptions {
        _ = syncEngine
        return fetchOverride ?? context.options
    }
}

final class CKSyncEngineMinimalDelegate: CKSyncEngineDelegate, @unchecked Sendable {
    var events: [CKSyncEngine.Event] = []

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        _ = syncEngine
        events.append(event)
    }

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        _ = context
        _ = syncEngine
        return nil
    }
}

func ckSyncEngineLastSerialization(
    _ events: [CKSyncEngine.Event]
) -> CKSyncEngine.State.Serialization? {
    for event in events.reversed() {
        if case .stateUpdate(let update) = event {
            return update.stateSerialization
        }
    }
    return nil
}

func testCKSyncEngineCEnumRawValues() {
    let events: [(CKSyncEngineEventType, Int)] = [
        (.stateUpdate, 0), (.accountChange, 1), (.fetchedDatabaseChanges, 2),
        (.fetchedRecordZoneChanges, 3), (.sentDatabaseChanges, 4),
        (.sentRecordZoneChanges, 5), (.willFetchChanges, 6),
        (.willFetchRecordZoneChanges, 7), (.didFetchRecordZoneChanges, 8),
        (.willSendChanges, 9), (.didFetchChanges, 10), (.didSendChanges, 11),
    ]
    precondition(events.count == 12)
    for (value, raw) in events {
        precondition(value.rawValue == raw)
        precondition(CKSyncEngineEventType(rawValue: raw) == value)
        precondition(CKSyncEngineEventType(rawValue: raw) != nil)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CKSyncEngineEventType.stateUpdate != .accountChange)

    let accounts: [(CKSyncEngineAccountChangeType, Int)] = [
        (.signIn, 0), (.signOut, 1), (.switchAccounts, 2),
    ]
    for (value, raw) in accounts {
        precondition(value.rawValue == raw)
        precondition(CKSyncEngineAccountChangeType(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CKSyncEngineAccountChangeType.signIn != .signOut)

    let pendingDB: [(CKSyncEnginePendingDatabaseChangeType, Int)] = [
        (.saveZone, 0), (.deleteZone, 1),
    ]
    for (value, raw) in pendingDB {
        precondition(value.rawValue == raw)
        precondition(CKSyncEnginePendingDatabaseChangeType(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CKSyncEnginePendingDatabaseChangeType.saveZone != .deleteZone)

    let pendingRZ: [(CKSyncEnginePendingRecordZoneChangeType, Int)] = [
        (.saveRecord, 0), (.deleteRecord, 1),
    ]
    for (value, raw) in pendingRZ {
        precondition(value.rawValue == raw)
        precondition(CKSyncEnginePendingRecordZoneChangeType(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CKSyncEnginePendingRecordZoneChangeType.saveRecord != .deleteRecord)

    let reasons: [(CKSyncEngineSyncReason, Int)] = [
        (.scheduled, 0), (.manual, 1),
    ]
    for (value, raw) in reasons {
        precondition(value.rawValue == raw)
        precondition(CKSyncEngineSyncReason(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CKSyncEngineSyncReason.scheduled != .manual)

    let deletions: [(CKSyncEngineZoneDeletionReason, Int)] = [
        (.deleted, 0), (.purged, 1), (.encryptedDataReset, 2),
    ]
    for (value, raw) in deletions {
        precondition(value.rawValue == raw)
        precondition(CKSyncEngineZoneDeletionReason(rawValue: raw) == value)
        _ = value.hashValue
        var hasher = Hasher()
        value.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CKSyncEngineZoneDeletionReason.deleted != .purged)
    precondition(CKSyncEngineZoneDeletionReason.purged != .encryptedDataReset)
}

func testCKSyncEngineSyncReasonAndScopes() {
    precondition(CKSyncEngine.SyncReason.manual == .manual)
    precondition(CKSyncEngine.SyncReason.scheduled == .scheduled)
    precondition(CKSyncEngine.SyncReason.manual != .scheduled)
    _ = CKSyncEngine.SyncReason.manual.hashValue
    var hasher = Hasher()
    CKSyncEngine.SyncReason.scheduled.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(!CKSyncEngine.SyncReason.manual.description.isEmpty)
    precondition(!CKSyncEngine.SyncReason.scheduled.description.isEmpty)

    let zoneA = CKRecordZone.ID(zoneName: "A")
    let zoneB = CKRecordZone.ID(zoneName: "B")
    let recordA = CKRecord.ID(recordName: "r1", zoneID: zoneA)
    let recordB = CKRecord.ID(recordName: "r2", zoneID: zoneB)
    let saveA = CKSyncEngine.PendingRecordZoneChange.saveRecord(recordA)

    let all = CKSyncEngine.SendChangesOptions.Scope.all
    precondition(all.contains(saveA))
    precondition(all.contains(recordA))
    precondition(all == .all)
    precondition(all != .zoneIDs([zoneA]))
    precondition(!all.description.isEmpty)
    _ = all.hashValue

    let excluding = CKSyncEngine.SendChangesOptions.Scope.allExcluding([zoneB])
    precondition(excluding.contains(recordA))
    precondition(!excluding.contains(recordB))
    precondition(excluding == .allExcluding([zoneB]))
    precondition(excluding != .all)
    precondition(!excluding.description.isEmpty)

    let zones = CKSyncEngine.SendChangesOptions.Scope.zoneIDs([zoneA])
    precondition(zones.contains(saveA))
    precondition(!zones.contains(recordB))
    precondition(zones == .zoneIDs([zoneA]))
    precondition(!zones.description.isEmpty)

    let records = CKSyncEngine.SendChangesOptions.Scope.recordIDs([recordA])
    precondition(records.contains(recordA))
    precondition(!records.contains(recordB))
    precondition(records == .recordIDs([recordA]))
    precondition(!records.description.isEmpty)

    var send = CKSyncEngine.SendChangesOptions(scope: zones, operationGroup: CKOperationGroup())
    send.scope = .all
    send.operationGroup.name = "send-group"
    precondition(send.scope == .all)
    precondition(send.operationGroup.name == "send-group")
    precondition(!send.description.isEmpty)

    let fetchAll = CKSyncEngine.FetchChangesOptions.Scope.all
    precondition(fetchAll.contains(zoneA))
    precondition(fetchAll == .all)
    precondition(fetchAll != .zoneIDs([zoneA]))
    precondition(!fetchAll.description.isEmpty)
    _ = fetchAll.hashValue

    let fetchExcluding = CKSyncEngine.FetchChangesOptions.Scope.allExcluding([zoneA])
    precondition(!fetchExcluding.contains(zoneA))
    precondition(fetchExcluding.contains(zoneB))
    precondition(fetchExcluding == .allExcluding([zoneA]))
    precondition(!fetchExcluding.description.isEmpty)

    let fetchZones = CKSyncEngine.FetchChangesOptions.Scope.zoneIDs([zoneB])
    precondition(fetchZones.contains(zoneB))
    precondition(!fetchZones.contains(zoneA))
    precondition(fetchZones == .zoneIDs([zoneB]))
    precondition(!fetchZones.description.isEmpty)

    var fetch = CKSyncEngine.FetchChangesOptions(scope: fetchZones, operationGroup: nil)
    fetch.prioritizedZoneIDs = [zoneB]
    fetch.scope = .all
    fetch.operationGroup.name = "fetch-group"
    precondition(fetch.prioritizedZoneIDs.count == 1)
    precondition(fetch.operationGroup.name == "fetch-group")
    precondition(!fetch.description.isEmpty)

    let sendContext = CKSyncEngine.SendChangesContext(reason: .manual, options: send)
    precondition(sendContext.reason == .manual)
    precondition(sendContext.options.scope == .all)
    precondition(!sendContext.description.isEmpty)

    let fetchContext = CKSyncEngine.FetchChangesContext(reason: .scheduled, options: fetch)
    precondition(fetchContext.reason == .scheduled)
    precondition(fetchContext.options.scope == .all)
    precondition(!fetchContext.description.isEmpty)
}

func testCKSyncEnginePendingChangeValues() {
    let zone = CKRecordZone(zoneName: "Articles")
    let saveZone = CKSyncEngine.PendingDatabaseChange.saveZone(zone)
    let deleteZone = CKSyncEngine.PendingDatabaseChange.deleteZone(zone.zoneID)
    precondition(saveZone == .saveZone(CKRecordZone(zoneID: zone.zoneID)))
    precondition(saveZone != deleteZone)
    precondition(saveZone.type == .saveZone)
    precondition(deleteZone.type == .deleteZone)
    precondition(saveZone.zoneID.isEqual(zone.zoneID))
    precondition(!saveZone.description.isEmpty)
    precondition(!deleteZone.description.isEmpty)
    _ = saveZone.hashValue
    var hasher = Hasher()
    deleteZone.hash(into: &hasher)
    _ = hasher.finalize()

    let recordID = CKRecord.ID(recordName: "rec-1", zoneID: zone.zoneID)
    let saveRecord = CKSyncEngine.PendingRecordZoneChange.saveRecord(recordID)
    let deleteRecord = CKSyncEngine.PendingRecordZoneChange.deleteRecord(recordID)
    precondition(saveRecord == .saveRecord(recordID))
    precondition(saveRecord != deleteRecord)
    precondition(saveRecord.type == .saveRecord)
    precondition(deleteRecord.type == .deleteRecord)
    precondition(saveRecord.recordID.isEqual(recordID))
    precondition(!saveRecord.description.isEmpty)
    precondition(!deleteRecord.description.isEmpty)
    _ = saveRecord.hashValue
    var hasher2 = Hasher()
    deleteRecord.hash(into: &hasher2)
    _ = hasher2.finalize()
}

func testCKSyncEngineConfigurationAndState() {
    let named = isolatedContainer("sync-config")
    let delegate = CKSyncEngineRecordingDelegate()
    var configuration = CKSyncEngine.Configuration(
        database: named.privateCloudDatabase,
        stateSerialization: nil,
        delegate: delegate
    )
    precondition(configuration.automaticallySync == true)
    precondition(configuration.subscriptionID == nil)
    configuration.automaticallySync = false
    configuration.subscriptionID = "sub-articles"
    let empty = CKSyncEngine.State.Serialization()
    configuration.stateSerialization = empty
    precondition(configuration.database === named.privateCloudDatabase)
    precondition(configuration.delegate is CKSyncEngineRecordingDelegate)
    precondition(!configuration.description.isEmpty)

    let engine = CKSyncEngine(configuration)
    precondition(engine.database === named.privateCloudDatabase)
    precondition(!engine.description.isEmpty)
    precondition(engine.state.pendingRecordZoneChanges.isEmpty)
    precondition(engine.state.pendingDatabaseChanges.isEmpty)
    precondition(engine.state.zoneIDsWithUnfetchedServerChanges.isEmpty)
    engine.state.hasPendingUntrackedChanges = true
    precondition(engine.state.hasPendingUntrackedChanges)

    let zone = CKRecordZone(zoneName: "Articles")
    let recordID = CKRecord.ID(recordName: "rec-config", zoneID: zone.zoneID)
    engine.state.add(pendingDatabaseChanges: [.saveZone(zone), .saveZone(zone)])
    engine.state.add(pendingRecordZoneChanges: [.saveRecord(recordID), .saveRecord(recordID)])
    precondition(engine.state.pendingDatabaseChanges.count == 1)
    precondition(engine.state.pendingRecordZoneChanges.count == 1)
    engine.state.remove(pendingDatabaseChanges: [.saveZone(zone)])
    engine.state.remove(pendingRecordZoneChanges: [.saveRecord(recordID)])
    precondition(engine.state.pendingDatabaseChanges.isEmpty)
    precondition(engine.state.pendingRecordZoneChanges.isEmpty)

    // automaticallySync is stored; Linux never schedules Apple iCloud work.
    precondition(delegate.events.isEmpty)
}

func testCKSyncEngineEventPayloads() {
    let zone = CKRecordZone(zoneName: "EventZone")
    let record = CKRecord(recordType: "Article", zoneID: zone.zoneID)
    let user = CKRecord.ID(recordName: "user-1")
    let previous = CKRecord.ID(recordName: "user-0")
    let sendContext = CKSyncEngine.SendChangesContext(
        reason: .manual,
        options: CKSyncEngine.SendChangesOptions()
    )
    let fetchContext = CKSyncEngine.FetchChangesContext(
        reason: .scheduled,
        options: CKSyncEngine.FetchChangesOptions()
    )
    let serialization = CKSyncEngine.State.Serialization()
    let encoded = try! JSONEncoder().encode(serialization)
    let decoded = try! JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: encoded)
    precondition(decoded == serialization)

    let stateUpdate = CKSyncEngine.Event.stateUpdate(.init(stateSerialization: serialization))
    let signIn = CKSyncEngine.Event.AccountChange.ChangeType.signIn(currentUser: user)
    let signOut = CKSyncEngine.Event.AccountChange.ChangeType.signOut(previousUser: previous)
    let switched = CKSyncEngine.Event.AccountChange.ChangeType.switchAccounts(
        previousUser: previous,
        currentUser: user
    )
    precondition(signIn == .signIn(currentUser: user))
    precondition(signIn != signOut)
    precondition(switched == .switchAccounts(previousUser: previous, currentUser: user))
    _ = signIn.hashValue
    var hasher = Hasher()
    signOut.hash(into: &hasher)
    _ = hasher.finalize()
    let account = CKSyncEngine.Event.accountChange(.init(changeType: signIn))
    let fetchedDB = CKSyncEngine.Event.fetchedDatabaseChanges(
        .init(
            modifications: [CKDatabase.DatabaseChange.Modification(zoneID: zone.zoneID)],
            deletions: [
                CKDatabase.DatabaseChange.Deletion(zoneID: zone.zoneID, reason: .deleted),
            ]
        )
    )
    let fetchedRZ = CKSyncEngine.Event.fetchedRecordZoneChanges(
        .init(
            modifications: [CKDatabase.RecordZoneChange.Modification(record: record)],
            deletions: [
                CKDatabase.RecordZoneChange.Deletion(
                    recordID: record.recordID,
                    recordType: "Article"
                ),
            ]
        )
    )
    let sentDB = CKSyncEngine.Event.sentDatabaseChanges(
        .init(
            savedZones: [zone],
            deletedZoneIDs: [zone.zoneID],
            failedZoneSaves: [
                .init(zone: zone, error: CKError(.zoneBusy)),
            ],
            failedZoneDeletes: [zone.zoneID: CKError(.zoneNotFound)]
        )
    )
    let sentRZ = CKSyncEngine.Event.sentRecordZoneChanges(
        .init(
            savedRecords: [record],
            deletedRecordIDs: [record.recordID],
            failedRecordSaves: [
                .init(record: record, error: CKError(.serverRecordChanged)),
            ],
            failedRecordDeletes: [record.recordID: CKError(.unknownItem)]
        )
    )
    let willFetch = CKSyncEngine.Event.willFetchChanges(.init(context: fetchContext))
    let willFetchZone = CKSyncEngine.Event.willFetchRecordZoneChanges(.init(zoneID: zone.zoneID))
    let didFetchZone = CKSyncEngine.Event.didFetchRecordZoneChanges(
        .init(zoneID: zone.zoneID, error: nil)
    )
    let willSend = CKSyncEngine.Event.willSendChanges(.init(context: sendContext))
    let didFetch = CKSyncEngine.Event.didFetchChanges(.init(context: fetchContext))
    let didSend = CKSyncEngine.Event.didSendChanges(.init(context: sendContext))

    let payloads: [CKSyncEngine.Event] = [
        stateUpdate, account, fetchedDB, fetchedRZ, sentDB, sentRZ,
        willFetch, willFetchZone, didFetchZone, willSend, didFetch, didSend,
    ]
    let types: [CKSyncEngineEventType] = [
        .stateUpdate, .accountChange, .fetchedDatabaseChanges, .fetchedRecordZoneChanges,
        .sentDatabaseChanges, .sentRecordZoneChanges, .willFetchChanges,
        .willFetchRecordZoneChanges, .didFetchRecordZoneChanges, .willSendChanges,
        .didFetchChanges, .didSendChanges,
    ]
    for (event, type) in zip(payloads, types) {
        precondition(event.type == type)
        precondition(!event.description.isEmpty)
    }
    if case .sentDatabaseChanges(let payload) = sentDB {
        precondition(payload.savedZones.count == 1)
        precondition(payload.deletedZoneIDs.count == 1)
        precondition(payload.failedZoneSaves.count == 1)
        precondition(payload.failedZoneSaves[0].error.code == .zoneBusy)
        precondition(payload.failedZoneSaves[0].zone.zoneID.isEqual(zone.zoneID))
        precondition(!payload.failedZoneSaves[0].description.isEmpty)
        precondition(payload.failedZoneDeletes[zone.zoneID]?.code == .zoneNotFound)
        precondition(!payload.description.isEmpty)
    } else {
        fatalError("expected sentDatabaseChanges")
    }
    if case .sentRecordZoneChanges(let payload) = sentRZ {
        precondition(payload.savedRecords.count == 1)
        precondition(payload.deletedRecordIDs.count == 1)
        precondition(payload.failedRecordSaves[0].error.code == .serverRecordChanged)
        precondition(payload.failedRecordSaves[0].record.recordID.isEqual(record.recordID))
        precondition(!payload.failedRecordSaves[0].description.isEmpty)
        precondition(payload.failedRecordDeletes[record.recordID]?.code == .unknownItem)
        precondition(!payload.description.isEmpty)
    } else {
        fatalError("expected sentRecordZoneChanges")
    }
    if case .fetchedDatabaseChanges(let payload) = fetchedDB {
        precondition(payload.modifications.count == 1)
        precondition(payload.deletions.count == 1)
        precondition(!payload.description.isEmpty)
    } else {
        fatalError("expected fetchedDatabaseChanges")
    }
    if case .fetchedRecordZoneChanges(let payload) = fetchedRZ {
        precondition(payload.modifications.count == 1)
        precondition(payload.deletions.count == 1)
        precondition(!payload.description.isEmpty)
    } else {
        fatalError("expected fetchedRecordZoneChanges")
    }
    if case .willFetchRecordZoneChanges(let payload) = willFetchZone {
        precondition(payload.zoneID.isEqual(zone.zoneID))
        precondition(!payload.description.isEmpty)
    } else {
        fatalError("expected willFetchRecordZoneChanges")
    }
    if case .didFetchRecordZoneChanges(let payload) = didFetchZone {
        precondition(payload.zoneID.isEqual(zone.zoneID))
        precondition(payload.error == nil)
        precondition(!payload.description.isEmpty)
    } else {
        fatalError("expected didFetchRecordZoneChanges")
    }
    if case .willSendChanges(let payload) = willSend {
        precondition(payload.context.reason == .manual)
        precondition(!payload.description.isEmpty)
    } else {
        fatalError("expected willSendChanges")
    }
    if case .didSendChanges(let payload) = didSend {
        precondition(payload.context.reason == .manual)
        precondition(!payload.description.isEmpty)
    } else {
        fatalError("expected didSendChanges")
    }
    if case .willFetchChanges(let payload) = willFetch {
        precondition(payload.context.reason == .scheduled)
        precondition(!payload.description.isEmpty)
    } else {
        fatalError("expected willFetchChanges")
    }
    if case .didFetchChanges(let payload) = didFetch {
        precondition(payload.context.reason == .scheduled)
        precondition(!payload.description.isEmpty)
    } else {
        fatalError("expected didFetchChanges")
    }
    if case .stateUpdate(let payload) = stateUpdate {
        precondition(!payload.description.isEmpty)
        _ = payload.stateSerialization
    } else {
        fatalError("expected stateUpdate")
    }
    if case .accountChange(let payload) = account {
        precondition(payload.changeType == signIn)
        precondition(!payload.description.isEmpty)
    } else {
        fatalError("expected accountChange")
    }
}

func testCKSyncEngineRecordZoneChangeBatch() async {
    let zone = CKRecordZone(zoneName: "BatchZone")
    let record = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "b1", zoneID: zone.zoneID))
    record["title"] = "Batch"
    var batch = CKSyncEngine.RecordZoneChangeBatch(
        recordsToSave: [record],
        recordIDsToDelete: [record.recordID],
        atomicByZone: true
    )
    precondition(batch.atomicByZone)
    precondition(batch.recordsToSave.count == 1)
    precondition(batch.recordIDsToDelete.count == 1)
    batch.atomicByZone = false
    precondition(!batch.atomicByZone)
    precondition(!batch.description.isEmpty)

    let empty = await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: [], recordProvider: { _ in nil })
    precondition(empty == nil)

    let pending = [
        CKSyncEngine.PendingRecordZoneChange.saveRecord(record.recordID),
        CKSyncEngine.PendingRecordZoneChange.deleteRecord(CKRecord.ID(recordName: "gone", zoneID: zone.zoneID)),
    ]
    let resolved = await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pending) { recordID in
        recordID.isEqual(record.recordID) ? record : nil
    }
    precondition(resolved != nil)
    precondition(resolved?.recordsToSave.count == 1)
    precondition(resolved?.recordIDsToDelete.count == 1)
}

func testCKSyncEngineSendChangesStateMachine() async throws {
    let named = isolatedContainer("sync-send")
    let db = named.privateCloudDatabase
    let delegate = CKSyncEngineRecordingDelegate()
    var configuration = CKSyncEngine.Configuration(
        database: db,
        stateSerialization: nil,
        delegate: delegate
    )
    configuration.automaticallySync = false
    let engine = CKSyncEngine(configuration)
    let zone = CKRecordZone(zoneName: "SendZone")
    _ = try await db.save(zone)
    let record = CKRecord(recordType: "Article", zoneID: zone.zoneID)
    record["title"] = "FromSyncEngine"
    _ = try await db.save(record)

    engine.state.add(pendingDatabaseChanges: [.saveZone(zone)])
    engine.state.add(pendingRecordZoneChanges: [.saveRecord(record.recordID)])
    try await engine.sendChanges(
        CKSyncEngine.SendChangesOptions(scope: .all, operationGroup: CKOperationGroup())
    )

    let types = delegate.events.map(\.type)
    precondition(types.contains(.willSendChanges))
    precondition(types.contains(.sentDatabaseChanges))
    precondition(types.contains(.sentRecordZoneChanges))
    precondition(types.contains(.didSendChanges))
    precondition(types.contains(.stateUpdate))
    precondition(!types.contains(.accountChange), "must not fabricate an Apple account change")
    precondition(engine.state.pendingRecordZoneChanges.isEmpty)
    precondition(engine.state.pendingDatabaseChanges.isEmpty)

    let fetched = await awaitValue { done in
        db.fetch(withRecordID: record.recordID) { record, error in
            done((record, error))
        }
    }
    precondition(fetched.1 == nil)
    precondition((fetched.0?["title"] as? String) == "FromSyncEngine")

    var sawSentRecords = false
    for event in delegate.events {
        if case .sentRecordZoneChanges(let payload) = event {
            sawSentRecords = true
            precondition(payload.savedRecords.contains(where: { $0.recordID.isEqual(record.recordID) }))
            precondition(!payload.description.isEmpty)
        }
        if case .willSendChanges(let payload) = event {
            precondition(payload.context.reason == .manual)
        }
        if case .didSendChanges(let payload) = event {
            precondition(payload.context.options.scope == .all)
        }
    }
    precondition(sawSentRecords)
}

func testCKSyncEngineFetchChangesStateMachine() async throws {
    let named = isolatedContainer("sync-fetch")
    let db = named.privateCloudDatabase
    let delegate = CKSyncEngineRecordingDelegate()
    let engine = CKSyncEngine(
        CKSyncEngine.Configuration(
            database: db,
            stateSerialization: nil,
            delegate: delegate
        )
    )
    let zone = CKRecordZone(zoneName: "FetchZone")
    _ = try await db.save(zone)
    let record = CKRecord(recordType: "Article", zoneID: zone.zoneID)
    record["title"] = "FetchedLocally"
    _ = try await db.save(record)

    var options = CKSyncEngine.FetchChangesOptions(scope: .all, operationGroup: CKOperationGroup())
    options.prioritizedZoneIDs = [zone.zoneID]
    try await engine.fetchChanges(options)

    let types = delegate.events.map(\.type)
    precondition(types.contains(.willFetchChanges))
    precondition(types.contains(.fetchedDatabaseChanges))
    precondition(types.contains(.willFetchRecordZoneChanges))
    precondition(types.contains(.fetchedRecordZoneChanges))
    precondition(types.contains(.didFetchRecordZoneChanges))
    precondition(types.contains(.didFetchChanges))
    precondition(types.contains(.stateUpdate))
    precondition(!types.contains(.accountChange), "must not fabricate an Apple account change")

    var sawRecord = false
    for event in delegate.events {
        if case .fetchedRecordZoneChanges(let payload) = event {
            if payload.modifications.contains(where: { $0.record.recordID.isEqual(record.recordID) }) {
                sawRecord = true
            }
            precondition(!payload.description.isEmpty)
        }
        if case .willFetchChanges(let payload) = event {
            precondition(payload.context.reason == .manual)
            precondition(!payload.context.options.prioritizedZoneIDs.isEmpty)
        }
        if case .didFetchChanges(let payload) = event {
            precondition(payload.context.options.scope == .all)
        }
        if case .fetchedDatabaseChanges(let payload) = event {
            precondition(!payload.description.isEmpty)
        }
    }
    precondition(sawRecord)

    let serialization = ckSyncEngineLastSerialization(delegate.events)
    precondition(serialization != nil)
    let restoredDelegate = CKSyncEngineRecordingDelegate()
    let restored = CKSyncEngine(
        CKSyncEngine.Configuration(
            database: db,
            stateSerialization: serialization,
            delegate: restoredDelegate
        )
    )
    try await restored.fetchChanges()
    // Second fetch against the same local token reports no additional Apple-server
    // mutations; the event sequence still runs.
    precondition(restoredDelegate.events.map(\.type).contains(.didFetchChanges))
}

func testCKSyncEngineDelegateDefaultFetchOptions() async throws {
    let named = isolatedContainer("sync-delegate")
    let delegate = CKSyncEngineMinimalDelegate()
    let engine = CKSyncEngine(
        CKSyncEngine.Configuration(
            database: named.privateCloudDatabase,
            stateSerialization: nil,
            delegate: delegate
        )
    )
    try await engine.fetchChanges(CKSyncEngine.FetchChangesOptions(scope: .all))
    var sawDidFetch = false
    for event in delegate.events {
        if case .didFetchChanges(let payload) = event {
            sawDidFetch = true
            precondition(payload.context.options.scope == .all)
            precondition(payload.context.reason == .manual)
        }
    }
    precondition(sawDidFetch)
    precondition(!delegate.events.map(\.type).contains(.accountChange))
}

func testCKSyncEngineCancelOperations() async throws {
    let named = isolatedContainer("sync-cancel")
    let delegate = CKSyncEngineRecordingDelegate()
    let engine = CKSyncEngine(
        CKSyncEngine.Configuration(
            database: named.privateCloudDatabase,
            stateSerialization: nil,
            delegate: delegate
        )
    )
    await engine.cancelOperations()
    do {
        try await engine.sendChanges()
        fatalError("cancelled sendChanges must throw")
    } catch {
        requireCKError(error, code: .operationCancelled)
    }
    do {
        try await engine.fetchChanges()
        fatalError("cancelled fetchChanges must throw")
    } catch {
        requireCKError(error, code: .operationCancelled)
    }
}

func testCKSyncEngineSendDeleteAndScopeFilter() async throws {
    let named = isolatedContainer("sync-delete")
    let db = named.privateCloudDatabase
    let delegate = CKSyncEngineRecordingDelegate()
    let engine = CKSyncEngine(
        CKSyncEngine.Configuration(
            database: db,
            stateSerialization: nil,
            delegate: delegate
        )
    )
    let zone = CKRecordZone(zoneName: "DeleteZone")
    _ = try await db.save(zone)
    let keep = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "keep", zoneID: zone.zoneID))
    keep["title"] = "Keep"
    let gone = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "gone", zoneID: zone.zoneID))
    gone["title"] = "Gone"
    _ = try await db.save(keep)
    _ = try await db.save(gone)

    engine.state.add(pendingRecordZoneChanges: [
        .deleteRecord(gone.recordID),
        .saveRecord(keep.recordID),
    ])
    try await engine.sendChanges(
        CKSyncEngine.SendChangesOptions(scope: .recordIDs([gone.recordID]))
    )
    let missing = await awaitValue { done in
        db.fetch(withRecordID: gone.recordID) { record, error in
            done((record, error))
        }
    }
    requireCKError(missing.1, code: .unknownItem)
    let still = await awaitValue { done in
        db.fetch(withRecordID: keep.recordID) { record, error in
            done((record, error))
        }
    }
    precondition(still.1 == nil)
    precondition((still.0?["title"] as? String) == "Keep")
}
