import CoreFoundation
import Foundation

public func ABPersonCreate() -> Unmanaged<ABRecord>! {
    Unmanaged.passRetained(ABRecordBox(recordType: ABRecordType(kABPersonType)))
}

public func ABPersonCreateInSource(_ source: ABRecord!) -> Unmanaged<ABRecord>! {
    guard let sourceBox = abRecord(source), sourceBox.recordType == ABRecordType(kABSourceType) else {
        return nil
    }
    let person = ABRecordBox(recordType: ABRecordType(kABPersonType))
    person.source = sourceBox
    return Unmanaged.passRetained(person)
}

public func ABPersonCopySource(_ person: ABRecord!) -> Unmanaged<ABRecord>! {
    guard let box = abRecord(person), let source = box.source ?? box.book?.defaultSource else {
        return nil
    }
    return Unmanaged.passUnretained(source)
}

public func ABPersonGetTypeOfProperty(_ property: ABPropertyID) -> ABPropertyType {
    abPersonPropertyType(property)
}

public func ABPersonCopyLocalizedPropertyName(_ property: ABPropertyID) -> Unmanaged<CFString>! {
    abPassRetainedString(abLocalizedPropertyName(property))
}

public func ABPersonGetCompositeNameFormat() -> ABPersonCompositeNameFormat {
    ABPersonCompositeNameFormat(kABPersonCompositeNameFormatFirstNameFirst)
}

public func ABPersonGetCompositeNameFormatForRecord(_ record: ABRecord!) -> ABPersonCompositeNameFormat {
    _ = record
    return ABPersonGetCompositeNameFormat()
}

public func ABPersonCopyCompositeNameDelimiterForRecord(_ record: ABRecord!) -> Unmanaged<CFString>! {
    _ = record
    return abPassRetainedString(" ")
}

public func ABPersonGetSortOrdering() -> ABPersonSortOrdering {
    ABPersonSortOrdering(kABPersonSortByFirstName)
}

public func ABPersonComparePeopleByName(
    _ person1: ABRecord!,
    _ person2: ABRecord!,
    _ ordering: ABPersonSortOrdering
) -> CFComparisonResult {
    guard let lhs = abRecord(person1), let rhs = abRecord(person2) else {
        return .compareEqualTo
    }
    let left = abSortKey(lhs, ordering: ordering)
    let right = abSortKey(rhs, ordering: ordering)
    if left < right { return .compareLessThan }
    if left > right { return .compareGreaterThan }
    return .compareEqualTo
}

public func ABPersonCopyArrayOfAllLinkedPeople(_ person: ABRecord!) -> Unmanaged<CFArray>! {
    guard let box = abRecord(person) else { return nil }
    return abPassRetainedArray([box])
}

public func ABPersonHasImageData(_ person: ABRecord!) -> Bool {
    abRecord(person)?.imageData != nil
}

public func ABPersonCopyImageData(_ person: ABRecord!) -> Unmanaged<CFData>! {
    guard let data = abRecord(person)?.imageData else { return nil }
    return abPassRetainedData(data)
}

public func ABPersonCopyImageDataWithFormat(
    _ person: ABRecord!,
    _ format: ABPersonImageFormat
) -> Unmanaged<CFData>! {
    _ = format
    return ABPersonCopyImageData(person)
}

public func ABPersonSetImageData(
    _ person: ABRecord!,
    _ imageData: CFData!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>!
) -> Bool {
    guard let box = abRecord(person) else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    box.imageData = abData(imageData)
    box.markDirty()
    return true
}

public func ABPersonRemoveImageData(
    _ person: ABRecord!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>!
) -> Bool {
    guard let box = abRecord(person) else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    box.imageData = nil
    box.markDirty()
    return true
}

func abCompositeName(_ person: ABRecordBox, ignoreOrganization: Bool) -> String {
    let prefix = person.stringValue(kABPersonPrefixProperty)
    let first = person.stringValue(kABPersonFirstNameProperty)
    let middle = person.stringValue(kABPersonMiddleNameProperty)
    let last = person.stringValue(kABPersonLastNameProperty)
    let suffix = person.stringValue(kABPersonSuffixProperty)
    let nickname = person.stringValue(kABPersonNicknameProperty)
    let organization = person.stringValue(kABPersonOrganizationProperty)
    let kind = person.values[kABPersonKindProperty]
    let isOrganization: Bool = {
        guard let kind else { return false }
        if let number = kind as? NSNumber {
            return number.intValue == 1
        }
        return false
    }()
    if !ignoreOrganization, isOrganization, !organization.isEmpty {
        return organization
    }
    let format = ABPersonGetCompositeNameFormatForRecord(person)
    var parts: [String] = []
    if format == ABPersonCompositeNameFormat(kABPersonCompositeNameFormatLastNameFirst) {
        if !last.isEmpty { parts.append(last) }
        if !first.isEmpty { parts.append(first) }
        if !middle.isEmpty { parts.append(middle) }
    } else {
        if !prefix.isEmpty { parts.append(prefix) }
        if !first.isEmpty { parts.append(first) }
        if !middle.isEmpty { parts.append(middle) }
        if !last.isEmpty { parts.append(last) }
        if !suffix.isEmpty { parts.append(suffix) }
    }
    if parts.isEmpty, !nickname.isEmpty {
        return nickname
    }
    if parts.isEmpty, !ignoreOrganization, !organization.isEmpty {
        return organization
    }
    if format == ABPersonCompositeNameFormat(kABPersonCompositeNameFormatLastNameFirst) {
        if !prefix.isEmpty {
            parts.insert(prefix, at: 0)
        }
        if !suffix.isEmpty {
            parts.append(suffix)
        }
    }
    return parts.joined(separator: " ")
}

func abSortKey(_ person: ABRecordBox, ordering: ABPersonSortOrdering) -> String {
    let first = person.stringValue(kABPersonFirstNameProperty).lowercased()
    let last = person.stringValue(kABPersonLastNameProperty).lowercased()
    if ordering == ABPersonSortOrdering(kABPersonSortByLastName) {
        return last + "\u{1}" + first
    }
    return first + "\u{1}" + last
}
