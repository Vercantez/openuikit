import Dispatch
import Foundation
import Matter

final class Wave9ControllerDelegate: NSObject, MTRDeviceControllerDelegate {}
final class Wave9PairingDelegate: NSObject, MTRDevicePairingDelegate {}
final class Wave9BrowserDelegate: NSObject, MTRCommissionableBrowserDelegate {}
final class Wave9NOCIssuer: NSObject, MTRNOCChainIssuer {}
final class Wave9OTADelegate: NSObject, MTROTAProviderDelegate {}
final class Wave9CertIssuer: NSObject, MTROperationalCertificateIssuer {}

private func wave9ExpectInvalidState(_ block: () throws -> Void, _ message: String) {
    do {
        try block()
        mtrRequire(false, message + " should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .invalidState, message + " code")
    } catch {
        mtrRequire(false, message + " wrong error")
    }
}

func testLegacyPairingThrowsFailClosed() {
    let controller = MTRDeviceController()
    wave9ExpectInvalidState(
        { try controller.pairDevice(UInt64(1), discriminator: UInt16(3840), setupPINCode: UInt32(20202021)) },
        "pair discriminator"
    )
    wave9ExpectInvalidState(
        { try controller.pairDevice(UInt64(1), address: "192.0.2.1", port: UInt16(5540), setupPINCode: UInt32(20202021)) },
        "pair address"
    )
    wave9ExpectInvalidState(
        { try controller.pairDevice(UInt64(1), onboardingPayload: "MT:TEST") },
        "pair payload"
    )
    wave9ExpectInvalidState(
        { try controller.commissionDevice(UInt64(1), commissioningParams: MTRCommissioningParameters()) },
        "commission legacy"
    )
    let handle = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    defer { handle.deallocate() }
    wave9ExpectInvalidState(
        { try controller.continueCommissioningDevice(handle, ignoreAttestationFailure: false) },
        "continue commissioning"
    )
    do {
        _ = try controller.deviceBeingCommissioned(withNodeID: n(1))
        mtrRequire(false, "being commissioned should throw")
    } catch let err as MTRError {
        mtrRequire(err.code == .notFound, "being commissioned code")
    } catch {
        mtrRequire(false, "being commissioned wrong error")
    }
    wave9ExpectInvalidState(
        { try controller.stopDevicePairing(UInt64(1)) },
        "stop pairing"
    )
}

func testPairingWindowAttestationFailClosed() {
    let controller = MTRDeviceController()
    wave9ExpectInvalidState(
        { try controller.openPairingWindow(UInt64(1), duration: 120) },
        "open window"
    )
    wave9ExpectInvalidState(
        { _ = try controller.openPairingWindow(withPIN: UInt64(1), duration: 120, discriminator: 3840, setupPIN: 20202021) },
        "open window PIN"
    )
    mtrRequire(controller.attestationChallenge(forDeviceID: n(1)) == nil, "no attestation challenge")
    mtrRequire(controller.fetchAttestationChallenge(forDeviceId: UInt64(1)) == nil, "no fetched challenge")
    controller.forgetDevice(withNodeID: n(1))
    mtrRequire(controller.devices().isEmpty, "still no devices")
    mtrRequire(controller.computePaseVerifier(UInt32(20202021), iterations: UInt32(1000), salt: Data([1, 2, 3])) == nil, "no PASE verifier")
    wave9ExpectInvalidState(
        { _ = try MTRDeviceController.computePASEVerifier(forSetupPasscode: n(20202021), iterations: n(1000), salt: Data([1, 2, 3])) },
        "class PASE verifier"
    )
}

func testControllerDelegatePlumbingFailClosed() {
    let controller = MTRDeviceController()
    let queue = DispatchQueue.global()
    controller.setDeviceControllerDelegate(Wave9ControllerDelegate(), queue: queue)
    controller.setPairingDelegate(Wave9PairingDelegate(), queue: queue)
    controller.setNocChainIssuer(Wave9NOCIssuer(), queue: queue)
    mtrRequire(!controller.isRunning, "still not running")
    mtrRequire(controller.startBrowse(forCommissionables: Wave9BrowserDelegate(), queue: queue) == false, "browse refused")
    mtrRequire(controller.stopBrowseForCommissionables() == false, "stop browse refused")
    controller.resume()
    mtrRequire(!controller.isSuspended, "never suspended")
    var called = false
    let started = controller.getBaseDevice(UInt64(1), queue: queue) { device, err in
        called = true
        mtrRequire(device == nil, "no base device")
        mtrExpectInvalidState(err)
    }
    mtrRequire(called, "connection callback ran synchronously")
    mtrRequire(started == false, "connection refused")
}

func testControllerLegacyProperties() {
    let controller = MTRDeviceController()
    mtrRequire(controller.isSuspended == false, "not suspended")
    mtrRequire(controller.nodesWithStoredData.isEmpty, "no stored nodes")
    mtrRequire(controller.controllerNodeId == nil, "no legacy node id")
    controller.controllerNodeId = n(42)
    mtrRequire(controller.controllerNodeID?.intValue == 42, "legacy alias writes through")
    mtrRequire(controller.controllerNodeId?.intValue == 42, "legacy alias reads back")
    let other = MTRDeviceController()
    mtrRequire(controller.uniqueIdentifier != other.uniqueIdentifier, "identifiers unique")
}

func testXPCParamCodecsRoundTrip() {
    let read = MTRReadParams()
    read.fabricFiltered = n(1)
    read.minEventNumber = NSNumber(value: UInt64(7))
    read.shouldFilterByFabric = false
    let encoded = MTRDeviceController.encodeXPCReadParams(read)
    mtrRequire(encoded != nil, "read params encoded")
    let decoded = MTRDeviceController.decodeXPCReadParams(encoded)
    mtrRequire(decoded?.fabricFiltered?.intValue == 1, "fabric filtered round-trip")
    mtrRequire(decoded?.minEventNumber?.uint64Value == UInt64(7), "event number round-trip")
    mtrRequire(decoded?.shouldFilterByFabric == false, "filter flag round-trip")
    mtrRequire(MTRDeviceController.decodeXPCReadParams(nil) == nil, "nil read decodes to nil")
    let sub = MTRSubscribeParams(minInterval: n(0), maxInterval: n(10))
    sub.autoResubscribe = n(1)
    let subEncoded = MTRDeviceController.encodeXPCSubscribeParams(sub)
    mtrRequire(subEncoded != nil, "subscribe params encoded")
    let subDecoded = MTRDeviceController.decodeXPCSubscribeParams(subEncoded)
    mtrRequire(subDecoded?.minInterval.intValue == 0, "min interval round-trip")
    mtrRequire(subDecoded?.maxInterval.intValue == 10, "max interval round-trip")
    mtrRequire(subDecoded?.autoResubscribe?.intValue == 1, "auto resubscribe round-trip")
    mtrRequire(MTRDeviceController.encodeXPCSubscribeParams(nil) == nil, "nil subscribe encodes to nil")
    mtrRequire(MTRDeviceController.decodeXPCSubscribeParams(nil) == nil, "nil subscribe decodes to nil")
    let values: [[String: Any]] = [["type": "Boolean", "value": true]]
    let responseEncoded = MTRDeviceController.encodeXPCResponseValues(values)
    mtrRequire(responseEncoded?.count == 1, "response values pass through")
    let responseDecoded = MTRDeviceController.decodeXPCResponseValues(responseEncoded)
    mtrRequire(responseDecoded?.count == 1, "response values decode")
    mtrRequire((responseDecoded?.first?["type"] as? String) == "Boolean", "response payload intact")
    mtrRequire(MTRDeviceController.encodeXPCResponseValues(nil) == nil, "nil response encodes to nil")
    mtrRequire(MTRDeviceController.decodeXPCResponseValues(nil) == nil, "nil response decodes to nil")
}

func testControllerParamsDelegatesStored() {
    let params = MTRDeviceControllerParameters()
    params.setOTAProviderDelegate(Wave9OTADelegate(), queue: DispatchQueue.global())
    params.setOperationalCertificateIssuer(Wave9CertIssuer(), queue: DispatchQueue.global())
    mtrRequire(!params.shouldAdvertiseOperational, "no advertising without daemon")
}
