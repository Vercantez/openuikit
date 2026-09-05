import CloudKit
import Foundation

func requireCKError(_ error: Error?, code: CKError.Code) {
    guard let error = error as? CKError else {
        fatalError("expected typed CKError")
    }
    precondition(error.code == code)
    precondition(error.errorCode == code.rawValue)
    precondition(CKError.errorDomain == CKErrorDomain)
}

func awaitPair<A, B>(_ body: (@escaping (A?, B?) -> Void) -> Void) async -> (A?, B?) {
    await withCheckedContinuation { continuation in
        body { a, b in continuation.resume(returning: (a, b)) }
    }
}

// MARK: - Constants, errors, enums

precondition(CKErrorDomain == "CKErrorDomain")
precondition(CKErrorRetryAfterKey == "CKRetryAfterSeconds")
precondition(CKErrorUserDidResetEncryptedDataKey == "CKErrorUserDidResetEncryptedData")
precondition(CKPartialErrorsByItemIDKey == "CKPartialErrors")
precondition(CKRecordChangedErrorAncestorRecordKey == "CKAncestorRecord")
precondition(CKRecordChangedErrorClientRecordKey == "CKClientRecord")
precondition(CKRecordChangedErrorServerRecordKey == "CKServerRecord")
precondition(CKCurrentUserDefaultName == "__defaultOwner__")
precondition(CKOwnerDefaultName == "__defaultOwner__")
precondition(CKRecordZoneDefaultName == "_defaultZone")
precondition(CKRecordNameZoneWideShare == "cloudkit.zoneshare")
precondition(CKRecordTypeUserRecord == "Users")
precondition(CKRecordTypeShare == "cloudkit.share")
precondition(CKRecordParentKey == "___parent")
precondition(CKRecordShareKey == "___share")
precondition(NSNotification.Name.CKAccountChanged.rawValue == "CKAccountChangedNotification")

let error = CKError(.notAuthenticated)
precondition(error.code == .notAuthenticated)
precondition(CKError.notAuthenticated == CKError.Code.notAuthenticated)
precondition(error.retryAfterSeconds == nil)
precondition(error.clientRecord == nil)
let retry = CKError(.zoneBusy, userInfo: [CKErrorRetryAfterKey: 1.5])
precondition(retry.retryAfterSeconds == 1.5)

let everyCode: [CKError.Code] = [
    .internalError, .partialFailure, .networkUnavailable, .networkFailure,
    .badContainer, .serviceUnavailable, .requestRateLimited, .missingEntitlement,
    .notAuthenticated, .permissionFailure, .unknownItem, .invalidArguments,
    .resultsTruncated, .serverRecordChanged, .serverRejectedRequest, .assetFileNotFound,
    .assetFileModified, .incompatibleVersion, .constraintViolation, .operationCancelled,
    .changeTokenExpired, .batchRequestFailed, .zoneBusy, .badDatabase, .quotaExceeded,
    .zoneNotFound, .limitExceeded, .userDeletedZone, .tooManyParticipants, .alreadyShared,
    .referenceViolation, .managedAccountRestricted, .participantMayNeedVerification,
    .serverResponseLost, .assetNotAvailable, .accountTemporarilyUnavailable,
    .participantAlreadyInvited,
]
precondition(everyCode.count == 37)
precondition(CKError.unknownItem == .unknownItem)
precondition(CKError.zoneNotFound == .zoneNotFound)
precondition(CKError.networkUnavailable == .networkUnavailable)
precondition(CKError.partialFailure == .partialFailure)
precondition(CKError.serverRecordChanged == .serverRecordChanged)
precondition(CKError.batchRequestFailed == .batchRequestFailed)
precondition(CKError.assetFileNotFound == .assetFileNotFound)
precondition(CKError.changeTokenExpired == .changeTokenExpired)
precondition(CKError.operationCancelled == .operationCancelled)

precondition(CKAccountStatus.couldNotDetermine.rawValue == 0)
precondition(CKAccountStatus.available.rawValue == 1)
precondition(CKAccountStatus.restricted.rawValue == 2)
precondition(CKAccountStatus.noAccount.rawValue == 3)
precondition(CKAccountStatus.temporarilyUnavailable.rawValue == 4)

precondition(CKContainer.ApplicationPermissionStatus.initialState.rawValue == 0)
precondition(CKContainer.ApplicationPermissionStatus.couldNotComplete.rawValue == 1)
precondition(CKContainer.ApplicationPermissionStatus.denied.rawValue == 2)
precondition(CKContainer.ApplicationPermissionStatus.granted.rawValue == 3)
precondition(CKContainer.ApplicationPermissions.userDiscoverability.rawValue == 1)
_ = CKContainer.ApplicationPermissionStatus(rawValue: 2)
_ = CKContainer.ApplicationPermissions(rawValue: 1)

precondition(CKNotification.NotificationType.query.rawValue == 1)
precondition(CKNotification.NotificationType.recordZone.rawValue == 2)
precondition(CKNotification.NotificationType.readNotification.rawValue == 3)
precondition(CKNotification.NotificationType.database.rawValue == 4)
precondition(CKQueryNotification.Reason.recordCreated.rawValue == 1)
precondition(CKQueryNotification.Reason.recordUpdated.rawValue == 2)
precondition(CKQueryNotification.Reason.recordDeleted.rawValue == 3)

precondition(CKModifyRecordsOperation.RecordSavePolicy.ifServerRecordUnchanged.rawValue == 0)
precondition(CKModifyRecordsOperation.RecordSavePolicy.changedKeys.rawValue == 1)
precondition(CKModifyRecordsOperation.RecordSavePolicy.allKeys.rawValue == 2)

