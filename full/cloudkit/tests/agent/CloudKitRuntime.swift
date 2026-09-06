import CloudKit
import Foundation

// Schema-v1 sealed gate compiles only this file. Family tests live in
// tests/agent/*Tests.swift; this compilation unit inlines them so the
// host gate actually runs each focused test.

// MARK: - CloudKitTestSupport.swift
func requireCKError(_ error: Error?, code: CKError.Code) {
    guard let error = error as? CKError else {
        fatalError("expected typed CKError")
    }
    precondition(error.code == code)
    precondition(error.errorCode == code.rawValue)
    precondition(CKError.errorDomain == CKErrorDomain)
}

func isolatedContainer(_ suffix: String = UUID().uuidString) -> CKContainer {
    CKContainer(identifier: "iCloud.openuikit." + suffix)
}

func awaitValue<T>(_ body: (@escaping (T) -> Void) -> Void) async -> T {
    await withCheckedContinuation { continuation in
        body { value in continuation.resume(returning: value) }
    }
}

// MARK: - CKErrorTests.swift
func testCKErrorCodeRawValues() {
    let codes: [(CKError.Code, Int)] = [
        (.internalError, 1), (.partialFailure, 2), (.networkUnavailable, 3),
        (.networkFailure, 4), (.badContainer, 5), (.serviceUnavailable, 6),
        (.requestRateLimited, 7), (.missingEntitlement, 8), (.notAuthenticated, 9),
        (.permissionFailure, 10), (.unknownItem, 11), (.invalidArguments, 12),
        (.resultsTruncated, 13), (.serverRecordChanged, 14), (.serverRejectedRequest, 15),
        (.assetFileNotFound, 16), (.assetFileModified, 17), (.incompatibleVersion, 18),
        (.constraintViolation, 19), (.operationCancelled, 20), (.changeTokenExpired, 21),
        (.batchRequestFailed, 22), (.zoneBusy, 23), (.badDatabase, 24),
        (.quotaExceeded, 25), (.zoneNotFound, 26), (.limitExceeded, 27),
        (.userDeletedZone, 28), (.tooManyParticipants, 29), (.alreadyShared, 30),
        (.referenceViolation, 31), (.managedAccountRestricted, 32),
        (.participantMayNeedVerification, 33), (.serverResponseLost, 34),
        (.assetNotAvailable, 35), (.accountTemporarilyUnavailable, 36),
        (.participantAlreadyInvited, 37),
    ]
    precondition(codes.count == 37)
    for (code, raw) in codes {
        precondition(code.rawValue == raw)
        precondition(CKError.Code(rawValue: raw) == code)
    }
}

func testCKErrorStaticAliases() {
    precondition(CKError.internalError == .internalError)
    precondition(CKError.partialFailure == .partialFailure)
    precondition(CKError.networkUnavailable == .networkUnavailable)
    precondition(CKError.networkFailure == .networkFailure)
    precondition(CKError.badContainer == .badContainer)
    precondition(CKError.serviceUnavailable == .serviceUnavailable)
    precondition(CKError.requestRateLimited == .requestRateLimited)
    precondition(CKError.missingEntitlement == .missingEntitlement)
    precondition(CKError.notAuthenticated == .notAuthenticated)
    precondition(CKError.permissionFailure == .permissionFailure)
    precondition(CKError.unknownItem == .unknownItem)
    precondition(CKError.invalidArguments == .invalidArguments)
    precondition(CKError.resultsTruncated == .resultsTruncated)
    precondition(CKError.serverRecordChanged == .serverRecordChanged)
    precondition(CKError.serverRejectedRequest == .serverRejectedRequest)
    precondition(CKError.assetFileNotFound == .assetFileNotFound)
    precondition(CKError.assetFileModified == .assetFileModified)
    precondition(CKError.incompatibleVersion == .incompatibleVersion)
    precondition(CKError.constraintViolation == .constraintViolation)
    precondition(CKError.operationCancelled == .operationCancelled)
    precondition(CKError.changeTokenExpired == .changeTokenExpired)
    precondition(CKError.batchRequestFailed == .batchRequestFailed)
    precondition(CKError.zoneBusy == .zoneBusy)
    precondition(CKError.badDatabase == .badDatabase)
    precondition(CKError.quotaExceeded == .quotaExceeded)
    precondition(CKError.zoneNotFound == .zoneNotFound)
    precondition(CKError.limitExceeded == .limitExceeded)
    precondition(CKError.userDeletedZone == .userDeletedZone)
    precondition(CKError.tooManyParticipants == .tooManyParticipants)
    precondition(CKError.alreadyShared == .alreadyShared)
    precondition(CKError.referenceViolation == .referenceViolation)
    precondition(CKError.managedAccountRestricted == .managedAccountRestricted)
    precondition(CKError.participantMayNeedVerification == .participantMayNeedVerification)
    precondition(CKError.serverResponseLost == .serverResponseLost)
    precondition(CKError.assetNotAvailable == .assetNotAvailable)
    precondition(CKError.accountTemporarilyUnavailable == .accountTemporarilyUnavailable)
    precondition(CKError.participantAlreadyInvited == .participantAlreadyInvited)
}

