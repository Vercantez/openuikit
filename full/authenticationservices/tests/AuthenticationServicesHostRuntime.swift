@_spi(OpenUIKitHost) import AuthenticationServices
@_spi(OpenUIKitHost) import _AuthenticationServices_SwiftUI
import Foundation
import SwiftUI

private final class EventRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storedEvents: [AuthenticationServicesPortable.Event] = []
    var reentrantCompletion: URL?

    var events: [AuthenticationServicesPortable.Event] {
        lock.lock()
        defer { lock.unlock() }
        return storedEvents
    }

    func record(_ event: AuthenticationServicesPortable.Event) {
        lock.lock()
        storedEvents.append(event)
        let reentrantCompletion = self.reentrantCompletion
        lock.unlock()
        if case .cancel(let id) = event,
           let reentrantCompletion
        {
            AuthenticationServicesPortable._hostDidComplete(
                requestID: id,
                callbackURL: reentrantCompletion
            )
        }
    }
}

@main
@MainActor
private struct AuthenticationServicesHostRuntime {
    static func requireError(
        _ expected: ASWebAuthenticationSessionError.Code,
        operation: () async throws -> URL
    ) async {
        do {
            _ = try await operation()
            preconditionFailure("authentication unexpectedly succeeded")
        } catch let error as ASWebAuthenticationSessionError {
            precondition(error.code == expected)
        } catch {
            preconditionFailure("unexpected error type: \(error)")
        }
    }

    static func waitForStart(
        _ recorder: EventRecorder,
        after index: Int
    ) async -> AuthenticationServicesPortable.Request {
        for _ in 0..<100 where recorder.events.count <= index {
            await Task.yield()
        }
        guard recorder.events.count > index,
              case .start(let request) = recorder.events[index] else {
            preconditionFailure("host never received start event")
        }
        return request
    }

    static func main() async {
        let session = EnvironmentValues().webAuthenticationSession
        let loginURL = URL(string: "https://social.example/oauth/authorize")!

        AuthenticationServicesPortable._reset()
        await requireError(.presentationContextNotProvided) {
            try await session.authenticate(
                using: loginURL,
                callbackURLScheme: "icecubesapp"
            )
        }
        precondition(
            !AuthenticationServicesPortable._installEventHandler { _ in },
            "the host boundary must be installed before the first request"
        )

        AuthenticationServicesPortable._reset()
        let recorder = EventRecorder()
        precondition(AuthenticationServicesPortable._installEventHandler {
            recorder.record($0)
        })
        precondition(AuthenticationServicesPortable.isHostConfigured)

        let preCanceledTask = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await session.authenticate(
                using: loginURL,
                callbackURLScheme: "icecubesapp"
            )
        }
        await requireError(.canceledLogin) {
            try await preCanceledTask.value
        }
        precondition(recorder.events.isEmpty)

        let successTask = Task {
            try await session.authenticate(
                using: loginURL,
                callbackURLScheme: "icecubesapp",
                preferredBrowserSession: .ephemeral
            )
        }
        let successRequest = await waitForStart(recorder, after: 0)
        precondition(successRequest.url == loginURL)
        precondition(successRequest.callbackURLScheme == "icecubesapp")
        precondition(successRequest.prefersEphemeralBrowserSession)
        precondition(AuthenticationServicesPortable.hasActiveRequest)
        precondition(
            !AuthenticationServicesPortable._installEventHandler { _ in },
            "startup configuration must remain immutable"
        )
        let callback = URL(string: "icecubesapp://oauth?code=portable")!
        AuthenticationServicesPortable._hostDidComplete(
            requestID: successRequest.id,
            callbackURL: callback
        )
        let completedCallback = try! await successTask.value
        precondition(completedCallback == callback)
        precondition(!AuthenticationServicesPortable.hasActiveRequest)

        let mismatchIndex = recorder.events.count
        let mismatchTask = Task {
            try await session.authenticate(
                using: loginURL,
                callbackURLScheme: "icecubesapp"
            )
        }
        let mismatchRequest = await waitForStart(
            recorder,
            after: mismatchIndex
        )
        AuthenticationServicesPortable._hostDidComplete(
            requestID: mismatchRequest.id,
            callbackURL: URL(string: "wrong://oauth?code=forged")!
        )
        await requireError(.presentationContextInvalid) {
            try await mismatchTask.value
        }

        let activeIndex = recorder.events.count
        let activeTask = Task {
            try await session.authenticate(
                using: loginURL,
                callbackURLScheme: "icecubesapp"
            )
        }
        let activeRequest = await waitForStart(recorder, after: activeIndex)
        await requireError(.presentationContextInvalid) {
            try await session.authenticate(
                using: loginURL,
                callbackURLScheme: "second"
            )
        }
        recorder.reentrantCompletion = callback
        activeTask.cancel()
        // Deliberately race a direct callback with the queued main-actor
        // cleanup, while the host's cancel event also reenters completion.
        AuthenticationServicesPortable._hostDidComplete(
            requestID: activeRequest.id,
            callbackURL: callback
        )
        await requireError(.canceledLogin) { try await activeTask.value }
        for _ in 0..<100 where recorder.events.count == activeIndex + 1 {
            await Task.yield()
        }
        precondition(
            recorder.events.contains(.cancel(id: activeRequest.id))
        )
        recorder.reentrantCompletion = nil
        AuthenticationServicesPortable._hostDidComplete(
            requestID: activeRequest.id,
            callbackURL: callback
        )
        precondition(!AuthenticationServicesPortable.hasActiveRequest)

        await requireError(.presentationContextInvalid) {
            try await session.authenticate(
                using: URL(fileURLWithPath: "/tmp/not-web-auth"),
                callbackURLScheme: "icecubesapp"
            )
        }

        AuthenticationServicesPortable._reset()
        print(
            "AUTHENTICATIONSERVICES_HOST_OK "
                + "environment=default startup=locked "
                + "browser=host-driven callback=validated "
                + "cancellation=once unavailable=fail-closed"
        )
    }
}
