import AddressBook
import CoreFoundation
import Foundation

func testAddressBookStore() {
    let book = abFreshBook()
    abRequire(!ABAddressBookHasUnsavedChanges(book), "fresh clean")
    abRequire(ABAddressBookGetPersonCount(book) == 0, "no people")
    abRequire(ABAddressBookGetGroupCount(book) == 0, "no groups")

    let sources = abNSArray(abTake(ABAddressBookCopyArrayOfAllSources(book)))
    abRequire(sources.count == 1, "one source")
    let source = abPeek(ABAddressBookCopyDefaultSource(book))
    abRequire(ABRecordGetRecordType(source) == ABRecordType(kABSourceType), "source type")
    let sourceName = abTake(ABRecordCopyCompositeName(source))
    abRequire(abText(sourceName) == "Local", "local source")
    let fetchedSource = abPeek(ABAddressBookGetSourceWithRecordID(book, ABRecordGetRecordID(source)))
    abRequire(fetchedSource === source, "get source by id")

    let person = abFreshPerson()
    _ = ABRecordSetValue(person, kABPersonFirstNameProperty, abCF("Ada"), nil)
    _ = ABRecordSetValue(person, kABPersonLastNameProperty, abCF("Lovelace"), nil)
    abRequire(ABAddressBookAddRecord(book, person, nil), "add person")
    abRequire(ABAddressBookHasUnsavedChanges(book), "dirty after add")
    abRequire(ABRecordGetRecordID(person) != kABRecordInvalidID, "assigned id")
    abRequire(ABAddressBookGetPersonCount(book) == 1, "one person")
    let byID = abPeek(ABAddressBookGetPersonWithRecordID(book, ABRecordGetRecordID(person)))
    abRequire(byID === person, "get person")

    let group = abTake(ABGroupCreate())
    _ = ABRecordSetValue(group, kABGroupNameProperty, abCF("Pioneers"), nil)
    abRequire(ABAddressBookAddRecord(book, group, nil), "add group")
    abRequire(ABAddressBookGetGroupCount(book) == 1, "one group")
    let groupByID = abPeek(ABAddressBookGetGroupWithRecordID(book, ABRecordGetRecordID(group)))
    abRequire(groupByID === group, "get group")

    let people = abNSArray(abTake(ABAddressBookCopyArrayOfAllPeople(book)))
    abRequire(people.count == 1, "copy people")
    let groups = abNSArray(abTake(ABAddressBookCopyArrayOfAllGroups(book)))
    abRequire(groups.count == 1, "copy groups")
    let inSource = abNSArray(abTake(ABAddressBookCopyArrayOfAllPeopleInSource(book, source)))
    abRequire(inSource.count == 1, "people in source")
    let groupsInSource = abNSArray(abTake(ABAddressBookCopyArrayOfAllGroupsInSource(book, source)))
    abRequire(groupsInSource.count == 1, "groups in source")

    abRequire(ABAddressBookSave(book, nil), "save")
    abRequire(!ABAddressBookHasUnsavedChanges(book), "clean after save")
    abRequire(ABAddressBookRemoveRecord(book, group, nil), "remove group")
    abRequire(ABAddressBookHasUnsavedChanges(book), "dirty after remove")
    ABAddressBookRevert(book)
    abRequire(!ABAddressBookHasUnsavedChanges(book), "clean after revert")
    abRequire(ABAddressBookGetGroupCount(book) == 1, "group restored")
    abRequire(ABAddressBookGetPersonWithRecordID(book, 999) == nil, "missing person")
    abRequire(ABAddressBookGetGroupWithRecordID(book, 999) == nil, "missing group")
    abRequire(ABAddressBookGetSourceWithRecordID(book, 999) == nil, "missing source")
    abRequire(!ABAddressBookRemoveRecord(book, source, nil), "cannot remove default source")
}

