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

func testPasswordAndPasskeyIdentityValueStores() {
    let service = ASCredentialServiceIdentifier(identifier: "example.com", type: .domain)
    let passwordIdentity = ASPasswordCredentialIdentity(
        serviceIdentifier: service,
        user: "lane",
        recordIdentifier: "rec"
    )
    passwordIdentity.rank = 4
    precondition(passwordIdentity.user == "lane")
    precondition(passwordIdentity.recordIdentifier == "rec")
    precondition(passwordIdentity.serviceIdentifier.identifier == "example.com")
    precondition(passwordIdentity.rank == 4)
    let passwordRequest = ASPasswordCredentialRequest(credentialIdentity: passwordIdentity)
    precondition(passwordRequest.type == .password)
    precondition(passwordRequest.credentialIdentity.user == "lane")
    let passkey = ASPasskeyCredentialIdentity(
        relyingPartyIdentifier: "example.invalid",
        userName: "lane",
        credentialID: Data("id".utf8),
        userHandle: Data("h".utf8),
        recordIdentifier: "r",
        rank: 2
    )
    precondition(passkey.rank == 2)
    precondition(passkey.user == "lane")
    let convenience = ASPasskeyCredentialIdentity(
        relyingPartyIdentifier: "example.invalid",
        userName: "lane",
        credentialID: Data("id".utf8),
        userHandle: Data("h".utf8),
        recordIdentifier: nil
    )
    precondition(convenience.rank == 0)
    let otpRequest = ASOneTimeCodeCredentialRequest(
        credentialIdentity: ASOneTimeCodeCredentialIdentity(
            serviceIdentifier: service,
            label: "otp",
            recordIdentifier: nil
        )
    )
    precondition(otpRequest.type == .oneTimeCode)
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    precondition(ASPasswordCredentialIdentity(coder: archiver) == nil)
    precondition(ASPasswordCredentialRequest(coder: archiver) == nil)
    precondition(ASPasskeyCredentialIdentity(coder: archiver) == nil)
    precondition(ASOneTimeCodeCredential(coder: archiver) == nil)
    precondition(ASOneTimeCodeCredentialIdentity(coder: archiver) == nil)
    precondition(ASOneTimeCodeCredentialRequest(coder: archiver) == nil)
    passwordIdentity.encode(with: archiver)
    passwordRequest.encode(with: archiver)
    _ = passwordIdentity.copy()
    _ = passwordRequest.copy()
    _ = passkey.copy()
    _ = otpRequest.copy()
    _ = ASOneTimeCodeCredential(code: "000000").copy()
}

func testIdentityStorePasswordCompletionOverloads() {
    let store = ASCredentialIdentityStore.shared
    let identity = ASPasswordCredentialIdentity(
        serviceIdentifier: ASCredentialServiceIdentifier(identifier: "example.com", type: .domain),
        user: "lane",
        recordIdentifier: nil
    )
    let saveSem = DispatchSemaphore(value: 0)
    let saveBox = ASLocked<(Bool, (any Error)?)?>(nil)
    store.saveCredentialIdentities([identity]) { ok, error in
        saveBox.store((ok, error))
        saveSem.signal()
    }
    asWait(saveSem, "save completion missing")
    precondition(saveBox.load()?.0 == false)
    precondition((saveBox.load()?.1 as? ASCredentialIdentityStoreError)?.code == .storeDisabled)

    let replaceSem = DispatchSemaphore(value: 0)
    store.replaceCredentialIdentities(with: [identity]) { ok, error in
        _ = ok
        _ = error
        replaceSem.signal()
    }
    asWait(replaceSem, "replace completion missing")

    let removeSem = DispatchSemaphore(value: 0)
    store.removeCredentialIdentities([identity]) { _, _ in
        removeSem.signal()
    }
    asWait(removeSem, "remove completion missing")

    let removeTyped = asAwait { () -> Bool in
        try await store.removeCredentialIdentities([identity])
        return true
    }
    guard case .failure(let error as ASCredentialIdentityStoreError) = removeTyped else {
        preconditionFailure("expected storeDisabled on typed remove")
    }
    precondition(error.code == .storeDisabled)

    let replaceTyped = asAwait { () -> Bool in
        try await store.replaceCredentialIdentities(with: [identity])
        return true
    }
    guard case .failure = replaceTyped else {
        preconditionFailure("expected storeDisabled on typed replace")
    }
    let saveTyped = asAwait { () -> Bool in
        try await store.saveCredentialIdentities([identity])
        return true
    }
    guard case .failure = saveTyped else {
        preconditionFailure("expected storeDisabled on typed save")
    }
    let replaceAny = asAwait { () -> Bool in
        try await store.replaceCredentialIdentities([identity as any ASCredentialIdentity])
        return true
    }
    guard case .failure = replaceAny else {
        preconditionFailure("expected storeDisabled on any replace")
    }
    let removeAny = asAwait { () -> Bool in
        try await store.removeCredentialIdentities([identity as any ASCredentialIdentity])
        return true
    }
    guard case .failure = removeAny else {
        preconditionFailure("expected storeDisabled on any remove")
    }
}

