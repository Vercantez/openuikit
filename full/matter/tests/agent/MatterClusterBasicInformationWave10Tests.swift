import Foundation
import Dispatch
import Matter

func testClusterBasicInformationInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterBasicInformation(device: device, endpointID: n(1), queue: DispatchQueue.global())
}

func testClusterBasicInformationDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterBasicInformation(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterBasicInformation init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeCapabilityMinima(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeDataModelRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeHardwareVersionString(with: MTRReadParams())
    _ = cluster.readAttributeHardwareVersion(with: MTRReadParams())
    _ = cluster.readAttributeLocalConfigDisabled(with: MTRReadParams())
    _ = cluster.readAttributeLocation(with: MTRReadParams())
    _ = cluster.readAttributeManufacturingDate(with: MTRReadParams())
    _ = cluster.readAttributeMaxPathsPerInvoke(with: MTRReadParams())
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
    _ = cluster.readAttributeSpecificationVersion(with: MTRReadParams())
    _ = cluster.readAttributeUniqueID(with: MTRReadParams())
    _ = cluster.readAttributeVendorID(with: MTRReadParams())
    _ = cluster.readAttributeVendorName(with: MTRReadParams())
    cluster.writeAttributeLocalConfigDisabled(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeLocalConfigDisabled(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeLocation(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeLocation(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeNodeLabel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeNodeLabel(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeLocalConfigDisabled(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeLocalConfigDisabled(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