precondition(CKShare.ParticipantAcceptanceStatus.unknown.rawValue == 0)
precondition(CKShare.ParticipantAcceptanceStatus.pending.rawValue == 1)
precondition(CKShare.ParticipantAcceptanceStatus.accepted.rawValue == 2)
precondition(CKShare.ParticipantAcceptanceStatus.removed.rawValue == 3)
precondition(CKShare.ParticipantPermission.unknown.rawValue == 0)
precondition(CKShare.ParticipantPermission.none.rawValue == 1)
precondition(CKShare.ParticipantPermission.readOnly.rawValue == 2)
precondition(CKShare.ParticipantPermission.readWrite.rawValue == 3)
precondition(CKShare.ParticipantRole.unknown.rawValue == 0)
precondition(CKShare.ParticipantRole.owner.rawValue == 1)
precondition(CKShare.ParticipantRole.administrator.rawValue == 2)
precondition(CKShare.ParticipantRole.privateUser.rawValue == 3)
precondition(CKShare.ParticipantRole.publicUser.rawValue == 4)

precondition(CKSharingParticipantAccessOption.anyoneWithLink.rawValue == 1)
precondition(CKSharingParticipantAccessOption.specifiedRecipientsOnly.rawValue == 2)
precondition(CKSharingParticipantAccessOption.any.contains(.anyoneWithLink))
precondition(CKSharingParticipantPermissionOption.readOnly.rawValue == 1)
precondition(CKSharingParticipantPermissionOption.readWrite.rawValue == 2)
precondition(CKSharingParticipantPermissionOption.any.contains(.readWrite))

precondition(CKSubscription.SubscriptionType.query.rawValue == 1)
precondition(CKSubscription.SubscriptionType.recordZone.rawValue == 2)
precondition(CKSubscription.SubscriptionType.database.rawValue == 3)
precondition(CKQuerySubscription.Options.firesOnRecordDeletion.rawValue == 4)
precondition(CKQuerySubscription.Options.firesOnce.rawValue == 8)

precondition(CKRecordZone.Capabilities.zoneWideSharing.rawValue == 8)
precondition(CKRecordZone.EncryptionScope.perZone.rawValue == 1)
precondition(CKRecord.SystemType.userRecord == CKRecordTypeUserRecord)
precondition(CKRecord.SystemType.share == CKRecordTypeShare)
precondition(CKRecord.SystemFieldKey.recordID == "recordID")
precondition(CKRecord.SystemFieldKey.creatorUserRecordID == "creatorUserRecordID")
precondition(CKRecord.SystemFieldKey.lastModifiedUserRecordID == "lastModifiedUserRecordID")
precondition(CKRecord.SystemFieldKey.creationDate == "creationDate")
precondition(CKRecord.SystemFieldKey.modificationDate == "modificationDate")
precondition(CKRecord.SystemFieldKey.parent == CKRecordParentKey)
precondition(CKRecord.SystemFieldKey.share == CKRecordShareKey)
precondition(CKShare.SystemFieldKey.title == CKShareTitleKey)
precondition(CKShare.SystemFieldKey.shareType == CKShareTypeKey)
precondition(CKShare.SystemFieldKey.thumbnailImageData == CKShareThumbnailImageDataKey)

let sizes: [CKOperationGroup.TransferSize] = [
    .unknown, .kilobytes, .megabytes, .tensOfMegabytes, .hundredsOfMegabytes,
    .gigabytes, .tensOfGigabytes, .hundredsOfGigabytes,
]
precondition(sizes.count == 8)
precondition(CKQueryOperation.maximumResults == 0)

// MARK: - Value types

let zoneID = CKRecordZone.ID(zoneName: "Articles", ownerName: CKCurrentUserDefaultName)
precondition(zoneID.zoneName == "Articles")
precondition(zoneID.ownerName == CKCurrentUserDefaultName)
precondition(CKRecordZone.ID.default.isEqual(CKRecordZone.default().zoneID))
precondition(CKRecordZone.ID.defaultZoneName == CKRecordZoneDefaultName)

let zone = CKRecordZone(zoneName: "Articles")
precondition(zone.zoneID.zoneName == "Articles")
precondition(zone.encryptionScope == .perRecord)
zone.encryptionScope = .perZone
precondition(zone.encryptionScope == .perZone)
let zoneCopy = zone.copy() as! CKRecordZone
precondition(zoneCopy.zoneID.isEqual(zone.zoneID))

var capabilities: CKRecordZone.Capabilities = [.atomic, .fetchChanges]
precondition(capabilities.contains(.atomic))
precondition(capabilities.contains(.fetchChanges))
capabilities.insert(.sharing)
precondition(capabilities.contains(.sharing))
capabilities.insert(.zoneWideSharing)
precondition(capabilities.contains(.zoneWideSharing))

let recordID = CKRecord.ID(recordName: "rec-1", zoneID: zoneID)
precondition(recordID.recordName == "rec-1")
precondition(recordID.zoneID.isEqual(zoneID))
precondition(recordID.isEqual(CKRecord.ID(recordName: "rec-1", zoneID: zoneID)))
precondition((recordID.copy() as! CKRecord.ID).isEqual(recordID))

let record = CKRecord(recordType: "Article", recordID: recordID)
precondition(record.recordType == "Article")
precondition(record.recordID.isEqual(recordID))
let zoned = CKRecord(recordType: "Article", zoneID: zoneID)
precondition(zoned.recordID.zoneID.isEqual(zoneID))

