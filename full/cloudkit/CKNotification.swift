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

        public required init?(coder: NSCoder) {
            _ = coder
            super.init()
        }

        public override init() {
            super.init()
        }

        open func encode(with coder: NSCoder) {
            _ = coder
        }

        open func copy(with zone: NSZone? = nil) -> Any {
            CKNotification.ID()
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
        _ = notificationDictionary
        self.init(type: .query)
        return nil
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

    init(
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

    init(databaseScope: CKDatabase.Scope) {
        self.databaseScope = databaseScope
        super.init(type: .database)
    }
}

open class CKRecordZoneNotification: CKNotification, @unchecked Sendable {
    open private(set) var databaseScope: CKDatabase.Scope
    open private(set) var recordZoneID: CKRecordZone.ID?

    init(databaseScope: CKDatabase.Scope, recordZoneID: CKRecordZone.ID?) {
        self.databaseScope = databaseScope
        self.recordZoneID = recordZoneID
        super.init(type: .recordZone)
    }
}
