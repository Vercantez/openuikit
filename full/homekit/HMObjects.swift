import Foundation

open class HMAccessControl: NSObject {}

open class HMHomeAccessControl: HMAccessControl {
    public private(set) var isAdministrator: Bool = false
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

    public override init() {
        self.name = ""
        self.uniqueIdentifier = UUID()
        self.accessories = []
        super.init()
    }

    public func updateName(_ name: String) async throws {
        _ = name
        throw HMFailClosed()
    }
}

open class HMZone: NSObject {
    public private(set) var name: String = ""
    public private(set) var uniqueIdentifier: UUID = UUID()
    public private(set) var rooms: [HMRoom] = []

    public func updateName(_ name: String) async throws {
        _ = name
        throw HMFailClosed()
    }

    public func addRoom(_ room: HMRoom) async throws {
        _ = room
        throw HMFailClosed()
    }

    public func removeRoom(_ room: HMRoom) async throws {
        _ = room
        throw HMFailClosed()
    }
}

open class HMServiceGroup: NSObject {
    public private(set) var name: String = ""
    public private(set) var uniqueIdentifier: UUID = UUID()
    public private(set) var services: [HMService] = []

    public func updateName(_ name: String) async throws {
        _ = name
        throw HMFailClosed()
    }

    public func addService(_ service: HMService) async throws {
        _ = service
        throw HMFailClosed()
    }

    public func removeService(_ service: HMService) async throws {
        _ = service
        throw HMFailClosed()
    }
}

open class HMActionSet: NSObject {
    public private(set) var name: String = ""
    public private(set) var uniqueIdentifier: UUID = UUID()
    public private(set) var actions: Set<HMAction> = []
    public private(set) var isExecuting: Bool = false
    public private(set) var actionSetType: String = HMActionSetTypeUserDefined

    public func updateName(_ name: String) async throws {
        _ = name
        throw HMFailClosed()
    }

    public func addAction(_ action: HMAction) async throws {
        _ = action
        throw HMFailClosed()
    }

