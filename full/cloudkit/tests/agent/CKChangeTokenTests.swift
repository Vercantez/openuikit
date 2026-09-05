import CloudKit
import Foundation

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
