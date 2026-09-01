import AdAttributionKit
import Foundation

try await AdAttributionKitRuntime.run()

enum AdAttributionKitRuntime {
    static func run() async throws {
        exerciseErrors()
        try exerciseCoarseValues()
        exercisePostbackUpdates()
        await exercisePostbacks()
        try await exerciseImpressions()
        print("ADATTRIBUTIONKIT_AGENT_RUNTIME_OK")
    }

    private static func expectError<T>(
        _ work: () async throws -> T,
        _ expected: AdAttributionKitError
    ) async {
        do {
            _ = try await work()
            fatalError("expected \(expected)")
        } catch let error as AdAttributionKitError {
            guard error == expected else {
                fatalError("expected \(expected), got \(error)")
            }
        } catch {
            fatalError("expected AdAttributionKitError, got \(error)")
        }
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func compactJWS(
        header: [String: Any],
        payload: [String: Any],
        signature: Data = Data([0x01, 0x02, 0x03])
    ) throws -> String {
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        return [
            base64URLEncode(headerData),
            base64URLEncode(payloadData),
            base64URLEncode(signature)
        ].joined(separator: ".")
    }

    private static func documentedPayload(
        eligible: Bool? = true
    ) -> [String: Any] {
        var payload: [String: Any] = [
            "impression-identifier": "7aa9f8cc-5689-4c02-b963-22ca22136015",
            "publisher-item-identifier": 0,
            "impression-type": "app-impression",
            "ad-network-identifier": "example.adattributionkit",
            "source-identifier": 5239,
            "timestamp": 1_679_790_422_446,
            "advertised-item-identifier": 1_108_187_390
        ]
        if let eligible {
            payload["eligible-for-re-engagement"] = eligible
        }
        return payload
    }

    private static func exerciseErrors() {
        let cases: [AdAttributionKitError] = [
            .unknown,
            .missingAttributionView,
            .impressionExpired,
            .invalidImpressionJWSHeader,
            .invalidImpressionJWSPayload,
            .invalidImpressionJWSSignature,
            .invalidImpressionJWSComponents,
            .conversionTagNotSupported,
            .invalidConversionTag
        ]
        for (index, error) in cases.enumerated() {
            precondition(error == error)
            precondition(!(error != error))
            precondition(!error.description.isEmpty)
            precondition(!error.localizedDescription.isEmpty)
            _ = error.hashValue
            var hasher = Hasher()
            error.hash(into: &hasher)
            _ = hasher.finalize()
            if index > 0 {
                precondition(error != cases[index - 1])
            }
        }
        precondition(AdAttributionKitError.unknown.description.contains("unknown"))
        precondition(AdAttributionKitError.missingAttributionView.description.contains("missing"))
        precondition(AdAttributionKitError.impressionExpired.description.contains("expired"))
        precondition(AdAttributionKitError.invalidConversionTag.description.contains("invalid conversion tag"))
    }

    private static func exerciseCoarseValues() throws {
        let values: [CoarseConversionValue] = [.low, .medium, .high]
        precondition(values.map(\.rawValue) == ["low", "medium", "high"])
        precondition(CoarseConversionValue(rawValue: "low") == .low)
        precondition(CoarseConversionValue(rawValue: "medium") == .medium)
        precondition(CoarseConversionValue(rawValue: "high") == .high)
        precondition(CoarseConversionValue(rawValue: "unknown") == nil)
        precondition(CoarseConversionValue.low != .high)

        let encoded = try JSONEncoder().encode(CoarseConversionValue.medium)
        let decoded = try JSONDecoder().decode(CoarseConversionValue.self, from: encoded)
        precondition(decoded == .medium)

        var hasher = Hasher()
        CoarseConversionValue.high.hash(into: &hasher)
        _ = hasher.finalize()
        _ = CoarseConversionValue.low.hashValue
    }

    private static func exercisePostbackUpdates() {
        let defaults = PostbackUpdate(fineConversionValue: 7, lockPostback: false)
        precondition(defaults.fineConversionValue == 7)
        precondition(defaults.lockPostback == false)
        precondition(defaults.coarseConversionValue == nil)
        precondition(defaults.conversionTypes == nil)
        precondition(defaults.conversionTag == nil)

        let typed = PostbackUpdate(
            fineConversionValue: 12,
            lockPostback: true,
            coarseConversionValue: .high,
            conversionTypes: [.install, .reengagement]
        )
        precondition(typed.lockPostback)
        precondition(typed.coarseConversionValue == .high)
        precondition(typed.conversionTypes == [.install, .reengagement])

        let tagged = PostbackUpdate(
            fineConversionValue: 3,
            lockPostback: false,
            conversionTag: "tag-1",
            coarseConversionValue: .low,
            conversionTypes: [.reengagement]
        )
        precondition(tagged.conversionTag == "tag-1")
        precondition(tagged.coarseConversionValue == .low)

        precondition(PostbackUpdate.ConversionType(rawValue: "install") == .install)
        precondition(PostbackUpdate.ConversionType(rawValue: "reengagement") == .reengagement)
        precondition(PostbackUpdate.ConversionType(rawValue: "download") == nil)
        precondition(PostbackUpdate.ConversionType.install != .reengagement)
        precondition(PostbackUpdate.ConversionType.install.rawValue == "install")
        var hasher = Hasher()
        PostbackUpdate.ConversionType.reengagement.hash(into: &hasher)
        _ = hasher.finalize()
        _ = PostbackUpdate.ConversionType.install.hashValue
    }

    private static func exercisePostbacks() async {
        precondition(!Postback.isSupported)
        precondition(Postback.reengagementOpenURLParameter == "AdAttributionKitReengagementOpen")

        await expectError({
            try await Postback.updateConversionValue(8, lockPostback: true)
        }, .unknown)
        await expectError({
            try await Postback.updateConversionValue(
                8,
                coarseConversionValue: .medium,
                lockPostback: false
            )
        }, .unknown)
        await expectError({
            try await Postback.updateConversionValue(
                PostbackUpdate(fineConversionValue: 1, lockPostback: false)
            )
        }, .unknown)
        await expectError({
            try await Postback.updateConversionValue(
                PostbackUpdate(
                    fineConversionValue: 1,
                    lockPostback: true,
                    conversionTag: "tag-1"
                )
            )
        }, .conversionTagNotSupported)
    }

    private static func exerciseImpressions() async throws {
        precondition(!AppImpression.isSupported)

        await expectError({
            try await AppImpression(compactJWS: "not-a-jws")
        }, .invalidImpressionJWSComponents)
        await expectError({
            try await AppImpression(compactJWS: "a.b")
        }, .invalidImpressionJWSComponents)
        await expectError({
            try await AppImpression(compactJWS: "a.b.c.d")
        }, .invalidImpressionJWSComponents)

        await expectError({
            try await AppImpression(compactJWS: try compactJWS(
                header: ["alg": "none", "kid": "example.adattributionkit"],
                payload: documentedPayload()
            ))
        }, .invalidImpressionJWSHeader)
        await expectError({
            try await AppImpression(compactJWS: try compactJWS(
                header: ["alg": "ES256"],
                payload: documentedPayload()
            ))
        }, .invalidImpressionJWSHeader)

        var badType = documentedPayload()
        badType["impression-type"] = "web-impression"
        await expectError({
            try await AppImpression(compactJWS: try compactJWS(
                header: ["alg": "ES256", "kid": "example.adattributionkit"],
                payload: badType
            ))
        }, .invalidImpressionJWSPayload)

        var mismatchedNetwork = documentedPayload()
        mismatchedNetwork["ad-network-identifier"] = "other.adattributionkit"
        await expectError({
            try await AppImpression(compactJWS: try compactJWS(
                header: ["alg": "ES256", "kid": "example.adattributionkit"],
                payload: mismatchedNetwork
            ))
        }, .invalidImpressionJWSPayload)

        let header = ["alg": "ES256", "kid": "example.adattributionkit"]
        let emptySignature = [
            base64URLEncode(try JSONSerialization.data(withJSONObject: header)),
            base64URLEncode(try JSONSerialization.data(withJSONObject: documentedPayload())),
            ""
        ].joined(separator: ".")
        await expectError({
            try await AppImpression(compactJWS: emptySignature)
        }, .invalidImpressionJWSSignature)

        let compact = try compactJWS(
            header: header,
            payload: documentedPayload()
        )
        let impression = try await AppImpression(compactJWS: compact)
        precondition(impression.id == UUID(uuidString: "7aa9f8cc-5689-4c02-b963-22ca22136015"))
        precondition(impression.publisherItemID == 0)
        precondition(impression.advertisedItemID == 1_108_187_390)
        precondition(impression.sourceID == 5239)
        precondition(impression.keyID == "example.adattributionkit")
        precondition(impression.adNetworkID == "example.adattributionkit")
        precondition(impression.eligibleForReengagement)
        precondition(impression.compactJWSRepresentation == compact)
        let expectedTimestamp = Date(timeIntervalSince1970: 1_679_790_422_446 / 1000.0)
        precondition(impression.timestamp == expectedTimestamp)
        _ = impression.hashValue
        var hasher = Hasher()
        impression.hash(into: &hasher)
        _ = hasher.finalize()

        let same = try await AppImpression(compactJWS: compact)
        precondition(impression == same)
        precondition(!(impression != same))

        let ineligibleCompact = try compactJWS(
            header: header,
            payload: documentedPayload(eligible: nil)
        )
        let ineligible = try await AppImpression(compactJWS: ineligibleCompact)
        precondition(!ineligible.eligibleForReengagement)
        precondition(impression != ineligible)

        await expectError({
            try await impression.beginView()
        }, .missingAttributionView)
        await expectError({
            try await impression.endView()
        }, .missingAttributionView)
        await expectError({
            try await impression.handleTap()
        }, .missingAttributionView)
        await expectError({
            try await impression.handleTap(
                reengagementURL: URL(string: "https://example.com/reengage")!
            )
        }, .missingAttributionView)
    }
}
