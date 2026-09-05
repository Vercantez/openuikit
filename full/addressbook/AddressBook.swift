import CoreFoundation
import Foundation

// MARK: - Typealiases (Clang overlay of AddressBookRef / related CF types)

public typealias ABAddressBook = CFTypeRef
public typealias ABRecord = CFTypeRef
public typealias ABMultiValue = CFTypeRef
public typealias ABMutableMultiValue = CFTypeRef
public typealias ABMultiValueIdentifier = Int32
public typealias ABPersonCompositeNameFormat = UInt32
public typealias ABPersonSortOrdering = UInt32
public typealias ABPropertyID = Int32
public typealias ABPropertyType = UInt32
public typealias ABRecordID = Int32
public typealias ABRecordType = UInt32
public typealias ABSourceType = Int32

public typealias ABAddressBookRequestAccessCompletionHandler = (Bool, CFError?) -> Void
public typealias ABExternalChangeCallback = (
    ABAddressBook?, CFDictionary?, UnsafeMutableRawPointer?
) -> Void

// MARK: - Bridged enumerations

/// `CF_ENUM(CFIndex, ABAuthorizationStatus)` overlay. Raw values follow the
/// public AddressBook header order (`notDetermined = 0` … `authorized = 3`).
public enum ABAuthorizationStatus: CFIndex, Sendable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorized = 3
}

/// `CF_ENUM(uint32_t, ABPersonImageFormat)` imported as a struct. Thumbnail is
/// 0 and original size is 2; there is no public member for 1.
public struct ABPersonImageFormat: RawRepresentable, Hashable, Equatable, Sendable {
    public var rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: UInt32) {
        self.rawValue = rawValue
    }
}

public var kABPersonImageFormatThumbnail: ABPersonImageFormat {
    ABPersonImageFormat(rawValue: 0)
}

public var kABPersonImageFormatOriginalSize: ABPersonImageFormat {
    ABPersonImageFormat(rawValue: 2)
}

// MARK: - Error domain

/// Documented AddressBook error domain. Linux fail-closed errors use this
/// domain with `kABOperationNotPermittedByUserError` or
/// `kABOperationNotPermittedByStoreError`.
public let ABAddressBookErrorDomain: CFString! = abCFString("ABAddressBookErrorDomain")

// MARK: - Shared labels (documented `_$!<Label>!$_` / iPhone payloads)

public let kABHomeLabel: CFString! = abCFString("_$!<Home>!$_")
public let kABWorkLabel: CFString! = abCFString("_$!<Work>!$_")
public let kABOtherLabel: CFString! = abCFString("_$!<Other>!$_")

public let kABPersonAnniversaryLabel: CFString! = abCFString("_$!<Anniversary>!$_")
public let kABPersonAssistantLabel: CFString! = abCFString("_$!<Assistant>!$_")
public let kABPersonBrotherLabel: CFString! = abCFString("_$!<Brother>!$_")
public let kABPersonChildLabel: CFString! = abCFString("_$!<Child>!$_")
public let kABPersonFatherLabel: CFString! = abCFString("_$!<Father>!$_")
public let kABPersonFriendLabel: CFString! = abCFString("_$!<Friend>!$_")
public let kABPersonHomePageLabel: CFString! = abCFString("_$!<HomePage>!$_")
public let kABPersonManagerLabel: CFString! = abCFString("_$!<Manager>!$_")
public let kABPersonMotherLabel: CFString! = abCFString("_$!<Mother>!$_")
public let kABPersonParentLabel: CFString! = abCFString("_$!<Parent>!$_")
public let kABPersonPartnerLabel: CFString! = abCFString("_$!<Partner>!$_")
public let kABPersonSisterLabel: CFString! = abCFString("_$!<Sister>!$_")
public let kABPersonSpouseLabel: CFString! = abCFString("_$!<Spouse>!$_")

public let kABPersonPhoneHomeFAXLabel: CFString! = abCFString("_$!<HomeFAX>!$_")
public let kABPersonPhoneIPhoneLabel: CFString! = abCFString("iPhone")
public let kABPersonPhoneMainLabel: CFString! = abCFString("_$!<Main>!$_")
public let kABPersonPhoneMobileLabel: CFString! = abCFString("_$!<Mobile>!$_")
public let kABPersonPhoneOtherFAXLabel: CFString! = abCFString("_$!<OtherFAX>!$_")
public let kABPersonPhonePagerLabel: CFString! = abCFString("_$!<Pager>!$_")
public let kABPersonPhoneWorkFAXLabel: CFString! = abCFString("_$!<WorkFAX>!$_")

// MARK: - Address dictionary keys

public let kABPersonAddressCityKey: CFString! = abCFString("City")
public let kABPersonAddressCountryCodeKey: CFString! = abCFString("CountryCode")
public let kABPersonAddressCountryKey: CFString! = abCFString("Country")
public let kABPersonAddressStateKey: CFString! = abCFString("State")
public let kABPersonAddressStreetKey: CFString! = abCFString("Street")
public let kABPersonAddressZIPKey: CFString! = abCFString("ZIP")

