import Foundation

/// Documented Linux contact directory. This is **not** a system address book.
///
/// Override with `OPENUIKIT_CONTACTS_DIRECTORY`. The default path is
/// `$HOME/.local/share/openuikit/contacts/`. The store file is `store.json`.
enum CNPortableStoreDirectory {
    static let environmentKey = "OPENUIKIT_CONTACTS_DIRECTORY"
    static let defaultRelativePath = ".local/share/openuikit/contacts"

    static func url() -> URL {
        if let override = ProcessInfo.processInfo.environment[environmentKey], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(defaultRelativePath, isDirectory: true)
    }

    static func storeFile() -> URL {
        url().appendingPathComponent("store.json")
    }
}

struct CNPersistedLabeledString: Codable {
    var identifier: String
    var label: String?
    var value: String
}

struct CNPersistedPostal: Codable {
    var identifier: String
    var label: String?
    var street: String
    var subLocality: String
    var city: String
    var subAdministrativeArea: String
    var state: String
    var postalCode: String
    var country: String
    var isoCountryCode: String
}

struct CNPersistedSocial: Codable {
    var identifier: String
    var label: String?
    var urlString: String
    var username: String
    var userIdentifier: String
    var service: String
}

struct CNPersistedIM: Codable {
    var identifier: String
    var label: String?
    var username: String
    var service: String
}

struct CNPersistedDate: Codable {
    var identifier: String
    var label: String?
    var year: Int?
    var month: Int?
    var day: Int?
}

struct CNPersistedPhone: Codable {
    var identifier: String
    var label: String?
    var stringValue: String
    var initialCountryCode: String
}

struct CNPersistedContact: Codable {
    var identifier: String
    var uuid: String
    var contactType: Int
    var namePrefix: String
    var givenName: String
    var middleName: String
    var familyName: String
    var previousFamilyName: String
    var nameSuffix: String
    var nickname: String
    var organizationName: String
    var departmentName: String
    var jobTitle: String
    var phoneticGivenName: String
    var phoneticMiddleName: String
    var phoneticFamilyName: String
    var phoneticOrganizationName: String
    var birthday: CNPersistedDate?
    var nonGregorianBirthday: CNPersistedDate?
    var note: String
    var imageDataBase64: String?
    var thumbnailImageDataBase64: String?
    var imagePresent: Bool
    var phoneNumbers: [CNPersistedPhone]
    var emailAddresses: [CNPersistedLabeledString]
    var postalAddresses: [CNPersistedPostal]
    var dates: [CNPersistedDate]
    var urlAddresses: [CNPersistedLabeledString]
    var contactRelations: [CNPersistedLabeledString]
    var socialProfiles: [CNPersistedSocial]
    var instantMessageAddresses: [CNPersistedIM]
    var unifiedIdentifiers: [String]
}

struct CNPersistedGroup: Codable {
    var identifier: String
    var name: String
}

struct CNPersistedHistory: Codable {
    var kind: String
    var contactIdentifier: String?
    var groupIdentifier: String?
    var groupName: String?
    var containerIdentifier: String?
}

struct CNPersistedSnapshot: Codable {
    var version: Int
    var authorization: Int
    var requestDecision: Int
    var historyCounter: UInt64
    var contacts: [CNPersistedContact]
    var groups: [CNPersistedGroup]
    var groupMembers: [String: [String]]
    var contactContainers: [String: String]
    var groupContainers: [String: String]
    var history: [CNPersistedHistory]
}