record["title"] = "Hello"
record["count"] = 3
let blob = Data([0x0A, 0x0B])
let stamp = Date(timeIntervalSince1970: 1_700_000_000)
record["blob"] = blob
record["stamp"] = stamp
record["flag"] = true
record["tags"] = ["a", "b"]
precondition((record["title"] as? String) == "Hello")
precondition(record.object(forKey: "count") as? Int == 3)
precondition((record["blob"] as? Data) == blob)
precondition((record["stamp"] as? Date) == stamp)
precondition(Set(record.allKeys()).isSuperset(of: ["title", "count", "blob", "stamp"]))
precondition(Set(record.changedKeys()).isSuperset(of: ["title", "count"]))
record.setObject(nil, forKey: "count")
precondition(record["count"] == nil)
_ = record.encryptedValues
_ = record.allTokens()
_ = record.recordChangeTag
_ = record.creationDate
_ = record.creatorUserRecordID
_ = record.share

let parent = CKRecord(recordType: "Folder", zoneID: zoneID)
record.setParent(parent)
precondition(record.parent?.recordID.isEqual(parent.recordID) == true)
record.setParent(nil as CKRecord.ID?)
precondition(record.parent == nil)
record.setParent(parent.recordID)
precondition(record.parent?.recordID.isEqual(parent.recordID) == true)

let reference = CKRecord.Reference(record: record, action: .deleteSelf)
precondition(reference.action == .deleteSelf)
precondition(reference.referenceAction == .deleteSelf)
precondition(reference.recordID.isEqual(record.recordID))
let noneRef = CKRecord.Reference(recordID: recordID, action: .none)
precondition(noneRef.action == .none)
precondition((noneRef.copy() as! CKRecord.Reference).isEqual(noneRef))
record["ref"] = reference

let assetPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("cloudkit-asset.bin")
try! Data([0x01, 0x02, 0x03]).write(to: assetPath)
let asset = CKAsset(fileURL: assetPath)
precondition(asset.fileURL == assetPath)
record["file"] = asset

var iterator = record.makeIterator()
var iterated = Set<String>()
while let (key, _) = iterator.next() {
    iterated.insert(key)
}
precondition(iterated.contains("title"))
precondition(iterated.contains("file"))

let keyed = try NSKeyedArchiver.archivedData(withRootObject: recordID, requiringSecureCoding: true)
let restoredID = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.ID.self, from: keyed)
precondition(restoredID?.isEqual(recordID) == true)

let archiver = NSKeyedArchiver(requiringSecureCoding: true)
record.encodeSystemFields(with: archiver)
archiver.finishEncoding()
let unarchiver = try NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
unarchiver.requiresSecureCoding = true
let restoredSystem = CKRecord(coder: unarchiver)
precondition(restoredSystem?.recordType == "Article")
precondition(restoredSystem?.recordID.isEqual(recordID) == true)

let fullArchive = try NSKeyedArchiver.archivedData(withRootObject: record, requiringSecureCoding: true)
let restoredRecord = try NSKeyedUnarchiver.unarchivedObject(
    ofClasses: [
        CKRecord.self, CKRecord.ID.self, CKRecordZone.ID.self, CKRecord.Reference.self,
        CKAsset.self, NSString.self, NSNumber.self, NSDate.self, NSData.self, NSArray.self,
    ],
    from: fullArchive
) as? CKRecord
precondition(restoredRecord?.recordType == "Article")
precondition((restoredRecord?["title"] as? String) == "Hello")

let queryPredicate = NSPredicate(format: "title == %@", "Hello")
let query = CKQuery(recordType: "Article", predicate: queryPredicate)
precondition(query.recordType == "Article")
precondition(query.predicate == queryPredicate)
query.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
precondition(query.sortDescriptors?.count == 1)
_ = query.copy() as! CKQuery

// MARK: - Container / account / databases

let container = CKContainer.default()
precondition(container === CKContainer.default())
precondition(container.containerIdentifier == nil)
let named = CKContainer(identifier: "iCloud.com.example.news")
precondition(named.containerIdentifier == "iCloud.com.example.news")
precondition(named.privateCloudDatabase.databaseScope == .private)
precondition(named.publicCloudDatabase.databaseScope == .public)
precondition(named.sharedCloudDatabase.databaseScope == .shared)
precondition(named.database(with: .private) === named.privateCloudDatabase)
precondition(named.database(with: .public) === named.publicCloudDatabase)
precondition(named.database(with: .shared) === named.sharedCloudDatabase)

let db = named.privateCloudDatabase
_ = named.configuredWith(configuration: CKOperation.Configuration(), group: CKOperationGroup()) { $0 }
_ = db.configuredWith(configuration: nil, group: nil) { $0 }

let status = await withCheckedContinuation { continuation in
    named.accountStatus { accountStatus, accountError in
        continuation.resume(returning: (accountStatus, accountError))
    }
}
precondition(status.0 == .noAccount)
precondition(status.1 == nil)

do {
    _ = try await named.requestApplicationPermission(.userDiscoverability)
    fatalError("permission must fail closed")
} catch {
    requireCKError(error, code: .notAuthenticated)
}
do {
    _ = try await named.applicationPermissionStatus(for: .userDiscoverability)
    fatalError("permission status must fail closed")
} catch {
    requireCKError(error, code: .notAuthenticated)
}

