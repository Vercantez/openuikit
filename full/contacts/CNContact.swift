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
    var thumbnailImageData: Data?
    var imagePresent = false
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

    mutating func setImageData(_ data: Data?) {
        imageData = data
        imagePresent = data != nil
        // Documented Linux thumbnail rule: thumbnail bytes equal imageData.
        // There is no Apple ImageIO downsample pipeline on this host.
        thumbnailImageData = data
    }

    func projected(keys: [String]?) -> CNContactStorage {
        guard let keys else { return self }
        var copy = self
        copy.availableKeys = Set(keys).union([CNContactIdentifierKey])
        if !copy.availableKeys.contains(CNContactImageDataKey) {
            copy.imageData = nil
        }
        if !copy.availableKeys.contains(CNContactThumbnailImageDataKey) {
            copy.thumbnailImageData = nil
        } else if copy.thumbnailImageData == nil {
            copy.thumbnailImageData = self.imageData
        }
        return copy
    }
}

enum CNUnfetchedKeyAccess {
    static let tlsKey = "OpenUIKit.CNUnfetchedKeyError"

    static func record(_ key: String) {
        let error = CNError(.unauthorizedKeys, userInfo: [CNErrorUserInfoKeyPathsKey: [key]])
        Thread.current.threadDictionary[tlsKey] = error
    }

