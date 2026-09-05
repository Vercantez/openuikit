import CloudKit
import Foundation

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