let userRecordID = await withCheckedContinuation { continuation in
    named.fetchUserRecordID { recordID, error in
        continuation.resume(returning: (recordID, error))
    }
}
precondition(userRecordID.0 == nil)
requireCKError(userRecordID.1, code: .notAuthenticated)

// MARK: - Simulated store: zones, records, query, modify

let savedZone = try await db.save(zone)
precondition(savedZone.zoneID.zoneName == "Articles")
precondition(savedZone.capabilities.contains(.fetchChanges))
precondition(savedZone.capabilities.contains(.atomic))

let fetchedZone: CKRecordZone? = await withCheckedContinuation { continuation in
    db.fetch(withRecordZoneID: zoneID) { zone, error in
        continuation.resume(returning: zone)
        _ = error
    }
}
precondition(fetchedZone?.zoneID.isEqual(zoneID) == true)

let allZones = try await db.allRecordZones()
precondition(allZones.contains { $0.zoneID.isEqual(zoneID) })
precondition(allZones.contains { $0.zoneID.isEqual(CKRecordZone.ID.default) })

let saved = try await db.save(record)
precondition(saved.recordChangeTag != nil)
precondition(saved.creationDate != nil)
precondition(saved.modificationDate != nil)
precondition((saved["title"] as? String) == "Hello")
precondition((saved["file"] as? CKAsset)?.fileURL != assetPath)

let fetched = await withCheckedContinuation { continuation in
    db.fetch(withRecordID: recordID) { record, error in
        continuation.resume(returning: (record, error))
    }
}
precondition(fetched.1 == nil)
precondition((fetched.0?["title"] as? String) == "Hello")

let byIDs = try await db.records(for: [recordID], desiredKeys: ["title"])
let desired = try byIDs[recordID]!.get()
precondition((desired["title"] as? String) == "Hello")
precondition(desired["blob"] == nil)

let performed = try await db.perform(query, inZoneWith: zoneID)
precondition(performed.count == 1)
precondition(performed[0].recordID.isEqual(recordID))

let trueQuery = CKQuery(recordType: "Article", predicate: NSPredicate(value: true))
let page = try await db.records(matching: trueQuery, inZoneWith: zoneID, desiredKeys: nil, resultsLimit: 1)
precondition(page.matchResults.count == 1)

let extra = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "rec-2", zoneID: zoneID))
extra["title"] = "World"
_ = try await db.save(extra)
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

let missingID = CKRecord.ID(recordName: "missing", zoneID: zoneID)
let missing = await withCheckedContinuation { continuation in
    db.fetch(withRecordID: missingID) { record, error in
        continuation.resume(returning: (record, error))
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

// Conflict / serverRecordChanged
let winnerMap = try await db.records(for: [recordID])
let winner = try winnerMap[recordID]!.get()
winner["title"] = "server-wins"
_ = try await db.save(winner)
let stale = fetched.0!
stale["title"] = "stale"
do {
    _ = try await db.save(stale)
    fatalError("unchanged-tag conflict must fail")
} catch {
    requireCKError(error, code: .serverRecordChanged)
    let ckError = error as! CKError
    precondition(ckError.clientRecord != nil)
    precondition(ckError.serverRecord != nil)
    precondition(ckError.ancestorRecord != nil)
}

let freshMap = try await db.records(for: [recordID])
let fresh = try freshMap[recordID]!.get()
fresh["title"] = "Updated"
let changedSave = CKModifyRecordsOperation(recordsToSave: [fresh], recordIDsToDelete: [])
changedSave.savePolicy = .changedKeys
changedSave.isAtomic = true
let changedOutcome = await withCheckedContinuation { continuation in
    changedSave.modifyRecordsCompletionBlock = { saved, deleted, error in
        continuation.resume(returning: (saved, deleted, error))
    }
    db.add(changedSave)
}
precondition(changedOutcome.2 == nil)
precondition((changedOutcome.0?.first?["title"] as? String) == "Updated")

// Atomic partial failure
let good = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "good", zoneID: zoneID))
good["title"] = "good"
let bad = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "bad", zoneID: unknownZone))
bad["title"] = "bad"
var perRecordOrder: [String] = []
let atomic = CKModifyRecordsOperation(recordsToSave: [good, bad], recordIDsToDelete: [])
atomic.isAtomic = true
atomic.savePolicy = .allKeys
atomic.perRecordProgressBlock = { _, _ in perRecordOrder.append("progress") }
atomic.perRecordSaveBlock = { recordID, _ in perRecordOrder.append("save:" + recordID.recordName) }
atomic.perRecordCompletionBlock = { record, _ in perRecordOrder.append("done:" + record.recordID.recordName) }
let atomicResult = await withCheckedContinuation { continuation in
    atomic.modifyRecordsCompletionBlock = { saved, deleted, error in
        continuation.resume(returning: (saved, deleted, error))
    }
    atomic.modifyRecordsResultBlock = { _ in perRecordOrder.append("result") }
    db.add(atomic)
}
requireCKError(atomicResult.2, code: .partialFailure)
let partial = (atomicResult.2 as! CKError).partialErrorsByItemID
precondition(partial != nil)
precondition(perRecordOrder.first == "progress")
precondition(perRecordOrder.contains("result"))
let stillMissing = await withCheckedContinuation { continuation in
    db.fetch(withRecordID: good.recordID) { record, error in
        continuation.resume(returning: (record, error))
    }
}
requireCKError(stillMissing.1, code: .unknownItem)

