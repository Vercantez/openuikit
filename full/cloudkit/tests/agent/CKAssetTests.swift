import CloudKit
import Foundation

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
