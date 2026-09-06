import Foundation
import Dispatch
import Matter

func testClusterThreadNetworkDiagnosticsInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterThreadNetworkDiagnostics(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterThreadNetworkDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterThreadNetworkDiagnosticsDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterThreadNetworkDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterThreadNetworkDiagnostics init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeActiveNetworkFaultsList(with: MTRReadParams())
    _ = cluster.readAttributeActiveTimestamp(with: MTRReadParams())
    _ = cluster.readAttributeAttachAttemptCount(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeBetterPartitionAttachAttemptCount(with: MTRReadParams())
    _ = cluster.readAttributeChannelPage0Mask(with: MTRReadParams())
    _ = cluster.readAttributeChannel(with: MTRReadParams())
    _ = cluster.readAttributeChildRoleCount(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeDataVersion(with: MTRReadParams())
    _ = cluster.readAttributeDelay(with: MTRReadParams())
    _ = cluster.readAttributeDetachedRoleCount(with: MTRReadParams())
    _ = cluster.readAttributeExtendedPanId(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeLeaderRoleCount(with: MTRReadParams())
    _ = cluster.readAttributeLeaderRouterId(with: MTRReadParams())
    _ = cluster.readAttributeMeshLocalPrefix(with: MTRReadParams())
    _ = cluster.readAttributeNeighborTableList(with: MTRReadParams())
    _ = cluster.readAttributeNeighborTable(with: MTRReadParams())
    _ = cluster.readAttributeNetworkName(with: MTRReadParams())
    _ = cluster.readAttributeOperationalDatasetComponents(with: MTRReadParams())
    _ = cluster.readAttributeOverrunCount(with: MTRReadParams())
    _ = cluster.readAttributePanId(with: MTRReadParams())
    _ = cluster.readAttributeParentChangeCount(with: MTRReadParams())
    _ = cluster.readAttributePartitionIdChangeCount(with: MTRReadParams())
    _ = cluster.readAttributePartitionId(with: MTRReadParams())
    _ = cluster.readAttributePendingTimestamp(with: MTRReadParams())
    _ = cluster.readAttributeRouteTableList(with: MTRReadParams())
    _ = cluster.readAttributeRouteTable(with: MTRReadParams())
    _ = cluster.readAttributeRouterRoleCount(with: MTRReadParams())
    _ = cluster.readAttributeRoutingRole(with: MTRReadParams())
    _ = cluster.readAttributeRxAddressFilteredCount(with: MTRReadParams())
    _ = cluster.readAttributeRxBeaconCount(with: MTRReadParams())
    _ = cluster.readAttributeRxBeaconRequestCount(with: MTRReadParams())
    _ = cluster.readAttributeRxBroadcastCount(with: MTRReadParams())
    _ = cluster.readAttributeRxDataCount(with: MTRReadParams())
    _ = cluster.readAttributeRxDataPollCount(with: MTRReadParams())
    _ = cluster.readAttributeRxDestAddrFilteredCount(with: MTRReadParams())
    _ = cluster.readAttributeRxDuplicatedCount(with: MTRReadParams())
    _ = cluster.readAttributeRxErrFcsCount(with: MTRReadParams())
    _ = cluster.readAttributeRxErrInvalidSrcAddrCount(with: MTRReadParams())
    _ = cluster.readAttributeRxErrNoFrameCount(with: MTRReadParams())
    _ = cluster.readAttributeRxErrOtherCount(with: MTRReadParams())
    _ = cluster.readAttributeRxErrSecCount(with: MTRReadParams())
    _ = cluster.readAttributeRxErrUnknownNeighborCount(with: MTRReadParams())
    _ = cluster.readAttributeRxOtherCount(with: MTRReadParams())
    _ = cluster.readAttributeRxTotalCount(with: MTRReadParams())
    _ = cluster.readAttributeRxUnicastCount(with: MTRReadParams())
    _ = cluster.readAttributeSecurityPolicy(with: MTRReadParams())
    _ = cluster.readAttributeStableDataVersion(with: MTRReadParams())
    _ = cluster.readAttributeTxAckRequestedCount(with: MTRReadParams())
    _ = cluster.readAttributeTxAckedCount(with: MTRReadParams())
    _ = cluster.readAttributeTxBeaconCount(with: MTRReadParams())
    _ = cluster.readAttributeTxBeaconRequestCount(with: MTRReadParams())
    _ = cluster.readAttributeTxBroadcastCount(with: MTRReadParams())
    _ = cluster.readAttributeTxDataCount(with: MTRReadParams())
    _ = cluster.readAttributeTxDataPollCount(with: MTRReadParams())
    _ = cluster.readAttributeTxDirectMaxRetryExpiryCount(with: MTRReadParams())
    _ = cluster.readAttributeTxErrAbortCount(with: MTRReadParams())
    _ = cluster.readAttributeTxErrBusyChannelCount(with: MTRReadParams())
    _ = cluster.readAttributeTxErrCcaCount(with: MTRReadParams())
    _ = cluster.readAttributeTxIndirectMaxRetryExpiryCount(with: MTRReadParams())
    _ = cluster.readAttributeTxNoAckRequestedCount(with: MTRReadParams())
    _ = cluster.readAttributeTxOtherCount(with: MTRReadParams())
    _ = cluster.readAttributeTxRetryCount(with: MTRReadParams())
    _ = cluster.readAttributeTxTotalCount(with: MTRReadParams())
    _ = cluster.readAttributeTxUnicastCount(with: MTRReadParams())
    _ = cluster.readAttributeWeighting(with: MTRReadParams())
}

func testClusterThreadNetworkDiagnosticsCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterThreadNetworkDiagnostics(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterThreadNetworkDiagnostics init")
        return
    }
    cluster.resetCounts(withExpectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.resetCounts(withExpectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
    cluster.resetCounts(with: MTRThreadNetworkDiagnosticsClusterResetCountsParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.resetCounts(with: MTRThreadNetworkDiagnosticsClusterResetCountsParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}
