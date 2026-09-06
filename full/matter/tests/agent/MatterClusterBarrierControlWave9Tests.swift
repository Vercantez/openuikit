import Foundation
import Dispatch
import Matter

func testClusterBarrierControlCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterBarrierControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterBarrierControl init")
        return
    }
    cluster.barrierControlGoToPercent(with: MTRBarrierControlClusterBarrierControlGoToPercentParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.barrierControlGoToPercent(with: MTRBarrierControlClusterBarrierControlGoToPercentParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.barrierControlStop(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.barrierControlStop(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.barrierControlStop(with: MTRBarrierControlClusterBarrierControlStopParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.barrierControlStop(with: MTRBarrierControlClusterBarrierControlStopParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterBarrierControlInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterBarrierControl(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterBarrierControl(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterBarrierControlDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterBarrierControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterBarrierControl init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeBarrierCapabilities(with: MTRReadParams())
    _ = cluster.readAttributeBarrierCloseEvents(with: MTRReadParams())
    _ = cluster.readAttributeBarrierClosePeriod(with: MTRReadParams())
    _ = cluster.readAttributeBarrierCommandCloseEvents(with: MTRReadParams())
    _ = cluster.readAttributeBarrierCommandOpenEvents(with: MTRReadParams())
    _ = cluster.readAttributeBarrierMovingState(with: MTRReadParams())
    _ = cluster.readAttributeBarrierOpenEvents(with: MTRReadParams())
    _ = cluster.readAttributeBarrierOpenPeriod(with: MTRReadParams())
    _ = cluster.readAttributeBarrierPosition(with: MTRReadParams())
    _ = cluster.readAttributeBarrierSafetyStatus(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    cluster.writeAttributeBarrierCloseEvents(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeBarrierCloseEvents(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeBarrierClosePeriod(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeBarrierClosePeriod(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeBarrierCommandCloseEvents(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeBarrierCommandCloseEvents(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeBarrierCommandOpenEvents(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeBarrierCommandOpenEvents(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeBarrierOpenEvents(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeBarrierOpenEvents(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeBarrierOpenPeriod(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeBarrierOpenPeriod(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeBarrierCloseEvents(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeBarrierCloseEvents(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