    public func removeAction(_ action: HMAction) async throws {
        _ = action
        throw HMFailClosed()
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

    public func updateName(_ name: String) async throws {
        _ = name
        throw HMFailClosed()
    }

    public func updateAssociatedServiceType(_ serviceType: String?) async throws {
        _ = serviceType
        throw HMFailClosed()
    }

    public static func host_make(name: String, serviceType: String) -> HMService {
        let service = HMService()
        service.name = name
        service.serviceType = serviceType
        return service
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
        if let minimumValue, value.compare(minimumValue) == .orderedAscending { return false }
        if let maximumValue, value.compare(maximumValue) == .orderedDescending { return false }
        if let validValues {
            return validValues.contains { $0.isEqual(to: value) }
        }
        return true
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
        completion(HMFailClosed(.accessoryNotReachable))
    }

    public func writeValue(_ value: Any?) async throws {
        _ = value
        throw HMFailClosed(.accessoryNotReachable)
    }

    public func enableNotification(_ enable: Bool) async throws {
        _ = enable
        throw HMFailClosed(.notificationNotSupported)
    }

    public func updateAuthorizationData(_ data: Data?) async throws {
        _ = data
        throw HMFailClosed(.invalidOrMissingAuthorizationData)
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
        if let metadata {
            if let number = value as? NSNumber {
                if !metadata.contains(number) {
                    if let maximumValue = metadata.maximumValue,
                       number.compare(maximumValue) == .orderedDescending {
                        completion(HMFailClosed(.valueHigherThanMaximum))
                        return
                    }
                    if let minimumValue = metadata.minimumValue,
                       number.compare(minimumValue) == .orderedAscending {
                        completion(HMFailClosed(.valueLowerThanMinimum))
                        return
                    }
                    completion(HMFailClosed(.invalidValueType))
                    return
                }
            } else if metadata.format == HMCharacteristicMetadataFormatUInt8
                || metadata.format == HMCharacteristicMetadataFormatInt
                || metadata.format == HMCharacteristicMetadataFormatFloat
            {
                completion(HMFailClosed(.invalidValueType))
                return
            }
        }
        self.value = value
        completion(nil)
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

    public func updateName(_ name: String) async throws {
        _ = name
        throw HMFailClosed()
    }

    public func identify(completionHandler completion: @escaping ((any Error)?) -> Void) {
        completion(HMFailClosed(.accessoryNotReachable))
    }

    public static func host_make(name: String) -> HMAccessory {
        let accessory = HMAccessory()
        accessory.name = name
        return accessory
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

    public func payload(with ownershipToken: HMAccessoryOwnershipToken) -> HMAccessorySetupPayload? {
        _ = ownershipToken
        return nil
    }

    public func payload(with url: URL, ownershipToken: HMAccessoryOwnershipToken) -> HMAccessorySetupPayload? {
        _ = (url, ownershipToken)
        return nil
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
        return entireHomeRoom
    }

    public func servicesWithTypes(_ serviceTypes: [String]) -> [HMService]? {
        let wanted = Set(serviceTypes)
        let matched = hostedServices.filter { wanted.contains($0.serviceType) }
        return matched
    }

    public func builtinActionSet(ofType actionSetType: String) -> HMActionSet? {
        actionSets.first(where: { $0.actionSetType == actionSetType })
    }

    public func homeAccessControl(for user: HMUser) -> HMHomeAccessControl {
        _ = user
        return HMHomeAccessControl()
    }

    public func updateName(_ name: String) async throws {
        _ = name
        throw HMFailClosed()
    }

    public func addAccessory(_ accessory: HMAccessory) async throws {
        _ = accessory
        throw HMFailClosed()
    }

    public func removeAccessory(_ accessory: HMAccessory) async throws {
        _ = accessory
        throw HMFailClosed()
    }

    public func assignAccessory(_ accessory: HMAccessory, to room: HMRoom) async throws {
        _ = (accessory, room)
        throw HMFailClosed()
    }

    public func unblockAccessory(_ accessory: HMAccessory) async throws {
        _ = accessory
        throw HMFailClosed()
    }

    public func addAndSetUpAccessories() async throws {
        throw HMFailClosed(.missingEntitlement)
    }

    public func addAndSetUpAccessories(payload: HMAccessorySetupPayload) async throws -> [HMAccessory] {
        _ = payload
        throw HMFailClosed(.missingEntitlement)
    }

    public func addRoom(named roomName: String) async throws -> HMRoom {
        _ = roomName
        throw HMFailClosed()
    }

    public func removeRoom(_ room: HMRoom) async throws {
        _ = room
        throw HMFailClosed()
    }

    public func addZone(named zoneName: String) async throws -> HMZone {
        _ = zoneName
        throw HMFailClosed()
    }

    public func removeZone(_ zone: HMZone) async throws {
        _ = zone
        throw HMFailClosed()
    }

    public func addServiceGroup(named serviceGroupName: String) async throws -> HMServiceGroup {
        _ = serviceGroupName
        throw HMFailClosed()
    }

    public func removeServiceGroup(_ group: HMServiceGroup) async throws {
        _ = group
        throw HMFailClosed()
    }

    public func addActionSet(named actionSetName: String) async throws -> HMActionSet {
        _ = actionSetName
        throw HMFailClosed()
    }

    public func removeActionSet(_ actionSet: HMActionSet) async throws {
        _ = actionSet
        throw HMFailClosed()
    }

    public func executeActionSet(_ actionSet: HMActionSet) async throws {
        _ = actionSet
        throw HMFailClosed(.noHomeHub)
    }

    public func addTrigger(_ trigger: HMTrigger) async throws {
        _ = trigger
        throw HMFailClosed()
    }

    public func removeTrigger(_ trigger: HMTrigger) async throws {
        _ = trigger
        throw HMFailClosed()
    }

    public func addUser(completionHandler completion: @escaping (HMUser?, (any Error)?) -> Void) {
        completion(nil, HMFailClosed())
    }

    public func removeUser(_ user: HMUser, completionHandler completion: @escaping ((any Error)?) -> Void) {
        _ = user
        completion(HMFailClosed())
    }

    public func manageUsers(completionHandler completion: @escaping ((any Error)?) -> Void) {
        completion(HMFailClosed())
    }

    public static func host_make(name: String) -> HMHome {
        let home = HMHome()
        home.name = name
        return home
    }

    public func host_setServices(_ services: [HMService]) {
        hostedServices = services
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
