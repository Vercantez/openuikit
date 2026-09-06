import Foundation

open class HMAccessControl: NSObject {}

open class HMHomeAccessControl: HMAccessControl {
    public private(set) var isAdministrator: Bool = false

    public static func host_make(isAdministrator: Bool) -> HMHomeAccessControl {
        let control = HMHomeAccessControl()
        control.isAdministrator = isAdministrator
        return control
    }
}

open class HMUser: NSObject {
    public private(set) var name: String
    public private(set) var uniqueIdentifier: UUID

    public override init() {
        self.name = ""
        self.uniqueIdentifier = UUID()
        super.init()
    }

    public static func host_make(name: String, uniqueIdentifier: UUID = UUID()) -> HMUser {
        let user = HMUser()
        user.name = name
        user.uniqueIdentifier = uniqueIdentifier
        return user
    }
}

open class HMRoom: NSObject {
    public internal(set) var name: String
    public internal(set) var uniqueIdentifier: UUID
    public internal(set) var accessories: [HMAccessory]
    public internal(set) weak var home: HMHome?
    public internal(set) var isEntireHomeRoom: Bool = false

    public override init() {
        self.name = ""
        self.uniqueIdentifier = UUID()
        self.accessories = []
        super.init()
    }

    public func updateName(_ name: String, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if isEntireHomeRoom {
            completion(HMFailClosed(.roomForHomeCannotBeUpdated))
            return
        }
        if let error = HMLocalName.errorIfInvalid(name) {
            completion(error)
            return
        }
        if let home, HMLocalName.collides(name, with: home.rooms.map(\.name).filter { $0 != self.name }) {
            completion(HMFailClosed(.objectWithSimilarNameExistsInHome))
            return
        }
        self.name = name
        hmNotifyHome(home) { $0.delegate?.home($0, didUpdateNameFor: self) }
        completion(nil)
    }

    public func updateName(_ name: String) async throws {
        try await hmFinishAsync { self.updateName(name, completionHandler: $0) }
    }

    public static func host_make(name: String, uniqueIdentifier: UUID = UUID()) -> HMRoom {
        let room = HMRoom()
        room.name = name
        room.uniqueIdentifier = uniqueIdentifier
        return room
    }
}

open class HMZone: NSObject {
    public private(set) var name: String = ""
    public private(set) var uniqueIdentifier: UUID = UUID()
    public private(set) var rooms: [HMRoom] = []
    public internal(set) weak var home: HMHome?

    public func updateName(_ name: String, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if let error = HMLocalName.errorIfInvalid(name) {
            completion(error)
            return
        }
        if let home, HMLocalName.collides(name, with: home.zones.map(\.name).filter { $0 != self.name }) {
            completion(HMFailClosed(.objectWithSimilarNameExistsInHome))
            return
        }
        self.name = name
        hmNotifyHome(home) { $0.delegate?.home($0, didUpdateNameFor: self) }
        completion(nil)
    }

    public func updateName(_ name: String) async throws {
        try await hmFinishAsync { self.updateName(name, completionHandler: $0) }
    }

    public func addRoom(_ room: HMRoom, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if room.isEntireHomeRoom {
            completion(HMFailClosed(.roomForHomeCannotBeInZone))
            return
        }
        if rooms.contains(where: { $0 === room }) {
            completion(HMFailClosed(.alreadyExists))
            return
        }
        if let home, !home.rooms.contains(where: { $0 === room }) && room.home !== home {
            completion(HMFailClosed(.objectNotAssociatedToAnyHome))
            return
        }
        rooms.append(room)
        hmNotifyHome(home) { $0.delegate?.home($0, didAdd: room, to: self) }
        completion(nil)
    }

    public func addRoom(_ room: HMRoom) async throws {
        try await hmFinishAsync { self.addRoom(room, completionHandler: $0) }
    }

    public func removeRoom(_ room: HMRoom, completionHandler completion: @escaping ((any Error)?) -> Void) {
        guard let index = rooms.firstIndex(where: { $0 === room }) else {
            completion(HMFailClosed(.notFound))
            return
        }
        rooms.remove(at: index)
        hmNotifyHome(home) { $0.delegate?.home($0, didRemove: room, from: self) }
        completion(nil)
    }

    public func removeRoom(_ room: HMRoom) async throws {
        try await hmFinishAsync { self.removeRoom(room, completionHandler: $0) }
    }

    public static func host_make(name: String, uniqueIdentifier: UUID = UUID()) -> HMZone {
        let zone = HMZone()
        zone.name = name
        zone.uniqueIdentifier = uniqueIdentifier
        return zone
    }
}

open class HMServiceGroup: NSObject {
    public private(set) var name: String = ""
    public private(set) var uniqueIdentifier: UUID = UUID()
    public private(set) var services: [HMService] = []
    public internal(set) weak var home: HMHome?

    public func updateName(_ name: String, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if let error = HMLocalName.errorIfInvalid(name) {
            completion(error)
            return
        }
        if let home, HMLocalName.collides(name, with: home.serviceGroups.map(\.name).filter { $0 != self.name }) {
            completion(HMFailClosed(.objectWithSimilarNameExistsInHome))
            return
        }
        self.name = name
        hmNotifyHome(home) { $0.delegate?.home($0, didUpdateNameFor: self) }
        completion(nil)
    }

    public func updateName(_ name: String) async throws {
        try await hmFinishAsync { self.updateName(name, completionHandler: $0) }
    }

    public func addService(_ service: HMService, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if services.contains(where: { $0 === service }) {
            completion(HMFailClosed(.alreadyExists))
            return
        }
        services.append(service)
        hmNotifyHome(home) { $0.delegate?.home($0, didAdd: service, to: self) }
        completion(nil)
    }

    public func addService(_ service: HMService) async throws {
        try await hmFinishAsync { self.addService(service, completionHandler: $0) }
    }

    public func removeService(_ service: HMService, completionHandler completion: @escaping ((any Error)?) -> Void) {
        guard let index = services.firstIndex(where: { $0 === service }) else {
            completion(HMFailClosed(.notFound))
            return
        }
        services.remove(at: index)
        hmNotifyHome(home) { $0.delegate?.home($0, didRemove: service, from: self) }
        completion(nil)
    }