let addLock = NSRecursiveLock()
var insideDatabaseAdd = true
let inlineProbe = CKModifyRecordsOperation(recordsToSave: [], recordIDsToDelete: [])
let inlineResult = await withCheckedContinuation { continuation in
    inlineProbe.modifyRecordsCompletionBlock = { saved, deleted, error in
        addLock.lock()
        let firedInline = insideDatabaseAdd
        addLock.unlock()
        continuation.resume(returning: firedInline)
        _ = (saved, deleted, error)
    }
    addLock.lock()
    db.add(inlineProbe)
    insideDatabaseAdd = false
    addLock.unlock()
}
precondition(inlineResult == false, "CKDatabase.add must not invoke completions inline")

// Query operation blocks
let queryOp = CKQueryOperation(query: trueQuery)
queryOp.zoneID = zoneID
queryOp.desiredKeys = ["title"]
queryOp.resultsLimit = 50
var fetchedByBlock = 0
queryOp.recordFetchedBlock = { _ in fetchedByBlock += 1 }
queryOp.recordMatchedBlock = { _, _ in }
let queryCursor = await withCheckedContinuation { continuation in
    queryOp.queryCompletionBlock = { cursor, error in
        continuation.resume(returning: (cursor, error))
    }
    queryOp.queryResultBlock = { _ in }
    db.add(queryOp)
}
precondition(queryCursor.1 == nil)
precondition(fetchedByBlock >= 1)

let fetchOp = CKFetchRecordsOperation(recordIDs: [recordID])
fetchOp.desiredKeys = ["title"]
fetchOp.perRecordProgressBlock = { _, _ in }
fetchOp.perRecordResultBlock = { _, _ in }
let fetchMap = await withCheckedContinuation { continuation in
    fetchOp.fetchRecordsCompletionBlock = { map, error in
        continuation.resume(returning: (map, error))
    }
    fetchOp.fetchRecordsResultBlock = { _ in }
    fetchOp.perRecordCompletionBlock = { _, _, _ in }
    db.add(fetchOp)
}
precondition(fetchMap.1 == nil)
precondition(fetchMap.0?[recordID] != nil)
_ = CKFetchRecordsOperation.fetchCurrentUserRecordOperation()

let fetchZones = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
let zoneMap = await withCheckedContinuation { continuation in
    fetchZones.fetchRecordZonesCompletionBlock = { map, error in
        continuation.resume(returning: (map, error))
    }
    fetchZones.fetchRecordZonesResultBlock = { _ in }
    fetchZones.perRecordZoneResultBlock = { _, _ in }
    db.add(fetchZones)
}
precondition(zoneMap.0?[zoneID] != nil)

let customZone = CKRecordZone(zoneName: "Scratch")
let modifyZones = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [])
let zoneModify = await withCheckedContinuation { continuation in
    modifyZones.modifyRecordZonesCompletionBlock = { saved, deleted, error in
        continuation.resume(returning: (saved, deleted, error))
    }
    modifyZones.perRecordZoneSaveBlock = { _, _ in }
    modifyZones.modifyRecordZonesResultBlock = { _ in }
    db.add(modifyZones)
}
precondition(zoneModify.2 == nil)

let zoneChangesOp = CKFetchRecordZoneChangesOperation(
    recordZoneIDs: [zoneID],
    configurationsByRecordZoneID: [
        zoneID: CKFetchRecordZoneChangesOperation.ZoneConfiguration(previousServerChangeToken: nil, resultsLimit: 50, desiredKeys: ["title"])
    ]
)
zoneChangesOp.recordChangedBlock = { _ in }
zoneChangesOp.recordWasChangedBlock = { _, _ in }
zoneChangesOp.recordWithIDWasDeletedBlock = { _, _ in }
zoneChangesOp.recordZoneChangeTokensUpdatedBlock = { _, _, _ in }
let zoneChangeDone = await withCheckedContinuation { continuation in
    zoneChangesOp.recordZoneFetchCompletionBlock = { _, token, _, _, error in
        continuation.resume(returning: (token, error))
    }
    zoneChangesOp.fetchRecordZoneChangesCompletionBlock = { _ in }
    db.add(zoneChangesOp)
}
precondition(zoneChangeDone.1 == nil)
precondition(zoneChangeDone.0 != nil)

let tokenCopy = zoneChangeDone.0?.copy() as? CKServerChangeToken
precondition(tokenCopy?.isEqual(zoneChangeDone.0) == true)
let tokenData = try NSKeyedArchiver.archivedData(withRootObject: zoneChangeDone.0!, requiringSecureCoding: true)
let restoredToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
precondition(restoredToken?.isEqual(zoneChangeDone.0) == true)

let dbChanges = try await db.databaseChanges(since: nil, resultsLimit: nil)
precondition(!dbChanges.modifications.isEmpty)
_ = dbChanges.deletions
_ = dbChanges.changeToken
_ = dbChanges.moreComing
let hashedMod = dbChanges.modifications[0]
precondition(hashedMod == hashedMod)
_ = hashedMod.hashValue

let rzChanges = try await db.recordZoneChanges(inZoneWith: zoneID, since: nil, desiredKeys: nil, resultsLimit: nil)
precondition(!rzChanges.modificationResultsByID.isEmpty)

let deletedID = await withCheckedContinuation { continuation in
    db.delete(withRecordID: extra.recordID) { recordID, error in
        continuation.resume(returning: (recordID, error))
    }
}
precondition(deletedID.1 == nil)
precondition(deletedID.0?.isEqual(extra.recordID) == true)

// MARK: - Subscriptions

