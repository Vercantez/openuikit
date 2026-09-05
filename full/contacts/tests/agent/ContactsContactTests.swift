import Foundation
@_spi(OpenUIKitHost) import Contacts

func testContactPropertiesAndKeys() {
    let contact = makeAdaContact()
    expect(contact.identifier.count == 36, "uuid identifier")
    expect(contact.contactType == .person, "contactType")
    expect(contact.namePrefix == "Ms", "namePrefix")
    expect(contact.givenName == "Ada", "givenName")
    expect(contact.middleName == "Byron", "middleName")
    expect(contact.familyName == "Lovelace", "familyName")
    expect(contact.previousFamilyName == "Byron", "previousFamilyName")
    expect(contact.nameSuffix == "Countess", "nameSuffix")
    expect(contact.nickname == "Ada", "nickname")
    expect(contact.organizationName == "Analytical Engine", "organizationName")
    expect(contact.departmentName == "Mathematics", "departmentName")
    expect(contact.jobTitle == "Mathematician", "jobTitle")
    expect(contact.phoneticGivenName == "Ay-duh", "phoneticGivenName")
    expect(contact.phoneticMiddleName == "By-ron", "phoneticMiddleName")
    expect(contact.phoneticFamilyName == "Love-lace", "phoneticFamilyName")
    expect(contact.phoneticOrganizationName == "Engine", "phoneticOrganizationName")
    expect(contact.birthday?.year == 1815, "birthday")
    expect(contact.nonGregorianBirthday == nil, "nonGregorianBirthday")
    expect(contact.note == "First programmer", "note")
    expect(contact.imageData == Data([0x00, 0x01, 0x02]), "imageData")
    expect(contact.imageDataAvailable, "imageDataAvailable")
    expect(contact.thumbnailImageData == contact.imageData, "thumbnailImageData")
    expect(contact.phoneNumbers.count == 1, "phoneNumbers")
    expect(contact.emailAddresses.count == 1, "emailAddresses")
    expect(contact.postalAddresses.count == 1, "postalAddresses")
    expect(contact.dates.count == 1, "dates")
    expect(contact.urlAddresses.count == 1, "urlAddresses")
    expect(contact.contactRelations.count == 1, "contactRelations")
    expect(contact.socialProfiles.count == 1, "socialProfiles")
    expect(contact.instantMessageAddresses.count == 1, "instantMessageAddresses")
    expect(contact.isKeyAvailable(CNContactGivenNameKey), "isKeyAvailable")
    expect(
        contact.areKeysAvailable([CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]),
        "areKeysAvailable"
    )
    expect(!contact.isUnifiedWithContact(withIdentifier: "missing"), "isUnifiedWithContact")
    expect(CNContact.localizedString(forKey: CNContactGivenNameKey) == "Given Name", "localizedString")
    let copied = contact.copy() as! CNContact
    expect(copied.givenName == "Ada", "NSCopying")
}

func testMutableContactSetters() {
    let contact = CNMutableContact()
    contact.contactType = .organization
    contact.namePrefix = "Dr"
    contact.givenName = "Grace"
    contact.middleName = "Brewster"
    contact.familyName = "Hopper"
    contact.previousFamilyName = "Murray"
    contact.nameSuffix = "USN"
    contact.nickname = "Amazing Grace"
    contact.organizationName = "Navy"
    contact.departmentName = "COBOL"
    contact.jobTitle = "Rear Admiral"
    contact.phoneticGivenName = "Grace"
    contact.phoneticMiddleName = "Brewster"
    contact.phoneticFamilyName = "Hopper"
    contact.phoneticOrganizationName = "Navy"
    contact.birthday = DateComponents(calendar: Calendar(identifier: .gregorian), year: 1906, month: 12, day: 9)
    contact.nonGregorianBirthday = DateComponents(year: 1906, month: 12, day: 9)
    contact.note = "compiler"
    contact.imageData = Data([0x0A])
    contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: "1"))]
    contact.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: "grace@example.com" as NSString)]
    contact.postalAddresses = [CNLabeledValue(label: CNLabelWork, value: CNMutablePostalAddress())]
    let anniversary = NSDateComponents()
    anniversary.year = 1952
    contact.dates = [CNLabeledValue(label: CNLabelDateAnniversary, value: anniversary)]
    contact.urlAddresses = [CNLabeledValue(label: CNLabelURLAddressHomePage, value: "https://example.com" as NSString)]
    contact.contactRelations = [CNLabeledValue(label: CNLabelContactRelationColleague, value: CNContactRelation(name: "Team"))]
    contact.socialProfiles = [
        CNLabeledValue(
            label: CNLabelWork,
            value: CNSocialProfile(urlString: "u", username: "g", userIdentifier: "1", service: CNSocialProfileServiceTwitter)
        )
    ]
    contact.instantMessageAddresses = [
        CNLabeledValue(label: CNLabelWork, value: CNInstantMessageAddress(username: "g", service: CNInstantMessageServiceAIM))
    ]
    expect(contact.contactType == .organization, "mutable contactType")
    expect(contact.givenName == "Grace", "mutable givenName")
    expect(contact.familyName == "Hopper", "mutable familyName")
    expect(contact.nonGregorianBirthday?.year == 1906, "mutable nonGregorianBirthday")
    expect(contact.phoneNumbers[0].label == CNLabelPhoneNumberMain, "mutable phoneNumbers")
    expect(contact.emailAddresses[0].value as String == "grace@example.com", "mutable emailAddresses")
    expect(contact.urlAddresses[0].value as String == "https://example.com", "mutable urlAddresses")
    expect(contact.dates[0].label == CNLabelDateAnniversary, "mutable dates")
    expect(contact.instantMessageAddresses[0].value.service == CNInstantMessageServiceAIM, "mutable IM")
    let snapshot = contact.copy() as! CNContact
    let mutated = snapshot.mutableCopy() as! CNMutableContact
    mutated.givenName = "Other"
    expect(snapshot.givenName == "Grace", "mutableCopy independence")
}