func testPeopleSearch() {
    let book = abFreshBook()
    let ada = abFreshPerson()
    _ = ABRecordSetValue(ada, kABPersonFirstNameProperty, abCF("Ada"), nil)
    _ = ABRecordSetValue(ada, kABPersonLastNameProperty, abCF("Lovelace"), nil)
    let grace = abFreshPerson()
    _ = ABRecordSetValue(grace, kABPersonFirstNameProperty, abCF("Grace"), nil)
    _ = ABRecordSetValue(grace, kABPersonLastNameProperty, abCF("Hopper"), nil)
    abRequire(ABAddressBookAddRecord(book, ada, nil), "add ada")
    abRequire(ABAddressBookAddRecord(book, grace, nil), "add grace")
    let found = abNSArray(abTake(ABAddressBookCopyPeopleWithName(book, abCF("love"))))
    abRequire(found.count == 1, "one match")
    abRequire(
        abAsString(abTake(ABRecordCopyValue(found[0] as AnyObject, kABPersonFirstNameProperty))) == "Ada",
        "matched ada"
    )
    let none = abNSArray(abTake(ABAddressBookCopyPeopleWithName(book, abCF("xyz"))))
    abRequire(none.count == 0, "no match")
}

func testCreateWithOptionsAndLocalizedLabel() {
    var slot: Unmanaged<CFError>? = nil
    let book = abTake(ABAddressBookCreateWithOptions(nil, &slot))
    abRequire(slot == nil, "no error on create")
    abRequire(ABAddressBookGetPersonCount(book) == 0, "empty book")
    let home = abTake(ABAddressBookCopyLocalizedLabel(kABHomeLabel))
    abRequire(abText(home) == "Home", "strip home")
    let iphone = abTake(ABAddressBookCopyLocalizedLabel(kABPersonPhoneIPhoneLabel))
    abRequire(abText(iphone) == "iPhone", "iphone passthrough")
}

func testAuthorizationFailClosed() {
    abRequire(ABAddressBookGetAuthorizationStatus() == .denied, "always denied")
    let book = abFreshBook()
    var granted = true
    var code = -1
    var domain = ""
    ABAddressBookRequestAccessWithCompletion(book) { success, error in
        granted = success
        if let error {
            let ns = abNSError(error)
            code = ns.code
            domain = ns.domain
        }
    }
    abRequire(!granted, "not granted")
    abRequire(code == kABOperationNotPermittedByUserError, "user error")
    abRequire(domain == "ABAddressBookErrorDomain", "error domain")
    abRequire(ABAddressBookGetAuthorizationStatus() == .denied, "still denied")
}

func testExternalChangeCallback() {
    let book = abFreshBook()
    var fired = false
    let callback: ABExternalChangeCallback = { _, _, _ in
        fired = true
    }
    ABAddressBookRegisterExternalChangeCallback(book, callback, nil)
    ABAddressBookUnregisterExternalChangeCallback(book, callback, nil)
    abRequire(!fired, "linux never delivers daemon callbacks")
}

func testStoreErrors() {
    var error: Unmanaged<CFError>? = nil
    abRequire(!ABAddressBookAddRecord(nil, nil, &error), "nil add")
    let ns = abNSError(error!.takeRetainedValue())
    abRequire(ns.code == kABOperationNotPermittedByStoreError, "store error")
    abRequire(ns.domain == "ABAddressBookErrorDomain", "domain")
    abRequire(!ABAddressBookSave(nil, nil), "nil save")
    ABAddressBookRevert(nil)
    abRequire(!ABPersonSetImageData(nil, nil, nil), "nil image")
    abRequire(!ABPersonRemoveImageData(nil, nil), "nil remove image")
    abRequire(!ABGroupAddMember(nil, nil, nil), "nil group add")
}

