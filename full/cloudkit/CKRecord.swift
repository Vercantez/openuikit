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
        guard let recordType = coder.decodeObject(of: NSString.self, forKey: CKRecord.ArchiveKey.recordType) as String?,
              let recordID = coder.decodeObject(of: CKRecord.ID.self, forKey: CKRecord.ArchiveKey.recordID)
        else {
            return nil
        }
        self.recordType = recordType
        self.recordID = recordID
        super.init()
        recordChangeTag = coder.decodeObject(of: NSString.self, forKey: CKRecord.ArchiveKey.changeTag) as String?
        creatorUserRecordID = coder.decodeObject(of: CKRecord.ID.self, forKey: CKRecord.ArchiveKey.creator)
        lastModifiedUserRecordID = coder.decodeObject(of: CKRecord.ID.self, forKey: CKRecord.ArchiveKey.lastModified)
        creationDate = coder.decodeObject(of: NSDate.self, forKey: CKRecord.ArchiveKey.creationDate) as Date?
        modificationDate = coder.decodeObject(of: NSDate.self, forKey: CKRecord.ArchiveKey.modificationDate) as Date?
        parent = coder.decodeObject(of: CKRecord.Reference.self, forKey: CKRecord.ArchiveKey.parent)
        share = coder.decodeObject(of: CKRecord.Reference.self, forKey: CKRecord.ArchiveKey.share)
        if let fieldKeys = coder.decodeObject(of: [NSArray.self, NSString.self], forKey: CKRecord.ArchiveKey.fieldKeys) as? [String] {
            for key in fieldKeys {
                if let value = CKRecord.unarchiveValue(coder.decodeObject(forKey: CKRecord.ArchiveKey.fieldPrefix + key)) {
                    store.setObject(value, forKey: key)
                }
            }
            store.clearChangedKeys()
        }
    }

    open func encode(with coder: NSCoder) {
        encodeSystemFields(with: coder)
        let keys = allKeys()
        coder.encode(keys as NSArray, forKey: CKRecord.ArchiveKey.fieldKeys)
        for key in keys {
            CKRecord.archiveValue(object(forKey: key), coder: coder, key: CKRecord.ArchiveKey.fieldPrefix + key)
        }
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
        // Apple full-text token extraction is unobserved on this host.
        []
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
        // Portable system-field archive (CloudKitRuntime NSSecureCoding probe).
        // Not Apple's unpublished CloudKit coder layout.
        coder.encode(recordType as NSString, forKey: CKRecord.ArchiveKey.recordType)
        coder.encode(recordID, forKey: CKRecord.ArchiveKey.recordID)
        if let recordChangeTag {
            coder.encode(recordChangeTag as NSString, forKey: CKRecord.ArchiveKey.changeTag)
        }
        coder.encode(creatorUserRecordID, forKey: CKRecord.ArchiveKey.creator)
        coder.encode(lastModifiedUserRecordID, forKey: CKRecord.ArchiveKey.lastModified)
        coder.encode(creationDate as NSDate?, forKey: CKRecord.ArchiveKey.creationDate)
        coder.encode(modificationDate as NSDate?, forKey: CKRecord.ArchiveKey.modificationDate)
        coder.encode(parent, forKey: CKRecord.ArchiveKey.parent)
        coder.encode(share, forKey: CKRecord.ArchiveKey.share)
    }

    open override func value(forKey key: String) -> Any? {
        if key == CKRecord.SystemFieldKey.recordID { return recordID }
        if key == CKRecord.SystemFieldKey.creatorUserRecordID { return creatorUserRecordID }
        if key == CKRecord.SystemFieldKey.lastModifiedUserRecordID { return lastModifiedUserRecordID }
        if key == CKRecord.SystemFieldKey.creationDate { return creationDate }
        if key == CKRecord.SystemFieldKey.modificationDate { return modificationDate }
        if key == CKRecord.SystemFieldKey.parent { return parent }
        if key == CKRecord.SystemFieldKey.share { return share }
        return object(forKey: key)
    }

    enum ArchiveKey {
        static let recordType = "ck.recordType"
        static let recordID = "ck.recordID"
        static let changeTag = "ck.recordChangeTag"
        static let creator = "ck.creatorUserRecordID"
        static let lastModified = "ck.lastModifiedUserRecordID"
        static let creationDate = "ck.creationDate"
        static let modificationDate = "ck.modificationDate"
        static let parent = "ck.parent"
        static let share = "ck.share"
        static let fieldKeys = "ck.fieldKeys"
        static let fieldPrefix = "ck.field."
    }

    open func makeIterator() -> CKRecordKeyValueIterator {
        CKRecordKeyValueIterator(store.pairs())
    }
}

extension CKRecord: Sequence {}