let info = CKSubscription.NotificationInfo(
    alertBody: "changed",
    alertLocalizationKey: "loc",
    alertLocalizationArgs: ["title"],
    title: "T",
    titleLocalizationKey: "tk",
    titleLocalizationArgs: ["title"],
    subtitle: "S",
    subtitleLocalizationKey: "sk",
    subtitleLocalizationArgs: ["title"],
    alertActionLocalizationKey: "act",
    alertLaunchImage: "img",
    soundName: "default",
    desiredKeys: ["title"],
    shouldBadge: true,
    shouldSendContentAvailable: true,
    shouldSendMutableContent: false,
    category: "cat",
    collapseIDKey: "collapse"
)
precondition(info.alertBody == "changed")
precondition(info.shouldBadge)
precondition(info.shouldSendContentAvailable)
precondition(info.title == "T")
precondition(info.subtitle == "S")
precondition(info.soundName == "default")
precondition(info.category == "cat")
precondition(info.collapseIDKey == "collapse")
_ = info.copy() as! CKSubscription.NotificationInfo

let subscription = CKQuerySubscription(
    recordType: "Article",
    predicate: NSPredicate(value: true),
    subscriptionID: "sub-articles",
    options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion, .firesOnce]
)
subscription.zoneID = zoneID
subscription.notificationInfo = info
precondition(subscription.subscriptionType == .query)
precondition(subscription.querySubscriptionOptions.contains(.firesOnRecordCreation))
precondition(subscription.querySubscriptionOptions.contains(.firesOnRecordDeletion))
precondition(subscription.querySubscriptionOptions.contains(.firesOnce))

let savedSub = try await db.save(subscription)
precondition(savedSub.subscriptionID == "sub-articles")
let fetchedSub = try await db.subscription(for: "sub-articles")
precondition(fetchedSub.subscriptionID == "sub-articles")
let allSubs = try await db.allSubscriptions()
precondition(allSubs.contains { $0.subscriptionID == "sub-articles" })

let zoneSub = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: "sub-zone")
zoneSub.recordType = "Article"
precondition(zoneSub.subscriptionType == .recordZone)
_ = try await db.save(zoneSub)

let dbSub = CKDatabaseSubscription(subscriptionID: "sub-db")
dbSub.recordType = "Article"
precondition(dbSub.subscriptionType == .database)
precondition(CKDatabaseSubscription().subscriptionType == .database)
_ = try await db.save(dbSub)

let modifySubs = CKModifySubscriptionsOperation(
    subscriptionsToSave: [CKQuerySubscription(recordType: "Article", predicate: NSPredicate(value: true), options: [.firesOnRecordCreation])],
    subscriptionIDsToDelete: []
)
modifySubs.perSubscriptionSaveBlock = { _, _ in }
let subModify = await withCheckedContinuation { continuation in
    modifySubs.modifySubscriptionsCompletionBlock = { saved, deleted, error in
        continuation.resume(returning: error)
    }
    modifySubs.modifySubscriptionsResultBlock = { _ in }
    db.add(modifySubs)
}
precondition(subModify == nil)

let fetchSubs = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
let subMap = await withCheckedContinuation { continuation in
    fetchSubs.fetchSubscriptionCompletionBlock = { map, error in
        continuation.resume(returning: (map, error))
    }
    db.add(fetchSubs)
}
precondition(subMap.1 == nil)

_ = try await db.deleteSubscription(withID: "sub-db")

// MARK: - Notifications

let parsedNil = CKNotification(fromRemoteNotificationDictionary: ["ck-missing": "value"])
precondition(parsedNil == nil)
let parsed = CKNotification(fromRemoteNotificationDictionary: [
    "ck": [
        "t": 1,
        "cid": "iCloud.com.example.news",
        "sid": "sub-articles",
        "nid": "n-1",
        "fet": 0,
    ] as [String: Any],
    "aps": [
        "alert": "Hello",
        "badge": 2,
        "sound": "default",
        "category": "cat",
    ] as [String: Any],
])
precondition(parsed != nil)
precondition(parsed?.notificationType == .query)
precondition(parsed?.containerIdentifier == "iCloud.com.example.news")
precondition(parsed?.subscriptionID == "sub-articles")
precondition(parsed?.alertBody == "Hello")
precondition(parsed?.soundName == "default")
precondition(parsed?.badge?.intValue == 2)
_ = parsed?.notificationID
_ = CKQueryNotification(reason: .recordCreated, databaseScope: .private, recordID: recordID)
_ = CKQueryNotification(reason: .recordUpdated, databaseScope: .public, recordID: nil)
_ = CKQueryNotification(reason: .recordDeleted, databaseScope: .shared, recordID: nil)
_ = CKRecordZoneNotification(databaseScope: .private, recordZoneID: zoneID)
_ = CKDatabaseNotification(databaseScope: .private)

// MARK: - Share value semantics, sharing fail-closed

let share = CKShare(rootRecord: record)
precondition(share.recordType == CKRecordTypeShare)
precondition(share.url == nil)
precondition(share.owner.role == .unknown)
precondition(share.owner.permission == .none)
precondition(share.owner.acceptanceStatus == .unknown)
precondition(share.owner.userIdentity.hasiCloudAccount == false)
precondition(share.oneTimeURL(for: share.owner.participantID) == nil)
share.publicPermission = .readOnly
share.allowsAccessRequests = true
let guest = CKShare.Participant(
    userIdentity: share.owner.userIdentity,
    role: .privateUser,
    permission: .readWrite,
    acceptanceStatus: .pending
)
share.addParticipant(guest)
precondition(share.participants.count == 2)
share.removeParticipant(guest)
precondition(share.participants.count == 1)
_ = CKShare.Participant.oneTimeURLParticipant()
_ = CKShare(recordZoneID: zoneID)
let options = CKAllowedSharingOptions.standard
precondition(options.allowedParticipantAccessOptions.contains(.anyoneWithLink))
options.allowsAccessRequests = true
options.allowsParticipantsToInviteOthers = true
_ = CKAllowedSharingOptions(
    allowedParticipantPermissionOptions: .readOnly,
    allowedParticipantAccessOptions: .specifiedRecipientsOnly
)

