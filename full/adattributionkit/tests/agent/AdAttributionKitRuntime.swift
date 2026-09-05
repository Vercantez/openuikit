import AdAttributionKit
import Foundation

private let eventTimeout = DispatchTimeInterval.seconds(5)

private func requireError(
    _ body: () async throws -> Void,
    _ expected: AdAttributionKitError,
    file: StaticString = #file,
    line: UInt = #line
) async {
    do {
        try await body()
        fatalError("expected \(expected) at \(file):\(line)")
    } catch let error as AdAttributionKitError {
        precondition(error == expected, "got \(error) expected \(expected) at \(file):\(line)")
        precondition(error != AdAttributionKitError.unknown || expected == .unknown)
    } catch {
        fatalError("wrong error type \(error) at \(file):\(line)")
    }
}

private func base64URL(_ data: Data) -> String {
    let encoded = data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
    return encoded
}

private func compactJWS(header: Data, payload: Data, signature: Data) -> String {
    "\(base64URL(header)).\(base64URL(payload)).\(base64URL(signature))"
}

private func jsonData(_ object: [String: Any]) -> Data {
    try! JSONSerialization.data(withJSONObject: object, options: [])
}

private func forgedCompactJWS() -> String {
    compactJWS(
        header: jsonData(["alg": "ES256", "kid": "test-key"]),
        payload: jsonData(["ad-network-id": "example.network"]),
        signature: Data(repeating: 0, count: 32)
    )
}

private func assertErrorSurface() {
    let cases: [AdAttributionKitError] = [
        .missingAttributionView,
        .impressionExpired,
        .invalidConversionTag,
        .conversionTagNotSupported,
        .invalidImpressionJWSHeader,
        .invalidImpressionJWSPayload,
        .invalidImpressionJWSSignature,
        .invalidImpressionJWSComponents,
        .unknown,
    ]
    precondition(Set(cases).count == 9)
    precondition(AdAttributionKitError.unknown == AdAttributionKitError.unknown)
    precondition(AdAttributionKitError.unknown != .invalidImpressionJWSSignature)
    precondition(AdAttributionKitError.unknown != .missingAttributionView)

    var hasher = Hasher()
    for item in cases {
        item.hash(into: &hasher)
        _ = item.hashValue
        _ = item.description
        _ = item.localizedDescription
        precondition(!item.description.isEmpty)
    }
    _ = hasher.finalize()
    precondition(AdAttributionKitError.unknown.description == "unknown")
}

private func assertCoarseConversionValue() {
    precondition(CoarseConversionValue.low.rawValue == "low")
    precondition(CoarseConversionValue.medium.rawValue == "medium")
    precondition(CoarseConversionValue.high.rawValue == "high")
    precondition(CoarseConversionValue(rawValue: "low") == .low)
    precondition(CoarseConversionValue(rawValue: "medium") == .medium)
    precondition(CoarseConversionValue(rawValue: "high") == .high)
    precondition(CoarseConversionValue(rawValue: "LOW") == nil)
    precondition(CoarseConversionValue.low != .high)

    let encoded = try! JSONEncoder().encode(CoarseConversionValue.low)
    let decoded = try! JSONDecoder().decode(CoarseConversionValue.self, from: encoded)
    precondition(decoded == .low)
    let quoted = try! JSONEncoder().encode(CoarseConversionValue.medium)
    precondition(String(data: quoted, encoding: .utf8) == "\"medium\"")

    var hasher = Hasher()
    CoarseConversionValue.high.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Set([CoarseConversionValue.low, .medium, .high]).count == 3)
}

private func assertPostbackUpdate() {
    let install = PostbackUpdate(
        fineConversionValue: 20,
        lockPostback: false,
        conversionTypes: [.install]
    )
    precondition(install.fineConversionValue == 20)
    precondition(install.lockPostback == false)
    precondition(install.coarseConversionValue == nil)
    precondition(install.conversionTypes == [.install])
    precondition(install.conversionTag == nil)

    let tagged = PostbackUpdate(
        fineConversionValue: 12,
        lockPostback: true,
        conversionTag: "campaign-tag",
        coarseConversionValue: .high,
        conversionTypes: [.reengagement]
    )
    precondition(tagged.fineConversionValue == 12)
    precondition(tagged.lockPostback == true)
    precondition(tagged.conversionTag == "campaign-tag")
    precondition(tagged.coarseConversionValue == .high)
    precondition(tagged.conversionTypes == [.reengagement])

    let defaults = PostbackUpdate(fineConversionValue: 0, lockPostback: false)
    precondition(defaults.coarseConversionValue == nil)
    precondition(defaults.conversionTypes == nil)
    precondition(defaults.conversionTag == nil)

    precondition(PostbackUpdate.ConversionType.install.rawValue == "install")
    precondition(PostbackUpdate.ConversionType.reengagement.rawValue == "reengagement")
    precondition(PostbackUpdate.ConversionType(rawValue: "install") == .install)
    precondition(PostbackUpdate.ConversionType(rawValue: "reengagement") == .reengagement)
    precondition(PostbackUpdate.ConversionType(rawValue: "re-engagement") == nil)
    precondition(PostbackUpdate.ConversionType.install != .reengagement)

    var hasher = Hasher()
    PostbackUpdate.ConversionType.install.hash(into: &hasher)
    _ = hasher.finalize()
}

private func assertSupportFlags() {
    precondition(AppImpression.isSupported == false)
    precondition(Postback.isSupported == false)
    let _: AppImpression.ID.Type = UUID.self
}

