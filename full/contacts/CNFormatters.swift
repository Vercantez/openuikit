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
        if contact.contactType == .organization {
            let organization = phonetic ? contact.phoneticOrganizationName : contact.organizationName
            if !organization.isEmpty { return organization }
        }
        let prefix = phonetic ? "" : contact.namePrefix
        let given = phonetic ? contact.phoneticGivenName : contact.givenName
        let middle = phonetic ? contact.phoneticMiddleName : contact.middleName
        let family = phonetic ? contact.phoneticFamilyName : contact.familyName
        let suffix = phonetic ? "" : contact.nameSuffix
        let order = nameOrder(for: contact)
        let ordered: [String]
        if order == .familyNameFirst {
            ordered = [prefix, family, given, middle, suffix]
        } else {
            ordered = [prefix, given, middle, family, suffix]
        }
        let joined = ordered.filter { !$0.isEmpty }.joined(separator: delimiter(for: contact))
        if joined.isEmpty {
            if !contact.nickname.isEmpty { return contact.nickname }
            let organization = phonetic ? contact.phoneticOrganizationName : contact.organizationName
            if !organization.isEmpty { return organization }
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
        let region = postalAddress.isoCountryCode.isEmpty
            ? (Locale.current.region?.identifier ?? "US")
            : postalAddress.isoCountryCode.uppercased()
        return layout(postalAddress, region: region)
    }

    private static func layout(_ address: CNPostalAddress, region: String) -> String {
        var lines: [String] = []
        func cityStatePostalUS() -> String? {
            var parts: [String] = []
            if !address.city.isEmpty { parts.append(address.city) }
            var stateZip = address.state
            if !address.postalCode.isEmpty {
                stateZip = stateZip.isEmpty ? address.postalCode : "\(stateZip) \(address.postalCode)"
            }
            if !stateZip.isEmpty { parts.append(stateZip) }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }
        switch region {
        case "US", "CA", "AU", "NZ":
            if !address.street.isEmpty { lines.append(address.street) }
            if let cityLine = cityStatePostalUS() { lines.append(cityLine) }
            if !address.country.isEmpty { lines.append(address.country) }
        case "GB", "UK":
            if !address.street.isEmpty { lines.append(address.street) }
            if !address.city.isEmpty { lines.append(address.city) }
            if !address.postalCode.isEmpty { lines.append(address.postalCode) }
            if !address.country.isEmpty { lines.append(address.country) }
        case "JP", "KR", "CN":
            if !address.country.isEmpty { lines.append(address.country) }
            if !address.postalCode.isEmpty { lines.append(address.postalCode) }
            var locality: [String] = []
            if !address.state.isEmpty { locality.append(address.state) }
            if !address.city.isEmpty { locality.append(address.city) }
            if !locality.isEmpty { lines.append(locality.joined(separator: " ")) }
            if !address.street.isEmpty { lines.append(address.street) }
        default:
            if !address.street.isEmpty { lines.append(address.street) }
            var cityLine: [String] = []
            if !address.postalCode.isEmpty { cityLine.append(address.postalCode) }
            if !address.city.isEmpty { cityLine.append(address.city) }
            if !cityLine.isEmpty { lines.append(cityLine.joined(separator: " ")) }
            if !address.state.isEmpty { lines.append(address.state) }
            if !address.country.isEmpty { lines.append(address.country) }
        }
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
        let unfolded = unfoldVCard(text.replacingOccurrences(of: "\r\n", with: "\n"))
        var contacts: [CNContact] = []
        var current: CNMutableContact?
        for rawLine in unfolded.split(separator: "\n", omittingEmptySubsequences: false) {
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

    private static func unfoldVCard(_ text: String) -> String {
        var result = ""
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        for line in lines {
            if line.first == " " || line.first == "\t" {
                result.append(contentsOf: line.dropFirst())
            } else {
                if !result.isEmpty { result.append("\n") }
                result.append(contentsOf: line)
            }
        }
        return result
    }

    private static func encodeCard(_ contact: CNContact) -> String {
        var lines = ["BEGIN:VCARD", "VERSION:3.0"]
        lines.append(
            "N:\(escape(contact.familyName));\(escape(contact.givenName));\(escape(contact.middleName));\(escape(contact.namePrefix));\(escape(contact.nameSuffix))"
        )
        if let full = CNContactFormatter.string(from: contact, style: .fullName) {
            lines.append("FN:\(escape(full))")
        }
        if !contact.nickname.isEmpty {
            lines.append("NICKNAME:\(escape(contact.nickname))")
        }
        if !contact.organizationName.isEmpty {
            lines.append("ORG:\(escape(contact.organizationName))")
        }
        if !contact.jobTitle.isEmpty {
            lines.append("TITLE:\(escape(contact.jobTitle))")
        }
        if let birthday = contact.birthday, let formatted = formatBDay(birthday) {
            lines.append("BDAY:\(formatted)")
        }
        if !contact.note.isEmpty {
            lines.append("NOTE:\(escape(contact.note))")
        }
        for phone in contact.phoneNumbers {
            let type = telType(phone.label)
            lines.append("TEL;TYPE=\(type):\(escape(phone.value.stringValue))")
        }
        for email in contact.emailAddresses {
            let type = emailType(email.label)
            lines.append("EMAIL;TYPE=\(type):\(escape(email.value as String))")
        }
        for url in contact.urlAddresses {
            lines.append("URL:\(escape(url.value as String))")
        }
        for labeled in contact.postalAddresses {
            let address = labeled.value
            let type = addressType(labeled.label)
            lines.append(
                "ADR;TYPE=\(type):;;\(escape(address.street));\(escape(address.city));\(escape(address.state));\(escape(address.postalCode));\(escape(address.country))"
            )
        }
        if let photo = contact.imageData ?? contact.thumbnailImageData {
            let encoded = photo.base64EncodedString()
            let kind = photoType(photo)
            lines.append("PHOTO;ENCODING=b;TYPE=\(kind):\(encoded)")
        }
        lines.append("END:VCARD")
        return foldVCard(lines).joined(separator: "\r\n") + "\r\n"
    }

    private static func foldVCard(_ lines: [String]) -> [String] {
        var folded: [String] = []
        for line in lines {
            if line.utf8.count <= 75 {
                folded.append(line)
                continue
            }
            var remaining = line
            var first = true
            while !remaining.isEmpty {
                let limit = first ? 75 : 74
                var index = remaining.startIndex
                var count = 0
                var cut = remaining.endIndex
                while index < remaining.endIndex {
                    let next = remaining.index(after: index)
                    count += remaining[index..<next].utf8.count
                    if count > limit {
                        cut = index
                        break
                    }
                    index = next
                }
                let chunk = String(remaining[..<cut])
                folded.append(first ? chunk : " " + chunk)
                remaining = String(remaining[cut...])
                first = false
            }
        }
        return folded
    }

    private static func formatBDay(_ components: DateComponents) -> String? {
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func telType(_ label: String?) -> String {
        switch label {
        case CNLabelPhoneNumberiPhone: return "IPHONE"
        case CNLabelPhoneNumberMobile: return "CELL"
        case CNLabelPhoneNumberAppleWatch: return "WATCH"
        case CNLabelPhoneNumberHomeFax: return "FAX,HOME"
        case CNLabelPhoneNumberWorkFax: return "FAX,WORK"
        case CNLabelPhoneNumberOtherFax: return "FAX"
        case CNLabelPhoneNumberPager: return "PAGER"
        case CNLabelPhoneNumberMain: return "MAIN"
        case CNLabelWork: return "WORK"
        case CNLabelHome: return "HOME"
        default: return "VOICE"
        }
    }

    private static func emailType(_ label: String?) -> String {
        switch label {
        case CNLabelWork: return "WORK"
        case CNLabelEmailiCloud: return "INTERNET"
        case CNLabelHome: return "HOME"
        default: return "INTERNET"
        }
    }

    private static func addressType(_ label: String?) -> String {
        switch label {
        case CNLabelWork: return "WORK"
        default: return "HOME"
        }
    }

    private static func photoType(_ data: Data) -> String {
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "PNG" }
        if data.starts(with: [0x47, 0x49, 0x46]) { return "GIF" }
        return "JPEG"
    }

    private static func applyVCardLine(_ line: String, to contact: CNMutableContact) {
        guard let colon = line.firstIndex(of: ":") else { return }
        let nameAndParams = String(line[..<colon])
        let value = unescape(String(line[line.index(after: colon)...]))
        let pieces = nameAndParams.split(separator: ";")
        guard let rawName = pieces.first else { return }
        let name = String(rawName).uppercased()
        var params: [String: String] = [:]
        for parameter in pieces.dropFirst() {
            let text = String(parameter)
            if let eq = text.firstIndex(of: "=") {
                let key = String(text[..<eq]).uppercased()
                let value = String(text[text.index(after: eq)...]).uppercased()
                if let existing = params[key], !existing.isEmpty {
                    params[key] = existing + "," + value
                } else {
                    params[key] = value
                }
            } else {
                params[text.uppercased()] = ""
            }
        }
        let types = params["TYPE"]?.split(separator: ",").map(String.init) ?? []
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
        } else if name == "BDAY" {
            contact.birthday = parseBDay(value)
        } else if name == "TEL" {
            contact.phoneNumbers.append(
                CNLabeledValue(label: phoneLabel(from: types), value: CNPhoneNumber(stringValue: value))
            )
        } else if name == "EMAIL" {
            contact.emailAddresses.append(
                CNLabeledValue(label: emailLabel(from: types), value: value as NSString)
            )
        } else if name == "URL" {
            contact.urlAddresses.append(CNLabeledValue(label: CNLabelURLAddressHomePage, value: value as NSString))
        } else if name == "ADR" {
            let parts = splitUnescaped(value)
            let address = CNMutablePostalAddress()
            if parts.count > 2 { address.street = parts[2] }
            if parts.count > 3 { address.city = parts[3] }
            if parts.count > 4 { address.state = parts[4] }
            if parts.count > 5 { address.postalCode = parts[5] }
            if parts.count > 6 { address.country = parts[6] }
            contact.postalAddresses.append(
                CNLabeledValue(label: types.contains("WORK") ? CNLabelWork : CNLabelHome, value: address)
            )
        } else if name == "PHOTO" {
            let cleaned = value.replacingOccurrences(of: " ", with: "")
            if let data = Data(base64Encoded: cleaned) {
                contact.imageData = data
            }
        }
    }

    private static func parseBDay(_ value: String) -> DateComponents? {
        let digits = value.filter(\.isNumber)
        guard digits.count >= 8 else { return nil }
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.year = Int(digits.prefix(4))
        components.month = Int(digits.dropFirst(4).prefix(2))
        components.day = Int(digits.dropFirst(6).prefix(2))
        return components
    }

    private static func phoneLabel(from types: [String]) -> String {
        if types.contains("IPHONE") { return CNLabelPhoneNumberiPhone }
        if types.contains("CELL") { return CNLabelPhoneNumberMobile }
        if types.contains("WATCH") { return CNLabelPhoneNumberAppleWatch }
        if types.contains("PAGER") { return CNLabelPhoneNumberPager }
        if types.contains("MAIN") { return CNLabelPhoneNumberMain }
        if types.contains("FAX") && types.contains("WORK") { return CNLabelPhoneNumberWorkFax }
        if types.contains("FAX") && types.contains("HOME") { return CNLabelPhoneNumberHomeFax }
        if types.contains("FAX") { return CNLabelPhoneNumberOtherFax }
        if types.contains("WORK") { return CNLabelWork }
        if types.contains("HOME") { return CNLabelHome }
        return CNLabelOther
    }

    private static func emailLabel(from types: [String]) -> String {
        if types.contains("WORK") { return CNLabelWork }
        if types.contains("HOME") { return CNLabelHome }
        return CNLabelOther
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
