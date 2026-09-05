@_spi(OpenUIKitHost) import CoreBluetooth
import Foundation

func testMutableCharacteristicModel() {
    let charUUID = CBUUID(string: "2A19")
    let characteristic = CBMutableCharacteristic(
        type: charUUID,
        properties: [.read, .notify],
        value: Data([0x64]),
        permissions: [.readable]
    )
    precondition(characteristic.uuid == charUUID)
    let asCharacteristic: CBCharacteristic = characteristic
    precondition(asCharacteristic.value == Data([0x64]))
    precondition(characteristic.permissions.contains(.readable))
    precondition(characteristic.properties.contains(.read))
    precondition(characteristic.subscribedCentrals == nil)
    precondition(characteristic.isBroadcasted == false)
    precondition(characteristic.isNotifying == false)
    characteristic.value = Data([0x01])
    characteristic.permissions = [.readable, .writeable]
    characteristic.properties = [.read, .write]
    precondition(characteristic.value == Data([0x01]))
}

func testMutableDescriptorOwnership() {
    let descriptor = CBMutableDescriptor(
        type: CBUUID(string: CBUUIDClientCharacteristicConfigurationString),
        value: Data([0x00, 0x00])
    )
    let otherDescriptor = CBMutableDescriptor(type: CBUUID(string: "2901"), value: "name")
    let characteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A19"),
        properties: [.read],
        value: nil,
        permissions: [.readable]
    )
    let otherCharacteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A29"),
        properties: [.read],
        value: nil,
        permissions: [.readable]
    )
    characteristic.descriptors = [descriptor]
    precondition(descriptor.characteristic === characteristic)
    let asDescriptor: CBDescriptor = descriptor
    _ = asDescriptor.value
    otherCharacteristic.descriptors = [descriptor]
    precondition(descriptor.characteristic === otherCharacteristic)
    otherCharacteristic.descriptors = [otherDescriptor]
    precondition(descriptor.characteristic == nil)
    precondition(otherDescriptor.characteristic === otherCharacteristic)
    precondition(otherDescriptor.value as? String == "name")
}

func testMutableServiceOwnership() {
    let serviceUUID = CBUUID(string: "180F")
    let otherServiceUUID = CBUUID(string: "180A")
    let characteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A19"),
        properties: [.read],
        value: Data([0x64]),
        permissions: [.readable]
    )
    let otherCharacteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A29"),
        properties: [.read],
        value: nil,
        permissions: [.readable]
    )
    let service = CBMutableService(type: serviceUUID, primary: true)
    let otherService = CBMutableService(type: otherServiceUUID, primary: false)
    precondition(service.isPrimary)
    let asService: CBService = service
    precondition(asService.uuid == serviceUUID)
    precondition(!otherService.isPrimary)
    precondition(service.peripheral == nil)
    precondition(service.uuid == serviceUUID)
    service.characteristics = [characteristic]
    precondition(characteristic.service === service)
    otherService.characteristics = [characteristic]
    precondition(characteristic.service === otherService)
    otherService.characteristics = [otherCharacteristic]
    precondition(characteristic.service == nil)
    precondition(otherCharacteristic.service === otherService)

    let included = CBMutableService(type: CBUUID(string: "1800"), primary: false)
    service.includedServices = [included]
    otherService.includedServices = [included]
    precondition(!(service.includedServices ?? []).contains(where: { $0 === included }))
    precondition((otherService.includedServices ?? []).contains(where: { $0 === included }))
    otherService.includedServices = []
    service.includedServices = [included]
    precondition((service.includedServices ?? []).contains(where: { $0 === included }))
    service.includedServices = nil
    precondition(service.includedServices == nil)
}

func testCBAttributeAndPeerIdentity() {
    let service = CBMutableService(type: CBUUID(string: "180F"), primary: true)
    let attribute: CBAttribute = service
    precondition(attribute.uuid == CBUUID(string: "180F"))
    let peer = CBPeripheral(hostIdentifier: UUID(), queue: nil)
    let asPeer: CBPeer = peer
    precondition(asPeer.identifier == peer.identifier)
    precondition(peer.identifier != UUID())
}

func testCBL2CAPChannelIdentity() {
    let peer = CBPeripheral(hostIdentifier: UUID(), queue: nil)
    let input = InputStream(data: Data([0x00]))
    let output = OutputStream.toMemory()
    let channel = CBL2CAPChannel(
        hostPeer: peer,
        psm: 0x0080,
        inputStream: input,
        outputStream: output
    )
    precondition(channel.peer.identifier == peer.identifier)
    precondition(channel.psm == 0x0080)
    _ = channel.inputStream
    _ = channel.outputStream
}

func testCBATTRequestModel() {
    let central = CBCentral(hostIdentifier: UUID(), maximumUpdateValueLength: 20)
    precondition(central.maximumUpdateValueLength == 20)
    precondition(central.identifier != UUID())
    let characteristic = CBMutableCharacteristic(
        type: CBUUID(string: "2A19"),
        properties: [.read, .write],
        value: Data([0x01]),
        permissions: [.readable, .writeable]
    )
    let request = CBATTRequest(
        hostCentral: central,
        characteristic: characteristic,
        offset: 4,
        value: Data([0x02])
    )
    precondition(request.central === central)
    precondition(request.characteristic === characteristic)
    precondition(request.offset == 4)
    precondition(request.value == Data([0x02]))
    request.value = Data([0x03])
    precondition(request.value == Data([0x03]))
}
