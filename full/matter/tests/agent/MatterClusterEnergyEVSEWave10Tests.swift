import Foundation
import Dispatch
import Matter

func testClusterEnergyEVSEInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterEnergyEVSE(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterEnergyEVSECommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterEnergyEVSE(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterEnergyEVSE init")
        return
    }
    cluster.clearTargets(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.clearTargets(with: MTREnergyEVSEClusterClearTargetsParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.disable(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.disable(with: MTREnergyEVSEClusterDisableParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.enableCharging(with: MTREnergyEVSEClusterEnableChargingParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.getTargetsWithExpectedValues([], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.getTargetsWith(MTREnergyEVSEClusterGetTargetsParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.setTargetsWith(MTREnergyEVSEClusterSetTargetsParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.startDiagnostics(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.startDiagnostics(with: MTREnergyEVSEClusterStartDiagnosticsParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterEnergyEVSEDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterEnergyEVSE(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterEnergyEVSE init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeApproximateEVEfficiency(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeChargingEnabledUntil(with: MTRReadParams())
    _ = cluster.readAttributeCircuitCapacity(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFaultState(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeMaximumChargeCurrent(with: MTRReadParams())
    _ = cluster.readAttributeMinimumChargeCurrent(with: MTRReadParams())
    _ = cluster.readAttributeNextChargeRequiredEnergy(with: MTRReadParams())
    _ = cluster.readAttributeNextChargeStartTime(with: MTRReadParams())
    _ = cluster.readAttributeNextChargeTargetSoC(with: MTRReadParams())
    _ = cluster.readAttributeNextChargeTargetTime(with: MTRReadParams())
    _ = cluster.readAttributeRandomizationDelayWindow(with: MTRReadParams())
    _ = cluster.readAttributeSessionDuration(with: MTRReadParams())
    _ = cluster.readAttributeSessionEnergyCharged(with: MTRReadParams())
    _ = cluster.readAttributeSessionID(with: MTRReadParams())
    _ = cluster.readAttributeState(with: MTRReadParams())
    _ = cluster.readAttributeSupplyState(with: MTRReadParams())
    _ = cluster.readAttributeUserMaximumChargeCurrent(with: MTRReadParams())
    cluster.writeAttributeApproximateEVEfficiency(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeApproximateEVEfficiency(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeRandomizationDelayWindow(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeRandomizationDelayWindow(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeUserMaximumChargeCurrent(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeUserMaximumChargeCurrent(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeApproximateEVEfficiency(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeAcceptedCommandList(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
