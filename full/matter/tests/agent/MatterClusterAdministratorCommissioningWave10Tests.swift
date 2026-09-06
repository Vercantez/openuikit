import Foundation
import Dispatch
import Matter

func testClusterAdministratorCommissioningInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterAdministratorCommissioning(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterAdministratorCommissioning(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterAdministratorCommissioningCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterAdministratorCommissioning(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterAdministratorCommissioning init")
        return
    }
    cluster.openBasicCommissioningWindow(with: MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.openBasicCommissioningWindow(with: MTRAdministratorCommissioningClusterOpenBasicCommissioningWindowParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.openWindow(with: MTRAdministratorCommissioningClusterOpenCommissioningWindowParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.openWindow(with: MTRAdministratorCommissioningClusterOpenCommissioningWindowParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.revokeCommissioning(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.revokeCommissioning(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.revokeCommissioning(with: MTRAdministratorCommissioningClusterRevokeCommissioningParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.revokeCommissioning(with: MTRAdministratorCommissioningClusterRevokeCommissioningParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterAdministratorCommissioningDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterAdministratorCommissioning(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterAdministratorCommissioning init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAdminFabricIndex(with: MTRReadParams())
    _ = cluster.readAttributeAdminVendorId(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeWindowStatus(with: MTRReadParams())
}