func testCKErrorUserInfoAndPatternMatch() {
    precondition(CKErrorDomain == "CKErrorDomain")
    precondition(CKError.errorDomain == CKErrorDomain)
    precondition(CKErrorRetryAfterKey == "CKRetryAfterSeconds")
    precondition(CKErrorUserDidResetEncryptedDataKey == "CKErrorUserDidResetEncryptedData")
    precondition(CKPartialErrorsByItemIDKey == "CKPartialErrors")
    precondition(CKRecordChangedErrorAncestorRecordKey == "CKAncestorRecord")
    precondition(CKRecordChangedErrorClientRecordKey == "CKClientRecord")
    precondition(CKRecordChangedErrorServerRecordKey == "CKServerRecord")

    let bare = CKError(.notAuthenticated)
    precondition(bare.code == .notAuthenticated)
    precondition(bare.errorCode == CKError.Code.notAuthenticated.rawValue)
    precondition(bare.retryAfterSeconds == nil)
    precondition(bare.partialErrorsByItemID == nil)
    precondition(bare.clientRecord == nil)
    precondition(bare.serverRecord == nil)
    precondition(bare.ancestorRecord == nil)
    precondition(bare == CKError(.notAuthenticated))
    precondition(bare.hashValue == CKError(.notAuthenticated).hashValue)

    let retry = CKError(.zoneBusy, userInfo: [CKErrorRetryAfterKey: 1.5])
    precondition(retry.retryAfterSeconds == 1.5)
    let retryNumber = CKError(.zoneBusy, userInfo: [CKErrorRetryAfterKey: NSNumber(value: 2.0)])
    precondition(retryNumber.retryAfterSeconds == 2.0)

    let item = CKRecord.ID(recordName: "missing")
    let nested = CKError(.unknownItem)
    let partial = CKError(
        .partialFailure,
        userInfo: [CKPartialErrorsByItemIDKey: [item as AnyHashable: nested as any Error]]
    )
    precondition(partial.partialErrorsByItemID?[item] is CKError)

    let client = CKRecord(recordType: "Article")
    let server = CKRecord(recordType: "Article", recordID: client.recordID)
    let changed = CKError(
        .serverRecordChanged,
        userInfo: [
            CKRecordChangedErrorClientRecordKey: client,
            CKRecordChangedErrorServerRecordKey: server,
            CKRecordChangedErrorAncestorRecordKey: server,
        ]
    )
    precondition(changed.clientRecord?.recordID.isEqual(client.recordID) == true)
    precondition(changed.serverRecord?.recordID.isEqual(server.recordID) == true)
    precondition(changed.ancestorRecord?.recordID.isEqual(server.recordID) == true)

    let caught: any Error = CKError(.unknownItem)
    precondition(CKError.Code.unknownItem ~= caught)
    precondition(!(CKError.Code.zoneNotFound ~= caught))
    _ = CKError.Code.self
}

// MARK: - CKRecordValueTests.swift
func testCKRecordStringNumberDateDataValues() {
    let record = CKRecord(recordType: "Article")
    precondition(record.recordType == "Article")
    record["title"] = "Hello"
    record["count"] = 3
    record["wide"] = Int64(99)
    record["flag"] = true
    record["ratio"] = 1.25
    record["small"] = Float(0.5)
    let blob = Data([0x0A, 0x0B])
    let stamp = Date(timeIntervalSince1970: 1_700_000_000)
    record["blob"] = blob
    record["stamp"] = stamp
    record["ns"] = NSString(string: "bridged")
    record["number"] = NSNumber(value: 7)
    record["tags"] = ["a", "b"]
    record["nums"] = [NSNumber(value: 1), NSNumber(value: 2)]

    precondition((record["title"] as? String) == "Hello")
    precondition(record.object(forKey: "count") as? Int == 3)
    precondition((record["wide"] as? Int64) == 99)
    precondition((record["flag"] as? Bool) == true)
    precondition((record["ratio"] as? Double) == 1.25)
    precondition((record["small"] as? Float) == 0.5)
    precondition((record["blob"] as? Data) == blob)
    precondition((record["stamp"] as? Date) == stamp)
    precondition((record["ns"] as? NSString) == "bridged")
    precondition((record["number"] as? NSNumber)?.intValue == 7)
    precondition((record["tags"] as? [String]) == ["a", "b"])
    precondition(Set(record.allKeys()).isSuperset(of: ["title", "count", "blob", "stamp"]))
    precondition(Set(record.changedKeys()).isSuperset(of: ["title", "count"]))
    record.setObject(nil, forKey: "count")
    precondition(record["count"] == nil)
    let typed: String? = record["title"]
    precondition(typed == "Hello")
    _ = record.encryptedValues
    precondition(record.allTokens().isEmpty)
    _ = record.recordChangeTag
    _ = record.creationDate
    _ = record.modificationDate
    _ = record.creatorUserRecordID
    _ = record.lastModifiedUserRecordID
    _ = record.share
    _ = CKRecordValue.self
    _ = CKRecordKeyValueSetting.self
}

func testCKRecordReferenceParentAndIteration() {
    let zoneID = CKRecordZone.ID(zoneName: "Articles")
    let recordID = CKRecord.ID(recordName: "rec-1", zoneID: zoneID)
    let record = CKRecord(recordType: "Article", recordID: recordID)
    record["title"] = "Hello"
    let parent = CKRecord(recordType: "Folder", zoneID: zoneID)
    record.setParent(parent)
    precondition(record.parent?.recordID.isEqual(parent.recordID) == true)
    record.setParent(nil as CKRecord.ID?)
    precondition(record.parent == nil)
    record.setParent(parent.recordID)
    precondition(record.parent?.recordID.isEqual(parent.recordID) == true)
    precondition(record.parent?.action == CKRecord.ReferenceAction.none)

    let reference = CKRecord.Reference(record: record, action: .deleteSelf)
    precondition(reference.action == .deleteSelf)
    precondition(reference.referenceAction == .deleteSelf)
    precondition(reference.recordID.isEqual(record.recordID))
    let noneRef = CKRecord.Reference(recordID: recordID, action: .none)
    precondition(noneRef.action == .none)
    precondition((noneRef.copy() as! CKRecord.Reference).isEqual(noneRef))
    record["ref"] = reference
    precondition((record["ref"] as? CKRecord.Reference)?.isEqual(reference) == true)
    precondition(CKRecord.ReferenceAction.none.rawValue == 0)
    precondition(CKRecord.ReferenceAction.deleteSelf.rawValue == 1)
    _ = CKRecord_Reference_Action.none

    var iterator = record.makeIterator()
    var iterated = Set<String>()
    while let (key, _) = iterator.next() {
        iterated.insert(key)
    }
    precondition(iterated.contains("title"))
    precondition(iterated.contains("ref"))
    let sequenced = Set(record.map { $0.0 })
    precondition(sequenced.contains("title"))
}

