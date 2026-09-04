import Dispatch
import Foundation
@_spi(OpenUIKitHost) import AuthenticationServices

final class ASLocked<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func store(_ value: Value) {
        lock.lock()
        self.value = value
        lock.unlock()
    }
}

func asAwait<T: Sendable>(_ body: @escaping @Sendable () async throws -> T) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    let box = ASLocked<Result<T, Error>?>(nil)
    Task.detached {
        do {
            box.store(.success(try await body()))
        } catch {
            box.store(.failure(error))
        }
        semaphore.signal()
    }
    precondition(
        semaphore.wait(timeout: .now() + 10) == .success,
        "async AuthenticationServices probe timed out"
    )
    guard let result = box.load() else {
        preconditionFailure("async AuthenticationServices probe did not complete")
    }
    return result
}

func asWait(_ semaphore: DispatchSemaphore, _ message: String) {
    precondition(semaphore.wait(timeout: .now() + 10) == .success, message)
}

func testASWebAuthenticationSessionErrorDomain() {
    precondition(
        ASWebAuthenticationSessionErrorDomain
            == "com.apple.AuthenticationServices.WebAuthenticationSession"
    )
    precondition(ASWebAuthenticationSessionError.errorDomain == ASWebAuthenticationSessionErrorDomain)
    precondition(ASWebAuthenticationSessionError._nsErrorDomain == ASWebAuthenticationSessionErrorDomain)
}

func testASWebAuthenticationSessionErrorCodes() {
    precondition(ASWebAuthenticationSessionError.Code.canceledLogin.rawValue == 1)
    precondition(ASWebAuthenticationSessionError.Code.presentationContextNotProvided.rawValue == 2)
    precondition(ASWebAuthenticationSessionError.Code.presentationContextInvalid.rawValue == 3)
    precondition(ASWebAuthenticationSessionError.canceledLogin == .canceledLogin)
    precondition(ASWebAuthenticationSessionError.presentationContextNotProvided == .presentationContextNotProvided)
    precondition(ASWebAuthenticationSessionError.presentationContextInvalid == .presentationContextInvalid)
    precondition(ASWebAuthenticationSessionError.Code(rawValue: 1) == .canceledLogin)
    precondition(ASWebAuthenticationSessionError.Code(rawValue: 4) == nil)
}

func testASWebAuthenticationSessionErrorEqualityAndHash() {
    let empty = ASWebAuthenticationSessionError(.canceledLogin)
    precondition(empty.errorCode == 1)
    precondition(empty.code == .canceledLogin)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.reason == "The web authentication session was canceled")

    let labeled = ASWebAuthenticationSessionError(.canceledLogin, reason: "host-cancel")
    precondition(labeled.reason == "host-cancel")
    precondition(labeled.userInfo[NSLocalizedDescriptionKey] as? String == "host-cancel")
    precondition(empty != labeled)
    precondition(empty.hashValue == labeled.hashValue)

    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    ASWebAuthenticationSessionError(.canceledLogin).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testASWebAuthenticationSessionErrorPatternMatch() {
    let error: any Error = ASWebAuthenticationSessionError(.presentationContextNotProvided)
    precondition(ASWebAuthenticationSessionError.Code.presentationContextNotProvided ~= error)
    precondition(!(ASWebAuthenticationSessionError.Code.canceledLogin ~= error))
    do {
        throw ASWebAuthenticationSessionError(.presentationContextInvalid)
    } catch let typed as ASWebAuthenticationSessionError where typed.code == .presentationContextInvalid {
        ()
    } catch {
        preconditionFailure("expected presentationContextInvalid")
    }
}

func testASWebAuthenticationSessionErrorNSErrorBridge() {
    let typed = ASWebAuthenticationSessionError(
        .presentationContextInvalid,
        reason: "bridge"
    )
    precondition(typed._nsError.domain == ASWebAuthenticationSessionErrorDomain)
    precondition(typed._nsError.code == 3)
    precondition(typed._nsError.userInfo[NSLocalizedDescriptionKey] as? String == "bridge")
}

