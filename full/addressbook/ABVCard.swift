import CoreFoundation
import Foundation

public func ABPersonCreateVCardRepresentationWithPeople(_ people: CFArray!) -> Unmanaged<CFData>! {
    guard let people else { return nil }
    let array = unsafeBitCast(people, to: NSArray.self)
    var chunks: [String] = []
    for object in array {
        guard let person = object as? ABRecordBox else { continue }
        chunks.append(abEncodeVCard(person))
    }
    if chunks.isEmpty {
        return nil
    }
    let joined = chunks.joined()
    return abPassRetainedData(Data(joined.utf8))
}

public func ABPersonCreatePeopleInSourceWithVCardRepresentation(
    _ source: ABRecord!,
    _ vCardData: CFData!
) -> Unmanaged<CFArray>! {
    guard let data = abData(vCardData), let text = String(data: data, encoding: .utf8) else {
        return nil
    }
    let cards = abParseVCards(text)
    if cards.isEmpty {
        return nil
    }
    let sourceBox = abRecord(source)
    var people: [ABRecordBox] = []
    for card in cards {
        let person = ABRecordBox(recordType: ABRecordType(kABPersonType))
        person.source = sourceBox
        abApplyVCard(card, to: person)
        people.append(person)
    }
    return abPassRetainedArray(people)
}

func abEncodeVCard(_ person: ABRecordBox) -> String {
    var lines = ["BEGIN:VCARD", "VERSION:3.0"]
    let last = person.stringValue(kABPersonLastNameProperty)
    let first = person.stringValue(kABPersonFirstNameProperty)
    let middle = person.stringValue(kABPersonMiddleNameProperty)
    let prefix = person.stringValue(kABPersonPrefixProperty)
    let suffix = person.stringValue(kABPersonSuffixProperty)
    lines.append("N:\(abEscape(last));\(abEscape(first));\(abEscape(middle));\(abEscape(prefix));\(abEscape(suffix))")
    let fn = abCompositeName(person, ignoreOrganization: false)
    if !fn.isEmpty {
        lines.append("FN:\(abEscape(fn))")
    }
    let org = person.stringValue(kABPersonOrganizationProperty)
    if !org.isEmpty { lines.append("ORG:\(abEscape(org))") }
    let title = person.stringValue(kABPersonJobTitleProperty)
    if !title.isEmpty { lines.append("TITLE:\(abEscape(title))") }
    let nick = person.stringValue(kABPersonNicknameProperty)
    if !nick.isEmpty { lines.append("NICKNAME:\(abEscape(nick))") }
    let note = person.stringValue(kABPersonNoteProperty)
    if !note.isEmpty { lines.append("NOTE:\(abEscape(note))") }
    if let birthday = person.values[kABPersonBirthdayProperty] as? Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let parts = calendar.dateComponents([.year, .month, .day], from: birthday)
        if let year = parts.year, let month = parts.month, let day = parts.day {
            lines.append(String(format: "BDAY:%04d-%02d-%02d", year, month, day))
        }
    }
    abAppendMultiStrings(person, property: kABPersonPhoneProperty, prefix: "TEL", lines: &lines)
    abAppendMultiStrings(person, property: kABPersonEmailProperty, prefix: "EMAIL", lines: &lines)
    abAppendMultiStrings(person, property: kABPersonURLProperty, prefix: "URL", lines: &lines)
    if let addresses = person.values[kABPersonAddressProperty] as? ABMultiValueBox {
        for entry in addresses.entries {
            let dict = (entry.value as? NSDictionary) ?? [:]
            let street = dict[abString(kABPersonAddressStreetKey) ?? "Street"] as? String ?? ""
            let city = dict[abString(kABPersonAddressCityKey) ?? "City"] as? String ?? ""
            let state = dict[abString(kABPersonAddressStateKey) ?? "State"] as? String ?? ""
            let zip = dict[abString(kABPersonAddressZIPKey) ?? "ZIP"] as? String ?? ""
            let country = dict[abString(kABPersonAddressCountryKey) ?? "Country"] as? String ?? ""
            let type = abVCardType(entry.label)
            lines.append(
                "ADR;TYPE=\(type):;;\(abEscape(street));\(abEscape(city));\(abEscape(state));\(abEscape(zip));\(abEscape(country))"
            )
        }
    }
    if let photo = person.imageData {
        let encoded = photo.base64EncodedString()
        lines.append("PHOTO;ENCODING=b;TYPE=JPEG:\(encoded)")
    }
    lines.append("END:VCARD")
    return lines.joined(separator: "\r\n") + "\r\n"
}

func abAppendMultiStrings(
    _ person: ABRecordBox,
    property: ABPropertyID,
    prefix: String,
    lines: inout [String]
) {
    guard let multi = person.values[property] as? ABMultiValueBox else { return }
    for entry in multi.entries {
        guard let value = abStringValue(entry.value), !value.isEmpty else { continue }
        let type = abVCardType(entry.label)
        if prefix == "URL" {
            lines.append("URL:\(abEscape(value))")
        } else {
            lines.append("\(prefix);TYPE=\(type):\(abEscape(value))")
        }
    }
}

