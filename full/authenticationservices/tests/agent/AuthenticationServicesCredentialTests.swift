import Dispatch
import Foundation
import AuthenticationServices

func testCredentialServiceIdentifierCoding() {
    let identifier = ASCredentialServiceIdentifier(identifier: "example.com", type: .domain)
    precondition(identifier.identifier == "example.com")
    precondition(identifier.type == .domain)
    precondition(ASCredentialServiceIdentifier.IdentifierType.domain.rawValue == 0)
    precondition(ASCredentialServiceIdentifier.IdentifierType.URL.rawValue == 1)
    let copy = identifier.copy() as? ASCredentialServiceIdentifier
    precondition(copy?.identifier == "example.com")
}

func testPasswordCredentialProperties() {
    let credential = ASPasswordCredential(user: "lane", password: "secret")
    precondition(credential.user == "lane")
    precondition(credential.password == "secret")
    let copy = credential.copy() as? ASPasswordCredential
    precondition(copy?.password == "secret")
}

func testIdentityStoreDisabled() {
    let store = ASCredentialIdentityStore.shared
    let stateBox = ASLocked<ASCredentialIdentityStoreState?>(nil)
    let returned = ASLocked(false)
    let afterReturn = ASLocked(false)
    let semaphore = DispatchSemaphore(value: 0)
    store.getState { state in
        afterReturn.store(returned.load())
        stateBox.store(state)
        semaphore.signal()
    }
    returned.store(true)
    asWait(semaphore, "identity store state callback missing")
    precondition(afterReturn.load())
    precondition(stateBox.load()?.isEnabled == false)
    precondition(stateBox.load()?.supportsIncrementalUpdates == false)

    let identities: [any ASCredentialIdentity] = [
        ASPasswordCredentialIdentity(
            serviceIdentifier: ASCredentialServiceIdentifier(identifier: "example.com", type: .domain),
            user: "lane",
            recordIdentifier: nil
        )
    ]
    let save = asAwait { () -> Bool in
        try await store.saveCredentialIdentities(identities)
        return true
    }
    guard case .failure(let error as ASCredentialIdentityStoreError) = save else {
        preconditionFailure("expected storeDisabled on save")
    }
    precondition(error.code == .storeDisabled)

    let listed = asAwait { () -> [any ASCredentialIdentity] in
        await store.credentialIdentities(
            forService: nil,
            credentialIdentityTypes: [.password, .passkey, .oneTimeCode]
        )
    }
    guard case .success(let values) = listed else {
        preconditionFailure("expected empty identity list")
    }
    precondition(values.isEmpty)
}

func testIdentityStoreRemoveAllCallbackAfterReturn() {
    let store = ASCredentialIdentityStore.shared
    let returned = ASLocked(false)
    let afterReturn = ASLocked(false)
    let okBox = ASLocked<Bool?>(nil)
    let errorBox = ASLocked<(any Error)?>(nil)
    let semaphore = DispatchSemaphore(value: 0)
    store.removeAllCredentialIdentities { ok, error in
        afterReturn.store(returned.load())
        okBox.store(ok)
        errorBox.store(error)
        semaphore.signal()
    }
    returned.store(true)
    asWait(semaphore, "removeAll callback missing")
    precondition(afterReturn.load())
    precondition(okBox.load() == false)
    let typed = errorBox.load() as? ASCredentialIdentityStoreError
    precondition(typed?.code == .storeDisabled)
}

func testIdentityTypesOptionSet() {
    var types: ASCredentialIdentityStore.IdentityTypes = [.password]
    types.insert(.passkey)
    precondition(types.contains(.password))
    precondition(types.contains(.passkey))
    precondition(!types.contains(.oneTimeCode))
    types.formUnion(.oneTimeCode)
    precondition(types.contains(.oneTimeCode))
    precondition(ASCredentialIdentityStore.IdentityTypes.password.rawValue == 1)
    precondition(ASCredentialIdentityStore.IdentityTypes.passkey.rawValue == 2)
    precondition(ASCredentialIdentityStore.IdentityTypes.oneTimeCode.rawValue == 4)
}

func testSettingsHelperFailClosed() {
    let semaphore = DispatchSemaphore(value: 0)
    let returned = ASLocked(false)
    let afterReturn = ASLocked(false)
    let errorBox = ASLocked<(any Error)?>(nil)
    ASSettingsHelper.openCredentialProviderAppSettings { error in
        afterReturn.store(returned.load())
        errorBox.store(error)
        semaphore.signal()
    }
    returned.store(true)
    asWait(semaphore, "settings helper callback missing")
    precondition(afterReturn.load())
    let typed = errorBox.load() as? ASAuthorizationError
    precondition(typed?.code == .notInteractive)

    let enabled = ASLocked<Bool?>(nil)
    let turnOn = DispatchSemaphore(value: 0)
    ASSettingsHelper.requestToTurnOnCredentialProviderExtension { value in
        enabled.store(value)
        turnOn.signal()
    }
    asWait(turnOn, "turn-on callback missing")
    precondition(enabled.load() == false)
}

