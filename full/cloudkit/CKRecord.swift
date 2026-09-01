import Foundation

public enum CKAccountStatus: Int, Sendable, Hashable {
    case couldNotDetermine = 0
    case available = 1
    case restricted = 2
    case noAccount = 3
    case temporarilyUnavailable = 4
}

open class CKRecord: NSObject, NSSecureCoding, @unchecked Sendable {
    public typealias RecordType = String
    public typealias FieldKey = String
    public typealias Element = (CKRecord.FieldKey, any CKRecordValueProtocol)
    public typealias Iterator = CKRecordKeyValueIterator

    public enum ReferenceAction: UInt, Sendable, Hashable {
        case none = 0
        case deleteSelf = 1
    }

    public enum SystemType {
        public static let userRecord: CKRecord.RecordType = CKRecordTypeUserRecord
        public static let share: CKRecord.RecordType = CKRecordTypeShare
    }

    public enum SystemFieldKey {
        public static var recordID: CKRecord.FieldKey { "recordID" }
        public static var creatorUserRecordID: CKRecord.FieldKey { "creatorUserRecordID" }
        public static var lastModifiedUserRecordID: CKRecord.FieldKey { "lastModifiedUserRecordID" }
        public static var creationDate: CKRecord.FieldKey { "creationDate" }
        public static var modificationDate: CKRecord.FieldKey { "modificationDate" }
        public static let parent: CKRecord.FieldKey = CKRecordParentKey
        public static let share: CKRecord.FieldKey = CKRecordShareKey
    }

    open private(set) var recordType: CKRecord.RecordType
    open private(set) var recordID: CKRecord.ID
    open private(set) var recordChangeTag: String?
    open private(set) var creatorUserRecordID: CKRecord.ID?
    open private(set) var lastModifiedUserRecordID: CKRecord.ID?
    open private(set) var creationDate: Date?
    open private(set) var modificationDate: Date?
    open var parent: CKRecord.Reference?
    open private(set) var share: CKRecord.Reference?

    private let store = CKRecordValueStore()
    private let encryptedStore = CKRecordValueStore()

    public static var supportsSecureCoding: Bool { true }

    public convenience init(recordType: CKRecord.RecordType, recordID: CKRecord.ID = CKRecord.ID()) {
        self.init(_recordType: recordType, recordID: recordID)
    }

    public convenience init(recordType: CKRecord.RecordType, zoneID: CKRecordZone.ID) {
        self.init(
            recordType: recordType,
            recordID: CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID)
        )
    }

    init(_recordType: CKRecord.RecordType, recordID: CKRecord.ID) {
        self.recordType = _recordType
        self.recordID = recordID
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    open var encryptedValues: any CKRecordKeyValueSetting & Sendable {
        encryptedStore
    }

    open func allKeys() -> [CKRecord.FieldKey] {
        store.allKeys()
    }

    open func changedKeys() -> [CKRecord.FieldKey] {
        store.changedKeys()
    }

    open func allTokens() -> [String] {
        store.pairs().compactMap { _, value in value as? String }
    }

    open func object(forKey key: CKRecord.FieldKey) -> (any CKRecordValue)? {
        store.object(forKey: key)
    }

    open func setObject(_ object: (any CKRecordValue)?, forKey key: CKRecord.FieldKey) {
        store.setObject(object, forKey: key)
    }

    open subscript(key: CKRecord.FieldKey) -> (any CKRecordValue)? {
        get { store.object(forKey: key) }
        set { store.setObject(newValue, forKey: key) }
    }

    open subscript<T>(key: CKRecord.FieldKey) -> T? where T: CKRecordValueProtocol {
        get { store.object(forKey: key) as? T }
        set { store.setObject(newValue, forKey: key) }
    }

    open func setParent(_ parentRecord: CKRecord?) {
        if let parentRecord {
            parent = CKRecord.Reference(record: parentRecord, action: .none)
        } else {
            parent = nil
        }
    }

    open func setParent(_ parentRecordID: CKRecord.ID?) {
        if let parentRecordID {
            parent = CKRecord.Reference(recordID: parentRecordID, action: .none)
        } else {
            parent = nil
        }
    }

    open func encodeSystemFields(with coder: NSCoder) {
        // Apple's system-field archive layout is not published. Linux does not
        // emit a fabricated Apple archive.
        _ = coder
    }

    open func makeIterator() -> CKRecordKeyValueIterator {
        CKRecordKeyValueIterator(store.pairs())
    }
}

extension CKRecord: Sequence {}

extension CKRecord {
    open class ID: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
        open private(set) var recordName: String
        open private(set) var zoneID: CKRecordZone.ID

        public static var supportsSecureCoding: Bool { true }

        public convenience init(
            recordName: String = UUID().uuidString,
            zoneID: CKRecordZone.ID = CKRecordZone.ID.default
        ) {
            self.init(_recordName: recordName, zoneID: zoneID)
        }

        init(_recordName: String, zoneID: CKRecordZone.ID) {
            self.recordName = _recordName
            self.zoneID = zoneID
            super.init()
        }

        public required init?(coder: NSCoder) {
            _ = coder
            return nil
        }

        open func encode(with coder: NSCoder) {
            _ = coder
        }

        open func copy(with zone: NSZone? = nil) -> Any {
            CKRecord.ID(_recordName: recordName, zoneID: zoneID)
        }

        open override var hash: Int {
            var hasher = Hasher()
            hasher.combine(recordName)
            hasher.combine(zoneID.zoneName)
            hasher.combine(zoneID.ownerName)
            return hasher.finalize()
        }

        open override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? CKRecord.ID else { return false }
            return recordName == other.recordName && zoneID.isEqual(other.zoneID)
        }
    }

    open class Reference: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
        public typealias Action = CKRecord.ReferenceAction

        open private(set) var recordID: CKRecord.ID
        open private(set) var action: CKRecord.ReferenceAction

        public var referenceAction: CKRecord.ReferenceAction { action }

        public static var supportsSecureCoding: Bool { true }

        public convenience init(record: CKRecord, action: CKRecord.ReferenceAction) {
            self.init(recordID: record.recordID, action: action)
        }

        public init(recordID: CKRecord.ID, action: CKRecord.ReferenceAction) {
            self.recordID = recordID
            self.action = action
            super.init()
        }

        public required init?(coder: NSCoder) {
            _ = coder
            return nil
        }

        open func encode(with coder: NSCoder) {
            _ = coder
        }

        open func copy(with zone: NSZone? = nil) -> Any {
            CKRecord.Reference(recordID: recordID, action: action)
        }

        open override var hash: Int {
            var hasher = Hasher()
            hasher.combine(recordID.hash)
            hasher.combine(action)
            return hasher.finalize()
        }

        open override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? CKRecord.Reference else { return false }
            return recordID.isEqual(other.recordID) && action == other.action
        }
    }
}

open class CKAsset: NSObject, @unchecked Sendable {
    open private(set) var fileURL: URL?

    public init(fileURL: URL) {
        self.fileURL = fileURL
        super.init()
    }
}

extension CKAsset: CKRecordValueProtocol {}
extension CKRecord.Reference: CKRecordValueProtocol {}
