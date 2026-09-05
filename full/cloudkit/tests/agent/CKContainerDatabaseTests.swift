import CloudKit
import Foundation

func testCKContainerDatabasesAndAccountStatus() async {
    let container = CKContainer.default()
    precondition(container === CKContainer.default())
    precondition(container.containerIdentifier == nil)
    let named = isolatedContainer("news")
    precondition(named.containerIdentifier == "iCloud.openuikit.news")
    precondition(named.privateCloudDatabase.databaseScope == .private)
    precondition(named.publicCloudDatabase.databaseScope == .public)
    precondition(named.sharedCloudDatabase.databaseScope == .shared)
    precondition(named.database(with: .private) === named.privateCloudDatabase)
    precondition(named.database(with: .public) === named.publicCloudDatabase)
    precondition(named.database(with: .shared) === named.sharedCloudDatabase)
    precondition(CKDatabase.Scope.public.rawValue == 1)
    precondition(CKDatabase.Scope.private.rawValue == 2)
    precondition(CKDatabase.Scope.shared.rawValue == 3)
    precondition(CKDatabase.Scope(rawValue: 2) == .private)
    _ = named.configuredWith(configuration: CKOperation.Configuration(), group: CKOperationGroup()) { $0 }
    _ = named.privateCloudDatabase.configuredWith(configuration: nil, group: nil) { $0 }
}

func testCKContainerAccountStatusAndPermissions() async {
    let named = isolatedContainer("account")
    let status = await awaitValue { done in
        named.accountStatus { accountStatus, error in
            done((accountStatus, error))
        }
    }
    precondition(status.0 == .noAccount)
    precondition(status.1 == nil)
    precondition(CKAccountStatus.couldNotDetermine.rawValue == 0)
    precondition(CKAccountStatus.available.rawValue == 1)
    precondition(CKAccountStatus.restricted.rawValue == 2)
    precondition(CKAccountStatus.noAccount.rawValue == 3)
    precondition(CKAccountStatus.temporarilyUnavailable.rawValue == 4)
    precondition(CKAccountStatus(rawValue: 3) == .noAccount)

    precondition(CKContainer.ApplicationPermissionStatus.initialState.rawValue == 0)
    precondition(CKContainer.ApplicationPermissionStatus.couldNotComplete.rawValue == 1)
    precondition(CKContainer.ApplicationPermissionStatus.denied.rawValue == 2)
    precondition(CKContainer.ApplicationPermissionStatus.granted.rawValue == 3)
    precondition(CKContainer.ApplicationPermissionStatus(rawValue: 2) == .denied)
    precondition(CKContainer.ApplicationPermissions.userDiscoverability.rawValue == 1)
    _ = CKContainer.ApplicationPermissions(rawValue: 1)
    _ = CKContainer.Application.Permissions.userDiscoverability
    _ = CKContainer.Application.PermissionStatus.granted
    _ = CKContainer_Application_Permissions.userDiscoverability
    _ = CKContainer_Application_PermissionStatus.denied
    _ = CKContainer.ApplicationPermissionBlock.self
    _ = CKContainer.Application.PermissionBlock.self
    _ = CKContainer_Application_PermissionBlock.self
}

