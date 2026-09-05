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

/// Lifetime-safe tagged `NSPredicate` subclass. The kind lives on the object,
/// so it cannot leak a global table or be confused with a later object that
/// reused an `ObjectIdentifier`.
final class CNContactsStorePredicate: NSPredicate {
    let kind: CNStorePredicateKind

    init(kind: CNStorePredicateKind) {
        self.kind = kind
        super.init { object, _ in
            CNStorePredicate.evaluate(kind, object)
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }
}

enum CNStorePredicate {
    static func make(_ kind: CNStorePredicateKind) -> NSPredicate {
        CNContactsStorePredicate(kind: kind)
    }

    static func kind(of predicate: NSPredicate?) -> CNStorePredicateKind? {
        (predicate as? CNContactsStorePredicate)?.kind
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

enum CNMemoryStore {
    static let lock = NSLock()
    static let defaultContainer = CNContainer(
        identifier: "local-default-container",
        name: "On My Device",
        type: .local
    )

    struct Snapshot {
        var authorization: CNAuthorizationStatus = .notDetermined
        var requestDecision: CNAuthorizationStatus = .authorized
        var contacts: [String: CNContactStorage] = [:]
        var groups: [String: (identifier: String, name: String)] = [:]
        var groupMembers: [String: Set<String>] = [:]
        var contactContainers: [String: String] = [:]
        var groupContainers: [String: String] = [:]
        var history: [CNChangeHistoryEvent] = []
        var historyCounter: UInt64 = 0
    }

    nonisolated(unsafe) static var state = Snapshot()
    nonisolated(unsafe) static var loaded = false

    static var authorization: CNAuthorizationStatus {
        get { state.authorization }
        set { state.authorization = newValue }
    }
    static var contacts: [String: CNContactStorage] {
        get { state.contacts }
        set { state.contacts = newValue }
    }
    static var history: [CNChangeHistoryEvent] {
        get { state.history }
        set { state.history = newValue }
    }
    static var historyCounter: UInt64 {
        get { state.historyCounter }
        set { state.historyCounter = newValue }
    }

    static func ensureLoaded() {
        if loaded { return }
        loaded = true
        let url = CNPortableStoreDirectory.storeFile()
        guard let data = try? Data(contentsOf: url),
              let decoded = try? CNPersistentCodec.decode(data)
        else { return }
        state = decoded
    }

    static func persistLocked() {
        let directory = CNPortableStoreDirectory.url()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard let data = try? CNPersistentCodec.encode(state) else { return }
        try? data.write(to: CNPortableStoreDirectory.storeFile(), options: .atomic)
    }

    static func capture() -> Snapshot {
        ensureLoaded()
        return state
    }

    static func install(_ snapshot: Snapshot) {
        state = snapshot
        persistLocked()
    }

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        state = Snapshot()
        loaded = true
        persistLocked()
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
        let names = (coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "keysToFetch") as? [String]) ?? []
        self.keysToFetch = names.map { $0 as NSString }
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
        CNMemoryStore.ensureLoaded()
        return CNMemoryStore.authorization
    }

    /// Grants access to the documented local directory store only. This is not
    /// an Apple TCC prompt and does not unlock a host AddressBook.
    ///
    /// Status starts `.notDetermined`. `requestAccess(for:)` moves it to
    /// `.authorized` unless the documented test hook
    /// `_setPortableAuthorizationDecision(.denied)` (or a persisted denied
    /// status) selected `.denied`.
    ///
    /// The completion handler is invoked on a detached thread after this
    /// method returns, matching Darwin's non-reentrant "arbitrary queue"
    /// contract rather than calling back on the same stack.
    open func requestAccess(for entityType: CNEntityType) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            requestAccess(for: entityType) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    open func requestAccess(
        for entityType: CNEntityType,
        completionHandler: @escaping (Bool, Error?) -> Void
    ) {
        let outcome: Result<Bool, Error>
        do {
            outcome = .success(try requestAccessBlocking(for: entityType))
        } catch {
            outcome = .failure(error)
        }
        // Invoke off the calling stack so the completion cannot re-enter
        // `requestAccess` on the same thread. Darwin delivers this on an
        // arbitrary queue; Linux uses a detached thread for the same
        // non-reentrancy contract.
        Thread.detachNewThread {
            switch outcome {
            case .success(let granted):
                completionHandler(granted, nil)
            case .failure(let error):
                completionHandler(false, error)
            }
        }
    }

