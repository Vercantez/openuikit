@_spi(OpenUIKitHost) import NearbyInteraction
import Foundation

private final class NIFullDelegateProbe: NSObject, NISessionDelegate {
    var updated = 0
    var removed = 0
    var suspended = 0
    var suspensionEnded = 0
    var invalidated = 0
    var shareable = 0
    var convergence = 0
    var started = 0
    var dtdoa = 0
    var lastReason: NINearbyObject.RemovalReason?
    var lastShareable: Data?
    var lastConvergence: NIAlgorithmConvergenceStatus?
    var lastMeasurements: [NIDLTDOAMeasurement] = []

    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        _ = session
        updated += nearbyObjects.count
    }

    func session(
        _ session: NISession,
        didRemove nearbyObjects: [NINearbyObject],
        reason: NINearbyObject.RemovalReason
    ) {
        _ = session
        removed += nearbyObjects.count
        lastReason = reason
    }

    func sessionWasSuspended(_ session: NISession) {
        _ = session
        suspended += 1
    }

    func sessionSuspensionEnded(_ session: NISession) {
        _ = session
        suspensionEnded += 1
    }

    func session(_ session: NISession, didInvalidateWith error: any Error) {
        _ = session
        _ = error
        invalidated += 1
    }

    func session(
        _ session: NISession,
        didGenerateShareableConfigurationData shareableConfigurationData: Data,
        for object: NINearbyObject
    ) {
        _ = session
        _ = object
        shareable += 1
        lastShareable = shareableConfigurationData
    }

    func session(
        _ session: NISession,
        didUpdateAlgorithmConvergence convergence: NIAlgorithmConvergence,
        for object: NINearbyObject?
    ) {
        _ = session
        _ = object
        self.convergence += 1
        lastConvergence = convergence.status
    }

    func sessionDidStartRunning(_ session: NISession) {
        _ = session
        started += 1
    }

    func session(_ session: NISession, didUpdateDLTDOA measurements: [NIDLTDOAMeasurement]) {
        _ = session
        dtdoa += measurements.count
        lastMeasurements = measurements
    }
}

func testNISessionDelegateCallbacks() {
    let session = NISession()
    let probe = NIFullDelegateProbe()
    session.delegate = probe

    let token = NIDiscoveryToken.hostToken()
    let object = NINearbyObject.hostObject(discoveryToken: token, distance: 1)
    let payload = Data([0xAA, 0xBB])
    let measurement = NIDLTDOAMeasurement.hostMeasurement(
        address: 1,
        measurementType: .poll,
        transmitTime: 0,
        receiveTime: 1,
        signalStrength: 0,
        carrierFrequencyOffset: 0,
        coordinatesType: .relative,
        coordinates: simd_double3(0, 0, 0)
    )
    let convergence = NIAlgorithmConvergence(status: .converged)

    probe.session(session, didUpdate: [object])
    probe.session(session, didRemove: [object], reason: .peerEnded)
    probe.sessionWasSuspended(session)
    probe.sessionSuspensionEnded(session)
    probe.session(session, didInvalidateWith: NIError(.sessionFailed))
    probe.session(session, didGenerateShareableConfigurationData: payload, for: object)
    probe.session(session, didUpdateAlgorithmConvergence: convergence, for: object)
    probe.session(session, didUpdateAlgorithmConvergence: convergence, for: nil)
    probe.sessionDidStartRunning(session)
    probe.session(session, didUpdateDLTDOA: [measurement])

    precondition(probe.updated == 1)
    precondition(probe.removed == 1)
    precondition(probe.lastReason == .peerEnded)
    precondition(probe.suspended == 1)
    precondition(probe.suspensionEnded == 1)
    precondition(probe.invalidated == 1)
    precondition(probe.shareable == 1)
    precondition(probe.lastShareable == payload)
    precondition(probe.convergence == 2)
    precondition(probe.lastConvergence == .converged)
    precondition(probe.started == 1)
    precondition(probe.dtdoa == 1)
    precondition(probe.lastMeasurements.count == 1)
}
