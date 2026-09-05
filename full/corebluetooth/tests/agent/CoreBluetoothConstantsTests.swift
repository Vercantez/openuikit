@_spi(OpenUIKitHost) import CoreBluetooth
import Foundation

func testAdvertisementDataKeys() {
    let keys: [(String, String)] = [
        (CBAdvertisementDataLocalNameKey, "CBAdvertisementDataLocalNameKey"),
        (CBAdvertisementDataManufacturerDataKey, "CBAdvertisementDataManufacturerDataKey"),
        (CBAdvertisementDataServiceDataKey, "CBAdvertisementDataServiceDataKey"),
        (CBAdvertisementDataServiceUUIDsKey, "CBAdvertisementDataServiceUUIDsKey"),
        (CBAdvertisementDataOverflowServiceUUIDsKey, "CBAdvertisementDataOverflowServiceUUIDsKey"),
        (CBAdvertisementDataTxPowerLevelKey, "CBAdvertisementDataTxPowerLevelKey"),
        (CBAdvertisementDataIsConnectable, "CBAdvertisementDataIsConnectable"),
        (CBAdvertisementDataSolicitedServiceUUIDsKey, "CBAdvertisementDataSolicitedServiceUUIDsKey"),
    ]
    for (value, expected) in keys {
        precondition(value == expected)
        precondition(!value.isEmpty)
    }
}

func testCentralManagerOptionKeys() {
    let keys: [String] = [
        CBCentralManagerOptionShowPowerAlertKey,
        CBCentralManagerOptionRestoreIdentifierKey,
        CBCentralManagerOptionDeviceAccessForMedia,
        CBCentralManagerScanOptionAllowDuplicatesKey,
        CBCentralManagerScanOptionSolicitedServiceUUIDsKey,
        CBCentralManagerRestoredStatePeripheralsKey,
        CBCentralManagerRestoredStateScanServicesKey,
        CBCentralManagerRestoredStateScanOptionsKey,
    ]
    for key in keys {
        precondition(!key.isEmpty)
        precondition(key.hasPrefix("CB"))
    }
}

func testConnectPeripheralOptionKeys() {
    let keys: [String] = [
        CBConnectPeripheralOptionNotifyOnConnectionKey,
        CBConnectPeripheralOptionNotifyOnDisconnectionKey,
        CBConnectPeripheralOptionNotifyOnNotificationKey,
        CBConnectPeripheralOptionStartDelayKey,
        CBConnectPeripheralOptionEnableTransportBridgingKey,
        CBConnectPeripheralOptionRequiresANCS,
        CBConnectPeripheralOptionEnableAutoReconnect,
    ]
    for key in keys {
        precondition(!key.isEmpty)
        precondition(key.hasPrefix("CBConnectPeripheralOption"))
    }
}

func testPeripheralManagerOptionKeys() {
    let keys: [String] = [
        CBPeripheralManagerOptionShowPowerAlertKey,
        CBPeripheralManagerOptionRestoreIdentifierKey,
        CBPeripheralManagerRestoredStateServicesKey,
        CBPeripheralManagerRestoredStateAdvertisementDataKey,
    ]
    for key in keys {
        precondition(!key.isEmpty)
        precondition(key.hasPrefix("CBPeripheralManager"))
    }
}

func testCBUUIDCharacteristicStrings() {
    precondition(CBUUIDCharacteristicExtendedPropertiesString == "2900")
    precondition(CBUUIDCharacteristicUserDescriptionString == "2901")
    precondition(CBUUIDClientCharacteristicConfigurationString == "2902")
    precondition(CBUUIDServerCharacteristicConfigurationString == "2903")
    precondition(CBUUIDCharacteristicFormatString == "2904")
    precondition(CBUUIDCharacteristicAggregateFormatString == "2905")
    precondition(CBUUIDCharacteristicValidRangeString == "2906")
    precondition(CBUUIDL2CAPPSMCharacteristicString == "ABDD3056-28FA-441D-A470-55A75A52553A")
    precondition(!CBUUIDCharacteristicObservationScheduleString.isEmpty)
}

func testErrorDomainConstants() {
    precondition(CBErrorDomain == "CBErrorDomain")
    precondition(CBATTErrorDomain == "CBATTErrorDomain")
}

func testCBL2CAPPSMAlias() {
    let psm: CBL2CAPPSM = 0x0080
    precondition(psm == 128)
    let typed: UInt16 = psm
    precondition(typed == 128)
}

func testConnectionEventMatchingOptionValues() {
    let supplied = CBConnectionEventMatchingOption(rawValue: "host-supplied")
    precondition(supplied.rawValue == "host-supplied")
    precondition(
        CBConnectionEventMatchingOption.peripheralUUIDs
            != CBConnectionEventMatchingOption.serviceUUIDs
    )
    precondition(!CBConnectionEventMatchingOption.peripheralUUIDs.rawValue.isEmpty)
    precondition(!CBConnectionEventMatchingOption.serviceUUIDs.rawValue.isEmpty)
    _ = supplied.hashValue
    var hasher = Hasher()
    supplied.hash(into: &hasher)
    CBConnectionEventMatchingOption.peripheralUUIDs.hash(into: &hasher)
    _ = hasher.finalize()
}
