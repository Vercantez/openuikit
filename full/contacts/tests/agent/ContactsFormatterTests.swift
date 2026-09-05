import Foundation
@_spi(OpenUIKitHost) import Contacts

func testContactFormatter() {
    let contact = makeAdaContact()
    let formatted = CNContactFormatter.string(from: contact, style: .fullName)
    expect(formatted == "Ms Ada Byron Lovelace Countess", "full name \(String(describing: formatted))")
    let phonetic = CNContactFormatter.string(from: contact, style: .phoneticFullName)
    expect(phonetic == "Ay-duh By-ron Love-lace", "phonetic \(String(describing: phonetic))")
    expect(CNContactFormatter.nameOrder(for: contact) == .givenNameFirst, "name order")
    expect(CNContactFormatter.delimiter(for: contact) == " ", "delimiter")
    expect(
        CNContactFormatter.attributedString(from: contact, style: .fullName)?.string == "Ms Ada Byron Lovelace Countess",
        "attributed name"
    )
    let formatter = CNContactFormatter()
    formatter.style = .fullName
    expect(formatter.style == .fullName, "formatter style property")
    expect(formatter.string(from: contact) == "Ms Ada Byron Lovelace Countess", "instance formatter")
    expect(formatter.attributedString(from: contact)?.string == "Ms Ada Byron Lovelace Countess", "instance attributed")
    _ = CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
    _ = CNContactFormatter.descriptorForRequiredKeysForDelimiter
    _ = CNContactFormatter.descriptorForRequiredKeysForNameOrder

    let nicknameOnly = CNMutableContact()
    nicknameOnly.nickname = "OnlyNick"
    expect(CNContactFormatter.string(from: nicknameOnly, style: .fullName) == "OnlyNick", "nickname fallback")
    let orgOnly = CNMutableContact()
    orgOnly.contactType = .organization
    orgOnly.organizationName = "Analytical Co"
    expect(CNContactFormatter.string(from: orgOnly, style: .fullName) == "Analytical Co", "organization fallback")
}

func testPostalAddressFormatter() {
    let postal = CNMutablePostalAddress()
    postal.street = "12 Great Street"
    postal.city = "London"
    postal.state = "England"
    postal.postalCode = "SW1A"
    postal.country = "United Kingdom"
    postal.isoCountryCode = "GB"
    postal.subLocality = "Westminster"
    postal.subAdministrativeArea = "Greater London"
    let mailing = CNPostalAddressFormatter.string(from: postal, style: .mailingAddress)
    expect(mailing.contains("12 Great Street"), "street in mailing")
    expect(mailing.contains("London"), "city in mailing")
    let postalFormatter = CNPostalAddressFormatter()
    expect(postalFormatter.style == .mailingAddress, "default postal style")
    postalFormatter.style = .mailingAddress
    expect(postalFormatter.string(from: postal).contains("United Kingdom"), "instance postal")
    expect(
        CNPostalAddressFormatter.attributedString(
            from: postal,
            style: .mailingAddress
        ).string.contains("SW1A"),
        "attributed postal"
    )
    expect(
        postalFormatter.attributedString(from: postal).string.contains("London"),
        "instance attributed postal"
    )
    expect(CNPostalAddress.localizedString(forKey: CNPostalAddressCityKey) == "City", "city title")

    let usAddress = CNMutablePostalAddress()
    usAddress.street = "1 Market St"
    usAddress.city = "San Francisco"
    usAddress.state = "CA"
    usAddress.postalCode = "94105"
    usAddress.country = "United States"
    usAddress.isoCountryCode = "US"
    let usMailing = CNPostalAddressFormatter.string(from: usAddress, style: .mailingAddress)
    expect(usMailing.contains("San Francisco, CA 94105"), "US city/state/ZIP layout \(usMailing)")
}