func testASAuthorizationErrorDomainAndCodes() {
    precondition(ASAuthorizationErrorDomain == "ASAuthorizationErrorDomain")
    precondition(ASAuthorizationError.errorDomain == ASAuthorizationErrorDomain)
    precondition(ASAuthorizationError._nsErrorDomain == ASAuthorizationErrorDomain)
    precondition(ASAuthorizationError.Code.unknown.rawValue == 1000)
    precondition(ASAuthorizationError.Code.canceled.rawValue == 1001)
    precondition(ASAuthorizationError.Code.invalidResponse.rawValue == 1002)
    precondition(ASAuthorizationError.Code.notHandled.rawValue == 1003)
    precondition(ASAuthorizationError.Code.failed.rawValue == 1004)
    precondition(ASAuthorizationError.Code.notInteractive.rawValue == 1005)
    precondition(ASAuthorizationError.Code.matchedExcludedCredential.rawValue == 1006)
    precondition(ASAuthorizationError.Code.credentialImport.rawValue == 1007)
    precondition(ASAuthorizationError.Code.credentialExport.rawValue == 1008)
    precondition(ASAuthorizationError.Code.preferSignInWithApple.rawValue == 1009)
    precondition(ASAuthorizationError.Code.deviceNotConfiguredForPasskeyCreation.rawValue == 1010)
    let failed = ASAuthorizationError(.failed)
    precondition(failed.code == .failed)
    precondition(failed.errorCode == 1004)
    precondition(ASAuthorizationError.failed ~= failed)
}

func testASExtensionErrorDomainAndCodes() {
    precondition(ASExtensionErrorDomain == "ASExtensionErrorDomain")
    precondition(ASExtensionLocalizedFailureReasonErrorKey == "ASExtensionLocalizedFailureReasonErrorKey")
    precondition(ASExtensionError.Code.failed.rawValue == 0)
    precondition(ASExtensionError.Code.userCanceled.rawValue == 1)
    precondition(ASExtensionError.Code.userInteractionRequired.rawValue == 100)
    precondition(ASExtensionError.Code.credentialIdentityNotFound.rawValue == 101)
    precondition(ASExtensionError.Code.matchedExcludedCredential.rawValue == 102)
    let canceled = ASExtensionError(.userCanceled)
    precondition(canceled.code == .userCanceled)
    precondition(ASExtensionError.userCanceled ~= canceled)
}

func testASCredentialIdentityStoreErrorDomainAndCodes() {
    precondition(ASCredentialIdentityStoreErrorDomain == "ASCredentialIdentityStoreErrorDomain")
    precondition(ASCredentialIdentityStoreError.Code.internalError.rawValue == 0)
    precondition(ASCredentialIdentityStoreError.Code.storeDisabled.rawValue == 1)
    precondition(ASCredentialIdentityStoreError.Code.storeBusy.rawValue == 2)
    let disabled = ASCredentialIdentityStoreError(.storeDisabled)
    precondition(disabled.code == .storeDisabled)
    precondition(ASCredentialIdentityStoreError.storeDisabled ~= disabled)
}

func testOverlayStringConstants() {
    precondition(ASCredentialImportToken == "ASCredentialImportToken")
    precondition(ASCredentialExchangeActivity == "ASCredentialExchangeActivity")
    precondition(
        ASAuthorizationAppleIDProviderCredentialRevokedNotification.rawValue
            == "ASAuthorizationAppleIDProviderCredentialRevokedNotification"
    )
    precondition(
        ASAuthorizationAppleIDProvider.credentialRevokedNotification
            == ASAuthorizationAppleIDProviderCredentialRevokedNotification
    )
}

func testWebAuthenticationCallbackMatching() {
    let scheme = ASWebAuthenticationSession.Callback.customScheme("icecubesapp")
    precondition(scheme.matchesURL(URL(string: "icecubesapp://oauth?code=1")!))
    precondition(!scheme.matchesURL(URL(string: "https://example.invalid/oauth")!))
    let https = ASWebAuthenticationSession.Callback.https(host: "example.invalid", path: "/cb")
    precondition(https.matchesURL(URL(string: "https://example.invalid/cb")!))
    precondition(https.matchesURL(URL(string: "https://example.invalid/cb/extra")!))
    precondition(!https.matchesURL(URL(string: "https://other.invalid/cb")!))
}