func testContactPredicatesAndDescriptors() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)

    let byName = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(matchingName: "Ada"),
        keysToFetch: keys(CNContactGivenNameKey)
    )
    expect(byName.count == 1, "predicateForContacts matchingName")
    let byEmail = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(matchingEmailAddress: "ada@example.com"),
        keysToFetch: keys(CNContactIdentifierKey)
    )
    expect(byEmail.count == 1, "predicateForContacts matchingEmailAddress")
    let byPhone = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(matching: CNPhoneNumber(stringValue: "+1-555-0100")),
        keysToFetch: keys(CNContactIdentifierKey)
    )
    expect(byPhone.count == 1, "predicateForContacts matching phone")
    let byID = try! store.unifiedContacts(
        matching: CNContact.predicateForContacts(withIdentifiers: [contact.identifier]),
        keysToFetch: keys(CNContactIdentifierKey)
    )
    expect(byID.count == 1, "predicateForContacts withIdentifiers")
    let inContainer = try! store.unifiedContacts(
        matching: CNContact.predicateForContactsInContainer(withIdentifier: store.defaultContainerIdentifier()),
        keysToFetch: keys(CNContactIdentifierKey)
    )
    expect(inContainer.count == 1, "predicateForContactsInContainer")

    let comparator = CNContact.comparator(forNameSortOrder: .familyName)
    expect(comparator(contact, contact) == .orderedSame, "comparator")
    _ = CNContact.descriptorForAllComparatorKeys()
}

func testContactIdentifiable() {
    let contact = CNMutableContact()
    contact.givenName = "Id"
    expect(contact.id.uuidString == contact.identifier, "CNContact.ID is UUID")
    let typed: CNContact.ID = contact.id
    expect(typed == contact.id, "typealias CNContact.ID")
}

func testUnfetchedKeysAndThumbnail() {
    resetIsolatedStore()
    let store = authorizeStore()
    let contact = makeAdaContact()
    let save = CNSaveRequest()
    save.add(contact, toContainerWithIdentifier: nil)
    try! store.execute(save)
    let partial = try! store.unifiedContact(
        withIdentifier: contact.identifier,
        keysToFetch: keys(CNContactGivenNameKey)
    )
    expect(partial.isKeyAvailable(CNContactGivenNameKey), "fetched given available")
    expect(!partial.isKeyAvailable(CNContactEmailAddressesKey), "unfetched email")
    do {
        try partial.requireKeyAvailable(CNContactEmailAddressesKey)
        fail("unfetched key must throw")
    } catch let error as CNError {
        expect(error.code == .unauthorizedKeys, "unauthorizedKeys on unfetched access")
        expect(error.keyPaths == [CNContactEmailAddressesKey], "unauthorized key path")
    } catch {
        fail("unexpected unfetched error \(error)")
    }
    do {
        try partial.requireKeysAvailable(keys(CNContactEmailAddressesKey, CNContactPhoneNumbersKey))
        fail("areKeysAvailable-style require must throw")
    } catch let error as CNError {
        expect(error.code == .unauthorizedKeys, "unauthorizedKeys for missing descriptors")
    } catch {
        fail("unexpected requireKeys \(error)")
    }
    _ = partial.emailAddresses
    let unfetched = CNContact._consumeUnfetchedKeyError()
    expect(unfetched?.code == .unauthorizedKeys, "getter records unauthorizedKeys")
    expect(contact.thumbnailImageData == contact.imageData, "thumbnail equals imageData")
}
