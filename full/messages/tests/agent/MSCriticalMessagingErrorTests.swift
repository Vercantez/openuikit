import Foundation
import Messages

func testCriticalMessagingErrorRawValues() {
    precondition(MSCriticalMessagingError.unknown.rawValue == 0)
    precondition(MSCriticalMessagingError.invalidAuthenticationRequest.rawValue == 1)
    precondition(MSCriticalMessagingError.notSupported.rawValue == 2)
    precondition(MSCriticalMessagingError.notAuthorized.rawValue == 3)
    precondition(MSCriticalMessagingError.sendFailed.rawValue == 4)
    precondition(MSCriticalMessagingError(rawValue: 0) == .unknown)
    precondition(MSCriticalMessagingError(rawValue: 1) == .invalidAuthenticationRequest)
    precondition(MSCriticalMessagingError(rawValue: 2) == .notSupported)
    precondition(MSCriticalMessagingError(rawValue: 3) == .notAuthorized)
    precondition(MSCriticalMessagingError(rawValue: 4) == .sendFailed)
    precondition(MSCriticalMessagingError(rawValue: 5) == nil)
    precondition(MSCriticalMessagingError.unknown != .sendFailed)
    precondition(
        MSCriticalMessagingError.notSupported.hashValue
            == MSCriticalMessagingError.notSupported.hashValue
    )
    var hasher = Hasher()
    MSCriticalMessagingError.notAuthorized.hash(into: &hasher)
    _ = hasher.finalize()
    let _: MSCriticalMessagingError.RawValue = MSCriticalMessagingError.unknown.rawValue
}

func testCriticalMessagingErrorDomainAndCode() {
    precondition(MSCriticalMessagingError.errorDomain == "MSCriticalMessagingError")
    precondition(MSCriticalMessagingError.notSupported.errorCode == 2)
    precondition(MSCriticalMessagingError.sendFailed.errorCode == 4)
    let ns = MSCriticalMessagingError.notSupported as NSError
    precondition(ns.domain == MSCriticalMessagingError.errorDomain)
    precondition(ns.code == MSCriticalMessagingError.notSupported.rawValue)
}

func testCriticalMessagingErrorDescription() {
    precondition(MSCriticalMessagingError.unknown.errorDescription != nil)
    precondition(MSCriticalMessagingError.invalidAuthenticationRequest.errorDescription != nil)
    precondition(MSCriticalMessagingError.notSupported.errorDescription != nil)
    precondition(MSCriticalMessagingError.notAuthorized.errorDescription != nil)
    precondition(MSCriticalMessagingError.sendFailed.errorDescription != nil)
    precondition(MSCriticalMessagingError.notSupported.errorDescription != MSCriticalMessagingError.sendFailed.errorDescription)
}

func testCriticalMessagingErrorUserInfo() {
    let error = MSCriticalMessagingError.notSupported as NSError
    precondition(!error.userInfo.isEmpty || error.localizedDescription.count > 0)
    let custom = MSCriticalMessagingError.notSupported
    _ = custom.errorUserInfo
}

func testCriticalMessagingLocalizedDescription() {
    let error: any Error = MSCriticalMessagingError.notSupported
    precondition(!error.localizedDescription.isEmpty)
}

func testCriticalMessagingLocalizedErrorDefaults() {
    let error = MSCriticalMessagingError.unknown
    let localized: any LocalizedError = error
    precondition(localized.failureReason == nil)
    precondition(localized.recoverySuggestion == nil)
    precondition(localized.helpAnchor == nil)
}

func testAuthorizationStatusRawValues() {
    precondition(MSCriticalMessagingAuthorizationStatus.unknown.rawValue == 0)
    precondition(MSCriticalMessagingAuthorizationStatus.denied.rawValue == 1)
    precondition(MSCriticalMessagingAuthorizationStatus.approved.rawValue == 2)
    precondition(MSCriticalMessagingAuthorizationStatus(rawValue: 0) == .unknown)
    precondition(MSCriticalMessagingAuthorizationStatus(rawValue: 1) == .denied)
    precondition(MSCriticalMessagingAuthorizationStatus(rawValue: 2) == .approved)
    precondition(MSCriticalMessagingAuthorizationStatus(rawValue: 3) == nil)
    precondition(MSCriticalMessagingAuthorizationStatus.denied != .approved)
    precondition(
        MSCriticalMessagingAuthorizationStatus.unknown.hashValue
            == MSCriticalMessagingAuthorizationStatus.unknown.hashValue
    )
    var hasher = Hasher()
    MSCriticalMessagingAuthorizationStatus.approved.hash(into: &hasher)
    _ = hasher.finalize()
    let _: MSCriticalMessagingAuthorizationStatus.RawValue =
        MSCriticalMessagingAuthorizationStatus.denied.rawValue
}
