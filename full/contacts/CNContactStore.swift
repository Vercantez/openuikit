import Foundation

enum CNStorePredicateKind: Equatable {
    case contactsWithIdentifiers([String])
    case contactsMatchingName(String)
    case contactsMatchingEmail(String)
    case contactsMatchingPhone(String)
    case contactsInContainer(String)
    case contactsInGroup(String)
    case groupsWithIdentifiers([String])
    case groupsInContainer(String)
    case containersWithIdentifiers([String])
    case containerOfContact(String)
    case containerOfGroup(String)
}

enum CNStorePredicate {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var table: [ObjectIdentifier: CNStorePredicateKind] = [:]

    static func make(_ kind: CNStorePredicateKind) -> NSPredicate {
        let predicate = NSPredicate { object, _ in
            CNStorePredicate.evaluate(kind, object)
        }
        lock.lock()
        table[ObjectIdentifier(predicate)] = kind
        lock.unlock()
        return predicate
    }

    static func kind(of predicate: NSPredicate?) -> CNStorePredicateKind? {
        guard let predicate else { return nil }
        lock.lock()
        defer { lock.unlock() }
        return table[ObjectIdentifier(predicate)]
    }

    static func evaluate(_ kind: CNStorePredicateKind, _ object: Any?) -> Bool {
        switch kind {
        case .contactsWithIdentifiers(let identifiers):
            return identifiers.contains((object as? CNContact)?.identifier ?? "")
        case .contactsMatchingName(let name):
            guard let contact = object as? CNContact else { return false }
            return contact.matchesName(name)
        case .contactsMatchingEmail(let email):
            guard let contact = object as? CNContact else { return false }
            return contact.emailAddresses.contains {
                ($0.value as String).caseInsensitiveCompare(email) == .orderedSame
            }
        case .contactsMatchingPhone(let phone):
            guard let contact = object as? CNContact else { return false }
            let digits = phone.filter(\.isNumber)
            return contact.phoneNumbers.contains { $0.value.digits() == digits && !digits.isEmpty }
        case .contactsInContainer, .contactsInGroup:
            return object is CNContact
        case .groupsWithIdentifiers(let identifiers):
            return identifiers.contains((object as? CNGroup)?.identifier ?? "")
        case .groupsInContainer:
            return object is CNGroup
        case .containersWithIdentifiers(let identifiers):
            return identifiers.contains((object as? CNContainer)?.identifier ?? "")
        case .containerOfContact, .containerOfGroup:
            return object is CNContainer
        }
    }
}

extension CNContact {
    func matchesName(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return false }
        let haystacks = [
            givenName, middleName, familyName, nickname, organizationName,
            namePrefix, nameSuffix, "\(givenName) \(familyName)", "\(familyName) \(givenName)",
        ]
        return haystacks.contains { $0.lowercased().contains(needle) }
    }
}

private enum CNMemoryStore {
    static let lock = NSLock()
    static let defaultContainer = CNContainer(
        identifier: "local-default-container",
        name: "On My Device",
        type: .local
    )

    nonisolated(unsafe) static var authorization: CNAuthorizationStatus = .notDetermined
    nonisolated(unsafe) static var contacts: [String: CNContactStorage] = [:]
    nonisolated(unsafe) static var groups: [String: (identifier: String, name: String)] = [:]
    nonisolated(unsafe) static var groupMembers: [String: Set<String>] = [:]
    nonisolated(unsafe) static var contactContainers: [String: String] = [:]
    nonisolated(unsafe) static var groupContainers: [String: String] = [:]
    nonisolated(unsafe) static var history: [CNChangeHistoryEvent] = []
    nonisolated(unsafe) static var historyCounter: UInt64 = 0

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        authorization = .notDetermined
        contacts = [:]
        groups = [:]
        groupMembers = [:]
        contactContainers = [:]
        groupContainers = [:]
        history = []
        historyCounter = 0
    }

    static func tokenData(_ value: UInt64) -> Data {
        withUnsafeBytes(of: value.bigEndian) { Data($0) }
    }
}

