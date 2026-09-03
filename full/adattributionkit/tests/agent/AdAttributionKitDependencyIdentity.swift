import AdAttributionKit
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build AdAttributionKit with that Foundation on `-I` / `-L`.
// 3. Link this file as a client that `import`s AdAttributionKit and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `ADATTRIBUTIONKIT_DEPENDENCY_IDENTITY_OK` and that
//    `libAdAttributionKit.dylib` was loaded.

private let eventTimeout = DispatchTimeInterval.seconds(5)

private func assertNotAdAttributionKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("AdAttributionKit."))
}

private func requireError(
    _ body: () async throws -> Void,
    _ expected: AdAttributionKitError
) async {
    do {
        try await body()
        fatalError("expected fail-closed \(expected)")
    } catch let error as AdAttributionKitError {
        precondition(error == expected)
        assertNotAdAttributionKitType(error as NSError)
    } catch {
        fatalError("unexpected error type \(error)")
    }
}

private func base64URL(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

private func passFoundationValues() {
    let now = Date()
    let uuid = UUID()
    let url = URL(string: "https://example.com/reengage")!
    let data = Data("adattributionkit".utf8)
    assertNotAdAttributionKitType(now)
    assertNotAdAttributionKitType(uuid)
    assertNotAdAttributionKitType(url)
    assertNotAdAttributionKitType(data)
    precondition(type(of: uuid) == UUID.self)
    precondition(type(of: url) == URL.self)
    precondition(type(of: data) == Data.self)
    _ = PostbackUpdate(
        fineConversionValue: 0,
        lockPostback: false,
        conversionTag: uuid.uuidString,
        conversionTypes: [.install]
    )
    precondition(
        URLComponents(url: url, resolvingAgainstBaseURL: false) != nil
    )
}

func adAttributionKitDependencyIdentityMain() async {
    passFoundationValues()
    precondition(AppImpression.isSupported == false)
    precondition(Postback.isSupported == false)
    precondition(Postback.reengagementOpenURLParameter == "AdAttributionKitReengagementOpen")

    let header = try! JSONSerialization.data(withJSONObject: ["alg": "ES256"])
    let payload = try! JSONSerialization.data(withJSONObject: ["ad-network-id": "example.network"])
    let forged = "\(base64URL(header)).\(base64URL(payload)).\(base64URL(Data(repeating: 9, count: 16)))"
    await requireError(
        { _ = try await AppImpression(compactJWS: forged) },
        .invalidImpressionJWSSignature
    )
    await requireError(
        { _ = try await AppImpression(compactJWS: "malformed") },
        .invalidImpressionJWSComponents
    )
    await requireError(
        { try await Postback.updateConversionValue(1, lockPostback: true) },
        .unknown
    )

    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<4 {
            group.addTask {
                await requireError(
                    { _ = try await AppImpression(compactJWS: forged) },
                    .invalidImpressionJWSSignature
                )
            }
            group.addTask {
                await requireError(
                    { try await Postback.updateConversionValue(0, lockPostback: false) },
                    .unknown
                )
            }
        }
        await group.waitForAll()
    }

    print("ADATTRIBUTIONKIT_DEPENDENCY_IDENTITY_OK")
}

let identitySemaphore = DispatchSemaphore(value: 0)
Task {
    await adAttributionKitDependencyIdentityMain()
    identitySemaphore.signal()
}
precondition(
    identitySemaphore.wait(timeout: .now() + eventTimeout) == .success,
    "AdAttributionKit dependency-identity probe timed out"
)
