import Foundation
import Dispatch
import Matter

func testClusterOnOffInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterOnOff(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterOnOff(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterOnOffCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOnOff(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOnOff init")
        return
    }
    cluster.offWithEffect(with: MTROnOffClusterOffWithEffectParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.offWithEffect(with: MTROnOffClusterOffWithEffectParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.off(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.off(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.off(with: MTROnOffClusterOffParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.off(with: MTROnOffClusterOffParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.on(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.on(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.on(with: MTROnOffClusterOnParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.on(with: MTROnOffClusterOnParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.onWithRecallGlobalScene(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.onWithRecallGlobalScene(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.onWithRecallGlobalScene(with: MTROnOffClusterOnWithRecallGlobalSceneParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.onWithRecallGlobalScene(with: MTROnOffClusterOnWithRecallGlobalSceneParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.onWithTimedOff(with: MTROnOffClusterOnWithTimedOffParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.onWithTimedOff(with: MTROnOffClusterOnWithTimedOffParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.toggle(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.toggle(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.toggle(with: MTROnOffClusterToggleParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.toggle(with: MTROnOffClusterToggleParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterOnOffDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterOnOff(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterOnOff init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeGlobalSceneControl(with: MTRReadParams())
    _ = cluster.readAttributeOffWaitTime(with: MTRReadParams())
    _ = cluster.readAttributeOnOff(with: MTRReadParams())
    _ = cluster.readAttributeOnTime(with: MTRReadParams())
    _ = cluster.readAttributeStartUp(with: MTRReadParams())
    cluster.writeAttributeOffWaitTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeOffWaitTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeOnTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeOnTime(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeStartUp(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeStartUp(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeOffWaitTime(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeOffWaitTime(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