func testAccountModificationControllerFailClosed() {
    let controller = ASAccountAuthenticationModificationController()
    let modificationAnchor = ModificationAnchorProvider()
    controller.presentationContextProvider = modificationAnchor
    let service = ASCredentialServiceIdentifier(identifier: "example.com", type: .domain)
    let request = ASAccountAuthenticationModificationReplacePasswordWithSignInWithAppleRequest(
        user: "lane",
        serviceIdentifier: service,
        userInfo: ["k": "v"]
    )
    precondition(request.user == "lane")
    let upgrade = ASAccountAuthenticationModificationUpgradePasswordToStrongPasswordRequest(
        user: "lane",
        serviceIdentifier: service
    )
    precondition(upgrade.user == "lane")
    final class Probe: NSObject, ASAccountAuthenticationModificationControllerDelegate, @unchecked Sendable {
        let semaphore = DispatchSemaphore(value: 0)
        let errorBox = ASLocked<(any Error)?>(nil)
        func accountAuthenticationModificationController(
            _ controller: ASAccountAuthenticationModificationController,
            didFail request: ASAccountAuthenticationModificationRequest,
            error: any Error
        ) {
            errorBox.store(error)
            semaphore.signal()
        }
    }
    let probe = Probe()
    controller.delegate = probe
    controller.perform(request)
    asWait(probe.semaphore, "modification didFail missing")
    let typed = probe.errorBox.load() as? ASAuthorizationError
    precondition(typed?.code == .notHandled)
    _ = upgrade
    _ = ASAccountAuthenticationModificationRequest()
}

func testPasskeyAssertionAndRegistrationCredentials() {
    let assertion = ASPasskeyAssertionCredential(
        userHandle: Data("h".utf8),
        relyingParty: "example.invalid",
        signature: Data("s".utf8),
        clientDataHash: Data("c".utf8),
        authenticatorData: Data("a".utf8),
        credentialID: Data("id".utf8),
        extensionOutput: ASPasskeyAssertionCredentialExtensionOutput(
            largeBlob: .read(data: nil),
            prf: ASAuthorizationPublicKeyCredentialPRFAssertionOutput()
        )
    )
    precondition(assertion.relyingParty == "example.invalid")
    let registration = ASPasskeyRegistrationCredential(
        relyingParty: "example.invalid",
        clientDataHash: Data("c".utf8),
        credentialID: Data("id".utf8),
        attestationObject: Data("att".utf8),
        extensionOutput: ASPasskeyRegistrationCredentialExtensionOutput(
            largeBlob: .supported,
            prf: .supported
        )
    )
    precondition(registration.attestationObject == Data("att".utf8))
    let parameters = ASPasskeyCredentialRequestParameters()
    parameters.relyingPartyIdentifier = "example.invalid"
    parameters.clientDataHash = Data("c".utf8)
    parameters.allowedCredentials = [Data("id".utf8)]
    parameters.userVerificationPreference = .required
    parameters.extensionInput = ASPasskeyAssertionCredentialExtensionInput(
        largeBlob: .read,
        prf: nil
    )
    precondition(parameters.relyingPartyIdentifier == "example.invalid")
    let identity = ASPasskeyCredentialIdentity(
        relyingPartyIdentifier: "example.invalid",
        userName: "lane",
        credentialID: Data("id".utf8),
        userHandle: Data("h".utf8),
        recordIdentifier: nil
    )
    let withAssertionExt = ASPasskeyCredentialRequest(
        credentialIdentity: identity,
        clientDataHash: Data("h".utf8),
        userVerificationPreference: .preferred,
        supportedAlgorithms: [.ES256],
        extensionInput: ASPasskeyAssertionCredentialExtensionInput()
    )
    if case .assertion = withAssertionExt.extensionInput { () } else {
        preconditionFailure("expected assertion extension")
    }
    let withRegExt = ASPasskeyCredentialRequest(
        credentialIdentity: identity,
        clientDataHash: Data("h".utf8),
        userVerificationPreference: .preferred,
        supportedAlgorithms: [.ES256],
        extensionInput: ASPasskeyRegistrationCredentialExtensionInput(
            largeBlob: .supportPreferred,
            prf: .checkForSupport
        )
    )
    if case .registration = withRegExt.extensionInput { () } else {
        preconditionFailure("expected registration extension")
    }
    let nsNumbers = ASPasskeyCredentialRequest(
        credentialIdentity: identity,
        clientDataHash: Data("h".utf8),
        userVerificationPreference: .preferred,
        supportedAlgorithms: [NSNumber(value: -7)]
    )
    precondition(nsNumbers.supportedAlgorithms.first?.rawValue == -7)
    _ = assertion.copy()
    _ = registration.copy()
    _ = parameters.copy()
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    assertion.encode(with: archiver)
    registration.encode(with: archiver)
    parameters.encode(with: archiver)
    precondition(ASPasskeyAssertionCredential(coder: archiver) == nil)
    precondition(ASPasskeyRegistrationCredential(coder: archiver) == nil)
    precondition(ASPasskeyCredentialRequest(coder: archiver) == nil)
    precondition(ASPasskeyCredentialRequestParameters(coder: archiver) == nil)
    _ = ASPasskeyCredentialExtensionInput.none
}

