import Foundation
import Dispatch
import Matter

func testClusterFlowMeasurementDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterFlowMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterFlowMeasurement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeMaxMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMinMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeTolerance(with: MTRReadParams())
}

func testClusterFlowMeasurementInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    _ = MTRClusterFlowMeasurement(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterFlowMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