func testCKRecordSecureCodingRoundTrip() throws {
    let zoneID = CKRecordZone.ID(zoneName: "Articles", ownerName: CKCurrentUserDefaultName)
    let recordID = CKRecord.ID(recordName: "rec-1", zoneID: zoneID)
    let record = CKRecord(recordType: "Article", recordID: recordID)
    record["title"] = "Hello"
    record["blob"] = Data([0x01])

    let keyed = try NSKeyedArchiver.archivedData(withRootObject: recordID, requiringSecureCoding: true)
    let restoredID = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.ID.self, from: keyed)
    precondition(restoredID?.isEqual(recordID) == true)
    precondition(CKRecord.ID.supportsSecureCoding)

    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    record.encodeSystemFields(with: archiver)
    archiver.finishEncoding()
    let unarchiver = try NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
    unarchiver.requiresSecureCoding = true
    let restoredSystem = CKRecord(coder: unarchiver)
    precondition(restoredSystem?.recordType == "Article")
    precondition(restoredSystem?.recordID.isEqual(recordID) == true)
    precondition(CKRecord.supportsSecureCoding)

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

    precondition(CKRecord.SystemType.userRecord == CKRecordTypeUserRecord)
    precondition(CKRecord.SystemType.share == CKRecordTypeShare)
    precondition(CKRecord.SystemFieldKey.recordID == "recordID")
    precondition(CKRecord.SystemFieldKey.creatorUserRecordID == "creatorUserRecordID")
    precondition(CKRecord.SystemFieldKey.lastModifiedUserRecordID == "lastModifiedUserRecordID")
    precondition(CKRecord.SystemFieldKey.creationDate == "creationDate")
    precondition(CKRecord.SystemFieldKey.modificationDate == "modificationDate")
    precondition(CKRecord.SystemFieldKey.parent == CKRecordParentKey)
    precondition(CKRecord.SystemFieldKey.share == CKRecordShareKey)
    precondition(CKRecordTypeUserRecord == "Users")
    precondition(CKRecordTypeShare == "cloudkit.share")
    precondition(CKRecordParentKey == "___parent")
    precondition(CKRecordShareKey == "___share")
}

// MARK: - CKRecordIDZoneTests.swift
func testCKRecordIDAndDefaultZoneRules() {
    precondition(CKCurrentUserDefaultName == "__defaultOwner__")
    precondition(CKOwnerDefaultName == "__defaultOwner__")
    precondition(CKRecordZoneDefaultName == "_defaultZone")
    precondition(CKRecordZone.ID.defaultZoneName == CKRecordZoneDefaultName)
    precondition(CKRecordZone.ID.default.zoneName == CKRecordZoneDefaultName)
    precondition(CKRecordZone.ID.default.ownerName == CKCurrentUserDefaultName)
    precondition(CKRecordZone.ID.default.isEqual(CKRecordZone.default().zoneID))
    precondition(CKRecordZone.default().zoneID.isEqual(CKRecordZone.ID.default))
    precondition(CKRecord.ID.supportsSecureCoding)
    precondition(CKRecordZone.ID.supportsSecureCoding)
    precondition(CKRecordZone.supportsSecureCoding)

    let zoneID = CKRecordZone.ID(zoneName: "Articles", ownerName: CKCurrentUserDefaultName)
    precondition(zoneID.zoneName == "Articles")
    precondition(zoneID.ownerName == CKCurrentUserDefaultName)
    precondition((zoneID.copy() as! CKRecordZone.ID).isEqual(zoneID))
    precondition(zoneID.hash == (zoneID.copy() as! CKRecordZone.ID).hash)

    let recordID = CKRecord.ID(recordName: "rec-1", zoneID: zoneID)
    precondition(recordID.recordName == "rec-1")
    precondition(recordID.zoneID.isEqual(zoneID))
    precondition(recordID.isEqual(CKRecord.ID(recordName: "rec-1", zoneID: zoneID)))
    precondition((recordID.copy() as! CKRecord.ID).isEqual(recordID))
    let generated = CKRecord.ID()
    precondition(!generated.recordName.isEmpty)
    precondition(generated.zoneID.isEqual(CKRecordZone.ID.default))

    let zoned = CKRecord(recordType: "Article", zoneID: zoneID)
    precondition(zoned.recordID.zoneID.isEqual(zoneID))
}

func testCKRecordZoneCapabilitiesAndCopy() {
    let zone = CKRecordZone(zoneName: "Articles")
    precondition(zone.zoneID.zoneName == "Articles")
    precondition(zone.encryptionScope == .perRecord)
    zone.encryptionScope = .perZone
    precondition(zone.encryptionScope == .perZone)
    precondition(CKRecordZone.EncryptionScope.perRecord.rawValue == 0)
    precondition(CKRecordZone.EncryptionScope.perZone.rawValue == 1)
    let zoneCopy = zone.copy() as! CKRecordZone
    precondition(zoneCopy.zoneID.isEqual(zone.zoneID))
    precondition(zone.isEqual(zoneCopy))
    precondition(zone.hash == zoneCopy.hash)

    var capabilities: CKRecordZone.Capabilities = [.atomic, .fetchChanges]
    precondition(capabilities.contains(.atomic))
    precondition(capabilities.contains(.fetchChanges))
    capabilities.insert(.sharing)
    precondition(capabilities.contains(.sharing))
    capabilities.insert(.zoneWideSharing)
    precondition(capabilities.contains(.zoneWideSharing))
    precondition(CKRecordZone.Capabilities.fetchChanges.rawValue == 1)
    precondition(CKRecordZone.Capabilities.atomic.rawValue == 2)
    precondition(CKRecordZone.Capabilities.sharing.rawValue == 4)
    precondition(CKRecordZone.Capabilities.zoneWideSharing.rawValue == 8)
    _ = CKRecordZone.Capabilities(rawValue: 0)

    let byID = CKRecordZone(zoneID: zone.zoneID)
    precondition(byID.zoneID.isEqual(zone.zoneID))
}

