import Foundation

open class CNContactFormatter: NSObject {
    public var style: CNContactFormatterStyle = .fullName

    public override init() {
        super.init()
    }

    open class var descriptorForRequiredKeysForDelimiter: any CNKeyDescriptor {
        CNContactKeyDescriptor(keys: [CNContactGivenNameKey, CNContactFamilyNameKey])
    }

    open class var descriptorForRequiredKeysForNameOrder: any CNKeyDescriptor {
        CNContactKeyDescriptor(keys: [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactOrganizationNameKey,
            CNContactTypeKey,
        ])
    }

    open class func descriptorForRequiredKeys(for style: CNContactFormatterStyle) -> any CNKeyDescriptor {
        switch style {
        case .fullName:
            return CNContactKeyDescriptor(keys: [
                CNContactNamePrefixKey,
                CNContactGivenNameKey,
                CNContactMiddleNameKey,
                CNContactFamilyNameKey,
                CNContactNameSuffixKey,
                CNContactOrganizationNameKey,
                CNContactNicknameKey,
                CNContactTypeKey,
            ])
        case .phoneticFullName:
            return CNContactKeyDescriptor(keys: [
                CNContactPhoneticGivenNameKey,
                CNContactPhoneticMiddleNameKey,
                CNContactPhoneticFamilyNameKey,
                CNContactPhoneticOrganizationNameKey,
                CNContactTypeKey,
            ])
        }
    }

    open class func delimiter(for contact: CNContact) -> String {
        _ = contact
        return " "
    }

    open class func nameOrder(for contact: CNContact) -> CNContactDisplayNameOrder {
        _ = contact
        return .givenNameFirst
    }

    open class func string(from contact: CNContact, style: CNContactFormatterStyle) -> String? {
        let phonetic = style == .phoneticFullName
        let parts = contact.displayNameParts(phonetic: phonetic)
        if contact.contactType == .organization && !parts.organization.isEmpty {
            return parts.organization
        }
        let order = nameOrder(for: contact)
        let pieces: [String]
        if order == .familyNameFirst {
            pieces = [parts.last, parts.first]
        } else {
            pieces = [parts.first, parts.last]
        }
        let joined = pieces.filter { !$0.isEmpty }.joined(separator: delimiter(for: contact))
        if joined.isEmpty {
            if !contact.nickname.isEmpty { return contact.nickname }
            if !parts.organization.isEmpty { return parts.organization }
            return nil
        }
        return joined
    }

    open class func attributedString(
        from contact: CNContact,
        style: CNContactFormatterStyle,
        defaultAttributes attributes: [AnyHashable: Any]? = nil
    ) -> NSAttributedString? {
        guard let string = self.string(from: contact, style: style) else { return nil }
        return makeAttributed(string, attributes)
    }

    open func string(from contact: CNContact) -> String? {
        Self.string(from: contact, style: style)
    }

    open func attributedString(
        from contact: CNContact,
        defaultAttributes attributes: [AnyHashable: Any]? = nil
    ) -> NSAttributedString? {
        Self.attributedString(from: contact, style: style, defaultAttributes: attributes)
    }
}

open class CNPostalAddressFormatter: NSObject {
    public var style: CNPostalAddressFormatterStyle = .mailingAddress

    public override init() {
        super.init()
    }

    open class func string(
        from postalAddress: CNPostalAddress,
        style: CNPostalAddressFormatterStyle
    ) -> String {
        _ = style
        var lines: [String] = []
        if !postalAddress.street.isEmpty { lines.append(postalAddress.street) }
        var cityLine: [String] = []
        if !postalAddress.city.isEmpty { cityLine.append(postalAddress.city) }
        if !postalAddress.state.isEmpty { cityLine.append(postalAddress.state) }
        if !postalAddress.postalCode.isEmpty { cityLine.append(postalAddress.postalCode) }
        if !cityLine.isEmpty {
            lines.append(cityLine.joined(separator: ", "))
        }
        if !postalAddress.country.isEmpty { lines.append(postalAddress.country) }
        return lines.joined(separator: "\n")
    }

    open class func attributedString(
        from postalAddress: CNPostalAddress,
        style: CNPostalAddressFormatterStyle,
        withDefaultAttributes attributes: [AnyHashable: Any] = [:]
    ) -> NSAttributedString {
        makeAttributed(string(from: postalAddress, style: style), attributes)
    }

    open func string(from postalAddress: CNPostalAddress) -> String {
        Self.string(from: postalAddress, style: style)
    }

    open func attributedString(
        from postalAddress: CNPostalAddress,
        withDefaultAttributes attributes: [AnyHashable: Any] = [:]
    ) -> NSAttributedString {
        Self.attributedString(from: postalAddress, style: style, withDefaultAttributes: attributes)
    }
}

private func makeAttributed(_ string: String, _ attributes: [AnyHashable: Any]?) -> NSAttributedString {
    var nsAttributes: [NSAttributedString.Key: Any] = [:]
    if let attributes {
        for (key, value) in attributes {
            if let typed = key as? NSAttributedString.Key {
                nsAttributes[typed] = value
            } else if let raw = key as? String {
                nsAttributes[NSAttributedString.Key(raw)] = value
            }
        }
    }
    return NSAttributedString(string: string, attributes: nsAttributes)
}

