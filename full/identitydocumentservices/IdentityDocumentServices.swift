@_exported import Foundation

/// Linux starting point for Apple's public `IdentityDocumentServices` module.
///
/// Isolated host compilation imports Foundation only. Value types, ISO 18013-5
/// request trees, presentment error codes (sequential `Int` raw values from the
/// pinned API-digester child order), and fail-closed web-presentment /
/// provider-registration boundaries are real. Linux has no entitlement, Secure
/// Element, Apple identity-document daemon, or ISO 18013-5 CBOR validator, so
/// those paths never report success.
enum IdentityDocumentServicesHostBoundary {
    static func presentmentError(
        _ code: IdentityDocumentPresentmentError.Code,
        debugDescription: String
    ) -> IdentityDocumentPresentmentError {
        IdentityDocumentPresentmentError(code: code, debugDescription: debugDescription)
    }
}
