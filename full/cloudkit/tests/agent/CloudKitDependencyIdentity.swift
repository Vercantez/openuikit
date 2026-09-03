import CloudKit
import Foundation

// Future clean EC2 probe: build guest Foundation, then libCloudKit.dylib with
// that -I/-L, then link this client (import CloudKit + Foundation), run with
// LD_LIBRARY_PATH, and confirm libCloudKit.dylib is loaded.
// Isolated host-gate success is not integrated Linux success.

func requireCKError(_ error: Error?, code: CKError.Code) {
    guard let error = error as? CKError else {
        fatalError("expected typed CKError")
    }
    precondition(error.code == code)
}

let payload = Data([0xC1, 0x0D, 0x4B, 0x17])
let stamp = Date(timeIntervalSince1970: 1_700_000_000)
let fileURL = URL(fileURLWithPath: "/tmp/cloudkit-dependency-identity.bin")
let matchPredicate = NSPredicate(value: true)

let record = CKRecord(recordType: "DependencyIdentity")
record["payload"] = payload
record["stamp"] = stamp
precondition((record["payload"] as? Data) == payload)
precondition((record["stamp"] as? Date) == stamp)

let asset = CKAsset(fileURL: fileURL)
precondition(asset.fileURL == fileURL)
record["asset"] = asset
precondition((record["asset"] as? CKAsset)?.fileURL == fileURL)

let query = CKQuery(recordType: "DependencyIdentity", predicate: matchPredicate)
precondition(query.predicate == matchPredicate)

let sequencedKeys = Set(record.map { pair in pair.0 })
precondition(sequencedKeys.isSuperset(of: ["payload", "stamp", "asset"]))

let archiver = NSKeyedArchiver(requiringSecureCoding: true)
record.encodeSystemFields(with: archiver)
let unarchiver = try NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
precondition(CKRecord(coder: unarchiver) == nil)
precondition(CKRecord.ID(coder: unarchiver) == nil)

let probeQueue = OperationQueue()
probeQueue.name = "CloudKit.DependencyIdentity.Probe"
probeQueue.maxConcurrentOperationCount = 1
precondition(probeQueue.name == "CloudKit.DependencyIdentity.Probe")
precondition(probeQueue.maxConcurrentOperationCount == 1)

let addLock = NSRecursiveLock()
var insideAdd = true
let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: [])
let outcome = await withCheckedContinuation { continuation in
    operation.modifyRecordsCompletionBlock = { saved, deleted, error in
        addLock.lock()
        let firedInline = insideAdd
        addLock.unlock()
        continuation.resume(returning: (saved, deleted, error, firedInline, OperationQueue.current))
    }
    addLock.lock()
    CKContainer.default().privateCloudDatabase.add(operation)
    insideAdd = false
    addLock.unlock()
}
precondition(outcome.0 == nil)
precondition(outcome.1 == nil)
precondition(outcome.3 == false)
requireCKError(outcome.2, code: .notAuthenticated)
precondition(outcome.4 !== OperationQueue.main)

print("CLOUDKIT_AGENT_RUNTIME_OK")
