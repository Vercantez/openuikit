import CoreFoundation
import Foundation

public func ABMultiValueCreateMutable(_ type: ABPropertyType) -> Unmanaged<ABMutableMultiValue>! {
    let box = ABMultiValueBox(propertyType: type, mutable: true)
    return Unmanaged.passRetained(box)
}

public func ABMultiValueCreateMutableCopy(_ multiValue: ABMultiValue!) -> Unmanaged<ABMutableMultiValue>! {
    guard let box = abMulti(multiValue) else { return nil }
    return Unmanaged.passRetained(box.mutableCopyBox())
}

public func ABMultiValueGetCount(_ multiValue: ABMultiValue!) -> CFIndex {
    CFIndex(abMulti(multiValue)?.entries.count ?? 0)
}

public func ABMultiValueGetPropertyType(_ multiValue: ABMultiValue!) -> ABPropertyType {
    abMulti(multiValue)?.propertyType ?? ABPropertyType(kABInvalidPropertyType)
}

public func ABMultiValueCopyValueAtIndex(
    _ multiValue: ABMultiValue!,
    _ index: CFIndex
) -> Unmanaged<CFTypeRef>! {
    guard let box = abMulti(multiValue), box.entries.indices.contains(Int(index)) else {
        return nil
    }
    return Unmanaged.passRetained(box.entries[Int(index)].value)
}

public func ABMultiValueCopyLabelAtIndex(
    _ multiValue: ABMultiValue!,
    _ index: CFIndex
) -> Unmanaged<CFString>! {
    guard let box = abMulti(multiValue), box.entries.indices.contains(Int(index)) else {
        return nil
    }
    guard let label = box.entries[Int(index)].label else { return nil }
    return abPassRetainedString(label)
}

public func ABMultiValueCopyArrayOfAllValues(_ multiValue: ABMultiValue!) -> Unmanaged<CFArray>! {
    guard let box = abMulti(multiValue) else { return nil }
    return abPassRetainedArray(box.entries.map(\.value))
}

public func ABMultiValueGetIdentifierAtIndex(
    _ multiValue: ABMultiValue!,
    _ index: CFIndex
) -> ABMultiValueIdentifier {
    guard let box = abMulti(multiValue), box.entries.indices.contains(Int(index)) else {
        return kABMultiValueInvalidIdentifier
    }
    return box.entries[Int(index)].identifier
}

public func ABMultiValueGetIndexForIdentifier(
    _ multiValue: ABMultiValue!,
    _ identifier: ABMultiValueIdentifier
) -> CFIndex {
    guard let box = abMulti(multiValue) else { return -1 }
    guard let index = box.entries.firstIndex(where: { $0.identifier == identifier }) else {
        return -1
    }
    return CFIndex(index)
}

public func ABMultiValueGetFirstIndexOfValue(
    _ multiValue: ABMultiValue!,
    _ value: CFTypeRef!
) -> CFIndex {
    guard let box = abMulti(multiValue), let value else { return -1 }
    let needle = abObject(value)
    for (index, entry) in box.entries.enumerated() {
        if let needle, let object = entry.value as? NSObject, object.isEqual(needle) {
            return CFIndex(index)
        }
        if entry.value === value {
            return CFIndex(index)
        }
        if abStringValue(entry.value) != nil, abStringValue(entry.value) == abStringValue(value) {
            return CFIndex(index)
        }
    }
    return -1
}

@discardableResult
public func ABMultiValueAddValueAndLabel(
    _ multiValue: ABMutableMultiValue!,
    _ value: CFTypeRef!,
    _ label: CFString!,
    _ outIdentifier: UnsafeMutablePointer<ABMultiValueIdentifier>!
) -> Bool {
    ABMultiValueInsertValueAndLabelAtIndex(
        multiValue,
        value,
        label,
        CFIndex(abMulti(multiValue)?.entries.count ?? 0),
        outIdentifier
    )
}

public func ABMultiValueInsertValueAndLabelAtIndex(
    _ multiValue: ABMutableMultiValue!,
    _ value: CFTypeRef!,
    _ label: CFString!,
    _ index: CFIndex,
    _ outIdentifier: UnsafeMutablePointer<ABMultiValueIdentifier>!
) -> Bool {
    guard let box = abMulti(multiValue), box.mutable, let value else { return false }
    let insertion = Int(index)
    guard insertion >= 0, insertion <= box.entries.count else { return false }
    let identifier = box.nextIdentifier
    box.nextIdentifier += 1
    let entry = ABMultiValueEntry(
        value: value,
        label: abString(label),
        identifier: identifier
    )
    box.entries.insert(entry, at: insertion)
    outIdentifier?.pointee = identifier
    return true
}

public func ABMultiValueRemoveValueAndLabelAtIndex(
    _ multiValue: ABMutableMultiValue!,
    _ index: CFIndex
) -> Bool {
    guard let box = abMulti(multiValue), box.mutable else { return false }
    let removal = Int(index)
    guard box.entries.indices.contains(removal) else { return false }
    box.entries.remove(at: removal)
    return true
}

public func ABMultiValueReplaceValueAtIndex(
    _ multiValue: ABMutableMultiValue!,
    _ value: CFTypeRef!,
    _ index: CFIndex
) -> Bool {
    guard let box = abMulti(multiValue), box.mutable, let value else { return false }
    let position = Int(index)
    guard box.entries.indices.contains(position) else { return false }
    box.entries[position].value = value
    return true
}

public func ABMultiValueReplaceLabelAtIndex(
    _ multiValue: ABMutableMultiValue!,
    _ label: CFString!,
    _ index: CFIndex
) -> Bool {
    guard let box = abMulti(multiValue), box.mutable else { return false }
    let position = Int(index)
    guard box.entries.indices.contains(position) else { return false }
    box.entries[position].label = abString(label)
    return true
}