func testVCardRoundTrip() {
    let ada = abFreshPerson()
    _ = ABRecordSetValue(ada, kABPersonPrefixProperty, abCF("Ms"), nil)
    _ = ABRecordSetValue(ada, kABPersonFirstNameProperty, abCF("Ada"), nil)
    _ = ABRecordSetValue(ada, kABPersonMiddleNameProperty, abCF("Byron"), nil)
    _ = ABRecordSetValue(ada, kABPersonLastNameProperty, abCF("Lovelace"), nil)
    _ = ABRecordSetValue(ada, kABPersonSuffixProperty, abCF("Countess"), nil)
    _ = ABRecordSetValue(ada, kABPersonOrganizationProperty, abCF("Analytical Engines"), nil)
    _ = ABRecordSetValue(ada, kABPersonJobTitleProperty, abCF("Mathematician"), nil)
    _ = ABRecordSetValue(ada, kABPersonNicknameProperty, abCF("Ada"), nil)
    _ = ABRecordSetValue(ada, kABPersonNoteProperty, abCF("First programmer"), nil)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let birthday = calendar.date(from: DateComponents(year: 1815, month: 12, day: 10))!
    _ = ABRecordSetValue(ada, kABPersonBirthdayProperty, birthday as NSDate, nil)

    let phones = abTake(ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType)))
    var phoneID = kABMultiValueInvalidIdentifier
    _ = ABMultiValueAddValueAndLabel(phones, abCF("+1-555-0100"), kABPersonPhoneMobileLabel, &phoneID)
    _ = ABRecordSetValue(ada, kABPersonPhoneProperty, phones, nil)

    let emails = abTake(ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType)))
    var emailID = kABMultiValueInvalidIdentifier
    _ = ABMultiValueAddValueAndLabel(emails, abCF("ada@example.com"), kABHomeLabel, &emailID)
    _ = ABRecordSetValue(ada, kABPersonEmailProperty, emails, nil)

    let urls = abTake(ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType)))
    var urlID = kABMultiValueInvalidIdentifier
    _ = ABMultiValueAddValueAndLabel(urls, abCF("https://example.invalid/ada"), kABPersonHomePageLabel, &urlID)
    _ = ABRecordSetValue(ada, kABPersonURLProperty, urls, nil)

    let addresses = abTake(ABMultiValueCreateMutable(ABPropertyType(kABMultiDictionaryPropertyType)))
    let address: [String: String] = [
        "Street": "12 Difference Engine Rd",
        "City": "London",
        "State": "England",
        "ZIP": "SW1A",
        "Country": "United Kingdom",
    ]
    var addressID = kABMultiValueInvalidIdentifier
    _ = ABMultiValueAddValueAndLabel(addresses, address as NSDictionary, kABHomeLabel, &addressID)
    _ = ABRecordSetValue(ada, kABPersonAddressProperty, addresses, nil)
    _ = ABPersonSetImageData(ada, abCFData(Data([0x00, 0x01, 0x02])), nil)

    let staging = abFreshBook()
    abRequire(ABAddressBookAddRecord(staging, ada, nil), "stage ada")
    let people = abTake(ABAddressBookCopyArrayOfAllPeople(staging))
    let dataUnmanaged = ABPersonCreateVCardRepresentationWithPeople(people)
    abRequire(dataUnmanaged != nil, "vcard representation")
    let data = dataUnmanaged!.takeRetainedValue()
    let text = String(data: abNSData(data), encoding: .utf8) ?? ""
    abRequire(text.contains("BEGIN:VCARD"), "begin")
    abRequire(text.contains("VERSION:3.0"), "version")
    abRequire(text.contains("N:Lovelace;Ada;Byron;Ms;Countess"), "N")
    abRequire(text.contains("TEL;TYPE=CELL:"), "tel")
    abRequire(text.contains("EMAIL;TYPE=HOME:"), "email")
    abRequire(text.contains("BDAY:1815-12-10"), "bday")
    abRequire(text.contains("ADR;TYPE=HOME:"), "adr")

    let book = abFreshBook()
    let source = abPeek(ABAddressBookCopyDefaultSource(book))
    let decoded = abNSArray(abTake(ABPersonCreatePeopleInSourceWithVCardRepresentation(source, data)))
    abRequire(decoded.count == 1, "one card")
    let roundTrip = decoded[0] as AnyObject
    abRequire(
        abAsString(abTake(ABRecordCopyValue(roundTrip, kABPersonFirstNameProperty))) == "Ada",
        "decoded first"
    )
    abRequire(
        abAsString(abTake(ABRecordCopyValue(roundTrip, kABPersonLastNameProperty))) == "Lovelace",
        "decoded last"
    )
    abRequire(
        abAsString(abTake(ABRecordCopyValue(roundTrip, kABPersonNoteProperty))) == "First programmer",
        "decoded note"
    )
    abRequire(ABPersonCreateVCardRepresentationWithPeople(abCFArray(NSArray())) == nil, "empty people")
    abRequire(ABPersonCreatePeopleInSourceWithVCardRepresentation(source, nil) == nil, "nil data")
}
