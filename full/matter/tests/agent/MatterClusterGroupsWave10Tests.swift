import Foundation
import Dispatch
import Matter

func testClusterGroupsInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterGroups(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterGroups(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterGroupsCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterGroups(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterGroups init")
        return
    }
    cluster.addGroupIfIdentifying(with: MTRGroupsClusterAddGroupIfIdentifyingParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.addGroupIfIdentifying(with: MTRGroupsClusterAddGroupIfIdentifyingParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.addGroup(with: MTRGroupsClusterAddGroupParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.addGroup(with: MTRGroupsClusterAddGroupParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.getGroupMembership(with: MTRGroupsClusterGetGroupMembershipParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.getGroupMembership(with: MTRGroupsClusterGetGroupMembershipParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.removeAllGroups(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.removeAllGroups(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.removeAllGroups(with: MTRGroupsClusterRemoveAllGroupsParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.removeAllGroups(with: MTRGroupsClusterRemoveAllGroupsParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.removeGroup(with: MTRGroupsClusterRemoveGroupParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.removeGroup(with: MTRGroupsClusterRemoveGroupParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.viewGroup(with: MTRGroupsClusterViewGroupParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.viewGroup(with: MTRGroupsClusterViewGroupParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testClusterGroupsDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterGroups(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterGroups init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeNameSupport(with: MTRReadParams())
}
