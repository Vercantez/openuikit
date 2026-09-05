import CloudKit
import Foundation

func testCKModifyRecordsCallbackOrderAndPartialFailure() async throws {
    let named = isolatedContainer("modify-op")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)
    let zoneID = zone.zoneID

    let fresh = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "fresh", zoneID: zoneID))
    fresh["title"] = "Updated"
    let changedSave = CKModifyRecordsOperation(recordsToSave: [fresh], recordIDsToDelete: [])
    changedSave.savePolicy = .changedKeys
    changedSave.isAtomic = true
    precondition(CKModifyRecordsOperation.RecordSavePolicy.ifServerRecordUnchanged.rawValue == 0)
    precondition(CKModifyRecordsOperation.RecordSavePolicy.changedKeys.rawValue == 1)
    precondition(CKModifyRecordsOperation.RecordSavePolicy.allKeys.rawValue == 2)
    let changedOutcome = await awaitValue {
        done in
        changedSave.modifyRecordsCompletionBlock = { saved, deleted, error in
            done((saved, deleted, error))
        }
        db.add(changedSave)
    }
    precondition(changedOutcome.2 == nil)
    precondition((changedOutcome.0?.first?["title"] as? String) == "Updated")

    let good = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "good", zoneID: zoneID))
    good["title"] = "good"
    let bad = CKRecord(
        recordType: "Article",
        recordID: CKRecord.ID(recordName: "bad", zoneID: CKRecordZone.ID(zoneName: "NoSuchZone"))
    )
    bad["title"] = "bad"
    var perRecordOrder: [String] = []
    let atomic = CKModifyRecordsOperation(recordsToSave: [good, bad], recordIDsToDelete: [])
    atomic.isAtomic = true
    atomic.savePolicy = .allKeys
    atomic.perRecordProgressBlock = { _, _ in perRecordOrder.append("progress") }
    atomic.perRecordSaveBlock = { recordID, _ in perRecordOrder.append("save:" + recordID.recordName) }
    atomic.perRecordCompletionBlock = { record, _ in perRecordOrder.append("done:" + record.recordID.recordName) }
    atomic.perRecordDeleteBlock = { _, _ in perRecordOrder.append("delete") }
    let atomicResult = await awaitValue {
        done in
        atomic.modifyRecordsCompletionBlock = { saved, deleted, error in
            done((saved, deleted, error))
        }
        atomic.modifyRecordsResultBlock = { _ in perRecordOrder.append("result") }
        db.add(atomic)
    }
    requireCKError(atomicResult.2, code: .partialFailure)
    precondition((atomicResult.2 as! CKError).partialErrorsByItemID != nil)
    precondition(perRecordOrder.first == "progress")
    precondition(perRecordOrder.contains("result"))
    let stillMissing = await awaitValue { done in
        db.fetch(withRecordID: good.recordID) { record, error in
            done((record, error))
        }
    }
    requireCKError(stillMissing.1, code: .unknownItem)

    let addLock = NSRecursiveLock()
    var insideDatabaseAdd = true
    let inlineProbe = CKModifyRecordsOperation(recordsToSave: [], recordIDsToDelete: [])
    let firedInline = await awaitValue { done in
        inlineProbe.modifyRecordsCompletionBlock = { _, _, _ in
            addLock.lock()
            let inline = insideDatabaseAdd
            addLock.unlock()
            done(inline)
        }
        addLock.lock()
        db.add(inlineProbe)
        insideDatabaseAdd = false
        addLock.unlock()
    }
    precondition(firedInline == false, "CKDatabase.add must not invoke completions inline")
    _ = CKModifyRecordsOperation()
}

