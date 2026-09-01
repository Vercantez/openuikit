import Foundation

/// Linux starting implementation of Apple's public `AdAttributionKit` module.
///
/// Value types and fail-closed postback/impression APIs are real. Apple
/// attribution recording, postback delivery, StoreKit rendered ads, and
/// ES256 verification against Apple-held ad-network keys are not available.
enum LinuxAdAttributionBoundary {
    static var isSupported: Bool { false }

    static func missingAttributionView() -> AdAttributionKitError {
        .missingAttributionView
    }

    static func postbackUnavailable(conversionTag: String?) -> AdAttributionKitError {
        if conversionTag != nil {
            return .conversionTagNotSupported
        }
        return .unknown
    }
}