do {
    _ = try await named.accept([] as [CKShare.Metadata])
    fatalError("accept must fail closed")
} catch {
    requireCKError(error, code: .notAuthenticated)
}

named.discoverUserIdentity(withEmailAddress: "user@example.com") { _, _ in }
named.discoverUserIdentity(withPhoneNumber: "+1") { _, _ in }
named.discoverUserIdentity(withUserRecordID: recordID) { _, _ in }
named.fetchShareMetadata(with: URL(fileURLWithPath: "/")) { _, _ in }
named.fetchShareParticipant(withEmailAddress: "user@example.com") { _, _ in }
named.fetchShareParticipant(withPhoneNumber: "+1") { _, _ in }
named.fetchShareParticipant(withUserRecordID: recordID) { _, _ in }
named.fetchShareMetadatas(for: []) { _ in }
named.discoverUserIdentities(forUserRecordIDs: []) { _ in }
named.discoverUserIdentities(forPhoneNumbers: []) { _ in }
named.discoverUserIdentities(forEmailAddresses: []) { _ in }
named.fetchShareParticipants(forPhoneNumbers: []) { _ in }
named.fetchShareParticipants(forUserRecordIDs: []) { _ in }
named.fetchShareParticipants(forEmailAddresses: []) { _ in }
named.fetchLongLivedOperation(withID: "op") { _, _ in }
named.fetchAllLongLivedOperationIDs { _, _ in }
_ = named.configuredWith { container in container }
do {
    _ = try await named.shareMetadatas(for: [])
} catch {
    requireCKError(error, code: .notAuthenticated)
}
do {
    _ = try await named.userIdentities(forPhoneNumbers: [])
} catch {
    requireCKError(error, code: .notAuthenticated)
}
do {
    _ = try await named.userIdentities(forUserRecordIDs: [])
} catch {
    requireCKError(error, code: .notAuthenticated)
}
do {
    _ = try await named.userIdentities(forEmailAddresses: [])
} catch {
    requireCKError(error, code: .notAuthenticated)
}
do {
    _ = try await named.shareParticipants(forPhoneNumbers: [])
} catch {
    requireCKError(error, code: .notAuthenticated)
}
do {
    _ = try await named.shareParticipants(forUserRecordIDs: [])
} catch {
    requireCKError(error, code: .notAuthenticated)
}
do {
    _ = try await named.shareParticipants(forEmailAddresses: [])
} catch {
    requireCKError(error, code: .notAuthenticated)
}
do {
    _ = try await named.shareParticipants(for: [lookup])
} catch {
    requireCKError(error, code: .notAuthenticated)
}
do {
    _ = try await named.longLivedOperation(for: "op")
} catch {
    requireCKError(error, code: .notAuthenticated)
}
do {
    _ = try await named.requestShareAccess(for: [])
} catch {
    requireCKError(error, code: .notAuthenticated)
}
do {
    _ = try await named.allLongLivedOperationIDs()
} catch {
    requireCKError(error, code: .notAuthenticated)
}

let lookup = CKUserIdentity.LookupInfo(emailAddress: "user@example.com")
precondition(lookup.emailAddress == "user@example.com")
let phoneLookup = CKUserIdentity.LookupInfo(phoneNumber: "+15555550100")
precondition(phoneLookup.phoneNumber == "+15555550100")
let idLookup = CKUserIdentity.LookupInfo(userRecordID: recordID)
precondition(idLookup.userRecordID?.isEqual(recordID) == true)
let lookups = CKUserIdentity.LookupInfo.lookupInfos(withEmails: ["a@b.c"])
precondition(lookups.count == 1)
_ = CKUserIdentity.LookupInfo.lookupInfos(withPhoneNumbers: ["+1"])
_ = CKUserIdentity.LookupInfo.lookupInfos(with: [recordID])
_ = lookup.copy() as! CKUserIdentity.LookupInfo

do {
    _ = try await named.allUserIdentitiesFromContacts()
    fatalError("identity discovery must fail closed")
} catch {
    requireCKError(error, code: .notAuthenticated)
}

var insideContainerAdd = true
let discover = CKDiscoverAllUserIdentitiesOperation()
discover.userIdentityDiscoveredBlock = { _ in }
let discoverError = await withCheckedContinuation { continuation in
    discover.discoverAllUserIdentitiesCompletionBlock = { discoverErr in
        addLock.lock()
        let firedInline = insideContainerAdd
        addLock.unlock()
        continuation.resume(returning: (discoverErr, firedInline))
    }
    addLock.lock()
    named.add(discover)
    insideContainerAdd = false
    addLock.unlock()
}
precondition(discoverError.1 == false, "CKContainer.add must not invoke completions inline")
requireCKError(discoverError.0, code: .notAuthenticated)