    public func removeService(_ service: HMService) async throws {
        try await hmFinishAsync { self.removeService(service, completionHandler: $0) }
    }

    public static func host_make(name: String, uniqueIdentifier: UUID = UUID()) -> HMServiceGroup {
        let group = HMServiceGroup()
        group.name = name
        group.uniqueIdentifier = uniqueIdentifier
        return group
    }
}

open class HMActionSet: NSObject {
    public private(set) var name: String = ""
    public private(set) var uniqueIdentifier: UUID = UUID()
    public private(set) var actions: Set<HMAction> = []
    public private(set) var isExecuting: Bool = false
    public private(set) var actionSetType: String = HMActionSetTypeUserDefined
    public private(set) var lastExecutionDate: Date?
    public internal(set) weak var home: HMHome?

    var host_isBuiltin: Bool {
        actionSetType != HMActionSetTypeUserDefined && actionSetType != HMActionSetTypeTriggerOwned
    }

    public func updateName(_ name: String, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if let error = HMLocalName.errorIfInvalid(name) {
            completion(error)
            return
        }
        if let home, HMLocalName.collides(name, with: home.actionSets.map(\.name).filter { $0 != self.name }) {
            completion(HMFailClosed(.objectWithSimilarNameExistsInHome))
            return
        }
        self.name = name
        hmNotifyHome(home) { $0.delegate?.home($0, didUpdateNameFor: self) }
        completion(nil)
    }

    public func updateName(_ name: String) async throws {
        try await hmFinishAsync { self.updateName(name, completionHandler: $0) }
    }

    public func addAction(_ action: HMAction, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if actions.contains(action) {
            completion(HMFailClosed(.alreadyExists))
            return
        }
        actions.insert(action)
        hmNotifyHome(home) { $0.delegate?.home($0, didUpdateActionsFor: self) }
        completion(nil)
    }

    public func addAction(_ action: HMAction) async throws {
        try await hmFinishAsync { self.addAction(action, completionHandler: $0) }
    }

    public func removeAction(_ action: HMAction, completionHandler completion: @escaping ((any Error)?) -> Void) {
        guard actions.contains(action) else {
            completion(HMFailClosed(.notFound))
            return
        }
        actions.remove(action)
        hmNotifyHome(home) { $0.delegate?.home($0, didUpdateActionsFor: self) }
        completion(nil)
    }

    public func removeAction(_ action: HMAction) async throws {
        try await hmFinishAsync { self.removeAction(action, completionHandler: $0) }
    }

    public static func host_make(
        name: String,
        actionSetType: String = HMActionSetTypeUserDefined,
        uniqueIdentifier: UUID = UUID()
    ) -> HMActionSet {
        let set = HMActionSet()
        set.name = name
        set.actionSetType = actionSetType
        set.uniqueIdentifier = uniqueIdentifier
        return set
    }

    func host_markExecuting(_ executing: Bool, at date: Date? = Date()) {
        isExecuting = executing
        if !executing {
            lastExecutionDate = date
        }
    }
}

open class HMAccessoryCategory: NSObject {
    public private(set) var categoryType: String
    public private(set) var localizedDescription: String

    public override init() {
        self.categoryType = HMAccessoryCategoryTypeOther
        self.localizedDescription = "Other"
        super.init()
    }

    public static func host_make(categoryType: String, localizedDescription: String) -> HMAccessoryCategory {
        let category = HMAccessoryCategory()
        category.categoryType = categoryType
        category.localizedDescription = localizedDescription
        return category
    }
}

open class HMAccessoryProfile: NSObject {
    public private(set) weak var accessory: HMAccessory?
    public private(set) var services: [HMService] = []
    public let uniqueIdentifier: UUID = UUID()
}

open class HMNetworkConfigurationProfile: HMAccessoryProfile {
    public weak var delegate: (any HMNetworkConfigurationProfileDelegate)?
    public private(set) var isNetworkAccessRestricted: Bool = true
}

open class HMService: NSObject {
    public private(set) weak var accessory: HMAccessory?
    public private(set) var name: String
    public private(set) var uniqueIdentifier: UUID
    public internal(set) var serviceType: String
    public private(set) var associatedServiceType: String?
    public private(set) var characteristics: [HMCharacteristic]
    public private(set) var linkedServices: [HMService]?
    public private(set) var isPrimaryService: Bool
    public private(set) var isUserInteractive: Bool
    public private(set) var matterEndpointID: UInt16?
    public var localizedDescription: String { name }

    public override init() {
        self.name = ""
        self.uniqueIdentifier = UUID()
        self.serviceType = HMServiceTypeSwitch
        self.associatedServiceType = nil
        self.characteristics = []
        self.linkedServices = nil
        self.isPrimaryService = false
        self.isUserInteractive = true
        self.matterEndpointID = nil
        super.init()
    }

    public func updateName(_ name: String, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if let error = HMLocalName.errorIfInvalid(name) {
            completion(error)
            return
        }
        self.name = name
        hmNotifyAccessory(accessory) { $0.delegate?.accessory($0, didUpdateNameFor: self) }
        completion(nil)
    }

    public func updateName(_ name: String) async throws {
        try await hmFinishAsync { self.updateName(name, completionHandler: $0) }
    }

    public func updateAssociatedServiceType(
        _ serviceType: String?,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        if let serviceType, !HMService.host_isKnownType(serviceType) {
            completion(HMFailClosed(.invalidAssociatedServiceType))
            return
        }
        associatedServiceType = serviceType
        hmNotifyAccessory(accessory) { $0.delegate?.accessory($0, didUpdateAssociatedServiceTypeFor: self) }
        completion(nil)
    }

    public func updateAssociatedServiceType(_ serviceType: String?) async throws {
        try await hmFinishAsync { self.updateAssociatedServiceType(serviceType, completionHandler: $0) }
    }

    public static func host_isKnownType(_ serviceType: String) -> Bool {
        [
            HMServiceTypeSwitch,
            HMServiceTypeLightbulb,
            HMServiceTypeFan,
            HMServiceTypeOutlet,
            HMServiceTypeThermostat,
            HMServiceTypeLockMechanism,
            HMServiceTypeGarageDoorOpener,
            HMServiceTypeAccessoryInformation,
        ].contains(serviceType)
    }