func abVCardType(_ label: String?) -> String {
    switch label {
    case abString(kABPersonPhoneIPhoneLabel): return "IPHONE"
    case abString(kABPersonPhoneMobileLabel): return "CELL"
    case abString(kABPersonPhoneMainLabel): return "MAIN"
    case abString(kABPersonPhoneHomeFAXLabel): return "FAX,HOME"
    case abString(kABPersonPhoneWorkFAXLabel): return "FAX,WORK"
    case abString(kABPersonPhoneOtherFAXLabel): return "FAX"
    case abString(kABPersonPhonePagerLabel): return "PAGER"
    case abString(kABWorkLabel): return "WORK"
    case abString(kABHomeLabel): return "HOME"
    default: return "VOICE"
    }
}

func abEscape(_ value: String) -> String {
    value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: ";", with: "\\;")
        .replacingOccurrences(of: ",", with: "\\,")
        .replacingOccurrences(of: "\n", with: "\\n")
}

func abUnescape(_ value: String) -> String {
    var result = ""
    var iterator = value.makeIterator()
    while let character = iterator.next() {
        if character == "\\" {
            if let next = iterator.next() {
                switch next {
                case "n", "N": result.append("\n")
                case ",", ";": result.append(next)
                case "\\": result.append("\\")
                default: result.append(next)
                }
            }
        } else {
            result.append(character)
        }
    }
    return result
}

func abParseVCards(_ text: String) -> [[String: [String]]] {
    let unfolded = abUnfold(text)
    var cards: [[String: [String]]] = []
    var current: [String: [String]] = [:]
    var inside = false
    for rawLine in unfolded.split(whereSeparator: { $0 == "\n" || $0 == "\r" }) {
        let line = String(rawLine).trimmingCharacters(in: .whitespaces)
        if line.isEmpty { continue }
        let upper = line.uppercased()
        if upper == "BEGIN:VCARD" {
            inside = true
            current = [:]
            continue
        }
        if upper == "END:VCARD" {
            if inside, !current.isEmpty {
                cards.append(current)
            }
            inside = false
            current = [:]
            continue
        }
        guard inside, let colon = line.firstIndex(of: ":") else { continue }
        let name = String(line[..<colon]).uppercased()
        let value = String(line[line.index(after: colon)...])
        let key = name.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)[0]
        current[String(key), default: []].append(contentsOf: [name + ":" + value])
    }
    return cards
}

func abUnfold(_ text: String) -> String {
    text.replacingOccurrences(of: "\r\n ", with: "")
        .replacingOccurrences(of: "\n ", with: "")
        .replacingOccurrences(of: "\r\n\t", with: "")
}

