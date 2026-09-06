import AddressBook
import CoreFoundation
import Foundation

func testABAddressBookTypealias() {
    let book: ABAddressBook = abTake(ABAddressBookCreate())
    abRequire(ABAddressBookGetPersonCount(book) == 0, "typed empty book")
    let person = abTake(ABPersonCreate())
    abRequire(ABAddressBookAddRecord(book, person, nil), "add through typed book")
    abRequire(ABAddressBookGetPersonCount(book) == 1, "typed count")
}

func testABRecordTypealias() {
    let record: ABRecord = abTake(ABPersonCreate())
    abRequire(ABRecordSetValue(record, kABPersonFirstNameProperty, abCF("Ada"), nil), "set on typed record")
    let copied = abTake(ABRecordCopyValue(record, kABPersonFirstNameProperty))
    abRequire(abAsString(copied) == "Ada", "copy from typed record")
}

func testABMultiValueTypealias() {
    let mutable = abTake(ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType)))
    var ident = kABMultiValueInvalidIdentifier
    abRequire(ABMultiValueAddValueAndLabel(mutable, abCF("ada@example.com"), kABHomeLabel, &ident), "add")
    let multi: ABMultiValue = mutable
    abRequire(ABMultiValueGetCount(multi) == 1, "typed multi count")
    let value = abTake(ABMultiValueCopyValueAtIndex(multi, 0))
    abRequire(abAsString(value) == "ada@example.com", "typed multi value")
}

func testABMutableMultiValueTypealias() {
    let mutable: ABMutableMultiValue = abTake(
        ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType))
    )
    var ident = kABMultiValueInvalidIdentifier
    abRequire(ABMultiValueAddValueAndLabel(mutable, abCF("work@example.com"), kABWorkLabel, &ident), "mutate")
    abRequire(ABMultiValueReplaceValueAtIndex(mutable, abCF("new@example.com"), 0), "replace")
    abRequire(abAsString(abTake(ABMultiValueCopyValueAtIndex(mutable, 0))) == "new@example.com", "replaced")
}

func testABMultiValueIdentifierTypealias() {
    let multi = abTake(ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType)))
    var ident: ABMultiValueIdentifier = kABMultiValueInvalidIdentifier
    abRequire(ABMultiValueAddValueAndLabel(multi, abCF("ada@example.com"), kABHomeLabel, &ident), "add")
    abRequire(ident != kABMultiValueInvalidIdentifier, "assigned identifier")
    let atZero: ABMultiValueIdentifier = ABMultiValueGetIdentifierAtIndex(multi, 0)
    abRequire(atZero == ident, "identifier round trip")
    abRequire(ABMultiValueGetIndexForIdentifier(multi, ident) == 0, "index for identifier")
}

func testABRecordIDTypealias() {
    let person = abTake(ABPersonCreate())
    let unsaved: ABRecordID = ABRecordGetRecordID(person)
    abRequire(unsaved == kABRecordInvalidID, "unsaved id")
    let book = abTake(ABAddressBookCreate())
    abRequire(ABAddressBookAddRecord(book, person, nil), "add")
    let saved: ABRecordID = ABRecordGetRecordID(person)
    abRequire(saved != kABRecordInvalidID, "assigned id")
    abRequire(ABAddressBookGetPersonWithRecordID(book, saved) != nil, "lookup by typed id")
}

func testABRecordTypeTypealias() {
    let personType: ABRecordType = ABRecordType(kABPersonType)
    let groupType: ABRecordType = ABRecordType(kABGroupType)
    let sourceType: ABRecordType = ABRecordType(kABSourceType)
    abRequire(ABRecordGetRecordType(abTake(ABPersonCreate())) == personType, "person")
    abRequire(ABRecordGetRecordType(abTake(ABGroupCreate())) == groupType, "group")
    let book = abTake(ABAddressBookCreate())
    abRequire(ABRecordGetRecordType(abPeek(ABAddressBookCopyDefaultSource(book))) == sourceType, "source")
}

func testABPropertyIDTypealias() {
    let first: ABPropertyID = kABPersonFirstNameProperty
    let note: ABPropertyID = kABPersonNoteProperty
    let person = abTake(ABPersonCreate())
    abRequire(ABRecordSetValue(person, first, abCF("Ada"), nil), "set first")
    abRequire(ABRecordSetValue(person, note, abCF("programmer"), nil), "set note")
    abRequire(abAsString(abTake(ABRecordCopyValue(person, first))) == "Ada", "copy first")
    abRequire(ABRecordRemoveValue(person, note, nil), "remove note")
    abRequire(ABRecordCopyValue(person, note) == nil, "note gone")
}

