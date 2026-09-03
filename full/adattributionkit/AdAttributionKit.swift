@_exported import Foundation

/// Linux starting point for Apple's public `AdAttributionKit` module.
///
/// Linux has no Apple attribution daemon, SKAdNetwork/AdAttributionKit
/// signing keys, `UIEventAttributionView`, or StoreKit product page. Public
/// APIs that would talk to those services fail closed. `AppImpression` never
/// becomes a successful value: compact JWS strings are classified and then
/// rejected. There is no trusted key source and no ES256 verification on this
/// host, so a structurally valid but unverified signature is never treated as
/// authentic.

// MARK: - Errors

public enum AdAttributionKitError: Error, Hashable, CustomStringConvertible, Sendable {
    case missingAttributionView
    case impressionExpired
    case invalidConversionTag
    case conversionTagNotSupported
    case invalidImpressionJWSHeader
    case invalidImpressionJWSPayload
    case invalidImpressionJWSSignature
    case invalidImpressionJWSComponents
    case unknown

    /// Linux-local case name. Darwin `description` strings are unobserved.
    public var description: String {
        switch self {
        case .missingAttributionView:
            return "missingAttributionView"
        case .impressionExpired:
            return "impressionExpired"
        case .invalidConversionTag:
            return "invalidConversionTag"
        case .conversionTagNotSupported:
            return "conversionTagNotSupported"
        case .invalidImpressionJWSHeader:
            return "invalidImpressionJWSHeader"
        case .invalidImpressionJWSPayload:
            return "invalidImpressionJWSPayload"
        case .invalidImpressionJWSSignature:
            return "invalidImpressionJWSSignature"
        case .invalidImpressionJWSComponents:
            return "invalidImpressionJWSComponents"
        case .unknown:
            return "unknown"
        }
    }
}

// MARK: - Compact JWS classification (reject-only)

/// Compact JWS is `header.payload.signature` (RFC 7515). Classification is
/// structural only. A decoded header/payload is never turned into a live
/// `AppImpression`; every path throws.
enum ImpressionJWS {
    static func reject(_ compactJWS: String) -> AdAttributionKitError {
        let parts = compactJWS.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            return .invalidImpressionJWSComponents
        }
        guard jsonObject(fromBase64URL: String(parts[0])) != nil else {
            return .invalidImpressionJWSHeader
        }
        guard jsonObject(fromBase64URL: String(parts[1])) != nil else {
            return .invalidImpressionJWSPayload
        }
        // Third component exists. Empty, garbage, or well-formed-looking
        // signature bytes are all unverified. Linux has no trusted AdAttributionKit
        // key source and does not perform ES256 verification.
        return .invalidImpressionJWSSignature
    }

    private static func jsonObject(fromBase64URL string: String) -> [String: Any]? {
        guard let data = base64URLDecodedData(string) else {
            return nil
        }
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any]
        else {
            return nil
        }
        return dictionary
    }

    private static func base64URLDecodedData(_ string: String) -> Data? {
        var encoded = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = encoded.count % 4
        if remainder != 0 {
            encoded.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: encoded)
    }
}

// MARK: - AppImpression

/// Attributable ad impression. The public initializer never succeeds on Linux:
/// there is no trusted key with which to verify the compact JWS. Stored
/// members exist so the canonical surface compiles; they are unreachable
/// because no public path returns an instance.
public struct AppImpression: Hashable, Identifiable, Sendable {
    public typealias ID = UUID

    private let storedID: UUID
    private let storedPublisherItemID: UInt64
    private let storedAdvertisedItemID: UInt64
    private let storedSourceID: Int
    private let storedKeyID: String
    private let storedAdNetworkID: String
    private let storedTimestamp: Date
    private let storedEligibleForReengagement: Bool
    private let storedCompactJWSRepresentation: String

