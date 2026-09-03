import Foundation

public class CNLabeledValue<ValueType: NSCopying & NSSecureCoding>: NSObject, NSCopying, NSSecureCoding {
    public let identifier: String
    public let label: String?
    public let value: ValueType

    public required init(label: String?, value: ValueType) {
        self.identifier = UUID().uuidString
        self.label = label
        self.value = value.copy(with: nil) as? ValueType ?? value
        super.init()
    }

    required init(identifier: String, label: String?, value: ValueType) {
        self.identifier = identifier
        self.label = label
        self.value = value.copy(with: nil) as? ValueType ?? value
        super.init()
    }

    public class func localizedString(forLabel label: String) -> String {
        CNLocalizedLabel(label)
    }

    public func settingLabel(_ label: String?) -> Self {
        Self.init(identifier: identifier, label: label, value: value)
    }

    public func settingValue(_ value: ValueType) -> Self {
        Self.init(identifier: identifier, label: label, value: value)
    }

    public func settingLabel(_ label: String?, value: ValueType) -> Self {
        Self.init(identifier: identifier, label: label, value: value)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNLabeledValue(identifier: identifier, label: label, value: value)
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard
            let identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String?,
            let decoded = coder.decodeObject(of: [NSObject.self], forKey: "value") as? ValueType
        else { return nil }
        self.identifier = identifier
        self.label = coder.decodeObject(of: NSString.self, forKey: "label") as String?
        self.value = decoded
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(label as NSString?, forKey: "label")
        coder.encode(value, forKey: "value")
    }
}

open class CNPhoneNumber: NSObject, NSCopying, NSSecureCoding {
    public let stringValue: String

    public required override init() {
        self.stringValue = ""
        super.init()
    }

    open class func new() -> Self {
        self.init()
    }

    public init(stringValue string: String) {
        self.stringValue = string
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNPhoneNumber(stringValue: stringValue)
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard let string = coder.decodeObject(of: NSString.self, forKey: "stringValue") as String?
        else { return nil }
        self.stringValue = string
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(stringValue as NSString, forKey: "stringValue")
    }

    func digits() -> String {
        stringValue.filter(\.isNumber)
    }
}

struct CNPostalAddressStorage {
    var street = ""
    var subLocality = ""
    var city = ""
    var subAdministrativeArea = ""
    var state = ""
    var postalCode = ""
    var country = ""
    var isoCountryCode = ""
}

open class CNPostalAddress: NSObject, NSCopying, NSSecureCoding, NSMutableCopying {
    var storage: CNPostalAddressStorage

    public override init() {
        self.storage = CNPostalAddressStorage()
        super.init()
    }

    init(storage: CNPostalAddressStorage) {
        self.storage = storage
        super.init()
    }

    public var street: String { storage.street }
    public var subLocality: String { storage.subLocality }
    public var city: String { storage.city }
    public var subAdministrativeArea: String { storage.subAdministrativeArea }
    public var state: String { storage.state }
    public var postalCode: String { storage.postalCode }
    public var country: String { storage.country }
    public var isoCountryCode: String { storage.isoCountryCode }

    open class func localizedString(forKey key: String) -> String {
        CNLocalizedContactKey(key)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNPostalAddress(storage: storage)
    }

    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        CNMutablePostalAddress(storage: storage)
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        var storage = CNPostalAddressStorage()
        storage.street = coder.decodeObject(of: NSString.self, forKey: "street") as String? ?? ""
        storage.subLocality = coder.decodeObject(of: NSString.self, forKey: "subLocality") as String? ?? ""
        storage.city = coder.decodeObject(of: NSString.self, forKey: "city") as String? ?? ""
        storage.subAdministrativeArea = coder.decodeObject(of: NSString.self, forKey: "subAdministrativeArea") as String? ?? ""
        storage.state = coder.decodeObject(of: NSString.self, forKey: "state") as String? ?? ""
        storage.postalCode = coder.decodeObject(of: NSString.self, forKey: "postalCode") as String? ?? ""
        storage.country = coder.decodeObject(of: NSString.self, forKey: "country") as String? ?? ""
        storage.isoCountryCode = coder.decodeObject(of: NSString.self, forKey: "isoCountryCode") as String? ?? ""
        self.storage = storage
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(street as NSString, forKey: "street")
        coder.encode(subLocality as NSString, forKey: "subLocality")
        coder.encode(city as NSString, forKey: "city")
        coder.encode(subAdministrativeArea as NSString, forKey: "subAdministrativeArea")
        coder.encode(state as NSString, forKey: "state")
        coder.encode(postalCode as NSString, forKey: "postalCode")
        coder.encode(country as NSString, forKey: "country")
        coder.encode(isoCountryCode as NSString, forKey: "isoCountryCode")
    }
}

