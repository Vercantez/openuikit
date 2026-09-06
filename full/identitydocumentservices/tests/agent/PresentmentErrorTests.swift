import Foundation
import IdentityDocumentServices

func testPresentmentErrorCodeRawValues() {
    let expected: [(IdentityDocumentPresentmentError.Code, Int)] = [
        (.unknown, 0),
        (.invalidRequest, 1),
        (.requestInProgress, 2),
        (.cancelled, 3),
        (.notEntitled, 4),
    ]
    for (code, raw) in expected {
        precondition(code.rawValue == raw)
        precondition(IdentityDocumentPresentmentError.Code(rawValue: raw) == code)
    }
    precondition(IdentityDocumentPresentmentError.Code(rawValue: -1) == nil)
    precondition(IdentityDocumentPresentmentError.Code(rawValue: 5) == nil)
    precondition(IdentityDocumentPresentmentError.Code.RawValue.self == Int.self)
}

func testPresentmentErrorStaticCodeAliases() {
    precondition(IdentityDocumentPresentmentError.unknown == .unknown)
    precondition(IdentityDocumentPresentmentError.invalidRequest == .invalidRequest)
    precondition(IdentityDocumentPresentmentError.requestInProgress == .requestInProgress)
    precondition(IdentityDocumentPresentmentError.cancelled == .cancelled)
    precondition(IdentityDocumentPresentmentError.notEntitled == .notEntitled)
}

func testPresentmentErrorStoredFields() {
    let error = IdentityDocumentPresentmentError(
        code: .cancelled,
        debugDescription: "linux-cancelled"
    )
    precondition(error.code == .cancelled)
    precondition(error.debugDescription == "linux-cancelled")
}

func testPresentmentErrorPatternMatch() {
    let error: any Error = IdentityDocumentPresentmentError(code: .invalidRequest)
    precondition(IdentityDocumentPresentmentError.Code.invalidRequest ~= error)
    precondition(!(IdentityDocumentPresentmentError.Code.notEntitled ~= error))
    precondition(!(IdentityDocumentPresentmentError.Code.unknown ~= NSError(domain: "x", code: 1)))
}

func testPresentmentErrorCodeInequality() {
    precondition(IdentityDocumentPresentmentError.Code.unknown != .notEntitled)
    precondition(!(IdentityDocumentPresentmentError.Code.cancelled != .cancelled))
}

func testPresentmentErrorCodeHash() {
    var hasher = Hasher()
    IdentityDocumentPresentmentError.Code.notEntitled.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(IdentityDocumentPresentmentError.Code.unknown.hashValue == IdentityDocumentPresentmentError.Code.unknown.hashValue)
}

func testPresentmentErrorLocalizedDescription() {
    let error = IdentityDocumentPresentmentError(code: .notEntitled)
    precondition(error.errorDescription == "The caller is not entitled.")
    precondition(error.localizedDescription.contains("entitled") || error.localizedDescription == error.errorDescription)
}

func testPresentmentErrorFailureReasonDefault() {
    let error = IdentityDocumentPresentmentError(code: .unknown)
    precondition(error.failureReason == nil)
}

func testPresentmentErrorRecoverySuggestionDefault() {
    let error = IdentityDocumentPresentmentError(code: .unknown)
    precondition(error.recoverySuggestion == nil)
}

func testPresentmentErrorHelpAnchorDefault() {
    let error = IdentityDocumentPresentmentError(code: .unknown)
    precondition(error.helpAnchor == nil)
}
