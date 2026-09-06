import AddressBook
import CoreFoundation
import Foundation

func abRequire(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func abTake<T: AnyObject>(_ unmanaged: Unmanaged<T>?) -> T {
    unmanaged!.takeRetainedValue()
}

func abPeek<T: AnyObject>(_ unmanaged: Unmanaged<T>?) -> T {
    unmanaged!.takeUnretainedValue()
}

func abText(_ value: CFString?) -> String {
    guard let value else { return "" }
    return unsafeBitCast(value, to: NSString.self) as String
}

func abCF(_ value: String) -> CFString {
    unsafeBitCast(value as NSString, to: CFString.self)
}

func abNSArray(_ value: CFArray) -> NSArray {
    unsafeBitCast(value, to: NSArray.self)
}

func abNSData(_ value: CFData) -> Data {
    unsafeBitCast(value, to: NSData.self) as Data
}

func abCFData(_ value: Data) -> CFData {
    unsafeBitCast(value as NSData, to: CFData.self)
}

func abCFArray(_ value: NSArray) -> CFArray {
    unsafeBitCast(value, to: CFArray.self)
}

func abAsString(_ value: CFTypeRef) -> String {
    unsafeBitCast(value, to: NSString.self) as String
}

func abNSError(_ value: CFError) -> NSError {
    unsafeBitCast(value, to: NSError.self)
}

func abFreshBook() -> ABAddressBook {
    abTake(ABAddressBookCreate())
}

func abFreshPerson() -> ABRecord {
    abTake(ABPersonCreate())
}

func testConstantCatalog() {
    abRequire(ABAuthorizationStatus.notDetermined.rawValue == 0, "auth notDetermined")
    abRequire(ABAuthorizationStatus.restricted.rawValue == 1, "auth restricted")
    abRequire(ABAuthorizationStatus.denied.rawValue == 2, "auth denied")
    abRequire(ABAuthorizationStatus.authorized.rawValue == 3, "auth authorized")
    abRequire(ABAuthorizationStatus(rawValue: 0) == .notDetermined, "auth init 0")

    abRequire(kABPersonImageFormatThumbnail.rawValue == 0, "thumb")
    abRequire(kABPersonImageFormatOriginalSize.rawValue == 2, "original")

    abRequire(kABInvalidPropertyType == 0, "invalid type")
    abRequire(kABStringPropertyType == 1, "string type")
    abRequire(kABIntegerPropertyType == 2, "integer type")
    abRequire(kABRealPropertyType == 3, "real type")
    abRequire(kABDateTimePropertyType == 4, "datetime type")
    abRequire(kABDictionaryPropertyType == 5, "dict type")
    abRequire(kABMultiValueMask == 256, "multi mask")
    abRequire(kABMultiStringPropertyType == 257, "multi string")
    abRequire(kABMultiIntegerPropertyType == 258, "multi int")
    abRequire(kABMultiRealPropertyType == 259, "multi real")
    abRequire(kABMultiDateTimePropertyType == 260, "multi date")
    abRequire(kABMultiDictionaryPropertyType == 261, "multi dict")

    abRequire(kABOperationNotPermittedByStoreError == 0, "store error")
    abRequire(kABOperationNotPermittedByUserError == 1, "user error")

    abRequire(kABPersonCompositeNameFormatFirstNameFirst == 0, "fnf")
    abRequire(kABPersonCompositeNameFormatLastNameFirst == 1, "lnf")
    abRequire(kABPersonSortByFirstName == 0, "sort first")
    abRequire(kABPersonSortByLastName == 1, "sort last")
    abRequire(kABPersonType == 0, "person type")
    abRequire(kABGroupType == 1, "group type")
    abRequire(kABSourceType == 2, "source type")

    abRequire(kABSourceTypeLocal == 0, "src local")
    abRequire(kABSourceTypeExchange == 1, "src exchange")
    abRequire(kABSourceTypeExchangeGAL == 0x01000001, "src gal")
    abRequire(kABSourceTypeMobileMe == 2, "src mobileme")
    abRequire(kABSourceTypeLDAP == 0x01000003, "src ldap")
    abRequire(kABSourceTypeCardDAV == 4, "src carddav")
    abRequire(kABSourceTypeCardDAVSearch == 0x01000004, "src carddav search")
    abRequire(kABSourceTypeSearchableMask == 0x01000000, "search mask")

    abRequire(kABMultiValueInvalidIdentifier == -1, "mv invalid")
    abRequire(kABPropertyInvalidID == -1, "prop invalid")
    abRequire(kABRecordInvalidID == -1, "rec invalid")

    abRequire(kABPersonFirstNameProperty == 0, "fn")
    abRequire(kABPersonLastNameProperty == 1, "ln")
    abRequire(kABPersonMiddleNameProperty == 2, "mn")
    abRequire(kABPersonPrefixProperty == 3, "prefix")
    abRequire(kABPersonSuffixProperty == 4, "suffix")
    abRequire(kABPersonNicknameProperty == 5, "nick")
    abRequire(kABPersonFirstNamePhoneticProperty == 6, "fn p")
    abRequire(kABPersonLastNamePhoneticProperty == 7, "ln p")
    abRequire(kABPersonMiddleNamePhoneticProperty == 8, "mn p")
    abRequire(kABPersonOrganizationProperty == 9, "org")
    abRequire(kABPersonJobTitleProperty == 10, "title")
    abRequire(kABPersonDepartmentProperty == 11, "dept")
    abRequire(kABPersonEmailProperty == 12, "email")
    abRequire(kABPersonBirthdayProperty == 13, "bday")
    abRequire(kABPersonNoteProperty == 14, "note")
    abRequire(kABPersonCreationDateProperty == 15, "created")
    abRequire(kABPersonModificationDateProperty == 16, "modified")
    abRequire(kABPersonAddressProperty == 17, "addr")
    abRequire(kABPersonDateProperty == 18, "date")
    abRequire(kABPersonKindProperty == 19, "kind")
    abRequire(kABPersonPhoneProperty == 20, "phone")
    abRequire(kABPersonInstantMessageProperty == 21, "im")
    abRequire(kABPersonURLProperty == 22, "url")
    abRequire(kABPersonRelatedNamesProperty == 23, "related")
    abRequire(kABPersonSocialProfileProperty == 24, "social")
    abRequire(kABPersonAlternateBirthdayProperty == 25, "alt bday")
    abRequire(kABGroupNameProperty == 0, "group name")
    abRequire(kABSourceNameProperty == 0, "source name")
    abRequire(kABSourceTypeProperty == 1, "source type prop")

    let strings: [(CFString?, String)] = [
        (kABHomeLabel, "_$!<Home>!$_"),
        (kABWorkLabel, "_$!<Work>!$_"),
        (kABOtherLabel, "_$!<Other>!$_"),
        (kABPersonAnniversaryLabel, "_$!<Anniversary>!$_"),
        (kABPersonAssistantLabel, "_$!<Assistant>!$_"),
        (kABPersonBrotherLabel, "_$!<Brother>!$_"),
        (kABPersonChildLabel, "_$!<Child>!$_"),
        (kABPersonFatherLabel, "_$!<Father>!$_"),
        (kABPersonFriendLabel, "_$!<Friend>!$_"),
        (kABPersonHomePageLabel, "_$!<HomePage>!$_"),
        (kABPersonManagerLabel, "_$!<Manager>!$_"),
        (kABPersonMotherLabel, "_$!<Mother>!$_"),
        (kABPersonParentLabel, "_$!<Parent>!$_"),
        (kABPersonPartnerLabel, "_$!<Partner>!$_"),
        (kABPersonSisterLabel, "_$!<Sister>!$_"),
        (kABPersonSpouseLabel, "_$!<Spouse>!$_"),
        (kABPersonPhoneHomeFAXLabel, "_$!<HomeFAX>!$_"),
        (kABPersonPhoneIPhoneLabel, "iPhone"),
        (kABPersonPhoneMainLabel, "_$!<Main>!$_"),
        (kABPersonPhoneMobileLabel, "_$!<Mobile>!$_"),
        (kABPersonPhoneOtherFAXLabel, "_$!<OtherFAX>!$_"),
        (kABPersonPhonePagerLabel, "_$!<Pager>!$_"),
        (kABPersonPhoneWorkFAXLabel, "_$!<WorkFAX>!$_"),
        (kABPersonAddressCityKey, "City"),
        (kABPersonAddressCountryCodeKey, "CountryCode"),
        (kABPersonAddressCountryKey, "Country"),
        (kABPersonAddressStateKey, "State"),
        (kABPersonAddressStreetKey, "Street"),
        (kABPersonAddressZIPKey, "ZIP"),
        (kABPersonAlternateBirthdayCalendarIdentifierKey, "calendarIdentifier"),
        (kABPersonAlternateBirthdayDayKey, "day"),
        (kABPersonAlternateBirthdayEraKey, "era"),
        (kABPersonAlternateBirthdayIsLeapMonthKey, "isLeapMonth"),
        (kABPersonAlternateBirthdayMonthKey, "month"),
        (kABPersonAlternateBirthdayYearKey, "year"),
        (kABPersonInstantMessageServiceKey, "service"),
        (kABPersonInstantMessageUsernameKey, "username"),
        (kABPersonInstantMessageServiceAIM, "AIM"),
        (kABPersonInstantMessageServiceFacebook, "Facebook"),
        (kABPersonInstantMessageServiceGaduGadu, "GaduGadu"),
        (kABPersonInstantMessageServiceGoogleTalk, "GoogleTalk"),
        (kABPersonInstantMessageServiceICQ, "ICQ"),
        (kABPersonInstantMessageServiceJabber, "Jabber"),
        (kABPersonInstantMessageServiceMSN, "MSN"),
        (kABPersonInstantMessageServiceQQ, "QQ"),
        (kABPersonInstantMessageServiceSkype, "Skype"),
        (kABPersonInstantMessageServiceYahoo, "Yahoo"),
        (kABPersonSocialProfileURLKey, "url"),
        (kABPersonSocialProfileServiceKey, "service"),
        (kABPersonSocialProfileUsernameKey, "username"),
        (kABPersonSocialProfileUserIdentifierKey, "userid"),
        (kABPersonSocialProfileServiceFacebook, "Facebook"),
        (kABPersonSocialProfileServiceFlickr, "Flickr"),
        (kABPersonSocialProfileServiceGameCenter, "GameCenter"),
        (kABPersonSocialProfileServiceLinkedIn, "LinkedIn"),
        (kABPersonSocialProfileServiceMyspace, "Myspace"),
        (kABPersonSocialProfileServiceSinaWeibo, "SinaWeibo"),
        (kABPersonSocialProfileServiceTwitter, "Twitter"),
    ]
    for (constant, expected) in strings {
        abRequire(abText(constant) == expected, expected)
    }

    abRequire(unsafeBitCast(kABPersonKindPerson, to: NSNumber.self).intValue == 0, "kind person")
    abRequire(unsafeBitCast(kABPersonKindOrganization, to: NSNumber.self).intValue == 1, "kind org")
}

func testAuthorizationStatusHashableAndEquatable() {
    abRequire(ABAuthorizationStatus.denied != .authorized, "auth !=")
    abRequire(ABAuthorizationStatus.denied == .denied, "auth ==")
    abRequire(ABAuthorizationStatus.denied.hashValue == ABAuthorizationStatus.denied.hashValue, "auth hashValue")
    var hasher = Hasher()
    ABAuthorizationStatus.restricted.hash(into: &hasher)
    _ = hasher.finalize()
    abRequire(ABAuthorizationStatus(rawValue: 2) == .denied, "auth raw 2")
    abRequire(ABAuthorizationStatus(rawValue: 99) == nil, "auth raw nil")
}

func testPersonImageFormatHashableAndEquatable() {
    let thumb = ABPersonImageFormat(rawValue: 0)
    let original = ABPersonImageFormat(2)
    abRequire(thumb != original, "format !=")
    abRequire(thumb == kABPersonImageFormatThumbnail, "format ==")
    abRequire(thumb.hashValue == kABPersonImageFormatThumbnail.hashValue, "format hashValue")
    var formatHasher = Hasher()
    original.hash(into: &formatHasher)
    _ = formatHasher.finalize()
    abRequire(original.rawValue == 2, "format rawValue")
}
