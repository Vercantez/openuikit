import Foundation
import Dispatch
import Matter

func testClusterFanControlInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterFanControl(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterFanControl(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterFanControlDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterFanControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterFanControl init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAirflowDirection(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFanModeSequence(with: MTRReadParams())
    _ = cluster.readAttributeFanMode(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributePercentCurrent(with: MTRReadParams())
    _ = cluster.readAttributePercentSetting(with: MTRReadParams())
    _ = cluster.readAttributeRockSetting(with: MTRReadParams())
    _ = cluster.readAttributeRockSupport(with: MTRReadParams())
    _ = cluster.readAttributeSpeedCurrent(with: MTRReadParams())
    _ = cluster.readAttributeSpeedMax(with: MTRReadParams())
    _ = cluster.readAttributeSpeedSetting(with: MTRReadParams())
    _ = cluster.readAttributeWindSetting(with: MTRReadParams())
    _ = cluster.readAttributeWindSupport(with: MTRReadParams())
    cluster.writeAttributeAirflowDirection(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeAirflowDirection(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeFanModeSequence(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeFanModeSequence(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeFanMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeFanMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributePercentSetting(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributePercentSetting(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeRockSetting(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeRockSetting(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeSpeedSetting(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeSpeedSetting(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeWindSetting(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeWindSetting(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeAirflowDirection(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeAirflowDirection(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterFanControlCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterFanControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterFanControl init")
        return
    }
    cluster.step(with: MTRFanControlClusterStepParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}
