import AdAttributionKit
import Foundation

private let viewEventTimeout = DispatchTimeInterval.seconds(5)

private final class ViewLocked<Value>: @unchecked Sendable {
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

private func requireViewError(
    _ body: @escaping () async throws -> Void,
    _ expected: AdAttributionKitError
) {
    let box = ViewLocked<AdAttributionKitError?>(nil)
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        do {
            try await body()
            fatalError("expected \(expected)")
        } catch let error as AdAttributionKitError {
            box.store(error)
        } catch {
            fatalError("wrong error type \(error)")
        }
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + viewEventTimeout) == .success)
    guard let error = box.load() else {
        fatalError("missing AdAttributionKitError")
    }
    precondition(error == expected)
}

private func unverifiedImpression() -> AppImpression {
    AppImpression._unverifiedForTesting(
        publisherItemID: 11,
        advertisedItemID: 22,
        sourceID: 33,
        keyID: "test-key-id",
        adNetworkID: "example.network"
    )
}

func testAppImpressionBeginViewFailsClosed() {
    let impression = unverifiedImpression()
    requireViewError({ try await impression.beginView() }, .unknown)
}

func testAppImpressionEndViewFailsClosed() {
    let impression = unverifiedImpression()
    requireViewError({ try await impression.endView() }, .unknown)
}

func testAppImpressionHandleTapFailsClosed() {
    let impression = unverifiedImpression()
    requireViewError({ try await impression.handleTap() }, .missingAttributionView)
}

func testAppImpressionHandleTapReengagementFailsClosed() {
    let impression = unverifiedImpression()
    let url = URL(string: "https://example.com/open?AdAttributionKitReengagementOpen=1")!
    requireViewError(
        { try await impression.handleTap(reengagementURL: url) },
        .missingAttributionView
    )
}
