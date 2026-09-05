import Dispatch
import Foundation
@_spi(OpenUIKitHost) import AuthenticationServices

private final class ControllerProbe: NSObject, ASAuthorizationControllerDelegate, @unchecked Sendable {
    let semaphore = DispatchSemaphore(value: 0)
    let returned = ASLocked(false)
    let afterReturn = ASLocked(false)
    let errorBox = ASLocked<(any Error)?>(nil)

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        preconditionFailure("authorization unexpectedly succeeded \(authorization)")
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        afterReturn.store(returned.load())
        errorBox.store(error)
        semaphore.signal()
    }
}

func testOpenIDOperationAndScopePlaceholders() {
    precondition(ASAuthorization.OpenIDOperation.operationImplicit.rawValue == "ASAuthorizationOperationImplicit")
    precondition(ASAuthorization.OpenIDOperation.operationLogin.rawValue == "ASAuthorizationOperationLogin")
    precondition(ASAuthorization.OpenIDOperation.operationRefresh.rawValue == "ASAuthorizationOperationRefresh")
    precondition(ASAuthorization.OpenIDOperation.operationLogout.rawValue == "ASAuthorizationOperationLogout")
    precondition(ASAuthorization.Scope.email.rawValue == "ASAuthorizationScopeEmail")
    precondition(ASAuthorization.Scope.fullName.rawValue == "ASAuthorizationScopeFullName")
}

func testAttestationAndPreferencePlaceholders() {
    precondition(
        ASAuthorizationPublicKeyCredentialAttestationKind.none.rawValue
            == "ASAuthorizationPublicKeyCredentialAttestationKindNone"
    )
    precondition(
        ASAuthorizationPublicKeyCredentialResidentKeyPreference.preferred.rawValue
            == "ASAuthorizationPublicKeyCredentialResidentKeyPreferencePreferred"
    )
    precondition(
        ASAuthorizationPublicKeyCredentialUserVerificationPreference.required.rawValue
            == "ASAuthorizationPublicKeyCredentialUserVerificationPreferenceRequired"
    )
}

func testCOSEIdentifiers() {
    precondition(ASCOSEAlgorithmIdentifier.ES256.rawValue == -7)
    precondition(ASCOSEEllipticCurveIdentifier.P256.rawValue == 1)
}

func testUserDetectionAgeRangeAndAttachment() {
    precondition(ASUserDetectionStatus.unsupported.rawValue == 0)
    precondition(ASUserDetectionStatus.unknown.rawValue == 1)
    precondition(ASUserDetectionStatus.likelyReal.rawValue == 2)
    precondition(ASUserAgeRange.unknown.rawValue == 0)
    precondition(ASUserAgeRange.child.rawValue == 1)
    precondition(ASUserAgeRange.notChild.rawValue == 2)
    precondition(ASAuthorizationPublicKeyCredentialAttachment.platform.rawValue == 0)
    precondition(ASAuthorizationPublicKeyCredentialAttachment.crossPlatform.rawValue == 1)
    precondition(ASCredentialRequestType.password.rawValue == 0)
    precondition(ASCredentialRequestType.passkeyAssertion.rawValue == 1)
    precondition(ASCredentialRequestType.passkeyRegistration.rawValue == 2)
}

func testAppleIDButtonStyles() {
    precondition(ASAuthorizationAppleIDButton.Style.white.rawValue == 0)
    precondition(ASAuthorizationAppleIDButton.Style.whiteOutline.rawValue == 1)
    precondition(ASAuthorizationAppleIDButton.Style.black.rawValue == 2)
    precondition(ASAuthorizationAppleIDButton.ButtonType.signIn.rawValue == 0)
    precondition(ASAuthorizationAppleIDButton.ButtonType.continue.rawValue == 1)
    precondition(ASAuthorizationAppleIDButton.ButtonType.signUp.rawValue == 2)
    precondition(ASAuthorizationAppleIDButton.ButtonType.default == .signIn)
}

