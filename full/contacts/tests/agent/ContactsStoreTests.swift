import Foundation
@_spi(OpenUIKitHost) import Contacts

func testContactStoreAuthorization() {
    resetIsolatedStore()
    expect(CNContactStore._portableStoreDirectory().path.contains("openuikit-contacts-"), "directory override")
    CNContactStore._setPortableAuthorizationDecision(.denied)
    expect(CNContactStore.authorizationStatus(for: .contacts) == .notDetermined, "denied-hook starts notDetermined")
    let deniedStore = CNContactStore()
    let deniedSem = DispatchSemaphore(value: 0)
    let deniedGranted = Box(true)
    deniedStore.requestAccess(for: .contacts) { granted, error in
        deniedGranted.value = granted
        expect(error == nil, "denied requestAccess has no fabricated TCC error")
        deniedSem.signal()
    }
    wait(deniedSem, "denied requestAccess deadlock")
    expect(!deniedGranted.value, "documented denied decision")
    expect(CNContactStore.authorizationStatus(for: .contacts) == .denied, "status denied after hook")
    do {
        _ = try deniedStore.unifiedContacts(
            matching: CNContact.predicateForContacts(matchingName: "Nobody"),
            keysToFetch: keys(CNContactGivenNameKey)
        )
        fail("denied fetch must stay fail-closed")
    } catch let error as CNError {
        expect(error.code == .authorizationDenied, "denied fetch code")
    } catch {
        fail("unexpected denied fetch \(error)")
    }

    resetIsolatedStore()
    expect(CNContactStore.authorizationStatus(for: .contacts) == .notDetermined, "start notDetermined")
    let store = CNContactStore()
    do {
        _ = try store.unifiedContacts(
            matching: CNContact.predicateForContacts(matchingName: "Ada"),
            keysToFetch: keys(CNContactGivenNameKey)
        )
        fail("fetch must fail closed before requestAccess")
    } catch let error as CNError {
        expect(error.code == .authorizationDenied, "fail closed authorization")
    } catch {
        fail("unexpected error \(error)")
    }

    let requestAccessReturned = Box(false)
    let granted = Box(false)
    let grantError = Box<Error?>(nil)
    let grantedSem = DispatchSemaphore(value: 0)
    store.requestAccess(for: .contacts) { ok, error in
        expect(requestAccessReturned.value, "requestAccess callback is not reentrant on the calling stack")
        granted.value = ok
        grantError.value = error
        grantedSem.signal()
    }
    requestAccessReturned.value = true
    wait(grantedSem, "requestAccess callback deadlock")
    expect(grantError.value == nil, "requestAccess error")
    expect(granted.value, "in-memory requestAccess")
    expect(CNContactStore.authorizationStatus(for: .contacts) == .authorized, "authorized after request")
}

func testContactStoreSaveAndFetch() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)
    let fetched = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(matchingName: "Ada"),
        keysToFetch: keys(CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey)
    )
    expect(fetched.count == 1, "fetched ada")
    expect(fetched[0].givenName == "Ada", "fetched given")
    let byID = try! store.unifiedContact(
        withIdentifier: contact.identifier,
        keysToFetch: keys(CNContactGivenNameKey)
    )
    expect(byID.givenName == "Ada", "unified by id")
    expect(byID.id == contact.id, "uuid identity")

    let update = byID.mutableCopy() as! CNMutableContact
    update.familyName = "King"
    let updateRequest = CNSaveRequest()
    updateRequest.update(update)
    try! store.execute(updateRequest)
    let updated = try! store.unifiedContact(
        withIdentifier: contact.identifier,
        keysToFetch: keys(CNContactFamilyNameKey)
    )
    expect(updated.familyName == "King", "updated family")

    do {
        _ = try store.unifiedContact(withIdentifier: "no-such-record", keysToFetch: keys(CNContactIdentifierKey))
        fail("missing unifiedContact must throw")
    } catch let error as CNError {
        expect(error.code == .recordDoesNotExist, "recordDoesNotExist")
        expect(error.affectedRecordIdentifiers == ["no-such-record"], "missing id userInfo")
    } catch {
        fail("unexpected missing contact \(error)")
    }
}

func testContactStoreEnumerate() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)

    var enumerated = 0
    let request = CNContactFetchRequest(keysToFetch: keys(CNContactGivenNameKey, CNContactFamilyNameKey))
    request.sortOrder = .familyName
    request.unifyResults = true
    request.predicate = CNContact.predicateForContacts(matchingName: "Ada")
    try! store.enumerateContacts(with: request) { item, stop in
        enumerated += 1
        if item.familyName == "Lovelace" {
            stop.pointee = ObjCBool(true)
        }
    }
    expect(enumerated == 1, "enumerated")

    let mutableEnumerate = CNContactFetchRequest(keysToFetch: keys(CNContactGivenNameKey, CNContactFamilyNameKey))
    mutableEnumerate.mutableObjects = true
    mutableEnumerate.unifyResults = false
    mutableEnumerate.sortOrder = .givenName
    var mutableCount = 0
    try! store.enumerateContacts(with: mutableEnumerate) { item, _ in
        expect(item is CNMutableContact, "mutableObjects honored")
        mutableCount += 1
    }
    expect(mutableCount >= 1, "mutable enumerate")
}