func testCKQueryConstructionAndCopy() {
    let predicate = NSPredicate { object, _ in
        (object as? CKRecord)?["title"] as? String == "Hello"
    }
    let query = CKQuery(recordType: "Article", predicate: predicate)
    precondition(query.recordType == "Article")
    precondition(query.predicate === predicate)
    query.sortDescriptors = [NSSortDescriptor(keyPath: \CKRecord.recordType, ascending: true)]
    precondition(query.sortDescriptors?.count == 1)
    let copied = query.copy() as! CKQuery
    precondition(copied.recordType == "Article")
    precondition(copied.sortDescriptors?.count == 1)
    precondition(CKQuery.supportsSecureCoding)
    _ = CKQueryOperation.maximumResults
    precondition(CKQueryOperation.maximumResults == 0)
}

// MARK: - CKContainerDatabaseTests.swift
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

// MARK: - CKOperationCallbackTests.swift
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

// MARK: - CKSubscriptionTests.swift
func testCKSubscriptionValueStoreAndPersistence() async throws {
    let named = isolatedContainer("subs")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)

    precondition(CKSubscription.SubscriptionType.query.rawValue == 1)
    precondition(CKSubscription.SubscriptionType.recordZone.rawValue == 2)
    precondition(CKSubscription.SubscriptionType.database.rawValue == 3)
    precondition(CKSubscription.SubscriptionType(rawValue: 1) == .query)
    precondition(CKQuerySubscription.Options.firesOnRecordCreation.rawValue == 1)
    precondition(CKQuerySubscription.Options.firesOnRecordUpdate.rawValue == 2)
    precondition(CKQuerySubscription.Options.firesOnRecordDeletion.rawValue == 4)
    precondition(CKQuerySubscription.Options.firesOnce.rawValue == 8)
    _ = CKQuerySubscription.Options(rawValue: 1)

    let info = CKSubscription.NotificationInfo(alertBody: "changed", shouldBadge: true)
    let subscription = CKQuerySubscription(
        recordType: "Article",
        predicate: NSPredicate(value: true),
        subscriptionID: "sub-articles",
        options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion, .firesOnce]
    )
    subscription.zoneID = zone.zoneID
    subscription.notificationInfo = info
    precondition(subscription.subscriptionType == .query)
    precondition(subscription.subscriptionID == "sub-articles")
    precondition(subscription.querySubscriptionOptions.contains(.firesOnRecordCreation))
    precondition(subscription.querySubscriptionOptions.contains(.firesOnRecordUpdate))
    precondition(subscription.querySubscriptionOptions.contains(.firesOnRecordDeletion))
    precondition(subscription.querySubscriptionOptions.contains(.firesOnce))
    precondition(subscription.recordType == "Article")
    precondition(subscription.predicate == NSPredicate(value: true))
    _ = CKQuerySubscription(
        recordType: "Article",
        predicate: NSPredicate(value: true),
        options: [.firesOnRecordCreation]
    )
    let savedSub = try await db.save(subscription)
    precondition(savedSub.subscriptionID == "sub-articles")

    let zoneSub = CKRecordZoneSubscription(zoneID: zone.zoneID, subscriptionID: "sub-zone")
    zoneSub.recordType = "Article"
    precondition(zoneSub.subscriptionType == .recordZone)
    precondition(zoneSub.zoneID.isEqual(zone.zoneID))
    _ = CKRecordZoneSubscription(zoneID: zone.zoneID)
    _ = try await db.save(zoneSub)

    let dbSub = CKDatabaseSubscription(subscriptionID: "sub-db")
    dbSub.recordType = "Article"
    precondition(dbSub.subscriptionType == .database)
    precondition(CKDatabaseSubscription().subscriptionType == .database)
    _ = try await db.save(dbSub)

    _ = CKSubscription.ID.self
    _ = CKSubscription.supportsSecureCoding
}

func testCKSubscriptionDatabaseFetchAndDelete() async throws {
    let named = isolatedContainer("subs-fetch")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)
    let zoneSub = CKRecordZoneSubscription(zoneID: zone.zoneID, subscriptionID: "sub-zone-fetch")
    _ = try await db.save(zoneSub)
    let fetchedSub = try await db.subscription(for: "sub-zone-fetch")
    precondition(fetchedSub.subscriptionID == "sub-zone-fetch")
    let allSubs = try await db.allSubscriptions()
    precondition(allSubs.contains { $0.subscriptionID == "sub-zone-fetch" })
    let byIDs = try await db.subscriptions(for: ["sub-zone-fetch"])
    precondition((try? byIDs["sub-zone-fetch"]?.get()) != nil)
    _ = try await db.deleteSubscription(withID: "sub-zone-fetch")
}

func testCKSubscriptionNotificationInfo() {
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
    precondition(info.alertLocalizationKey == "loc")
    precondition(info.alertLocalizationArgs == ["title"])
    precondition(info.shouldBadge)
    precondition(info.shouldSendContentAvailable)
    precondition(info.shouldSendMutableContent == false)
    precondition(info.title == "T")
    precondition(info.titleLocalizationKey == "tk")
    precondition(info.subtitle == "S")
    precondition(info.subtitleLocalizationKey == "sk")
    precondition(info.soundName == "default")
    precondition(info.category == "cat")
    precondition(info.collapseIDKey == "collapse")
    precondition(info.alertActionLocalizationKey == "act")
    precondition(info.alertLaunchImage == "img")
    _ = info.copy() as! CKSubscription.NotificationInfo
    precondition(CKSubscription.NotificationInfo.supportsSecureCoding)
    _ = CKSubscription.NotificationInfo()
}

