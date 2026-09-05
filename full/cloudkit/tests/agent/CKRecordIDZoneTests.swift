import CloudKit
import Foundation

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
