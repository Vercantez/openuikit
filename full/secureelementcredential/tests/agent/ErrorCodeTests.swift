import Foundation
import SecureElementCredential

func testErrorCodeCases() {
    let cases: [CredentialSession.ErrorCode] = [
        .userNotAuthorized,
        .accessDenied,
        .clientNotInForeground,
        .invalidSessionState,
        .invalidCredentialState,
        .credentialDoesNotExist,
        .instanceDoesNotExist,
        .sessionInvalidated,
        .userCanceledAuthorization,
        .userAuthorizationTimedOut,
        .commandNotSupported,
        .network,
        .resourceUnavailable,
        .insufficientSpace,
        .presentmentIntentAssertionTimeout,
        .featureUnavailable,
        .ineligible,
        .invalidView,
        .acquiredResourceRelinquished,
        .conditionsNotSatisfied,
        .invalidInput,
        .internalError,
    ]
    precondition(cases.count == 22)
    precondition(Set(cases).count == 22)
    precondition(CredentialSession.ErrorCode.featureUnavailable != .ineligible)
    precondition(CredentialSession.ErrorCode.invalidSessionState != .invalidCredentialState)
    precondition(CredentialSession.ErrorCode.accessDenied != .userNotAuthorized)
}

func testErrorCodeEquality() {
    let a = CredentialSession.ErrorCode.featureUnavailable
    let b = CredentialSession.ErrorCode.featureUnavailable
    let c = CredentialSession.ErrorCode.network
    precondition(a == b)
    precondition(a != c)
    precondition(!(a != b))
}

func testErrorCodeHash() {
    let a = CredentialSession.ErrorCode.invalidInput
    let b = CredentialSession.ErrorCode.invalidInput
    let c = CredentialSession.ErrorCode.internalError
    var h1 = Hasher()
    var h2 = Hasher()
    a.hash(into: &h1)
    b.hash(into: &h2)
    precondition(h1.finalize() == h2.finalize())
    precondition(a.hashValue == b.hashValue)
    precondition(a.hashValue != c.hashValue)
}

func testErrorCodeFailureReason() {
    let unavailable = CredentialSession.ErrorCode.featureUnavailable
    precondition(unavailable.failureReason == "Secure Element Credential is unavailable on this host.")
    precondition(CredentialSession.ErrorCode.ineligible.failureReason != nil)
    precondition(CredentialSession.ErrorCode.accessDenied.failureReason != unavailable.failureReason)
    precondition(CredentialSession.ErrorCode.sessionInvalidated.failureReason?.contains("invalidated") == true)
}

func testErrorCodeErrorDescription() {
    let code = CredentialSession.ErrorCode.commandNotSupported
    precondition(code.errorDescription == code.failureReason)
    precondition(code.errorDescription?.isEmpty == false)
}

func testErrorCodeHelpAnchor() {
    precondition(CredentialSession.ErrorCode.featureUnavailable.helpAnchor == nil)
    precondition(CredentialSession.ErrorCode.network.helpAnchor == nil)
}

func testErrorCodeRecoverySuggestion() {
    precondition(CredentialSession.ErrorCode.invalidInput.recoverySuggestion == nil)
    precondition(CredentialSession.ErrorCode.internalError.recoverySuggestion == nil)
}

func testErrorCodeLocalizedDescription() {
    let error: any Error = CredentialSession.ErrorCode.featureUnavailable
    precondition(!error.localizedDescription.isEmpty)
    precondition(!CredentialSession.ErrorCode.userNotAuthorized.localizedDescription.isEmpty)
}

func testErrorCodeInequality() {
    precondition(CredentialSession.ErrorCode.resourceUnavailable != .insufficientSpace)
    precondition(!(CredentialSession.ErrorCode.network != .network))
}
