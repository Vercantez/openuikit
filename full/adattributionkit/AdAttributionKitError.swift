import Foundation

/// Values that describe ad attribution error conditions.
public enum AdAttributionKitError: Error, CustomStringConvertible, Hashable, Sendable {
    /// The attribution failed due to an unknown, unrecoverable error.
    case unknown
    /// The attribution failed due to a missing attribution view.
    case missingAttributionView
    /// The attribution failed because the impression expired.
    case impressionExpired
    /// The attribution failed due to an invalid JWS header.
    case invalidImpressionJWSHeader
    /// The attribution failed due to an invalid JWS payload.
    case invalidImpressionJWSPayload
    /// The attribution failed due to an invalid JWS signature.
    case invalidImpressionJWSSignature
    /// The attribution failed due to invalid JWS components.
    case invalidImpressionJWSComponents
    /// The postback update failed due to an unsupported use of conversion tag.
    case conversionTagNotSupported
    /// The postback update failed due to an invalid conversion tag.
    case invalidConversionTag

    /// A string that describes the error.
    public var description: String {
        switch self {
        case .unknown:
            return "The attribution failed due to an unknown, unrecoverable error."
        case .missingAttributionView:
            return "The attribution failed due to a missing attribution view."
        case .impressionExpired:
            return "The attribution failed because the impression expired."
        case .invalidImpressionJWSHeader:
            return "The attribution failed due to an invalid JWS header."
        case .invalidImpressionJWSPayload:
            return "The attribution failed due to an invalid JWS payload."
        case .invalidImpressionJWSSignature:
            return "The attribution failed due to an invalid JWS signature."
        case .invalidImpressionJWSComponents:
            return "The attribution failed due to invalid JWS components."
        case .conversionTagNotSupported:
            return "The postback update failed due to an unsupported use of conversion tag."
        case .invalidConversionTag:
            return "The postback update failed due to an invalid conversion tag."
        }
    }
}
