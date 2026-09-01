import Foundation

/// An attributable impression produced from a compact JSON Web Signature (JWS).
///
/// Linux decodes documented JWS header and payload claims so callers can inspect
/// impression metadata. It does not verify the ES256 signature against Apple
/// ad-network keys, does not record view-through or click-through attribution,
/// and does not open reengagement URLs. `isSupported` is `false`, and every
/// recording method throws `AdAttributionKitError.missingAttributionView`.
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

    /// Creates an impression by decoding documented compact-JWS claims.
    ///
    /// This initializer validates compact JWS structure and the documented
    /// header/payload fields. It does not contact Apple services and does not
    /// verify the ES256 signature.
    public init(compactJWS: String) async throws {
        self = try Self.decodeClaims(compactJWS: compactJWS)
    }

    private init(
        id: UUID,
        publisherItemID: UInt64,
        advertisedItemID: UInt64,
        sourceID: Int,
        keyID: String,
        adNetworkID: String,
        timestamp: Date,
        eligibleForReengagement: Bool,
        compactJWSRepresentation: String
    ) {
        self.id = id
        self.publisherItemID = publisherItemID
        self.advertisedItemID = advertisedItemID
        self.sourceID = sourceID
        self.keyID = keyID
        self.adNetworkID = adNetworkID
        self.timestamp = timestamp
        self.eligibleForReengagement = eligibleForReengagement
        self.compactJWSRepresentation = compactJWSRepresentation
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

    private struct JWSHeader: Decodable {
        let alg: String
        let kid: String
    }

    private struct JWSPayload: Decodable {
        let impressionIdentifier: UUID
        let publisherItemIdentifier: UInt64
        let impressionType: String
        let adNetworkIdentifier: String
        let sourceIdentifier: Int
        let timestamp: Int64
        let advertisedItemIdentifier: UInt64
        let eligibleForReengagement: Bool?

        enum CodingKeys: String, CodingKey {
            case impressionIdentifier = "impression-identifier"
            case publisherItemIdentifier = "publisher-item-identifier"
            case impressionType = "impression-type"
            case adNetworkIdentifier = "ad-network-identifier"
            case sourceIdentifier = "source-identifier"
            case timestamp
            case advertisedItemIdentifier = "advertised-item-identifier"
            case eligibleForReengagement = "eligible-for-re-engagement"
        }
    }

    private static func decodeClaims(compactJWS: String) throws -> AppImpression {
        let parts = compactJWS.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            throw AdAttributionKitError.invalidImpressionJWSComponents
        }

        let headerData = try decodeBase64URL(
            String(parts[0]),
            or: .invalidImpressionJWSHeader
        )
        let payloadData = try decodeBase64URL(
            String(parts[1]),
            or: .invalidImpressionJWSPayload
        )
        let signatureData = try decodeBase64URL(
            String(parts[2]),
            or: .invalidImpressionJWSSignature
        )
        guard !signatureData.isEmpty else {
            throw AdAttributionKitError.invalidImpressionJWSSignature
        }

        let decoder = JSONDecoder()
        let header: JWSHeader
        do {
            header = try decoder.decode(JWSHeader.self, from: headerData)
        } catch {
            throw AdAttributionKitError.invalidImpressionJWSHeader
        }
        guard header.alg == "ES256", !header.kid.isEmpty else {
            throw AdAttributionKitError.invalidImpressionJWSHeader
        }

        let payload: JWSPayload
        do {
            payload = try decoder.decode(JWSPayload.self, from: payloadData)
        } catch {
            throw AdAttributionKitError.invalidImpressionJWSPayload
        }
        guard payload.impressionType == "app-impression" else {
            throw AdAttributionKitError.invalidImpressionJWSPayload
        }
        guard payload.adNetworkIdentifier == header.kid else {
            throw AdAttributionKitError.invalidImpressionJWSPayload
        }

        let timestamp = Date(
            timeIntervalSince1970: TimeInterval(payload.timestamp) / 1000.0
        )
        return AppImpression(
            id: payload.impressionIdentifier,
            publisherItemID: payload.publisherItemIdentifier,
            advertisedItemID: payload.advertisedItemIdentifier,
            sourceID: payload.sourceIdentifier,
            keyID: header.kid,
            adNetworkID: payload.adNetworkIdentifier,
            timestamp: timestamp,
            eligibleForReengagement: payload.eligibleForReengagement ?? false,
            compactJWSRepresentation: compactJWS
        )
    }

    private static func decodeBase64URL(
        _ string: String,
        or error: AdAttributionKitError
    ) throws -> Data {
        guard !string.isEmpty else { throw error }
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
            throw error
        }
        guard let data = Data(base64Encoded: encoded) else {
            throw error
        }
        return data
    }
}