func testAppleIDProviderCredentialState() {
    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()
    request.user = "lane-user"
    request.nonce = "nonce"
    request.requestedOperation = .operationLogin
    request.requestedScopes = [.email, .fullName]
    precondition(request.user == "lane-user")
    let state = asAwait { () -> ASAuthorizationAppleIDProvider.CredentialState in
        try await provider.credentialState(forUserID: "missing")
    }
    guard case .success(.notFound) = state else {
        preconditionFailure("Linux has no Apple ID daemon; expected notFound")
    }
    precondition(ASAuthorizationAppleIDProvider.CredentialState.revoked.rawValue == 0)
    precondition(ASAuthorizationAppleIDProvider.CredentialState.authorized.rawValue == 1)
    precondition(ASAuthorizationAppleIDProvider.CredentialState.notFound.rawValue == 2)
    precondition(ASAuthorizationAppleIDProvider.CredentialState.transferred.rawValue == 3)

    let completionBox = ASLocked<ASAuthorizationAppleIDProvider.CredentialState?>(nil)
    let completionError = ASLocked<(any Error)?>(nil)
    let completionSem = DispatchSemaphore(value: 0)
    provider.getCredentialState(forUserID: "missing") { state, error in
        completionBox.store(state)
        completionError.store(error)
        completionSem.signal()
    }
    asWait(completionSem, "getCredentialState completion missing")
    precondition(completionBox.load() == .notFound)
    precondition(completionError.load() == nil)
    precondition(ASAuthorizationAppleIDProvider.CredentialState(rawValue: 2) == .notFound)
    precondition(ASAuthorizationAppleIDProvider.CredentialState(rawValue: 99) == nil)
    var hasher = Hasher()
    ASAuthorizationAppleIDProvider.CredentialState.notFound.hash(into: &hasher)
    _ = hasher.finalize()
    _ = ASAuthorizationAppleIDProvider.CredentialState.notFound.hashValue
}

func testAuthorizationControllerFailClosed() {
    let provider = ASAuthorizationPasswordProvider()
    let request = provider.createRequest()
    let controller = ASAuthorizationController(authorizationRequests: [request])
    let probe = ControllerProbe()
    controller.delegate = probe
    var options = ASAuthorizationController.RequestOptions()
    options.insert(.preferImmediatelyAvailableCredentials)
    precondition(options.contains(.preferImmediatelyAvailableCredentials))
    precondition(!options.isEmpty)
    _ = options.union([])
    controller.performRequests(options: options)
    probe.returned.store(true)
    asWait(probe.semaphore, "authorization controller did not complete")
    precondition(probe.afterReturn.load())
    let typed = probe.errorBox.load() as? ASAuthorizationError
    precondition(typed?.code == .notHandled)
    controller.cancel()
    controller.performAutoFillAssistedRequests()
}

func testPasswordAndSSOProviders() {
    let password = ASAuthorizationPasswordProvider().createRequest()
    _ = password
    let sso = ASAuthorizationSingleSignOnProvider(
        identityProvider: URL(string: "https://sso.example/auth")!
    )
    precondition(!sso.canPerformAuthorization)
    let request = sso.createRequest()
    request.isUserInterfaceEnabled = false
    request.authorizationOptions = ["prompt": "none"]
    precondition(request.isUserInterfaceEnabled == false)
}

func testRequestOptionsOptionSet() {
    let empty = ASAuthorizationController.RequestOptions()
    precondition(empty.isEmpty)
    let prefer = ASAuthorizationController.RequestOptions.preferImmediatelyAvailableCredentials
    precondition(prefer.rawValue == 1)
    precondition(prefer.union(empty) == prefer)
    precondition(prefer.intersection(empty).isEmpty)
    precondition(prefer.isDisjoint(with: empty))
    precondition(prefer.isSuperset(of: empty))
    precondition(empty.isSubset(of: prefer))
    var mutable = prefer
    mutable.subtract(prefer)
    precondition(mutable.isEmpty)
    var inserted = ASAuthorizationController.RequestOptions()
    let result = inserted.insert(.preferImmediatelyAvailableCredentials)
    precondition(result.inserted)
    precondition(inserted.remove(.preferImmediatelyAvailableCredentials) != nil)
}

