import Foundation
@_spi(OpenUIKitHost) import FileProviderUI

func testErrorCodeType() {
    let values: [FPUIExtensionErrorCode] = [.userCancelled, .failed]
    precondition(values.count == 2)
    precondition(type(of: FPUIExtensionErrorCode.userCancelled) == FPUIExtensionErrorCode.self)
}

func testErrorCodeCases() {
    let table: [(FPUIExtensionErrorCode, UInt)] = [
        (.userCancelled, 0),
        (.failed, 1),
    ]
    precondition(Set(table.map(\.0)).count == 2)
    precondition(Set(table.map(\.1)).count == 2)
    for (value, raw) in table {
        precondition(value.rawValue == raw)
        precondition(FPUIExtensionErrorCode(rawValue: raw) == value)
    }
}

func testErrorCodeInitRawValue() {
    precondition(FPUIExtensionErrorCode(rawValue: 0) == .userCancelled)
    precondition(FPUIExtensionErrorCode(rawValue: 1) == .failed)
    precondition(FPUIExtensionErrorCode(rawValue: 2) == nil)
    precondition(FPUIExtensionErrorCode(rawValue: UInt.max) == nil)
}

func testErrorCodeInequality() {
    precondition(FPUIExtensionErrorCode.userCancelled != .failed)
    precondition(FPUIExtensionErrorCode.failed != .userCancelled)
    precondition(!(FPUIExtensionErrorCode.failed != .failed))
    precondition(!(FPUIExtensionErrorCode.userCancelled != .userCancelled))
    precondition(FPUIExtensionErrorCode.failed == .failed)
}

func testErrorCodeHashValue() {
    precondition(
        FPUIExtensionErrorCode.userCancelled.hashValue
            == FPUIExtensionErrorCode.userCancelled.hashValue
    )
    precondition(
        FPUIExtensionErrorCode.failed.hashValue
            == FPUIExtensionErrorCode.failed.hashValue
    )
    precondition(
        FPUIExtensionErrorCode.userCancelled.hashValue
            != FPUIExtensionErrorCode.failed.hashValue
    )
    _ = FPUIExtensionErrorCode.failed.hashValue
}

func testErrorCodeHashInto() {
    var hasherA = Hasher()
    FPUIExtensionErrorCode.failed.hash(into: &hasherA)
    var hasherB = Hasher()
    FPUIExtensionErrorCode.failed.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())

    var hasherCancelled = Hasher()
    FPUIExtensionErrorCode.userCancelled.hash(into: &hasherCancelled)
    var hasherFailed = Hasher()
    FPUIExtensionErrorCode.failed.hash(into: &hasherFailed)
    precondition(hasherCancelled.finalize() != hasherFailed.finalize())
}

func testErrorDomain() {
    precondition(FPUIErrorDomain == "FPUIErrorDomain")
    precondition(FPUIExtensionErrorCode.errorDomain == FPUIErrorDomain)
    let nsError = FPUIExtensionErrorCode.failed as NSError
    precondition(nsError.domain == FPUIErrorDomain)
    precondition(nsError.code == 1)
    let cancelled = FPUIExtensionErrorCode.userCancelled as NSError
    precondition(cancelled.domain == FPUIErrorDomain)
    precondition(cancelled.code == 0)
}
