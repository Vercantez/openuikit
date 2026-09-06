import Foundation
import Dispatch
import Matter

func testClusterBridgedDeviceBasicInformationDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterBridgedDeviceBasicInformation(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterBridgedDeviceBasicInformation init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeHardwareVersionString(with: MTRReadParams())
    _ = cluster.readAttributeHardwareVersion(with: MTRReadParams())
    _ = cluster.readAttributeManufacturingDate(with: MTRReadParams())
    _ = cluster.readAttributeNodeLabel(with: MTRReadParams())
    _ = cluster.readAttributePartNumber(with: MTRReadParams())
    _ = cluster.readAttributeProductAppearance(with: MTRReadParams())
    _ = cluster.readAttributeProductID(with: MTRReadParams())
    _ = cluster.readAttributeProductLabel(with: MTRReadParams())
    _ = cluster.readAttributeProductName(with: MTRReadParams())
    _ = cluster.readAttributeProductURL(with: MTRReadParams())
    _ = cluster.readAttributeReachable(with: MTRReadParams())
    _ = cluster.readAttributeSerialNumber(with: MTRReadParams())
    _ = cluster.readAttributeSoftwareVersionString(with: MTRReadParams())
    _ = cluster.readAttributeSoftwareVersion(with: MTRReadParams())
    _ = cluster.readAttributeUniqueID(with: MTRReadParams())
    _ = cluster.readAttributeVendorID(with: MTRReadParams())
    _ = cluster.readAttributeVendorName(with: MTRReadParams())
    cluster.writeAttributeNodeLabel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeNodeLabel(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeNodeLabel(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
    cluster.writeAttributeNodeLabel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
}

func testClusterBridgedDeviceBasicInformationCommandFailClosed() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    guard let cluster = MTRClusterBridgedDeviceBasicInformation(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterBridgedDeviceBasicInformation init")
        return
    }
    cluster.keepActive(with: MTRBridgedDeviceBasicInformationClusterKeepActiveParams(), expectedValues: [], expectedValueInterval: n(1), completion: { err in mtrExpectInvalidState(err) })
}

func testClusterBridgedDeviceBasicInformationInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)

    _ = MTRClusterBridgedDeviceBasicInformation(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

