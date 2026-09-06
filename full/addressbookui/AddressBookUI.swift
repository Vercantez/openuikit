@_exported import Foundation

#if canImport(AddressBook)
@_exported import AddressBook
#endif

// Portable AddressBookUI starting point for Linux.
//
// People-picker property constants match the documented CNContact key
// payloads used by ABPeoplePickerNavigationController predicates. Controllers
// store caller configuration. Linux has no Contacts daemon, TCC prompt, or
// Address Book chrome, so presentation, persistence, and default actions
// stay fail-closed. Isolated host compilation has Foundation only: UIKit
// superclasses apply when that module is importable.

// MARK: - People-picker property keys
//
// These NSString constants are the iOS 8+ predicate keys. Apple documents
// them as corresponding to CNContact keys. Related-names uses
// "relatedNames" (the AddressBook property name); CNContactRelationsKey
// ("contactRelations") is an oracle item.

public let ABPersonNamePrefixProperty = "namePrefix"
public let ABPersonGivenNameProperty = "givenName"
public let ABPersonMiddleNameProperty = "middleName"
public let ABPersonFamilyNameProperty = "familyName"
public let ABPersonPreviousFamilyNameProperty = "previousFamilyName"
public let ABPersonNameSuffixProperty = "nameSuffix"
public let ABPersonNicknameProperty = "nickname"
public let ABPersonOrganizationNameProperty = "organizationName"
public let ABPersonDepartmentNameProperty = "departmentName"
public let ABPersonJobTitleProperty = "jobTitle"
public let ABPersonPhoneticGivenNameProperty = "phoneticGivenName"
public let ABPersonPhoneticMiddleNameProperty = "phoneticMiddleName"
public let ABPersonPhoneticFamilyNameProperty = "phoneticFamilyName"
public let ABPersonBirthdayProperty = "birthday"
public let ABPersonNoteProperty = "note"
public let ABPersonPhoneNumbersProperty = "phoneNumbers"
public let ABPersonEmailAddressesProperty = "emailAddresses"
public let ABPersonUrlAddressesProperty = "urlAddresses"
public let ABPersonDatesProperty = "dates"
public let ABPersonPostalAddressesProperty = "postalAddresses"
public let ABPersonInstantMessageAddressesProperty = "instantMessageAddresses"
public let ABPersonSocialProfilesProperty = "socialProfiles"
public let ABPersonRelatedNamesProperty = "relatedNames"

// MARK: - Address formatting
//
// Formats an AddressBook postal-address dictionary using the documented
// Street / City / State / ZIP / Country / CountryCode keys. Linux does
// not localize country names or apply Apple's locale-specific layout.

public func ABCreateStringWithAddressDictionary(
    _ address: [AnyHashable: Any],
    _ addCountryName: Bool
) -> String {
    let fields = abuiNormalizedAddressFields(address)
    var lines: [String] = []
    if let street = fields["Street"], !street.isEmpty {
        lines.append(street)
    }
    if let cityLine = abuiCityStateZIPLine(fields) {
        lines.append(cityLine)
    }
    if addCountryName {
        if let country = fields["Country"], !country.isEmpty {
            lines.append(country)
        } else if let code = fields["CountryCode"], !code.isEmpty {
            lines.append(code)
        }
    }
    return lines.joined(separator: "\n")
}

func abuiNormalizedAddressFields(_ address: [AnyHashable: Any]) -> [String: String] {
    var fields: [String: String] = [:]
    for (key, value) in address {
        let keyText: String
        if let string = key as? String {
            keyText = string
        } else if let string = key as? NSString {
            keyText = string as String
        } else {
            continue
        }
        let text = abuiStringify(value)
        if !text.isEmpty {
            fields[keyText] = text
        }
    }
    return fields
}

func abuiCityStateZIPLine(_ fields: [String: String]) -> String? {
    let city = fields["City"]
    let state = fields["State"]
    let zip = fields["ZIP"]
    let stateZIP = [state, zip].compactMap { value -> String? in
        guard let value, !value.isEmpty else { return nil }
        return value
    }.joined(separator: " ")
    switch (city, stateZIP.isEmpty) {
    case (nil, true):
        return nil
    case (let city?, true):
        return city.isEmpty ? nil : city
    case (nil, false):
        return stateZIP
    case (let city?, false):
        if city.isEmpty {
            return stateZIP
        }
        return "\(city), \(stateZIP)"
    }
}

func abuiStringify(_ value: Any) -> String {
    if value is NSNull {
        return ""
    }
    if let string = value as? String {
        return string
    }
    if let string = value as? NSString {
        return string as String
    }
    if let number = value as? NSNumber {
        return number.stringValue
    }
    return ""
}

func abuiCopyPredicate(_ predicate: NSPredicate?) -> NSPredicate? {
    guard let predicate else { return nil }
    return predicate.copy() as? NSPredicate
}
