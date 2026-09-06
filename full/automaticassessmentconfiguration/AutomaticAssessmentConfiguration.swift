import Foundation

/// Linux starting point for Apple's public `AutomaticAssessmentConfiguration`
/// module.
///
/// Configuration objects, autocorrect option-set arithmetic, and
/// `AEAssessmentError` codes are real and process-local. There is no
/// Automatic Assessment daemon, entitlement, or lock-task service on Linux:
/// `AEAssessmentSession.begin()` and `update(to:)` fail closed with the
/// documented error codes. See `README.md`.
public enum AutomaticAssessmentConfigurationModule {
    /// Human-readable overlay identity; not an Apple public symbol.
    public static let portableOverlayName = "AutomaticAssessmentConfiguration"
}