    public static func host_make(
        name: String,
        serviceType: String,
        characteristics: [HMCharacteristic] = [],
        primary: Bool = false,
        userInteractive: Bool = true,
        uniqueIdentifier: UUID = UUID()
    ) -> HMService {
        let service = HMService()
        service.name = name
        service.serviceType = serviceType
        service.characteristics = characteristics
        service.isPrimaryService = primary
        service.isUserInteractive = userInteractive
        service.uniqueIdentifier = uniqueIdentifier
        for characteristic in characteristics {
            characteristic.host_bind(service: service)
        }
        return service
    }

    func host_bind(accessory: HMAccessory?) {
        self.accessory = accessory
    }

    public func host_setLinkedServices(_ services: [HMService]?) {
        linkedServices = services
    }

    public func host_setMatterEndpointID(_ value: UInt16?) {
        matterEndpointID = value
    }
}

open class HMCharacteristicMetadata: NSObject {
    public var manufacturerDescription: String?
    public var validValues: [NSNumber]?
    public var minimumValue: NSNumber?
    public var maximumValue: NSNumber?
    public var stepValue: NSNumber?
    public var maxLength: NSNumber?
    public var format: String?
    public var units: String?

    public override init() {
        super.init()
    }

    public func contains(_ value: NSNumber) -> Bool {
        if let validValues {
            return validValues.contains { $0.isEqual(to: value) }
        }
        if let minimumValue, value.compare(minimumValue) == .orderedAscending { return false }
        if let maximumValue, value.compare(maximumValue) == .orderedDescending { return false }
        if let stepValue, let minimumValue {
            let offset = value.doubleValue - minimumValue.doubleValue
            let step = stepValue.doubleValue
            if step > 0 {
                let remainder = offset.truncatingRemainder(dividingBy: step)
                if abs(remainder) > 1e-9 && abs(remainder - step) > 1e-9 {
                    return false
                }
            }
        }
        return true
    }

    public func host_acceptsWrite(_ value: Any?) -> HMError? {
        if let maxLength, let string = value as? String, string.utf8.count > maxLength.intValue {
            return HMFailClosed(.stringLongerThanMaximum)
        }
        if let number = value as? NSNumber {
            if !contains(number) {
                if let maximumValue, number.compare(maximumValue) == .orderedDescending {
                    return HMFailClosed(.valueHigherThanMaximum)
                }
                if let minimumValue, number.compare(minimumValue) == .orderedAscending {
                    return HMFailClosed(.valueLowerThanMinimum)
                }
                return HMFailClosed(.invalidValueType)
            }
            return nil
        }
        if format == HMCharacteristicMetadataFormatUInt8
            || format == HMCharacteristicMetadataFormatInt
            || format == HMCharacteristicMetadataFormatFloat
            || format == HMCharacteristicMetadataFormatUInt16
            || format == HMCharacteristicMetadataFormatUInt32
            || format == HMCharacteristicMetadataFormatUInt64
        {
            return HMFailClosed(.invalidValueType)
        }
        return nil
    }

    public static func host_make(
        format: String?,
        units: String?,
        minimumValue: NSNumber?,
        maximumValue: NSNumber?,
        stepValue: NSNumber?
    ) -> HMCharacteristicMetadata {
        let meta = HMCharacteristicMetadata()
        meta.format = format
        meta.units = units
        meta.minimumValue = minimumValue
        meta.maximumValue = maximumValue
        meta.stepValue = stepValue
        return meta
    }

    public static func host_makeFull(
        format: String?,
        units: String?,
        minimumValue: NSNumber?,
        maximumValue: NSNumber?,
        stepValue: NSNumber?,
        maxLength: NSNumber?,
        validValues: [NSNumber]?,
        manufacturerDescription: String?
    ) -> HMCharacteristicMetadata {
        let meta = host_make(
            format: format,
            units: units,
            minimumValue: minimumValue,
            maximumValue: maximumValue,
            stepValue: stepValue
        )
        meta.maxLength = maxLength
        meta.validValues = validValues
        meta.manufacturerDescription = manufacturerDescription
        return meta
    }

    public static func host_celsiusToFahrenheit(_ celsius: Double) -> Double {
        celsius * 9.0 / 5.0 + 32.0
    }

    public static func host_fahrenheitToCelsius(_ fahrenheit: Double) -> Double {
        (fahrenheit - 32.0) * 5.0 / 9.0
    }

    public static func host_isKnownFormat(_ format: String) -> Bool {
        [
            HMCharacteristicMetadataFormatBool,
            HMCharacteristicMetadataFormatInt,
            HMCharacteristicMetadataFormatFloat,
            HMCharacteristicMetadataFormatString,
            HMCharacteristicMetadataFormatArray,
            HMCharacteristicMetadataFormatDictionary,
            HMCharacteristicMetadataFormatUInt8,
            HMCharacteristicMetadataFormatUInt16,
            HMCharacteristicMetadataFormatUInt32,
            HMCharacteristicMetadataFormatUInt64,
            HMCharacteristicMetadataFormatData,
            HMCharacteristicMetadataFormatTLV8,
        ].contains(format)
    }
}

open class HMCharacteristic: NSObject {
    public private(set) weak var service: HMService?
    public internal(set) var characteristicType: String
    public private(set) var uniqueIdentifier: UUID
    public internal(set) var value: Any?
    public internal(set) var metadata: HMCharacteristicMetadata?
    public internal(set) var properties: [String]
    public private(set) var isNotificationEnabled: Bool
    public var localizedDescription: String { characteristicType }

    public override init() {
        self.characteristicType = HMCharacteristicTypePowerState
        self.uniqueIdentifier = UUID()
        self.value = nil
        self.metadata = nil
        self.properties = []
        self.isNotificationEnabled = false
        super.init()
    }