func testCKQueryAndFetchRecordsOperationCallbacks() async throws {
    let named = isolatedContainer("query-op")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)
    let record = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "q1", zoneID: zone.zoneID))
    record["title"] = "Hello"
    _ = try await db.save(record)

    let trueQuery = CKQuery(recordType: "Article", predicate: NSPredicate(value: true))
    let queryOp = CKQueryOperation(query: trueQuery)
    queryOp.zoneID = zone.zoneID
    queryOp.desiredKeys = ["title"]
    queryOp.resultsLimit = 50
    var fetchedByBlock = 0
    queryOp.recordFetchedBlock = { _ in fetchedByBlock += 1 }
    queryOp.recordMatchedBlock = { _, _ in }
    let queryCursor = await awaitValue { done in
        queryOp.queryCompletionBlock = { cursor, error in
            done((cursor, error))
        }
        queryOp.queryResultBlock = { _ in }
        db.add(queryOp)
    }
    precondition(queryCursor.1 == nil)
    precondition(fetchedByBlock >= 1)
    _ = CKQueryOperation()
    _ = CKQueryOperation.Cursor()
    precondition(CKQueryOperation.Cursor.supportsSecureCoding)

    let fetchOp = CKFetchRecordsOperation(recordIDs: [record.recordID])
    fetchOp.desiredKeys = ["title"]
    fetchOp.perRecordProgressBlock = { _, _ in }
    fetchOp.perRecordResultBlock = { _, _ in }
    let fetchMap = await awaitValue { done in
        fetchOp.fetchRecordsCompletionBlock = { map, error in
            done((map, error))
        }
        fetchOp.fetchRecordsResultBlock = { _ in }
        fetchOp.perRecordCompletionBlock = { _, _, _ in }
        db.add(fetchOp)
    }
    precondition(fetchMap.1 == nil)
    precondition(fetchMap.0?[record.recordID] != nil)
    _ = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()
    _ = CKFetchRecordsOperation()
}

func testCKRecordZoneCRUDOperationCallbacks() async throws {
    let named = isolatedContainer("zone-crud")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)

    let fetchZones = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
    let zoneMap = await awaitValue { done in
        fetchZones.fetchRecordZonesCompletionBlock = { map, error in
            done((map, error))
        }
        fetchZones.fetchRecordZonesResultBlock = { _ in }
        fetchZones.perRecordZoneResultBlock = { _, _ in }
        db.add(fetchZones)
    }
    precondition(zoneMap.0?[zone.zoneID] != nil)
    _ = CKFetchRecordZonesOperation(recordZoneIDs: [zone.zoneID])

    let customZone = CKRecordZone(zoneName: "Scratch")
    let modifyZones = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [])
    let zoneModify = await awaitValue {
        done in
        modifyZones.modifyRecordZonesCompletionBlock = { saved, deleted, error in
            done((saved, deleted, error))
        }
        modifyZones.perRecordZoneSaveBlock = { _, _ in }
        modifyZones.perRecordZoneDeleteBlock = { _, _ in }
        modifyZones.modifyRecordZonesResultBlock = { _ in }
        db.add(modifyZones)
    }
    precondition(zoneModify.2 == nil)
    _ = CKModifyRecordZonesOperation()
}

func testCKFetchRecordZoneChangesOperationCallbacks() async throws {
    let named = isolatedContainer("zone-changes")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)
    let record = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "z1", zoneID: zone.zoneID))
    record["title"] = "Hello"
    _ = try await db.save(record)

    let zoneChangesOp = CKFetchRecordZoneChangesOperation(
        recordZoneIDs: [zone.zoneID],
        configurationsByRecordZoneID: [
            zone.zoneID: CKFetchRecordZoneChangesOperation.ZoneConfiguration(
                previousServerChangeToken: nil,
                resultsLimit: 50,
                desiredKeys: ["title"]
            )
        ]
    )
    zoneChangesOp.recordChangedBlock = { _ in }
    zoneChangesOp.recordWasChangedBlock = { _, _ in }
    zoneChangesOp.recordWithIDWasDeletedBlock = { _, _ in }
    zoneChangesOp.recordZoneChangeTokensUpdatedBlock = { _, _, _ in }
    zoneChangesOp.recordZoneFetchResultBlock = { _, _ in }
    zoneChangesOp.fetchRecordZoneChangesResultBlock = { _ in }
    let zoneChangeDone = await awaitValue {
        done in
        zoneChangesOp.recordZoneFetchCompletionBlock = { _, token, _, _, error in
            done((token, error))
        }
        zoneChangesOp.fetchRecordZoneChangesCompletionBlock = { _ in }
        db.add(zoneChangesOp)
    }
    precondition(zoneChangeDone.1 == nil)
    precondition(zoneChangeDone.0 != nil)

    let zoneOptions = CKFetchRecordZoneChangesOperation.ZoneOptions()
    zoneOptions.desiredKeys = ["title"]
    zoneOptions.resultsLimit = 10
    _ = CKFetchRecordZoneChangesOperation(
        recordZoneIDs: [zone.zoneID],
        optionsByRecordZoneID: [zone.zoneID: zoneOptions]
    )
    _ = CKFetchRecordZoneChangesOperation()
}

