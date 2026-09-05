import AdAttributionKit
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class PostbackLocked<Value>: @unchecked Sendable {
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

private func requirePostbackError(
    _ body: @escaping () async throws -> Void,
    _ expected: AdAttributionKitError
) {
    let box = PostbackLocked<AdAttributionKitError?>(nil)
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
    precondition(semaphore.wait(timeout: .now() + eventTimeout) == .success)
    guard let error = box.load() else {
        fatalError("missing AdAttributionKitError")
    }
    precondition(error == expected)
}

func testPostbackTypeIdentity() {
    _ = Postback.self
    precondition(type(of: Postback.isSupported) == Bool.self)
}

func testPostbackUnsupported() {
    precondition(Postback.isSupported == false)
}

func testReengagementOpenURLParameter() {
    precondition(Postback.reengagementOpenURLParameter == "AdAttributionKitReengagementOpen")
    let url = URL(string: "https://example.com/open?AdAttributionKitReengagementOpen=1")!
    let items = URLComponents(url: url, resolvingAgainstBaseURL: true)!.queryItems!
    precondition(items.contains { $0.name == Postback.reengagementOpenURLParameter })
}

func testUpdateConversionValueFineLock() {
    requirePostbackError(
        { try await Postback.updateConversionValue(7, lockPostback: false) },
        .unknown
    )
    requirePostbackError(
        { try await Postback.updateConversionValue(0, lockPostback: true) },
        .unknown
    )
}

func testUpdateConversionValueCoarse() {
    requirePostbackError(
        {
            try await Postback.updateConversionValue(
                3,
                coarseConversionValue: .medium,
                lockPostback: true
            )
        },
        .unknown
    )
    requirePostbackError(
        {
            try await Postback.updateConversionValue(
                63,
                coarseConversionValue: .low,
                lockPostback: false
            )
        },
        .unknown
    )
}

func testUpdateConversionValueStruct() {
    let update = PostbackUpdate(
        fineConversionValue: 1,
        lockPostback: false,
        conversionTag: "tag",
        coarseConversionValue: .low,
        conversionTypes: [.install, .reengagement]
    )
    requirePostbackError(
        { try await Postback.updateConversionValue(update) },
        .unknown
    )
}
