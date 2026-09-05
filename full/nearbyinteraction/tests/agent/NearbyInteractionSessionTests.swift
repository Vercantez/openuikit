@_spi(OpenUIKitHost) import NearbyInteraction
import Dispatch
import Foundation

private final class NIInvalidateProbe: NSObject, NISessionDelegate {
    var invalidations: [Int] = []
    var sawConfigurationDuringCallback = false

    func session(_ session: NISession, didInvalidateWith error: any Error) {
        let ns = error as NSError
        invalidations.append(ns.code)
        sawConfigurationDuringCallback = session.configuration != nil
        if let ni = error as? NIError {
            precondition(ni.code == .unsupportedPlatform)
        } else {
            precondition(ns.domain == NIErrorDomain)
            precondition(ns.code == NIError.Code.unsupportedPlatform.rawValue)
        }
    }
}

func testNISessionUnsupported() {
    precondition(NISession.isSupported == false)
    let capabilities = NISession.deviceCapabilities
    precondition(capabilities.supportsPreciseDistanceMeasurement == false)
    precondition(capabilities.supportsDirectionMeasurement == false)
    precondition(capabilities.supportsCameraAssistance == false)
    precondition(capabilities.supportsExtendedDistanceMeasurement == false)
    precondition(capabilities.supportsDLTDOAMeasurement == false)
}

func testNISessionDiscoveryToken() {
    let session = NISession()
    precondition(session.discoveryToken != nil)
    precondition(session.configuration == nil)
    let first = session.discoveryToken
    let second = NISession().discoveryToken
    precondition(first != nil)
    precondition(second != nil)
    precondition(first!.isEqual(second!) == false)
}

func testNISessionRunFailClosed() {
    let session = NISession()
    let probe = NIInvalidateProbe()
    session.delegate = probe
    let config = NIDLTDOAConfiguration(networkIdentifier: 1)
    session.run(config)
    precondition(probe.invalidations == [NIError.Code.unsupportedPlatform.rawValue])
    precondition(probe.sawConfigurationDuringCallback)
    precondition(session.configuration == nil)
}

func testNISessionPauseInvalidate() {
    let session = NISession()
    let token = session.discoveryToken
    session.pause()
    session.invalidate()
    precondition(session.configuration == nil)
    precondition(session.discoveryToken?.isEqual(token) == true)
}

func testNISessionDelegateAndQueue() {
    let session = NISession()
    let probe = NIInvalidateProbe()
    let queue = DispatchQueue(label: "nearbyinteraction.tests.delegate")
    session.delegate = probe
    session.delegateQueue = queue
    precondition(session.delegate === probe)
    precondition(session.delegateQueue === queue)
    session.delegate = nil
    session.delegateQueue = nil
    precondition(session.delegate == nil)
    precondition(session.delegateQueue == nil)
}

func testNISessionWorldTransform() {
    let session = NISession()
    let token = session.discoveryToken!
    let object = NINearbyObject.hostObject(discoveryToken: token, distance: 1.5)
    precondition(session.worldTransform(for: object) == nil)
}

func testNISessionSetARSession() {
    let session = NISession()
    let ar = ARSession()
    session.setARSession(ar)
    precondition(NISession.isSupported == false)
    precondition(NISession.deviceCapabilities.supportsCameraAssistance == false)
}

func testNISessionPeerRunUsesCopy() {
    let session = NISession()
    let probe = NIInvalidateProbe()
    session.delegate = probe
    let token = NIDiscoveryToken.hostToken()
    let config = NINearbyPeerConfiguration(peerToken: token)
    config.isCameraAssistanceEnabled = true
    session.run(config)
    precondition(probe.invalidations.count == 1)
    precondition(session.configuration == nil)
}
