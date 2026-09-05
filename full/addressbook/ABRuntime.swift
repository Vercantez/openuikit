import CoreFoundation
import Foundation

final class ABMultiValueEntry {
    var value: AnyObject
    var label: String?
    var identifier: ABMultiValueIdentifier

    init(value: AnyObject, label: String?, identifier: ABMultiValueIdentifier) {
        self.value = value
        self.label = label
        self.identifier = identifier
    }

    func copy() -> ABMultiValueEntry {
        ABMultiValueEntry(value: value, label: label, identifier: identifier)
    }
}

final class ABMultiValueBox: NSObject {
    let propertyType: ABPropertyType
    var mutable: Bool
    var entries: [ABMultiValueEntry]
    var nextIdentifier: ABMultiValueIdentifier

    init(propertyType: ABPropertyType, mutable: Bool) {
        self.propertyType = propertyType
        self.mutable = mutable
        self.entries = []
        self.nextIdentifier = 0
    }

    func mutableCopyBox() -> ABMultiValueBox {
        let copy = ABMultiValueBox(propertyType: propertyType, mutable: true)
        copy.entries = entries.map { $0.copy() }
        copy.nextIdentifier = nextIdentifier
        return copy
    }
}

final class ABRecordBox: NSObject {
    let recordType: ABRecordType
    var recordID: ABRecordID
    var values: [ABPropertyID: AnyObject]
    var imageData: Data?
    weak var book: ABAddressBookBox?
    weak var source: ABRecordBox?
    var members: [ABRecordBox]

    init(recordType: ABRecordType) {
        self.recordType = recordType
        self.recordID = kABRecordInvalidID
        self.values = [:]
        self.imageData = nil
        self.members = []
    }

    func cloneDetached() -> ABRecordBox {
        let copy = ABRecordBox(recordType: recordType)
        copy.recordID = recordID
        copy.values = values.mapValues { value in
            if let multi = value as? ABMultiValueBox {
                return multi.mutableCopyBox()
            }
            return value
        }
        copy.imageData = imageData
        return copy
    }

    func stringValue(_ property: ABPropertyID) -> String {
        abStringValue(values[property]) ?? ""
    }

    func markDirty() {
        book?.hasUnsavedChanges = true
    }
}

final class ABExternalCallbackEntry {
    let callback: ABExternalChangeCallback
    let context: UnsafeMutableRawPointer?

    init(callback: @escaping ABExternalChangeCallback, context: UnsafeMutableRawPointer?) {
        self.callback = callback
        self.context = context
    }
}

final class ABAddressBookBox: NSObject {
    let lock = NSLock()
    var records: [ABRecordBox]
    var nextRecordID: ABRecordID
    var hasUnsavedChanges: Bool
    var defaultSource: ABRecordBox
    var callbacks: [ABExternalCallbackEntry]
    var snapshot: [ABRecordBox]

    override init() {
        self.records = []
        self.nextRecordID = 1
        self.hasUnsavedChanges = false
        self.callbacks = []
        self.snapshot = []
        let source = ABRecordBox(recordType: ABRecordType(kABSourceType))
        source.recordID = 1
        source.values[kABSourceNameProperty] = abCFString("Local") as AnyObject
        source.values[kABSourceTypeProperty] = abCFNumber(kABSourceTypeLocal) as AnyObject
        self.defaultSource = source
        self.records.append(source)
        self.nextRecordID = 2
        super.init()
        source.book = self
        self.snapshot = captureSnapshot()
    }

    func captureSnapshot() -> [ABRecordBox] {
        records.map { record in
            let copy = record.cloneDetached()
            copy.source = record.source
            copy.members = record.members
            return copy
        }
    }

    func assignID(_ record: ABRecordBox) {
        if record.recordID == kABRecordInvalidID {
            record.recordID = nextRecordID
            nextRecordID += 1
        }
    }

    func people() -> [ABRecordBox] {
        records.filter { $0.recordType == ABRecordType(kABPersonType) }
    }

    func groups() -> [ABRecordBox] {
        records.filter { $0.recordType == ABRecordType(kABGroupType) }
    }

    func sources() -> [ABRecordBox] {
        records.filter { $0.recordType == ABRecordType(kABSourceType) }
    }
}

func abBook(_ value: ABAddressBook?) -> ABAddressBookBox? {
    value as? ABAddressBookBox
}

func abRecord(_ value: ABRecord?) -> ABRecordBox? {
    value as? ABRecordBox
}

func abMulti(_ value: ABMultiValue?) -> ABMultiValueBox? {
    value as? ABMultiValueBox
}

func abSortPeople(_ people: [ABRecordBox], ordering: ABPersonSortOrdering) -> [ABRecordBox] {
    people.sorted { lhs, rhs in
        ABPersonComparePeopleByName(lhs, rhs, ordering) == .compareLessThan
    }
}