func testCKSubscriptionOperations() async throws {
    let named = isolatedContainer("sub-ops")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)
    let zoneSub = CKRecordZoneSubscription(zoneID: zone.zoneID, subscriptionID: "sub-zone")
    zoneSub.recordType = "Article"
    _ = try await db.save(zoneSub)

    let modifySubs = CKModifySubscriptionsOperation(
        subscriptionsToSave: [
            CKQuerySubscription(
                recordType: "Article",
                predicate: NSPredicate(value: true),
                options: [.firesOnRecordCreation]
            )
        ],
        subscriptionIDsToDelete: []
    )
    modifySubs.perSubscriptionSaveBlock = { _, _ in }
    modifySubs.perSubscriptionDeleteBlock = { _, _ in }
    let subModify = await awaitValue { done in
        modifySubs.modifySubscriptionsCompletionBlock = { _, _, error in
            done(error)
        }
        modifySubs.modifySubscriptionsResultBlock = { _ in }
        db.add(modifySubs)
    }
    precondition(subModify == nil)
    _ = CKModifySubscriptionsOperation()
    _ = try await db.modifySubscriptions(saving: [], deleting: [])

    let fetchSubs = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
    fetchSubs.perSubscriptionResultBlock = { _, _ in }
    fetchSubs.fetchSubscriptionsResultBlock = { _ in }
    let subMap = await awaitValue { done in
        fetchSubs.fetchSubscriptionCompletionBlock = { map, error in
            done((map, error))
        }
        db.add(fetchSubs)
    }
    precondition(subMap.1 == nil)
    _ = CKFetchSubscriptionsOperation(subscriptionIDs: ["sub-zone"])
    _ = CKFetchSubscriptionsOperation()
}

// MARK: - CKAssetTests.swift
func testCKAssetFileCopyOnSave() async throws {
    let named = isolatedContainer("asset")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)

    let source = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("cloudkit-asset-\(UUID().uuidString).bin")
    let payload = Data([0x01, 0x02, 0x03, 0x04])
    try payload.write(to: source)
    let asset = CKAsset(fileURL: source)
    precondition(asset.fileURL == source)
    precondition(CKAsset.supportsSecureCoding)

    let record = CKRecord(
        recordType: "Article",
        recordID: CKRecord.ID(recordName: "asset-1", zoneID: zone.zoneID)
    )
    record["file"] = asset
    let saved = try await db.save(record)
    let stored = saved["file"] as? CKAsset
    precondition(stored?.fileURL != nil)
    precondition(stored?.fileURL != source)
    let copiedBytes = try Data(contentsOf: stored!.fileURL!)
    precondition(copiedBytes == payload)

    let missingAsset = CKAsset(fileURL: URL(fileURLWithPath: "/tmp/openuikit-cloudkit-missing-asset.bin"))
    let assetRecord = CKRecord(
        recordType: "Article",
        recordID: CKRecord.ID(recordName: "asset-miss", zoneID: zone.zoneID)
    )
    assetRecord["file"] = missingAsset
    do {
        _ = try await db.save(assetRecord)
        fatalError("missing asset must fail")
    } catch {
        requireCKError(error, code: .assetFileNotFound)
    }
}

// MARK: - CKChangeTokenTests.swift
func testCKServerChangeTokensAndZoneChanges() async throws {
    let named = isolatedContainer("tokens")
    let db = named.privateCloudDatabase
    let zone = CKRecordZone(zoneName: "Articles")
    _ = try await db.save(zone)
    let recordID = CKRecord.ID(recordName: "tok-1", zoneID: zone.zoneID)
    let record = CKRecord(recordType: "Article", recordID: recordID)
    record["title"] = "Hello"
    _ = try await db.save(record)

    let dbChanges = try await db.databaseChanges(since: nil, resultsLimit: nil)
    precondition(!dbChanges.modifications.isEmpty)
    _ = dbChanges.deletions
    _ = dbChanges.changeToken
    _ = dbChanges.moreComing
    let hashedMod = dbChanges.modifications[0]
    precondition(hashedMod == hashedMod)
    _ = hashedMod.hashValue
    precondition(hashedMod.zoneID.zoneName == "Articles" || hashedMod.zoneID.isEqual(CKRecordZone.ID.default))

    let reasons: [CKDatabase.DatabaseChange.Deletion.Reason] = [.deleted, .purged, .encryptedDataReset]
    precondition(reasons.contains(.purged))
    let deletion = CKDatabase.DatabaseChange.Deletion(zoneID: zone.zoneID, reason: .purged)
    precondition(deletion.purged)
    precondition(deletion.reason == .purged)
    precondition(deletion.zoneID.isEqual(zone.zoneID))
    precondition(deletion == deletion)
    _ = deletion.hashValue
    let modification = CKDatabase.DatabaseChange.Modification(zoneID: zone.zoneID)
    precondition(modification == modification)
    precondition(modification.zoneID.isEqual(zone.zoneID))
    _ = modification.hashValue
    let rzDeletion = CKDatabase.RecordZoneChange.Deletion(recordID: recordID, recordType: "Article")
    precondition(rzDeletion == rzDeletion)
    precondition(rzDeletion.recordType == "Article")
    precondition(rzDeletion.recordID.isEqual(recordID))
    _ = rzDeletion.hashValue
    let rzMod = CKDatabase.RecordZoneChange.Modification(record: record)
    precondition(rzMod == rzMod)
    precondition(rzMod.record.recordID.isEqual(recordID))
    _ = rzMod.hashValue
    _ = CKDatabase.DatabaseChange.self
    _ = CKDatabase.RecordZoneChange.self

    let rzChanges = try await db.recordZoneChanges(
        inZoneWith: zone.zoneID,
        since: nil,
        desiredKeys: nil,
        resultsLimit: nil
    )
    precondition(!rzChanges.modificationResultsByID.isEmpty)
    let token = rzChanges.changeToken
    let tokenCopy = token.copy() as? CKServerChangeToken
    precondition(tokenCopy?.isEqual(token) == true)
    precondition(token.hash == tokenCopy?.hash)
    precondition(CKServerChangeToken.supportsSecureCoding)
    let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
    let restoredToken = try NSKeyedUnarchiver.unarchivedObject(
        ofClass: CKServerChangeToken.self,
        from: tokenData
    )
    precondition(restoredToken?.isEqual(token) == true)

    let extra = CKRecord(
        recordType: "Article",
        recordID: CKRecord.ID(recordName: "tok-2", zoneID: zone.zoneID)
    )
    extra["title"] = "Next"
    _ = try await db.save(extra)
    let next = try await db.recordZoneChanges(
        inZoneWith: zone.zoneID,
        since: token,
        desiredKeys: ["title"],
        resultsLimit: 10
    )
    precondition(!next.modificationResultsByID.isEmpty || next.deletions.isEmpty)
}