// MARK: - Alternate birthday dictionary keys

public let kABPersonAlternateBirthdayCalendarIdentifierKey: CFString! = abCFString("calendarIdentifier")
public let kABPersonAlternateBirthdayDayKey: CFString! = abCFString("day")
public let kABPersonAlternateBirthdayEraKey: CFString! = abCFString("era")
public let kABPersonAlternateBirthdayIsLeapMonthKey: CFString! = abCFString("isLeapMonth")
public let kABPersonAlternateBirthdayMonthKey: CFString! = abCFString("month")
public let kABPersonAlternateBirthdayYearKey: CFString! = abCFString("year")

// MARK: - Instant-message dictionary keys and services

public let kABPersonInstantMessageServiceKey: CFString! = abCFString("service")
public let kABPersonInstantMessageUsernameKey: CFString! = abCFString("username")
public let kABPersonInstantMessageServiceAIM: CFString! = abCFString("AIM")
public let kABPersonInstantMessageServiceFacebook: CFString! = abCFString("Facebook")
public let kABPersonInstantMessageServiceGaduGadu: CFString! = abCFString("GaduGadu")
public let kABPersonInstantMessageServiceGoogleTalk: CFString! = abCFString("GoogleTalk")
public let kABPersonInstantMessageServiceICQ: CFString! = abCFString("ICQ")
public let kABPersonInstantMessageServiceJabber: CFString! = abCFString("Jabber")
public let kABPersonInstantMessageServiceMSN: CFString! = abCFString("MSN")
public let kABPersonInstantMessageServiceQQ: CFString! = abCFString("QQ")
public let kABPersonInstantMessageServiceSkype: CFString! = abCFString("Skype")
public let kABPersonInstantMessageServiceYahoo: CFString! = abCFString("Yahoo")

// MARK: - Social-profile dictionary keys and services

public let kABPersonSocialProfileURLKey: CFString! = abCFString("url")
public let kABPersonSocialProfileServiceKey: CFString! = abCFString("service")
public let kABPersonSocialProfileUsernameKey: CFString! = abCFString("username")
public let kABPersonSocialProfileUserIdentifierKey: CFString! = abCFString("userid")
public let kABPersonSocialProfileServiceFacebook: CFString! = abCFString("Facebook")
public let kABPersonSocialProfileServiceFlickr: CFString! = abCFString("Flickr")
public let kABPersonSocialProfileServiceGameCenter: CFString! = abCFString("GameCenter")
public let kABPersonSocialProfileServiceLinkedIn: CFString! = abCFString("LinkedIn")
public let kABPersonSocialProfileServiceMyspace: CFString! = abCFString("Myspace")
public let kABPersonSocialProfileServiceSinaWeibo: CFString! = abCFString("SinaWeibo")
public let kABPersonSocialProfileServiceTwitter: CFString! = abCFString("Twitter")

// MARK: - Person kind numbers

public let kABPersonKindPerson: CFNumber! = abCFNumber(0)
public let kABPersonKindOrganization: CFNumber! = abCFNumber(1)

func abCFString(_ value: String) -> CFString {
    unsafeBitCast(value as NSString, to: CFString.self)
}

func abCFNumber(_ value: Int) -> CFNumber {
    unsafeBitCast(NSNumber(value: value), to: CFNumber.self)
}

func abString(_ value: CFString?) -> String? {
    guard let value else { return nil }
    return unsafeBitCast(value, to: NSString.self) as String
}

func abStringValue(_ value: CFTypeRef?) -> String? {
    guard let value else { return nil }
    if let string = value as? NSString {
        return string as String
    }
    if CFGetTypeID(value) == CFStringGetTypeID() {
        return unsafeBitCast(value, to: NSString.self) as String
    }
    return nil
}

func abObject(_ value: CFTypeRef?) -> NSObject? {
    value as? NSObject
}

func abWriteError(
    _ slot: UnsafeMutablePointer<Unmanaged<CFError>?>?,
    code: Int
) {
    guard let slot else { return }
    let nsError = NSError(
        domain: "ABAddressBookErrorDomain",
        code: code,
        userInfo: nil
    )
    slot.pointee = Unmanaged.passRetained(unsafeBitCast(nsError, to: CFError.self))
}

func abPassRetainedArray(_ objects: [AnyObject]) -> Unmanaged<CFArray> {
    let array = objects as NSArray
    return Unmanaged.passRetained(unsafeBitCast(array, to: CFArray.self))
}

func abPassRetainedString(_ value: String) -> Unmanaged<CFString> {
    Unmanaged.passRetained(abCFString(value))
}

func abPassRetainedData(_ data: Data) -> Unmanaged<CFData> {
    Unmanaged.passRetained(unsafeBitCast(data as NSData, to: CFData.self))
}

func abData(_ value: CFData?) -> Data? {
    guard let value else { return nil }
    return unsafeBitCast(value, to: NSData.self) as Data
}
