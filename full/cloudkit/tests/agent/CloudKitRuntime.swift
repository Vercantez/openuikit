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

let error = CKError(.notAuthenticated)
precondition(error.code == .notAuthenticated)
precondition(CKError.notAuthenticated == CKError.Code.notAuthenticated)
precondition(error.retryAfterSeconds == nil)
precondition(error.clientRecord == nil)
let retry = CKError(.zoneBusy, userInfo: [CKErrorRetryAfterKey: 1.5])
precondition(retry.retryAfterSeconds == 1.5)

let zoneID = CKRecordZone.ID(zoneName: "Articles", ownerName: CKCurrentUserDefaultName)
precondition(zoneID.zoneName == "Articles")
precondition(zoneID.ownerName == CKCurrentUserDefaultName)
precondition(CKRecordZone.ID.default.isEqual(CKRecordZone.default().zoneID))

let zone = CKRecordZone(zoneName: "Articles")
precondition(zone.zoneID.zoneName == "Articles")
precondition(zone.encryptionScope == .perRecord)

var capabilities: CKRecordZone.Capabilities = [.atomic, .fetchChanges]
precondition(capabilities.contains(.atomic))
precondition(capabilities.contains(.fetchChanges))
capabilities.insert(.sharing)
precondition(capabilities.contains(.sharing))

let recordID = CKRecord.ID(recordName: "rec-1", zoneID: zoneID)
precondition(recordID.recordName == "rec-1")
precondition(recordID.zoneID.isEqual(zoneID))
let sameID = CKRecord.ID(recordName: "rec-1", zoneID: zoneID)
precondition(recordID.isEqual(sameID))

let record = CKRecord(recordType: "Article", recordID: recordID)
precondition(record.recordType == "Article")
precondition(record.recordID.isEqual(recordID))
record["title"] = "Hello"
record["count"] = 3
let blob = Data([0x0A, 0x0B])
let stamp = Date(timeIntervalSince1970: 1_700_000_000)
record["blob"] = blob
record["stamp"] = stamp
precondition((record["title"] as? String) == "Hello")
precondition(record.object(forKey: "count") as? Int == 3)
precondition((record["blob"] as? Data) == blob)
precondition((record["stamp"] as? Date) == stamp)
precondition(Set(record.allKeys()) == Set(["title", "count", "blob", "stamp"]))
precondition(Set(record.changedKeys()) == Set(["title", "count", "blob", "stamp"]))
record.setObject(nil, forKey: "count")
precondition(record["count"] == nil)

let parent = CKRecord(recordType: "Folder", zoneID: zoneID)
record.setParent(parent)
precondition(record.parent?.recordID.isEqual(parent.recordID) == true)
record.setParent(nil as CKRecord.ID?)
precondition(record.parent == nil)

let reference = CKRecord.Reference(record: record, action: .deleteSelf)
precondition(reference.action == .deleteSelf)
precondition(reference.recordID.isEqual(record.recordID))
let noneRef = CKRecord.Reference(recordID: recordID, action: .none)
precondition(noneRef.action == .none)

let asset = CKAsset(fileURL: URL(fileURLWithPath: "/tmp/cloudkit-asset.bin"))
precondition(asset.fileURL?.path == "/tmp/cloudkit-asset.bin")
record["file"] = asset
precondition((record["file"] as? CKAsset)?.fileURL == asset.fileURL)

var iterator = record.makeIterator()
var iterated = Set<String>()
while let (key, _) = iterator.next() {
    iterated.insert(key)
}
precondition(iterated.contains("title"))
precondition(iterated.contains("file"))
precondition(iterated.contains("blob"))
precondition(iterated.contains("stamp"))

let archiver = NSKeyedArchiver(requiringSecureCoding: true)
record.encodeSystemFields(with: archiver)
let unarchiver = try NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
precondition(CKRecord(coder: unarchiver) == nil)

let queryPredicate = NSPredicate(value: true)
let query = CKQuery(recordType: "Article", predicate: queryPredicate)
precondition(query.recordType == "Article")
precondition(query.predicate == queryPredicate)

