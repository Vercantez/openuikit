import Foundation
import HomeKit

private func hmRequire(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("HomeKit test failed: \(message)\n", stderr)
        exit(1)
    }
}

final class RecordingAccessoryDelegate: NSObject, HMAccessoryDelegate, @unchecked Sendable {
    var log: [String] = []
    func accessoryDidUpdateName(_ accessory: HMAccessory) { log.append("name:\(accessory.name)") }
    func accessory(_ accessory: HMAccessory, didUpdateNameFor service: HMService) {
        log.append("serviceName:\(service.name)")
    }
    func accessory(_ accessory: HMAccessory, didUpdateAssociatedServiceTypeFor service: HMService) {
        log.append("assoc:\(service.associatedServiceType ?? "nil")")
    }
    func accessoryDidUpdateServices(_ accessory: HMAccessory) { log.append("services:\(accessory.services.count)") }
    func accessory(_ accessory: HMAccessory, didAdd profile: HMAccessoryProfile) { log.append("addProfile") }
    func accessory(_ accessory: HMAccessory, didRemove profile: HMAccessoryProfile) { log.append("removeProfile") }
    func accessoryDidUpdateReachability(_ accessory: HMAccessory) {
        log.append("reach:\(accessory.isReachable)")
    }
    func accessory(
        _ accessory: HMAccessory,
        service: HMService,
        didUpdateValueFor characteristic: HMCharacteristic
    ) {
        log.append("value:\(characteristic.characteristicType)")
    }
    func accessory(_ accessory: HMAccessory, didUpdateFirmwareVersion firmwareVersion: String) {
        log.append("fw:\(firmwareVersion)")
    }
}

