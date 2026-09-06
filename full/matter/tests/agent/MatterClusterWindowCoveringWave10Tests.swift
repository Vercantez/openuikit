import Foundation
import Dispatch
import Matter

func testClusterWindowCoveringInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterWindowCovering(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterWindowCovering(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterWindowCoveringCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterWindowCovering(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterWindowCovering init")
        return
    }
    cluster.downOrClose(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.downOrClose(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.downOrClose(with: MTRWindowCoveringClusterDownOrCloseParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.downOrClose(with: MTRWindowCoveringClusterDownOrCloseParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.goToLiftPercentage(with: MTRWindowCoveringClusterGoToLiftPercentageParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.goToLiftPercentage(with: MTRWindowCoveringClusterGoToLiftPercentageParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.goToLiftValue(with: MTRWindowCoveringClusterGoToLiftValueParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.goToLiftValue(with: MTRWindowCoveringClusterGoToLiftValueParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.goToTiltPercentage(with: MTRWindowCoveringClusterGoToTiltPercentageParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.goToTiltPercentage(with: MTRWindowCoveringClusterGoToTiltPercentageParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.goToTiltValue(with: MTRWindowCoveringClusterGoToTiltValueParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.goToTiltValue(with: MTRWindowCoveringClusterGoToTiltValueParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.stopMotion(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.stopMotion(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.stopMotion(with: MTRWindowCoveringClusterStopMotionParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.stopMotion(with: MTRWindowCoveringClusterStopMotionParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.upOrOpen(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.upOrOpen(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.upOrOpen(with: MTRWindowCoveringClusterUpOrOpenParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.upOrOpen(with: MTRWindowCoveringClusterUpOrOpenParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterWindowCoveringDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterWindowCovering(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterWindowCovering init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeConfigStatus(with: MTRReadParams())
    _ = cluster.readAttributeCurrentPositionLiftPercent100ths(with: MTRReadParams())
    _ = cluster.readAttributeCurrentPositionLiftPercentage(with: MTRReadParams())
    _ = cluster.readAttributeCurrentPositionLift(with: MTRReadParams())
    _ = cluster.readAttributeCurrentPositionTiltPercent100ths(with: MTRReadParams())
    _ = cluster.readAttributeCurrentPositionTiltPercentage(with: MTRReadParams())
    _ = cluster.readAttributeCurrentPositionTilt(with: MTRReadParams())
    _ = cluster.readAttributeEndProductType(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeInstalledClosedLimitLift(with: MTRReadParams())
    _ = cluster.readAttributeInstalledClosedLimitTilt(with: MTRReadParams())
    _ = cluster.readAttributeInstalledOpenLimitLift(with: MTRReadParams())
    _ = cluster.readAttributeInstalledOpenLimitTilt(with: MTRReadParams())
    _ = cluster.readAttributeMode(with: MTRReadParams())
    _ = cluster.readAttributeNumberOfActuationsLift(with: MTRReadParams())
    _ = cluster.readAttributeNumberOfActuationsTilt(with: MTRReadParams())
    _ = cluster.readAttributeOperationalStatus(with: MTRReadParams())
    _ = cluster.readAttributePhysicalClosedLimitLift(with: MTRReadParams())
    _ = cluster.readAttributePhysicalClosedLimitTilt(with: MTRReadParams())
    _ = cluster.readAttributeSafetyStatus(with: MTRReadParams())
    _ = cluster.readAttributeTargetPositionLiftPercent100ths(with: MTRReadParams())
    _ = cluster.readAttributeTargetPositionTiltPercent100ths(with: MTRReadParams())
    _ = cluster.readAttributeType(with: MTRReadParams())
    cluster.writeAttributeMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeMode(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeAcceptedCommandList(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
