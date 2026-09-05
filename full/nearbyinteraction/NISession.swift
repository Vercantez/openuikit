import Dispatch
import Foundation

public protocol NISessionDelegate: AnyObject {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject])
    func session(
        _ session: NISession,
        didRemove nearbyObjects: [NINearbyObject],
        reason: NINearbyObject.RemovalReason
    )
    func sessionWasSuspended(_ session: NISession)
    func sessionSuspensionEnded(_ session: NISession)
    func session(_ session: NISession, didInvalidateWith error: any Error)
    func session(
        _ session: NISession,
        didGenerateShareableConfigurationData shareableConfigurationData: Data,
        for object: NINearbyObject
    )
    func session(
        _ session: NISession,
        didUpdateAlgorithmConvergence convergence: NIAlgorithmConvergence,
        for object: NINearbyObject?
    )
    func sessionDidStartRunning(_ session: NISession)
    func session(_ session: NISession, didUpdateDLTDOA measurements: [NIDLTDOAMeasurement])
}

extension NISessionDelegate {
    public func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        _ = session
        _ = nearbyObjects
    }

    public func session(
        _ session: NISession,
        didRemove nearbyObjects: [NINearbyObject],
        reason: NINearbyObject.RemovalReason
    ) {
        _ = session
        _ = nearbyObjects
        _ = reason
    }

    public func sessionWasSuspended(_ session: NISession) {
        _ = session
    }

    public func sessionSuspensionEnded(_ session: NISession) {
        _ = session
    }

    public func session(_ session: NISession, didInvalidateWith error: any Error) {
        _ = session
        _ = error
    }

    public func session(
        _ session: NISession,
        didGenerateShareableConfigurationData shareableConfigurationData: Data,
        for object: NINearbyObject
    ) {
        _ = session
        _ = shareableConfigurationData
        _ = object
    }

    public func session(
        _ session: NISession,
        didUpdateAlgorithmConvergence convergence: NIAlgorithmConvergence,
        for object: NINearbyObject?
    ) {
        _ = session
        _ = convergence
        _ = object
    }

    public func sessionDidStartRunning(_ session: NISession) {
        _ = session
    }

    public func session(_ session: NISession, didUpdateDLTDOA measurements: [NIDLTDOAMeasurement]) {
        _ = session
        _ = measurements
    }
}

/// Linux Nearby Interaction session.
///
/// `isSupported` is false. `run(_:)` never starts ranging: it stores the
/// configuration for the duration of the synchronous fail-closed
/// `session(_:didInvalidateWith:)` callback, then clears it. Delegate
/// delivery is on the caller thread so tests can observe it without a run
/// loop. Apple's queue hop is unobserved and recorded as an oracle question.
public class NISession: NSObject {
    public static var isSupported: Bool { false }

    public static var deviceCapabilities: any NIDeviceCapability {
        NIHostDeviceCapability.unsupported
    }

    public weak var delegate: (any NISessionDelegate)?
    public var delegateQueue: DispatchQueue?
    public private(set) var discoveryToken: NIDiscoveryToken?
    public private(set) var configuration: NIConfiguration?

    private var invalidated = false

    public override init() {
        super.init()
        self.discoveryToken = NIDiscoveryToken(identifier: UUID())
    }

    public func run(_ configuration: NIConfiguration) {
        let stored = (configuration.copy() as? NIConfiguration) ?? configuration
        self.configuration = stored
        let error = NIError(.unsupportedPlatform)
        deliverFailClosed(error)
        self.configuration = nil
        invalidated = true
    }

    public func pause() {
        // Never running on Linux; pause is a documented no-op.
    }

    public func invalidate() {
        configuration = nil
        invalidated = true
    }

    public func setARSession(_ session: ARSession) {
        // Camera assistance remains unsupported. The object is ignored.
        _ = session
    }

    public func worldTransform(for object: NINearbyObject) -> simd_float4x4? {
        _ = object
        return nil
    }

    private func deliverFailClosed(_ error: NIError) {
        delegate?.session(self, didInvalidateWith: error)
    }
}
