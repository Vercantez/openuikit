// guestcloudkitprobe -- CloudKit with no iCloud account: the Apple side
// (run.sh: iOS 26.1 simulator, a CloudKit-entitled process on a device with
// no account signed in) and the guest side
// (Tools/guestprobes/GuestCloudKitProbe.probe.sh) of the same program.
import CloudKit
import Foundation

func say(_ items: Any...) { print(items.map { "\($0)" }.joined(separator: " ")) }

func describe(_ error: (any Error)?) -> String {
    guard let error else { return "nil" }
    let ns = error as NSError
    return "\(ns.domain) \(ns.code)"
}

@main
struct GuestCloudKitProbe {
    static func main() {
        print("guestcloudkitprobe v1")
        let container = CKContainer(identifier: "iCloud.org.openuikit.guestprobe")
        say("cloudkit.identifier", container.containerIdentifier ?? "nil")

        let status = DispatchSemaphore(value: 0)
        container.accountStatus { accountStatus, error in
            say("cloudkit.accountStatus", accountStatus.rawValue, describe(error))
            status.signal()
        }
        status.wait()

        let database = container.privateCloudDatabase
        say("cloudkit.database.scope", database.databaseScope.rawValue)
        let record = CKRecord(recordType: "Probe", recordID: CKRecord.ID(recordName: "probe-1"))
        record["value"] = "x" as NSString
        say("cloudkit.record", record.recordType, record.recordID.recordName,
            record["value"] as? String ?? "nil", record.recordID.zoneID.zoneName)

        let saved = DispatchSemaphore(value: 0)
        database.save(record) { _, error in
            say("cloudkit.save", describe(error))
            saved.signal()
        }
        saved.wait()

        let fetched = DispatchSemaphore(value: 0)
        database.fetch(withRecordID: CKRecord.ID(recordName: "missing")) { _, error in
            say("cloudkit.fetch", describe(error))
            fetched.signal()
        }
        fetched.wait()

        let userID = DispatchSemaphore(value: 0)
        container.fetchUserRecordID { id, error in
            say("cloudkit.userRecordID", id == nil ? "nil" : "value", describe(error))
            userID.signal()
        }
        userID.wait()

        let modify = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        let modified = DispatchSemaphore(value: 0)
        modify.modifyRecordsResultBlock = { result in
            switch result {
            case .success: say("cloudkit.modify", "success")
            case .failure(let error): say("cloudkit.modify", describe(error))
            }
            modified.signal()
        }
        database.add(modify)
        modified.wait()
        print("guestcloudkitprobe done")
    }
}
