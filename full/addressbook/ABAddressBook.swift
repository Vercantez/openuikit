import CoreFoundation
import Foundation

/// Linux has no Contacts daemon or privacy prompt. Authorization is always
/// `.denied`. Request-access delivers `granted=false` and
/// `kABOperationNotPermittedByUserError` inline so tests do not need a run loop.
/// `ABAddressBookCreate` still returns an isolated in-process book so record,
/// multi-value, and vCard APIs have a store; it is never the host address book.
public func ABAddressBookGetAuthorizationStatus() -> ABAuthorizationStatus {
    .denied
}

public func ABAddressBookCreate() -> Unmanaged<ABAddressBook>! {
    Unmanaged.passRetained(ABAddressBookBox())
}

public func ABAddressBookCreateWithOptions(
    _ options: CFDictionary!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>!
) -> Unmanaged<ABAddressBook>! {
    _ = options
    _ = error
    return ABAddressBookCreate()
}

public func ABAddressBookRequestAccessWithCompletion(
    _ addressBook: ABAddressBook!,
    _ completion: ABAddressBookRequestAccessCompletionHandler!
) {
    _ = addressBook
    guard let completion else { return }
    let nsError = NSError(
        domain: "ABAddressBookErrorDomain",
        code: kABOperationNotPermittedByUserError,
        userInfo: nil
    )
    completion(false, unsafeBitCast(nsError, to: CFError.self))
}

public func ABAddressBookHasUnsavedChanges(_ addressBook: ABAddressBook!) -> Bool {
    abBook(addressBook)?.hasUnsavedChanges ?? false
}

public func ABAddressBookSave(
    _ addressBook: ABAddressBook!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>!
) -> Bool {
    guard let book = abBook(addressBook) else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    book.lock.lock()
    defer { book.lock.unlock() }
    book.snapshot = book.records.map { $0.cloneDetached() }
    book.hasUnsavedChanges = false
    return true
}

public func ABAddressBookRevert(_ addressBook: ABAddressBook!) {
    guard let book = abBook(addressBook) else { return }
    book.lock.lock()
    defer { book.lock.unlock() }
    let restored = book.snapshot.map { $0.cloneDetached() }
    for record in restored {
        record.book = book
        if record.recordType == ABRecordType(kABSourceType), record.recordID == 1 {
            book.defaultSource = record
        }
    }
    book.records = restored
    book.hasUnsavedChanges = false
}

public func ABAddressBookAddRecord(
    _ addressBook: ABAddressBook!,
    _ record: ABRecord!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>!
) -> Bool {
    guard let book = abBook(addressBook), let box = abRecord(record) else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    book.lock.lock()
    defer { book.lock.unlock() }
    if book.records.contains(where: { $0 === box }) {
        return true
    }
    book.assignID(box)
    if box.source == nil, box.recordType != ABRecordType(kABSourceType) {
        box.source = book.defaultSource
    }
    box.book = book
    book.records.append(box)
    book.hasUnsavedChanges = true
    return true
}

