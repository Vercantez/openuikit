import Foundation

/// Linux starting implementation of Apple's public `Contacts` module.
///
/// This port provides a documented **local directory** contact store, formatters,
/// vCard 3.0 (RFC 2426) coding, and the public type surface used by the 20-app
/// corpus. It does **not** connect to Apple AddressBook, iCloud, CardDAV,
/// Exchange, or TCC. Authorization succeeds only for that local directory
/// sandbox after `requestAccess`; host address books stay fail-closed.
///
/// Store directory: `$HOME/.local/share/openuikit/contacts/` or
/// `OPENUIKIT_CONTACTS_DIRECTORY`.
///
/// Apple's `CNKeyDescriptor` inherits `NSCopying`, `NSSecureCoding`, and
/// `NSObjectProtocol`. Darwin `String` keys bridge to `NSString`. Linux
/// `String` is a value type and cannot satisfy those class bounds, so the
/// public overlay matches Foundation's class identity: `NSString` conforms,
/// and callers pass `CNContactGivenNameKey as NSString` (or a
/// `CNContactKeyDescriptor`). This is the shared Foundation strategy rather
/// than a second String-shaped descriptor type.

public protocol CNKeyDescriptor: NSObjectProtocol, NSCopying, NSSecureCoding {}

extension NSString: CNKeyDescriptor {}

/// Composite key descriptor returned by formatter / comparator helpers.
public final class CNContactKeyDescriptor: NSObject, CNKeyDescriptor, NSCopying, NSSecureCoding {
    public let keys: [String]

    public init(keys: [String]) {
        self.keys = keys
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        CNContactKeyDescriptor(keys: keys)
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        guard let keys = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: "keys") as? [String]
        else { return nil }
        self.keys = keys
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(keys as NSArray, forKey: "keys")
    }
}

func CNFlattenKeyDescriptors(_ descriptors: [any CNKeyDescriptor]) -> [String] {
    var keys: [String] = []
    for descriptor in descriptors {
        if let composite = descriptor as? CNContactKeyDescriptor {
            keys.append(contentsOf: composite.keys)
        } else if let string = descriptor as? NSString {
            keys.append(string as String)
        }
    }
    return keys
}

extension NSNotification.Name {
    public static let CNContactStoreDidChange = NSNotification.Name("CNContactStoreDidChangeNotification")
}

public enum CNAuthorizationStatus: Int, Sendable, Hashable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorized = 3
    case limited = 4
}

public enum CNContactSortOrder: Int, Sendable, Hashable {
    case none = 0
    case userDefault = 1
    case givenName = 2
    case familyName = 3
}

public enum CNContactType: Int, Sendable, Hashable {
    case person = 0
    case organization = 1
}

public enum CNEntityType: Int, Sendable, Hashable {
    case contacts = 0
}

public enum CNContainerType: Int, Sendable, Hashable {
    case unassigned = 0
    case local = 1
    case exchange = 2
    case cardDAV = 3
}

public enum CNContactDisplayNameOrder: Int, Sendable, Hashable {
    case userDefault = 0
    case givenNameFirst = 1
    case familyNameFirst = 2
}

public enum CNContactFormatterStyle: Int, Sendable, Hashable {
    case fullName = 0
    case phoneticFullName = 1
}

public enum CNPostalAddressFormatterStyle: Int, Sendable, Hashable {
    case mailingAddress = 0
}

