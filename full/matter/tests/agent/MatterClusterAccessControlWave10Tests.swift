import Foundation
import Dispatch
import Matter

func testClusterAccessControlInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterAccessControl(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterAccessControl(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterAccessControlDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterAccessControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterAccessControl init")
        return
    }
    _ = cluster.readAttributeACL(with: MTRReadParams())
    _ = cluster.readAttributeARL(with: MTRReadParams())
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAccessControlEntriesPerFabric(with: MTRReadParams())
    _ = cluster.readAttributeAcl(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCommissioningARL(with: MTRReadParams())
    _ = cluster.readAttributeExtension(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeSubjectsPerAccessControlEntry(with: MTRReadParams())
    _ = cluster.readAttributeTargetsPerAccessControlEntry(with: MTRReadParams())
    cluster.writeAttributeACL(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeACL(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeAcl(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeAcl(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeExtension(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeExtension(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeACL(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeACL(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}

func testClusterAccessControlCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterAccessControl(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterAccessControl init")
        return
    }
    cluster.reviewFabricRestrictions(with: MTRAccessControlClusterReviewFabricRestrictionsParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
}
