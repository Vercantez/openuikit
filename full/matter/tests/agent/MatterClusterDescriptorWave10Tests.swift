import Foundation
import Dispatch
import Matter

func testClusterDescriptorInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterDescriptor(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterDescriptor(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterDescriptorDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterDescriptor(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterDescriptor init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClientList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeDeviceList(with: MTRReadParams())
    _ = cluster.readAttributeDeviceTypeList(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributePartsList(with: MTRReadParams())
    _ = cluster.readAttributeServerList(with: MTRReadParams())
}