func testCredentialUpdaterAndExtensionContext() {
    let updater = ASCredentialUpdater()
    let unused = asAwait { () -> Bool in
        try await updater.reportUnusedPasswordCredential(domain: "example.com", userName: "lane")
        return true
    }
    guard case .failure(let error as ASAuthorizationError) = unused else {
        preconditionFailure("expected failed updater")
    }
    precondition(error.code == .failed)
    let pk = asAwait { () -> Bool in
        try await updater.reportPublicKeyCredentialUpdate(
            relyingPartyIdentifier: "example.invalid",
            userHandle: Data(),
            newName: "n"
        )
        return true
    }
    guard case .failure = pk else { preconditionFailure("expected failed pk update") }
    let unknown = asAwait { () -> Bool in
        try await updater.reportUnknownPublicKeyCredential(
            relyingPartyIdentifier: "example.invalid",
            credentialID: Data()
        )
        return true
    }
    guard case .failure = unknown else { preconditionFailure("expected failed unknown pk") }
    let accepted = asAwait { () -> Bool in
        try await updater.reportAllAcceptedPublicKeyCredentials(
            relyingPartyIdentifier: "example.invalid",
            userHandle: Data(),
            acceptedCredentialIDs: []
        )
        return true
    }
    guard case .failure = accepted else { preconditionFailure("expected failed accepted pk") }

    let extensionContext = ASCredentialProviderExtensionContext()
    extensionContext.cancelRequest(withError: ASExtensionError(.userCanceled))
    extensionContext.completeExtensionConfigurationRequest()
    let completePassword = DispatchSemaphore(value: 0)
    extensionContext.completeRequest(withSelectedCredential: ASPasswordCredential(user: "u", password: "p")) { ok in
        precondition(ok == false)
        completePassword.signal()
    }
    asWait(completePassword, "completeRequest callback missing")
    let assertionDone = asAwait { () -> Bool in
        await extensionContext.completeAssertionRequest(
            using: ASPasskeyAssertionCredential(
                userHandle: Data(),
                relyingParty: "example.invalid",
                signature: Data(),
                clientDataHash: Data(),
                authenticatorData: Data(),
                credentialID: Data()
            )
        )
    }
    guard case .success(false) = assertionDone else { preconditionFailure("expected false assertion complete") }
    let otpDone = asAwait { () -> Bool in
        await extensionContext.completeOneTimeCodeRequest(using: ASOneTimeCodeCredential(code: "1"))
    }
    guard case .success(false) = otpDone else { preconditionFailure("expected false otp complete") }
    let regDone = asAwait { () -> Bool in
        await extensionContext.completeRegistrationRequest(
            using: ASPasskeyRegistrationCredential(
                relyingParty: "example.invalid",
                clientDataHash: Data(),
                credentialID: Data(),
                attestationObject: Data()
            )
        )
    }
    guard case .success(false) = regDone else { preconditionFailure("expected false registration complete") }
    let insert = asAwait { () -> Bool in
        await extensionContext.completeRequest(withTextToInsert: "x")
    }
    guard case .success(false) = insert else { preconditionFailure("expected false insert") }

    let modification = ASAccountAuthenticationModificationExtensionContext()
    modification.cancelRequest(withError: ASAuthorizationError(.canceled))
    modification.completeChangePasswordRequest(
        updatedCredential: ASPasswordCredential(user: "u", password: "p"),
        userInfo: nil
    )
    modification.completeUpgradeToSignInWithApple(userInfo: nil)
    let siwa = DispatchSemaphore(value: 0)
    modification.getSignInWithAppleUpgradeAuthorization(state: "s", nonce: "n") { credential, error in
        precondition(credential == nil)
        precondition(error is ASAuthorizationError)
        siwa.signal()
    }
    asWait(siwa, "siwa upgrade callback missing")
}

