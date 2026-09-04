import Foundation

struct CNContactStorage {
    var identifier: String
    var uuid: UUID
    var contactType: CNContactType = .person
    var namePrefix = ""
    var givenName = ""
    var middleName = ""
    var familyName = ""
    var previousFamilyName = ""
    var nameSuffix = ""
    var nickname = ""
    var organizationName = ""
    var departmentName = ""
    var jobTitle = ""
    var phoneticGivenName = ""
    var phoneticMiddleName = ""
    var phoneticFamilyName = ""
    var phoneticOrganizationName = ""
    var birthday: DateComponents?
    var nonGregorianBirthday: DateComponents?
    var note = ""
    var imageData: Data?
    var phoneNumbers: [CNLabeledValue<CNPhoneNumber>] = []
    var emailAddresses: [CNLabeledValue<NSString>] = []
    var postalAddresses: [CNLabeledValue<CNPostalAddress>] = []
    var dates: [CNLabeledValue<NSDateComponents>] = []
    var urlAddresses: [CNLabeledValue<NSString>] = []
    var contactRelations: [CNLabeledValue<CNContactRelation>] = []
    var socialProfiles: [CNLabeledValue<CNSocialProfile>] = []
    var instantMessageAddresses: [CNLabeledValue<CNInstantMessageAddress>] = []
    var availableKeys: Set<String> = Set(CNAllContactPropertyKeys())
    var unifiedIdentifiers: Set<String> = []

    static func makeNew() -> CNContactStorage {
        let uuid = UUID()
        return CNContactStorage(identifier: uuid.uuidString, uuid: uuid)
    }

    func projected(keys: [String]?) -> CNContactStorage {
        guard let keys else { return self }
        var copy = self
        copy.availableKeys = Set(keys).union([CNContactIdentifierKey])
        return copy
    }
}

open class CNContact: NSObject, NSCopying, NSSecureCoding, NSMutableCopying, Identifiable {
    public typealias ID = UUID

    var storage: CNContactStorage

    public var id: UUID { storage.uuid }

    init(storage: CNContactStorage) {
        self.storage = storage
        super.init()
    }

    public var identifier: String { storage.identifier }
    public var contactType: CNContactType { storage.contactType }
    public var namePrefix: String { storage.namePrefix }
    public var givenName: String { storage.givenName }
    public var middleName: String { storage.middleName }
    public var familyName: String { storage.familyName }
    public var previousFamilyName: String { storage.previousFamilyName }
    public var nameSuffix: String { storage.nameSuffix }
    public var nickname: String { storage.nickname }
    public var organizationName: String { storage.organizationName }
    public var departmentName: String { storage.departmentName }
    public var jobTitle: String { storage.jobTitle }
    public var phoneticGivenName: String { storage.phoneticGivenName }
    public var phoneticMiddleName: String { storage.phoneticMiddleName }
    public var phoneticFamilyName: String { storage.phoneticFamilyName }
    public var phoneticOrganizationName: String { storage.phoneticOrganizationName }
    public var birthday: DateComponents? { storage.birthday }
    public var nonGregorianBirthday: DateComponents? { storage.nonGregorianBirthday }
    public var note: String { storage.note }
    public var imageData: Data? { storage.imageData }
    public var imageDataAvailable: Bool { storage.imageData != nil }
    public var thumbnailImageData: Data? { storage.imageData }
    public var phoneNumbers: [CNLabeledValue<CNPhoneNumber>] { storage.phoneNumbers }
    public var emailAddresses: [CNLabeledValue<NSString>] { storage.emailAddresses }
    public var postalAddresses: [CNLabeledValue<CNPostalAddress>] { storage.postalAddresses }
    public var dates: [CNLabeledValue<NSDateComponents>] { storage.dates }
    public var urlAddresses: [CNLabeledValue<NSString>] { storage.urlAddresses }
    public var contactRelations: [CNLabeledValue<CNContactRelation>] { storage.contactRelations }
    public var socialProfiles: [CNLabeledValue<CNSocialProfile>] { storage.socialProfiles }
    public var instantMessageAddresses: [CNLabeledValue<CNInstantMessageAddress>] { storage.instantMessageAddresses }

    open class func localizedString(forKey key: String) -> String {
        CNLocalizedContactKey(key)
    }

    open class func descriptorForAllComparatorKeys() -> any CNKeyDescriptor {
        CNContactKeyDescriptor(keys: [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactMiddleNameKey,
            CNContactNamePrefixKey,
            CNContactNameSuffixKey,
            CNContactOrganizationNameKey,
        ])
    }

    open class func comparator(forNameSortOrder sortOrder: CNContactSortOrder) -> Comparator {
        { lhs, rhs in
            guard let left = lhs as? CNContact, let right = rhs as? CNContact else {
                return .orderedSame
            }
            let leftName = left.sortKey(sortOrder)
            let rightName = right.sortKey(sortOrder)
            if leftName < rightName { return .orderedAscending }
            if leftName > rightName { return .orderedDescending }
            return .orderedSame
        }
    }