extension CKRecord {
    @objc(CKRecordID)
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
            guard let recordName = coder.decodeObject(of: NSString.self, forKey: "ck.recordName") as String?,
                  let zoneID = coder.decodeObject(of: CKRecordZone.ID.self, forKey: "ck.zoneID")
            else {
                return nil
            }
            self.recordName = recordName
            self.zoneID = zoneID
            super.init()
        }

        open func encode(with coder: NSCoder) {
            coder.encode(recordName as NSString, forKey: "ck.recordName")
            coder.encode(zoneID, forKey: "ck.zoneID")
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

    @objc(CKReference)
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
            guard let recordID = coder.decodeObject(of: CKRecord.ID.self, forKey: "ck.ref.recordID") else {
                return nil
            }
            self.recordID = recordID
            let raw = coder.decodeInteger(forKey: "ck.ref.action")
            self.action = CKRecord.ReferenceAction(rawValue: UInt(raw)) ?? .none
            super.init()
        }

        open func encode(with coder: NSCoder) {
            coder.encode(recordID, forKey: "ck.ref.recordID")
            coder.encode(Int(action.rawValue), forKey: "ck.ref.action")
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

open class CKAsset: NSObject, NSSecureCoding, @unchecked Sendable {
    open private(set) var fileURL: URL?

    public static var supportsSecureCoding: Bool { true }

    public init(fileURL: URL) {
        self.fileURL = fileURL
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let path = coder.decodeObject(of: NSString.self, forKey: "ck.asset.path") as String? else {
            return nil
        }
        self.fileURL = URL(fileURLWithPath: path)
        super.init()
    }

    open func encode(with coder: NSCoder) {
        if let fileURL {
            coder.encode(fileURL.path as NSString, forKey: "ck.asset.path")
        }
    }
}

extension CKAsset: CKRecordValueProtocol {}
extension CKRecord.Reference: CKRecordValueProtocol {}

extension CKRecord {
    func ck_copy(desiredKeys: [CKRecord.FieldKey]? = nil) -> CKRecord {
        let copy: CKRecord
        if let share = self as? CKShare {
            copy = share.ck_copyShare()
        } else {
            copy = CKRecord(_recordType: recordType, recordID: recordID)
        }
        copy.ck_setSystemFields(
            changeTag: recordChangeTag,
            creationDate: creationDate,
            modificationDate: modificationDate,
            creator: creatorUserRecordID,
            lastModified: lastModifiedUserRecordID,
            share: share
        )
        copy.parent = parent
        copy.store.replaceAll(from: store, keys: desiredKeys)
        copy.encryptedStore.replaceAll(from: encryptedStore, keys: desiredKeys)
        copy.store.clearChangedKeys()
        copy.encryptedStore.clearChangedKeys()
        return copy
    }

    func ck_setSystemFields(
        changeTag: String?,
        creationDate: Date?,
        modificationDate: Date?,
        creator: CKRecord.ID?,
        lastModified: CKRecord.ID?,
        share: CKRecord.Reference?
    ) {
        self.recordChangeTag = changeTag
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.creatorUserRecordID = creator
        self.lastModifiedUserRecordID = lastModified
        self.share = share
    }

    func ck_clearChangedKeys() {
        store.clearChangedKeys()
        encryptedStore.clearChangedKeys()
    }

    func ck_mergeChanged(from client: CKRecord) {
        store.mergeChanged(from: client.store)
        encryptedStore.mergeChanged(from: client.encryptedStore)
        parent = client.parent
    }

    func ck_ingestAssets(using database: CKSimulatedDatabaseState) throws {
        for key in store.allKeys() {
            if let value = store.object(forKey: key) {
                store.setObject(try database.ingestValue(value), forKey: key)
            }
        }
        store.clearChangedKeys()
    }

    static func archiveValue(_ value: (any CKRecordValue)?, coder: NSCoder, key: String) {
        guard let value else { return }
        if let text = value as? String {
            coder.encode(text as NSString, forKey: key)
        } else if let text = value as? NSString {
            coder.encode(text, forKey: key)
        } else if let number = value as? NSNumber {
            coder.encode(number, forKey: key)
        } else if let number = value as? Int {
            coder.encode(NSNumber(value: number), forKey: key)
        } else if let number = value as? Int64 {
            coder.encode(NSNumber(value: number), forKey: key)
        } else if let number = value as? Double {
            coder.encode(NSNumber(value: number), forKey: key)
        } else if let number = value as? Float {
            coder.encode(NSNumber(value: number), forKey: key)
        } else if let number = value as? Bool {
            coder.encode(NSNumber(value: number), forKey: key)
        } else if let date = value as? Date {
            coder.encode(date as NSDate, forKey: key)
        } else if let data = value as? Data {
            coder.encode(data as NSData, forKey: key)
        } else if let asset = value as? CKAsset {
            coder.encode(asset, forKey: key)
        } else if let reference = value as? CKRecord.Reference {
            coder.encode(reference, forKey: key)
        } else if let values = value as? [String] {
            coder.encode(values as NSArray, forKey: key)
        } else if let values = value as? [NSNumber] {
            coder.encode(values as NSArray, forKey: key)
        }
    }

    static func unarchiveValue(_ value: Any?) -> (any CKRecordValue)? {
        if let text = value as? String { return text }
        if let text = value as? NSString { return text as String }
        if let number = value as? NSNumber { return number }
        if let date = value as? Date { return date }
        if let date = value as? NSDate { return date as Date }
        if let data = value as? Data { return data }
        if let data = value as? NSData { return data as Data }
        if let asset = value as? CKAsset { return asset }
        if let reference = value as? CKRecord.Reference { return reference }
        if let values = value as? [String] { return values }
        if let values = value as? [NSNumber] { return values }
        return nil
    }
}