func CNLocalizedContactKey(_ key: String) -> String {
    let titles: [String: String] = [
        CNContactIdentifierKey: "Identifier",
        CNContactNamePrefixKey: "Prefix",
        CNContactGivenNameKey: "Given Name",
        CNContactMiddleNameKey: "Middle Name",
        CNContactFamilyNameKey: "Family Name",
        CNContactPreviousFamilyNameKey: "Previous Family Name",
        CNContactNameSuffixKey: "Suffix",
        CNContactNicknameKey: "Nickname",
        CNContactOrganizationNameKey: "Organization",
        CNContactDepartmentNameKey: "Department",
        CNContactJobTitleKey: "Job Title",
        CNContactPhoneticGivenNameKey: "Phonetic Given Name",
        CNContactPhoneticMiddleNameKey: "Phonetic Middle Name",
        CNContactPhoneticFamilyNameKey: "Phonetic Family Name",
        CNContactPhoneticOrganizationNameKey: "Phonetic Organization",
        CNContactBirthdayKey: "Birthday",
        CNContactNonGregorianBirthdayKey: "Non-Gregorian Birthday",
        CNContactNoteKey: "Note",
        CNContactImageDataKey: "Image",
        CNContactThumbnailImageDataKey: "Thumbnail",
        CNContactImageDataAvailableKey: "Image Available",
        CNContactTypeKey: "Type",
        CNContactPhoneNumbersKey: "Phone Numbers",
        CNContactEmailAddressesKey: "Email Addresses",
        CNContactPostalAddressesKey: "Postal Addresses",
        CNContactDatesKey: "Dates",
        CNContactUrlAddressesKey: "URL Addresses",
        CNContactRelationsKey: "Relations",
        CNContactSocialProfilesKey: "Social Profiles",
        CNContactInstantMessageAddressesKey: "Instant Message Addresses",
        CNPostalAddressStreetKey: "Street",
        CNPostalAddressCityKey: "City",
        CNPostalAddressStateKey: "State",
        CNPostalAddressPostalCodeKey: "Postal Code",
        CNPostalAddressCountryKey: "Country",
        CNPostalAddressISOCountryCodeKey: "Country Code",
        CNPostalAddressSubLocalityKey: "Sub Locality",
        CNPostalAddressSubAdministrativeAreaKey: "Sub Administrative Area",
        CNInstantMessageAddressUsernameKey: "Username",
        CNInstantMessageAddressServiceKey: "Service",
        CNSocialProfileURLStringKey: "URL",
        CNSocialProfileUserIdentifierKey: "User Identifier",
    ]
    return titles[key] ?? key
}

func CNLocalizedLabel(_ label: String) -> String {
    var stem = label
    if stem.hasPrefix("_$!<"), stem.hasSuffix(">!$_") {
        stem = String(stem.dropFirst(4).dropLast(4))
    }
    return stem
}

func CNAllContactPropertyKeys() -> [String] {
    [
        CNContactIdentifierKey,
        CNContactNamePrefixKey,
        CNContactGivenNameKey,
        CNContactMiddleNameKey,
        CNContactFamilyNameKey,
        CNContactPreviousFamilyNameKey,
        CNContactNameSuffixKey,
        CNContactNicknameKey,
        CNContactOrganizationNameKey,
        CNContactDepartmentNameKey,
        CNContactJobTitleKey,
        CNContactPhoneticGivenNameKey,
        CNContactPhoneticMiddleNameKey,
        CNContactPhoneticFamilyNameKey,
        CNContactPhoneticOrganizationNameKey,
        CNContactBirthdayKey,
        CNContactNonGregorianBirthdayKey,
        CNContactNoteKey,
        CNContactImageDataKey,
        CNContactThumbnailImageDataKey,
        CNContactImageDataAvailableKey,
        CNContactTypeKey,
        CNContactPhoneNumbersKey,
        CNContactEmailAddressesKey,
        CNContactPostalAddressesKey,
        CNContactDatesKey,
        CNContactUrlAddressesKey,
        CNContactRelationsKey,
        CNContactSocialProfilesKey,
        CNContactInstantMessageAddressesKey,
    ]
}

/// Fail-closed ContactsUI picker stand-in. `CNContactPickerViewController` lives
/// in ContactsUI and requires UIKit. This module does not present a picker and
/// does not fabricate a successful Apple UI session.
open class CNContactPickerViewController: NSObject {
    public override init() {
        super.init()
    }

    open func presentPicker() throws {
        throw CNError(
            .featureNotAvailable,
            userInfo: [CNErrorUserInfoKeyPathsKey: ["CNContactPickerViewController"]]
        )
    }
}
