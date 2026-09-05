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

func isolatedContainer(_ suffix: String = UUID().uuidString) -> CKContainer {
    CKContainer(identifier: "iCloud.openuikit." + suffix)
}

func awaitValue<T>(_ body: (@escaping (T) -> Void) -> Void) async -> T {
    await withCheckedContinuation { continuation in
        body { value in continuation.resume(returning: value) }
    }
}
