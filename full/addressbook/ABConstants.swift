import CoreFoundation
import Foundation

// Integer constants match the public C headers: property-type bits, record
// types, sort/composite-name formats, source types, and error codes. Person
// property IDs are Linux-stable sequential values in header declaration order;
// Apple's exact dylib integers remain an oracle item.

public var kABInvalidPropertyType: Int { 0 }
public var kABStringPropertyType: Int { 0x1 }
public var kABIntegerPropertyType: Int { 0x2 }
public var kABRealPropertyType: Int { 0x3 }
public var kABDateTimePropertyType: Int { 0x4 }
public var kABDictionaryPropertyType: Int { 0x5 }
public var kABMultiValueMask: Int32 { 1 << 8 }
public var kABMultiStringPropertyType: Int { Int(kABMultiValueMask) | kABStringPropertyType }
public var kABMultiIntegerPropertyType: Int { Int(kABMultiValueMask) | kABIntegerPropertyType }
public var kABMultiRealPropertyType: Int { Int(kABMultiValueMask) | kABRealPropertyType }
public var kABMultiDateTimePropertyType: Int { Int(kABMultiValueMask) | kABDateTimePropertyType }
public var kABMultiDictionaryPropertyType: Int { Int(kABMultiValueMask) | kABDictionaryPropertyType }

public var kABOperationNotPermittedByStoreError: Int { 0 }
public var kABOperationNotPermittedByUserError: Int { 1 }

public var kABPersonCompositeNameFormatFirstNameFirst: Int { 0 }
public var kABPersonCompositeNameFormatLastNameFirst: Int { 1 }

public var kABPersonSortByFirstName: Int { 0 }
public var kABPersonSortByLastName: Int { 1 }

public var kABPersonType: Int { 0 }
public var kABGroupType: Int { 1 }
public var kABSourceType: Int { 2 }

public var kABSourceTypeSearchableMask: Int32 { 0x01000000 }
public var kABSourceTypeLocal: Int { 0x0 }
public var kABSourceTypeExchange: Int { 0x1 }
public var kABSourceTypeExchangeGAL: Int { kABSourceTypeExchange | Int(kABSourceTypeSearchableMask) }
public var kABSourceTypeMobileMe: Int { 0x2 }
public var kABSourceTypeLDAP: Int { 0x3 | Int(kABSourceTypeSearchableMask) }
public var kABSourceTypeCardDAV: Int { 0x4 }
public var kABSourceTypeCardDAVSearch: Int { kABSourceTypeCardDAV | Int(kABSourceTypeSearchableMask) }

public var kABMultiValueInvalidIdentifier: Int32 { -1 }
public var kABPropertyInvalidID: Int32 { -1 }
public var kABRecordInvalidID: Int32 { -1 }

public let kABPersonFirstNameProperty: ABPropertyID = 0
public let kABPersonLastNameProperty: ABPropertyID = 1
public let kABPersonMiddleNameProperty: ABPropertyID = 2
public let kABPersonPrefixProperty: ABPropertyID = 3
public let kABPersonSuffixProperty: ABPropertyID = 4
public let kABPersonNicknameProperty: ABPropertyID = 5
public let kABPersonFirstNamePhoneticProperty: ABPropertyID = 6
public let kABPersonLastNamePhoneticProperty: ABPropertyID = 7
public let kABPersonMiddleNamePhoneticProperty: ABPropertyID = 8
public let kABPersonOrganizationProperty: ABPropertyID = 9
public let kABPersonJobTitleProperty: ABPropertyID = 10
public let kABPersonDepartmentProperty: ABPropertyID = 11
public let kABPersonEmailProperty: ABPropertyID = 12
public let kABPersonBirthdayProperty: ABPropertyID = 13
public let kABPersonNoteProperty: ABPropertyID = 14
public let kABPersonCreationDateProperty: ABPropertyID = 15
public let kABPersonModificationDateProperty: ABPropertyID = 16
public let kABPersonAddressProperty: ABPropertyID = 17
public let kABPersonDateProperty: ABPropertyID = 18
public let kABPersonKindProperty: ABPropertyID = 19
public let kABPersonPhoneProperty: ABPropertyID = 20
public let kABPersonInstantMessageProperty: ABPropertyID = 21
public let kABPersonURLProperty: ABPropertyID = 22
public let kABPersonRelatedNamesProperty: ABPropertyID = 23
public let kABPersonSocialProfileProperty: ABPropertyID = 24
public let kABPersonAlternateBirthdayProperty: ABPropertyID = 25

