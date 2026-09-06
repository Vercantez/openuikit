import Foundation
import Dispatch
import Matter

func testClusterSmokeCOAlarmInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterSmokeCOAlarm(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterSmokeCOAlarmDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterSmokeCOAlarm(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterSmokeCOAlarm init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeBatteryAlert(with: MTRReadParams())
    _ = cluster.readAttributeCOState(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeContaminationState(with: MTRReadParams())
    _ = cluster.readAttributeDeviceMuted(with: MTRReadParams())
    _ = cluster.readAttributeEndOfServiceAlert(with: MTRReadParams())
    _ = cluster.readAttributeExpiryDate(with: MTRReadParams())
    _ = cluster.readAttributeExpressedState(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeHardwareFaultAlert(with: MTRReadParams())
    _ = cluster.readAttributeInterconnectCOAlarm(with: MTRReadParams())
    _ = cluster.readAttributeInterconnectSmoke(with: MTRReadParams())
    _ = cluster.readAttributeSmokeSensitivityLevel(with: MTRReadParams())
    _ = cluster.readAttributeSmokeState(with: MTRReadParams())
    _ = cluster.readAttributeTestInProgress(with: MTRReadParams())
    cluster.writeAttributeSmokeSensitivityLevel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeSmokeSensitivityLevel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeSmokeSensitivityLevel(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeSmokeSensitivityLevel(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterSmokeCOAlarmCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterSmokeCOAlarm(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterSmokeCOAlarm init")
        return
    }
    cluster.selfTestRequest(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.selfTestRequest(with: MTRSmokeCOAlarmClusterSelfTestRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}
