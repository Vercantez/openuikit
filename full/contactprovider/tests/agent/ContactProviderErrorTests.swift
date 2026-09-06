import Foundation
import ContactProvider

func testContactProviderErrorType() {
    let error: ContactProviderError = .featureNotAvailable
    precondition(type(of: error) == ContactProviderError.self)
}

func testContactProviderErrorCases() {
    let cases: [ContactProviderError] = [
        .extensionNotFound,
        .itemsLimitReached,
        .cannotEnumerate,
        .pageExpired,
        .changeAnchorExpired,
        .featureNotAvailable,
        .deniedByUser,
        .enumerationTimeout,
        .extensionInvalidated,
        .extensionInvalidateTimeout,
        .domainNotRegistered,
    ]
    precondition(cases.count == 11)
    for index in cases.indices {
        precondition(cases[index] == cases[index])
        for other in cases.indices where other != index {
            precondition(cases[index] != cases[other])
        }
    }
}

func testContactProviderErrorCodes() {
    precondition(ContactProviderError.extensionNotFound.errorCode == 0)
    precondition(ContactProviderError.itemsLimitReached.errorCode == 1)
    precondition(ContactProviderError.cannotEnumerate.errorCode == 2)
    precondition(ContactProviderError.pageExpired.errorCode == 3)
    precondition(ContactProviderError.changeAnchorExpired.errorCode == 4)
    precondition(ContactProviderError.featureNotAvailable.errorCode == 5)
    precondition(ContactProviderError.deniedByUser.errorCode == 6)
    precondition(ContactProviderError.enumerationTimeout.errorCode == 7)
    precondition(ContactProviderError.extensionInvalidated.errorCode == 8)
    precondition(ContactProviderError.extensionInvalidateTimeout.errorCode == 9)
    precondition(ContactProviderError.domainNotRegistered.errorCode == 10)
}

func testContactProviderErrorDomain() {
    precondition(ContactProviderError.errorDomain == "ContactProvider.ContactProviderError")
    let nsError = ContactProviderError.featureNotAvailable as NSError
    precondition(nsError.domain == ContactProviderError.errorDomain)
    precondition(nsError.code == 5)
}

func testContactProviderErrorUserInfo() {
    let info = ContactProviderError.deniedByUser.errorUserInfo
    let description = info[NSLocalizedDescriptionKey] as? String
    precondition(description == ContactProviderError.deniedByUser.errorDescription)
    let reason = info[NSLocalizedFailureReasonErrorKey] as? String
    precondition(reason == ContactProviderError.deniedByUser.failureReason)
}

func testContactProviderErrorDescription() {
    precondition(
        ContactProviderError.extensionNotFound.errorDescription
            == "The framework couldn't discover the app's extension."
    )
    precondition(
        ContactProviderError.itemsLimitReached.errorDescription
            == "Limit of items has been reached."
    )
    precondition(
        ContactProviderError.cannotEnumerate.errorDescription
            == "The extension is unable to enumerate."
    )
    precondition(
        ContactProviderError.pageExpired.errorDescription
            == "The page expired and is no longer valid."
    )
    precondition(
        ContactProviderError.changeAnchorExpired.errorDescription
            == "The change anchor expired and is no longer valid."
    )
    precondition(
        ContactProviderError.featureNotAvailable.errorDescription
            == "The extension can't run because the feature isn't available."
    )
    precondition(
        ContactProviderError.deniedByUser.errorDescription
            == "The person using the app denied the action."
    )
    precondition(
        ContactProviderError.enumerationTimeout.errorDescription
            == "The extension enumeration timed out."
    )
    precondition(
        ContactProviderError.extensionInvalidated.errorDescription
            == "The app invalidated the extension while it was enumerating content or changes."
    )
    precondition(
        ContactProviderError.extensionInvalidateTimeout.errorDescription
            == "The extension invalidate operation timed out."
    )
    precondition(
        ContactProviderError.domainNotRegistered.errorDescription
            == "The domain has not been registered."
    )
}

func testContactProviderFailureReason() {
    let error = ContactProviderError.pageExpired
    precondition(error.failureReason == error.errorDescription)
    precondition(error.failureReason != nil)
}

func testContactProviderHelpAnchor() {
    let error = ContactProviderError.cannotEnumerate
    precondition(error.helpAnchor == nil)
}

func testContactProviderRecoverySuggestion() {
    let error = ContactProviderError.enumerationTimeout
    precondition(error.recoverySuggestion == nil)
}

func testContactProviderLocalizedDescription() {
    let error = ContactProviderError.featureNotAvailable
    precondition(error.localizedDescription == error.errorDescription)
    precondition(!error.localizedDescription.isEmpty)
}

func testContactProviderErrorHashable() {
    let error = ContactProviderError.extensionNotFound
    precondition(error.hashValue == ContactProviderError.extensionNotFound.hashValue)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    var set = Set<ContactProviderError>()
    set.insert(.pageExpired)
    set.insert(.pageExpired)
    set.insert(.changeAnchorExpired)
    precondition(set.count == 2)
}

func testContactProviderErrorInequality() {
    precondition(ContactProviderError.extensionNotFound != .itemsLimitReached)
    precondition(!(ContactProviderError.deniedByUser != .deniedByUser))
}