func testAccessoryGraphAndDelegate() {
    let category = HMAccessoryCategory.host_make(
        categoryType: HMAccessoryCategoryTypeLightbulb,
        localizedDescription: "Lightbulb"
    )
    hmRequire(category.categoryType == HMAccessoryCategoryTypeLightbulb, "cat type")
    hmRequire(category.localizedDescription == "Lightbulb", "cat desc")
    let power = HMCharacteristic.host_make(
        type: HMCharacteristicTypePowerState,
        properties: [
            HMCharacteristicPropertyReadable,
            HMCharacteristicPropertyWritable,
            HMCharacteristicPropertySupportsEventNotification,
        ],
        metadata: nil,
        value: NSNumber(value: false)
    )
    let service = HMService.host_make(
        name: "Bulb",
        serviceType: HMServiceTypeLightbulb,
        characteristics: [power],
        primary: true
    )
    hmRequire(service.isPrimaryService, "primary")
    hmRequire(service.isUserInteractive, "interactive")
    hmRequire(service.localizedDescription == "Bulb", "desc")
    hmRequire(service.uniqueIdentifier.uuidString.isEmpty == false, "svc uuid")
    hmRequire(service.characteristics.count == 1, "chars")
    hmRequire(power.service === service, "char service")
    hmRequire(service.matterEndpointID == nil, "no matter")
    service.host_setMatterEndpointID(7)
    hmRequire(service.matterEndpointID == 7, "endpoint")
    service.host_setLinkedServices([])
    hmRequire(service.linkedServices?.isEmpty == true, "linked")

    let accessory = HMAccessory.host_make(
        name: "Lamp",
        category: category,
        services: [service],
        reachable: false,
        supportsIdentify: true,
        firmwareVersion: "1.0"
    )
    hmRequire(accessory.name == "Lamp", "name")
    hmRequire(accessory.identifier == accessory.uniqueIdentifier, "identifier alias")
    hmRequire(accessory.category.categoryType == HMAccessoryCategoryTypeLightbulb, "category")
    hmRequire(accessory.services.count == 1, "services")
    hmRequire(service.accessory === accessory, "backref")
    hmRequire(accessory.isReachable == false, "unreachable")
    hmRequire(accessory.supportsIdentify, "identify flag")
    hmRequire(accessory.firmwareVersion == "1.0", "fw")
    hmRequire(accessory.isVendorAccessory == false, "not vendor")
    hmRequire(accessory.bridgedAccessories.isEmpty, "no bridged")
    hmRequire(accessory.uniqueIdentifiersForBridgedAccessories == nil, "ids nil")
    hmRequire(accessory.identifiersForBridgedAccessories == nil, "alias nil")
    hmRequire(accessory.profiles.isEmpty, "no profiles")
    hmRequire(accessory.cameraProfiles == nil, "no cameras")
    hmRequire(accessory.home == nil, "no home")
    hmRequire(accessory.room == nil, "no room")
    hmRequire(accessory.hapInstanceID == nil, "no hap")
    hmRequire(accessory.matterNodeID == nil, "no matter node")
    let constructed = HMAccessory()
    hmRequire(constructed.name == "", "empty init")
    let emptyService = HMService()
    hmRequire(emptyService.serviceType == HMServiceTypeSwitch, "svc init")

    let recorder = RecordingAccessoryDelegate()
    accessory.delegate = recorder
    hmRequire(accessory.delegate === recorder, "delegate")

    var error: (any Error)?
    accessory.updateName("Desk Lamp") { error = $0 }
    hmRequire(error == nil && accessory.name == "Desk Lamp", "rename")
    accessory.host_setReachable(true)
    hmRequire(accessory.isReachable, "reachable")
    accessory.host_setFirmwareVersion("1.1")
    let child = HMAccessory.host_make(name: "Child")
    accessory.host_setBridgedAccessories([child])
    hmRequire(accessory.isBridged, "bridged")
    hmRequire(accessory.bridgedAccessories.count == 1, "children")
    hmRequire(accessory.uniqueIdentifiersForBridgedAccessories?.first == child.uniqueIdentifier, "child id")
    hmRequire(accessory.identifiersForBridgedAccessories?.first == child.uniqueIdentifier, "alias id")
    accessory.host_setVendorAccessory(true, matterNodeID: 9, hapInstanceID: 3)
    hmRequire(accessory.isVendorAccessory && accessory.matterNodeID == 9 && accessory.hapInstanceID == 3, "vendor")

    service.updateName("Ceiling") { error = $0 }
    hmRequire(error == nil && service.name == "Ceiling", "svc rename")
    service.updateAssociatedServiceType(HMServiceTypeSwitch) { error = $0 }
    hmRequire(error == nil && service.associatedServiceType == HMServiceTypeSwitch, "assoc")
    service.updateAssociatedServiceType("not-a-type") { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.invalidAssociatedServiceType.rawValue, "bad assoc")

    let profile = HMAccessoryProfile()
    accessory.host_setProfiles([profile])
    hmRequire(accessory.profiles.count == 1, "profiles")

    power.enableNotification(true) { error = $0 }
    hmRequire(error == nil && power.isNotificationEnabled, "notify on")
    power.enableNotification(true) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.notificationAlreadyEnabled.rawValue, "already")
    power.writeValue(NSNumber(value: true)) { error = $0 }
    hmRequire(error == nil, "write reachable")
    hmRequire((power.value as? NSNumber)?.boolValue == true, "stored")
    var readErr: (any Error)?
    power.readValue { readErr = $0 }
    hmRequire(readErr == nil, "read reachable")

    accessory.identify { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.accessoryNotReachable.rawValue, "identify still hap")

    hmRequire(recorder.log.contains("name:Desk Lamp"), "name cb")
    hmRequire(recorder.log.contains("reach:true"), "reach cb")
    hmRequire(recorder.log.contains("fw:1.1"), "fw cb")
    hmRequire(recorder.log.contains("serviceName:Ceiling"), "svc name cb")
    hmRequire(recorder.log.contains("assoc:HMServiceTypeSwitch"), "assoc cb")
    hmRequire(recorder.log.contains("addProfile"), "add profile")
    hmRequire(recorder.log.contains("value:HMCharacteristicTypePowerState"), "value cb")
}

