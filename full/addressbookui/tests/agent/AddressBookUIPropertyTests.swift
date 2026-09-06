import Foundation
import AddressBookUI

func testPersonPropertyConstants() {
    let rows: [(String, String)] = [
        (ABPersonNamePrefixProperty, "namePrefix"),
        (ABPersonGivenNameProperty, "givenName"),
        (ABPersonMiddleNameProperty, "middleName"),
        (ABPersonFamilyNameProperty, "familyName"),
        (ABPersonPreviousFamilyNameProperty, "previousFamilyName"),
        (ABPersonNameSuffixProperty, "nameSuffix"),
        (ABPersonNicknameProperty, "nickname"),
        (ABPersonOrganizationNameProperty, "organizationName"),
        (ABPersonDepartmentNameProperty, "departmentName"),
        (ABPersonJobTitleProperty, "jobTitle"),
        (ABPersonPhoneticGivenNameProperty, "phoneticGivenName"),
        (ABPersonPhoneticMiddleNameProperty, "phoneticMiddleName"),
        (ABPersonPhoneticFamilyNameProperty, "phoneticFamilyName"),
        (ABPersonBirthdayProperty, "birthday"),
        (ABPersonNoteProperty, "note"),
        (ABPersonPhoneNumbersProperty, "phoneNumbers"),
        (ABPersonEmailAddressesProperty, "emailAddresses"),
        (ABPersonUrlAddressesProperty, "urlAddresses"),
        (ABPersonDatesProperty, "dates"),
        (ABPersonPostalAddressesProperty, "postalAddresses"),
        (ABPersonInstantMessageAddressesProperty, "instantMessageAddresses"),
        (ABPersonSocialProfilesProperty, "socialProfiles"),
        (ABPersonRelatedNamesProperty, "relatedNames"),
    ]
    precondition(rows.count == 23)
    for (actual, expected) in rows {
        precondition(actual == expected)
        precondition(!actual.isEmpty)
    }
    precondition(ABPersonGivenNameProperty != ABPersonFamilyNameProperty)
    precondition(Set(rows.map(\.0)).count == 23)
}