    public func readValue(completionHandler completion: @escaping ((any Error)?) -> Void) {
        if let accessory = service?.accessory, !accessory.isReachable {
            completion(HMFailClosed(.accessoryNotReachable))
            return
        }
        if service?.accessory == nil {
            completion(HMFailClosed(.accessoryNotReachable))
            return
        }
        if !properties.contains(HMCharacteristicPropertyReadable) {
            if properties.contains(HMCharacteristicPropertyWritable) {
                completion(HMFailClosed(.writeOnlyCharacteristic))
                return
            }
            completion(HMFailClosed(.operationNotSupported))
            return
        }
        completion(nil)
    }

    public func writeValue(_ value: Any?, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if let accessory = service?.accessory, !accessory.isReachable {
            completion(HMFailClosed(.accessoryNotReachable))
            return
        }
        host_writeLocal(value, completion: completion)
    }

    public func writeValue(_ value: Any?) async throws {
        try await hmFinishAsync { self.writeValue(value, completionHandler: $0) }
    }

    public func enableNotification(_ enable: Bool, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if !properties.contains(HMCharacteristicPropertySupportsEventNotification) {
            completion(HMFailClosed(.notificationNotSupported))
            return
        }
        if enable && isNotificationEnabled {
            completion(HMFailClosed(.notificationAlreadyEnabled))
            return
        }
        isNotificationEnabled = enable
        completion(nil)
    }

    public func enableNotification(_ enable: Bool) async throws {
        try await hmFinishAsync { self.enableNotification(enable, completionHandler: $0) }
    }

    public func updateAuthorizationData(_ data: Data?, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if !properties.contains(HMCharacteristicPropertyRequiresAuthorizationData) {
            completion(HMFailClosed(.operationNotSupported))
            return
        }
        if data == nil || data?.isEmpty == true {
            completion(HMFailClosed(.invalidOrMissingAuthorizationData))
            return
        }
        completion(nil)
    }

    public func updateAuthorizationData(_ data: Data?) async throws {
        try await hmFinishAsync { self.updateAuthorizationData(data, completionHandler: $0) }
    }

    public static func host_make(
        type: String,
        properties: [String],
        metadata: HMCharacteristicMetadata?,
        value: Any?
    ) -> HMCharacteristic {
        let characteristic = HMCharacteristic()
        characteristic.characteristicType = type
        characteristic.properties = properties
        characteristic.metadata = metadata
        characteristic.value = value
        return characteristic
    }

    public func host_writeLocal(_ value: Any?, completion: @escaping ((any Error)?) -> Void) {
        if !properties.contains(HMCharacteristicPropertyWritable) {
            completion(HMFailClosed(.readOnlyCharacteristic))
            return
        }
        if let metadata, let error = metadata.host_acceptsWrite(value) {
            completion(error)
            return
        }
        self.value = value
        if isNotificationEnabled, let service, let accessory = service.accessory {
            accessory.delegate?.accessory(accessory, service: service, didUpdateValueFor: self)
        }
        completion(nil)
    }

    func host_bind(service: HMService?) {
        self.service = service
    }
}

open class HMAccessory: NSObject {
    public weak var delegate: (any HMAccessoryDelegate)?
    public private(set) var name: String
    public private(set) var uniqueIdentifier: UUID
    public var identifier: UUID { uniqueIdentifier }
    public private(set) var isReachable: Bool
    public private(set) var isBridged: Bool
    public private(set) var isBlocked: Bool
    public private(set) var isVendorAccessory: Bool
    public private(set) var supportsIdentify: Bool
    public private(set) weak var room: HMRoom?
    public private(set) weak var home: HMHome?
    public private(set) var services: [HMService]
    public private(set) var profiles: [HMAccessoryProfile]
    public private(set) var cameraProfiles: [HMCameraProfile]?
    public private(set) var bridgedAccessories: [HMAccessory]
    public private(set) var uniqueIdentifiersForBridgedAccessories: [UUID]?
    public var identifiersForBridgedAccessories: [UUID]? { uniqueIdentifiersForBridgedAccessories }
    public private(set) var category: HMAccessoryCategory
    public private(set) var model: String?
    public private(set) var manufacturer: String?
    public private(set) var firmwareVersion: String?
    public private(set) var matterNodeID: UInt64?
    public private(set) var hapInstanceID: UInt64?

    public override init() {
        self.name = ""
        self.uniqueIdentifier = UUID()
        self.isReachable = false
        self.isBridged = false
        self.isBlocked = false
        self.isVendorAccessory = false
        self.supportsIdentify = false
        self.services = []
        self.profiles = []
        self.cameraProfiles = nil
        self.bridgedAccessories = []
        self.uniqueIdentifiersForBridgedAccessories = nil
        self.category = HMAccessoryCategory()
        super.init()
    }

    public func updateName(_ name: String, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if let error = HMLocalName.errorIfInvalid(name) {
            completion(error)
            return
        }
        self.name = name
        delegate?.accessoryDidUpdateName(self)
        completion(nil)
    }

    public func updateName(_ name: String) async throws {
        try await hmFinishAsync { self.updateName(name, completionHandler: $0) }
    }

    public func identify(completionHandler completion: @escaping ((any Error)?) -> Void) {
        completion(HMFailClosed(.accessoryNotReachable))
    }

    public static func host_make(name: String) -> HMAccessory {
        let accessory = HMAccessory()
        accessory.name = name
        return accessory
    }

    public static func host_make(
        name: String,
        uniqueIdentifier: UUID = UUID(),
        category: HMAccessoryCategory = HMAccessoryCategory(),
        services: [HMService] = [],
        reachable: Bool = false,
        bridged: Bool = false,
        blocked: Bool = false,
        supportsIdentify: Bool = false,
        manufacturer: String? = nil,
        model: String? = nil,
        firmwareVersion: String? = nil
    ) -> HMAccessory {
        let accessory = HMAccessory()
        accessory.name = name
        accessory.uniqueIdentifier = uniqueIdentifier
        accessory.category = category
        accessory.isReachable = reachable
        accessory.isBridged = bridged
        accessory.isBlocked = blocked
        accessory.supportsIdentify = supportsIdentify
        accessory.manufacturer = manufacturer
        accessory.model = model
        accessory.firmwareVersion = firmwareVersion
        accessory.host_setServices(services)
        return accessory
    }

    public func host_setServices(_ services: [HMService]) {
        self.services = services
        for service in services {
            service.host_bind(accessory: self)
        }
        delegate?.accessoryDidUpdateServices(self)
    }