func testCKDatabaseSaveFetchDeleteQuery() async throws {
    let named = isolatedContainer("store")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    let zoneID = zone.zoneID
    let savedZone = try await db.save(zone)
    precondition(savedZone.zoneID.zoneName == "Articles")
    precondition(savedZone.capabilities.contains(.fetchChanges))
    precondition(savedZone.capabilities.contains(.atomic))

    let fetchedZone = await awaitValue { done in
        db.fetch(withRecordZoneID: zoneID) { zone, error in
            done((zone, error))
        }
    }
    precondition(fetchedZone.1 == nil)
    precondition(fetchedZone.0?.zoneID.isEqual(zoneID) == true)

    let allZones = try await db.allRecordZones()
    precondition(allZones.contains { $0.zoneID.isEqual(zoneID) })
    precondition(allZones.contains { $0.zoneID.isEqual(CKRecordZone.ID.default) })

    let zonesByID = try await db.recordZones(for: [zoneID, CKRecordZone.ID.default])
    precondition((try? zonesByID[zoneID]?.get()) != nil)

    let recordID = CKRecord.ID(recordName: "rec-1", zoneID: zoneID)
    let record = CKRecord(recordType: "Article", recordID: recordID)
    record["title"] = "Hello"
    record["blob"] = Data([0x0A])
    let saved = try await db.save(record)
    precondition(saved.recordChangeTag != nil)
    precondition(saved.creationDate != nil)
    precondition(saved.modificationDate != nil)
    precondition((saved["title"] as? String) == "Hello")

    let fetched = await awaitValue { done in
        db.fetch(withRecordID: recordID) { record, error in
            done((record, error))
        }
    }
    precondition(fetched.1 == nil)
    precondition((fetched.0?["title"] as? String) == "Hello")

    let byIDs = try await db.records(for: [recordID], desiredKeys: ["title"])
    let desired = try byIDs[recordID]!.get()
    precondition((desired["title"] as? String) == "Hello")
    precondition(desired["blob"] == nil)

    let query = CKQuery(recordType: "Article", predicate: NSPredicate { object, _ in
        (object as? CKRecord)?["title"] as? String == "Hello"
    })
    let performed = try await db.perform(query, inZoneWith: zoneID)
    precondition(performed.count == 1)
    precondition(performed[0].recordID.isEqual(recordID))
    let matching = try await db.records(matching: query, inZoneWith: zoneID)
    precondition(matching.count == 1)

    let extra = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "rec-2", zoneID: zoneID))
    extra["title"] = "World"
    _ = try await db.save(extra)
    let trueQuery = CKQuery(recordType: "Article", predicate: NSPredicate(value: true))
    let limited = try await db.records(
        matching: trueQuery,
        inZoneWith: zoneID,
        desiredKeys: nil,
        resultsLimit: 1
    )
    precondition(limited.matchResults.count == 1)
    precondition(limited.queryCursor != nil)
    let continued = try await db.records(
        continuingMatchFrom: limited.queryCursor!,
        desiredKeys: nil,
        resultsLimit: 10
    )
    precondition(continued.matchResults.count == 1)

    let deletedID = await awaitValue { done in
        db.delete(withRecordID: extra.recordID) { recordID, error in
            done((recordID, error))
        }
    }
    precondition(deletedID.1 == nil)
    precondition(deletedID.0?.isEqual(extra.recordID) == true)

    let missingID = CKRecord.ID(recordName: "missing", zoneID: zoneID)
    let missing = await awaitValue { done in
        db.fetch(withRecordID: missingID) { record, error in
            done((record, error))
        }
    }
    precondition(missing.0 == nil)
    requireCKError(missing.1, code: .unknownItem)

    let unknownZone = CKRecordZone.ID(zoneName: "NoSuchZone")
    let stray = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "x", zoneID: unknownZone))
    do {
        _ = try await db.save(stray)
        fatalError("missing zone must fail")
    } catch {
        requireCKError(error, code: .zoneNotFound)
    }

    let defaultDelete = await awaitValue { done in
        db.delete(withRecordZoneID: .default) { zoneID, error in
            done((zoneID, error))
        }
    }
    requireCKError(defaultDelete.1, code: .invalidArguments)
}

func testCKDatabaseConflictOfflineAndBatch() async throws {
    let named = isolatedContainer("conflict")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)
    let recordID = CKRecord.ID(recordName: "rec-1", zoneID: zone.zoneID)
    let record = CKRecord(recordType: "Article", recordID: recordID)
    record["title"] = "Hello"
    _ = try await db.save(record)

    let winnerMap = try await db.records(for: [recordID])
    let winner = try winnerMap[recordID]!.get()
    winner["title"] = "server-wins"
    _ = try await db.save(winner)
    let staleClient = CKRecord(recordType: "Article", recordID: recordID)
    staleClient["title"] = "stale"
    do {
        _ = try await db.save(staleClient)
        fatalError("unchanged-tag conflict must fail")
    } catch {
        requireCKError(error, code: .serverRecordChanged)
        let ckError = error as! CKError
        precondition(ckError.clientRecord != nil)
        precondition(ckError.serverRecord != nil)
        precondition(ckError.ancestorRecord != nil)
    }

    named.setSimulatedOffline(true)
    do {
        _ = try await db.save(CKRecord(recordType: "Article", zoneID: zone.zoneID))
        fatalError("offline save must fail")
    } catch {
        requireCKError(error, code: .networkUnavailable)
    }
    named.setSimulatedOffline(false)

    let modify = try await db.modifyRecords(
        saving: [CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "batch", zoneID: zone.zoneID))],
        deleting: [],
        savePolicy: .allKeys,
        atomically: true
    )
    precondition((try? modify.saveResults.values.first?.get()) != nil)

    let custom = CKRecordZone(zoneName: "Scratch")
    let zoneModify = try await db.modifyRecordZones(saving: [custom], deleting: [])
    precondition((try? zoneModify.saveResults[custom.zoneID]?.get()) != nil)
    let deletedZone = await awaitValue { done in
        db.delete(withRecordZoneID: custom.zoneID) { zoneID, error in
            done((zoneID, error))
        }
    }
    precondition(deletedZone.1 == nil)
}
