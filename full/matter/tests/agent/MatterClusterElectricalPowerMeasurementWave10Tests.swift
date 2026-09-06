import Foundation
import Dispatch
import Matter

func testClusterElectricalPowerMeasurementDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterElectricalPowerMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterElectricalPowerMeasurement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAccuracy(with: MTRReadParams())
    _ = cluster.readAttributeActiveCurrent(with: MTRReadParams())
    _ = cluster.readAttributeActivePower(with: MTRReadParams())
    _ = cluster.readAttributeApparentCurrent(with: MTRReadParams())
    _ = cluster.readAttributeApparentPower(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeFrequency(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeHarmonicCurrents(with: MTRReadParams())
    _ = cluster.readAttributeHarmonicPhases(with: MTRReadParams())
    _ = cluster.readAttributeNeutralCurrent(with: MTRReadParams())
    _ = cluster.readAttributeNumberOfMeasurementTypes(with: MTRReadParams())
    _ = cluster.readAttributePowerFactor(with: MTRReadParams())
    _ = cluster.readAttributePowerMode(with: MTRReadParams())
    _ = cluster.readAttributeRMSCurrent(with: MTRReadParams())
    _ = cluster.readAttributeRMSPower(with: MTRReadParams())
    _ = cluster.readAttributeRMSVoltage(with: MTRReadParams())
    _ = cluster.readAttributeRanges(with: MTRReadParams())
    _ = cluster.readAttributeReactiveCurrent(with: MTRReadParams())
    _ = cluster.readAttributeReactivePower(with: MTRReadParams())
    _ = cluster.readAttributeVoltage(with: MTRReadParams())
}

func testClusterElectricalPowerMeasurementInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    _ = MTRClusterElectricalPowerMeasurement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