public func ABAddressBookRemoveRecord(
    _ addressBook: ABAddressBook!,
    _ record: ABRecord!,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>!
) -> Bool {
    guard let book = abBook(addressBook), let box = abRecord(record) else {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    book.lock.lock()
    defer { book.lock.unlock() }
    if box.recordType == ABRecordType(kABSourceType), box === book.defaultSource {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    let before = book.records.count
    book.records.removeAll { $0 === box }
    if book.records.count == before {
        abWriteError(error, code: kABOperationNotPermittedByStoreError)
        return false
    }
    for group in book.groups() {
        group.members.removeAll { $0 === box }
    }
    box.book = nil
    book.hasUnsavedChanges = true
    return true
}

public func ABAddressBookGetPersonCount(_ addressBook: ABAddressBook!) -> CFIndex {
    guard let book = abBook(addressBook) else { return 0 }
    return CFIndex(book.people().count)
}

public func ABAddressBookGetGroupCount(_ addressBook: ABAddressBook!) -> CFIndex {
    guard let book = abBook(addressBook) else { return 0 }
    return CFIndex(book.groups().count)
}

public func ABAddressBookCopyArrayOfAllPeople(_ addressBook: ABAddressBook!) -> Unmanaged<CFArray>! {
    guard let book = abBook(addressBook) else { return nil }
    return abPassRetainedArray(book.people())
}

public func ABAddressBookCopyArrayOfAllGroups(_ addressBook: ABAddressBook!) -> Unmanaged<CFArray>! {
    guard let book = abBook(addressBook) else { return nil }
    return abPassRetainedArray(book.groups())
}

public func ABAddressBookCopyArrayOfAllSources(_ addressBook: ABAddressBook!) -> Unmanaged<CFArray>! {
    guard let book = abBook(addressBook) else { return nil }
    return abPassRetainedArray(book.sources())
}

public func ABAddressBookCopyDefaultSource(_ addressBook: ABAddressBook!) -> Unmanaged<ABRecord>! {
    guard let book = abBook(addressBook) else { return nil }
    return Unmanaged.passUnretained(book.defaultSource)
}

public func ABAddressBookGetPersonWithRecordID(
    _ addressBook: ABAddressBook!,
    _ recordID: ABRecordID
) -> Unmanaged<ABRecord>! {
    guard let book = abBook(addressBook),
          let person = book.people().first(where: { $0.recordID == recordID })
    else { return nil }
    return Unmanaged.passUnretained(person)
}

public func ABAddressBookGetGroupWithRecordID(
    _ addressBook: ABAddressBook!,
    _ recordID: ABRecordID
) -> Unmanaged<ABRecord>! {
    guard let book = abBook(addressBook),
          let group = book.groups().first(where: { $0.recordID == recordID })
    else { return nil }
    return Unmanaged.passUnretained(group)
}

public func ABAddressBookGetSourceWithRecordID(
    _ addressBook: ABAddressBook!,
    _ sourceID: ABRecordID
) -> Unmanaged<ABRecord>! {
    guard let book = abBook(addressBook),
          let source = book.sources().first(where: { $0.recordID == sourceID })
    else { return nil }
    return Unmanaged.passUnretained(source)
}

public func ABAddressBookCopyArrayOfAllPeopleInSource(
    _ addressBook: ABAddressBook!,
    _ source: ABRecord!
) -> Unmanaged<CFArray>! {
    guard let book = abBook(addressBook), let sourceBox = abRecord(source) else { return nil }
    let people = book.people().filter { $0.source === sourceBox || $0.source == nil }
    return abPassRetainedArray(people)
}

public func ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(
    _ addressBook: ABAddressBook!,
    _ source: ABRecord!,
    _ sortOrdering: ABPersonSortOrdering
) -> Unmanaged<CFArray>! {
    guard let book = abBook(addressBook), let sourceBox = abRecord(source) else { return nil }
    let people = book.people().filter { $0.source === sourceBox || $0.source == nil }
    return abPassRetainedArray(abSortPeople(people, ordering: sortOrdering))
}

public func ABAddressBookCopyArrayOfAllGroupsInSource(
    _ addressBook: ABAddressBook!,
    _ source: ABRecord!
) -> Unmanaged<CFArray>! {
    guard let book = abBook(addressBook), let sourceBox = abRecord(source) else { return nil }
    let groups = book.groups().filter { $0.source === sourceBox || $0.source == nil }
    return abPassRetainedArray(groups)
}

public func ABAddressBookCopyPeopleWithName(
    _ addressBook: ABAddressBook!,
    _ name: CFString!
) -> Unmanaged<CFArray>! {
    guard let book = abBook(addressBook) else { return nil }
    let needle = (abString(name) ?? "").lowercased()
    if needle.isEmpty {
        return abPassRetainedArray([])
    }
    let matches = book.people().filter { person in
        let composite = abCompositeName(person, ignoreOrganization: false).lowercased()
        let first = person.stringValue(kABPersonFirstNameProperty).lowercased()
        let last = person.stringValue(kABPersonLastNameProperty).lowercased()
        return composite.contains(needle) || first.contains(needle) || last.contains(needle)
    }
    return abPassRetainedArray(matches)
}

public func ABAddressBookCopyLocalizedLabel(_ label: CFString!) -> Unmanaged<CFString>! {
    guard let raw = abString(label) else {
        return abPassRetainedString("")
    }
    if raw.hasPrefix("_$!<"), raw.hasSuffix(">!$_"), raw.count > 8 {
        let start = raw.index(raw.startIndex, offsetBy: 4)
        let end = raw.index(raw.endIndex, offsetBy: -4)
        return abPassRetainedString(String(raw[start..<end]))
    }
    return abPassRetainedString(raw)
}

public func ABAddressBookRegisterExternalChangeCallback(
    _ addressBook: ABAddressBook!,
    _ callback: ABExternalChangeCallback!,
    _ context: UnsafeMutableRawPointer!
) {
    guard let book = abBook(addressBook), let callback else { return }
    book.lock.lock()
    defer { book.lock.unlock() }
    book.callbacks.append(ABExternalCallbackEntry(callback: callback, context: context))
}

public func ABAddressBookUnregisterExternalChangeCallback(
    _ addressBook: ABAddressBook!,
    _ callback: ABExternalChangeCallback!,
    _ context: UnsafeMutableRawPointer!
) {
    guard let book = abBook(addressBook) else { return }
    book.lock.lock()
    defer { book.lock.unlock() }
    book.callbacks.removeAll { entry in
        entry.context == context
    }
    _ = callback
}