open class CNContactVCardSerialization: NSObject {
    open class func descriptorForRequiredKeys() -> any CNKeyDescriptor {
        CNContactKeyDescriptor(keys: CNAllContactPropertyKeys())
    }

    open class func data(with contacts: [CNContact]) throws -> Data {
        var output = ""
        for contact in contacts {
            output += encodeCard(contact)
        }
        guard let data = output.data(using: .utf8) else {
            throw CNError(.vCardSummarizationError)
        }
        return data
    }

    open class func contacts(with data: Data) throws -> [CNContact] {
        guard let text = String(data: data, encoding: .utf8) else {
            throw CNError(.vCardMalformed)
        }
        var contacts: [CNContact] = []
        var current: CNMutableContact?
        for rawLine in text.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(rawLine)
            let upper = line.uppercased()
            if upper == "BEGIN:VCARD" {
                current = CNMutableContact()
            } else if upper == "END:VCARD" {
                if let current {
                    contacts.append(current)
                }
                current = nil
            } else if let contact = current {
                applyVCardLine(line, to: contact)
            }
        }
        if current != nil {
            throw CNError(.vCardMalformed)
        }
        return contacts
    }

    private static func encodeCard(_ contact: CNContact) -> String {
        var lines = ["BEGIN:VCARD", "VERSION:3.0"]
        lines.append(
            "N:\(escape(contact.familyName));\(escape(contact.givenName));\(escape(contact.middleName));\(escape(contact.namePrefix));\(escape(contact.nameSuffix))"
        )
        if let full = CNContactFormatter.string(from: contact, style: .fullName) {
            lines.append("FN:\(escape(full))")
        }
        if !contact.organizationName.isEmpty {
            lines.append("ORG:\(escape(contact.organizationName))")
        }
        if !contact.jobTitle.isEmpty {
            lines.append("TITLE:\(escape(contact.jobTitle))")
        }
        if !contact.nickname.isEmpty {
            lines.append("NICKNAME:\(escape(contact.nickname))")
        }
        if !contact.note.isEmpty {
            lines.append("NOTE:\(escape(contact.note))")
        }
        for phone in contact.phoneNumbers {
            lines.append("TEL:\(escape(phone.value.stringValue))")
        }
        for email in contact.emailAddresses {
            lines.append("EMAIL:\(escape(email.value as String))")
        }
        for url in contact.urlAddresses {
            lines.append("URL:\(escape(url.value as String))")
        }
        for labeled in contact.postalAddresses {
            let address = labeled.value
            lines.append(
                "ADR:;;\(escape(address.street));\(escape(address.city));\(escape(address.state));\(escape(address.postalCode));\(escape(address.country))"
            )
        }
        lines.append("END:VCARD")
        return lines.joined(separator: "\r\n") + "\r\n"
    }

    private static func applyVCardLine(_ line: String, to contact: CNMutableContact) {
        guard let colon = line.firstIndex(of: ":") else { return }
        let name = String(line[..<colon]).uppercased()
        let value = unescape(String(line[line.index(after: colon)...]))
        if name == "N" {
            let parts = splitUnescaped(value)
            if parts.count > 0 { contact.familyName = parts[0] }
            if parts.count > 1 { contact.givenName = parts[1] }
            if parts.count > 2 { contact.middleName = parts[2] }
            if parts.count > 3 { contact.namePrefix = parts[3] }
            if parts.count > 4 { contact.nameSuffix = parts[4] }
        } else if name == "ORG" {
            contact.organizationName = value
        } else if name == "TITLE" {
            contact.jobTitle = value
        } else if name == "NICKNAME" {
            contact.nickname = value
        } else if name == "NOTE" {
            contact.note = value
        } else if name.hasPrefix("TEL") {
            contact.phoneNumbers.append(CNLabeledValue(label: CNLabelOther, value: CNPhoneNumber(stringValue: value)))
        } else if name.hasPrefix("EMAIL") {
            contact.emailAddresses.append(CNLabeledValue(label: CNLabelOther, value: value as NSString))
        } else if name.hasPrefix("URL") {
            contact.urlAddresses.append(CNLabeledValue(label: CNLabelHome, value: value as NSString))
        } else if name.hasPrefix("ADR") {
            let parts = splitUnescaped(value)
            let address = CNMutablePostalAddress()
            if parts.count > 2 { address.street = parts[2] }
            if parts.count > 3 { address.city = parts[3] }
            if parts.count > 4 { address.state = parts[4] }
            if parts.count > 5 { address.postalCode = parts[5] }
            if parts.count > 6 { address.country = parts[6] }
            contact.postalAddresses.append(CNLabeledValue(label: CNLabelHome, value: address))
        }
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private static func unescape(_ value: String) -> String {
        var result = ""
        var iterator = value.makeIterator()
        while let character = iterator.next() {
            if character == "\\" {
                if let next = iterator.next() {
                    switch next {
                    case "n", "N": result.append("\n")
                    case ";", ",", "\\": result.append(next)
                    default: result.append(next)
                    }
                }
            } else {
                result.append(character)
            }
        }
        return result
    }

    private static func splitUnescaped(_ value: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var iterator = value.makeIterator()
        while let character = iterator.next() {
            if character == "\\" {
                if let next = iterator.next() {
                    current.append(next)
                }
            } else if character == ";" {
                parts.append(current)
                current = ""
            } else {
                current.append(character)
            }
        }
        parts.append(current)
        return parts
    }
}