func testContactStoreGroupsAndContainers() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let group = CNMutableGroup()
    group.name = "Scientists"
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    save.add(group, toContainerWithIdentifier: nil)
    try! store.execute(save)
    let memberSave = CNSaveRequest()
    memberSave.addMember(contact, to: group)
    try! store.execute(memberSave)

    let groups = try! store.groups(matching: CNGroup.predicateForGroups(withIdentifiers: [group.identifier]))
    expect(groups.count == 1 && groups[0].name == "Scientists", "group fetch")
    expect(groups[0].identifier == group.identifier, "group identifier")
    let inGroup = try! store.unifiedContacts(
        matching: CNContact.predicateForContactsInGroup(withIdentifier: group.identifier),
        keysToFetch: keys(CNContactGivenNameKey)
    )
    expect(inGroup.count == 1, "contacts in group")
    _ = try! store.groups(matching: CNGroup.predicateForGroupsInContainer(withIdentifier: store.defaultContainerIdentifier()))

    let containers = try! store.containers(matching: nil)
    expect(containers.count == 1 && containers[0].type == .local, "local container")
    expect(containers[0].name.count >= 0, "container name")
    expect(store.defaultContainerIdentifier() == containers[0].identifier, "default container")
    let ofContact = try! store.containers(
        matching: CNContainer.predicateForContainerOfContact(withIdentifier: contact.identifier)
    )
    expect(ofContact.count == 1, "container of contact")
    _ = try! store.containers(matching: CNContainer.predicateForContainers(withIdentifiers: [store.defaultContainerIdentifier()]))
    _ = try! store.containers(matching: CNContainer.predicateForContainerOfGroup(withIdentifier: group.identifier))
}

func testContactStoreNotifications() {
    resetIsolatedStore()
    let store = authorizeStore()
    expect(NSNotification.Name.CNContactStoreDidChange.rawValue == "CNContactStoreDidChangeNotification", "note name")
    let observerQueries = Box(0)
    let observer = NotificationCenter.default.addObserver(
        forName: .CNContactStoreDidChange,
        object: store,
        queue: nil
    ) { _ in
        let containers = try? store.containers(matching: nil)
        expect(containers?.count == 1, "observer reentered containers()")
        observerQueries.value += 1
    }
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)
    expect(observerQueries.value >= 1, "did-change observer ran without deadlock")
    NotificationCenter.default.removeObserver(observer)
}

func testContactStoreValidationAndRollback() {
    resetIsolatedStore()
    let store = authorizeStore()

    let invalid = CNMutableContact()
    invalid.givenName = "BadDate"
    invalid.birthday = DateComponents(calendar: Calendar(identifier: .gregorian), year: 2000, month: 99, day: 99)
    let invalidSave = CNSaveRequest()
    invalidSave.add(invalid, toContainerWithIdentifier: nil)
    do {
        try store.execute(invalidSave)
        fail("invalid birthday must fail validation")
    } catch let error as CNError {
        expect(error.code == .validationMultipleErrors, "validationMultipleErrors \(error.code)")
        expect(error.userInfo[CNErrorUserInfoValidationErrorsKey] != nil, "validation errors userInfo")
        expect(error.affectedRecordIdentifiers == [invalid.identifier], "validation affected ids")
        expect(error.keyPaths?.contains(CNContactBirthdayKey) == true, "validation keyPaths")
    } catch {
        fail("unexpected validation error \(error)")
    }

    let foreign = CNMutableContact()
    foreign.givenName = "CardDAV"
    let foreignSave = CNSaveRequest()
    foreignSave.add(foreign, toContainerWithIdentifier: "icloud-not-attached")
    do {
        try store.execute(foreignSave)
        fail("non-local container must fail closed")
    } catch let error as CNError {
        expect(error.code == .parentContainerNotWritable, "parentContainerNotWritable")
    } catch {
        fail("unexpected container error \(error)")
    }

    let rolledInsert = CNMutableContact()
    rolledInsert.givenName = "RollbackA"
    let duplicateInsert = CNSaveRequest()
    duplicateInsert.add(rolledInsert, toContainerWithIdentifier: nil)
    duplicateInsert.add(rolledInsert, toContainerWithIdentifier: nil)
    do {
        try store.execute(duplicateInsert)
        fail("duplicate insert must fail the whole transaction")
    } catch let error as CNError {
        expect(error.code == .insertedRecordAlreadyExists, "duplicate insert code")
    } catch {
        fail("unexpected rollback error \(error)")
    }
    let rolledHits = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(matchingName: "RollbackA"),
        keysToFetch: keys(CNContactGivenNameKey)
    )
    expect(rolledHits.isEmpty, "valid insert rolled back after later duplicate")
}

func testContactStoreDirectoryPersistence() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)
    CNContactStore._reloadPortableStoreFromDisk()
    let reloaded = try! CNContactStore().unifiedContact(
        withIdentifier: contact.identifier,
        keysToFetch: keys(CNContactFamilyNameKey, CNContactGivenNameKey, CNContactImageDataKey, CNContactThumbnailImageDataKey)
    )
    expect(reloaded.familyName == "Lovelace", "directory store survived reload")
    expect(reloaded.givenName == "Ada", "directory store given name")
    expect(reloaded.thumbnailImageData == Data([0x00, 0x01, 0x02]), "persisted thumbnail")
    expect(
        FileManager.default.fileExists(
            atPath: CNContactStore._portableStoreDirectory().appendingPathComponent("store.json").path
        ),
        "store.json exists"
    )
}
