import Foundation
import Dispatch
import Matter

func testClusterSoftwareDiagnosticsDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterSoftwareDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterSoftwareDiagnostics init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCurrentHeapFree(with: MTRReadParams())
    _ = cluster.readAttributeCurrentHeapHighWatermark(with: MTRReadParams())
    _ = cluster.readAttributeCurrentHeapUsed(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeThreadMetrics(with: MTRReadParams())
}

func testClusterSoftwareDiagnosticsCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterSoftwareDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterSoftwareDiagnostics init")
        return
    }
    cluster.resetWatermarks(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.resetWatermarks(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.resetWatermarks(with: MTRSoftwareDiagnosticsClusterResetWatermarksParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.resetWatermarks(with: MTRSoftwareDiagnosticsClusterResetWatermarksParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterSoftwareDiagnosticsInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    _ = MTRClusterSoftwareDiagnostics(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterSoftwareDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