    public func host_setReachable(_ reachable: Bool) {
        isReachable = reachable
        delegate?.accessoryDidUpdateReachability(self)
    }

    public func host_setBlocked(_ blocked: Bool) {
        isBlocked = blocked
    }

    public func host_setFirmwareVersion(_ firmwareVersion: String) {
        self.firmwareVersion = firmwareVersion
        delegate?.accessory(self, didUpdateFirmwareVersion: firmwareVersion)
    }

    public func host_setProfiles(_ profiles: [HMAccessoryProfile], cameraProfiles: [HMCameraProfile]? = nil) {
        let removed = self.profiles
        self.profiles = profiles
        self.cameraProfiles = cameraProfiles
        for profile in removed {
            delegate?.accessory(self, didRemove: profile)
        }
        for profile in profiles {
            delegate?.accessory(self, didAdd: profile)
        }
    }

    public func host_setBridgedAccessories(_ accessories: [HMAccessory]) {
        bridgedAccessories = accessories
        uniqueIdentifiersForBridgedAccessories = accessories.map(\.uniqueIdentifier)
        isBridged = true
    }

    func host_bind(home: HMHome?, room: HMRoom?) {
        self.home = home
        self.room = room
    }

    public func host_setVendorAccessory(_ value: Bool, matterNodeID: UInt64? = nil, hapInstanceID: UInt64? = nil) {
        isVendorAccessory = value
        self.matterNodeID = matterNodeID
        self.hapInstanceID = hapInstanceID
    }
}

open class HMAccessoryBrowser: NSObject {
    public weak var delegate: (any HMAccessoryBrowserDelegate)?
    public private(set) var discoveredAccessories: [HMAccessory] = []

    public override init() {
        super.init()
    }

    public func startSearchingForNewAccessories() {
        discoveredAccessories = []
    }

    public func stopSearchingForNewAccessories() {
        discoveredAccessories = []
    }
}

open class HMAccessoryOwnershipToken: NSObject {
    public let data: Data

    public init?(data: Data) {
        if data.isEmpty { return nil }
        self.data = data
        super.init()
    }
}

open class HMAccessorySetupPayload: NSObject {
    public let url: URL?

    public init?(url setupPayloadURL: URL?) {
        guard let setupPayloadURL else { return nil }
        self.url = setupPayloadURL
        super.init()
    }

    public init?(URL setupPayloadURL: URL?) {
        guard let setupPayloadURL else { return nil }
        self.url = setupPayloadURL
        super.init()
    }

    public init?(url setupPayloadURL: URL, ownershipToken: HMAccessoryOwnershipToken?) {
        _ = ownershipToken
        self.url = setupPayloadURL
        super.init()
    }

    public init?(URL setupPayloadURL: URL, ownershipToken: HMAccessoryOwnershipToken?) {
        _ = ownershipToken
        self.url = setupPayloadURL
        super.init()
    }
}

open class HMAccessorySetupRequest: NSObject {
    public var payload: HMAccessorySetupPayload?
    public var homeUniqueIdentifier: UUID?
    public var suggestedRoomUniqueIdentifier: UUID?
    public var suggestedAccessoryName: String?

    public override init() {
        super.init()
    }
}

open class HMAccessorySetupResult: NSObject {
    public private(set) var homeUniqueIdentifier: UUID = UUID()
    public private(set) var accessoryUniqueIdentifiers: [UUID] = []
}

open class HMAccessorySetupManager: NSObject {
    public override init() {
        super.init()
    }

    public func performAccessorySetup(using request: HMAccessorySetupRequest) async throws -> HMAccessorySetupResult {
        _ = request
        throw HMFailClosed(.missingEntitlement)
    }

    public func host_performSetup(
        _ request: HMAccessorySetupRequest,
        completion: @escaping (HMAccessorySetupResult?, (any Error)?) -> Void
    ) {
        _ = request
        completion(nil, HMFailClosed(.missingEntitlement))
    }
}

open class HMAddAccessoryRequest: NSObject {
    public private(set) var home: HMHome
    public private(set) var accessoryCategory: HMAccessoryCategory
    public private(set) var accessoryName: String
    public private(set) var requiresSetupPayloadURL: Bool
    public private(set) var requiresOwnershipToken: Bool

    public override init() {
        self.home = HMHome()
        self.accessoryCategory = HMAccessoryCategory()
        self.accessoryName = ""
        self.requiresSetupPayloadURL = true
        self.requiresOwnershipToken = true
        super.init()
    }

    public func makePayload(ownershipToken: HMAccessoryOwnershipToken) -> HMAccessorySetupPayload? {
        if requiresSetupPayloadURL { return nil }
        _ = ownershipToken
        return nil
    }

    public func makePayload(
        url setupPayloadURL: URL,
        ownershipToken: HMAccessoryOwnershipToken
    ) -> HMAccessorySetupPayload? {
        if requiresOwnershipToken, ownershipToken.data.isEmpty { return nil }
        let scheme = setupPayloadURL.scheme?.lowercased()
        if scheme != "homekit" && scheme != "hap" {
            return nil
        }
        return HMAccessorySetupPayload(url: setupPayloadURL, ownershipToken: ownershipToken)
    }

    public func payload(with ownershipToken: HMAccessoryOwnershipToken) -> HMAccessorySetupPayload? {
        makePayload(ownershipToken: ownershipToken)
    }

    public func payload(with url: URL, ownershipToken: HMAccessoryOwnershipToken) -> HMAccessorySetupPayload? {
        makePayload(url: url, ownershipToken: ownershipToken)
    }

    public static func host_make(
        home: HMHome,
        accessoryName: String,
        accessoryCategory: HMAccessoryCategory = HMAccessoryCategory(),
        requiresSetupPayloadURL: Bool = true,
        requiresOwnershipToken: Bool = true
    ) -> HMAddAccessoryRequest {
        let request = HMAddAccessoryRequest()
        request.home = home
        request.accessoryName = accessoryName
        request.accessoryCategory = accessoryCategory
        request.requiresSetupPayloadURL = requiresSetupPayloadURL
        request.requiresOwnershipToken = requiresOwnershipToken
        return request
    }
}