    private func requestAccessBlocking(for entityType: CNEntityType) throws -> Bool {
        guard entityType == .contacts else {
            throw CNError(.featureNotAvailable)
        }
        CNMemoryStore.lock.lock()
        CNMemoryStore.ensureLoaded()
        if CNMemoryStore.authorization == .notDetermined {
            let decision = CNMemoryStore.state.requestDecision
            switch decision {
            case .denied, .restricted:
                CNMemoryStore.authorization = .denied
            case .limited:
                CNMemoryStore.authorization = .limited
            case .authorized, .notDetermined:
                CNMemoryStore.authorization = .authorized
            }
            CNMemoryStore.persistLocked()
        }
        let authorized = CNMemoryStore.authorization == .authorized
            || CNMemoryStore.authorization == .limited
        CNMemoryStore.lock.unlock()
        return authorized
    }

    public var currentHistoryToken: Data? {
        CNMemoryStore.lock.lock()
        defer { CNMemoryStore.lock.unlock() }
        CNMemoryStore.ensureLoaded()
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
        return try contacts(matching: predicate, keys: keys, mutable: false, sort: .none, unifyResults: true)
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
            sort: fetchRequest.sortOrder,
            unifyResults: fetchRequest.unifyResults
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
        let snapshot = CNMemoryStore.capture()
        CNMemoryStore.lock.unlock()
        var result: [CNGroup] = snapshot.groups.values.map {
            CNGroup(identifier: $0.identifier, name: $0.name)
        }
        if let predicate {
            result = filterGroups(result, predicate: predicate, snapshot: snapshot)
        }
        return result
    }

    open func containers(matching predicate: NSPredicate?) throws -> [CNContainer] {
        try requireAccess()
        CNMemoryStore.lock.lock()
        let snapshot = CNMemoryStore.capture()
        CNMemoryStore.lock.unlock()
        var result = [CNMemoryStore.defaultContainer]
        if let predicate {
            result = filterContainers(result, predicate: predicate, snapshot: snapshot)
        }
        return result
    }

    open func execute(_ saveRequest: CNSaveRequest) throws {
        try requireAccess()
        var commitError: Error?
        CNMemoryStore.lock.lock()
        let prior = CNMemoryStore.capture()
        var working = prior
        do {
            for operation in saveRequest.operations {
                try apply(operation, to: &working)
            }
            CNMemoryStore.install(working)
        } catch {
            CNMemoryStore.install(prior)
            commitError = error
        }
        CNMemoryStore.lock.unlock()
        if let commitError {
            throw commitError
        }
        NotificationCenter.default.post(name: .CNContactStoreDidChange, object: self)
    }

    @_spi(OpenUIKitHost)
    public static func _resetPortableStore() {
        CNMemoryStore.reset()
    }

    @_spi(OpenUIKitHost)
    public static func _portableStoreDirectory() -> URL {
        CNPortableStoreDirectory.url()
    }

    @_spi(OpenUIKitHost)
    public static func _reloadPortableStoreFromDisk() {
        CNMemoryStore.lock.lock()
        CNMemoryStore.loaded = false
        CNMemoryStore.state = CNMemoryStore.Snapshot()
        CNMemoryStore.ensureLoaded()
        CNMemoryStore.lock.unlock()
    }

    /// Documented test hook: when status is `.notDetermined`, the next
    /// `requestAccess(for:)` call records this decision (`.authorized` or
    /// `.denied`). It never claims an Apple TCC prompt.
    @_spi(OpenUIKitHost)
    public static func _setPortableAuthorizationDecision(_ status: CNAuthorizationStatus) {
        CNMemoryStore.lock.lock()
        CNMemoryStore.ensureLoaded()
        CNMemoryStore.state.requestDecision = status
        CNMemoryStore.persistLocked()
        CNMemoryStore.lock.unlock()
    }