    open class func predicateForContacts(withIdentifiers identifiers: [String]) -> NSPredicate {
        CNStorePredicate.make(.contactsWithIdentifiers(identifiers))
    }

    open class func predicateForContacts(matchingName name: String) -> NSPredicate {
        CNStorePredicate.make(.contactsMatchingName(name))
    }

    open class func predicateForContacts(matchingEmailAddress emailAddress: String) -> NSPredicate {
        CNStorePredicate.make(.contactsMatchingEmail(emailAddress))
    }

    open class func predicateForContacts(matching phoneNumber: CNPhoneNumber) -> NSPredicate {
        CNStorePredicate.make(.contactsMatchingPhone(phoneNumber.stringValue))
    }

    open class func predicateForContactsInContainer(withIdentifier containerIdentifier: String) -> NSPredicate {
        CNStorePredicate.make(.contactsInContainer(containerIdentifier))
    }

    open class func predicateForContactsInGroup(withIdentifier groupIdentifier: String) -> NSPredicate {
        CNStorePredicate.make(.contactsInGroup(groupIdentifier))
    }

    open func isKeyAvailable(_ key: String) -> Bool {
        storage.availableKeys.contains(key)
    }

    open func areKeysAvailable(_ keyDescriptors: [any CNKeyDescriptor]) -> Bool {
        let keys = CNFlattenKeyDescriptors(keyDescriptors)
        return keys.allSatisfy { storage.availableKeys.contains($0) }
    }

    open func isUnifiedWithContact(withIdentifier contactIdentifier: String) -> Bool {
        storage.unifiedIdentifiers.contains(contactIdentifier) || storage.identifier == contactIdentifier
    }

    func sortKey(_ order: CNContactSortOrder) -> String {
        let resolved: CNContactSortOrder
        switch order {
        case .none:
            return identifier.lowercased()
        case .userDefault:
            resolved = CNContactsUserDefaults.shared().sortOrder == .familyName ? .familyName : .givenName
        case .givenName, .familyName:
            resolved = order
        }
        if contactType == .organization && !organizationName.isEmpty {
            return organizationName.lowercased()
        }
        if resolved == .familyName {
            return "\(familyName) \(givenName)".trimmingCharacters(in: .whitespaces).lowercased()
        }
        return "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces).lowercased()
    }

    func displayNameParts(phonetic: Bool) -> (first: String, last: String, organization: String) {
        if phonetic {
            return (phoneticGivenName, phoneticFamilyName, phoneticOrganizationName)
        }
        return (givenName, familyName, organizationName)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNContact(storage: storage)
    }

    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        CNMutableContact(storage: storage)
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard let identifier = coder.decodeObject(of: NSString.self, forKey: "identifier") as String? else {
            return nil
        }
        var storage = CNContactStorage(identifier: identifier, uuid: UUID(uuidString: identifier) ?? UUID())
        storage.contactType = CNContactType(rawValue: coder.decodeInteger(forKey: "contactType")) ?? .person
        storage.namePrefix = coder.decodeObject(of: NSString.self, forKey: "namePrefix") as String? ?? ""
        storage.givenName = coder.decodeObject(of: NSString.self, forKey: "givenName") as String? ?? ""
        storage.middleName = coder.decodeObject(of: NSString.self, forKey: "middleName") as String? ?? ""
        storage.familyName = coder.decodeObject(of: NSString.self, forKey: "familyName") as String? ?? ""
        storage.previousFamilyName = coder.decodeObject(of: NSString.self, forKey: "previousFamilyName") as String? ?? ""
        storage.nameSuffix = coder.decodeObject(of: NSString.self, forKey: "nameSuffix") as String? ?? ""
        storage.nickname = coder.decodeObject(of: NSString.self, forKey: "nickname") as String? ?? ""
        storage.organizationName = coder.decodeObject(of: NSString.self, forKey: "organizationName") as String? ?? ""
        storage.departmentName = coder.decodeObject(of: NSString.self, forKey: "departmentName") as String? ?? ""
        storage.jobTitle = coder.decodeObject(of: NSString.self, forKey: "jobTitle") as String? ?? ""
        storage.phoneticGivenName = coder.decodeObject(of: NSString.self, forKey: "phoneticGivenName") as String? ?? ""
        storage.phoneticMiddleName = coder.decodeObject(of: NSString.self, forKey: "phoneticMiddleName") as String? ?? ""
        storage.phoneticFamilyName = coder.decodeObject(of: NSString.self, forKey: "phoneticFamilyName") as String? ?? ""
        storage.phoneticOrganizationName = coder.decodeObject(of: NSString.self, forKey: "phoneticOrganizationName") as String? ?? ""
        storage.note = coder.decodeObject(of: NSString.self, forKey: "note") as String? ?? ""
        storage.imageData = coder.decodeObject(of: NSData.self, forKey: "imageData") as Data?
        self.storage = storage
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(contactType.rawValue, forKey: "contactType")
        coder.encode(namePrefix as NSString, forKey: "namePrefix")
        coder.encode(givenName as NSString, forKey: "givenName")
        coder.encode(middleName as NSString, forKey: "middleName")
        coder.encode(familyName as NSString, forKey: "familyName")
        coder.encode(previousFamilyName as NSString, forKey: "previousFamilyName")
        coder.encode(nameSuffix as NSString, forKey: "nameSuffix")
        coder.encode(nickname as NSString, forKey: "nickname")
        coder.encode(organizationName as NSString, forKey: "organizationName")
        coder.encode(departmentName as NSString, forKey: "departmentName")
        coder.encode(jobTitle as NSString, forKey: "jobTitle")
        coder.encode(phoneticGivenName as NSString, forKey: "phoneticGivenName")
        coder.encode(phoneticMiddleName as NSString, forKey: "phoneticMiddleName")
        coder.encode(phoneticFamilyName as NSString, forKey: "phoneticFamilyName")
        coder.encode(phoneticOrganizationName as NSString, forKey: "phoneticOrganizationName")
        coder.encode(note as NSString, forKey: "note")
        coder.encode(imageData as NSData?, forKey: "imageData")
    }
}