open class HMHome: NSObject {
    public weak var delegate: (any HMHomeDelegate)?
    public private(set) var name: String
    public private(set) var uniqueIdentifier: UUID
    public private(set) var isPrimary: Bool
    public private(set) var homeHubState: HMHomeHubState
    public private(set) var supportsAddingNetworkRouter: Bool
    public private(set) var accessories: [HMAccessory]
    public private(set) var rooms: [HMRoom]
    public private(set) var zones: [HMZone]
    public private(set) var serviceGroups: [HMServiceGroup]
    public private(set) var actionSets: [HMActionSet]
    public private(set) var triggers: [HMTrigger]
    public private(set) var users: [HMUser]
    public private(set) var currentUser: HMUser
    public var matterControllerID: String { uniqueIdentifier.uuidString }

    private var hostedServices: [HMService] = []
    private lazy var entireHomeRoom: HMRoom = {
        let room = HMRoom()
        room.name = self.name
        room.isEntireHomeRoom = true
        room.home = self
        return room
    }()

    public override init() {
        self.name = ""
        self.uniqueIdentifier = UUID()
        self.isPrimary = false
        self.homeHubState = .notAvailable
        self.supportsAddingNetworkRouter = false
        self.accessories = []
        self.rooms = []
        self.zones = []
        self.serviceGroups = []
        self.actionSets = []
        self.triggers = []
        self.users = []
        self.currentUser = HMUser()
        super.init()
    }

    public func roomForEntireHome() -> HMRoom {
        entireHomeRoom.name = name
        entireHomeRoom.home = self
        entireHomeRoom.isEntireHomeRoom = true
        return entireHomeRoom
    }

    public func servicesWithTypes(_ serviceTypes: [String]) -> [HMService]? {
        let wanted = Set(serviceTypes)
        let fromAccessories = accessories.flatMap(\.services)
        let combined = hostedServices + fromAccessories
        var seen = Set<ObjectIdentifier>()
        let matched = combined.filter { service in
            guard wanted.contains(service.serviceType) else { return false }
            return seen.insert(ObjectIdentifier(service)).inserted
        }
        return matched
    }

    public func builtinActionSet(ofType actionSetType: String) -> HMActionSet? {
        actionSets.first(where: { $0.actionSetType == actionSetType })
    }

    public func homeAccessControl(for user: HMUser) -> HMHomeAccessControl {
        HMHomeAccessControl.host_make(isAdministrator: user === currentUser)
    }

    public func updateName(_ name: String, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if let error = HMLocalName.errorIfInvalid(name) {
            completion(error)
            return
        }
        self.name = name
        entireHomeRoom.name = name
        delegate?.homeDidUpdateName(self)
        completion(nil)
    }

    public func updateName(_ name: String) async throws {
        try await hmFinishAsync { self.updateName(name, completionHandler: $0) }
    }

    public func addAccessory(
        _ accessory: HMAccessory,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        completion(HMFailClosed(.accessoryNotReachable))
    }

    public func addAccessory(_ accessory: HMAccessory) async throws {
        try await hmFinishAsync { self.addAccessory(accessory, completionHandler: $0) }
    }

    public func removeAccessory(
        _ accessory: HMAccessory,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        guard let index = accessories.firstIndex(where: { $0 === accessory }) else {
            completion(HMFailClosed(.objectNotAssociatedToAnyHome))
            return
        }
        accessories.remove(at: index)
        if let room = accessory.room {
            room.accessories.removeAll { $0 === accessory }
        }
        accessory.host_bind(home: nil, room: nil)
        delegate?.home(self, didRemove: accessory)
        completion(nil)
    }

    public func removeAccessory(_ accessory: HMAccessory) async throws {
        try await hmFinishAsync { self.removeAccessory(accessory, completionHandler: $0) }
    }

    public func assignAccessory(
        _ accessory: HMAccessory,
        to room: HMRoom,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        guard accessories.contains(where: { $0 === accessory }) else {
            completion(HMFailClosed(.objectNotAssociatedToAnyHome))
            return
        }
        let target = room.isEntireHomeRoom || room === entireHomeRoom ? entireHomeRoom : room
        if !target.isEntireHomeRoom, !rooms.contains(where: { $0 === target }) {
            completion(HMFailClosed(.objectNotAssociatedToAnyHome))
            return
        }
        if let previous = accessory.room {
            previous.accessories.removeAll { $0 === accessory }
        }
        accessory.host_bind(home: self, room: target)
        if !target.accessories.contains(where: { $0 === accessory }) {
            target.accessories.append(accessory)
        }
        delegate?.home(self, didUpdate: target, for: accessory)
        completion(nil)
    }

    public func assignAccessory(_ accessory: HMAccessory, to room: HMRoom) async throws {
        try await hmFinishAsync { self.assignAccessory(accessory, to: room, completionHandler: $0) }
    }

    public func unblockAccessory(
        _ accessory: HMAccessory,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        guard accessories.contains(where: { $0 === accessory }) else {
            completion(HMFailClosed(.objectNotAssociatedToAnyHome))
            return
        }
        if !accessory.isBridged {
            completion(HMFailClosed(.cannotUnblockNonBridgeAccessory))
            return
        }
        accessory.host_setBlocked(false)
        delegate?.home(self, didUnblockAccessory: accessory)
        completion(nil)
    }

    public func unblockAccessory(_ accessory: HMAccessory) async throws {
        try await hmFinishAsync { self.unblockAccessory(accessory, completionHandler: $0) }
    }

    public func addAndSetUpAccessories(completionHandler completion: @escaping ((any Error)?) -> Void) {
        completion(HMFailClosed(.missingEntitlement))
    }

    public func addAndSetUpAccessories() async throws {
        try await hmFinishAsync { self.addAndSetUpAccessories(completionHandler: $0) }
    }

    public func addAndSetUpAccessories(
        payload: HMAccessorySetupPayload,
        completionHandler completion: @escaping ([HMAccessory]?, (any Error)?) -> Void
    ) {
        _ = payload
        completion(nil, HMFailClosed(.missingEntitlement))
    }

