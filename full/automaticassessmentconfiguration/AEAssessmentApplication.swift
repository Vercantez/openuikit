import Foundation

/// An application that can participate in an assessment session.
///
/// Linux stores the bundle identifier only. There is no code-signature
/// check, team-identifier match, or App Store lookup. Equality and hashing
/// use the bundle identifier so `AEAssessmentConfiguration` can look up
/// participants by identity rather than object pointer.
open class AEAssessmentApplication: NSObject {
    public let bundleIdentifier: String

    public init(bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
        super.init()
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AEAssessmentApplication else {
            return false
        }
        return bundleIdentifier == other.bundleIdentifier
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(bundleIdentifier)
        return hasher.finalize()
    }

    func makeSnapshot() -> AEAssessmentApplication {
        AEAssessmentApplication(bundleIdentifier: bundleIdentifier)
    }
}