open class CNMutablePostalAddress: CNPostalAddress {
    public override init() {
        super.init()
    }

    override init(storage: CNPostalAddressStorage) {
        super.init(storage: storage)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override var street: String {
        get { storage.street }
        set { storage.street = newValue }
    }
    public override var subLocality: String {
        get { storage.subLocality }
        set { storage.subLocality = newValue }
    }
    public override var city: String {
        get { storage.city }
        set { storage.city = newValue }
    }
    public override var subAdministrativeArea: String {
        get { storage.subAdministrativeArea }
        set { storage.subAdministrativeArea = newValue }
    }
    public override var state: String {
        get { storage.state }
        set { storage.state = newValue }
    }
    public override var postalCode: String {
        get { storage.postalCode }
        set { storage.postalCode = newValue }
    }
    public override var country: String {
        get { storage.country }
        set { storage.country = newValue }
    }
    public override var isoCountryCode: String {
        get { storage.isoCountryCode }
        set { storage.isoCountryCode = newValue }
    }
}

open class CNContactRelation: NSObject, NSCopying, NSSecureCoding {
    public let name: String

    public init(name: String) {
        self.name = name
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNContactRelation(name: name)
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard let name = coder.decodeObject(of: NSString.self, forKey: "name") as String?
        else { return nil }
        self.name = name
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(name as NSString, forKey: "name")
    }
}

open class CNInstantMessageAddress: NSObject, NSCopying, NSSecureCoding {
    public let username: String
    public let service: String

    public init(username: String, service: String) {
        self.username = username
        self.service = service
        super.init()
    }

    open class func localizedString(forKey key: String) -> String {
        CNLocalizedContactKey(key)
    }

    open class func localizedString(forService service: String) -> String {
        service
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNInstantMessageAddress(username: username, service: service)
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        self.username = coder.decodeObject(of: NSString.self, forKey: "username") as String? ?? ""
        self.service = coder.decodeObject(of: NSString.self, forKey: "service") as String? ?? ""
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(username as NSString, forKey: "username")
        coder.encode(service as NSString, forKey: "service")
    }
}

open class CNSocialProfile: NSObject, NSCopying, NSSecureCoding {
    public let urlString: String
    public let username: String
    public let userIdentifier: String
    public let service: String

    public init(urlString: String?, username: String?, userIdentifier: String?, service: String?) {
        self.urlString = urlString ?? ""
        self.username = username ?? ""
        self.userIdentifier = userIdentifier ?? ""
        self.service = service ?? ""
        super.init()
    }

    open class func localizedString(forKey key: String) -> String {
        CNLocalizedContactKey(key)
    }

    open class func localizedString(forService service: String) -> String {
        service
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNSocialProfile(
            urlString: urlString,
            username: username,
            userIdentifier: userIdentifier,
            service: service
        )
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        self.urlString = coder.decodeObject(of: NSString.self, forKey: "urlString") as String? ?? ""
        self.username = coder.decodeObject(of: NSString.self, forKey: "username") as String? ?? ""
        self.userIdentifier = coder.decodeObject(of: NSString.self, forKey: "userIdentifier") as String? ?? ""
        self.service = coder.decodeObject(of: NSString.self, forKey: "service") as String? ?? ""
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(urlString as NSString, forKey: "urlString")
        coder.encode(username as NSString, forKey: "username")
        coder.encode(userIdentifier as NSString, forKey: "userIdentifier")
        coder.encode(service as NSString, forKey: "service")
    }
}

open class CNGroup: NSObject, NSCopying, NSSecureCoding, NSMutableCopying {
    var storageIdentifier: String
    var storageName: String

    public var identifier: String { storageIdentifier }
    public var name: String { storageName }