open class CNMutableContact: CNContact {
    public init() {
        super.init(storage: .makeNew())
    }

    override init(storage: CNContactStorage) {
        super.init(storage: storage)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override var contactType: CNContactType {
        get { storage.contactType }
        set { storage.contactType = newValue }
    }
    public override var namePrefix: String {
        get { storage.namePrefix }
        set { storage.namePrefix = newValue }
    }
    public override var givenName: String {
        get { storage.givenName }
        set { storage.givenName = newValue }
    }
    public override var middleName: String {
        get { storage.middleName }
        set { storage.middleName = newValue }
    }
    public override var familyName: String {
        get { storage.familyName }
        set { storage.familyName = newValue }
    }
    public override var previousFamilyName: String {
        get { storage.previousFamilyName }
        set { storage.previousFamilyName = newValue }
    }
    public override var nameSuffix: String {
        get { storage.nameSuffix }
        set { storage.nameSuffix = newValue }
    }
    public override var nickname: String {
        get { storage.nickname }
        set { storage.nickname = newValue }
    }
    public override var organizationName: String {
        get { storage.organizationName }
        set { storage.organizationName = newValue }
    }
    public override var departmentName: String {
        get { storage.departmentName }
        set { storage.departmentName = newValue }
    }
    public override var jobTitle: String {
        get { storage.jobTitle }
        set { storage.jobTitle = newValue }
    }
    public override var phoneticGivenName: String {
        get { storage.phoneticGivenName }
        set { storage.phoneticGivenName = newValue }
    }
    public override var phoneticMiddleName: String {
        get { storage.phoneticMiddleName }
        set { storage.phoneticMiddleName = newValue }
    }
    public override var phoneticFamilyName: String {
        get { storage.phoneticFamilyName }
        set { storage.phoneticFamilyName = newValue }
    }
    public override var phoneticOrganizationName: String {
        get { storage.phoneticOrganizationName }
        set { storage.phoneticOrganizationName = newValue }
    }
    public override var birthday: DateComponents? {
        get { storage.birthday }
        set { storage.birthday = newValue }
    }
    public override var nonGregorianBirthday: DateComponents? {
        get { storage.nonGregorianBirthday }
        set { storage.nonGregorianBirthday = newValue }
    }
    public override var note: String {
        get { storage.note }
        set { storage.note = newValue }
    }
    public override var imageData: Data? {
        get { storage.imageData }
        set { storage.imageData = newValue }
    }
    public override var phoneNumbers: [CNLabeledValue<CNPhoneNumber>] {
        get { storage.phoneNumbers }
        set { storage.phoneNumbers = newValue }
    }
    public override var emailAddresses: [CNLabeledValue<NSString>] {
        get { storage.emailAddresses }
        set { storage.emailAddresses = newValue }
    }
    public override var postalAddresses: [CNLabeledValue<CNPostalAddress>] {
        get { storage.postalAddresses }
        set { storage.postalAddresses = newValue }
    }
    public override var dates: [CNLabeledValue<NSDateComponents>] {
        get { storage.dates }
        set { storage.dates = newValue }
    }
    public override var urlAddresses: [CNLabeledValue<NSString>] {
        get { storage.urlAddresses }
        set { storage.urlAddresses = newValue }
    }
    public override var contactRelations: [CNLabeledValue<CNContactRelation>] {
        get { storage.contactRelations }
        set { storage.contactRelations = newValue }
    }
    public override var socialProfiles: [CNLabeledValue<CNSocialProfile>] {
        get { storage.socialProfiles }
        set { storage.socialProfiles = newValue }
    }
    public override var instantMessageAddresses: [CNLabeledValue<CNInstantMessageAddress>] {
        get { storage.instantMessageAddresses }
        set { storage.instantMessageAddresses = newValue }
    }
}