func testAccountCreationRequest() {
    let provider = ASAuthorizationAccountCreationProvider()
    let request = provider.createPlatformPublicKeyCredentialRegistrationRequest(
        acceptedContactIdentifiers: [.email],
        shouldRequestName: true,
        relyingPartyIdentifier: "example.invalid",
        challenge: Data("challenge".utf8),
        userID: Data("user".utf8)
    )
    precondition(request.shouldRequestName)
    precondition(request.relyingPartyIdentifier == "example.invalid")
    precondition(request.acceptedContactIdentifiers == [.email])
    let fallback = provider.createCredentialRegistrationRequest()
    _ = fallback
}

func testWebBrowserManagerDenied() {
    precondition(!ASAuthorizationWebBrowserPublicKeyCredentialManager.isDeviceConfiguredForPasskeys)
    let manager = ASAuthorizationWebBrowserPublicKeyCredentialManager()
    precondition(manager.authorizationStateForPlatformCredentials == .denied)
    let state = asAwait { () -> ASAuthorizationWebBrowserPublicKeyCredentialManager.AuthorizationState in
        await manager.authorizationState()
    }
    guard case .success(.denied) = state else {
        preconditionFailure("expected denied authorization state")
    }
    let credentials = asAwait { () -> [ASAuthorizationWebBrowserPlatformPublicKeyCredential] in
        await manager.platformCredentials(forRelyingParty: "example.invalid")
    }
    guard case .success(let list) = credentials else {
        preconditionFailure("expected empty platform credentials")
    }
    precondition(list.isEmpty)
    let semaphore = DispatchSemaphore(value: 0)
    let box = ASLocked<ASAuthorizationWebBrowserPublicKeyCredentialManager.AuthorizationState?>(nil)
    manager.requestAuthorizationForPublicKeyCredentials { state in
        box.store(state)
        semaphore.signal()
    }
    asWait(semaphore, "web browser authorization callback missing")
    precondition(box.load() == .denied)
    precondition(ASAuthorizationWebBrowserPublicKeyCredentialManager.AuthorizationState.authorized.rawValue == 0)
    precondition(ASAuthorizationWebBrowserPublicKeyCredentialManager.AuthorizationState.denied.rawValue == 1)
    precondition(ASAuthorizationWebBrowserPublicKeyCredentialManager.AuthorizationState.notDetermined.rawValue == 2)
    let credential = ASAuthorizationWebBrowserPlatformPublicKeyCredential(
        name: "lane",
        relyingParty: "example.invalid",
        credentialID: Data(),
        userHandle: Data()
    )
    precondition(credential.customTitle.isEmpty)
}

func testAuthorizationResultAndAppleIDCredential() {
    let password = ASPasswordCredential(user: "lane", password: "secret")
    let result = ASAuthorizationResult.password(password)
    if case .password(let value) = result {
        precondition(value.user == "lane")
    } else {
        preconditionFailure("expected password result")
    }
    let apple = ASAuthorizationAppleIDCredential()
    precondition(apple.user.isEmpty)
    precondition(apple.realUserStatus == .unsupported)
    precondition(apple.userAgeRange == .unknown)
}

func testAuthorizationControllerEmptyRequestsUnknown() {
    let controller = ASAuthorizationController(authorizationRequests: [])
    let probe = ControllerProbe()
    controller.delegate = probe
    let authAnchor = AuthorizationAnchorProvider()
    controller.presentationContextProvider = authAnchor
    _ = controller.presentationContextProvider
    controller.performRequests()
    probe.returned.store(true)
    asWait(probe.semaphore, "empty controller did not complete")
    let typed = probe.errorBox.load() as? ASAuthorizationError
    precondition(typed?.code == .unknown)
}