    public func addAndSetUpAccessories(payload: HMAccessorySetupPayload) async throws -> [HMAccessory] {
        try await withCheckedThrowingContinuation { continuation in
            addAndSetUpAccessories(payload: payload) { accessories, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: accessories ?? [])
                }
            }
        }
    }

    public func addRoom(
        named roomName: String,
        completionHandler completion: @escaping (HMRoom?, (any Error)?) -> Void
    ) {
        if let error = HMLocalName.errorIfInvalid(roomName) {
            completion(nil, error)
            return
        }
        if HMLocalName.collides(roomName, with: rooms.map(\.name) + [name]) {
            completion(nil, HMFailClosed(.objectWithSimilarNameExistsInHome))
            return
        }
        let room = HMRoom.host_make(name: roomName)
        room.home = self
        rooms.append(room)
        delegate?.home(self, didAdd: room)
        completion(room, nil)
    }

    public func addRoom(named roomName: String) async throws -> HMRoom {
        try await hmFinishAsync { self.addRoom(named: roomName, completionHandler: $0) }
    }

    public func removeRoom(_ room: HMRoom, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if room.isEntireHomeRoom || room === entireHomeRoom {
            completion(HMFailClosed(.roomForHomeCannotBeUpdated))
            return
        }
        guard let index = rooms.firstIndex(where: { $0 === room }) else {
            completion(HMFailClosed(.notFound))
            return
        }
        rooms.remove(at: index)
        room.home = nil
        delegate?.home(self, didRemove: room)
        completion(nil)
    }

    public func removeRoom(_ room: HMRoom) async throws {
        try await hmFinishAsync { self.removeRoom(room, completionHandler: $0) }
    }

    public func addZone(
        named zoneName: String,
        completionHandler completion: @escaping (HMZone?, (any Error)?) -> Void
    ) {
        if let error = HMLocalName.errorIfInvalid(zoneName) {
            completion(nil, error)
            return
        }
        if HMLocalName.collides(zoneName, with: zones.map(\.name)) {
            completion(nil, HMFailClosed(.objectWithSimilarNameExistsInHome))
            return
        }
        let zone = HMZone.host_make(name: zoneName)
        zone.home = self
        zones.append(zone)
        delegate?.home(self, didAdd: zone)
        completion(zone, nil)
    }

    public func addZone(named zoneName: String) async throws -> HMZone {
        try await hmFinishAsync { self.addZone(named: zoneName, completionHandler: $0) }
    }

    public func removeZone(_ zone: HMZone, completionHandler completion: @escaping ((any Error)?) -> Void) {
        guard let index = zones.firstIndex(where: { $0 === zone }) else {
            completion(HMFailClosed(.notFound))
            return
        }
        zones.remove(at: index)
        zone.home = nil
        delegate?.home(self, didRemove: zone)
        completion(nil)
    }

    public func removeZone(_ zone: HMZone) async throws {
        try await hmFinishAsync { self.removeZone(zone, completionHandler: $0) }
    }

    public func addServiceGroup(
        named serviceGroupName: String,
        completionHandler completion: @escaping (HMServiceGroup?, (any Error)?) -> Void
    ) {
        if let error = HMLocalName.errorIfInvalid(serviceGroupName) {
            completion(nil, error)
            return
        }
        if HMLocalName.collides(serviceGroupName, with: serviceGroups.map(\.name)) {
            completion(nil, HMFailClosed(.objectWithSimilarNameExistsInHome))
            return
        }
        let group = HMServiceGroup.host_make(name: serviceGroupName)
        group.home = self
        serviceGroups.append(group)
        delegate?.home(self, didAdd: group)
        completion(group, nil)
    }

    public func addServiceGroup(named serviceGroupName: String) async throws -> HMServiceGroup {
        try await hmFinishAsync { self.addServiceGroup(named: serviceGroupName, completionHandler: $0) }
    }

    public func removeServiceGroup(
        _ group: HMServiceGroup,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        guard let index = serviceGroups.firstIndex(where: { $0 === group }) else {
            completion(HMFailClosed(.notFound))
            return
        }
        serviceGroups.remove(at: index)
        group.home = nil
        delegate?.home(self, didRemove: group)
        completion(nil)
    }

    public func removeServiceGroup(_ group: HMServiceGroup) async throws {
        try await hmFinishAsync { self.removeServiceGroup(group, completionHandler: $0) }
    }

    public func addActionSet(
        named actionSetName: String,
        completionHandler completion: @escaping (HMActionSet?, (any Error)?) -> Void
    ) {
        if let error = HMLocalName.errorIfInvalid(actionSetName) {
            completion(nil, error)
            return
        }
        if HMLocalName.collides(actionSetName, with: actionSets.map(\.name)) {
            completion(nil, HMFailClosed(.objectWithSimilarNameExistsInHome))
            return
        }
        let set = HMActionSet.host_make(name: actionSetName)
        set.home = self
        actionSets.append(set)
        delegate?.home(self, didAdd: set)
        completion(set, nil)
    }

    public func addActionSet(named actionSetName: String) async throws -> HMActionSet {
        try await hmFinishAsync { self.addActionSet(named: actionSetName, completionHandler: $0) }
    }

    public func removeActionSet(
        _ actionSet: HMActionSet,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        if actionSet.host_isBuiltin {
            completion(HMFailClosed(.cannotRemoveBuiltinActionSet))
            return
        }
        guard let index = actionSets.firstIndex(where: { $0 === actionSet }) else {
            completion(HMFailClosed(.notFound))
            return
        }
        actionSets.remove(at: index)
        actionSet.home = nil
        delegate?.home(self, didRemove: actionSet)
        completion(nil)
    }

    public func removeActionSet(_ actionSet: HMActionSet) async throws {
        try await hmFinishAsync { self.removeActionSet(actionSet, completionHandler: $0) }
    }

    public func executeActionSet(
        _ actionSet: HMActionSet,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        guard actionSets.contains(where: { $0 === actionSet }) else {
            completion(HMFailClosed(.objectNotAssociatedToAnyHome))
            return
        }
        if actionSet.actions.isEmpty {
            completion(HMFailClosed(.noActionsInActionSet))
            return
        }
        if homeHubState != .connected {
            completion(HMFailClosed(.noHomeHub))
            return
        }
        if actionSet.isExecuting {
            completion(HMFailClosed(.actionSetExecutionInProgress))
            return
        }
        actionSet.host_markExecuting(true)
        var firstError: (any Error)?
        for action in actionSet.actions {
            action.host_apply { error in
                if firstError == nil { firstError = error }
            }
        }
        actionSet.host_markExecuting(false)
        delegate?.home(self, didUpdateActionsFor: actionSet)
        completion(firstError)
    }

    public func executeActionSet(_ actionSet: HMActionSet) async throws {
        try await hmFinishAsync { self.executeActionSet(actionSet, completionHandler: $0) }
    }

    public func addTrigger(_ trigger: HMTrigger, completionHandler completion: @escaping ((any Error)?) -> Void) {
        if let error = HMLocalName.errorIfInvalid(trigger.name) {
            completion(error)
            return
        }
        if triggers.contains(where: { $0 === trigger }) {
            completion(HMFailClosed(.alreadyExists))
            return
        }
        trigger.host_bind(home: self)
        triggers.append(trigger)
        delegate?.home(self, didAdd: trigger)
        completion(nil)
    }

    public func addTrigger(_ trigger: HMTrigger) async throws {
        try await hmFinishAsync { self.addTrigger(trigger, completionHandler: $0) }
    }

    public func removeTrigger(_ trigger: HMTrigger, completionHandler completion: @escaping ((any Error)?) -> Void) {
        guard let index = triggers.firstIndex(where: { $0 === trigger }) else {
            completion(HMFailClosed(.notFound))
            return
        }
        triggers.remove(at: index)
        trigger.host_bind(home: nil)
        delegate?.home(self, didRemove: trigger)
        completion(nil)
    }

    public func removeTrigger(_ trigger: HMTrigger) async throws {
        try await hmFinishAsync { self.removeTrigger(trigger, completionHandler: $0) }
    }

    public func addUser(completionHandler completion: @escaping (HMUser?, (any Error)?) -> Void) {
        completion(nil, HMFailClosed(.homeAccessNotAuthorized))
    }

    public func removeUser(_ user: HMUser, completionHandler completion: @escaping ((any Error)?) -> Void) {
        _ = user
        completion(HMFailClosed(.homeAccessNotAuthorized))
    }

    public func manageUsers(completionHandler completion: @escaping ((any Error)?) -> Void) {
        completion(HMFailClosed(.homeAccessNotAuthorized))
    }

    public static func host_make(name: String) -> HMHome {
        let home = HMHome()
        home.name = name
        home.currentUser = HMUser.host_make(name: "Current User")
        home.users = [home.currentUser]
        return home
    }

    public func host_setServices(_ services: [HMService]) {
        hostedServices = services
    }

    public func host_attachAccessory(_ accessory: HMAccessory, room: HMRoom? = nil) {
        if !accessories.contains(where: { $0 === accessory }) {
            accessories.append(accessory)
        }
        let target = room ?? entireHomeRoom
        accessory.host_bind(home: self, room: target)
        if !target.accessories.contains(where: { $0 === accessory }) {
            target.accessories.append(accessory)
        }
        delegate?.home(self, didAdd: accessory)
    }

    public func host_installBuiltinActionSets() {
        let types = [
            HMActionSetTypeWakeUp,
            HMActionSetTypeSleep,
            HMActionSetTypeHomeArrival,
            HMActionSetTypeHomeDeparture,
        ]
        for type in types where builtinActionSet(ofType: type) == nil {
            let set = HMActionSet.host_make(name: type, actionSetType: type)
            set.home = self
            actionSets.append(set)
        }
    }

    public func host_setHomeHubState(_ state: HMHomeHubState) {
        homeHubState = state
        delegate?.home(self, didUpdate: state)
    }

    public func host_setSupportsAddingNetworkRouter(_ value: Bool) {
        supportsAddingNetworkRouter = value
        delegate?.homeDidUpdateSupportedFeatures(self)
    }

    public func host_setPrimary(_ value: Bool) {
        isPrimary = value
    }

    public func host_notifyEncounteredError(_ error: any Error, for accessory: HMAccessory) {
        delegate?.home(self, didEncounterError: error, for: accessory)
    }

    public func host_notifyAccessControlUpdated() {
        delegate?.homeDidUpdateAccessControl(forCurrentUser: self)
    }

    public func host_addLocalUser(_ user: HMUser) {
        users.append(user)
        delegate?.home(self, didAdd: user)
    }

    public func host_removeLocalUser(_ user: HMUser) {
        users.removeAll { $0 === user }
        delegate?.home(self, didRemove: user)
    }
}

