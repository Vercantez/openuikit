import Foundation

/// Delegate callbacks for `AEAssessmentSession` lifecycle events.
///
/// Darwin methods are `@objc optional`. Linux provides empty default
/// implementations so a type may implement only the events it cares about.
/// Callbacks from this overlay run synchronously on the caller before
/// `begin()`, `end()`, and `update(to:)` return. Apple's queue, timing,
/// and exactly-once delivery are unobserved.
public protocol AEAssessmentSessionDelegate: NSObjectProtocol {
    func assessmentSessionDidBegin(_ session: AEAssessmentSession)
    func assessmentSession(_ session: AEAssessmentSession, failedToBeginWithError error: any Error)
    func assessmentSession(_ session: AEAssessmentSession, wasInterruptedWithError error: any Error)
    func assessmentSessionDidEnd(_ session: AEAssessmentSession)
    func assessmentSessionDidUpdate(_ session: AEAssessmentSession)
    func assessmentSession(
        _ session: AEAssessmentSession,
        failedToUpdateTo configuration: AEAssessmentConfiguration,
        error: any Error
    )
}

extension AEAssessmentSessionDelegate {
    public func assessmentSessionDidBegin(_ session: AEAssessmentSession) {
        _ = session
    }

    public func assessmentSession(
        _ session: AEAssessmentSession,
        failedToBeginWithError error: any Error
    ) {
        _ = session
        _ = error
    }

    public func assessmentSession(
        _ session: AEAssessmentSession,
        wasInterruptedWithError error: any Error
    ) {
        _ = session
        _ = error
    }

    public func assessmentSessionDidEnd(_ session: AEAssessmentSession) {
        _ = session
    }

    public func assessmentSessionDidUpdate(_ session: AEAssessmentSession) {
        _ = session
    }

    public func assessmentSession(
        _ session: AEAssessmentSession,
        failedToUpdateTo configuration: AEAssessmentConfiguration,
        error: any Error
    ) {
        _ = session
        _ = configuration
        _ = error
    }
}

/// An assessment session.
///
/// Linux has no lock-task / Automatic Assessment daemon. `begin()` never
/// activates the session and always reports `unsupportedPlatform`.
/// `update(to:)` always reports `configurationUpdatesNotSupported`.
/// `supportsMultipleParticipants` and `supportsConfigurationUpdates` are
/// `false`.
open class AEAssessmentSession: NSObject {
    private let storedConfiguration: AEAssessmentConfiguration
    private var active = false

    public weak var delegate: (any AEAssessmentSessionDelegate)?

    /// Linux never hosts a multi-app assessment service.
    open class var supportsMultipleParticipants: Bool { false }

    /// Linux never applies live configuration updates to an OS session.
    open class var supportsConfigurationUpdates: Bool { false }

    public init(configuration: AEAssessmentConfiguration) {
        self.storedConfiguration = configuration.makeSnapshot()
        super.init()
    }

    /// Snapshot of the configuration captured at `init`. `update(to:)` does
    /// not replace it on Linux.
    open var configuration: AEAssessmentConfiguration {
        storedConfiguration.makeSnapshot()
    }

    open var isActive: Bool { active }

    /// Always fails closed: Linux cannot enter Single App / assessment mode.
    ///
    /// `isActive` stays `false`. The delegate receives
    /// `assessmentSession(_:failedToBeginWithError:)` synchronously with
    /// `AEAssessmentError.unsupportedPlatform` before this method returns.
    /// `assessmentSessionDidBegin` is never invoked.
    open func begin() {
        let error = AEAssessmentError(.unsupportedPlatform)
        delegate?.assessmentSession(self, failedToBeginWithError: error)
    }

    /// No-op on Linux: the session never becomes active, so there is nothing
    /// to tear down and `assessmentSessionDidEnd` is not invoked.
    open func end() {}

    /// Always fails closed because `supportsConfigurationUpdates` is `false`.
    ///
    /// The stored configuration is unchanged. The delegate receives
    /// `assessmentSession(_:failedToUpdateTo:error:)` synchronously with
    /// `AEAssessmentError.configurationUpdatesNotSupported`.
    open func update(to configuration: AEAssessmentConfiguration) {
        let error = AEAssessmentError(.configurationUpdatesNotSupported)
        delegate?.assessmentSession(self, failedToUpdateTo: configuration, error: error)
    }
}