open class CNFetchRequest: NSObject {}

open class CNContactFetchRequest: CNFetchRequest, NSSecureCoding {
    public var keysToFetch: [any CNKeyDescriptor]
    public var mutableObjects = false
    public var unifyResults = true
    public var sortOrder: CNContactSortOrder = .none
    public var predicate: NSPredicate?

    public init(keysToFetch: [any CNKeyDescriptor]) {
        self.keysToFetch = keysToFetch
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        self.keysToFetch = (coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "keysToFetch") as? [String]) ?? []
        self.mutableObjects = coder.decodeBool(forKey: "mutableObjects")
        self.unifyResults = coder.decodeBool(forKey: "unifyResults")
        self.sortOrder = CNContactSortOrder(rawValue: coder.decodeInteger(forKey: "sortOrder")) ?? .none
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(CNFlattenKeyDescriptors(keysToFetch) as NSArray, forKey: "keysToFetch")
        coder.encode(mutableObjects, forKey: "mutableObjects")
        coder.encode(unifyResults, forKey: "unifyResults")
        coder.encode(sortOrder.rawValue, forKey: "sortOrder")
    }
}

open class CNFetchResult<ValueType: AnyObject>: NSObject {
    public let value: ValueType
    public let currentHistoryToken: Data

    public init(value: ValueType, currentHistoryToken: Data) {
        self.value = value
        self.currentHistoryToken = currentHistoryToken
        super.init()
    }
}

enum CNSaveOperation {
    case addContact(CNMutableContact, String?)
    case updateContact(CNMutableContact)
    case deleteContact(CNMutableContact)
    case addGroup(CNMutableGroup, String?)
    case updateGroup(CNMutableGroup)
    case deleteGroup(CNMutableGroup)
    case addMember(String, String)
    case removeMember(String, String)
}

open class CNSaveRequest: NSObject {
    var operations: [CNSaveOperation] = []
    public var shouldRefetchContacts = false
    public var transactionAuthor: String?

    public override init() {
        super.init()
    }

    open func add(_ contact: CNMutableContact, toContainerWithIdentifier identifier: String?) {
        operations.append(.addContact(contact, identifier))
    }

    open func update(_ contact: CNMutableContact) {
        operations.append(.updateContact(contact))
    }

    open func delete(_ contact: CNMutableContact) {
        operations.append(.deleteContact(contact))
    }

    open func add(_ group: CNMutableGroup, toContainerWithIdentifier identifier: String?) {
        operations.append(.addGroup(group, identifier))
    }

    open func update(_ group: CNMutableGroup) {
        operations.append(.updateGroup(group))
    }

    open func delete(_ group: CNMutableGroup) {
        operations.append(.deleteGroup(group))
    }

    open func addMember(_ contact: CNContact, to group: CNGroup) {
        operations.append(.addMember(contact.identifier, group.identifier))
    }

    open func removeMember(_ contact: CNContact, from group: CNGroup) {
        operations.append(.removeMember(contact.identifier, group.identifier))
    }
}

open class CNContactStore: NSObject {
    public override init() {
        super.init()
    }

    open class func authorizationStatus(for entityType: CNEntityType) -> CNAuthorizationStatus {
        _ = entityType
        CNMemoryStore.lock.lock()
        defer { CNMemoryStore.lock.unlock() }
        return CNMemoryStore.authorization
    }

    /// Grants access to the process-local in-memory store only. This is not an
    /// Apple TCC prompt and does not unlock a host AddressBook.
    open func requestAccess(for entityType: CNEntityType) async throws -> Bool {
        try requestAccessBlocking(for: entityType)
    }

    open func requestAccess(
        for entityType: CNEntityType,
        completionHandler: @escaping (Bool, Error?) -> Void
    ) {
        do {
            completionHandler(try requestAccessBlocking(for: entityType), nil)
        } catch {
            completionHandler(false, error)
        }
    }