func abApplyVCard(_ card: [String: [String]], to person: ABRecordBox) {
    if let nLines = card["N"], let line = nLines.first, let value = abVCardValue(line) {
        let parts = abSplitUnescaped(value)
        if parts.count > 0 { _ = ABRecordSetValue(person, kABPersonLastNameProperty, abCFString(abUnescape(parts[0])), nil) }
        if parts.count > 1 { _ = ABRecordSetValue(person, kABPersonFirstNameProperty, abCFString(abUnescape(parts[1])), nil) }
        if parts.count > 2 { _ = ABRecordSetValue(person, kABPersonMiddleNameProperty, abCFString(abUnescape(parts[2])), nil) }
        if parts.count > 3 { _ = ABRecordSetValue(person, kABPersonPrefixProperty, abCFString(abUnescape(parts[3])), nil) }
        if parts.count > 4 { _ = ABRecordSetValue(person, kABPersonSuffixProperty, abCFString(abUnescape(parts[4])), nil) }
    }
    if let org = card["ORG"].flatMap(\.first).flatMap(abVCardValue) {
        _ = ABRecordSetValue(person, kABPersonOrganizationProperty, abCFString(abUnescape(org)), nil)
    }
    if let title = card["TITLE"].flatMap(\.first).flatMap(abVCardValue) {
        _ = ABRecordSetValue(person, kABPersonJobTitleProperty, abCFString(abUnescape(title)), nil)
    }
    if let nick = card["NICKNAME"].flatMap(\.first).flatMap(abVCardValue) {
        _ = ABRecordSetValue(person, kABPersonNicknameProperty, abCFString(abUnescape(nick)), nil)
    }
    if let note = card["NOTE"].flatMap(\.first).flatMap(abVCardValue) {
        _ = ABRecordSetValue(person, kABPersonNoteProperty, abCFString(abUnescape(note)), nil)
    }
    if let bday = card["BDAY"].flatMap(\.first).flatMap(abVCardValue) {
        let digits = bday.replacingOccurrences(of: "-", with: "")
        if digits.count >= 8 {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let year = Int(digits.prefix(4))
            let month = Int(digits.dropFirst(4).prefix(2))
            let day = Int(digits.dropFirst(6).prefix(2))
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                _ = ABRecordSetValue(person, kABPersonBirthdayProperty, date as NSDate, nil)
            }
        }
    }
    if let tels = card["TEL"] {
        let multi = ABMultiValueBox(propertyType: ABPropertyType(kABMultiStringPropertyType), mutable: true)
        for line in tels {
            guard let value = abVCardValue(line) else { continue }
            var identifier = kABMultiValueInvalidIdentifier
            _ = ABMultiValueAddValueAndLabel(
                multi,
                abCFString(abUnescape(value)),
                abCFString(abLabelForVCardType(line)),
                &identifier
            )
        }
        _ = ABRecordSetValue(person, kABPersonPhoneProperty, multi, nil)
    }
    if let emails = card["EMAIL"] {
        let multi = ABMultiValueBox(propertyType: ABPropertyType(kABMultiStringPropertyType), mutable: true)
        for line in emails {
            guard let value = abVCardValue(line) else { continue }
            var identifier = kABMultiValueInvalidIdentifier
            _ = ABMultiValueAddValueAndLabel(
                multi,
                abCFString(abUnescape(value)),
                abCFString(abLabelForVCardType(line)),
                &identifier
            )
        }
        _ = ABRecordSetValue(person, kABPersonEmailProperty, multi, nil)
    }
    if let urls = card["URL"] {
        let multi = ABMultiValueBox(propertyType: ABPropertyType(kABMultiStringPropertyType), mutable: true)
        for line in urls {
            guard let value = abVCardValue(line) else { continue }
            var identifier = kABMultiValueInvalidIdentifier
            _ = ABMultiValueAddValueAndLabel(multi, abCFString(abUnescape(value)), kABHomeLabel, &identifier)
        }
        _ = ABRecordSetValue(person, kABPersonURLProperty, multi, nil)
    }
    if let adrs = card["ADR"] {
        let multi = ABMultiValueBox(propertyType: ABPropertyType(kABMultiDictionaryPropertyType), mutable: true)
        for line in adrs {
            guard let value = abVCardValue(line) else { continue }
            let parts = abSplitUnescaped(value)
            let street = parts.count > 2 ? abUnescape(parts[2]) : ""
            let city = parts.count > 3 ? abUnescape(parts[3]) : ""
            let state = parts.count > 4 ? abUnescape(parts[4]) : ""
            let zip = parts.count > 5 ? abUnescape(parts[5]) : ""
            let country = parts.count > 6 ? abUnescape(parts[6]) : ""
            let dict: [String: String] = [
                abString(kABPersonAddressStreetKey) ?? "Street": street,
                abString(kABPersonAddressCityKey) ?? "City": city,
                abString(kABPersonAddressStateKey) ?? "State": state,
                abString(kABPersonAddressZIPKey) ?? "ZIP": zip,
                abString(kABPersonAddressCountryKey) ?? "Country": country,
            ]
            var identifier = kABMultiValueInvalidIdentifier
            _ = ABMultiValueAddValueAndLabel(
                multi,
                dict as NSDictionary,
                abCFString(abLabelForVCardType(line)),
                &identifier
            )
        }
        _ = ABRecordSetValue(person, kABPersonAddressProperty, multi, nil)
    }
}

func abVCardValue(_ line: String) -> String? {
    guard let colon = line.firstIndex(of: ":") else { return nil }
    return String(line[line.index(after: colon)...])
}

func abLabelForVCardType(_ line: String) -> String {
    let upper = line.uppercased()
    if upper.contains("TYPE=IPHONE") { return abString(kABPersonPhoneIPhoneLabel) ?? "iPhone" }
    if upper.contains("TYPE=CELL") { return abString(kABPersonPhoneMobileLabel) ?? "_$!<Mobile>!$_" }
    if upper.contains("TYPE=MAIN") { return abString(kABPersonPhoneMainLabel) ?? "_$!<Main>!$_" }
    if upper.contains("TYPE=PAGER") { return abString(kABPersonPhonePagerLabel) ?? "_$!<Pager>!$_" }
    if upper.contains("TYPE=WORK") { return abString(kABWorkLabel) ?? "_$!<Work>!$_" }
    if upper.contains("TYPE=HOME") { return abString(kABHomeLabel) ?? "_$!<Home>!$_" }
    return abString(kABOtherLabel) ?? "_$!<Other>!$_"
}

func abSplitUnescaped(_ value: String) -> [String] {
    var parts: [String] = []
    var current = ""
    var escaped = false
    for character in value {
        if escaped {
            current.append(character)
            escaped = false
            continue
        }
        if character == "\\" {
            escaped = true
            current.append(character)
            continue
        }
        if character == ";" {
            parts.append(current)
            current = ""
            continue
        }
        current.append(character)
    }
    parts.append(current)
    return parts
}
