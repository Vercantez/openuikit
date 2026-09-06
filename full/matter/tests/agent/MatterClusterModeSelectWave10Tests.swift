import Foundation
import Dispatch
import Matter

func testClusterModeSelectDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterModeSelect(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterModeSelect init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeCurrentMode(with: MTRReadParams())
    _ = cluster.readAttributeDescription(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeOnMode(with: MTRReadParams())
    _ = cluster.readAttributeStandardNamespace(with: MTRReadParams())
    _ = cluster.readAttributeStartUpMode(with: MTRReadParams())
    _ = cluster.readAttributeSupportedModes(with: MTRReadParams())
    cluster.writeAttributeOnMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeOnMode(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeOnMode(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
    cluster.writeAttributeOnMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeStartUpMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeStartUpMode(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
}

func testClusterModeSelectCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterModeSelect(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterModeSelect init")
        return
    }
    cluster.changeToMode(with: MTRModeSelectClusterChangeToModeParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
    cluster.changeToMode(with: MTRModeSelectClusterChangeToModeParams(), expectedValues: [], expectedValueInterval: n(1), completionHandler: { err in mtrExpectInvalidState(err) })
}

func testClusterModeSelectInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    _ = MTRClusterModeSelect(device: device, endpoint: 1, queue: DispatchQueue.global())
    _ = MTRClusterModeSelect(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

