import Foundation
import Dispatch
import Matter

func testClusterTimeSynchronizationInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterTimeSynchronization(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterTimeSynchronizationDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterTimeSynchronization(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterTimeSynchronization init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeDSTOffsetListMaxSize(with: MTRReadParams())
    _ = cluster.readAttributeDSTOffset(with: MTRReadParams())
    _ = cluster.readAttributeDefaultNTP(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeGranularity(with: MTRReadParams())
    _ = cluster.readAttributeLocalTime(with: MTRReadParams())
    _ = cluster.readAttributeNTPServerAvailable(with: MTRReadParams())
    _ = cluster.readAttributeSupportsDNSResolve(with: MTRReadParams())
    _ = cluster.readAttributeTimeSource(with: MTRReadParams())
    _ = cluster.readAttributeTimeZoneDatabase(with: MTRReadParams())
    _ = cluster.readAttributeTimeZoneListMaxSize(with: MTRReadParams())
    _ = cluster.readAttributeTimeZone(with: MTRReadParams())
    _ = cluster.readAttributeTrustedTimeSource(with: MTRReadParams())
    _ = cluster.readAttributeUTCTime(with: MTRReadParams())
}

func testClusterTimeSynchronizationCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterTimeSynchronization(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterTimeSynchronization init")
        return
    }
    cluster.setDSTOffsetWith(MTRTimeSynchronizationClusterSetDSTOffsetParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.setDefaultNTPWith(MTRTimeSynchronizationClusterSetDefaultNTPParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.setTimeZoneWith(MTRTimeSynchronizationClusterSetTimeZoneParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.setTrustedTimeSourceWith(MTRTimeSynchronizationClusterSetTrustedTimeSourceParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.setUTCTimeWith(MTRTimeSynchronizationClusterSetUTCTimeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}
