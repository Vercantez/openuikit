import Foundation
import Dispatch
import Matter

func testClusterPressureMeasurementInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterPressureMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterPressureMeasurement(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterPressureMeasurementDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterPressureMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterPressureMeasurement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeMaxMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMaxScaledValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMinMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMinScaledValue(with: MTRReadParams())
    _ = cluster.readAttributeScale(with: MTRReadParams())
    _ = cluster.readAttributeScaledTolerance(with: MTRReadParams())
    _ = cluster.readAttributeScaledValue(with: MTRReadParams())
    _ = cluster.readAttributeTolerance(with: MTRReadParams())
}
