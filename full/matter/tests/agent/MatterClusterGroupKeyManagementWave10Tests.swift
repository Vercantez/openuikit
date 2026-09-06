import Foundation
import Dispatch
import Matter

func testClusterGroupKeyManagementInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterGroupKeyManagement(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterGroupKeyManagement(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterGroupKeyManagementCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterGroupKeyManagement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterGroupKeyManagement init")
        return
    }
    cluster.keySetReadAllIndices(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.keySetReadAllIndices(with: MTRGroupKeyManagementClusterKeySetReadAllIndicesParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.keySetReadAllIndices(with: MTRGroupKeyManagementClusterKeySetReadAllIndicesParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.keySetRead(with: MTRGroupKeyManagementClusterKeySetReadParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.keySetRead(with: MTRGroupKeyManagementClusterKeySetReadParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.keySetRemove(with: MTRGroupKeyManagementClusterKeySetRemoveParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.keySetRemove(with: MTRGroupKeyManagementClusterKeySetRemoveParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.keySetWrite(with: MTRGroupKeyManagementClusterKeySetWriteParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.keySetWrite(with: MTRGroupKeyManagementClusterKeySetWriteParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterGroupKeyManagementDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterGroupKeyManagement(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterGroupKeyManagement init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeGroupKeyMap(with: MTRReadParams())
    _ = cluster.readAttributeGroupTable(with: MTRReadParams())
    _ = cluster.readAttributeMaxGroupKeysPerFabric(with: MTRReadParams())
    _ = cluster.readAttributeMaxGroupsPerFabric(with: MTRReadParams())
    cluster.writeAttributeGroupKeyMap(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeGroupKeyMap(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeGroupKeyMap(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeGroupKeyMap(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
