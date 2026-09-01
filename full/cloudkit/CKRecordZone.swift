import Foundation

open class CKRecordZone: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public struct Capabilities: OptionSet, Sendable, Hashable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let fetchChanges = Capabilities(rawValue: 1 << 0)
        public static let atomic = Capabilities(rawValue: 1 << 1)
        public static let sharing = Capabilities(rawValue: 1 << 2)
        public static let zoneWideSharing = Capabilities(rawValue: 1 << 3)
    }

    public enum EncryptionScope: Int, Sendable, Hashable {
        case perRecord = 0
        case perZone = 1
    }

    open private(set) var zoneID: CKRecordZone.ID
    open private(set) var capabilities: CKRecordZone.Capabilities
    open var encryptionScope: CKRecordZone.EncryptionScope
    open private(set) var share: CKRecord.Reference?

    public static var supportsSecureCoding: Bool { true }

    open class func `default`() -> CKRecordZone {
        CKRecordZone(zoneID: .default)
    }

    public init(zoneName: String) {
        self.zoneID = CKRecordZone.ID(zoneName: zoneName)
        self.capabilities = []
        self.encryptionScope = .perRecord
        super.init()
    }

    public init(zoneID: CKRecordZone.ID) {
        self.zoneID = zoneID
        self.capabilities = []
        self.encryptionScope = .perRecord
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
        let copied = CKRecordZone(zoneID: zoneID)
        copied.encryptionScope = encryptionScope
        return copied
    }

    open override var hash: Int {
        zoneID.hash
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CKRecordZone else { return false }
        return zoneID.isEqual(other.zoneID)
    }
}

extension CKRecordZone {
    open class ID: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
        public static let defaultZoneName = CKRecordZoneDefaultName
        public static let `default` = CKRecordZone.ID(
            zoneName: CKRecordZone.ID.defaultZoneName,
            ownerName: CKCurrentUserDefaultName
        )

        open private(set) var zoneName: String
        open private(set) var ownerName: String

        public static var supportsSecureCoding: Bool { true }

        public convenience init(
            zoneName: String = CKRecordZone.ID.defaultZoneName,
            ownerName: String = CKCurrentUserDefaultName
        ) {
            self.init(_zoneName: zoneName, ownerName: ownerName)
        }

        init(_zoneName: String, ownerName: String) {
            self.zoneName = _zoneName
            self.ownerName = ownerName
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
            CKRecordZone.ID(_zoneName: zoneName, ownerName: ownerName)
        }

        open override var hash: Int {
            var hasher = Hasher()
            hasher.combine(zoneName)
            hasher.combine(ownerName)
            return hasher.finalize()
        }

        open override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? CKRecordZone.ID else { return false }
            return zoneName == other.zoneName && ownerName == other.ownerName
        }
    }
}

open class CKQuery: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    open private(set) var recordType: CKRecord.RecordType
    open private(set) var predicate: NSPredicate
    open var sortDescriptors: [NSSortDescriptor]?

    public static var supportsSecureCoding: Bool { true }

    public convenience init(recordType: CKRecord.RecordType, predicate: NSPredicate) {
        self.init(_recordType: recordType, predicate: predicate)
    }

    init(_recordType: CKRecord.RecordType, predicate: NSPredicate) {
        self.recordType = _recordType
        self.predicate = predicate
        super.init()
    }

    public required init(coder aDecoder: NSCoder) {
        _ = aDecoder
        self.recordType = ""
        self.predicate = NSPredicate(value: false)
        super.init()
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copied = CKQuery(_recordType: recordType, predicate: predicate)
        copied.sortDescriptors = sortDescriptors
        return copied
    }
}

open class CKServerChangeToken: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public override init() {
        super.init()
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        CKServerChangeToken()
    }
}
