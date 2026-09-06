import Foundation
import Dispatch
import Matter

func testClusterIdentifyInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterIdentify(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterIdentify(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterIdentifyCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterIdentify(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterIdentify init")
        return
    }
    cluster.identify(with: MTRIdentifyClusterIdentifyParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.identify(with: MTRIdentifyClusterIdentifyParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.triggerEffect(with: MTRIdentifyClusterTriggerEffectParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.triggerEffect(with: MTRIdentifyClusterTriggerEffectParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterIdentifyDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterIdentify(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterIdentify init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeIdentifyTime(with: MTRReadParams())
    _ = cluster.readAttributeIdentifyType(with: MTRReadParams())
    cluster.writeAttributeIdentifyTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeIdentifyTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeIdentifyTime(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeIdentifyTime(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
