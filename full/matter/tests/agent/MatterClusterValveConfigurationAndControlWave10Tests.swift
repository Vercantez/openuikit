import Foundation
import Dispatch
import Matter

func testClusterValveConfigurationAndControlInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterValveConfigurationAndControl(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterValveConfigurationAndControlCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterValveConfigurationAndControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterValveConfigurationAndControl init")
        return
    }
    cluster.close(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.close(with: MTRValveConfigurationAndControlClusterCloseParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.open(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.open(with: MTRValveConfigurationAndControlClusterOpenParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterValveConfigurationAndControlDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterValveConfigurationAndControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterValveConfigurationAndControl init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeAutoCloseTime(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCurrentLevel(with: MTRReadParams())
    _ = cluster.readAttributeCurrentState(with: MTRReadParams())
    _ = cluster.readAttributeDefaultOpenDuration(with: MTRReadParams())
    _ = cluster.readAttributeDefaultOpenLevel(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLevelStep(with: MTRReadParams())
    _ = cluster.readAttributeOpenDuration(with: MTRReadParams())
    _ = cluster.readAttributeRemainingDuration(with: MTRReadParams())
    _ = cluster.readAttributeTargetLevel(with: MTRReadParams())
    _ = cluster.readAttributeTargetState(with: MTRReadParams())
    _ = cluster.readAttributeValveFault(with: MTRReadParams())
    cluster.writeAttributeDefaultOpenDuration(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeDefaultOpenDuration(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeDefaultOpenLevel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeDefaultOpenLevel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeDefaultOpenDuration(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeDefaultOpenDuration(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