let container = CKContainer.default()
precondition(container === CKContainer.default())
precondition(container.containerIdentifier == nil)
let named = CKContainer(identifier: "iCloud.com.example.news")
precondition(named.containerIdentifier == "iCloud.com.example.news")
precondition(named.privateCloudDatabase.databaseScope == .private)
precondition(named.publicCloudDatabase.databaseScope == .public)
precondition(named.sharedCloudDatabase.databaseScope == .shared)
precondition(named.database(with: .private) === named.privateCloudDatabase)

let status = await withCheckedContinuation { continuation in
    named.accountStatus { accountStatus, accountError in
        continuation.resume(returning: (accountStatus, accountError))
    }
}
precondition(status.0 == .couldNotDetermine)
requireCKError(status.1, code: .notAuthenticated)

let fetched = await withCheckedContinuation { continuation in
    named.privateCloudDatabase.fetch(withRecordID: recordID) { saved, fetchError in
        continuation.resume(returning: (saved, fetchError))
    }
}
precondition(fetched.0 == nil)
requireCKError(fetched.1, code: .notAuthenticated)

do {
    _ = try await named.privateCloudDatabase.save(record)
    fatalError("save must fail closed")
} catch {
    requireCKError(error, code: .notAuthenticated)
}

do {
    _ = try await named.allUserIdentitiesFromContacts()
    fatalError("identity discovery must fail closed")
} catch {
    requireCKError(error, code: .notAuthenticated)
}

let addLock = NSRecursiveLock()
var insideDatabaseAdd = true
let modify = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: [recordID])
let modifyResult = await withCheckedContinuation { continuation in
    modify.modifyRecordsCompletionBlock = { saved, deleted, modifyError in
        addLock.lock()
        let firedInline = insideDatabaseAdd
        addLock.unlock()
        continuation.resume(returning: (saved, deleted, modifyError, firedInline))
    }
    addLock.lock()
    named.privateCloudDatabase.add(modify)
    insideDatabaseAdd = false
    addLock.unlock()
}
precondition(modifyResult.0 == nil)
precondition(modifyResult.1 == nil)
precondition(modifyResult.3 == false, "CKDatabase.add must not invoke fail-closed completions inline")
requireCKError(modifyResult.2, code: .notAuthenticated)

var insideContainerAdd = true
let discover = CKDiscoverAllUserIdentitiesOperation()
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
precondition(discoverError.1 == false, "CKContainer.add must not invoke fail-closed completions inline")
requireCKError(discoverError.0, code: .notAuthenticated)

let lookup = CKUserIdentity.LookupInfo(emailAddress: "user@example.com")
precondition(lookup.emailAddress == "user@example.com")
let lookups = CKUserIdentity.LookupInfo.lookupInfos(withEmails: ["a@b.c"])
precondition(lookups.count == 1)
precondition(lookups[0].emailAddress == "a@b.c")

let subscription = CKQuerySubscription(
    recordType: "Article",
    predicate: NSPredicate(value: true),
    options: [.firesOnRecordCreation, .firesOnRecordUpdate]
)
precondition(subscription.subscriptionType == .query)
precondition(subscription.querySubscriptionOptions.contains(.firesOnRecordCreation))
precondition(subscription.querySubscriptionOptions.contains(.firesOnRecordUpdate))

let share = CKShare(rootRecord: record)
precondition(share.recordType == CKRecordTypeShare)
precondition(share.url == nil)
precondition(share.owner.role == .unknown)
precondition(share.owner.permission == .none)
precondition(share.owner.acceptanceStatus == .unknown)
precondition(share.owner.userIdentity.hasiCloudAccount == false)
precondition(share.oneTimeURL(for: share.owner.participantID) == nil)

let info = CKSubscription.NotificationInfo(alertBody: "changed", shouldBadge: true)
precondition(info.alertBody == "changed")
precondition(info.shouldBadge)

let parsed = CKNotification(fromRemoteNotificationDictionary: ["ck": "value"])
precondition(parsed == nil)

let group = CKOperationGroup()
precondition(!group.operationGroupID.isEmpty)
precondition(group.expectedSendSize == .unknown)
group.expectedSendSize = .kilobytes
precondition(group.expectedSendSize == .kilobytes)

print("CLOUDKIT_AGENT_RUNTIME_OK")
