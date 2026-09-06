import Foundation
import Dispatch
import Matter

func testClusterGeneralCommissioningInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterGeneralCommissioning(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterGeneralCommissioning(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterGeneralCommissioningCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterGeneralCommissioning(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterGeneralCommissioning init")
        return
    }
    cluster.armFailSafe(with: MTRGeneralCommissioningClusterArmFailSafeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.armFailSafe(with: MTRGeneralCommissioningClusterArmFailSafeParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.commissioningComplete(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.commissioningComplete(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.commissioningComplete(with: MTRGeneralCommissioningClusterCommissioningCompleteParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.commissioningComplete(with: MTRGeneralCommissioningClusterCommissioningCompleteParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.setRegulatoryConfigWith(MTRGeneralCommissioningClusterSetRegulatoryConfigParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.setRegulatoryConfigWith(MTRGeneralCommissioningClusterSetRegulatoryConfigParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testClusterGeneralCommissioningDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterGeneralCommissioning(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterGeneralCommissioning init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeBasicCommissioningInfo(with: MTRReadParams())
    _ = cluster.readAttributeBreadcrumb(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLocationCapability(with: MTRReadParams())
    _ = cluster.readAttributeRegulatoryConfig(with: MTRReadParams())
    _ = cluster.readAttributeSupportsConcurrentConnection(with: MTRReadParams())
    cluster.writeAttributeBreadcrumb(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeBreadcrumb(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeBreadcrumb(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeBreadcrumb(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
