import Foundation
import Dispatch
import Matter

func testClusterWiFiNetworkDiagnosticsInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterWiFiNetworkDiagnostics(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterWiFiNetworkDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterWiFiNetworkDiagnosticsDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterWiFiNetworkDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterWiFiNetworkDiagnostics init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeBSSID(with: MTRReadParams())
    _ = cluster.readAttributeBeaconLostCount(with: MTRReadParams())
    _ = cluster.readAttributeBeaconRxCount(with: MTRReadParams())
    _ = cluster.readAttributeBssid(with: MTRReadParams())
    _ = cluster.readAttributeChannelNumber(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCurrentMaxRate(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeOverrunCount(with: MTRReadParams())
    _ = cluster.readAttributePacketMulticastRxCount(with: MTRReadParams())
    _ = cluster.readAttributePacketMulticastTxCount(with: MTRReadParams())
    _ = cluster.readAttributePacketUnicastRxCount(with: MTRReadParams())
    _ = cluster.readAttributePacketUnicastTxCount(with: MTRReadParams())
    _ = cluster.readAttributeRSSI(with: MTRReadParams())
    _ = cluster.readAttributeRssi(with: MTRReadParams())
    _ = cluster.readAttributeSecurityType(with: MTRReadParams())
    _ = cluster.readAttributeWiFiVersion(with: MTRReadParams())
}

func testClusterWiFiNetworkDiagnosticsCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterWiFiNetworkDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterWiFiNetworkDiagnostics init")
        return
    }
    cluster.resetCounts(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.resetCounts(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.resetCounts(with: MTRWiFiNetworkDiagnosticsClusterResetCountsParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.resetCounts(with: MTRWiFiNetworkDiagnosticsClusterResetCountsParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}
