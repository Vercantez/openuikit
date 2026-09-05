import AdAttributionKit
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private final class ImpressionLocked<Value>: @unchecked Sendable {
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

private func requireImpressionError(
    _ body: @escaping () async throws -> Void,
    _ expected: AdAttributionKitError
) {
    let box = ImpressionLocked<AdAttributionKitError?>(nil)
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

private func base64URL(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

private func jsonData(_ object: [String: Any]) -> Data {
    try! JSONSerialization.data(withJSONObject: object, options: [])
}

private func compactJWS(header: Data, payload: Data, signature: Data) -> String {
    "\(base64URL(header)).\(base64URL(payload)).\(base64URL(signature))"
}

func testAppImpressionTypeIdentity() {
    _ = AppImpression.self
    precondition(type(of: AppImpression.isSupported) == Bool.self)
}

func testAppImpressionUnsupported() {
    precondition(AppImpression.isSupported == false)
}

func testAppImpressionIDType() {
    let _: AppImpression.ID.Type = UUID.self
    precondition(AppImpression.ID.self == UUID.self)
}

func testInitCompactJWSClassifiesAndRejects() {
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: "") },
        .invalidImpressionJWSComponents
    )
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: "only-one-part") },
        .invalidImpressionJWSComponents
    )
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: "two.parts") },
        .invalidImpressionJWSComponents
    )
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: "a.b.c.d") },
        .invalidImpressionJWSComponents
    )

    let payload = base64URL(jsonData(["ad-network-id": "example.network"]))
    let signature = base64URL(Data(repeating: 1, count: 16))
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: ".payload.sig") },
        .invalidImpressionJWSHeader
    )
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: "not-b64.\(payload).\(signature)") },
        .invalidImpressionJWSHeader
    )
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: "\(base64URL(Data("not-json".utf8))).\(payload).\(signature)") },
        .invalidImpressionJWSHeader
    )
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: "\(base64URL(Data("[]".utf8))).\(payload).\(signature)") },
        .invalidImpressionJWSHeader
    )

    let header = base64URL(jsonData(["alg": "ES256"]))
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: "\(header)..\(signature)") },
        .invalidImpressionJWSPayload
    )
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: "\(header).$$$$.\(signature)") },
        .invalidImpressionJWSPayload
    )
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: "\(header).\(base64URL(Data("[]".utf8))).\(signature)") },
        .invalidImpressionJWSPayload
    )

    let forged = compactJWS(
        header: jsonData(["alg": "ES256", "kid": "test-key"]),
        payload: jsonData(["ad-network-id": "example.network"]),
        signature: Data(repeating: 0, count: 32)
    )
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: forged) },
        .invalidImpressionJWSSignature
    )
    let emptySignature = compactJWS(
        header: jsonData(["alg": "ES256"]),
        payload: jsonData(["source-identifier": 42]),
        signature: Data()
    )
    requireImpressionError(
        { _ = try await AppImpression(compactJWS: emptySignature) },
        .invalidImpressionJWSSignature
    )
}
