import Foundation

@available(iOS 8.0, *)
open class CBAttribute: NSObject {
    let _uuid: CBUUID

    open var uuid: CBUUID { _uuid }

    init(uuid: CBUUID) {
        _uuid = uuid
        super.init()
    }
}

@available(iOS 5.0, *)
open class CBService: CBAttribute {
    weak var _peripheral: CBPeripheral?
    weak var _includedOwner: CBMutableService?
    var _isPrimary: Bool
    var _characteristics: [CBCharacteristic]?
    var _includedServices: [CBService]?
    var _hostService: CBHostSimulatedService?

    open weak var peripheral: CBPeripheral? { _peripheral }
    open var isPrimary: Bool { _isPrimary }
    open var characteristics: [CBCharacteristic]? { _characteristics }
    open var includedServices: [CBService]? { _includedServices }

    init(uuid: CBUUID, primary: Bool) {
        _isPrimary = primary
        super.init(uuid: uuid)
    }
}

@available(iOS 6.0, *)
open class CBMutableService: CBService {
    public init(type UUID: CBUUID, primary isPrimary: Bool) {
        super.init(uuid: UUID, primary: isPrimary)
    }

    open override var characteristics: [CBCharacteristic]? {
        get { _characteristics }
        set { _adoptCharacteristics(newValue) }
    }

    open override var includedServices: [CBService]? {
        get { _includedServices }
        set { _adoptIncludedServices(newValue) }
    }

    func _adoptCharacteristics(_ newValue: [CBCharacteristic]?) {
        let incoming = newValue ?? []
        let previous = _characteristics ?? []
        for characteristic in previous where !incoming.contains(where: { $0 === characteristic }) {
            if characteristic._service === self {
                characteristic._service = nil
            }
        }
        for characteristic in incoming {
            if let owner = characteristic._service as? CBMutableService, owner !== self {
                owner._removeCharacteristicIdentity(characteristic)
            }
            characteristic._service = self
        }
        _characteristics = newValue
    }

    func _removeCharacteristicIdentity(_ characteristic: CBCharacteristic) {
        guard var list = _characteristics else { return }
        list.removeAll { $0 === characteristic }
        _characteristics = list.isEmpty ? nil : list
        if characteristic._service === self {
            characteristic._service = nil
        }
    }

    func _adoptIncludedServices(_ newValue: [CBService]?) {
        let incoming = newValue ?? []
        let previous = _includedServices ?? []
        for service in previous where !incoming.contains(where: { $0 === service }) {
            if service._includedOwner === self {
                service._includedOwner = nil
            }
        }
        for service in incoming {
            if let owner = service._includedOwner, owner !== self {
                owner._removeIncludedServiceIdentity(service)
            }
            service._includedOwner = self
            service._peripheral = _peripheral
        }
        _includedServices = newValue
    }

    func _removeIncludedServiceIdentity(_ service: CBService) {
        guard var list = _includedServices else { return }
        list.removeAll { $0 === service }
        _includedServices = list.isEmpty ? nil : list
        if service._includedOwner === self {
            service._includedOwner = nil
        }
    }
}

@available(iOS 5.0, *)
open class CBCharacteristic: CBAttribute {
    weak var _service: CBService?
    var _properties: CBCharacteristicProperties
    var _value: Data?
    var _descriptors: [CBDescriptor]?
    var _isBroadcasted = false
    var _isNotifying = false
    var _hostCharacteristic: CBHostSimulatedCharacteristic?

    open weak var service: CBService? { _service }
    open var properties: CBCharacteristicProperties { _properties }
    open var value: Data? { _value }
    open var descriptors: [CBDescriptor]? { _descriptors }
    open var isBroadcasted: Bool { _isBroadcasted }
    open var isNotifying: Bool { _isNotifying }

    init(
        uuid: CBUUID,
        properties: CBCharacteristicProperties,
        value: Data?
    ) {
        _properties = properties
        _value = value
        super.init(uuid: uuid)
    }
}

@available(iOS 6.0, *)
open class CBMutableCharacteristic: CBCharacteristic {
    open var permissions: CBAttributePermissions
    var _subscribedCentrals: [CBCentral]?

    public init(
        type UUID: CBUUID,
        properties: CBCharacteristicProperties,
        value: Data?,
        permissions: CBAttributePermissions
    ) {
        self.permissions = permissions
        super.init(uuid: UUID, properties: properties, value: value)
    }

    open override var properties: CBCharacteristicProperties {
        get { _properties }
        set { _properties = newValue }
    }

    open override var value: Data? {
        get { _value }
        set { _value = newValue }
    }

    open override var descriptors: [CBDescriptor]? {
        get { _descriptors }
        set { _adoptDescriptors(newValue) }
    }

    open var subscribedCentrals: [CBCentral]? { _subscribedCentrals }

    func _adoptDescriptors(_ newValue: [CBDescriptor]?) {
        let incoming = newValue ?? []
        let previous = _descriptors ?? []
        for descriptor in previous where !incoming.contains(where: { $0 === descriptor }) {
            if descriptor._characteristic === self {
                descriptor._characteristic = nil
            }
        }
        for descriptor in incoming {
            if let owner = descriptor._characteristic as? CBMutableCharacteristic, owner !== self {
                owner._removeDescriptorIdentity(descriptor)
            }
            descriptor._characteristic = self
        }
        _descriptors = newValue
    }

    func _removeDescriptorIdentity(_ descriptor: CBDescriptor) {
        guard var list = _descriptors else { return }
        list.removeAll { $0 === descriptor }
        _descriptors = list.isEmpty ? nil : list
        if descriptor._characteristic === self {
            descriptor._characteristic = nil
        }
    }
}

@available(iOS 5.0, *)
open class CBDescriptor: CBAttribute {
    weak var _characteristic: CBCharacteristic?
    var _value: Any?
    var _hostDescriptor: CBHostSimulatedDescriptor?

    open weak var characteristic: CBCharacteristic? { _characteristic }
    open var value: Any? { _value }

    init(uuid: CBUUID, value: Any?) {
        _value = value
        super.init(uuid: uuid)
    }
}

@available(iOS 6.0, *)
open class CBMutableDescriptor: CBDescriptor {
    public init(type UUID: CBUUID, value: Any?) {
        super.init(uuid: UUID, value: value)
    }
}

@available(iOS 6.0, *)
open class CBATTRequest: NSObject {
    let _central: CBCentral
    let _characteristic: CBCharacteristic
    let _offset: Int
    var _value: Data?

    open var central: CBCentral { _central }
    open var characteristic: CBCharacteristic { _characteristic }
    open var offset: Int { _offset }
    open var value: Data? {
        get { _value }
        set { _value = newValue }
    }

    init(central: CBCentral, characteristic: CBCharacteristic, offset: Int, value: Data?) {
        _central = central
        _characteristic = characteristic
        _offset = offset
        _value = value
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(
        hostCentral central: CBCentral,
        characteristic: CBCharacteristic,
        offset: Int,
        value: Data?
    ) {
        self.init(central: central, characteristic: characteristic, offset: offset, value: value)
    }
}
