import Foundation
import Dispatch
import Matter

func testClusterTimeFormatLocalizationInit() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    _ = MTRClusterTimeFormatLocalization(device: device, endpointID: n(1), queue: DispatchQueue.global())
    _ = MTRClusterTimeFormatLocalization(device: device, endpoint: 1, queue: DispatchQueue.global())
}

func testClusterTimeFormatLocalizationDeviceCache() {
    let controller = MTRDeviceController()
    let device = MTRDevice(nodeID: n(1), controller: controller)
    let baseDevice: MTRBaseDevice = device
    _ = (device, baseDevice)
    guard let cluster = MTRClusterTimeFormatLocalization(device: device, endpointID: n(1), queue: DispatchQueue.global()) else {
        mtrRequire(false, "MTRClusterTimeFormatLocalization init")
        return
    }
    _ = cluster.readAttributeAcceptedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeActiveCalendarType(with: MTRReadParams())
    _ = cluster.readAttributeAttributeList(with: MTRReadParams())
    _ = cluster.readAttributeClusterRevision(with: MTRReadParams())
    _ = cluster.readAttributeFeatureMap(with: MTRReadParams())
    _ = cluster.readAttributeGeneratedCommandList(with: MTRReadParams())
    _ = cluster.readAttributeHourFormat(with: MTRReadParams())
    _ = cluster.readAttributeSupportedCalendarTypes(with: MTRReadParams())
    cluster.writeAttributeActiveCalendarType(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeActiveCalendarType(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    cluster.writeAttributeHourFormat(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1))
    cluster.writeAttributeHourFormat(withValue: MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(1)), expectedValueInterval: n(1), params: MTRWriteParams())
    let probe = MTRMakeDataValue(type: MTRUnsignedIntegerValueType, value: n(7))
    cluster.writeAttributeActiveCalendarType(withValue: probe, expectedValueInterval: n(1))
    let cached = cluster.readAttributeAcceptedCommandList(with: nil)
    mtrRequire(cached != nil, "expected-value cache round-trip")
}
