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
        guard let zoneID = coder.decodeObject(of: CKRecordZone.ID.self, forKey: "ck.zone.zoneID") else {
            return nil
        }
        self.zoneID = zoneID
        self.capabilities = CKRecordZone.Capabilities(rawValue: UInt(coder.decodeInteger(forKey: "ck.zone.capabilities")))
        let rawScope = coder.decodeInteger(forKey: "ck.zone.encryption")
        self.encryptionScope = CKRecordZone.EncryptionScope(rawValue: rawScope) ?? .perRecord
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(zoneID, forKey: "ck.zone.zoneID")
        coder.encode(Int(capabilities.rawValue), forKey: "ck.zone.capabilities")
        coder.encode(encryptionScope.rawValue, forKey: "ck.zone.encryption")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        ck_copyZone()
    }

    func ck_copyZone() -> CKRecordZone {
        let copied = CKRecordZone(zoneID: zoneID)
        copied.encryptionScope = encryptionScope
        copied.ck_setCapabilities(capabilities)
        return copied
    }

    func ck_setCapabilities(_ capabilities: CKRecordZone.Capabilities) {
        self.capabilities = capabilities
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
    @objc(CKRecordZoneID)
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
            guard let zoneName = coder.decodeObject(of: NSString.self, forKey: "ck.zoneName") as String?,
                  let ownerName = coder.decodeObject(of: NSString.self, forKey: "ck.ownerName") as String?
            else {
                return nil
            }
            self.zoneName = zoneName
            self.ownerName = ownerName
            super.init()
        }

        open func encode(with coder: NSCoder) {
            coder.encode(zoneName as NSString, forKey: "ck.zoneName")
            coder.encode(ownerName as NSString, forKey: "ck.ownerName")
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
        let recordType = aDecoder.decodeObject(of: NSString.self, forKey: "ck.query.recordType") as String? ?? ""
        let predicate = aDecoder.decodeObject(of: NSPredicate.self, forKey: "ck.query.predicate") ?? NSPredicate(value: false)
        self.recordType = recordType
        self.predicate = predicate
        super.init()
        sortDescriptors = aDecoder.decodeObject(of: [NSArray.self, NSSortDescriptor.self], forKey: "ck.query.sort") as? [NSSortDescriptor]
    }

    open func encode(with coder: NSCoder) {
        coder.encode(recordType as NSString, forKey: "ck.query.recordType")
        coder.encode(predicate, forKey: "ck.query.predicate")
        coder.encode(sortDescriptors as NSArray?, forKey: "ck.query.sort")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copied = CKQuery(_recordType: recordType, predicate: predicate)
        copied.sortDescriptors = sortDescriptors
        return copied
    }
}

open class CKServerChangeToken: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    private(set) var ck_sequence: UInt64

    public required init?(coder: NSCoder) {
        ck_sequence = UInt64(bitPattern: Int64(coder.decodeInt64(forKey: "ck.token.seq")))
        super.init()
    }

    public override init() {
        self.ck_sequence = 0
        super.init()
    }

    static func ck_make(sequence: UInt64) -> CKServerChangeToken {
        let token = CKServerChangeToken()
        token.ck_sequence = sequence
        return token
    }

    open func encode(with coder: NSCoder) {
        coder.encode(Int64(bitPattern: ck_sequence), forKey: "ck.token.seq")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        CKServerChangeToken.ck_make(sequence: ck_sequence)
    }

    open override var hash: Int {
        Int(truncatingIfNeeded: ck_sequence)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CKServerChangeToken else { return false }
        return ck_sequence == other.ck_sequence
    }
}