func testCKDatabaseChangeOperationCallbacks() async throws {
    let named = isolatedContainer("db-changes")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)

    let dbChangeFetch = CKFetchDatabaseChangesOperation(previousServerChangeToken: nil)
    dbChangeFetch.fetchAllChanges = true
    dbChangeFetch.resultsLimit = 10
    dbChangeFetch.recordZoneWithIDChangedBlock = { _ in }
    dbChangeFetch.recordZoneWithIDWasDeletedBlock = { _ in }
    dbChangeFetch.recordZoneWithIDWasPurgedBlock = { _ in }
    dbChangeFetch.recordZoneWithIDWasDeletedDueToUserEncryptedDataResetBlock = { _ in }
    dbChangeFetch.changeTokenUpdatedBlock = { _ in }
    dbChangeFetch.fetchDatabaseChangesResultBlock = { _ in }
    let dbChangeToken = await awaitValue { done in
        dbChangeFetch.fetchDatabaseChangesCompletionBlock = { token, _, error in
            done((token, error))
        }
        db.add(dbChangeFetch)
    }
    precondition(dbChangeToken.1 == nil)

    let legacyChanges = CKFetchRecordChangesOperation(recordZoneID: zone.zoneID, previousServerChangeToken: nil)
    legacyChanges.desiredKeys = ["title"]
    legacyChanges.recordChangedBlock = { _ in }
    legacyChanges.recordWithIDWasDeletedBlock = { _ in }
    _ = await awaitValue { done in
        legacyChanges.fetchRecordChangesCompletionBlock = { _, _, error in
            done(error)
        }
        db.add(legacyChanges)
    }
    _ = CKFetchRecordChangesOperation()
    _ = CKDatabaseOperation()
}

func testCKOperationConfigurationAndGroup() {
    let named = isolatedContainer("config")
    let config = CKOperation.Configuration()
    config.allowsCellularAccess = false
    config.isLongLived = true
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 60
    config.qualityOfService = .userInitiated
    config.container = named
    let configCopy = config.copy() as! CKOperation.Configuration
    precondition(configCopy.allowsCellularAccess == false)
    precondition(configCopy.isLongLived)
    precondition(configCopy.timeoutIntervalForRequest == 30)
    precondition(configCopy.timeoutIntervalForResource == 60)

    let group = CKOperationGroup()
    precondition(!group.operationGroupID.isEmpty)
    precondition(group.expectedSendSize == .unknown)
    group.expectedSendSize = .kilobytes
    group.expectedReceiveSize = .megabytes
    group.name = "batch"
    group.quantity = 4
    group.defaultConfiguration = config
    precondition(group.expectedSendSize == .kilobytes)
    precondition(group.expectedReceiveSize == .megabytes)
    precondition(group.name == "batch")
    precondition(group.quantity == 4)
    precondition(CKOperationGroup.supportsSecureCoding)
    precondition(CKOperationGroup.TransferSize.unknown.rawValue == 0)
    precondition(CKOperationGroup.TransferSize.kilobytes.rawValue == 1)
    precondition(CKOperationGroup.TransferSize.megabytes.rawValue == 2)
    precondition(CKOperationGroup.TransferSize.tensOfMegabytes.rawValue == 3)
    precondition(CKOperationGroup.TransferSize.hundredsOfMegabytes.rawValue == 4)
    precondition(CKOperationGroup.TransferSize.gigabytes.rawValue == 5)
    precondition(CKOperationGroup.TransferSize.tensOfGigabytes.rawValue == 6)
    precondition(CKOperationGroup.TransferSize.hundredsOfGigabytes.rawValue == 7)

    let operation = CKModifyRecordsOperation()
    operation.allowsCellularAccess = false
    operation.isLongLived = true
    operation.configuration = config
    operation.group = group
    operation.timeoutIntervalForRequest = 15
    operation.timeoutIntervalForResource = 30
    operation.longLivedOperationWasPersistedBlock = {}
    precondition(!operation.operationID.isEmpty)
    _ = CKOperation()
}