func testWebAuthenticationSessionStartFailsWithoutHost() {
    _ = asAwait { () -> Bool in
        AuthenticationServicesPortable._reset()
        return true
    }
    let semaphore = DispatchSemaphore(value: 0)
    let returned = ASLocked(false)
    let afterReturn = ASLocked(false)
    let callbacks = ASLocked(0)
    let urlBox = ASLocked<URL?>(nil)
    let errorBox = ASLocked<(any Error)?>(nil)
    let login = URL(string: "https://social.example/oauth/authorize")!
    let session = ASWebAuthenticationSession(
        url: login,
        callbackURLScheme: "icecubesapp",
        completionHandler: { url, error in
            afterReturn.store(returned.load())
            callbacks.store(callbacks.load() + 1)
            urlBox.store(url)
            errorBox.store(error)
            semaphore.signal()
        }
    )
    session.prefersEphemeralWebBrowserSession = true
    session.additionalHeaderFields = ["X-Test": "1"]
    precondition(session.canStart)
    let started = session.start()
    returned.store(true)
    precondition(started)
    asWait(semaphore, "web authentication completion did not run")
    precondition(afterReturn.load())
    precondition(callbacks.load() == 1)
    precondition(urlBox.load() == nil)
    let typed = errorBox.load() as? ASWebAuthenticationSessionError
    precondition(typed?.code == .presentationContextNotProvided)
    precondition(!session.canStart)
    precondition(!session.start())
}

func testWebAuthenticationSessionCancelDeliversCanceledLogin() {
    _ = asAwait { () -> Bool in
        AuthenticationServicesPortable._reset()
        return true
    }
    let semaphore = DispatchSemaphore(value: 0)
    let errorBox = ASLocked<(any Error)?>(nil)
    let session = ASWebAuthenticationSession(
        URL: URL(string: "https://social.example/oauth/authorize")!,
        callbackURLScheme: "icecubesapp",
        completionHandler: { _, error in
            errorBox.store(error)
            semaphore.signal()
        }
    )
    session.cancel()
    asWait(semaphore, "cancel completion did not run")
    let typed = errorBox.load() as? ASWebAuthenticationSessionError
    precondition(typed?.code == .canceledLogin)
    precondition(!session.canStart)
    precondition(!session.start())
}

func testWebAuthenticationSessionHTTPSCallbackRejectedWithoutHostScheme() {
    _ = asAwait { () -> Bool in
        AuthenticationServicesPortable._reset()
        return AuthenticationServicesPortable._installEventHandler { _ in }
    }
    let semaphore = DispatchSemaphore(value: 0)
    let errorBox = ASLocked<(any Error)?>(nil)
    let callback = ASWebAuthenticationSession.Callback.https(host: "example.invalid", path: "/cb")
    let session = ASWebAuthenticationSession(
        url: URL(string: "https://social.example/oauth/authorize")!,
        callback: callback,
        completionHandler: { _, error in
            errorBox.store(error)
            semaphore.signal()
        }
    )
    precondition(session.start())
    asWait(semaphore, "https callback session did not complete")
    let typed = errorBox.load() as? ASWebAuthenticationSessionError
    precondition(typed?.code == .presentationContextInvalid)
}

func testPortableAuthenticateFailsWithoutHost() {
    _ = asAwait { () -> Bool in
        AuthenticationServicesPortable._reset()
        return true
    }
    let session = WebAuthenticationSession()
    let result = asAwait { () -> URL in
        try await session.authenticate(
            using: URL(string: "https://social.example/oauth/authorize")!,
            callbackURLScheme: "icecubesapp"
        )
    }
    guard case .failure(let error as ASWebAuthenticationSessionError) = result else {
        preconditionFailure("expected presentationContextNotProvided")
    }
    precondition(error.code == .presentationContextNotProvided)
}