let discoverOne = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [lookup])
discoverOne.userIdentityDiscoveredBlock = { _, _ in }
precondition(discoverOne.userIdentityLookupInfos.count == 1)
let acceptOp = CKAcceptSharesOperation()
acceptOp.shareMetadatas = []
acceptOp.perShareCompletionBlock = { _, _, _ in }
_ = CKAcceptSharesOperation(shareMetadatas: [])
_ = CKFetchShareMetadataOperation(shareURLs: [URL(fileURLWithPath: "/")])
_ = CKFetchShareParticipantsOperation(userIdentityLookupInfos: [lookup])
_ = CKShareRequestAccessOperation(shareURLs: [])
_ = CKFetchWebAuthTokenOperation(apiToken: "token")
_ = CKSystemSharingUIObserver(container: named)

let config = CKOperation.Configuration()
config.allowsCellularAccess = false
config.isLongLived = true
config.timeoutIntervalForRequest = 30
config.timeoutIntervalForResource = 60
config.qualityOfService = .userInitiated
config.container = named
let configCopy = config.copy() as! CKOperation.Configuration
precondition(configCopy.allowsCellularAccess == false)

let group = CKOperationGroup()
precondition(!group.operationGroupID.isEmpty)
precondition(group.expectedSendSize == .unknown)
group.expectedSendSize = .kilobytes
group.expectedReceiveSize = .megabytes
group.name = "batch"
group.quantity = 4
group.defaultConfiguration = config
precondition(group.expectedSendSize == .kilobytes)
_ = CKOperationGroup.TransferSize.tensOfMegabytes
_ = CKOperationGroup.TransferSize.hundredsOfMegabytes
_ = CKOperationGroup.TransferSize.gigabytes
_ = CKOperationGroup.TransferSize.tensOfGigabytes
_ = CKOperationGroup.TransferSize.hundredsOfGigabytes

let dbChangeFetch = CKFetchDatabaseChangesOperation(previousServerChangeToken: nil)
dbChangeFetch.fetchAllChanges = true
dbChangeFetch.resultsLimit = 10
dbChangeFetch.recordZoneWithIDChangedBlock = { _ in }
dbChangeFetch.recordZoneWithIDWasDeletedBlock = { _ in }
dbChangeFetch.recordZoneWithIDWasPurgedBlock = { _ in }
dbChangeFetch.recordZoneWithIDWasDeletedDueToUserEncryptedDataResetBlock = { _ in }
dbChangeFetch.changeTokenUpdatedBlock = { _ in }
let dbChangeToken = await withCheckedContinuation { continuation in
    dbChangeFetch.fetchDatabaseChangesCompletionBlock = { token, _, error in
        continuation.resume(returning: (token, error))
    }
    db.add(dbChangeFetch)
}
precondition(dbChangeToken.1 == nil)

let legacyChanges = CKFetchRecordChangesOperation(recordZoneID: zoneID, previousServerChangeToken: nil)
legacyChanges.desiredKeys = ["title"]
legacyChanges.recordChangedBlock = { _ in }
legacyChanges.recordWithIDWasDeletedBlock = { _ in }
_ = await withCheckedContinuation { continuation in
    legacyChanges.fetchRecordChangesCompletionBlock = { _, _, error in
        continuation.resume(returning: error)
    }
    db.add(legacyChanges)
}

let zoneOptions = CKFetchRecordZoneChangesOperation.ZoneOptions()
zoneOptions.desiredKeys = ["title"]
zoneOptions.resultsLimit = 10
_ = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], optionsByRecordZoneID: [zoneID: zoneOptions])

// MARK: - Offline + default-zone delete + asset missing

named.setSimulatedOffline(true)
do {
    _ = try await db.save(CKRecord(recordType: "Article", zoneID: zoneID))
    fatalError("offline save must fail")
} catch {
    requireCKError(error, code: .networkUnavailable)
}
named.setSimulatedOffline(false)

let defaultDelete = await withCheckedContinuation { continuation in
    db.delete(withRecordZoneID: .default) { zoneID, error in
        continuation.resume(returning: (zoneID, error))
    }
}
requireCKError(defaultDelete.1, code: .invalidArguments)

let missingAsset = CKAsset(fileURL: URL(fileURLWithPath: "/tmp/openuikit-cloudkit-missing-asset.bin"))
let assetRecord = CKRecord(recordType: "Article", recordID: CKRecord.ID(recordName: "asset-miss", zoneID: zoneID))
assetRecord["file"] = missingAsset
do {
    _ = try await db.save(assetRecord)
    fatalError("missing asset must fail")
} catch {
    requireCKError(error, code: .assetFileNotFound)
}

let deletedZone = await withCheckedContinuation { continuation in
    db.delete(withRecordZoneID: customZone.zoneID) { zoneID, error in
        continuation.resume(returning: (zoneID, error))
    }
}
precondition(deletedZone.1 == nil)

let reasons: [CKDatabase.DatabaseChange.Deletion.Reason] = [.deleted, .purged, .encryptedDataReset]
precondition(reasons.contains(.purged))
let deletion = CKDatabase.DatabaseChange.Deletion(zoneID: zoneID, reason: .purged)
precondition(deletion.purged)
precondition(deletion == deletion)
_ = deletion.hashValue
let modification = CKDatabase.DatabaseChange.Modification(zoneID: zoneID)
precondition(modification == modification)
let rzDeletion = CKDatabase.RecordZoneChange.Deletion(recordID: recordID, recordType: "Article")
precondition(rzDeletion == rzDeletion)
_ = rzDeletion.hashValue

print("CLOUDKIT_AGENT_RUNTIME_OK")