func testAuthorizationControllerTestHookDeliversCredential() {
    let provider = ASAuthorizationAppleIDProvider()
    let request = provider.createRequest()
    request.requestedScopes = [.email, .fullName]
    request.requestedOperation = .operationLogin
    request.nonce = "n"
    request.state = "s"
    request.user = "lane"
    let controller = ASAuthorizationController(authorizationRequests: [request])
    let credential = ASAuthorizationAppleIDCredential(
        user: "lane",
        email: "lane@example.invalid",
        identityToken: Data("token".utf8),
        authorizationCode: Data("code".utf8),
        state: "s",
        authorizedScopes: [.email, .fullName],
        realUserStatus: .likelyReal,
        userAgeRange: .notChild
    )
    let authorization = ASAuthorization(provider: provider, credential: credential)
    controller._testAuthorization = authorization

    final class SuccessProbe: NSObject, ASAuthorizationControllerDelegate, @unchecked Sendable {
        let semaphore = DispatchSemaphore(value: 0)
        let box = ASLocked<ASAuthorization?>(nil)
        func authorizationController(
            controller: ASAuthorizationController,
            didCompleteWithAuthorization authorization: ASAuthorization
        ) {
            box.store(authorization)
            semaphore.signal()
        }
        func authorizationController(
            controller: ASAuthorizationController,
            didCompleteWithError error: Error
        ) {
            preconditionFailure("hook should succeed \(error)")
        }
    }
    let probe = SuccessProbe()
    controller.delegate = probe
    controller.performRequests()
    asWait(probe.semaphore, "hook authorization missing")
    let delivered = probe.box.load()
    let apple = delivered?.credential as? ASAuthorizationAppleIDCredential
    precondition(apple?.user == "lane")
    precondition(apple?.email == "lane@example.invalid")
    precondition(apple?.identityToken == Data("token".utf8))
    precondition(apple?.authorizationCode == Data("code".utf8))
    precondition(apple?.authorizedScopes == [.email, .fullName])
    let copy = apple?.copy() as? ASAuthorizationAppleIDCredential
    precondition(copy?.user == "lane")
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    apple?.encode(with: archiver)
    precondition(ASAuthorizationAppleIDCredential(coder: archiver) == nil)
}

func testPlatformPublicKeyProviderValueStores() {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(
        relyingPartyIdentifier: "example.invalid"
    )
    precondition(provider.relyingPartyIdentifier == "example.invalid")
    let challenge = Data("challenge".utf8)
    let userID = Data("user".utf8)
    let registration = provider.createCredentialRegistrationRequest(
        challenge: challenge,
        name: "lane",
        userID: userID
    )
    precondition(registration.challenge == challenge)
    precondition(registration.name == "lane")
    precondition(registration.userID == userID)
    precondition(registration.relyingPartyIdentifier == "example.invalid")
    registration.displayName = "Lane"
    registration.attestationPreference = .direct
    registration.userVerificationPreference = .required
    precondition(registration.displayName == "Lane")
    precondition(registration.attestationPreference == .direct)
    let styled = provider.createCredentialRegistrationRequest(
        challenge: challenge,
        name: "lane",
        userID: userID,
        requestStyle: .conditional
    )
    precondition(styled.requestStyle == .conditional)
    precondition(ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest.RequestStyle.standard.rawValue == 0)
    precondition(ASAuthorizationPlatformPublicKeyCredentialRegistrationRequest.RequestStyle.conditional.rawValue == 1)

    let assertion = provider.createCredentialAssertionRequest(challenge: challenge)
    assertion.challenge = Data("other".utf8)
    assertion.relyingPartyIdentifier = "example.invalid"
    assertion.userVerificationPreference = .discouraged
    let descriptor = ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: Data("cred".utf8))
    assertion.platformAllowedCredentials = [descriptor]
    precondition(assertion.allowedCredentials.count == 1)
    precondition(assertion.platformAllowedCredentials.first?.credentialID == Data("cred".utf8))
    let client = ASPublicKeyCredentialClientData(challenge: challenge, origin: "https://example.invalid")
    _ = provider.createCredentialAssertionRequest(clientData: client)
    _ = provider.createCredentialRegistrationRequest(clientData: client, name: "lane", userID: userID)
    _ = provider.createCredentialRegistrationRequest(
        clientData: client,
        name: "lane",
        userID: userID,
        requestStyle: .standard
    )

    let controller = ASAuthorizationController(authorizationRequests: [registration])
    let probe = ControllerProbe()
    controller.delegate = probe
    controller.performRequests()
    probe.returned.store(true)
    asWait(probe.semaphore, "passkey controller did not fail closed")
    let typed = probe.errorBox.load() as? ASAuthorizationError
    precondition(typed?.code == .notHandled)
}

