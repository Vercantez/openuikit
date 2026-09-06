import Foundation
import Dispatch
import Matter

func testClusterContentLauncherInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterContentLauncher(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterContentLauncher(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterContentLauncherCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterContentLauncher(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterContentLauncher init")
        return
    }
    cluster.launchContent(with: MTRContentLauncherClusterLaunchContentParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.launchContent(with: MTRContentLauncherClusterLaunchContentParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.launchURL(with: MTRContentLauncherClusterLaunchURLParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.launchURL(with: MTRContentLauncherClusterLaunchURLParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testClusterContentLauncherDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterContentLauncher(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterContentLauncher init")
        return
    }
    _ = cluster.readAttributeAcceptHeader(with: MTRReadParams())
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeSupportedStreamingProtocols(with: MTRReadParams())
    cluster.writeAttributeSupportedStreamingProtocols(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeSupportedStreamingProtocols(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeSupportedStreamingProtocols(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeSupportedStreamingProtocols(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
