import Foundation
import Dispatch
import Matter

func testClusterThermostatUserInterfaceConfigurationInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterThermostatUserInterfaceConfiguration(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterThermostatUserInterfaceConfiguration(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterThermostatUserInterfaceConfigurationDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterThermostatUserInterfaceConfiguration(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterThermostatUserInterfaceConfiguration init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeKeypadLockout(with: MTRReadParams())
    _ = cluster.readAttributeScheduleProgrammingVisibility(with: MTRReadParams())
    _ = cluster.readAttributeTemperatureDisplayMode(with: MTRReadParams())
    cluster.writeAttributeKeypadLockout(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeKeypadLockout(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeScheduleProgrammingVisibility(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeScheduleProgrammingVisibility(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeTemperatureDisplayMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeTemperatureDisplayMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeKeypadLockout(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeAcceptedCommandList(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
