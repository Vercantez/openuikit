import Foundation
import IdentityDocumentServices

func testMobileDocumentRegistrationStoresFields() {
    let aki = Data([0xDE, 0xAD, 0xBE, 0xEF])
    let date = Date(timeIntervalSince1970: 1_800_000_000)
    var registration = MobileDocumentRegistration(
        mobileDocumentType: "org.iso.18013.5.mDL",
        supportedAuthorityKeyIdentifiers: [aki],
        documentIdentifier: "doc-1",
        invalidationDate: date
    )
    precondition(registration.mobileDocumentType == "org.iso.18013.5.mDL")
    precondition(registration.supportedAuthorityKeyIdentifiers == [aki])
    precondition(registration.documentIdentifier == "doc-1")
    precondition(registration.invalidationDate == date)
    registration.mobileDocumentType = "org.iso.23220.1.photoid"
    precondition(registration.mobileDocumentType == "org.iso.23220.1.photoid")
}

func testMobileDocumentRegistrationDefaultIdentifierAndDate() {
    let first = MobileDocumentRegistration(
        mobileDocumentType: "org.iso.18013.5.mDL",
        supportedAuthorityKeyIdentifiers: []
    )
    let second = MobileDocumentRegistration(
        mobileDocumentType: "org.iso.18013.5.mDL",
        supportedAuthorityKeyIdentifiers: []
    )
    precondition(UUID(uuidString: first.documentIdentifier) != nil)
    precondition(UUID(uuidString: second.documentIdentifier) != nil)
    precondition(first.documentIdentifier != second.documentIdentifier)
    precondition(first.invalidationDate == nil)
}

func testIdentityDocumentRegistrationProtocolWitness() {
    let registration = MobileDocumentRegistration(
        mobileDocumentType: "org.iso.18013.5.mDL",
        supportedAuthorityKeyIdentifiers: [Data([0x01])],
        documentIdentifier: "witness-id"
    )
    let boxed: any IdentityDocumentRegistration = registration
    precondition(boxed.documentIdentifier == "witness-id")
}

func testProviderRegistrationStoreInit() {
    let store = IdentityDocumentProviderRegistrationStore()
    _ = store
}

func testProviderRegistrationStoreUnownedExecutor() {
    let store = IdentityDocumentProviderRegistrationStore()
    _ = store.unownedExecutor
}

func testRegistrationErrorCases() {
    let cases: [IdentityDocumentProviderRegistrationStore.RegistrationError] = [
        .unknown, .invalidRequest, .notAuthorized, .notSupported,
    ]
    precondition(cases.count == 4)
    precondition(IdentityDocumentProviderRegistrationStore.RegistrationError.notSupported == .notSupported)
}

func testRegistrationErrorEquality() {
    precondition(
        IdentityDocumentProviderRegistrationStore.RegistrationError.notAuthorized
            == .notAuthorized
    )
}

func testRegistrationErrorInequality() {
    precondition(
        IdentityDocumentProviderRegistrationStore.RegistrationError.unknown
            != .notSupported
    )
}

func testRegistrationErrorHash() {
    var hasher = Hasher()
    IdentityDocumentProviderRegistrationStore.RegistrationError.invalidRequest.hash(into: &hasher)
    _ = hasher.finalize()
    let value = IdentityDocumentProviderRegistrationStore.RegistrationError.unknown.hashValue
    precondition(value == IdentityDocumentProviderRegistrationStore.RegistrationError.unknown.hashValue)
}

func testRegistrationErrorLocalizedDescription() {
    let error = IdentityDocumentProviderRegistrationStore.RegistrationError.notSupported
    precondition(error.errorDescription?.contains("not supported") == true)
    precondition(error.localizedDescription.contains("not supported") || error.localizedDescription == error.errorDescription)
}

func testRegistrationErrorFailureReasonDefault() {
    let error = IdentityDocumentProviderRegistrationStore.RegistrationError.unknown
    precondition(error.failureReason == nil)
}

func testRegistrationErrorRecoverySuggestionDefault() {
    let error = IdentityDocumentProviderRegistrationStore.RegistrationError.unknown
    precondition(error.recoverySuggestion == nil)
}

func testRegistrationErrorHelpAnchorDefault() {
    let error = IdentityDocumentProviderRegistrationStore.RegistrationError.unknown
    precondition(error.helpAnchor == nil)
}

func testRegistrationStoreStatusCases() {
    let cases: [IdentityDocumentProviderRegistrationStore.Status] = [
        .authorized, .notDetermined, .notAuthorized, .notSupported,
    ]
    precondition(cases.count == 4)
    precondition(IdentityDocumentProviderRegistrationStore.Status.notSupported == .notSupported)
}

func testRegistrationStoreStatusEquality() {
    precondition(
        IdentityDocumentProviderRegistrationStore.Status.authorized
            == .authorized
    )
}

func testRegistrationStoreStatusInequality() {
    precondition(
        IdentityDocumentProviderRegistrationStore.Status.notDetermined
            != .notAuthorized
    )
}

func testRegistrationStoreStatusHash() {
    var hasher = Hasher()
    IdentityDocumentProviderRegistrationStore.Status.notSupported.hash(into: &hasher)
    _ = hasher.finalize()
    let value = IdentityDocumentProviderRegistrationStore.Status.authorized.hashValue
    precondition(value == IdentityDocumentProviderRegistrationStore.Status.authorized.hashValue)
}

func testProviderRegistrationStoreStatusNotSupported() async {
    let store = IdentityDocumentProviderRegistrationStore()
    let status = await store.status
    precondition(status == .notSupported)
}

func testProviderRegistrationStoreRegistrationsThrowsNotSupported() async {
    let store = IdentityDocumentProviderRegistrationStore()
    do {
        _ = try await store.registrations
        preconditionFailure("registrations should throw notSupported without the Apple presentment daemon")
    } catch let error as IdentityDocumentProviderRegistrationStore.RegistrationError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("unexpected registrations error: \(error)")
    }
}

func testProviderRegistrationStoreAddRegistrationThrowsNotSupported() async {
    let store = IdentityDocumentProviderRegistrationStore()
    let registration = MobileDocumentRegistration(
        mobileDocumentType: "org.iso.18013.5.mDL",
        supportedAuthorityKeyIdentifiers: [],
        documentIdentifier: "async-add-1"
    )
    do {
        try await store.addRegistration(registration)
        preconditionFailure("addRegistration should throw notSupported without the Apple presentment daemon")
    } catch let error as IdentityDocumentProviderRegistrationStore.RegistrationError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("unexpected addRegistration error: \(error)")
    }
}

func testProviderRegistrationStoreRemoveRegistrationThrowsNotSupported() async {
    let store = IdentityDocumentProviderRegistrationStore()
    do {
        try await store.removeRegistration(forDocumentIdentifier: "async-remove-1")
        preconditionFailure("removeRegistration should throw notSupported without the Apple presentment daemon")
    } catch let error as IdentityDocumentProviderRegistrationStore.RegistrationError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("unexpected removeRegistration error: \(error)")
    }
}
