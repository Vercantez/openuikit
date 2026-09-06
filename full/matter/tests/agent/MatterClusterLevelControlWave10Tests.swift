import Foundation
import Dispatch
import Matter

func testClusterLevelControlInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterLevelControl(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterLevelControl(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterLevelControlCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterLevelControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterLevelControl init")
        return
    }
    cluster.moveToClosestFrequency(with: MTRLevelControlClusterMoveToClosestFrequencyParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.moveToClosestFrequency(with: MTRLevelControlClusterMoveToClosestFrequencyParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.moveToLevelWithOnOff(with: MTRLevelControlClusterMoveToLevelWithOnOffParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.moveToLevelWithOnOff(with: MTRLevelControlClusterMoveToLevelWithOnOffParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.moveToLevel(with: MTRLevelControlClusterMoveToLevelParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.moveToLevel(with: MTRLevelControlClusterMoveToLevelParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.moveWithOnOff(with: MTRLevelControlClusterMoveWithOnOffParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.moveWithOnOff(with: MTRLevelControlClusterMoveWithOnOffParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.move(with: MTRLevelControlClusterMoveParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.move(with: MTRLevelControlClusterMoveParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.stepWithOnOff(with: MTRLevelControlClusterStepWithOnOffParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.stepWithOnOff(with: MTRLevelControlClusterStepWithOnOffParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.step(with: MTRLevelControlClusterStepParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.step(with: MTRLevelControlClusterStepParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.stopWithOnOff(with: MTRLevelControlClusterStopWithOnOffParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.stopWithOnOff(with: MTRLevelControlClusterStopWithOnOffParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.stop(with: MTRLevelControlClusterStopParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.stop(with: MTRLevelControlClusterStopParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterLevelControlDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterLevelControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterLevelControl init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCurrentFrequency(with: MTRReadParams())
    _ = cluster.readAttributeCurrentLevel(with: MTRReadParams())
    _ = cluster.readAttributeDefaultMoveRate(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeMaxFrequency(with: MTRReadParams())
    _ = cluster.readAttributeMaxLevel(with: MTRReadParams())
    _ = cluster.readAttributeMinFrequency(with: MTRReadParams())
    _ = cluster.readAttributeMinLevel(with: MTRReadParams())
    _ = cluster.readAttributeOffTransitionTime(with: MTRReadParams())
    _ = cluster.readAttributeOnLevel(with: MTRReadParams())
    _ = cluster.readAttributeOnOffTransitionTime(with: MTRReadParams())
    _ = cluster.readAttributeOnTransitionTime(with: MTRReadParams())
    _ = cluster.readAttributeOptions(with: MTRReadParams())
    _ = cluster.readAttributeRemainingTime(with: MTRReadParams())
    _ = cluster.readAttributeStartUpCurrentLevel(with: MTRReadParams())
    cluster.writeAttributeDefaultMoveRate(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeDefaultMoveRate(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeOffTransitionTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeOffTransitionTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeOnLevel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeOnLevel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeOnOffTransitionTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeOnOffTransitionTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeOnTransitionTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeOnTransitionTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeOptions(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeOptions(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeStartUpCurrentLevel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeStartUpCurrentLevel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeDefaultMoveRate(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeDefaultMoveRate(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