    public override init() {
        self.storageIdentifier = UUID().uuidString
        self.storageName = ""
        super.init()
    }

    init(identifier: String, name: String) {
        self.storageIdentifier = identifier
        self.storageName = name
        super.init()
    }

    open class func predicateForGroups(withIdentifiers identifiers: [String]) -> NSPredicate {
        CNStorePredicate.make(.groupsWithIdentifiers(identifiers))
    }

    open class func predicateForGroupsInContainer(withIdentifier containerIdentifier: String) -> NSPredicate {
        CNStorePredicate.make(.groupsInContainer(containerIdentifier))
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNGroup(identifier: storageIdentifier, name: storageName)
    }

    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        CNMutableGroup(identifier: storageIdentifier, name: storageName)
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        self.storageIdentifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String? ?? UUID().uuidString
        self.storageName = coder.decodeObject(of: NSString.self, forKey: "name") as String? ?? ""
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(storageIdentifier as NSString, forKey: "identifier")
        coder.encode(storageName as NSString, forKey: "name")
    }
}

open class CNMutableGroup: CNGroup {
    public override init() {
        super.init()
    }

    override init(identifier: String, name: String) {
        super.init(identifier: identifier, name: name)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override var name: String {
        get { storageName }
        set { storageName = newValue }
    }
}

open class CNContainer: NSObject, NSCopying, NSSecureCoding {
    public let identifier: String
    public let name: String
    public let type: CNContainerType

    public init(identifier: String, name: String, type: CNContainerType) {
        self.identifier = identifier
        self.name = name
        self.type = type
        super.init()
    }

    open class func predicateForContainers(withIdentifiers identifiers: [String]) -> NSPredicate {
        CNStorePredicate.make(.containersWithIdentifiers(identifiers))
    }

    open class func predicateForContainerOfContact(withIdentifier contactIdentifier: String) -> NSPredicate {
        CNStorePredicate.make(.containerOfContact(contactIdentifier))
    }

    open class func predicateForContainerOfGroup(withIdentifier groupIdentifier: String) -> NSPredicate {
        CNStorePredicate.make(.containerOfGroup(groupIdentifier))
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNContainer(identifier: identifier, name: name, type: type)
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        self.identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String? ?? ""
        self.name = coder.decodeObject(of: NSString.self, forKey: "name") as String? ?? ""
        self.type = CNContainerType(rawValue: coder.decodeInteger(forKey: "type")) ?? .unassigned
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(name as NSString, forKey: "name")
        coder.encode(type.rawValue, forKey: "type")
    }
}

open class CNContactProperty: NSObject, NSCopying, NSSecureCoding {
    public let contact: CNContact
    public let key: String
    public let value: Any?
    public let identifier: String?
    public let label: String?

    public init(
        contact: CNContact,
        key: String,
        value: Any?,
        identifier: String? = nil,
        label: String? = nil
    ) {
        self.contact = contact.copy() as? CNContact ?? contact
        self.key = key
        self.value = value
        self.identifier = identifier
        self.label = label
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNContactProperty(
            contact: contact,
            key: key,
            value: value,
            identifier: identifier,
            label: label
        )
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard let contact = coder.decodeObject(of: CNContact.self, forKey: "contact") else { return nil }
        self.contact = contact
        self.key = coder.decodeObject(of: NSString.self, forKey: "key") as String? ?? ""
        self.value = coder.decodeObject(of: [NSObject.self], forKey: "value")
        self.identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String?
        self.label = coder.decodeObject(of: NSString.self, forKey: "label") as String?
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(contact, forKey: "contact")
        coder.encode(key as NSString, forKey: "key")
        if let value = value {
            coder.encode(value, forKey: "value")
        }
        coder.encode(identifier as NSString?, forKey: "identifier")
        coder.encode(label as NSString?, forKey: "label")
    }
}

open class CNContactsUserDefaults: NSObject {
    private static let sharedDefaults = CNContactsUserDefaults()

    open class func shared() -> Self {
        sharedDefaults as! Self
    }

    public var countryCode: String {
        Locale.current.region?.identifier ?? "US"
    }

    public var sortOrder: CNContactSortOrder {
        .givenName
    }
}