enum CNPersistentCodec {
    static func encode(_ snapshot: CNMemoryStore.Snapshot) throws -> Data {
        let payload = CNPersistedSnapshot(
            version: 1,
            authorization: snapshot.authorization.rawValue,
            requestDecision: snapshot.requestDecision.rawValue,
            historyCounter: snapshot.historyCounter,
            contacts: snapshot.contacts.values.map(persist(contact:)),
            groups: snapshot.groups.values.map { CNPersistedGroup(identifier: $0.identifier, name: $0.name) },
            groupMembers: snapshot.groupMembers.mapValues { Array($0) },
            contactContainers: snapshot.contactContainers,
            groupContainers: snapshot.groupContainers,
            history: snapshot.history.map(persist(event:))
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(payload)
    }

    static func decode(_ data: Data) throws -> CNMemoryStore.Snapshot {
        let payload = try JSONDecoder().decode(CNPersistedSnapshot.self, from: data)
        var snapshot = CNMemoryStore.Snapshot()
        snapshot.authorization = CNAuthorizationStatus(rawValue: payload.authorization) ?? .notDetermined
        snapshot.requestDecision = CNAuthorizationStatus(rawValue: payload.requestDecision) ?? .authorized
        snapshot.historyCounter = payload.historyCounter
        for persisted in payload.contacts {
            let storage = inflate(contact: persisted)
            snapshot.contacts[storage.identifier] = storage
        }
        for group in payload.groups {
            snapshot.groups[group.identifier] = (group.identifier, group.name)
        }
        snapshot.groupMembers = payload.groupMembers.mapValues { Set($0) }
        snapshot.contactContainers = payload.contactContainers
        snapshot.groupContainers = payload.groupContainers
        snapshot.history = payload.history.map { inflate(event: $0, snapshot: snapshot) }
        return snapshot
    }

    private static func persist(components: DateComponents?, identifier: String = "", label: String? = nil) -> CNPersistedDate? {
        guard let components else { return nil }
        return CNPersistedDate(
            identifier: identifier,
            label: label,
            year: components.year,
            month: components.month,
            day: components.day
        )
    }

    private static func inflateDate(_ persisted: CNPersistedDate?) -> DateComponents? {
        guard let persisted else { return nil }
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.year = persisted.year
        components.month = persisted.month
        components.day = persisted.day
        return components
    }

    private static func persist(contact storage: CNContactStorage) -> CNPersistedContact {
        CNPersistedContact(
            identifier: storage.identifier,
            uuid: storage.uuid.uuidString,
            contactType: storage.contactType.rawValue,
            namePrefix: storage.namePrefix,
            givenName: storage.givenName,
            middleName: storage.middleName,
            familyName: storage.familyName,
            previousFamilyName: storage.previousFamilyName,
            nameSuffix: storage.nameSuffix,
            nickname: storage.nickname,
            organizationName: storage.organizationName,
            departmentName: storage.departmentName,
            jobTitle: storage.jobTitle,
            phoneticGivenName: storage.phoneticGivenName,
            phoneticMiddleName: storage.phoneticMiddleName,
            phoneticFamilyName: storage.phoneticFamilyName,
            phoneticOrganizationName: storage.phoneticOrganizationName,
            birthday: persist(components: storage.birthday),
            nonGregorianBirthday: persist(components: storage.nonGregorianBirthday),
            note: storage.note,
            imageDataBase64: storage.imageData?.base64EncodedString(),
            thumbnailImageDataBase64: storage.thumbnailImageData?.base64EncodedString(),
            imagePresent: storage.imagePresent,
            phoneNumbers: storage.phoneNumbers.map {
                CNPersistedPhone(
                    identifier: $0.identifier,
                    label: $0.label,
                    stringValue: $0.value.stringValue,
                    initialCountryCode: $0.value.initialCountryCode
                )
            },
            emailAddresses: storage.emailAddresses.map {
                CNPersistedLabeledString(identifier: $0.identifier, label: $0.label, value: $0.value as String)
            },
            postalAddresses: storage.postalAddresses.map {
                CNPersistedPostal(
                    identifier: $0.identifier,
                    label: $0.label,
                    street: $0.value.street,
                    subLocality: $0.value.subLocality,
                    city: $0.value.city,
                    subAdministrativeArea: $0.value.subAdministrativeArea,
                    state: $0.value.state,
                    postalCode: $0.value.postalCode,
                    country: $0.value.country,
                    isoCountryCode: $0.value.isoCountryCode
                )
            },
            dates: storage.dates.map {
                CNPersistedDate(
                    identifier: $0.identifier,
                    label: $0.label,
                    year: $0.value.year,
                    month: $0.value.month,
                    day: $0.value.day
                )
            },
            urlAddresses: storage.urlAddresses.map {
                CNPersistedLabeledString(identifier: $0.identifier, label: $0.label, value: $0.value as String)
            },
            contactRelations: storage.contactRelations.map {
                CNPersistedLabeledString(identifier: $0.identifier, label: $0.label, value: $0.value.name)
            },
            socialProfiles: storage.socialProfiles.map {
                CNPersistedSocial(
                    identifier: $0.identifier,
                    label: $0.label,
                    urlString: $0.value.urlString,
                    username: $0.value.username,
                    userIdentifier: $0.value.userIdentifier,
                    service: $0.value.service
                )
            },
            instantMessageAddresses: storage.instantMessageAddresses.map {
                CNPersistedIM(
                    identifier: $0.identifier,
                    label: $0.label,
                    username: $0.value.username,
                    service: $0.value.service
                )
            },
            unifiedIdentifiers: Array(storage.unifiedIdentifiers)
        )
    }

    private static func inflate(contact persisted: CNPersistedContact) -> CNContactStorage {
        var storage = CNContactStorage(
            identifier: persisted.identifier,
            uuid: UUID(uuidString: persisted.uuid) ?? UUID()
        )
        storage.contactType = CNContactType(rawValue: persisted.contactType) ?? .person
        storage.namePrefix = persisted.namePrefix
        storage.givenName = persisted.givenName
        storage.middleName = persisted.middleName
        storage.familyName = persisted.familyName
        storage.previousFamilyName = persisted.previousFamilyName
        storage.nameSuffix = persisted.nameSuffix
        storage.nickname = persisted.nickname
        storage.organizationName = persisted.organizationName
        storage.departmentName = persisted.departmentName
        storage.jobTitle = persisted.jobTitle
        storage.phoneticGivenName = persisted.phoneticGivenName
        storage.phoneticMiddleName = persisted.phoneticMiddleName
        storage.phoneticFamilyName = persisted.phoneticFamilyName
        storage.phoneticOrganizationName = persisted.phoneticOrganizationName
        storage.birthday = inflateDate(persisted.birthday)
        storage.nonGregorianBirthday = inflateDate(persisted.nonGregorianBirthday)
        storage.note = persisted.note
        storage.imageData = persisted.imageDataBase64.flatMap { Data(base64Encoded: $0) }
        storage.thumbnailImageData = persisted.thumbnailImageDataBase64.flatMap { Data(base64Encoded: $0) }
        storage.imagePresent = persisted.imagePresent || storage.imageData != nil
        storage.phoneNumbers = persisted.phoneNumbers.map {
            CNLabeledValue(
                identifier: $0.identifier,
                label: $0.label,
                value: CNPhoneNumber(stringValue: $0.stringValue, countryCode: $0.initialCountryCode)
            )
        }
        storage.emailAddresses = persisted.emailAddresses.map {
            CNLabeledValue(identifier: $0.identifier, label: $0.label, value: $0.value as NSString)
        }
        storage.postalAddresses = persisted.postalAddresses.map {
            var address = CNPostalAddressStorage()
            address.street = $0.street
            address.subLocality = $0.subLocality
            address.city = $0.city
            address.subAdministrativeArea = $0.subAdministrativeArea
            address.state = $0.state
            address.postalCode = $0.postalCode
            address.country = $0.country
            address.isoCountryCode = $0.isoCountryCode
            return CNLabeledValue(
                identifier: $0.identifier,
                label: $0.label,
                value: CNPostalAddress(storage: address)
            )
        }
        storage.dates = persisted.dates.map {
            let components = NSDateComponents()
            if let year = $0.year { components.year = year }
            if let month = $0.month { components.month = month }
            if let day = $0.day { components.day = day }
            return CNLabeledValue(identifier: $0.identifier, label: $0.label, value: components)
        }
        storage.urlAddresses = persisted.urlAddresses.map {
            CNLabeledValue(identifier: $0.identifier, label: $0.label, value: $0.value as NSString)
        }
        storage.contactRelations = persisted.contactRelations.map {
            CNLabeledValue(
                identifier: $0.identifier,
                label: $0.label,
                value: CNContactRelation(name: $0.value)
            )
        }
        storage.socialProfiles = persisted.socialProfiles.map {
            CNLabeledValue(
                identifier: $0.identifier,
                label: $0.label,
                value: CNSocialProfile(
                    urlString: $0.urlString,
                    username: $0.username,
                    userIdentifier: $0.userIdentifier,
                    service: $0.service
                )
            )
        }
        storage.instantMessageAddresses = persisted.instantMessageAddresses.map {
            CNLabeledValue(
                identifier: $0.identifier,
                label: $0.label,
                value: CNInstantMessageAddress(username: $0.username, service: $0.service)
            )
        }
        storage.unifiedIdentifiers = Set(persisted.unifiedIdentifiers)
        storage.availableKeys = Set(CNAllContactPropertyKeys())
        return storage
    }

    private static func persist(event: CNChangeHistoryEvent) -> CNPersistedHistory {
        switch event {
        case let add as CNChangeHistoryAddContactEvent:
            return CNPersistedHistory(
                kind: "addContact",
                contactIdentifier: add.contact.identifier,
                groupIdentifier: nil,
                groupName: nil,
                containerIdentifier: add.containerIdentifier
            )
        case let update as CNChangeHistoryUpdateContactEvent:
            return CNPersistedHistory(
                kind: "updateContact",
                contactIdentifier: update.contact.identifier,
                groupIdentifier: nil,
                groupName: nil,
                containerIdentifier: nil
            )
        case let delete as CNChangeHistoryDeleteContactEvent:
            return CNPersistedHistory(
                kind: "deleteContact",
                contactIdentifier: delete.contactIdentifier,
                groupIdentifier: nil,
                groupName: nil,
                containerIdentifier: nil
            )
        case let add as CNChangeHistoryAddGroupEvent:
            return CNPersistedHistory(
                kind: "addGroup",
                contactIdentifier: nil,
                groupIdentifier: add.group.identifier,
                groupName: add.group.name,
                containerIdentifier: add.containerIdentifier
            )
        case let update as CNChangeHistoryUpdateGroupEvent:
            return CNPersistedHistory(
                kind: "updateGroup",
                contactIdentifier: nil,
                groupIdentifier: update.group.identifier,
                groupName: update.group.name,
                containerIdentifier: nil
            )
        case let delete as CNChangeHistoryDeleteGroupEvent:
            return CNPersistedHistory(
                kind: "deleteGroup",
                contactIdentifier: nil,
                groupIdentifier: delete.groupIdentifier,
                groupName: nil,
                containerIdentifier: nil
            )
        case let add as CNChangeHistoryAddMemberToGroupEvent:
            return CNPersistedHistory(
                kind: "addMember",
                contactIdentifier: add.member.identifier,
                groupIdentifier: add.group.identifier,
                groupName: add.group.name,
                containerIdentifier: nil
            )
        case let remove as CNChangeHistoryRemoveMemberFromGroupEvent:
            return CNPersistedHistory(
                kind: "removeMember",
                contactIdentifier: remove.member.identifier,
                groupIdentifier: remove.group.identifier,
                groupName: remove.group.name,
                containerIdentifier: nil
            )
        default:
            return CNPersistedHistory(
                kind: "dropEverything",
                contactIdentifier: nil,
                groupIdentifier: nil,
                groupName: nil,
                containerIdentifier: nil
            )
        }
    }

    private static func inflate(event persisted: CNPersistedHistory, snapshot: CNMemoryStore.Snapshot) -> CNChangeHistoryEvent {
        let contact: CNContact = {
            if let identifier = persisted.contactIdentifier, let storage = snapshot.contacts[identifier] {
                return CNContact(storage: storage)
            }
            var storage = CNContactStorage.makeNew()
            if let identifier = persisted.contactIdentifier {
                storage.identifier = identifier
            }
            return CNContact(storage: storage)
        }()
        let group = CNGroup(
            identifier: persisted.groupIdentifier ?? UUID().uuidString,
            name: persisted.groupName ?? ""
        )
        switch persisted.kind {
        case "addContact":
            return CNChangeHistoryAddContactEvent(contact: contact, containerIdentifier: persisted.containerIdentifier)
        case "updateContact":
            return CNChangeHistoryUpdateContactEvent(contact: contact)
        case "deleteContact":
            return CNChangeHistoryDeleteContactEvent(contactIdentifier: persisted.contactIdentifier ?? "")
        case "addGroup":
            return CNChangeHistoryAddGroupEvent(
                group: group,
                containerIdentifier: persisted.containerIdentifier ?? CNMemoryStore.defaultContainer.identifier
            )
        case "updateGroup":
            return CNChangeHistoryUpdateGroupEvent(group: group)
        case "deleteGroup":
            return CNChangeHistoryDeleteGroupEvent(groupIdentifier: persisted.groupIdentifier ?? "")
        case "addMember":
            return CNChangeHistoryAddMemberToGroupEvent(member: contact, group: group)
        case "removeMember":
            return CNChangeHistoryRemoveMemberFromGroupEvent(member: contact, group: group)
        default:
            return CNChangeHistoryDropEverythingEvent()
        }
    }
}
