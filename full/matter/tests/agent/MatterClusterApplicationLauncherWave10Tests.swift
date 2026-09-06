import Foundation
import Dispatch
import Matter

func testClusterApplicationLauncherInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterApplicationLauncher(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterApplicationLauncher(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterApplicationLauncherCommand() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterApplicationLauncher(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterApplicationLauncher init")
        return
    }
    cluster.hideApp(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.hideApp(with: MTRApplicationLauncherClusterHideAppParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.hideApp(with: MTRApplicationLauncherClusterHideAppParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.launchApp(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.launchApp(with: MTRApplicationLauncherClusterLaunchAppParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.launchApp(with: MTRApplicationLauncherClusterLaunchAppParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
    cluster.stopApp(withExpectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.stopApp(with: MTRApplicationLauncherClusterStopAppParams(), expectedValues: [], expectedValueInterval: n(1), completion: { _, err in mtrExpectInvalidState(err) })
    cluster.stopApp(with: MTRApplicationLauncherClusterStopAppParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { _, err in mtrExpectInvalidState(err) })
}

func testClusterApplicationLauncherDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterApplicationLauncher(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterApplicationLauncher init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeCatalogList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCurrentApp(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    cluster.writeAttributeCurrentApp(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeCurrentApp(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeCurrentApp(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeAcceptedCommandList(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