    public var id: UUID { storedID }
    public var publisherItemID: UInt64 { storedPublisherItemID }
    public var advertisedItemID: UInt64 { storedAdvertisedItemID }
    public var sourceID: Int { storedSourceID }
    public var keyID: String { storedKeyID }
    public var adNetworkID: String { storedAdNetworkID }
    public var timestamp: Date { storedTimestamp }
    public var eligibleForReengagement: Bool { storedEligibleForReengagement }
    public var compactJWSRepresentation: String { storedCompactJWSRepresentation }

    /// Linux has no Apple impression/attribution service.
    public static var isSupported: Bool { false }

    public init(compactJWS: String) async throws {
        throw ImpressionJWS.reject(compactJWS)
    }

    /// Unreachable without a verified instance. Fail-closed if ever invoked.
    public func beginView() async throws {
        throw AdAttributionKitError.unknown
    }

    /// Unreachable without a verified instance. Fail-closed if ever invoked.
    public func endView() async throws {
        throw AdAttributionKitError.unknown
    }

    /// Darwin requires a tap inside `UIEventAttributionView`. Linux has none.
    public func handleTap() async throws {
        throw AdAttributionKitError.missingAttributionView
    }

    /// Darwin requires a tap inside `UIEventAttributionView`. Linux has none.
    public func handleTap(reengagementURL: URL) async throws {
        throw AdAttributionKitError.missingAttributionView
    }
}

// MARK: - Coarse conversion value

/// Developer-defined relative conversion value. Apple's public documentation
/// for the postback field uses the strings `low`, `medium`, and `high`, which
/// match these Swift `String` raw values.
public enum CoarseConversionValue: String, Codable, Hashable, Sendable {
    case low
    case medium
    case high
}

// MARK: - Postback update

public struct PostbackUpdate: Sendable {
    public enum ConversionType: String, Hashable, Sendable {
        case install
        case reengagement
    }

    public let fineConversionValue: Int
    public let lockPostback: Bool
    public let coarseConversionValue: CoarseConversionValue?
    public let conversionTypes: [ConversionType]?
    public let conversionTag: String?

    public init(
        fineConversionValue: Int,
        lockPostback: Bool,
        coarseConversionValue: CoarseConversionValue? = nil,
        conversionTypes: [ConversionType]? = nil
    ) {
        self.fineConversionValue = fineConversionValue
        self.lockPostback = lockPostback
        self.coarseConversionValue = coarseConversionValue
        self.conversionTypes = conversionTypes
        self.conversionTag = nil
    }

    public init(
        fineConversionValue: Int,
        lockPostback: Bool,
        conversionTag: String,
        coarseConversionValue: CoarseConversionValue? = nil,
        conversionTypes: [ConversionType]? = nil
    ) {
        self.fineConversionValue = fineConversionValue
        self.lockPostback = lockPostback
        self.coarseConversionValue = coarseConversionValue
        self.conversionTypes = conversionTypes
        self.conversionTag = conversionTag
    }
}

// MARK: - Postback

/// Namespace for advertised-app conversion-value updates. Empty of stored
/// state; the implicit memberwise initializer is hidden because it is not on
/// the canonical graph.
public struct Postback: Sendable {
    private init() {}

    /// Linux has no Apple postback / conversion-window service.
    public static var isSupported: Bool { false }

    /// Query parameter Apple appends to a reengagement universal link.
    /// Public documentation name: `AdAttributionKitReengagementOpen`.
    public static var reengagementOpenURLParameter: String {
        "AdAttributionKitReengagementOpen"
    }

    public static func updateConversionValue(
        _ fineConversionValue: Int,
        lockPostback: Bool
    ) async throws {
        _ = (fineConversionValue, lockPostback)
        throw AdAttributionKitError.unknown
    }

    public static func updateConversionValue(
        _ fineConversionValue: Int,
        coarseConversionValue: CoarseConversionValue,
        lockPostback: Bool
    ) async throws {
        _ = (fineConversionValue, coarseConversionValue, lockPostback)
        throw AdAttributionKitError.unknown
    }

    public static func updateConversionValue(
        _ postbackUpdate: PostbackUpdate
    ) async throws {
        _ = postbackUpdate
        throw AdAttributionKitError.unknown
    }
}
