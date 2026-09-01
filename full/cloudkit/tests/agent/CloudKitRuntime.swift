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

precondition(CKErrorDomain == "CKErrorDomain")
precondition(CKCurrentUserDefaultName == CKOwnerDefaultName)
precondition(CKRecordZoneDefaultName == "_defaultZone")
precondition(CKRecordZone.ID.defaultZoneName == CKRecordZoneDefaultName)
precondition(CKRecordTypeUserRecord == "Users")
precondition(CKRecordTypeShare == "cloudkit.share")
precondition(NSNotification.Name.CKAccountChanged.rawValue == "CKAccountChangedNotification")

let error = CKError(.notAuthenticated)
precondition(error.code == .notAuthenticated)
precondition(error.errorCode == 9)
precondition(CKError.notAuthenticated == CKError.Code.notAuthenticated)
precondition(error.retryAfterSeconds == nil)
precondition(error.clientRecord == nil)
let retry = CKError(.zoneBusy, userInfo: [CKErrorRetryAfterKey: 1.5])
precondition(retry.retryAfterSeconds == 1.5)

let zoneID = CKRecordZone.ID(zoneName: "Articles", ownerName: CKCurrentUserDefaultName)
precondition(zoneID.zoneName == "Articles")
precondition(zoneID.ownerName == CKCurrentUserDefaultName)
precondition(CKRecordZone.ID.default.zoneName == CKRecordZoneDefaultName)

let zone = CKRecordZone(zoneName: "Articles")
precondition(zone.zoneID.zoneName == "Articles")
precondition(zone.encryptionScope == .perRecord)
let defaultZone = CKRecordZone.default()
precondition(defaultZone.zoneID.isEqual(CKRecordZone.ID.default))

var capabilities: CKRecordZone.Capabilities = [.atomic, .fetchChanges]
precondition(capabilities.contains(.atomic))
capabilities.insert(.sharing)
precondition(capabilities.contains(.sharing))

let recordID = CKRecord.ID(recordName: "rec-1", zoneID: zoneID)
precondition(recordID.recordName == "rec-1")
let sameID = CKRecord.ID(recordName: "rec-1", zoneID: zoneID)
precondition(recordID.isEqual(sameID))

let record = CKRecord(recordType: "Article", recordID: recordID)
precondition(record.recordType == "Article")
record["title"] = "Hello"
record["count"] = 3
precondition((record["title"] as? String) == "Hello")
precondition(record.object(forKey: "count") as? Int == 3)
precondition(Set(record.allKeys()) == Set(["title", "count"]))
precondition(Set(record.changedKeys()) == Set(["title", "count"]))
precondition(record.allTokens() == ["Hello"])
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

let query = CKQuery(
    recordType: "Article",
    predicate: NSPredicate(value: true)
)
precondition(query.recordType == "Article")

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

let modify = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: [recordID])
let modifyResult = await withCheckedContinuation { continuation in
    modify.modifyRecordsCompletionBlock = { saved, deleted, modifyError in
        continuation.resume(returning: (saved, deleted, modifyError))
    }
    named.privateCloudDatabase.add(modify)
}
precondition(modifyResult.0 == nil)
precondition(modifyResult.1 == nil)
requireCKError(modifyResult.2, code: .notAuthenticated)

let lookup = CKUserIdentity.LookupInfo(emailAddress: "user@example.com")
precondition(lookup.emailAddress == "user@example.com")
let lookups = CKUserIdentity.LookupInfo.lookupInfos(withEmails: ["a@b.c"])
precondition(lookups.count == 1)

let subscription = CKQuerySubscription(
    recordType: "Article",
    predicate: NSPredicate(value: true),
    options: [.firesOnRecordCreation, .firesOnRecordUpdate]
)
precondition(subscription.subscriptionType == .query)
precondition(subscription.querySubscriptionOptions.contains(.firesOnRecordCreation))

let share = CKShare(rootRecord: record)
precondition(share.recordType == CKRecordTypeShare)
precondition(share.owner.role == .owner)
precondition(share.url == nil)
precondition(share.oneTimeURL(for: share.owner.participantID) == nil)

let info = CKSubscription.NotificationInfo(alertBody: "changed", shouldBadge: true)
precondition(info.alertBody == "changed")
precondition(info.shouldBadge)

let parsed = CKNotification(fromRemoteNotificationDictionary: ["ck": "value"])
precondition(parsed == nil)

let group = CKOperationGroup()
precondition(!group.operationGroupID.isEmpty)
group.expectedSendSize = .kilobytes
precondition(group.expectedSendSize == .kilobytes)

print("CLOUDKIT_AGENT_RUNTIME_OK")