    @_spi(OpenUIKitHost)
    public static func _setPortableAuthorization(_ status: CNAuthorizationStatus) {
        CNMemoryStore.lock.lock()
        CNMemoryStore.ensureLoaded()
        CNMemoryStore.authorization = status
        CNMemoryStore.persistLocked()
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
        CNMemoryStore.ensureLoaded()
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
        sort: CNContactSortOrder,
        unifyResults: Bool
    ) throws -> [CNContact] {
        CNMemoryStore.lock.lock()
        let snapshot = CNMemoryStore.capture()
        CNMemoryStore.lock.unlock()

        var storages = Array(snapshot.contacts.values)
        if let kind = CNStorePredicate.kind(of: predicate) {
            storages = storages.filter { storage in
                matches(kind, storage: storage, snapshot: snapshot)
            }
        } else if let predicate {
            storages = storages.filter { predicate.evaluate(with: CNContact(storage: $0)) }
        }

        let projected = storages.map { $0.projected(keys: CNFlattenKeyDescriptors(keys)) }
        var result: [CNContact] = projected.map { storage in
            mutable ? CNMutableContact(storage: storage) : CNContact(storage: storage)
        }
        // unifyResults is honored as identity: this port has a single local
        // container and does not fabricate CardDAV/iCloud linked-contact graphs.
        _ = unifyResults
        if sort != .none {
            let comparator = CNContact.comparator(forNameSortOrder: sort)
            result.sort { comparator($0, $1) == .orderedAscending }
        }
        return result
    }

    private func matches(
        _ kind: CNStorePredicateKind,
        storage: CNContactStorage,
        snapshot: CNMemoryStore.Snapshot
    ) -> Bool {
        switch kind {
        case .contactsWithIdentifiers(let identifiers):
            return identifiers.contains(storage.identifier)
        case .contactsMatchingName(let name):
            return CNContact(storage: storage).matchesName(name)
        case .contactsMatchingEmail(let email):
            return storage.emailAddresses.contains {
                ($0.value as String).caseInsensitiveCompare(email) == .orderedSame
            }
        case .contactsMatchingPhone(let phone):
            let digits = phone.filter(\.isNumber)
            return storage.phoneNumbers.contains { $0.value.digits() == digits && !digits.isEmpty }
        case .contactsInContainer(let container):
            return snapshot.contactContainers[storage.identifier] == container
        case .contactsInGroup(let group):
            return snapshot.groupMembers[group]?.contains(storage.identifier) == true
        default:
            return false
        }
    }

    private func filterGroups(
        _ groups: [CNGroup],
        predicate: NSPredicate,
        snapshot: CNMemoryStore.Snapshot
    ) -> [CNGroup] {
        switch CNStorePredicate.kind(of: predicate) {
        case .groupsWithIdentifiers(let identifiers):
            return groups.filter { identifiers.contains($0.identifier) }
        case .groupsInContainer(let container):
            return groups.filter { snapshot.groupContainers[$0.identifier] == container }
        case .none:
            return groups.filter { predicate.evaluate(with: $0) }
        default:
            return groups.filter { predicate.evaluate(with: $0) }
        }
    }

    private func filterContainers(
        _ containers: [CNContainer],
        predicate: NSPredicate,
        snapshot: CNMemoryStore.Snapshot
    ) -> [CNContainer] {
        switch CNStorePredicate.kind(of: predicate) {
        case .containersWithIdentifiers(let identifiers):
            return containers.filter { identifiers.contains($0.identifier) }
        case .containerOfContact(let identifier):
            let containerID = snapshot.contactContainers[identifier]
            return containers.filter { $0.identifier == containerID }
        case .containerOfGroup(let identifier):
            let containerID = snapshot.groupContainers[identifier]
            return containers.filter { $0.identifier == containerID }
        case .none:
            return containers.filter { predicate.evaluate(with: $0) }
        default:
            return containers.filter { predicate.evaluate(with: $0) }
        }
    }

