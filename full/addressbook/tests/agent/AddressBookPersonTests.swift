import AddressBook
import CoreFoundation
import Foundation

func testPersonImageAndSource() {
    let book = abFreshBook()
    let source = abPeek(ABAddressBookCopyDefaultSource(book))
    let person = abTake(ABPersonCreateInSource(source))
    abRequire(ABRecordGetRecordType(person) == ABRecordType(kABPersonType), "person")
    let copiedSource = abPeek(ABPersonCopySource(person))
    abRequire(copiedSource === source, "same source")
    abRequire(!ABPersonHasImageData(person), "no image")
    let payload = Data([0x00, 0x01, 0x02, 0xFF])
    abRequire(
        ABPersonSetImageData(person, unsafeBitCast(payload as NSData, to: CFData.self), nil),
        "set image"
    )
    abRequire(ABPersonHasImageData(person), "has image")
    let copied = abTake(ABPersonCopyImageData(person))
    abRequire((copied as Data) == payload, "image bytes")
    let thumb = abTake(ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail))
    abRequire((thumb as Data) == payload, "thumb same bytes")
    let original = abTake(ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatOriginalSize))
    abRequire((original as Data) == payload, "original same bytes")
    abRequire(ABPersonRemoveImageData(person, nil), "remove image")
    abRequire(!ABPersonHasImageData(person), "image gone")
    abRequire(ABPersonCreateInSource(person) == nil, "person is not a source")
}

func testPersonCompareAndSort() {
    let ada = abFreshPerson()
    _ = ABRecordSetValue(ada, kABPersonFirstNameProperty, abCF("Ada"), nil)
    _ = ABRecordSetValue(ada, kABPersonLastNameProperty, abCF("Lovelace"), nil)
    let grace = abFreshPerson()
    _ = ABRecordSetValue(grace, kABPersonFirstNameProperty, abCF("Grace"), nil)
    _ = ABRecordSetValue(grace, kABPersonLastNameProperty, abCF("Hopper"), nil)
    abRequire(
        ABPersonComparePeopleByName(ada, grace, ABPersonSortOrdering(kABPersonSortByFirstName))
            == .compareLessThan,
        "ada < grace first"
    )
    abRequire(
        ABPersonComparePeopleByName(grace, ada, ABPersonSortOrdering(kABPersonSortByLastName))
            == .compareLessThan,
        "hopper < lovelace last"
    )
    abRequire(
        ABPersonComparePeopleByName(ada, ada, ABPersonSortOrdering(kABPersonSortByFirstName))
            == .compareEqualTo,
        "equal"
    )
    abRequire(
        ABPersonGetSortOrdering() == ABPersonSortOrdering(kABPersonSortByFirstName),
        "default sort"
    )

    let book = abFreshBook()
    abRequire(ABAddressBookAddRecord(book, ada, nil), "add ada")
    abRequire(ABAddressBookAddRecord(book, grace, nil), "add grace")
    let source = abPeek(ABAddressBookCopyDefaultSource(book))
    let sorted = abTake(
        ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(
            book,
            source,
            ABPersonSortOrdering(kABPersonSortByLastName)
        )
    ) as NSArray
    abRequire(sorted.count == 2, "sorted count")
    let first = sorted[0] as AnyObject
    abRequire(abText(abTake(ABRecordCopyValue(first, kABPersonLastNameProperty)) as! CFString) == "Hopper", "hopper first")
}

func testLinkedPeopleAndPropertyMetadata() {
    let person = abFreshPerson()
    let linked = abTake(ABPersonCopyArrayOfAllLinkedPeople(person)) as NSArray
    abRequire(linked.count == 1, "self linked")
    abRequire(linked[0] as AnyObject === person, "self identity")
    abRequire(ABPersonGetTypeOfProperty(kABPersonFirstNameProperty) == ABPropertyType(kABStringPropertyType), "fn type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonEmailProperty) == ABPropertyType(kABMultiStringPropertyType), "email type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonAddressProperty) == ABPropertyType(kABMultiDictionaryPropertyType), "addr type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonBirthdayProperty) == ABPropertyType(kABDateTimePropertyType), "bday type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonKindProperty) == ABPropertyType(kABIntegerPropertyType), "kind type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonDateProperty) == ABPropertyType(kABMultiDateTimePropertyType), "dates type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonPhoneProperty) == ABPropertyType(kABMultiStringPropertyType), "phone type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonInstantMessageProperty) == ABPropertyType(kABMultiDictionaryPropertyType), "im type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonSocialProfileProperty) == ABPropertyType(kABMultiDictionaryPropertyType), "social type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonURLProperty) == ABPropertyType(kABMultiStringPropertyType), "url type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonRelatedNamesProperty) == ABPropertyType(kABMultiStringPropertyType), "related type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonAlternateBirthdayProperty) == ABPropertyType(kABDictionaryPropertyType), "alt bday type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonCreationDateProperty) == ABPropertyType(kABDateTimePropertyType), "created type")
    abRequire(ABPersonGetTypeOfProperty(kABPersonModificationDateProperty) == ABPropertyType(kABDateTimePropertyType), "modified type")
    abRequire(ABPersonGetTypeOfProperty(99) == ABPropertyType(kABInvalidPropertyType), "unknown type")
    let localized = abTake(ABPersonCopyLocalizedPropertyName(kABPersonFirstNameProperty))
    abRequire(abText(localized) == "First Name", "localized first")
}

func testGroupMembership() {
    let book = abFreshBook()
    let source = abPeek(ABAddressBookCopyDefaultSource(book))
    let group = abTake(ABGroupCreateInSource(source))
    _ = ABRecordSetValue(group, kABGroupNameProperty, abCF("Engineers"), nil)
    let groupName = abTake(ABRecordCopyCompositeName(group))
    abRequire(abText(groupName) == "Engineers", "group name")
    abRequire(ABRecordGetRecordType(group) == ABRecordType(kABGroupType), "group type")
    let copiedSource = abPeek(ABGroupCopySource(group))
    abRequire(copiedSource === source, "group source")

    let ada = abFreshPerson()
    _ = ABRecordSetValue(ada, kABPersonFirstNameProperty, abCF("Ada"), nil)
    _ = ABRecordSetValue(ada, kABPersonLastNameProperty, abCF("Lovelace"), nil)
    let grace = abFreshPerson()
    _ = ABRecordSetValue(grace, kABPersonFirstNameProperty, abCF("Grace"), nil)
    _ = ABRecordSetValue(grace, kABPersonLastNameProperty, abCF("Hopper"), nil)
    abRequire(ABGroupAddMember(group, ada, nil), "add ada")
    abRequire(ABGroupAddMember(group, grace, nil), "add grace")
    let members = abTake(ABGroupCopyArrayOfAllMembers(group)) as NSArray
    abRequire(members.count == 2, "members")
    let sorted = abTake(
        ABGroupCopyArrayOfAllMembersWithSortOrdering(group, ABPersonSortOrdering(kABPersonSortByLastName))
    ) as NSArray
    abRequire(
        abText(abTake(ABRecordCopyValue(sorted[0] as AnyObject, kABPersonLastNameProperty)) as! CFString) == "Hopper",
        "sorted hopper"
    )
    abRequire(ABGroupRemoveMember(group, ada, nil), "remove ada")
    abRequire((abTake(ABGroupCopyArrayOfAllMembers(group)) as NSArray).count == 1, "one left")
    abRequire(!ABGroupRemoveMember(group, ada, nil), "remove missing")
    let standalone = abTake(ABGroupCreate())
    abRequire(ABRecordGetRecordType(standalone) == ABRecordType(kABGroupType), "standalone group")
}
