import Foundation
import Dispatch
import Matter

func testClusterDeviceEnergyManagementInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterDeviceEnergyManagement(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterDeviceEnergyManagementCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterDeviceEnergyManagement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterDeviceEnergyManagement init")
        return
    }
    cluster.cancelPowerAdjustRequest(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.cancelPowerAdjustRequest(with: MTRDeviceEnergyManagementClusterCancelPowerAdjustRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.cancelRequest(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.cancelRequest(with: MTRDeviceEnergyManagementClusterCancelRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.modifyForecastRequest(with: MTRDeviceEnergyManagementClusterModifyForecastRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.pauseRequest(with: MTRDeviceEnergyManagementClusterPauseRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.powerAdjustRequest(with: MTRDeviceEnergyManagementClusterPowerAdjustRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.requestConstraintBasedForecast(with: MTRDeviceEnergyManagementClusterRequestConstraintBasedForecastParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.resumeRequest(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.resumeRequest(with: MTRDeviceEnergyManagementClusterResumeRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.startTimeAdjustRequest(with: MTRDeviceEnergyManagementClusterStartTimeAdjustRequestParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterDeviceEnergyManagementDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterDeviceEnergyManagement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterDeviceEnergyManagement init")
        return
    }
    _ = cluster.readAttributeAbsMaxPower(with: MTRReadParams())
    _ = cluster.readAttributeAbsMinPower(with: MTRReadParams())
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeESACanGenerate(with: MTRReadParams())
    _ = cluster.readAttributeESAState(with: MTRReadParams())
    _ = cluster.readAttributeESAType(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeForecast(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeOptOutState(with: MTRReadParams())
    _ = cluster.readAttributePowerAdjustmentCapability(with: MTRReadParams())
}
