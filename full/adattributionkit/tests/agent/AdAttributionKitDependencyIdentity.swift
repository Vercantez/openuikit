import AdAttributionKit
import Foundation

try await AdAttributionKitDependencyIdentity.run()

/// Future clean-EC2 client probe. This file is not part of the isolated host
/// gate. That future run must: build guest Foundation (module + dylib) first,
/// compile AdAttributionKit with those `-I`/`-L` paths, link a client that
/// imports AdAttributionKit and Foundation, execute with `LD_LIBRARY_PATH`,
/// confirm `libAdAttributionKit.dylib` is loaded, and only then treat
/// `ADATTRIBUTIONKIT_DEPENDENCY_IDENTITY_OK` as integrated evidence.
enum AdAttributionKitDependencyIdentity {
    static func run() async throws {
        try await exerciseFoundationValues()
        try await exerciseMalformedAndForgedJWS()
        await exerciseConcurrentAsyncAndPostbackFailure()
        print("ADATTRIBUTIONKIT_DEPENDENCY_IDENTITY_OK")
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
        signature: Data
    ) throws -> String {
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        return [
            base64URLEncode(headerData),
            base64URLEncode(payloadData),
            base64URLEncode(signature)
        ].joined(separator: ".")
    }

    private static func expectImpressionRejection(
        _ compactJWS: String,
        _ expected: AdAttributionKitError
    ) async {
        do {
            _ = try await AppImpression(compactJWS: compactJWS)
            fatalError("forged or malformed compact JWS must not construct AppImpression")
        } catch let error as AdAttributionKitError {
            guard error == expected else {
                fatalError("expected \(expected), got \(error)")
            }
        } catch {
            fatalError("expected AdAttributionKitError, got \(error)")
        }
    }

    private static func exerciseFoundationValues() async throws {
        let impressionIdentifier = UUID()
        let issuedAt = Date(timeIntervalSince1970: 1_679_790_422.446)
        let forgedSignature = Data([0xC0, 0xFF, 0xEE, 0x01])
        var components = URLComponents()
        components.scheme = "https"
        components.host = "example.com"
        components.path = "/reengage"
        components.queryItems = [
            URLQueryItem(name: Postback.reengagementOpenURLParameter, value: "1")
        ]
        guard let reengagementURL = components.url else {
            fatalError("expected Foundation URL")
        }

        precondition(impressionIdentifier.uuidString.count == 36)
        precondition(issuedAt.timeIntervalSince1970 > 0)
        precondition(!forgedSignature.isEmpty)
        precondition(
            URLComponents(url: reengagementURL, resolvingAgainstBaseURL: false)?
                .queryItems?
                .contains(where: { $0.name == Postback.reengagementOpenURLParameter }) == true
        )

        let milliseconds = Int64((issuedAt.timeIntervalSince1970 * 1000.0).rounded())
        let forged = try compactJWS(
            header: ["alg": "ES256", "kid": "example.adattributionkit"],
            payload: [
                "impression-identifier": impressionIdentifier.uuidString,
                "publisher-item-identifier": 0,
                "impression-type": "app-impression",
                "ad-network-identifier": "example.adattributionkit",
                "source-identifier": 5239,
                "timestamp": milliseconds,
                "advertised-item-identifier": 1_108_187_390
            ],
            signature: forgedSignature
        )
        await expectImpressionRejection(forged, .invalidImpressionJWSSignature)
    }

    private static func exerciseMalformedAndForgedJWS() async throws {
        await expectImpressionRejection("not-a-jws", .invalidImpressionJWSComponents)
        await expectImpressionRejection("only.two", .invalidImpressionJWSComponents)

        let payload = try JSONSerialization.data(withJSONObject: ["impression-type": "app-impression"])
        await expectImpressionRejection(
            [
                base64URLEncode(Data("not-json".utf8)),
                base64URLEncode(payload),
                base64URLEncode(Data([0x01]))
            ].joined(separator: "."),
            .invalidImpressionJWSHeader
        )

        let header = try JSONSerialization.data(withJSONObject: ["alg": "ES256"])
        await expectImpressionRejection(
            [
                base64URLEncode(header),
                "%%%",
                base64URLEncode(Data([0x01]))
            ].joined(separator: "."),
            .invalidImpressionJWSPayload
        )

        let structurallyValidForged = try compactJWS(
            header: ["alg": "ES256", "kid": "example.adattributionkit"],
            payload: [
                "impression-identifier": UUID().uuidString,
                "publisher-item-identifier": 1,
                "impression-type": "app-impression",
                "ad-network-identifier": "example.adattributionkit",
                "source-identifier": 12,
                "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
                "advertised-item-identifier": 2
            ],
            signature: Data([0x11, 0x22, 0x33, 0x44])
        )
        await expectImpressionRejection(
            structurallyValidForged,
            .invalidImpressionJWSSignature
        )
    }

    private static func exerciseConcurrentAsyncAndPostbackFailure() async {
        let malformed = "not-a-jws"
        let forged: String
        do {
            forged = try compactJWS(
                header: ["alg": "ES256", "kid": "example.adattributionkit"],
                payload: ["impression-type": "app-impression"],
                signature: Data([0xAB, 0xCD])
            )
        } catch {
            fatalError("failed to encode forged compact JWS")
        }

        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                do {
                    _ = try await AppImpression(compactJWS: malformed)
                    return false
                } catch is AdAttributionKitError {
                    return true
                } catch {
                    return false
                }
            }
            group.addTask {
                do {
                    _ = try await AppImpression(compactJWS: forged)
                    return false
                } catch let error as AdAttributionKitError {
                    return error == .invalidImpressionJWSSignature
                } catch {
                    return false
                }
            }
            group.addTask {
                do {
                    try await Postback.updateConversionValue(4, lockPostback: false)
                    return false
                } catch let error as AdAttributionKitError {
                    return error == .unknown
                } catch {
                    return false
                }
            }
            group.addTask {
                do {
                    try await Postback.updateConversionValue(
                        4,
                        coarseConversionValue: .low,
                        lockPostback: true
                    )
                    return false
                } catch let error as AdAttributionKitError {
                    return error == .unknown
                } catch {
                    return false
                }
            }

            for await passed in group {
                precondition(passed, "concurrent fail-closed task did not reject")
            }
        }

        let callbackRejected = await withCheckedContinuation { continuation in
            Task {
                do {
                    try await Postback.updateConversionValue(
                        PostbackUpdate(fineConversionValue: 9, lockPostback: false)
                    )
                    continuation.resume(returning: false)
                } catch let error as AdAttributionKitError {
                    continuation.resume(returning: error == .unknown)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
        precondition(callbackRejected)
        precondition(!Postback.isSupported)
        precondition(!AppImpression.isSupported)
    }
}