func testABPropertyTypeTypealias() {
    let stringType: ABPropertyType = ABPropertyType(kABStringPropertyType)
    let multiString: ABPropertyType = ABPropertyType(kABMultiStringPropertyType)
    let invalid: ABPropertyType = ABPropertyType(kABInvalidPropertyType)
    abRequire(ABPersonGetTypeOfProperty(kABPersonFirstNameProperty) == stringType, "fn")
    abRequire(ABPersonGetTypeOfProperty(kABPersonEmailProperty) == multiString, "email")
    abRequire(ABPersonGetTypeOfProperty(99) == invalid, "unknown")
    let multi = abTake(ABMultiValueCreateMutable(multiString))
    abRequire(ABMultiValueGetPropertyType(multi) == multiString, "created type")
}

func testABSourceTypeTypealias() {
    let local: ABSourceType = ABSourceType(kABSourceTypeLocal)
    abRequire(local == 0, "local raw")
    let book = abTake(ABAddressBookCreate())
    let source = abPeek(ABAddressBookCopyDefaultSource(book))
    let stored = abTake(ABRecordCopyValue(source, kABSourceTypeProperty))
    abRequire(unsafeBitCast(stored, to: NSNumber.self).intValue == Int(local), "stored local")
}

func testABPersonCompositeNameFormatTypealias() {
    let firstFirst: ABPersonCompositeNameFormat = ABPersonCompositeNameFormat(
        kABPersonCompositeNameFormatFirstNameFirst
    )
    abRequire(ABPersonGetCompositeNameFormat() == firstFirst, "default format")
    let person = abTake(ABPersonCreate())
    _ = ABRecordSetValue(person, kABPersonFirstNameProperty, abCF("Ada"), nil)
    _ = ABRecordSetValue(person, kABPersonLastNameProperty, abCF("Lovelace"), nil)
    abRequire(ABPersonGetCompositeNameFormatForRecord(person) == firstFirst, "record format")
    abRequire(abText(abTake(ABRecordCopyCompositeName(person))) == "Ada Lovelace", "composite")
}

func testABPersonSortOrderingTypealias() {
    let byFirst: ABPersonSortOrdering = ABPersonSortOrdering(kABPersonSortByFirstName)
    let byLast: ABPersonSortOrdering = ABPersonSortOrdering(kABPersonSortByLastName)
    abRequire(ABPersonGetSortOrdering() == byFirst, "default sort")
    let ada = abTake(ABPersonCreate())
    _ = ABRecordSetValue(ada, kABPersonFirstNameProperty, abCF("Ada"), nil)
    _ = ABRecordSetValue(ada, kABPersonLastNameProperty, abCF("Lovelace"), nil)
    let grace = abTake(ABPersonCreate())
    _ = ABRecordSetValue(grace, kABPersonFirstNameProperty, abCF("Grace"), nil)
    _ = ABRecordSetValue(grace, kABPersonLastNameProperty, abCF("Hopper"), nil)
    abRequire(ABPersonComparePeopleByName(ada, grace, byFirst) == .compareLessThan, "first")
    abRequire(ABPersonComparePeopleByName(grace, ada, byLast) == .compareLessThan, "last")
}

func testABAddressBookRequestAccessCompletionHandlerTypealias() {
    let book = abTake(ABAddressBookCreate())
    var granted = true
    var code = -1
    let handler: ABAddressBookRequestAccessCompletionHandler = { success, error in
        granted = success
        if let error {
            code = abNSError(error).code
        }
    }
    ABAddressBookRequestAccessWithCompletion(book, handler)
    abRequire(!granted, "denied")
    abRequire(code == kABOperationNotPermittedByUserError, "user error")
}

func testABExternalChangeCallbackTypealias() {
    let book = abTake(ABAddressBookCreate())
    var fired = false
    let callback: ABExternalChangeCallback = { _, _, _ in
        fired = true
    }
    ABAddressBookRegisterExternalChangeCallback(book, callback, nil)
    ABAddressBookUnregisterExternalChangeCallback(book, callback, nil)
    abRequire(!fired, "never delivered")
}