    static func consume() -> CNError? {
        let error = Thread.current.threadDictionary[tlsKey] as? CNError
        Thread.current.threadDictionary.removeObject(forKey: tlsKey)
        return error
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
    public var contactType: CNContactType { accessed(CNContactTypeKey, storage.contactType, empty: .person) }
    public var namePrefix: String { accessed(CNContactNamePrefixKey, storage.namePrefix, empty: "") }
    public var givenName: String { accessed(CNContactGivenNameKey, storage.givenName, empty: "") }
    public var middleName: String { accessed(CNContactMiddleNameKey, storage.middleName, empty: "") }
    public var familyName: String { accessed(CNContactFamilyNameKey, storage.familyName, empty: "") }
    public var previousFamilyName: String { accessed(CNContactPreviousFamilyNameKey, storage.previousFamilyName, empty: "") }
    public var nameSuffix: String { accessed(CNContactNameSuffixKey, storage.nameSuffix, empty: "") }
    public var nickname: String { accessed(CNContactNicknameKey, storage.nickname, empty: "") }
    public var organizationName: String { accessed(CNContactOrganizationNameKey, storage.organizationName, empty: "") }
    public var departmentName: String { accessed(CNContactDepartmentNameKey, storage.departmentName, empty: "") }
    public var jobTitle: String { accessed(CNContactJobTitleKey, storage.jobTitle, empty: "") }
    public var phoneticGivenName: String { accessed(CNContactPhoneticGivenNameKey, storage.phoneticGivenName, empty: "") }
    public var phoneticMiddleName: String { accessed(CNContactPhoneticMiddleNameKey, storage.phoneticMiddleName, empty: "") }
    public var phoneticFamilyName: String { accessed(CNContactPhoneticFamilyNameKey, storage.phoneticFamilyName, empty: "") }
    public var phoneticOrganizationName: String { accessed(CNContactPhoneticOrganizationNameKey, storage.phoneticOrganizationName, empty: "") }
    public var birthday: DateComponents? { accessed(CNContactBirthdayKey, storage.birthday, empty: nil) }
    public var nonGregorianBirthday: DateComponents? { accessed(CNContactNonGregorianBirthdayKey, storage.nonGregorianBirthday, empty: nil) }
    public var note: String { accessed(CNContactNoteKey, storage.note, empty: "") }
    public var imageData: Data? { accessed(CNContactImageDataKey, storage.imageData, empty: nil) }
    public var imageDataAvailable: Bool {
        accessed(CNContactImageDataAvailableKey, storage.imagePresent || storage.imageData != nil, empty: false)
    }
    public var thumbnailImageData: Data? {
        accessed(CNContactThumbnailImageDataKey, storage.thumbnailImageData ?? storage.imageData, empty: nil)
    }
    public var phoneNumbers: [CNLabeledValue<CNPhoneNumber>] { accessed(CNContactPhoneNumbersKey, storage.phoneNumbers, empty: []) }
    public var emailAddresses: [CNLabeledValue<NSString>] { accessed(CNContactEmailAddressesKey, storage.emailAddresses, empty: []) }
    public var postalAddresses: [CNLabeledValue<CNPostalAddress>] { accessed(CNContactPostalAddressesKey, storage.postalAddresses, empty: []) }
    public var dates: [CNLabeledValue<NSDateComponents>] { accessed(CNContactDatesKey, storage.dates, empty: []) }
    public var urlAddresses: [CNLabeledValue<NSString>] { accessed(CNContactUrlAddressesKey, storage.urlAddresses, empty: []) }
    public var contactRelations: [CNLabeledValue<CNContactRelation>] { accessed(CNContactRelationsKey, storage.contactRelations, empty: []) }
    public var socialProfiles: [CNLabeledValue<CNSocialProfile>] { accessed(CNContactSocialProfilesKey, storage.socialProfiles, empty: []) }
    public var instantMessageAddresses: [CNLabeledValue<CNInstantMessageAddress>] {
        accessed(CNContactInstantMessageAddressesKey, storage.instantMessageAddresses, empty: [])
    }

    private func accessed<T>(_ key: String, _ value: T, empty: T) -> T {
        if storage.availableKeys.contains(key) { return value }
        CNUnfetchedKeyAccess.record(key)
        return empty
    }

    /// Throws `CNError.unauthorizedKeys` when `key` was not included in `keysToFetch`.
    /// Darwin raises `CNContactPropertyNotFetchedExceptionName`; Linux uses this
    /// throwing boundary because `NSException` is not a recoverable control path.
    open func requireKeyAvailable(_ key: String) throws {
        guard isKeyAvailable(key) else {
            throw CNError(.unauthorizedKeys, userInfo: [CNErrorUserInfoKeyPathsKey: [key]])
        }
    }

    open func requireKeysAvailable(_ keyDescriptors: [any CNKeyDescriptor]) throws {
        let keys = CNFlattenKeyDescriptors(keyDescriptors)
        let missing = keys.filter { !storage.availableKeys.contains($0) }
        if !missing.isEmpty {
            throw CNError(.unauthorizedKeys, userInfo: [CNErrorUserInfoKeyPathsKey: missing])
        }
    }

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

    @_spi(OpenUIKitHost)
    public static func _consumeUnfetchedKeyError() -> CNError? {
        CNUnfetchedKeyAccess.consume()
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
        storage.thumbnailImageData = coder.decodeObject(of: NSData.self, forKey: "thumbnailImageData") as Data?
        storage.imagePresent = coder.decodeBool(forKey: "imagePresent") || storage.imageData != nil
        if let year = coder.decodeObject(of: NSNumber.self, forKey: "birthdayYear") {
            var birthday = DateComponents()
            birthday.calendar = Calendar(identifier: .gregorian)
            birthday.year = year.intValue
            birthday.month = (coder.decodeObject(of: NSNumber.self, forKey: "birthdayMonth") as NSNumber?)?.intValue
            birthday.day = (coder.decodeObject(of: NSNumber.self, forKey: "birthdayDay") as NSNumber?)?.intValue
            storage.birthday = birthday
        }
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
        coder.encode(thumbnailImageData as NSData?, forKey: "thumbnailImageData")
        coder.encode(storage.imagePresent, forKey: "imagePresent")
        if let birthday {
            if let year = birthday.year { coder.encode(NSNumber(value: year), forKey: "birthdayYear") }
            if let month = birthday.month { coder.encode(NSNumber(value: month), forKey: "birthdayMonth") }
            if let day = birthday.day { coder.encode(NSNumber(value: day), forKey: "birthdayDay") }
        }
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
        get { super.contactType }
        set { storage.contactType = newValue }
    }
    public override var namePrefix: String {
        get { super.namePrefix }
        set { storage.namePrefix = newValue }
    }
    public override var givenName: String {
        get { super.givenName }
        set { storage.givenName = newValue }
    }
    public override var middleName: String {
        get { super.middleName }
        set { storage.middleName = newValue }
    }
    public override var familyName: String {
        get { super.familyName }
        set { storage.familyName = newValue }
    }
    public override var previousFamilyName: String {
        get { super.previousFamilyName }
        set { storage.previousFamilyName = newValue }
    }
    public override var nameSuffix: String {
        get { super.nameSuffix }
        set { storage.nameSuffix = newValue }
    }
    public override var nickname: String {
        get { super.nickname }
        set { storage.nickname = newValue }
    }
    public override var organizationName: String {
        get { super.organizationName }
        set { storage.organizationName = newValue }
    }
    public override var departmentName: String {
        get { super.departmentName }
        set { storage.departmentName = newValue }
    }
    public override var jobTitle: String {
        get { super.jobTitle }
        set { storage.jobTitle = newValue }
    }
    public override var phoneticGivenName: String {
        get { super.phoneticGivenName }
        set { storage.phoneticGivenName = newValue }
    }
    public override var phoneticMiddleName: String {
        get { super.phoneticMiddleName }
        set { storage.phoneticMiddleName = newValue }
    }
    public override var phoneticFamilyName: String {
        get { super.phoneticFamilyName }
        set { storage.phoneticFamilyName = newValue }
    }
    public override var phoneticOrganizationName: String {
        get { super.phoneticOrganizationName }
        set { storage.phoneticOrganizationName = newValue }
    }
    public override var birthday: DateComponents? {
        get { super.birthday }
        set { storage.birthday = newValue }
    }
    public override var nonGregorianBirthday: DateComponents? {
        get { super.nonGregorianBirthday }
        set { storage.nonGregorianBirthday = newValue }
    }
    public override var note: String {
        get { super.note }
        set { storage.note = newValue }
    }
    public override var imageData: Data? {
        get { super.imageData }
        set { storage.setImageData(newValue) }
    }
    public override var phoneNumbers: [CNLabeledValue<CNPhoneNumber>] {
        get { super.phoneNumbers }
        set { storage.phoneNumbers = newValue }
    }
    public override var emailAddresses: [CNLabeledValue<NSString>] {
        get { super.emailAddresses }
        set { storage.emailAddresses = newValue }
    }
    public override var postalAddresses: [CNLabeledValue<CNPostalAddress>] {
        get { super.postalAddresses }
        set { storage.postalAddresses = newValue }
    }
    public override var dates: [CNLabeledValue<NSDateComponents>] {
        get { super.dates }
        set { storage.dates = newValue }
    }
    public override var urlAddresses: [CNLabeledValue<NSString>] {
        get { super.urlAddresses }
        set { storage.urlAddresses = newValue }
    }
    public override var contactRelations: [CNLabeledValue<CNContactRelation>] {
        get { super.contactRelations }
        set { storage.contactRelations = newValue }
    }
    public override var socialProfiles: [CNLabeledValue<CNSocialProfile>] {
        get { super.socialProfiles }
        set { storage.socialProfiles = newValue }
    }
    public override var instantMessageAddresses: [CNLabeledValue<CNInstantMessageAddress>] {
        get { super.instantMessageAddresses }
        set { storage.instantMessageAddresses = newValue }
    }
}
