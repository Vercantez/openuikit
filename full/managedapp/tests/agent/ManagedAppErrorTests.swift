import Foundation
import ManagedApp

func testManagedAppErrorEnum() {
    let error: ManagedAppError = .invalidIdentifier
    managedAppExpect(error is any Error)
    managedAppExpectEqual(String(describing: type(of: error)), "ManagedAppError")
}

func testManagedAppErrorCases() {
    let cases: [ManagedAppError] = [.invalidIdentifier, .serverError, .internalError]
    managedAppExpectEqual(cases.count, 3)
    managedAppExpectEqual(cases[0], .invalidIdentifier)
    managedAppExpectEqual(cases[1], .serverError)
    managedAppExpectEqual(cases[2], .internalError)
}

func testManagedAppErrorEquality() {
    managedAppExpect(.invalidIdentifier == .invalidIdentifier)
    managedAppExpectFalse(.invalidIdentifier == .serverError)
    managedAppExpectFalse(.serverError == .internalError)
}

func testManagedAppErrorInequality() {
    managedAppExpect(.invalidIdentifier != .serverError)
    managedAppExpect(.serverError != .internalError)
    managedAppExpectFalse(.internalError != .internalError)
}

func testManagedAppErrorHashInto() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    ManagedAppError.invalidIdentifier.hash(into: &hasherA)
    ManagedAppError.invalidIdentifier.hash(into: &hasherB)
    managedAppExpectEqual(hasherA.finalize(), hasherB.finalize())
    let set: Set<ManagedAppError> = [.invalidIdentifier, .serverError, .internalError]
    managedAppExpectEqual(set.count, 3)
}

func testManagedAppErrorHashValue() {
    managedAppExpectEqual(
        ManagedAppError.invalidIdentifier.hashValue,
        ManagedAppError.invalidIdentifier.hashValue
    )
    managedAppExpect(
        ManagedAppError.invalidIdentifier.hashValue != ManagedAppError.serverError.hashValue
            || ManagedAppError.invalidIdentifier != .serverError
    )
}

func testManagedAppErrorErrorDescription() {
    managedAppExpectEqual(
        ManagedAppError.invalidIdentifier.errorDescription,
        "An error that indicates a failure finding an identifier."
    )
    managedAppExpectEqual(
        ManagedAppError.serverError.errorDescription,
        "An error that indicates a failure requesting a secret from the asset server."
    )
    managedAppExpectEqual(
        ManagedAppError.internalError.errorDescription,
        "An error that indicates a failure at the system level."
    )
}

func testManagedAppErrorFailureReason() {
    managedAppExpect(ManagedAppError.invalidIdentifier.failureReason == nil)
    managedAppExpect(ManagedAppError.serverError.failureReason == nil)
    managedAppExpect(ManagedAppError.internalError.failureReason == nil)
}

func testManagedAppErrorRecoverySuggestion() {
    managedAppExpect(ManagedAppError.invalidIdentifier.recoverySuggestion == nil)
    managedAppExpect(ManagedAppError.serverError.recoverySuggestion == nil)
    managedAppExpect(ManagedAppError.internalError.recoverySuggestion == nil)
}

func testManagedAppErrorHelpAnchor() {
    managedAppExpect(ManagedAppError.invalidIdentifier.helpAnchor == nil)
    managedAppExpect(ManagedAppError.serverError.helpAnchor == nil)
    managedAppExpect(ManagedAppError.internalError.helpAnchor == nil)
}

func testManagedAppErrorLocalizedDescription() {
    managedAppExpectEqual(
        ManagedAppError.invalidIdentifier.localizedDescription,
        ManagedAppError.invalidIdentifier.errorDescription!
    )
    managedAppExpectEqual(
        ManagedAppError.serverError.localizedDescription,
        ManagedAppError.serverError.errorDescription!
    )
    managedAppExpectEqual(
        ManagedAppError.internalError.localizedDescription,
        ManagedAppError.internalError.errorDescription!
    )
}

private func managedAppExpectFalse(_ condition: Bool, _ message: String = "") {
    managedAppExpect(!condition, message)
}
