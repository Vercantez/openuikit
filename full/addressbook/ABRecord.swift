import CoreFoundation
import Foundation

public func ABRecordGetRecordID(_ record: ABRecord!) -> ABRecordID {
    abRecord(record)?.recordID ?? kABRecordInvalidID
}

public func ABRecordGetRecordType(_ record: ABRecord!) -> ABRecordType {
    abRecord(record)?.recordType ?? ABRecordType(kABPersonType)
}

public func ABRecordCopyValue(_ record: ABRecord!, _ property: ABPropertyID) -> Unmanaged<CFTypeRef>! {
    guard let box = abRecord(record), let value = box.values[property] else {
        return nil
    }
    if let multi = value as? ABMultiValueBox {
        return Unmanaged.passRetained(multi.mutableCopyBox())
    }
    return Unmanaged.passRetained(value)
}

public func ABRecordSetValue(
    _ record: ABRecord!,
    _ property: ABPropertyID,
    _ value: CFTypeRef!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>!
) -> Bool {
    guard let box = abRecord(record) else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    guard property != kABPropertyInvalidID, let value else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    if let multi = value as? ABMultiValueBox {
        box.values[property] = multi.mutableCopyBox()
    } else {
        box.values[property] = value
    }
    box.markDirty()
    return true
}

public func ABRecordRemoveValue(
    _ record: ABRecord!,
    _ property: ABPropertyID,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>!
) -> Bool {
    guard let box = abRecord(record) else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    box.values.removeValue(forKey: property)
    box.markDirty()
    return true
}

public func ABRecordCopyCompositeName(_ record: ABRecord!) -> Unmanaged<CFString>! {
    guard let box = abRecord(record) else { return nil }
    switch box.recordType {
    case ABRecordType(kABGroupType):
        let name = box.stringValue(kABGroupNameProperty)
        return abPassRetainedString(name)
    case ABRecordType(kABSourceType):
        let name = box.stringValue(kABSourceNameProperty)
        return abPassRetainedString(name)
    default:
        return abPassRetainedString(abCompositeName(box, ignoreOrganization: false))
    }
}