public let kABGroupNameProperty: Int32 = 0
public let kABSourceNameProperty: ABPropertyID = 0
public let kABSourceTypeProperty: ABPropertyID = 1

func abPersonPropertyType(_ property: ABPropertyID) -> ABPropertyType {
    switch property {
    case kABPersonFirstNameProperty, kABPersonLastNameProperty, kABPersonMiddleNameProperty,
         kABPersonPrefixProperty, kABPersonSuffixProperty, kABPersonNicknameProperty,
         kABPersonFirstNamePhoneticProperty, kABPersonLastNamePhoneticProperty,
         kABPersonMiddleNamePhoneticProperty, kABPersonOrganizationProperty,
         kABPersonJobTitleProperty, kABPersonDepartmentProperty, kABPersonNoteProperty:
        return ABPropertyType(kABStringPropertyType)
    case kABPersonBirthdayProperty, kABPersonCreationDateProperty, kABPersonModificationDateProperty:
        return ABPropertyType(kABDateTimePropertyType)
    case kABPersonKindProperty:
        return ABPropertyType(kABIntegerPropertyType)
    case kABPersonAlternateBirthdayProperty:
        return ABPropertyType(kABDictionaryPropertyType)
    case kABPersonEmailProperty, kABPersonPhoneProperty, kABPersonURLProperty,
         kABPersonRelatedNamesProperty:
        return ABPropertyType(kABMultiStringPropertyType)
    case kABPersonDateProperty:
        return ABPropertyType(kABMultiDateTimePropertyType)
    case kABPersonAddressProperty, kABPersonInstantMessageProperty, kABPersonSocialProfileProperty:
        return ABPropertyType(kABMultiDictionaryPropertyType)
    default:
        return ABPropertyType(kABInvalidPropertyType)
    }
}

func abLocalizedPropertyName(_ property: ABPropertyID) -> String {
    switch property {
    case kABPersonFirstNameProperty: return "First Name"
    case kABPersonLastNameProperty: return "Last Name"
    case kABPersonMiddleNameProperty: return "Middle Name"
    case kABPersonPrefixProperty: return "Prefix"
    case kABPersonSuffixProperty: return "Suffix"
    case kABPersonNicknameProperty: return "Nickname"
    case kABPersonFirstNamePhoneticProperty: return "Phonetic First Name"
    case kABPersonLastNamePhoneticProperty: return "Phonetic Last Name"
    case kABPersonMiddleNamePhoneticProperty: return "Phonetic Middle Name"
    case kABPersonOrganizationProperty: return "Organization"
    case kABPersonJobTitleProperty: return "Job Title"
    case kABPersonDepartmentProperty: return "Department"
    case kABPersonEmailProperty: return "Email"
    case kABPersonBirthdayProperty: return "Birthday"
    case kABPersonNoteProperty: return "Note"
    case kABPersonCreationDateProperty: return "Created"
    case kABPersonModificationDateProperty: return "Modified"
    case kABPersonAddressProperty: return "Address"
    case kABPersonDateProperty: return "Date"
    case kABPersonKindProperty: return "Kind"
    case kABPersonPhoneProperty: return "Phone"
    case kABPersonInstantMessageProperty: return "Instant Message"
    case kABPersonURLProperty: return "URL"
    case kABPersonRelatedNamesProperty: return "Related Names"
    case kABPersonSocialProfileProperty: return "Social Profile"
    case kABPersonAlternateBirthdayProperty: return "Alternate Birthday"
    default: return ""
    }
}
