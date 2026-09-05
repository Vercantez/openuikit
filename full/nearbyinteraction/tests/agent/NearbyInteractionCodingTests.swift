@_spi(OpenUIKitHost) import NearbyInteraction
import Foundation

private func niArchiveRoundTrip<T: NSObject & NSSecureCoding>(_ value: T) -> T {
    let data: Data
    do {
        data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
    } catch {
        preconditionFailure("archive failed: \(error)")
    }
    do {
        guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: T.self, from: data) else {
            preconditionFailure("expected restored \(T.self)")
        }
        return restored
    } catch {
        preconditionFailure("unarchive failed: \(error)")
    }
}

private func niRejectsEmptyCoder<T: NSObject & NSSecureCoding>(_ type: T.Type) {
    do {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: "ni-malformed",
            requiringSecureCoding: true
        )
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        precondition(type.init(coder: unarchiver) == nil)
    } catch {
        preconditionFailure("malformed archive setup failed: \(error)")
    }
}

func testNIDiscoveryTokenCoding() {
    let token = NIDiscoveryToken.hostToken()
    let restored = niArchiveRoundTrip(token)
    precondition(restored.isEqual(token))
    niRejectsEmptyCoder(NIDiscoveryToken.self)
}

func testNINearbyObjectCoding() {
    let token = NIDiscoveryToken.hostToken()
    let object = NINearbyObject.hostObject(
        discoveryToken: token,
        distance: 3,
        direction: simd_float3(1, 0, 0),
        horizontalAngle: 0.5,
        verticalDirectionEstimate: .below
    )
    let restored = niArchiveRoundTrip(object)
    precondition(restored.discoveryToken.isEqual(token))
    precondition(restored.distance == 3)
    precondition(restored.direction == simd_float3(1, 0, 0))
    precondition(restored.horizontalAngle == 0.5)
    precondition(restored.verticalDirectionEstimate == .below)
    niRejectsEmptyCoder(NINearbyObject.self)
}

func testNIDLTDOAMeasurementCoding() {
    let measurement = NIDLTDOAMeasurement.hostMeasurement(
        address: 8,
        measurementType: .final,
        transmitTime: 4,
        receiveTime: 5,
        signalStrength: -10,
        carrierFrequencyOffset: 0.5,
        coordinatesType: .relative,
        coordinates: simd_double3(9, 8, 7)
    )
    let restored = niArchiveRoundTrip(measurement)
    precondition(restored.address == 8)
    precondition(restored.measurementType == .final)
    precondition(restored.coordinatesType == .relative)
    precondition(restored.coordinates == simd_double3(9, 8, 7))
}

func testNIAlgorithmConvergenceCoding() {
    let unknown = niArchiveRoundTrip(NIAlgorithmConvergence(status: .unknown))
    precondition(unknown.status == .unknown)
    let converged = niArchiveRoundTrip(NIAlgorithmConvergence(status: .converged))
    precondition(converged.status == .converged)
    let pending = niArchiveRoundTrip(
        NIAlgorithmConvergence(status: .notConverged([.insufficientSignalStrength]))
    )
    precondition(pending.status == .notConverged([.insufficientSignalStrength]))
}

func testNIConfigurationCoding() {
    let token = NIDiscoveryToken.hostToken()
    let peer = NINearbyPeerConfiguration(peerToken: token)
    peer.isExtendedDistanceMeasurementEnabled = true
    let restoredPeer = niArchiveRoundTrip(peer)
    precondition(restoredPeer.peerDiscoveryToken.isEqual(token))
    precondition(restoredPeer.isExtendedDistanceMeasurementEnabled)

    let dtdoa = NIDLTDOAConfiguration(networkIdentifier: 12)
    let restoredDL = niArchiveRoundTrip(dtdoa)
    precondition(restoredDL.networkIdentifier == 12)

    let accessory = NINearbyAccessoryConfiguration.hostConfiguration(token: token)
    accessory.isCameraAssistanceEnabled = true
    let restoredAccessory = niArchiveRoundTrip(accessory)
    precondition(restoredAccessory.accessoryDiscoveryToken.isEqual(token))
    precondition(restoredAccessory.isCameraAssistanceEnabled)

    let base = NIConfiguration()
    let restoredBase = niArchiveRoundTrip(base)
    precondition(restoredBase !== base)
}
