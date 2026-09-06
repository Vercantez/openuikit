import Foundation
import Dispatch
import Matter

func testClusterBinaryInputBasicInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterBinaryInputBasic(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterBinaryInputBasic(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterBinaryInputBasicDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterBinaryInputBasic(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterBinaryInputBasic init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeActiveText(with: MTRReadParams())
    _ = cluster.readAttributeApplicationType(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeDescription(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeInactiveText(with: MTRReadParams())
    _ = cluster.readAttributeOutOfService(with: MTRReadParams())
    _ = cluster.readAttributePolarity(with: MTRReadParams())
    _ = cluster.readAttributePresentValue(with: MTRReadParams())
    _ = cluster.readAttributeReliability(with: MTRReadParams())
    _ = cluster.readAttributeStatusFlags(with: MTRReadParams())
    cluster.writeAttributeActiveText(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeActiveText(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeDescription(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeDescription(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeInactiveText(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeInactiveText(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeOutOfService(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeOutOfService(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributePresentValue(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributePresentValue(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeReliability(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeReliability(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeActiveText(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeActiveText(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
