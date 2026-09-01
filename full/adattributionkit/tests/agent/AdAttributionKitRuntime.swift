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

    private static func documentedPayload() -> [String: Any] {
        [
            "impression-identifier": "7aa9f8cc-5689-4c02-b963-22ca22136015",
            "publisher-item-identifier": 0,
            "impression-type": "app-impression",
            "ad-network-identifier": "example.adattributionkit",
            "source-identifier": 5239,
            "timestamp": 1_679_790_422_446,
            "advertised-item-identifier": 1_108_187_390,
            "eligible-for-re-engagement": true
        ]
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
            _ = error.hashValue
            var hasher = Hasher()
            error.hash(into: &hasher)
            _ = hasher.finalize()
            if index > 0 {
                precondition(error != cases[index - 1])
            }
        }
    }

    private static func exerciseCoarseValues() throws {
        let values: [CoarseConversionValue] = [.low, .medium, .high]
        for value in values {
            precondition(CoarseConversionValue(rawValue: value.rawValue) == value)
        }
        precondition(CoarseConversionValue(rawValue: "not-a-coarse-value") == nil)
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

        let install = PostbackUpdate.ConversionType.install
        let reengagement = PostbackUpdate.ConversionType.reengagement
        precondition(PostbackUpdate.ConversionType(rawValue: install.rawValue) == install)
        precondition(PostbackUpdate.ConversionType(rawValue: reengagement.rawValue) == reengagement)
        precondition(PostbackUpdate.ConversionType(rawValue: "not-a-conversion-type") == nil)
        precondition(install != reengagement)
        var hasher = Hasher()
        reengagement.hash(into: &hasher)
        _ = hasher.finalize()
        _ = install.hashValue
    }

    private static func exercisePostbacks() async {
        precondition(!Postback.isSupported)
        precondition(!Postback.reengagementOpenURLParameter.isEmpty)

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
            try await AppImpression(compactJWS: [
                base64URLEncode(Data("not-json".utf8)),
                base64URLEncode(try JSONSerialization.data(withJSONObject: documentedPayload())),
                base64URLEncode(Data([0x01]))
            ].joined(separator: "."))
        }, .invalidImpressionJWSHeader)

        await expectError({
            try await AppImpression(compactJWS: [
                base64URLEncode(try JSONSerialization.data(withJSONObject: ["alg": "ES256"])),
                base64URLEncode(try JSONSerialization.data(withJSONObject: ["not-an-object"])),
                base64URLEncode(Data([0x01]))
            ].joined(separator: "."))
        }, .invalidImpressionJWSPayload)

        let header: [String: Any] = ["alg": "ES256", "kid": "example.adattributionkit"]
        let emptySignature = [
            base64URLEncode(try JSONSerialization.data(withJSONObject: header)),
            base64URLEncode(try JSONSerialization.data(withJSONObject: documentedPayload())),
            ""
        ].joined(separator: ".")
        await expectError({
            try await AppImpression(compactJWS: emptySignature)
        }, .invalidImpressionJWSSignature)

        let forged = try compactJWS(
            header: header,
            payload: documentedPayload(),
            signature: Data([0xDE, 0xAD, 0xBE, 0xEF])
        )
        await expectError({
            try await AppImpression(compactJWS: forged)
        }, .invalidImpressionJWSSignature)

        let anotherForged = try compactJWS(
            header: ["alg": "ES256", "kid": "example.adattributionkit"],
            payload: documentedPayload(),
            signature: Data([0x00])
        )
        await expectError({
            try await AppImpression(compactJWS: anotherForged)
        }, .invalidImpressionJWSSignature)
    }
}
