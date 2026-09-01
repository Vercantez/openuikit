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
    var _isPrimary: Bool
    var _characteristics: [CBCharacteristic]?
    var _includedServices: [CBService]?

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
        set {
            _characteristics = newValue
            newValue?.forEach { $0._service = self }
        }
    }

    open override var includedServices: [CBService]? {
        get { _includedServices }
        set {
            _includedServices = newValue
            newValue?.forEach { $0._peripheral = self._peripheral }
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
        set {
            _descriptors = newValue
            newValue?.forEach { $0._characteristic = self }
        }
    }

    open var subscribedCentrals: [CBCentral]? { _subscribedCentrals }
}

@available(iOS 5.0, *)
open class CBDescriptor: CBAttribute {
    weak var _characteristic: CBCharacteristic?
    var _value: Any?

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
}
