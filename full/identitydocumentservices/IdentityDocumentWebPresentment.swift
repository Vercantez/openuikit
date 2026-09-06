import Foundation

/// Marker protocol for an identity-document web presentment request.
public protocol IdentityDocumentWebPresentmentRequest: Sendable {}

/// Marker protocol for an identity-document web presentment response.
public protocol IdentityDocumentWebPresentmentResponse: Sendable {}

/// A raw web presentment request envelope (type + opaque bytes).
public struct IdentityDocumentWebPresentmentRawRequest: Sendable {
    public enum RequestType: Hashable, Sendable {
        case iso18013MobileDocument
    }

    public var requestType: RequestType
    public var requestData: Data

    public init(requestType: RequestType, requestData: Data) {
        self.requestType = requestType
        self.requestData = requestData
    }
}

/// Functions for validating an incoming web presentment raw request.
///
/// Linux never returns a parsed ISO 18013-5 request. Empty or non-https
/// origins fail as `invalidRequest`. Any other payload fails as `notEntitled`
/// because this host has no entitlement, daemon, or Apple CBOR validator.
public struct IdentityDocumentWebPresentmentRawRequestValidator {
    public init() {}

    public func validateISO18013MobileDocumentRequest(
        _ requestData: Data,
        origin: URL
    ) throws -> ISO18013MobileDocumentRequest {
        if requestData.isEmpty {
            throw IdentityDocumentServicesHostBoundary.presentmentError(
                .invalidRequest,
                debugDescription: "ISO 18013-5 request data is empty"
            )
        }
        guard origin.scheme?.lowercased() == "https",
              let host = origin.host, !host.isEmpty
        else {
            throw IdentityDocumentServicesHostBoundary.presentmentError(
                .invalidRequest,
                debugDescription: "web presentment origin is not an https URL with a host"
            )
        }
        throw IdentityDocumentServicesHostBoundary.presentmentError(
            .notEntitled,
            debugDescription: "Linux cannot validate ISO 18013-5 web presentment requests"
        )
    }
}
