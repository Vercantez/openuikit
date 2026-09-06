import Foundation
import Dispatch
import Matter

func testClusterNetworkCommissioningCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterNetworkCommissioning(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterNetworkCommissioning init")
        return
    }
    cluster.addOrUpdateThreadNetwork(with: MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.addOrUpdateThreadNetwork(with: MTRNetworkCommissioningClusterAddOrUpdateThreadNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.addOrUpdateWiFiNetwork(with: MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.addOrUpdateWiFiNetwork(with: MTRNetworkCommissioningClusterAddOrUpdateWiFiNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.connectNetwork(with: MTRNetworkCommissioningClusterConnectNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.connectNetwork(with: MTRNetworkCommissioningClusterConnectNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.removeNetwork(with: MTRNetworkCommissioningClusterRemoveNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.removeNetwork(with: MTRNetworkCommissioningClusterRemoveNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.reorderNetwork(with: MTRNetworkCommissioningClusterReorderNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.reorderNetwork(with: MTRNetworkCommissioningClusterReorderNetworkParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.scanNetworks(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.scanNetworks(with: MTRNetworkCommissioningClusterScanNetworksParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.scanNetworks(with: MTRNetworkCommissioningClusterScanNetworksParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testClusterNetworkCommissioningInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterNetworkCommissioning(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterNetworkCommissioning(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterNetworkCommissioningDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterNetworkCommissioning(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterNetworkCommissioning init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeConnectMaxTimeSeconds(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeInterfaceEnabled(with: MTRReadParams())
    _ = cluster.readAttributeLastConnectErrorValue(with: MTRReadParams())
    _ = cluster.readAttributeLastNetworkID(with: MTRReadParams())
    _ = cluster.readAttributeLastNetworkingStatus(with: MTRReadParams())
    _ = cluster.readAttributeMaxNetworks(with: MTRReadParams())
    _ = cluster.readAttributeNetworks(with: MTRReadParams())
    _ = cluster.readAttributeScanMaxTimeSeconds(with: MTRReadParams())
    _ = cluster.readAttributeSupportedThreadFeatures(with: MTRReadParams())
    _ = cluster.readAttributeSupportedWiFiBands(with: MTRReadParams())
    _ = cluster.readAttributeThreadVersion(with: MTRReadParams())
    cluster.writeAttributeInterfaceEnabled(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeInterfaceEnabled(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeInterfaceEnabled(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeInterfaceEnabled(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
