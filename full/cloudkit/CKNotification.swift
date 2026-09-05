import Foundation

open class CKNotification: NSObject, @unchecked Sendable {
    public enum NotificationType: Int, Sendable, Hashable {
        case query = 1
        case recordZone = 2
        case readNotification = 3
        case database = 4
    }

    open class ID: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
        public static var supportsSecureCoding: Bool { true }
        var ck_payload: String = ""

        public required init?(coder: NSCoder) {
            ck_payload = coder.decodeObject(of: NSString.self, forKey: "ck.nid") as String? ?? ""
            super.init()
        }

        public override init() {
            super.init()
        }

        open func encode(with coder: NSCoder) {
            coder.encode(ck_payload as NSString, forKey: "ck.nid")
        }

        open func copy(with zone: NSZone? = nil) -> Any {
            let copied = CKNotification.ID()
            copied.ck_payload = ck_payload
            return copied
        }
    }

    open private(set) var alertActionLocalizationKey: String?
    open private(set) var alertBody: String?
    open private(set) var alertLaunchImage: String?
    open private(set) var alertLocalizationArgs: [String]?
    open private(set) var alertLocalizationKey: String?
    open private(set) var badge: NSNumber?
    open private(set) var category: String?
    open private(set) var containerIdentifier: String?
    open private(set) var isPruned: Bool
    open private(set) var notificationID: CKNotification.ID?
    open private(set) var notificationType: CKNotification.NotificationType
    open private(set) var soundName: String?
    open private(set) var subscriptionOwnerUserRecordID: CKRecord.ID?
    open private(set) var subtitle: String?
    open private(set) var subtitleLocalizationArgs: [String]?
    open private(set) var subtitleLocalizationKey: String?
    open private(set) var title: String?
    open private(set) var titleLocalizationArgs: [String]?
    open private(set) var titleLocalizationKey: String?
    open private(set) var subscriptionID: CKSubscription.ID?

    init(type: CKNotification.NotificationType) {
        self.notificationType = type
        self.isPruned = false
        super.init()
    }

    public convenience init?(fromRemoteNotificationDictionary notificationDictionary: [AnyHashable: Any]) {
        // Documented CloudKit remote payload: top-level `ck` dictionary plus
        // `aps` alert keys. Missing `ck` is not a CloudKit notification
        // (CloudKitRuntime notification-parse probe).
        guard let ck = notificationDictionary["ck"] as? [AnyHashable: Any] else {
            return nil
        }
        let type = CKNotification.decodedType(ck["t"])
        self.init(type: type)
        containerIdentifier = ck["cid"] as? String ?? (ck["cid"] as? NSString) as String?
        subscriptionID = ck["sid"] as? String ?? (ck["sid"] as? NSString) as String?
        isPruned = CKNotification.decodedInt(ck["fet"]) == 1
        if let nid = ck["nid"] as? String ?? (ck["nid"] as? NSString) as String? {
            let ident = CKNotification.ID()
            ident.ck_payload = nid
            notificationID = ident
        }
        if let aps = notificationDictionary["aps"] as? [AnyHashable: Any] {
            applyAPS(aps)
        }
        if let alert = notificationDictionary["aps"] as? String {
            alertBody = alert
        }
    }

    private func applyAPS(_ aps: [AnyHashable: Any]) {
        if let alert = aps["alert"] as? String {
            alertBody = alert
        } else if let alert = aps["alert"] as? [AnyHashable: Any] {
            alertBody = alert["body"] as? String
            title = alert["title"] as? String
            subtitle = alert["subtitle"] as? String
            alertLocalizationKey = alert["loc-key"] as? String
            alertLocalizationArgs = alert["loc-args"] as? [String]
            alertActionLocalizationKey = alert["action-loc-key"] as? String
            alertLaunchImage = alert["launch-image"] as? String
        }
        badge = aps["badge"] as? NSNumber
        if let number = aps["badge"] as? Int {
            badge = NSNumber(value: number)
        }
        soundName = aps["sound"] as? String
        category = aps["category"] as? String
    }

    static func decodedType(_ raw: Any?) -> CKNotification.NotificationType {
        switch decodedInt(raw) {
        case 2: return .recordZone
        case 3: return .readNotification
        case 4: return .database
        default: return .query
        }
    }

    static func decodedInt(_ raw: Any?) -> Int {
        if let number = raw as? NSNumber { return number.intValue }
        if let number = raw as? Int { return number }
        return 0
    }
}

open class CKQueryNotification: CKNotification, @unchecked Sendable {
    public enum Reason: Int, Sendable, Hashable {
        case recordCreated = 1
        case recordUpdated = 2
        case recordDeleted = 3
    }

    open private(set) var databaseScope: CKDatabase.Scope
    open private(set) var queryNotificationReason: CKQueryNotification.Reason
    open private(set) var recordFields: [String: Any]?
    open private(set) var recordID: CKRecord.ID?

    public init(
        reason: CKQueryNotification.Reason,
        databaseScope: CKDatabase.Scope,
        recordID: CKRecord.ID?
    ) {
        self.queryNotificationReason = reason
        self.databaseScope = databaseScope
        self.recordID = recordID
        super.init(type: .query)
    }
}

open class CKDatabaseNotification: CKNotification, @unchecked Sendable {
    open private(set) var databaseScope: CKDatabase.Scope

    public init(databaseScope: CKDatabase.Scope) {
        self.databaseScope = databaseScope
        super.init(type: .database)
    }
}

open class CKRecordZoneNotification: CKNotification, @unchecked Sendable {
    open private(set) var databaseScope: CKDatabase.Scope
    open private(set) var recordZoneID: CKRecordZone.ID?

    public init(databaseScope: CKDatabase.Scope, recordZoneID: CKRecordZone.ID?) {
        self.databaseScope = databaseScope
        self.recordZoneID = recordZoneID
        super.init(type: .recordZone)
    }
}