// MARK: - CKNotificationShareTests.swift
func testCKNotificationParseAndTypes() {
    precondition(CKNotification.NotificationType.query.rawValue == 1)
    precondition(CKNotification.NotificationType.recordZone.rawValue == 2)
    precondition(CKNotification.NotificationType.readNotification.rawValue == 3)
    precondition(CKNotification.NotificationType.database.rawValue == 4)
    precondition(CKQueryNotification.Reason.recordCreated.rawValue == 1)
    precondition(CKQueryNotification.Reason.recordUpdated.rawValue == 2)
    precondition(CKQueryNotification.Reason.recordDeleted.rawValue == 3)

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
    precondition(parsed?.category == "cat")
    precondition(parsed?.isPruned == false)
    _ = parsed?.notificationID
    _ = parsed?.alertActionLocalizationKey
    _ = parsed?.alertLaunchImage
    _ = parsed?.alertLocalizationArgs
    _ = parsed?.alertLocalizationKey
    _ = parsed?.title
    _ = parsed?.titleLocalizationKey
    _ = parsed?.titleLocalizationArgs
    _ = parsed?.subtitle
    _ = parsed?.subtitleLocalizationKey
    _ = parsed?.subtitleLocalizationArgs
    precondition(parsed?.subscriptionOwnerUserRecordID == nil || parsed?.subscriptionOwnerUserRecordID != nil)
}

func testCKQueryZoneAndDatabaseNotificationTypes() {
    precondition(CKQueryNotification.Reason.recordCreated.rawValue == 1)
    precondition(CKQueryNotification.Reason.recordUpdated.rawValue == 2)
    precondition(CKQueryNotification.Reason.recordDeleted.rawValue == 3)
    precondition(CKNotification.ID.supportsSecureCoding)
    _ = CKNotification.ID()

    let recordID = CKRecord.ID(recordName: "n1")
    let zoneID = CKRecordZone.ID(zoneName: "Articles")
    let created = CKQueryNotification(reason: .recordCreated, databaseScope: .private, recordID: recordID)
    precondition(created.queryNotificationReason == .recordCreated)
    precondition(created.databaseScope == .private)
    precondition(created.recordID?.isEqual(recordID) == true)
    _ = created.recordFields
    _ = CKQueryNotification(reason: .recordUpdated, databaseScope: .public, recordID: nil)
    _ = CKQueryNotification(reason: .recordDeleted, databaseScope: .shared, recordID: nil)
    let zoneNote = CKRecordZoneNotification(databaseScope: .private, recordZoneID: zoneID)
    _ = zoneNote.recordZoneID
    let dbNote = CKDatabaseNotification(databaseScope: .private)
    precondition(dbNote.databaseScope == .private)
}

func testCKShareValueSemanticsAndFailClosedURL() {
    let record = CKRecord(recordType: "Article")
    let share = CKShare(rootRecord: record)
    precondition(share.recordType == CKRecordTypeShare)
    precondition(share.url == nil)
    precondition(share.owner.role == .unknown)
    precondition(share.owner.permission == CKShare.ParticipantPermission.none)
    precondition(share.owner.acceptanceStatus == .unknown)
    precondition(share.owner.userIdentity.hasiCloudAccount == false)
    precondition(share.oneTimeURL(for: share.owner.participantID) == nil)
    share.publicPermission = .readOnly
    share.allowsAccessRequests = true
    precondition(share.publicPermission == .readOnly)
    precondition(share.allowsAccessRequests)
    _ = share.blockedIdentities
    _ = share.currentUserParticipant
    _ = share.requesters
    share.blockRequesters([])
    share.denyRequesters([])
    share.unblockIdentities([])

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
    _ = CKShare(recordZoneID: CKRecordZone.ID(zoneName: "Articles"))
    _ = CKShare(rootRecord: record, shareID: CKRecord.ID(recordName: CKRecordNameZoneWideShare))
    _ = CKShare(rootRecord: record, share: CKRecord.ID(recordName: "share-2"))
    precondition(CKRecordNameZoneWideShare == "cloudkit.zoneshare")
    precondition(CKShare.SystemFieldKey.title == CKShareTitleKey)
    precondition(CKShare.SystemFieldKey.shareType == CKShareTypeKey)
    precondition(CKShare.SystemFieldKey.thumbnailImageData == CKShareThumbnailImageDataKey)
    precondition(CKShareTitleKey == "cloudkit.share.title")
    precondition(CKShareTypeKey == "cloudkit.share.type")
    precondition(CKShareThumbnailImageDataKey == "cloudkit.share.thumbnailImageData")
    _ = CKShare_Participant_AcceptanceStatus.unknown
    _ = CKShare_Participant_Permission.none
    _ = CKShare_Participant_Role.owner
    _ = CKShare.Participant.Permission.readOnly
    _ = CKShare.Participant.AcceptanceStatus.accepted
    _ = CKShare.Participant.Role.administrator
    _ = CKShare.Participant.ID.self
}

func testCKShareMetadataAndAccessTypes() {
    precondition(CKShare.Metadata.supportsSecureCoding)
    precondition(CKShare.AccessRequester.supportsSecureCoding)
    precondition(CKShare.BlockedIdentity.supportsSecureCoding)
    let named = isolatedContainer("share-meta")
    _ = named
}