func testSecurityKeyPublicKeyProvider() {
    let provider = ASAuthorizationSecurityKeyPublicKeyCredentialProvider(
        relyingPartyIdentifier: "example.invalid"
    )
    let registration = provider.createCredentialRegistrationRequest(
        challenge: Data("c".utf8),
        displayName: "Lane",
        name: "lane",
        userID: Data("u".utf8)
    )
    precondition(registration.displayName == "Lane")
    registration.credentialParameters = [
        ASAuthorizationPublicKeyCredentialParameters(algorithm: .ES256)
    ]
    registration.residentKeyPreference = .required
    let descriptor = ASAuthorizationSecurityKeyPublicKeyCredentialDescriptor(
        credentialID: Data("cred".utf8),
        transports: [.usb, .nfc, .bluetooth]
    )
    precondition(descriptor.transports.contains(.usb))
    registration.excludedCredentials = [descriptor]
    let assertion = provider.createCredentialAssertionRequest(challenge: Data("c".utf8))
    assertion.appID = "appid"
    assertion.securityKeyAllowedCredentials = [descriptor]
    precondition(assertion.securityKeyAllowedCredentials.count == 1)
}

func testAppleIDButtonConstruction() {
    let button = ASAuthorizationAppleIDButton(
        authorizationButtonType: .signIn,
        authorizationButtonStyle: .black
    )
    button.cornerRadius = 12
    precondition(button.cornerRadius == 12)
    let convenience = ASAuthorizationAppleIDButton(type: .continue, style: .whiteOutline)
    convenience.cornerRadius = 0
    precondition(convenience.cornerRadius == 0)
    precondition(ASAuthorizationAppleIDButton.Style(rawValue: 2) == .black)
    precondition(ASAuthorizationAppleIDButton.ButtonType(rawValue: 0) == .signIn)
    var hasher = Hasher()
    ASAuthorizationAppleIDButton.Style.white.hash(into: &hasher)
    _ = hasher.finalize()
    _ = ASAuthorizationAppleIDButton.Style.white.hashValue
    _ = ASAuthorizationAppleIDButton.ButtonType.signUp.hashValue
}

func testOpenIDRequestAndAuthorizationNewtypes() {
    let implicit = ASAuthorization.OpenIDOperation(rawValue: "ASAuthorizationOperationImplicit")
    let labeled = ASAuthorization.OpenIDOperation("ASAuthorizationOperationLogin")
    precondition(implicit == .operationImplicit)
    precondition(labeled == .operationLogin)
    var hasher = Hasher()
    implicit.hash(into: &hasher)
    _ = hasher.finalize()
    _ = implicit.hashValue
    let email = ASAuthorization.Scope(rawValue: "ASAuthorizationScopeEmail")
    let fullName = ASAuthorization.Scope("ASAuthorizationScopeFullName")
    precondition(email == .email)
    precondition(fullName == .fullName)
    _ = email.hashValue
    var scopeHasher = Hasher()
    fullName.hash(into: &scopeHasher)
    _ = scopeHasher.finalize()
    let passwordRequest = ASAuthorizationPasswordRequest(
        provider: ASAuthorizationPasswordProvider()
    )
    _ = passwordRequest.provider
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    precondition(ASAuthorizationRequest(coder: archiver) == nil)
}

func testAuthorizationErrorUserInfoAndHash() {
    let typed = ASAuthorizationError(.unknown, userInfo: ["k": "v"])
    precondition(typed.userInfo["k"] as? String == "v")
    precondition(typed.errorUserInfo["k"] as? String == "v")
    precondition(typed.errorCode == 1000)
    precondition(!typed.localizedDescription.isEmpty)
    precondition(ASAuthorizationError.Code(rawValue: 1003) == .notHandled)
    var hasher = Hasher()
    typed.hash(into: &hasher)
    _ = hasher.finalize()
    _ = typed.hashValue
    _ = ASAuthorizationError.Code.unknown.hashValue
    var codeHasher = Hasher()
    ASAuthorizationError.Code.failed.hash(into: &codeHasher)
    _ = codeHasher.finalize()
}