private func assertReengagementParameter() {
    precondition(Postback.reengagementOpenURLParameter == "AdAttributionKitReengagementOpen")
    let url = URL(string: "https://example.com/open?AdAttributionKitReengagementOpen=1")!
    let items = URLComponents(url: url, resolvingAgainstBaseURL: true)!.queryItems!
    precondition(items.contains { $0.name == Postback.reengagementOpenURLParameter })
}

private func rejectMalformedJWS() async {
    await requireError(
        { _ = try await AppImpression(compactJWS: "") },
        .invalidImpressionJWSComponents
    )
    await requireError(
        { _ = try await AppImpression(compactJWS: "only-one-part") },
        .invalidImpressionJWSComponents
    )
    await requireError(
        { _ = try await AppImpression(compactJWS: "two.parts") },
        .invalidImpressionJWSComponents
    )
    await requireError(
        { _ = try await AppImpression(compactJWS: "a.b.c.d") },
        .invalidImpressionJWSComponents
    )
    await requireError(
        { _ = try await AppImpression(compactJWS: ".payload.sig") },
        .invalidImpressionJWSHeader
    )

    let payload = base64URL(jsonData(["ad-network-id": "example.network"]))
    let signature = base64URL(Data(repeating: 1, count: 16))
    await requireError(
        { _ = try await AppImpression(compactJWS: "not-b64.\(payload).\(signature)") },
        .invalidImpressionJWSHeader
    )
    await requireError(
        { _ = try await AppImpression(compactJWS: "\(base64URL(Data("not-json".utf8))).\(payload).\(signature)") },
        .invalidImpressionJWSHeader
    )
    await requireError(
        { _ = try await AppImpression(compactJWS: "\(base64URL(Data("[]".utf8))).\(payload).\(signature)") },
        .invalidImpressionJWSHeader
    )

    let header = base64URL(jsonData(["alg": "ES256"]))
    await requireError(
        { _ = try await AppImpression(compactJWS: "\(header)..\(signature)") },
        .invalidImpressionJWSPayload
    )
    await requireError(
        { _ = try await AppImpression(compactJWS: "\(header).$$$$.\(signature)") },
        .invalidImpressionJWSPayload
    )
    await requireError(
        { _ = try await AppImpression(compactJWS: "\(header).\(base64URL(Data("[]".utf8))).\(signature)") },
        .invalidImpressionJWSPayload
    )
}

private func rejectForgedJWS() async {
    let forged = forgedCompactJWS()
    await requireError(
        { _ = try await AppImpression(compactJWS: forged) },
        .invalidImpressionJWSSignature
    )

    let emptySignature = compactJWS(
        header: jsonData(["alg": "ES256"]),
        payload: jsonData(["source-identifier": 42]),
        signature: Data()
    )
    await requireError(
        { _ = try await AppImpression(compactJWS: emptySignature) },
        .invalidImpressionJWSSignature
    )
}

private func rejectPostbackUpdates() async {
    await requireError(
        { try await Postback.updateConversionValue(7, lockPostback: false) },
        .unknown
    )
    await requireError(
        {
            try await Postback.updateConversionValue(
                3,
                coarseConversionValue: .medium,
                lockPostback: true
            )
        },
        .unknown
    )
    let update = PostbackUpdate(
        fineConversionValue: 1,
        lockPostback: false,
        conversionTag: "tag",
        coarseConversionValue: .low,
        conversionTypes: [.install, .reengagement]
    )
    await requireError(
        { try await Postback.updateConversionValue(update) },
        .unknown
    )
}

private func rejectConcurrentJWSAndPostback() async {
    let forged = forgedCompactJWS()
    await withTaskGroup(of: AdAttributionKitError.self) { group in
        for _ in 0..<8 {
            group.addTask {
                do {
                    _ = try await AppImpression(compactJWS: forged)
                    fatalError("forged JWS must not succeed")
                } catch let error as AdAttributionKitError {
                    return error
                } catch {
                    fatalError("unexpected error \(error)")
                }
            }
            group.addTask {
                do {
                    try await Postback.updateConversionValue(0, lockPostback: false)
                    fatalError("postback update must not succeed")
                } catch let error as AdAttributionKitError {
                    return error
                } catch {
                    fatalError("unexpected error \(error)")
                }
            }
        }
        var impressionFails = 0
        var postbackFails = 0
        for await error in group {
            switch error {
            case .invalidImpressionJWSSignature:
                impressionFails += 1
            case .unknown:
                postbackFails += 1
            default:
                fatalError("unexpected concurrent error \(error)")
            }
        }
        precondition(impressionFails == 8)
        precondition(postbackFails == 8)
    }
}

func adAttributionKitRuntimeMain() async {
    assertErrorSurface()
    assertCoarseConversionValue()
    assertPostbackUpdate()
    assertSupportFlags()
    assertReengagementParameter()
    await rejectMalformedJWS()
    await rejectForgedJWS()
    await rejectPostbackUpdates()
    await rejectConcurrentJWSAndPostback()
    print("CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean")
    print("ADATTRIBUTIONKIT_AGENT_RUNTIME_OK")
}

let runtimeSemaphore = DispatchSemaphore(value: 0)
Task {
    await adAttributionKitRuntimeMain()
    runtimeSemaphore.signal()
}
precondition(
    runtimeSemaphore.wait(timeout: .now() + eventTimeout) == .success,
    "AdAttributionKit runtime probe timed out"
)
