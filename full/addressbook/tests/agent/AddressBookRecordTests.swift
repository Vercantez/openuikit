import AddressBook
import CoreFoundation
import Foundation

func testMultiValueCreateAndRead() {
    let multi = abTake(ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType)))
    abRequire(ABMultiValueGetPropertyType(multi) == ABPropertyType(kABMultiStringPropertyType), "type")
    abRequire(ABMultiValueGetCount(multi) == 0, "empty count")

    var firstID = kABMultiValueInvalidIdentifier
    abRequire(
        ABMultiValueAddValueAndLabel(multi, abCF("ada@example.com"), kABHomeLabel, &firstID),
        "add home"
    )
    var workID = kABMultiValueInvalidIdentifier
    abRequire(
        ABMultiValueAddValueAndLabel(multi, abCF("ada@work.example"), kABWorkLabel, &workID),
        "add work"
    )
    abRequire(ABMultiValueGetCount(multi) == 2, "count 2")

    let homeValue = abTake(ABMultiValueCopyValueAtIndex(multi, 0))
    abRequire(abAsString(homeValue) == "ada@example.com", "value 0")
    let homeLabel = abTake(ABMultiValueCopyLabelAtIndex(multi, 0))
    abRequire(abText(homeLabel) == "_$!<Home>!$_", "label 0")
    abRequire(ABMultiValueCopyValueAtIndex(multi, 9) == nil, "oob value")
    abRequire(ABMultiValueCopyLabelAtIndex(multi, 9) == nil, "oob label")

    let values = abNSArray(abTake(ABMultiValueCopyArrayOfAllValues(multi)))
    abRequire(values.count == 2, "all values")
}

func testMultiValueMutate() {
    let multi = abTake(ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType)))
    var firstID = kABMultiValueInvalidIdentifier
    abRequire(
        ABMultiValueAddValueAndLabel(multi, abCF("ada@example.com"), kABHomeLabel, &firstID),
        "add home"
    )
    var workID = kABMultiValueInvalidIdentifier
    abRequire(
        ABMultiValueAddValueAndLabel(multi, abCF("ada@work.example"), kABWorkLabel, &workID),
        "add work"
    )
    var insertedID = kABMultiValueInvalidIdentifier
    abRequire(
        ABMultiValueInsertValueAndLabelAtIndex(
            multi,
            abCF("ada@other.example"),
            kABOtherLabel,
            1,
            &insertedID
        ),
        "insert"
    )
    abRequire(ABMultiValueGetCount(multi) == 3, "count 3")
    abRequire(ABMultiValueReplaceValueAtIndex(multi, abCF("replaced@example.com"), 0), "replace value")
    abRequire(ABMultiValueReplaceLabelAtIndex(multi, kABWorkLabel, 0), "replace label")
    abRequire(ABMultiValueRemoveValueAndLabelAtIndex(multi, 2), "remove")
    abRequire(ABMultiValueGetCount(multi) == 2, "count after remove")
    abRequire(!ABMultiValueRemoveValueAndLabelAtIndex(multi, 9), "remove oob")

    let copy = abTake(ABMultiValueCreateMutableCopy(multi))
    abRequire(ABMultiValueGetCount(copy) == 2, "copy count")
    var copyID = kABMultiValueInvalidIdentifier
    abRequire(ABMultiValueAddValueAndLabel(copy, abCF("copy-only"), kABOtherLabel, &copyID), "copy mutate")
    abRequire(ABMultiValueGetCount(multi) == 2, "original unchanged")
}

