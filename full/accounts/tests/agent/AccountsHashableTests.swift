import Accounts
import Foundation

func testACErrorCodeHashValue() {
    let code = ACErrorPermissionDenied
    let value: Int = code.hashValue
    _ = value
    precondition(code.hashValue == ACErrorPermissionDenied.hashValue)
    precondition(ACErrorUnknown.hashValue == ACErrorUnknown.hashValue)
    precondition(ACErrorUnknown.hashValue == ACErrorCode(rawValue: 1).hashValue)
    var hasher = Hasher()
    code.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Set([ACErrorUnknown, ACErrorPermissionDenied]).count == 2)
}

func testAccountCredentialRenewResultHashValue() {
    let result = ACAccountCredentialRenewResult.failed
    let value: Int = result.hashValue
    _ = value
    precondition(result.hashValue == ACAccountCredentialRenewResult.failed.hashValue)
    precondition(ACAccountCredentialRenewResult.renewed.hashValue == ACAccountCredentialRenewResult.renewed.hashValue)
    var hasher = Hasher()
    result.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(
        Set([
            ACAccountCredentialRenewResult.renewed,
            ACAccountCredentialRenewResult.rejected,
            ACAccountCredentialRenewResult.failed,
        ]).count == 3
    )
}