    private func requestAccessBlocking(for entityType: CNEntityType) throws -> Bool {
        guard entityType == .contacts else {
            throw CNError(.featureNotAvailable)
        }
        CNMemoryStore.lock.lock()
        if CNMemoryStore.authorization == .notDetermined {
            CNMemoryStore.authorization = .authorized
        }
        let authorized = CNMemoryStore.authorization == .authorized
            || CNMemoryStore.authorization == .limited
        CNMemoryStore.lock.unlock()
        return authorized
    }

    public var currentHistoryToken: Data? {
        CNMemoryStore.lock.lock()
        defer { CNMemoryStore.lock.unlock() }
        guard CNMemoryStore.historyCounter > 0 else { return nil }
        return CNMemoryStore.tokenData(CNMemoryStore.historyCounter)
    }

    open func defaultContainerIdentifier() -> String {
        CNMemoryStore.defaultContainer.identifier
    }

    open func unifiedContact(
        withIdentifier identifier: String,
        keysToFetch keys: [any CNKeyDescriptor]
    ) throws -> CNContact {
        try requireAccess()
        CNMemoryStore.lock.lock()
        defer { CNMemoryStore.lock.unlock() }
        guard let storage = CNMemoryStore.contacts[identifier] else {
            throw CNError(
                .recordDoesNotExist,
                userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: [identifier]]
            )
        }
        return CNContact(storage: storage.projected(keys: CNFlattenKeyDescriptors(keys)))
    }

    open func unifiedContacts(
        matching predicate: NSPredicate,
        keysToFetch keys: [any CNKeyDescriptor]
    ) throws -> [CNContact] {
        try requireAccess()
        return try contacts(matching: predicate, keys: keys, mutable: false, sort: .none)
    }

    open func enumerateContacts(
        with fetchRequest: CNContactFetchRequest,
        usingBlock block: (CNContact, UnsafeMutablePointer<ObjCBool>) -> Void
    ) throws {
        try requireAccess()
        let contacts = try contacts(
            matching: fetchRequest.predicate,
            keys: fetchRequest.keysToFetch,
            mutable: fetchRequest.mutableObjects,
            sort: fetchRequest.sortOrder
        )
        var stop = ObjCBool(false)
        withUnsafeMutablePointer(to: &stop) { pointer in
            for contact in contacts {
                block(contact, pointer)
                if pointer.pointee.boolValue { break }
            }
        }
    }

    open func groups(matching predicate: NSPredicate?) throws -> [CNGroup] {
        try requireAccess()
        CNMemoryStore.lock.lock()
        defer { CNMemoryStore.lock.unlock() }
        var result: [CNGroup] = CNMemoryStore.groups.values.map {
            CNGroup(identifier: $0.identifier, name: $0.name)
        }
        if let predicate {
            result = filterGroups(result, predicate: predicate)
        }
        return result
    }

    open func containers(matching predicate: NSPredicate?) throws -> [CNContainer] {
        try requireAccess()
        CNMemoryStore.lock.lock()
        defer { CNMemoryStore.lock.unlock() }
        var result = [CNMemoryStore.defaultContainer]
        if let predicate {
            result = filterContainers(result, predicate: predicate)
        }
        return result
    }

    open func execute(_ saveRequest: CNSaveRequest) throws {
        try requireAccess()
        CNMemoryStore.lock.lock()
        defer { CNMemoryStore.lock.unlock() }
        for operation in saveRequest.operations {
            try applyLocked(operation)
        }
        NotificationCenter.default.post(name: .CNContactStoreDidChange, object: self)
    }

    @_spi(OpenUIKitHost)
    public static func _resetPortableStore() {
        CNMemoryStore.reset()
    }

    @_spi(OpenUIKitHost)
    public static func _setPortableAuthorization(_ status: CNAuthorizationStatus) {
        CNMemoryStore.lock.lock()
        CNMemoryStore.authorization = status
        CNMemoryStore.lock.unlock()
    }

    @_spi(OpenUIKitHost)
    public func _portableChangeHistory() -> [CNChangeHistoryEvent] {
        CNMemoryStore.lock.lock()
        defer { CNMemoryStore.lock.unlock() }
        return CNMemoryStore.history
    }

    private func requireAccess() throws {
        CNMemoryStore.lock.lock()
        let status = CNMemoryStore.authorization
        CNMemoryStore.lock.unlock()
        switch status {
        case .authorized, .limited:
            return
        case .notDetermined, .denied, .restricted:
            throw CNError(.authorizationDenied)
        }
    }

    private func contacts(
        matching predicate: NSPredicate?,
        keys: [any CNKeyDescriptor],
        mutable: Bool,
        sort: CNContactSortOrder
    ) throws -> [CNContact] {
        CNMemoryStore.lock.lock()
        var storages = Array(CNMemoryStore.contacts.values)
        let kind = CNStorePredicate.kind(of: predicate)
        switch kind {
        case .contactsWithIdentifiers(let identifiers):
            storages = storages.filter { identifiers.contains($0.identifier) }
        case .contactsMatchingName(let name):
            storages = storages.filter { CNContact(storage: $0).matchesName(name) }
        case .contactsMatchingEmail(let email):
            storages = storages.filter { storage in
                storage.emailAddresses.contains {
                    ($0.value as String).caseInsensitiveCompare(email) == .orderedSame
                }
            }
        case .contactsMatchingPhone(let phone):
            let digits = phone.filter(\.isNumber)
            storages = storages.filter { storage in
                storage.phoneNumbers.contains { $0.value.digits() == digits && !digits.isEmpty }
            }
        case .contactsInContainer(let container):
            storages = storages.filter {
                CNMemoryStore.contactContainers[$0.identifier] == container
            }
        case .contactsInGroup(let group):
            let members = CNMemoryStore.groupMembers[group] ?? []
            storages = storages.filter { members.contains($0.identifier) }
        case .none:
            if let predicate {
                storages = storages.filter { predicate.evaluate(with: CNContact(storage: $0)) }
            }
        default:
            throw CNError(.predicateInvalid)
        }
        CNMemoryStore.lock.unlock()

        let projected = storages.map { $0.projected(keys: CNFlattenKeyDescriptors(keys)) }
        var result: [CNContact] = projected.map { storage in
            mutable ? CNMutableContact(storage: storage) : CNContact(storage: storage)
        }
        if sort != .none {
            let comparator = CNContact.comparator(forNameSortOrder: sort)
            result.sort { comparator($0, $1) == .orderedAscending }
        }
        return result
    }

    private func filterGroups(_ groups: [CNGroup], predicate: NSPredicate) -> [CNGroup] {
        switch CNStorePredicate.kind(of: predicate) {
        case .groupsWithIdentifiers(let identifiers):
            return groups.filter { identifiers.contains($0.identifier) }
        case .groupsInContainer(let container):
            return groups.filter { CNMemoryStore.groupContainers[$0.identifier] == container }
        default:
            return groups.filter { predicate.evaluate(with: $0) }
        }
    }

    private func filterContainers(_ containers: [CNContainer], predicate: NSPredicate) -> [CNContainer] {
        switch CNStorePredicate.kind(of: predicate) {
        case .containersWithIdentifiers(let identifiers):
            return containers.filter { identifiers.contains($0.identifier) }
        case .containerOfContact(let identifier):
            let containerID = CNMemoryStore.contactContainers[identifier]
            return containers.filter { $0.identifier == containerID }
        case .containerOfGroup(let identifier):
            let containerID = CNMemoryStore.groupContainers[identifier]
            return containers.filter { $0.identifier == containerID }
        default:
            return containers.filter { predicate.evaluate(with: $0) }
        }
    }

    private func applyLocked(_ operation: CNSaveOperation) throws {
        let containerID = CNMemoryStore.defaultContainer.identifier
        switch operation {
        case .addContact(let contact, let container):
            var storage = contact.storage
            if CNMemoryStore.contacts[storage.identifier] != nil {
                throw CNError(
                    .insertedRecordAlreadyExists,
                    userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: [storage.identifier]]
                )
            }
            storage.availableKeys = Set(CNAllContactPropertyKeys())
            CNMemoryStore.contacts[storage.identifier] = storage
            CNMemoryStore.contactContainers[storage.identifier] = container ?? containerID
            appendHistory(
                CNChangeHistoryAddContactEvent(
                    contact: CNContact(storage: storage),
                    containerIdentifier: container ?? containerID
                )
            )
        case .updateContact(let contact):
            guard CNMemoryStore.contacts[contact.identifier] != nil else {
                throw CNError(
                    .recordDoesNotExist,
                    userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: [contact.identifier]]
                )
            }
            var storage = contact.storage
            storage.availableKeys = Set(CNAllContactPropertyKeys())
            CNMemoryStore.contacts[contact.identifier] = storage
            appendHistory(CNChangeHistoryUpdateContactEvent(contact: CNContact(storage: storage)))
        case .deleteContact(let contact):
            guard CNMemoryStore.contacts.removeValue(forKey: contact.identifier) != nil else {
                throw CNError(
                    .recordDoesNotExist,
                    userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: [contact.identifier]]
                )
            }
            CNMemoryStore.contactContainers.removeValue(forKey: contact.identifier)
            for key in CNMemoryStore.groupMembers.keys {
                CNMemoryStore.groupMembers[key]?.remove(contact.identifier)
            }
            appendHistory(CNChangeHistoryDeleteContactEvent(contactIdentifier: contact.identifier))
        case .addGroup(let group, let container):
            if CNMemoryStore.groups[group.identifier] != nil {
                throw CNError(.insertedRecordAlreadyExists)
            }
            CNMemoryStore.groups[group.identifier] = (group.identifier, group.name)
            CNMemoryStore.groupContainers[group.identifier] = container ?? containerID
            CNMemoryStore.groupMembers[group.identifier] = []
            appendHistory(
                CNChangeHistoryAddGroupEvent(
                    group: CNGroup(identifier: group.identifier, name: group.name),
                    containerIdentifier: container ?? containerID
                )
            )
        case .updateGroup(let group):
            guard CNMemoryStore.groups[group.identifier] != nil else {
                throw CNError(.recordDoesNotExist)
            }
            CNMemoryStore.groups[group.identifier] = (group.identifier, group.name)
            appendHistory(
                CNChangeHistoryUpdateGroupEvent(
                    group: CNGroup(identifier: group.identifier, name: group.name)
                )
            )
        case .deleteGroup(let group):
            guard CNMemoryStore.groups.removeValue(forKey: group.identifier) != nil else {
                throw CNError(.recordDoesNotExist)
            }
            CNMemoryStore.groupMembers.removeValue(forKey: group.identifier)
            CNMemoryStore.groupContainers.removeValue(forKey: group.identifier)
            appendHistory(CNChangeHistoryDeleteGroupEvent(groupIdentifier: group.identifier))
        case .addMember(let contactID, let groupID):
            guard CNMemoryStore.contacts[contactID] != nil else {
                throw CNError(.recordDoesNotExist)
            }
            guard CNMemoryStore.groups[groupID] != nil else {
                throw CNError(.parentRecordDoesNotExist)
            }
            CNMemoryStore.groupMembers[groupID, default: []].insert(contactID)
            let group = CNMemoryStore.groups[groupID]!
            appendHistory(
                CNChangeHistoryAddMemberToGroupEvent(
                    member: CNContact(storage: CNMemoryStore.contacts[contactID]!),
                    group: CNGroup(identifier: group.identifier, name: group.name)
                )
            )
        case .removeMember(let contactID, let groupID):
            CNMemoryStore.groupMembers[groupID]?.remove(contactID)
            if let group = CNMemoryStore.groups[groupID], let storage = CNMemoryStore.contacts[contactID] {
                appendHistory(
                    CNChangeHistoryRemoveMemberFromGroupEvent(
                        member: CNContact(storage: storage),
                        group: CNGroup(identifier: group.identifier, name: group.name)
                    )
                )
            }
        }
    }

    private func appendHistory(_ event: CNChangeHistoryEvent) {
        CNMemoryStore.history.append(event)
        CNMemoryStore.historyCounter += 1
    }
}