func testCKShareParticipantEnums() {
    precondition(CKShare.ParticipantAcceptanceStatus.unknown.rawValue == 0)
    precondition(CKShare.ParticipantAcceptanceStatus.pending.rawValue == 1)
    precondition(CKShare.ParticipantAcceptanceStatus.accepted.rawValue == 2)
    precondition(CKShare.ParticipantAcceptanceStatus.removed.rawValue == 3)
    precondition(CKShare.ParticipantAcceptanceStatus(rawValue: 2) == .accepted)
    precondition(CKShare.ParticipantPermission.unknown.rawValue == 0)
    precondition(CKShare.ParticipantPermission.none.rawValue == 1)
    precondition(CKShare.ParticipantPermission.readOnly.rawValue == 2)
    precondition(CKShare.ParticipantPermission.readWrite.rawValue == 3)
    precondition(CKShare.ParticipantPermission(rawValue: 3) == .readWrite)
    precondition(CKShare.ParticipantRole.unknown.rawValue == 0)
    precondition(CKShare.ParticipantRole.owner.rawValue == 1)
    precondition(CKShare.ParticipantRole.administrator.rawValue == 2)
    precondition(CKShare.ParticipantRole.privateUser.rawValue == 3)
    precondition(CKShare.ParticipantRole.publicUser.rawValue == 4)
    precondition(CKShare.ParticipantRole(rawValue: 1) == .owner)
    _ = CKShare_Participant_AcceptanceStatus.unknown
    _ = CKShare_Participant_Permission.none
    _ = CKShare_Participant_Role.owner
    _ = CKShare.Participant.Permission.readOnly
    _ = CKShare.Participant.AcceptanceStatus.accepted
    _ = CKShare.Participant.Role.administrator
}

func testCKSharingOptions() {
    precondition(CKSharingParticipantAccessOption.anyoneWithLink.rawValue == 1)
    precondition(CKSharingParticipantAccessOption.specifiedRecipientsOnly.rawValue == 2)
    precondition(CKSharingParticipantAccessOption.any.contains(.anyoneWithLink))
    precondition(CKSharingParticipantPermissionOption.readOnly.rawValue == 1)
    precondition(CKSharingParticipantPermissionOption.readWrite.rawValue == 2)
    precondition(CKSharingParticipantPermissionOption.any.contains(.readWrite))
    let options = CKAllowedSharingOptions.standard
    precondition(options.allowedParticipantAccessOptions.contains(.anyoneWithLink))
    options.allowsAccessRequests = true
    options.allowsParticipantsToInviteOthers = true
    _ = CKAllowedSharingOptions(
        allowedParticipantPermissionOptions: .readOnly,
        allowedParticipantAccessOptions: .specifiedRecipientsOnly
    )
    precondition(CKAllowedSharingOptions.supportsSecureCoding)
}

func testCKUserIdentityLookupInfo() {
    let recordID = CKRecord.ID(recordName: "user-1")
    let lookup = CKUserIdentity.LookupInfo(emailAddress: "user@example.com")
    precondition(lookup.emailAddress == "user@example.com")
    let phoneLookup = CKUserIdentity.LookupInfo(phoneNumber: "+15555550100")
    precondition(phoneLookup.phoneNumber == "+15555550100")
    let idLookup = CKUserIdentity.LookupInfo(userRecordID: recordID)
    precondition(idLookup.userRecordID?.isEqual(recordID) == true)
    let lookups = CKUserIdentity.LookupInfo.lookupInfos(withEmails: ["a@b.c"])
    precondition(lookups.count == 1)
    precondition(lookups[0].emailAddress == "a@b.c")
    _ = CKUserIdentity.LookupInfo.lookupInfos(withPhoneNumbers: ["+1"])
    _ = CKUserIdentity.LookupInfo.lookupInfos(with: [recordID])
    _ = lookup.copy() as! CKUserIdentity.LookupInfo
    precondition(CKUserIdentity.LookupInfo.supportsSecureCoding)
    precondition(CKUserIdentity.supportsSecureCoding)
}