func testSettingsHelperVerificationAndErrorWitnesses() {
    let semaphore = DispatchSemaphore(value: 0)
    ASSettingsHelper.openVerificationCodeAppSettings { error in
        precondition((error as? ASAuthorizationError)?.code == .notInteractive)
        semaphore.signal()
    }
    asWait(semaphore, "verification settings callback missing")
    let storeError = ASCredentialIdentityStoreError(.internalError, userInfo: ["a": "b"])
    precondition(storeError.userInfo["a"] as? String == "b")
    precondition(storeError.errorUserInfo["a"] as? String == "b")
    precondition(storeError.errorCode == 0)
    precondition(!storeError.localizedDescription.isEmpty)
    precondition(ASCredentialIdentityStoreError.Code(rawValue: 2) == .storeBusy)
    var hasher = Hasher()
    storeError.hash(into: &hasher)
    _ = hasher.finalize()
    _ = storeError.hashValue
    _ = ASCredentialIdentityStoreError.Code.storeDisabled.hashValue
    var codeHasher = Hasher()
    ASCredentialIdentityStoreError.Code.storeBusy.hash(into: &codeHasher)
    _ = codeHasher.finalize()
    let ext = ASExtensionError(.failed, userInfo: [:])
    _ = ext.hashValue
    ext.hash(into: &hasher)
    _ = ASExtensionError.Code(rawValue: 100)
    _ = ASExtensionError.Code.failed.hashValue
    var extHasher = Hasher()
    ASExtensionError.Code.userCanceled.hash(into: &extHasher)
    _ = extHasher.finalize()
    _ = ext.localizedDescription
    _ = ext.userInfo
    _ = ext.errorUserInfo
    _ = ASExtensionError.errorDomain
    _ = ASCredentialIdentityStoreError.errorDomain
    _ = ASCredentialIdentityStore.IdentityTypes()
    var types = ASCredentialIdentityStore.IdentityTypes(rawValue: 0)
    types.formUnion(.password)
    _ = types.union(.passkey)
    _ = types.intersection(.password)
    _ = types.symmetricDifference(.oneTimeCode)
    types.formIntersection(.password)
    types.formSymmetricDifference(.passkey)
    _ = types.subtracting(.password)
    types.subtract(.password)
    _ = types.isDisjoint(with: .oneTimeCode)
    _ = types.isSuperset(of: [])
    _ = types.isSubset(of: [.password, .passkey, .oneTimeCode])
    _ = types.isStrictSubset(of: [.password, .passkey])
    _ = types.isStrictSuperset(of: [])
    _ = types.isEmpty
    _ = types.remove(.passkey)
    _ = types.update(with: .oneTimeCode)
    _ = ASCredentialIdentityStore.IdentityTypes([.password, .passkey])
    _ = ASCredentialIdentityStore.IdentityTypes(arrayLiteral: .password)
}

func testPasswordCredentialCodingRoundTrip() {
    let credential = ASPasswordCredential(user: "lane", password: "secret")
    let data = try! NSKeyedArchiver.archivedData(withRootObject: credential, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: ASPasswordCredential.self, from: data)
    precondition(decoded?.user == "lane")
    precondition(decoded?.password == "secret")
    let service = ASCredentialServiceIdentifier(identifier: "https://example.com", type: .URL)
    let serviceData = try! NSKeyedArchiver.archivedData(withRootObject: service, requiringSecureCoding: true)
    let decodedService = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ASCredentialServiceIdentifier.self,
        from: serviceData
    )
    precondition(decodedService?.identifier == "https://example.com")
    precondition(decodedService?.type == .URL)
}

func testProviderExtensionAuthorizationRequestFields() {
    let request = ASAuthorizationProviderExtensionAuthorizationRequest()
    request.authorizationOptions = ["k": "v"]
    request.callerBundleIdentifier = "bundle"
    request.isCallerManaged = true
    request.callerTeamIdentifier = "team"
    request.extensionData = ["e": 1]
    request.httpBody = Data("body".utf8)
    request.httpHeaders = ["H": "v"]
    request.localizedCallerDisplayName = "Lane"
    request.realm = "realm"
    request.requestedOperation = .configurationRemoved
    request.url = URL(string: "https://example.invalid")!
    request.isUserInterfaceEnabled = true
    precondition(request.callerBundleIdentifier == "bundle")
    request.complete(error: ASAuthorizationError(.failed))
    request.complete(httpAuthorizationHeaders: ["Authorization": "x"])
    let result = ASAuthorizationProviderExtensionAuthorizationResult(
        HTTPAuthorizationHeaders: ["A": "b"]
    )
    precondition(result.httpAuthorizationHeaders?["A"] == "b")
    result.httpBody = Data()
    final class Handler: NSObject, ASAuthorizationProviderExtensionAuthorizationRequestHandler {
        func beginAuthorization(with request: ASAuthorizationProviderExtensionAuthorizationRequest) {
            request.doNotHandle()
        }
    }
    let handler = Handler()
    handler.beginAuthorization(with: request)
    handler.cancelAuthorization(with: request)
}
