import Foundation
import DeclaredAgeRange

func testErrorType() {
    let error: AgeRangeService.Error = .notAvailable
    precondition(type(of: error) == AgeRangeService.Error.self)
    let asSwiftError: any Swift.Error = error
    _ = asSwiftError
}

func testErrorCases() {
    let table: [AgeRangeService.Error] = [
        .notAvailable,
        .invalidRequest,
    ]
    precondition(Set(table).count == 2)
    switch table[0] {
    case .notAvailable:
        break
    case .invalidRequest:
        preconditionFailure("order mismatch")
    }
    switch table[1] {
    case .invalidRequest:
        break
    case .notAvailable:
        preconditionFailure("order mismatch")
    }
}

func testErrorEquality() {
    precondition(AgeRangeService.Error.notAvailable == .notAvailable)
    precondition(AgeRangeService.Error.invalidRequest == .invalidRequest)
    precondition(!(AgeRangeService.Error.notAvailable == .invalidRequest))
}

func testErrorInequality() {
    precondition(AgeRangeService.Error.notAvailable != .invalidRequest)
    precondition(!(AgeRangeService.Error.notAvailable != .notAvailable))
    precondition(!(AgeRangeService.Error.invalidRequest != .invalidRequest))
}

func testErrorHashInto() {
    var hasher = Hasher()
    AgeRangeService.Error.notAvailable.hash(into: &hasher)
    AgeRangeService.Error.invalidRequest.hash(into: &hasher)
    _ = hasher.finalize()
}

func testErrorHashValue() {
    let unavailable = AgeRangeService.Error.notAvailable.hashValue
    precondition(unavailable == AgeRangeService.Error.notAvailable.hashValue)
    let invalid = AgeRangeService.Error.invalidRequest.hashValue
    precondition(invalid == AgeRangeService.Error.invalidRequest.hashValue)
}

func testErrorHelpAnchor() {
    let error: any LocalizedError = AgeRangeService.Error.notAvailable
    precondition(error.helpAnchor == nil)
    let invalid: any LocalizedError = AgeRangeService.Error.invalidRequest
    precondition(invalid.helpAnchor == nil)
}

func testErrorFailureReason() {
    let error: any LocalizedError = AgeRangeService.Error.notAvailable
    precondition(error.failureReason == nil)
    let invalid: any LocalizedError = AgeRangeService.Error.invalidRequest
    precondition(invalid.failureReason == nil)
}

func testErrorErrorDescription() {
    let error: any LocalizedError = AgeRangeService.Error.notAvailable
    precondition(error.errorDescription == nil)
    let invalid: any LocalizedError = AgeRangeService.Error.invalidRequest
    precondition(invalid.errorDescription == nil)
}

func testErrorRecoverySuggestion() {
    let error: any LocalizedError = AgeRangeService.Error.notAvailable
    precondition(error.recoverySuggestion == nil)
    let invalid: any LocalizedError = AgeRangeService.Error.invalidRequest
    precondition(invalid.recoverySuggestion == nil)
}

func testErrorLocalizedDescription() {
    let unavailable = AgeRangeService.Error.notAvailable.localizedDescription
    precondition(!unavailable.isEmpty)
    let invalid = AgeRangeService.Error.invalidRequest.localizedDescription
    precondition(!invalid.isEmpty)
}