open class HMHomeManager: NSObject {
    public weak var delegate: (any HMHomeManagerDelegate)?
    public private(set) var homes: [HMHome] = []
    public private(set) var primaryHome: HMHome?
    public private(set) var authorizationStatus: HMHomeManagerAuthorizationStatus = [.determined, .restricted]

    public override init() {
        super.init()
    }

    public func addHome(named homeName: String) async throws -> HMHome {
        _ = homeName
        throw HMFailClosed(.homeAccessNotAuthorized)
    }

    public func removeHome(_ home: HMHome) async throws {
        _ = home
        throw HMFailClosed(.homeAccessNotAuthorized)
    }

    public func updatePrimaryHome(_ home: HMHome) async throws {
        _ = home
        throw HMFailClosed(.homeAccessNotAuthorized)
    }

    public func findVendorAccessory(hapPublicKey: Data) async throws -> HMAccessory? {
        _ = hapPublicKey
        throw HMFailClosed(.accessoryDiscoveryFailed)
    }
}

open class HMMediaSourceDisplayOrderProfile: NSObject {
    public protocol Delegate: AnyObject, Sendable {
        func mediaSourceDisplayOrderProfileDidUpdateOrder(_ profile: HMMediaSourceDisplayOrderProfile)
    }

    public weak var delegate: (any HMMediaSourceDisplayOrderProfile.Delegate)?
    public let canModifyOrder: Bool = false
    public private(set) var order: [Int] = []

    public func writeOrder(_ order: [Int]) async throws {
        _ = order
        throw HMFailClosed(.operationNotSupported)
    }
}