func testCharacteristicWriteNotifyAndMetadata() {
    let meta = HMCharacteristicMetadata.host_makeFull(
        format: HMCharacteristicMetadataFormatUInt8,
        units: HMCharacteristicMetadataUnitsPercentage,
        minimumValue: 0,
        maximumValue: 100,
        stepValue: 5,
        maxLength: nil,
        validValues: nil,
        manufacturerDescription: "Brightness"
    )
    hmRequire(meta.manufacturerDescription == "Brightness", "mfr desc")
    hmRequire(meta.minimumValue?.intValue == 0, "min")
    hmRequire(meta.maximumValue?.intValue == 100, "max")
    hmRequire(meta.stepValue?.intValue == 5, "step")
    hmRequire(meta.maxLength == nil, "maxLength nil")
    hmRequire(meta.validValues == nil, "valid nil")
    hmRequire(meta.contains(NSNumber(value: 10)), "step ok")
    hmRequire(!meta.contains(NSNumber(value: 12)), "step reject")
    hmRequire(!meta.contains(NSNumber(value: 101)), "max reject")

    let allowed = HMCharacteristicMetadata.host_makeFull(
        format: HMCharacteristicMetadataFormatUInt8,
        units: nil,
        minimumValue: nil,
        maximumValue: nil,
        stepValue: nil,
        maxLength: nil,
        validValues: [1, 2, 3],
        manufacturerDescription: nil
    )
    hmRequire(allowed.contains(NSNumber(value: 2)), "valid ok")
    hmRequire(!allowed.contains(NSNumber(value: 4)), "valid reject")

    let stringMeta = HMCharacteristicMetadata()
    stringMeta.format = HMCharacteristicMetadataFormatString
    stringMeta.maxLength = 4
    hmRequire(stringMeta.host_acceptsWrite("abcd") == nil, "len ok")
    hmRequire(
        stringMeta.host_acceptsWrite("abcde")?.code == .stringLongerThanMaximum,
        "len reject"
    )

    let writable = HMCharacteristic.host_make(
        type: HMCharacteristicTypeBrightness,
        properties: [HMCharacteristicPropertyWritable],
        metadata: meta,
        value: NSNumber(value: 10)
    )
    hmRequire(writable.uniqueIdentifier.uuidString.isEmpty == false, "uuid")
    hmRequire(writable.localizedDescription == HMCharacteristicTypeBrightness, "desc")
    hmRequire(writable.properties.contains(HMCharacteristicPropertyWritable), "props")
    hmRequire(writable.metadata === meta, "meta")
    hmRequire(writable.service == nil, "unbound")
    let constructed = HMCharacteristic()
    hmRequire(constructed.characteristicType == HMCharacteristicTypePowerState, "init type")
    let metaInit = HMCharacteristicMetadata()
    hmRequire(metaInit.format == nil, "meta init")

    var error: (any Error)?
    writable.host_writeLocal(NSNumber(value: 12)) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.invalidValueType.rawValue, "step")
    writable.enableNotification(true) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.notificationNotSupported.rawValue, "no event")
    writable.updateAuthorizationData(Data([0x01])) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.operationNotSupported.rawValue, "no auth prop")

    let auth = HMCharacteristic.host_make(
        type: HMCharacteristicTypePowerState,
        properties: [HMCharacteristicPropertyRequiresAuthorizationData],
        metadata: nil,
        value: nil
    )
    auth.updateAuthorizationData(nil) { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.invalidOrMissingAuthorizationData.rawValue, "missing auth")
    auth.updateAuthorizationData(Data([0xAA])) { error = $0 }
    hmRequire(error == nil, "auth ok")

    let writeOnly = HMCharacteristic.host_make(
        type: HMCharacteristicTypePowerState,
        properties: [HMCharacteristicPropertyWritable],
        metadata: nil,
        value: nil
    )
    let service = HMService.host_make(
        name: "S",
        serviceType: HMServiceTypeSwitch,
        characteristics: [writeOnly]
    )
    let accessory = HMAccessory.host_make(name: "A", services: [service], reachable: true)
    _ = accessory
    writeOnly.readValue { error = $0 }
    hmRequire(hmNSErrorCode(error) == HMError.Code.writeOnlyCharacteristic.rawValue, "write-only read")
}
