import Dispatch
import Foundation
import AuthenticationServices

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
    precondition(typed?.code == .notInteractive)
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
