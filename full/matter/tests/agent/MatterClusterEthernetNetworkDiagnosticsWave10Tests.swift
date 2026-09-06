import Foundation
import Dispatch
import Matter

func testClusterEthernetNetworkDiagnosticsInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterEthernetNetworkDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterEthernetNetworkDiagnostics(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterEthernetNetworkDiagnosticsDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterEthernetNetworkDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterEthernetNetworkDiagnostics init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeCarrierDetect(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCollisionCount(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeFullDuplex(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeOverrunCount(with: MTRReadParams())
    _ = cluster.readAttributePHYRate(with: MTRReadParams())
    _ = cluster.readAttributePacketRxCount(with: MTRReadParams())
    _ = cluster.readAttributePacketTxCount(with: MTRReadParams())
    _ = cluster.readAttributeTimeSinceReset(with: MTRReadParams())
    _ = cluster.readAttributeTxErrCount(with: MTRReadParams())
}

func testClusterEthernetNetworkDiagnosticsCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterEthernetNetworkDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterEthernetNetworkDiagnostics init")
        return
    }
    cluster.resetCounts(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.resetCounts(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.resetCounts(with: MTREthernetNetworkDiagnosticsClusterResetCountsParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.resetCounts(with: MTREthernetNetworkDiagnosticsClusterResetCountsParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}