func testSSOCredentialValueSemantics() {
    let credential = ASAuthorizationSingleSignOnCredential(
        state: "st",
        accessToken: Data("a".utf8),
        identityToken: Data("i".utf8),
        authorizedScopes: [.email]
    )
    precondition(credential.state == "st")
    precondition(credential.accessToken == Data("a".utf8))
    precondition(credential.identityToken == Data("i".utf8))
    let copy = credential.copy() as? ASAuthorizationSingleSignOnCredential
    precondition(copy?.state == "st")
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    credential.encode(with: archiver)
    precondition(ASAuthorizationSingleSignOnCredential(coder: archiver) == nil)
}

func testPublicKeyCredentialParametersAndPRF() {
    let parameters = ASAuthorizationPublicKeyCredentialParameters(algorithm: .ES256)
    precondition(parameters.algorithm == .ES256)
    let copy = parameters.copy() as? ASAuthorizationPublicKeyCredentialParameters
    precondition(copy?.algorithm.rawValue == -7)
    let values = ASAuthorizationPublicKeyCredentialPRFAssertionInput.InputValues(
        saltInput1: Data("s1".utf8),
        saltInput2: Data("s2".utf8)
    )
    let input = ASAuthorizationPublicKeyCredentialPRFAssertionInput.inputValues(
        values,
        perCredentialInputValues: [Data("c".utf8): values]
    )
    precondition(input.inputValues?.saltInput1 == Data("s1".utf8))
    let per = ASAuthorizationPublicKeyCredentialPRFAssertionInput.perCredentialInputValues(
        [Data("c".utf8): .saltInput1(Data("x".utf8))]
    )
    precondition(per.inputValues == nil)
    let reg = ASAuthorizationPublicKeyCredentialPRFRegistrationInput.inputValues(values)
    precondition(reg.shouldCheckForSupport == false)
    precondition(ASAuthorizationPublicKeyCredentialPRFRegistrationInput.checkForSupport.shouldCheckForSupport)
    precondition(ASAuthorizationPublicKeyCredentialPRFRegistrationOutput.unsupported.isSupported == false)
    precondition(ASAuthorizationPublicKeyCredentialPRFRegistrationOutput.supported.isSupported)
    let blobIn = ASAuthorizationPublicKeyCredentialLargeBlobRegistrationInput.supportRequired
    precondition(blobIn.supportRequirement == .required)
    _ = ASAuthorizationPublicKeyCredentialLargeBlobRegistrationInput.supportPreferred
    _ = ASAuthorizationPublicKeyCredentialLargeBlobRegistrationOutput.supported
    _ = ASAuthorizationPublicKeyCredentialLargeBlobRegistrationOutput.unsupported
    _ = ASAuthorizationPublicKeyCredentialLargeBlobAssertionInput.read
    _ = ASAuthorizationPublicKeyCredentialLargeBlobAssertionInput.write(Data("b".utf8))
    _ = ASAuthorizationPublicKeyCredentialLargeBlobAssertionOutput.read(data: Data("r".utf8))
    _ = ASAuthorizationPublicKeyCredentialLargeBlobAssertionOutput.write(success: true)
    let client = ASPublicKeyCredentialClientData(
        challenge: Data("c".utf8),
        origin: "https://example.invalid",
        topOrigin: "https://top.invalid",
        crossOrigin: .crossOrigin
    )
    precondition(client.origin == "https://example.invalid")
    precondition(ASPublicKeyCredentialClientData.CrossOriginValue.sameOriginWithAncestors != .crossOrigin)
    precondition(ASPublicKeyCredentialClientDataCrossOriginValue.notSet.rawValue == 0)
    precondition(ASAuthorizationPublicKeyCredentialAttestationKind(rawValue: "x").rawValue == "x")
    precondition(ASAuthorizationPublicKeyCredentialResidentKeyPreference("y").rawValue == "y")
    precondition(ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: "z").rawValue == "z")
    _ = ASCOSEAlgorithmIdentifier(rawValue: -7)
    _ = ASCOSEEllipticCurveIdentifier(1)
    _ = ASAuthorizationProviderAuthorizationOperation.configurationRemoved
    _ = ASAuthorizationProviderAuthorizationOperation.directRequest
}