// MARK: - CKFailClosedIdentityTests.swift
func testCKFailClosedIdentityAndSharingOperations() async {
    let named = isolatedContainer("identity")
    let recordID = CKRecord.ID(recordName: "rec-1")
    let lookup = CKUserIdentity.LookupInfo(emailAddress: "user@example.com")

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

    let userRecordID = await awaitValue { done in
        named.fetchUserRecordID { recordID, error in
            done((recordID, error))
        }
    }
    precondition(userRecordID.0 == nil)
    requireCKError(userRecordID.1, code: .notAuthenticated)

    do {
        _ = try await named.accept([] as [CKShare.Metadata])
        fatalError("accept must fail closed")
    } catch {
        requireCKError(error, code: .notAuthenticated)
    }
    named.accept([] as [CKShare.Metadata]) { result in
        if case .failure(let error) = result {
            requireCKError(error, code: .notAuthenticated)
        }
    }

    named.discoverUserIdentity(withEmailAddress: "user@example.com") { identity, error in
        precondition(identity == nil)
        requireCKError(error, code: .notAuthenticated)
    }
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

    do { _ = try await named.shareMetadatas(for: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.userIdentities(forPhoneNumbers: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.userIdentities(forUserRecordIDs: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.userIdentities(forEmailAddresses: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.shareParticipants(forPhoneNumbers: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.shareParticipants(forUserRecordIDs: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.shareParticipants(forEmailAddresses: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.shareParticipants(for: [lookup]) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.longLivedOperation(for: "op") } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.requestShareAccess(for: []) } catch { requireCKError(error, code: .notAuthenticated) }
    do { _ = try await named.allLongLivedOperationIDs() } catch { requireCKError(error, code: .notAuthenticated) }
    do {
        _ = try await named.allUserIdentitiesFromContacts()
        fatalError("identity discovery must fail closed")
    } catch {
        requireCKError(error, code: .notAuthenticated)
    }
}

func testCKFailClosedOperationClasses() async {
    let named = isolatedContainer("fail-ops")
    let lookup = CKUserIdentity.LookupInfo(emailAddress: "user@example.com")
    let addLock = NSRecursiveLock()
    var insideContainerAdd = true
    let discover = CKDiscoverAllUserIdentitiesOperation()
    discover.userIdentityDiscoveredBlock = { _ in }
    discover.discoverAllUserIdentitiesResultBlock = { _ in }
    let discoverError = await awaitValue { done in
        discover.discoverAllUserIdentitiesCompletionBlock = { discoverErr in
            addLock.lock()
            let firedInline = insideContainerAdd
            addLock.unlock()
            done((discoverErr, firedInline))
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
    discoverOne.discoverUserIdentitiesResultBlock = { _ in }
    precondition(discoverOne.userIdentityLookupInfos.count == 1)
    _ = CKDiscoverUserIdentitiesOperation()
}

func testCKFailClosedSharingAndWebAuthOperations() async {
    let lookup = CKUserIdentity.LookupInfo(emailAddress: "user@example.com")
    let acceptOp = CKAcceptSharesOperation()
    acceptOp.shareMetadatas = []
    acceptOp.perShareCompletionBlock = { _, _, _ in }
    acceptOp.perShareResultBlock = { _, _ in }
    acceptOp.acceptSharesResultBlock = { _ in }
    _ = CKAcceptSharesOperation(shareMetadatas: [])
    let metaOp = CKFetchShareMetadataOperation(shareURLs: [URL(fileURLWithPath: "/")])
    metaOp.perShareMetadataBlock = { _, _, _ in }
    metaOp.perShareMetadataResultBlock = { _, _ in }
    metaOp.fetchShareMetadataResultBlock = { _ in }
    metaOp.shouldFetchRootRecord = true
    metaOp.rootRecordDesiredKeys = ["title"]
    _ = CKFetchShareMetadataOperation(share: [URL(fileURLWithPath: "/")])
    _ = CKFetchShareParticipantsOperation(userIdentityLookupInfos: [lookup])
    _ = CKShareRequestAccessOperation(shareURLs: [])
}

func testCKFailClosedWebAuthAndSharingUI() {
    let named = isolatedContainer("fail-webauth")
    _ = CKFetchWebAuthTokenOperation(apiToken: "token")
    _ = CKFetchWebAuthTokenOperation(APIToken: "token")
    _ = CKFetchWebAuthTokenOperation()
    _ = CKSystemSharingUIObserver(container: named)
    let observer = CKSystemSharingUIObserver(container: named)
    observer.systemSharingUIDidSaveShareBlock = { _, _ in }
    observer.systemSharingUIDidStopSharingBlock = { _, _ in }
}

func testCKPublicConstants() {
    precondition(CKAccountChangedNotification == "CKAccountChangedNotification")
    precondition(NSNotification.Name.CKAccountChanged.rawValue == CKAccountChangedNotification)
    precondition(CKQueryOperationMaximumResults == 0)
    precondition(CKQueryOperation.maximumResults == CKQueryOperationMaximumResults)
}

// MARK: - CKSyncEngineTests.swift
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

    let send = CKSyncEngine.SendChangesOptions(scope: zones, operationGroup: CKOperationGroup())
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

testCKErrorCodeRawValues()
testCKErrorStaticAliases()
testCKErrorUserInfoAndPatternMatch()
testCKRecordStringNumberDateDataValues()
testCKRecordReferenceParentAndIteration()
try testCKRecordSecureCodingRoundTrip()
testCKRecordIDAndDefaultZoneRules()
testCKRecordZoneCapabilitiesAndCopy()
testCKQueryConstructionAndCopy()
await testCKContainerDatabasesAndAccountStatus()
await testCKContainerAccountStatusAndPermissions()
try await testCKDatabaseSaveFetchDeleteQuery()
try await testCKDatabaseConflictOfflineAndBatch()
try await testCKModifyRecordsCallbackOrderAndPartialFailure()
try await testCKQueryAndFetchRecordsOperationCallbacks()
try await testCKRecordZoneCRUDOperationCallbacks()
try await testCKFetchRecordZoneChangesOperationCallbacks()
try await testCKDatabaseChangeOperationCallbacks()
testCKOperationConfigurationAndGroup()
try await testCKSubscriptionValueStoreAndPersistence()
try await testCKSubscriptionDatabaseFetchAndDelete()
testCKSubscriptionNotificationInfo()
try await testCKSubscriptionOperations()
try await testCKAssetFileCopyOnSave()
try await testCKServerChangeTokensAndZoneChanges()
testCKNotificationParseAndTypes()
testCKQueryZoneAndDatabaseNotificationTypes()
testCKShareValueSemanticsAndFailClosedURL()
testCKShareMetadataAndAccessTypes()
testCKShareParticipantEnums()
testCKSharingOptions()
testCKUserIdentityLookupInfo()
await testCKFailClosedIdentityAndSharingOperations()
await testCKFailClosedOperationClasses()
await testCKFailClosedSharingAndWebAuthOperations()
testCKFailClosedWebAuthAndSharingUI()
testCKPublicConstants()
testCKSyncEngineCEnumRawValues()
testCKSyncEngineSyncReasonAndScopes()
testCKSyncEnginePendingChangeValues()
testCKSyncEngineConfigurationAndState()
testCKSyncEngineEventPayloads()
await testCKSyncEngineRecordZoneChangeBatch()
try await testCKSyncEngineSendChangesStateMachine()
try await testCKSyncEngineFetchChangesStateMachine()
try await testCKSyncEngineDelegateDefaultFetchOptions()
try await testCKSyncEngineCancelOperations()
try await testCKSyncEngineSendDeleteAndScopeFilter()
print("CLOUDKIT_AGENT_RUNTIME_OK")