func testMultiValueIdentifiers() {
    let multi = abTake(ABMultiValueCreateMutable(ABPropertyType(kABMultiStringPropertyType)))
    var firstID = kABMultiValueInvalidIdentifier
    abRequire(
        ABMultiValueAddValueAndLabel(multi, abCF("ada@example.com"), kABHomeLabel, &firstID),
        "add home"
    )
    var workID = kABMultiValueInvalidIdentifier
    abRequire(
        ABMultiValueAddValueAndLabel(multi, abCF("ada@work.example"), kABWorkLabel, &workID),
        "add work"
    )
    abRequire(firstID == 0, "first identifier")
    abRequire(ABMultiValueGetIdentifierAtIndex(multi, 1) == workID, "id at 1")
    abRequire(ABMultiValueGetIndexForIdentifier(multi, firstID) == 0, "index for first")
    abRequire(ABMultiValueGetIndexForIdentifier(multi, 99) == -1, "missing identifier")
    abRequire(ABMultiValueGetFirstIndexOfValue(multi, abCF("ada@work.example")) == 1, "first index")
    abRequire(ABMultiValueGetFirstIndexOfValue(multi, abCF("missing")) == -1, "missing value")
}

func testRecordIdentity() {
    let person = abTake(ABPersonCreate())
    abRequire(ABRecordGetRecordID(person) == kABRecordInvalidID, "unsaved id")
    abRequire(ABRecordGetRecordType(person) == ABRecordType(kABPersonType), "person type")
}

func testRecordSetCopyRemove() {
    let person = abFreshPerson()
    abRequire(
        ABRecordSetValue(person, kABPersonFirstNameProperty, abCF("Ada"), nil),
        "set first"
    )
    abRequire(
        ABRecordSetValue(person, kABPersonLastNameProperty, abCF("Lovelace"), nil),
        "set last"
    )
    abRequire(
        ABRecordSetValue(person, kABPersonNicknameProperty, abCF("Ada"), nil),
        "set nick"
    )
    let copied = abTake(ABRecordCopyValue(person, kABPersonFirstNameProperty))
    abRequire(abAsString(copied) == "Ada", "copy first")
    abRequire(ABRecordCopyValue(person, kABPersonNoteProperty) == nil, "missing note")
    abRequire(ABRecordRemoveValue(person, kABPersonNicknameProperty, nil), "remove nick")
    abRequire(ABRecordCopyValue(person, kABPersonNicknameProperty) == nil, "nick gone")
    abRequire(!ABRecordSetValue(nil, kABPersonFirstNameProperty, abCF("X"), nil), "nil record")
}

func testCompositeName() {
    let person = abFreshPerson()
    _ = ABRecordSetValue(person, kABPersonPrefixProperty, abCF("Ms"), nil)
    _ = ABRecordSetValue(person, kABPersonFirstNameProperty, abCF("Ada"), nil)
    _ = ABRecordSetValue(person, kABPersonMiddleNameProperty, abCF("Byron"), nil)
    _ = ABRecordSetValue(person, kABPersonLastNameProperty, abCF("Lovelace"), nil)
    _ = ABRecordSetValue(person, kABPersonSuffixProperty, abCF("Countess"), nil)
    let name = abTake(ABRecordCopyCompositeName(person))
    abRequire(abText(name) == "Ms Ada Byron Lovelace Countess", "first-first name")
    abRequire(
        ABPersonGetCompositeNameFormat() == ABPersonCompositeNameFormat(kABPersonCompositeNameFormatFirstNameFirst),
        "default format"
    )
    abRequire(
        ABPersonGetCompositeNameFormatForRecord(person)
            == ABPersonCompositeNameFormat(kABPersonCompositeNameFormatFirstNameFirst),
        "record format"
    )
    let delimiter = abTake(ABPersonCopyCompositeNameDelimiterForRecord(person))
    abRequire(abText(delimiter) == " ", "delimiter")

    let org = abFreshPerson()
    _ = ABRecordSetValue(org, kABPersonKindProperty, kABPersonKindOrganization, nil)
    _ = ABRecordSetValue(org, kABPersonOrganizationProperty, abCF("Analytical Engines"), nil)
    let orgName = abTake(ABRecordCopyCompositeName(org))
    abRequire(abText(orgName) == "Analytical Engines", "org composite")
}
