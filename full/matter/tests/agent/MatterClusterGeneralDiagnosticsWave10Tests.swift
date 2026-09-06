import Foundation
import Dispatch
import Matter

func testClusterGeneralDiagnosticsDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterGeneralDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterGeneralDiagnostics init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeActiveHardwareFaults(with: MTRReadParams())
    _ = cluster.readAttributeActiveNetworkFaults(with: MTRReadParams())
    _ = cluster.readAttributeActiveRadioFaults(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeBootReason(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeNetworkInterfaces(with: MTRReadParams())
    _ = cluster.readAttributeRebootCount(with: MTRReadParams())
    _ = cluster.readAttributeTestEventTriggersEnabled(with: MTRReadParams())
    _ = cluster.readAttributeTotalOperationalHours(with: MTRReadParams())
    _ = cluster.readAttributeUpTime(with: MTRReadParams())
}

func testClusterGeneralDiagnosticsCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterGeneralDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterGeneralDiagnostics init")
        return
    }
    cluster.payloadTestRequest(with: MTRGeneralDiagnosticsClusterPayloadTestRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.testEventTrigger(with: MTRGeneralDiagnosticsClusterTestEventTriggerParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.testEventTrigger(with: MTRGeneralDiagnosticsClusterTestEventTriggerParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.timeSnapshot(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.timeSnapshot(with: MTRGeneralDiagnosticsClusterTimeSnapshotParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}

func testClusterGeneralDiagnosticsInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    _ = MTRClusterGeneralDiagnostics(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterGeneralDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterGeneralDiagnosticsReadFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterGeneralDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterGeneralDiagnostics init")
        return
    }
    _ = cluster.readAttributeBootReasons(with: MTRReadParams())
}

