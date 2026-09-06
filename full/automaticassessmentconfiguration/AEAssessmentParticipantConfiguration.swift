import Foundation

/// Per-participant restrictions for an assessment session.
///
/// Linux keeps these flags and the `configurationInfo` dictionary in
/// process-local storage. They never reach an assessment daemon.
open class AEAssessmentParticipantConfiguration: NSObject {
    /// Whether the participant may use the network during the session.
    ///
    /// Linux default is `false` (restrictive local policy). Darwin's
    /// `init` default is unobserved.
    open var allowsNetworkAccess: Bool = false

    /// Opaque vendor-specific configuration payload.
    ///
    /// Linux stores the dictionary as given. Keys, value types, and
    /// round-trip encoding on Darwin are unobserved.
    open var configurationInfo: [String: Any] = [:]

    /// Whether this participant must be present for the session to begin.
    ///
    /// Linux default is `false`. A required participant does not make
    /// `AEAssessmentSession.begin()` succeed on Linux; begin still fails
    /// closed with `unsupportedPlatform`.
    open var isRequired: Bool = false

    public required override init() {
        super.init()
    }

    open class func `new`() -> Self {
        Self.init()
    }

    func makeSnapshot() -> AEAssessmentParticipantConfiguration {
        let copy = AEAssessmentParticipantConfiguration()
        copy.allowsNetworkAccess = allowsNetworkAccess
        copy.configurationInfo = configurationInfo
        copy.isRequired = isRequired
        return copy
    }
}
