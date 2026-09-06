import Foundation
import Dispatch
import Matter

func testClusterIlluminanceMeasurementDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterIlluminanceMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterIlluminanceMeasurement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLightSensorType(with: MTRReadParams())
    _ = cluster.readAttributeMaxMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeMinMeasuredValue(with: MTRReadParams())
    _ = cluster.readAttributeTolerance(with: MTRReadParams())
}

func testClusterIlluminanceMeasurementInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    _ = MTRClusterIlluminanceMeasurement(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterIlluminanceMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

