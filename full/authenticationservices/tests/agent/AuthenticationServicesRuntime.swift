@_spi(OpenUIKitHost) import AuthenticationServices
import Dispatch
import Foundation

// Schema v2 sealed host gate compiles LoadSmoke + *Tests.swift, not this file.
// Keep a host-SPI probe here so a later Linux runner can exercise the portable
// web-auth boundary and print AUTHENTICATIONSERVICES_AGENT_RUNTIME_OK.

private final class ASRLocked<Value>: @unchecked Sendable {
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

private func asrAwait<T: Sendable>(_ body: @escaping @Sendable () async throws -> T) -> Result<T, Error> {
    let semaphore = DispatchSemaphore(value: 0)
    let box = ASRLocked<Result<T, Error>?>(nil)
    Task.detached {
        do {
            box.store(.success(try await body()))
        } catch {
            box.store(.failure(error))
        }
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + 10) == .success, "portable probe timed out")
    guard let result = box.load() else {
        preconditionFailure("portable probe did not complete")
    }
    return result
}

private func asrRequire(
    _ expected: ASWebAuthenticationSessionError.Code,
    _ body: @escaping @Sendable () async throws -> URL
) {
    switch asrAwait(body) {
    case .success:
        preconditionFailure("authentication unexpectedly succeeded")
    case .failure(let error as ASWebAuthenticationSessionError):
        precondition(error.code == expected)
    case .failure(let error):
        preconditionFailure("unexpected error type: \(error)")
    }
}

func authenticationServicesRuntimeProbe() {
    let login = URL(string: "https://social.example/oauth/authorize")!
    let session = WebAuthenticationSession()

    _ = asrAwait { () -> Bool in
        AuthenticationServicesPortable._reset()
        return true
    }

    asrRequire(.presentationContextNotProvided) {
        try await session.authenticate(using: login, callbackURLScheme: "icecubesapp")
    }

    let events = ASRLocked<[AuthenticationServicesPortable.Event]>([])
    let installed = asrAwait { () -> Bool in
        AuthenticationServicesPortable._reset()
        return AuthenticationServicesPortable._installEventHandler { event in
            var snapshot = events.load()
            snapshot.append(event)
            events.store(snapshot)
        }
    }
    guard case .success(true) = installed else {
        preconditionFailure("host handler install failed")
    }

    let success = asrAwait { () -> URL in
        async let result = session.authenticate(
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
        precondition(request.prefersEphemeralBrowserSession)
        AuthenticationServicesPortable._hostDidComplete(
            requestID: request.id,
            callbackURL: URL(string: "icecubesapp://oauth?code=portable")!
        )
        return try await result
    }
    guard case .success(let callback) = success else {
        preconditionFailure("expected host-driven success, got \(success)")
    }
    precondition(callback.scheme == "icecubesapp")

    _ = asrAwait { () -> Bool in
        AuthenticationServicesPortable._reset()
        return true
    }
}

authenticationServicesRuntimeProbe()
print("AUTHENTICATIONSERVICES_AGENT_RUNTIME_OK")