func testImportExportManagersThrow() {
    let exporter = ASCredentialExportManager()
    let export = asAwait { () -> ASCredentialExportManager.ExportOptions in
        try await exporter.requestExport(for: nil)
    }
    guard case .failure(let error as ASAuthorizationError) = export else {
        preconditionFailure("expected credentialExport")
    }
    precondition(error.code == .credentialExport)

    let payload = ASExportedCredentialData(
        accounts: [],
        formatVersion: .v1,
        exporterRelyingPartyIdentifier: "example.invalid",
        exporterDisplayName: "lane",
        timestamp: Date(timeIntervalSince1970: 0)
    )
    let write = asAwait { () -> Bool in
        try await exporter.exportCredentials(payload)
        return true
    }
    guard case .failure(let writeError as ASAuthorizationError) = write else {
        preconditionFailure("expected credentialExport on write")
    }
    precondition(writeError.code == .credentialExport)

    let importer = ASCredentialImportManager()
    let imported = asAwait { () -> ASExportedCredentialData in
        try await importer.importCredentials(token: UUID())
    }
    guard case .failure(let importError as ASAuthorizationError) = imported else {
        preconditionFailure("expected credentialImport")
    }
    precondition(importError.code == .credentialImport)
}

func testImportableCredentialCodableRoundTrip() {
    let field = ASImportableEditableField(
        id: Data("id".utf8),
        fieldType: .string,
        value: "lane",
        label: "user"
    )
    let credential = ASImportableCredential.basicAuthentication(
        ASImportableCredential.BasicAuthentication(userName: field, password: nil)
    )
    let item = ASImportableItem(
        id: Data("item".utf8),
        title: "example",
        credentials: [credential]
    )
    let account = ASImportableAccount(
        id: Data("account".utf8),
        userName: "lane",
        email: "lane@example.invalid",
        collections: [],
        items: [item]
    )
    let exported = ASExportedCredentialData(
        accounts: [account],
        formatVersion: .v1,
        exporterRelyingPartyIdentifier: "example.invalid",
        exporterDisplayName: "lane",
        timestamp: Date(timeIntervalSince1970: 1)
    )
    let encoded = try! JSONEncoder().encode(exported)
    let decoded = try! JSONDecoder().decode(ASExportedCredentialData.self, from: encoded)
    precondition(decoded == exported)
    precondition(decoded.formatVersion == .v1)
    precondition(ASExportedCredentialData.FormatVersion.allCases == [.v1])
    precondition(ASImportableEditableField.FieldType.string.rawValue == "string")
}

func testPasskeyCredentialRequestConstruction() {
    let identity = ASPasskeyCredentialIdentity(
        relyingPartyIdentifier: "example.invalid",
        userName: "lane",
        credentialID: Data("cred".utf8),
        userHandle: Data("handle".utf8),
        recordIdentifier: nil
    )
    precondition(identity.serviceIdentifier.type == .domain)
    let request = ASPasskeyCredentialRequest(
        credentialIdentity: identity,
        clientDataHash: Data("hash".utf8),
        userVerificationPreference: .preferred,
        supportedAlgorithms: [.ES256]
    )
    precondition(request.type == .passkeyAssertion)
    precondition(request.supportedAlgorithms == [.ES256])
    if case .none = request.extensionInput {
        ()
    } else {
        preconditionFailure("expected none extension input")
    }
}

func testExtensionAuthorizationRequestFailClosed() {
    let request = ASAuthorizationProviderExtensionAuthorizationRequest()
    precondition(!request.isUserInterfaceEnabled)
    precondition(request.httpBody.isEmpty)
    request.complete()
    request.doNotHandle()
    request.cancel()
    let semaphore = DispatchSemaphore(value: 0)
    let okBox = ASLocked<Bool?>(nil)
    request.presentAuthorizationViewController { ok, error in
        okBox.store(ok)
        _ = error
        semaphore.signal()
    }
    asWait(semaphore, "extension presentation callback missing")
    precondition(okBox.load() == false)
    let result = ASAuthorizationProviderExtensionAuthorizationResult(
        httpAuthorizationHeaders: ["Authorization": "Bearer x"]
    )
    request.complete(authorizationResult: result)
}

func testOneTimeCodeAndPasskeyIdentities() {
    let service = ASCredentialServiceIdentifier(identifier: "example.com", type: .URL)
    let otp = ASOneTimeCodeCredentialIdentity(
        serviceIdentifier: service,
        label: "lane",
        recordIdentifier: "rec"
    )
    otp.rank = 3
    precondition(otp.rank == 3)
    precondition(otp.user == "lane")
    let code = ASOneTimeCodeCredential(code: "123456")
    precondition(code.code == "123456")
}
