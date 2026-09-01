import Foundation

/// An attributable impression produced from a compact JSON Web Signature (JWS).
///
/// Linux has no trusted Apple ad-network key source and does not implement
/// ES256 verification. `init(compactJWS:)` therefore never returns an instance:
/// malformed compact JWS values throw a structural `AdAttributionKitError`, and
/// every structurally valid value — including a forged nonempty signature — is
/// rejected with `invalidImpressionJWSSignature`. `isSupported` is `false`.
/// View and tap methods remain fail-closed if an instance is ever constructed.
public struct AppImpression: Hashable, Identifiable, Sendable {
    public typealias ID = UUID

    /// The impression's unique ID.
    public let id: UUID
    /// The publisher app's item ID.
    public let publisherItemID: UInt64
    /// The advertised item's ID.
    public let advertisedItemID: UInt64
    /// A four-digit integer that ad networks define to represent the ad campaign.
    public let sourceID: Int
    /// The JSON Web Signature (JWS) key ID.
    public let keyID: String
    /// The advertising network ID.
    public let adNetworkID: String
    /// The impression's timestamp, in milliseconds since 1970, as a `Date`.
    public let timestamp: Date
    /// A Boolean value that indicates whether this impression is eligible for reengagement.
    public let eligibleForReengagement: Bool
    /// The compact representation of the impression's JSON Web Signature (JWS).
    public let compactJWSRepresentation: String

    /// Whether the framework supports app impressions on this device.
    public static var isSupported: Bool {
        LinuxAdAttributionBoundary.isSupported
    }

    /// Rejects every compact JWS. Does not verify signatures and does not
    /// return an impression after parsing header/payload JSON.
    public init(compactJWS: String) async throws {
        try Self.rejectUnverifiedCompactJWS(compactJWS)
    }

    /// Begins recording a view-through impression.
    ///
    /// Linux has no attribution view, so this always fails closed.
    public func beginView() async throws {
        throw LinuxAdAttributionBoundary.missingAttributionView()
    }

    /// Ends the view-through impression.
    ///
    /// Linux has no attribution view, so this always fails closed.
    public func endView() async throws {
        throw LinuxAdAttributionBoundary.missingAttributionView()
    }

    /// Processes a click-through interaction on custom rendered ad content.
    ///
    /// Linux does not record click-through attribution.
    public func handleTap() async throws {
        throw LinuxAdAttributionBoundary.missingAttributionView()
    }

    /// Processes a click-through interaction and would deliver a reengagement URL.
    ///
    /// Linux never opens the URL and does not record the tap.
    public func handleTap(reengagementURL: URL) async throws {
        _ = reengagementURL
        throw LinuxAdAttributionBoundary.missingAttributionView()
    }

    private static func rejectUnverifiedCompactJWS(_ compactJWS: String) throws -> Never {
        let parts = compactJWS.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            throw AdAttributionKitError.invalidImpressionJWSComponents
        }

        _ = try jsonObject(
            fromBase64URL: String(parts[0]),
            or: .invalidImpressionJWSHeader
        )
        _ = try jsonObject(
            fromBase64URL: String(parts[1]),
            or: .invalidImpressionJWSPayload
        )
        let signature = try decodeBase64URL(
            String(parts[2]),
            or: .invalidImpressionJWSSignature
        )
        guard !signature.isEmpty else {
            throw AdAttributionKitError.invalidImpressionJWSSignature
        }

        // No trusted key source and no ES256 verifier: never succeed.
        throw AdAttributionKitError.invalidImpressionJWSSignature
    }

    private static func jsonObject(
        fromBase64URL string: String,
        or failure: AdAttributionKitError
    ) throws -> [String: Any] {
        let data = try decodeBase64URL(string, or: failure)
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw failure
        }
        if let dictionary = object as? [String: Any] {
            return dictionary
        }
        throw failure
    }

    private static func decodeBase64URL(
        _ string: String,
        or failure: AdAttributionKitError
    ) throws -> Data {
        guard !string.isEmpty else { throw failure }
        var encoded = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        switch encoded.count % 4 {
        case 0:
            break
        case 2:
            encoded += "=="
        case 3:
            encoded += "="
        default:
            throw failure
        }
        guard let data = Data(base64Encoded: encoded) else {
            throw failure
        }
        return data
    }
}
