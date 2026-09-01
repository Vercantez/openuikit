import Foundation

/// Values that describe ad attribution error conditions.
///
/// `description` returns the case name. Apple's shipped CustomStringConvertible
/// text is unobserved in this seed and is not claimed.
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

    /// A string that names the error case. Not Apple description copy.
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .missingAttributionView:
            return "missingAttributionView"
        case .impressionExpired:
            return "impressionExpired"
        case .invalidImpressionJWSHeader:
            return "invalidImpressionJWSHeader"
        case .invalidImpressionJWSPayload:
            return "invalidImpressionJWSPayload"
        case .invalidImpressionJWSSignature:
            return "invalidImpressionJWSSignature"
        case .invalidImpressionJWSComponents:
            return "invalidImpressionJWSComponents"
        case .conversionTagNotSupported:
            return "conversionTagNotSupported"
        case .invalidConversionTag:
            return "invalidConversionTag"
        }
    }
}