    private func apply(
        _ operation: CNSaveOperation,
        to working: inout CNMemoryStore.Snapshot
    ) throws {
        switch operation {
        case .addContact(let contact, let container):
            var storage = contact.storage
            let resolvedContainer = try writableContainer(container)
            if working.contacts[storage.identifier] != nil {
                throw CNError(
                    .insertedRecordAlreadyExists,
                    userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: [storage.identifier]]
                )
            }
            try validate(storage)
            storage.availableKeys = Set(CNAllContactPropertyKeys())
            working.contacts[storage.identifier] = storage
            working.contactContainers[storage.identifier] = resolvedContainer
            appendHistory(
                CNChangeHistoryAddContactEvent(
                    contact: CNContact(storage: storage),
                    containerIdentifier: resolvedContainer
                ),
                to: &working
            )
        case .updateContact(let contact):
            guard let existing = working.contacts[contact.identifier] else {
                throw CNError(
                    .recordDoesNotExist,
                    userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: [contact.identifier]]
                )
            }
            var storage = mergeUnfetched(existing: existing, incoming: contact.storage)
            try validate(storage)
            storage.availableKeys = Set(CNAllContactPropertyKeys())
            working.contacts[contact.identifier] = storage
            appendHistory(
                CNChangeHistoryUpdateContactEvent(contact: CNContact(storage: storage)),
                to: &working
            )
        case .deleteContact(let contact):
            guard working.contacts.removeValue(forKey: contact.identifier) != nil else {
                throw CNError(
                    .recordDoesNotExist,
                    userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: [contact.identifier]]
                )
            }
            working.contactContainers.removeValue(forKey: contact.identifier)
            for key in working.groupMembers.keys {
                working.groupMembers[key]?.remove(contact.identifier)
            }
            appendHistory(
                CNChangeHistoryDeleteContactEvent(contactIdentifier: contact.identifier),
                to: &working
            )
        case .addGroup(let group, let container):
            let resolvedContainer = try writableContainer(container)
            if working.groups[group.identifier] != nil {
                throw CNError(.insertedRecordAlreadyExists)
            }
            working.groups[group.identifier] = (group.identifier, group.name)
            working.groupContainers[group.identifier] = resolvedContainer
            working.groupMembers[group.identifier] = []
            appendHistory(
                CNChangeHistoryAddGroupEvent(
                    group: CNGroup(identifier: group.identifier, name: group.name),
                    containerIdentifier: resolvedContainer
                ),
                to: &working
            )
        case .updateGroup(let group):
            guard working.groups[group.identifier] != nil else {
                throw CNError(.recordDoesNotExist)
            }
            working.groups[group.identifier] = (group.identifier, group.name)
            appendHistory(
                CNChangeHistoryUpdateGroupEvent(
                    group: CNGroup(identifier: group.identifier, name: group.name)
                ),
                to: &working
            )
        case .deleteGroup(let group):
            guard working.groups.removeValue(forKey: group.identifier) != nil else {
                throw CNError(.recordDoesNotExist)
            }
            working.groupMembers.removeValue(forKey: group.identifier)
            working.groupContainers.removeValue(forKey: group.identifier)
            appendHistory(
                CNChangeHistoryDeleteGroupEvent(groupIdentifier: group.identifier),
                to: &working
            )
        case .addMember(let contactID, let groupID):
            guard working.contacts[contactID] != nil else {
                throw CNError(.recordDoesNotExist)
            }
            guard working.groups[groupID] != nil else {
                throw CNError(.parentRecordDoesNotExist)
            }
            working.groupMembers[groupID, default: []].insert(contactID)
            let group = working.groups[groupID]!
            appendHistory(
                CNChangeHistoryAddMemberToGroupEvent(
                    member: CNContact(storage: working.contacts[contactID]!),
                    group: CNGroup(identifier: group.identifier, name: group.name)
                ),
                to: &working
            )
        case .removeMember(let contactID, let groupID):
            working.groupMembers[groupID]?.remove(contactID)
            if let group = working.groups[groupID], let storage = working.contacts[contactID] {
                appendHistory(
                    CNChangeHistoryRemoveMemberFromGroupEvent(
                        member: CNContact(storage: storage),
                        group: CNGroup(identifier: group.identifier, name: group.name)
                    ),
                    to: &working
                )
            }
        }
    }

    private func mergeUnfetched(existing: CNContactStorage, incoming: CNContactStorage) -> CNContactStorage {
        var merged = incoming
        func keep(_ key: String) -> Bool { !incoming.availableKeys.contains(key) }
        if keep(CNContactTypeKey) { merged.contactType = existing.contactType }
        if keep(CNContactNamePrefixKey) { merged.namePrefix = existing.namePrefix }
        if keep(CNContactGivenNameKey) { merged.givenName = existing.givenName }
        if keep(CNContactMiddleNameKey) { merged.middleName = existing.middleName }
        if keep(CNContactFamilyNameKey) { merged.familyName = existing.familyName }
        if keep(CNContactPreviousFamilyNameKey) { merged.previousFamilyName = existing.previousFamilyName }
        if keep(CNContactNameSuffixKey) { merged.nameSuffix = existing.nameSuffix }
        if keep(CNContactNicknameKey) { merged.nickname = existing.nickname }
        if keep(CNContactOrganizationNameKey) { merged.organizationName = existing.organizationName }
        if keep(CNContactDepartmentNameKey) { merged.departmentName = existing.departmentName }
        if keep(CNContactJobTitleKey) { merged.jobTitle = existing.jobTitle }
        if keep(CNContactPhoneticGivenNameKey) { merged.phoneticGivenName = existing.phoneticGivenName }
        if keep(CNContactPhoneticMiddleNameKey) { merged.phoneticMiddleName = existing.phoneticMiddleName }
        if keep(CNContactPhoneticFamilyNameKey) { merged.phoneticFamilyName = existing.phoneticFamilyName }
        if keep(CNContactPhoneticOrganizationNameKey) { merged.phoneticOrganizationName = existing.phoneticOrganizationName }
        if keep(CNContactBirthdayKey) { merged.birthday = existing.birthday }
        if keep(CNContactNonGregorianBirthdayKey) { merged.nonGregorianBirthday = existing.nonGregorianBirthday }
        if keep(CNContactNoteKey) { merged.note = existing.note }
        if keep(CNContactImageDataKey) { merged.imageData = existing.imageData }
        if keep(CNContactThumbnailImageDataKey) { merged.thumbnailImageData = existing.thumbnailImageData }
        if keep(CNContactImageDataAvailableKey) { merged.imagePresent = existing.imagePresent }
        if keep(CNContactPhoneNumbersKey) { merged.phoneNumbers = existing.phoneNumbers }
        if keep(CNContactEmailAddressesKey) { merged.emailAddresses = existing.emailAddresses }
        if keep(CNContactPostalAddressesKey) { merged.postalAddresses = existing.postalAddresses }
        if keep(CNContactDatesKey) { merged.dates = existing.dates }
        if keep(CNContactUrlAddressesKey) { merged.urlAddresses = existing.urlAddresses }
        if keep(CNContactRelationsKey) { merged.contactRelations = existing.contactRelations }
        if keep(CNContactSocialProfilesKey) { merged.socialProfiles = existing.socialProfiles }
        if keep(CNContactInstantMessageAddressesKey) {
            merged.instantMessageAddresses = existing.instantMessageAddresses
        }
        merged.unifiedIdentifiers = existing.unifiedIdentifiers.union(incoming.unifiedIdentifiers)
        if merged.imageData != nil { merged.imagePresent = true }
        if merged.thumbnailImageData == nil { merged.thumbnailImageData = merged.imageData }
        return merged
    }

    private func writableContainer(_ identifier: String?) throws -> String {
        let defaultID = CNMemoryStore.defaultContainer.identifier
        let resolved = identifier ?? defaultID
        if resolved != defaultID {
            throw CNError(
                .parentContainerNotWritable,
                userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: [resolved]]
            )
        }
        return resolved
    }

    private func validate(_ storage: CNContactStorage) throws {
        var errors: [CNError] = []
        var keyPaths: [String] = []
        if let birthday = storage.birthday {
            if let month = birthday.month, !(1...12).contains(month) {
                errors.append(
                    CNError(.validationTypeMismatch, userInfo: [CNErrorUserInfoKeyPathsKey: [CNContactBirthdayKey]])
                )
                keyPaths.append(CNContactBirthdayKey)
            }
            if let day = birthday.day, !(1...31).contains(day) {
                errors.append(
                    CNError(.validationTypeMismatch, userInfo: [CNErrorUserInfoKeyPathsKey: [CNContactBirthdayKey]])
                )
                keyPaths.append(CNContactBirthdayKey)
            }
        }
        if storage.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(
                CNError(.recordIdentifierInvalid, userInfo: [CNErrorUserInfoKeyPathsKey: [CNContactIdentifierKey]])
            )
            keyPaths.append(CNContactIdentifierKey)
        }
        if errors.count == 1 {
            throw errors[0]
        }
        if errors.count > 1 {
            throw CNError(
                .validationMultipleErrors,
                userInfo: [
                    CNErrorUserInfoValidationErrorsKey: errors,
                    CNErrorUserInfoAffectedRecordIdentifiersKey: [storage.identifier],
                    CNErrorUserInfoKeyPathsKey: keyPaths,
                ]
            )
        }
    }

    private func appendHistory(
        _ event: CNChangeHistoryEvent,
        to working: inout CNMemoryStore.Snapshot
    ) {
        working.history.append(event)
        working.historyCounter += 1
    }
}
