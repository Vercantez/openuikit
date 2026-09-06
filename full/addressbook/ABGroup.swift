import CoreFoundation
import Foundation

public func ABGroupCreate() -> Unmanaged<ABRecord>! {
    Unmanaged.passRetained(ABRecordBox(recordType: ABRecordType(kABGroupType)))
}

public func ABGroupCreateInSource(_ source: ABRecord!) -> Unmanaged<ABRecord>! {
    guard let sourceBox = abRecord(source), sourceBox.recordType == ABRecordType(kABSourceType) else {
        return nil
    }
    let group = ABRecordBox(recordType: ABRecordType(kABGroupType))
    group.source = sourceBox
    return Unmanaged.passRetained(group)
}

public func ABGroupCopySource(_ group: ABRecord!) -> Unmanaged<ABRecord>! {
    guard let box = abRecord(group), let source = box.source ?? box.book?.defaultSource else {
        return nil
    }
    return Unmanaged.passUnretained(source)
}

public func ABGroupAddMember(
    _ group: ABRecord!,
    _ person: ABRecord!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>!
) -> Bool {
    guard let groupBox = abRecord(group), groupBox.recordType == ABRecordType(kABGroupType) else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    guard let personBox = abRecord(person), personBox.recordType == ABRecordType(kABPersonType) else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    if !groupBox.members.contains(where: { $0 === personBox }) {
        groupBox.members.append(personBox)
        groupBox.markDirty()
    }
    return true
}

public func ABGroupRemoveMember(
    _ group: ABRecord!,
    _ member: ABRecord!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>!
) -> Bool {
    guard let groupBox = abRecord(group), groupBox.recordType == ABRecordType(kABGroupType) else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    guard let personBox = abRecord(member) else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    let before = groupBox.members.count
    groupBox.members.removeAll { $0 === personBox }
    if groupBox.members.count == before {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    groupBox.markDirty()
    return true
}

public func ABGroupCopyArrayOfAllMembers(_ group: ABRecord!) -> Unmanaged<CFArray>! {
    guard let box = abRecord(group) else { return nil }
    return abPassRetainedArray(box.members)
}

public func ABGroupCopyArrayOfAllMembersWithSortOrdering(
    _ group: ABRecord!,
    _ sortOrdering: ABPersonSortOrdering
) -> Unmanaged<CFArray>! {
    guard let box = abRecord(group) else { return nil }
    return abPassRetainedArray(abSortPeople(box.members, ordering: sortOrdering))
}