func testPortableHostCompleteAndSchemeMismatch() {
    let events = ASLocked<[AuthenticationServicesPortable.Event]>([])
    _ = asAwait { () -> Bool in
        AuthenticationServicesPortable._reset()
        return AuthenticationServicesPortable._installEventHandler { event in
            var snapshot = events.load()
            snapshot.append(event)
            events.store(snapshot)
        }
    }
    let login = URL(string: "https://social.example/oauth/authorize")!
    let session = WebAuthenticationSession()
    let success = asAwait { () -> URL in
        async let value = session.authenticate(
            using: login,
            callbackURLScheme: "icecubesapp",
            preferredBrowserSession: .ephemeral
        )
        for _ in 0..<200 where events.load().isEmpty {
            await Task.yield()
        }
        guard case .start(let request) = events.load().first else {
            preconditionFailure("host never received start")
        }
        precondition(request.url == login)
        precondition(request.callbackURLScheme == "icecubesapp")
        precondition(request.prefersEphemeralBrowserSession)
        precondition(AuthenticationServicesPortable.hasActiveRequest)
        precondition(!AuthenticationServicesPortable._installEventHandler { _ in })
        AuthenticationServicesPortable._hostDidComplete(
            requestID: request.id,
            callbackURL: URL(string: "icecubesapp://oauth?code=portable")!
        )
        return try await value
    }
    guard case .success(let callback) = success else {
        preconditionFailure("expected host-driven callback, got \(success)")
    }
    precondition(callback.absoluteString == "icecubesapp://oauth?code=portable")

    events.store([])
    let mismatch = asAwait { () -> URL in
        async let value = session.authenticate(
            using: login,
            callbackURLScheme: "icecubesapp"
        )
        for _ in 0..<200 where events.load().isEmpty {
            await Task.yield()
        }
        guard case .start(let request) = events.load().first else {
            preconditionFailure("host never received mismatch start")
        }
        AuthenticationServicesPortable._hostDidComplete(
            requestID: request.id,
            callbackURL: URL(string: "wrong://oauth?code=forged")!
        )
        return try await value
    }
    guard case .failure(let error as ASWebAuthenticationSessionError) = mismatch else {
        preconditionFailure("expected scheme mismatch")
    }
    precondition(error.code == .presentationContextInvalid)

    _ = asAwait { () -> Bool in
        AuthenticationServicesPortable._reset()
        return true
    }
}

func testPortableInvalidURLAndConcurrentRequest() {
    let events = ASLocked<[AuthenticationServicesPortable.Event]>([])
    _ = asAwait { () -> Bool in
        AuthenticationServicesPortable._reset()
        return AuthenticationServicesPortable._installEventHandler { event in
            var snapshot = events.load()
            snapshot.append(event)
            events.store(snapshot)
        }
    }
    let session = WebAuthenticationSession()
    let invalid = asAwait { () -> URL in
        try await session.authenticate(
            using: URL(fileURLWithPath: "/tmp/not-web-auth"),
            callbackURLScheme: "icecubesapp"
        )
    }
    guard case .failure(let error as ASWebAuthenticationSessionError) = invalid else {
        preconditionFailure("expected invalid URL")
    }
    precondition(error.code == .presentationContextInvalid)

    let login = URL(string: "https://social.example/oauth/authorize")!
    let second = asAwait { () -> URL in
        async let first = session.authenticate(using: login, callbackURLScheme: "icecubesapp")
        for _ in 0..<200 where events.load().isEmpty {
            await Task.yield()
        }
        do {
            _ = try await session.authenticate(using: login, callbackURLScheme: "second")
            preconditionFailure("expected concurrent rejection")
        } catch let overlap as ASWebAuthenticationSessionError {
            precondition(overlap.code == .presentationContextInvalid)
        } catch {
            preconditionFailure("unexpected concurrent error \(error)")
        }
        guard case .start(let request) = events.load().first else {
            preconditionFailure("missing active request")
        }
        AuthenticationServicesPortable._hostDidCancel(requestID: request.id)
        return try await first
    }
    guard case .failure(let canceled as ASWebAuthenticationSessionError) = second else {
        preconditionFailure("expected canceledLogin from host cancel")
    }
    precondition(canceled.code == .canceledLogin)
    _ = asAwait { () -> Bool in
        AuthenticationServicesPortable._reset()
        return true
    }
}

func testHostCallbackQueueLabel() {
    precondition(
        AuthenticationServicesHostCallback.queue.label
            == "org.openuikit.AuthenticationServices.host-callback"
    )
}

func testBrowserSessionEquality() {
    precondition(WebAuthenticationSession.BrowserSession.shared == .shared)
    precondition(WebAuthenticationSession.BrowserSession.ephemeral == .ephemeral)
    precondition(WebAuthenticationSession.BrowserSession.shared != .ephemeral)
}
