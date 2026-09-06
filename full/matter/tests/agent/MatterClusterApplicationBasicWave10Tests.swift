import Foundation
import Dispatch
import Matter

func testClusterApplicationBasicInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterApplicationBasic(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterApplicationBasic(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterApplicationBasicDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterApplicationBasic(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterApplicationBasic init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAllowedVendorList(with: MTRReadParams())
    _ = cluster.readAttributeApplicationName(with: MTRReadParams())
    _ = cluster.readAttributeApplicationVersion(with: MTRReadParams())
    _ = cluster.readAttributeApplication(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeProductID(with: MTRReadParams())
    _ = cluster.readAttributeStatus(with: MTRReadParams())
    _ = cluster.readAttributeVendorID(with: MTRReadParams())
    _ = cluster.readAttributeVendorName(with: MTRReadParams())
}
