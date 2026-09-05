import Foundation

open class CKSubscription: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public typealias ID = String

    public enum SubscriptionType: Int, Sendable, Hashable {
        case query = 1
        case recordZone = 2
        case database = 3
    }

    open class NotificationInfo: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
        open var alertActionLocalizationKey: String?
        open var alertBody: String?
        open var alertLaunchImage: String?
        open var alertLocalizationKey: String?
        open var category: String?
        open var collapseIDKey: String?
        open var shouldBadge: Bool = false
        open var shouldSendContentAvailable: Bool = false
        open var shouldSendMutableContent: Bool = false
        open var soundName: String?
        open var subtitle: String?
        open var subtitleLocalizationKey: String?
        open var title: String?
        open var titleLocalizationKey: String?
        open var desiredKeys: [CKRecord.FieldKey]?
        open var alertLocalizationArgs: [CKRecord.FieldKey]?
        open var titleLocalizationArgs: [CKRecord.FieldKey]?
        open var subtitleLocalizationArgs: [CKRecord.FieldKey]?

        public static var supportsSecureCoding: Bool { true }

        public override init() {
            super.init()
        }

        public convenience init(
            alertBody: String? = nil,
            alertLocalizationKey: String? = nil,
            alertLocalizationArgs: [CKRecord.FieldKey] = [],
            title: String? = nil,
            titleLocalizationKey: String? = nil,
            titleLocalizationArgs: [CKRecord.FieldKey] = [],
            subtitle: String? = nil,
            subtitleLocalizationKey: String? = nil,
            subtitleLocalizationArgs: [CKRecord.FieldKey] = [],
            alertActionLocalizationKey: String? = nil,
            alertLaunchImage: String? = nil,
            soundName: String? = nil,
            desiredKeys: [CKRecord.FieldKey]? = nil,
            shouldBadge: Bool = false,
            shouldSendContentAvailable: Bool = false,
            shouldSendMutableContent: Bool = false,
            category: String? = nil,
            collapseIDKey: String? = nil
        ) {
            self.init()
            self.alertBody = alertBody
            self.alertLocalizationKey = alertLocalizationKey
            self.alertLocalizationArgs = alertLocalizationArgs
            self.title = title
            self.titleLocalizationKey = titleLocalizationKey
            self.titleLocalizationArgs = titleLocalizationArgs
            self.subtitle = subtitle
            self.subtitleLocalizationKey = subtitleLocalizationKey
            self.subtitleLocalizationArgs = subtitleLocalizationArgs
            self.alertActionLocalizationKey = alertActionLocalizationKey
            self.alertLaunchImage = alertLaunchImage
            self.soundName = soundName
            self.desiredKeys = desiredKeys
            self.shouldBadge = shouldBadge
            self.shouldSendContentAvailable = shouldSendContentAvailable
            self.shouldSendMutableContent = shouldSendMutableContent
            self.category = category
            self.collapseIDKey = collapseIDKey
        }

        public required init?(coder: NSCoder) {
            _ = coder
            super.init()
        }

        open func encode(with coder: NSCoder) {
            _ = coder
        }

        open func copy(with zone: NSZone? = nil) -> Any {
            let copied = CKSubscription.NotificationInfo()
            copied.alertActionLocalizationKey = alertActionLocalizationKey
            copied.alertBody = alertBody
            copied.alertLaunchImage = alertLaunchImage
            copied.alertLocalizationKey = alertLocalizationKey
            copied.category = category
            copied.collapseIDKey = collapseIDKey
            copied.shouldBadge = shouldBadge
            copied.shouldSendContentAvailable = shouldSendContentAvailable
            copied.shouldSendMutableContent = shouldSendMutableContent
            copied.soundName = soundName
            copied.subtitle = subtitle
            copied.subtitleLocalizationKey = subtitleLocalizationKey
            copied.title = title
            copied.titleLocalizationKey = titleLocalizationKey
            copied.desiredKeys = desiredKeys
            copied.alertLocalizationArgs = alertLocalizationArgs
            copied.titleLocalizationArgs = titleLocalizationArgs
            copied.subtitleLocalizationArgs = subtitleLocalizationArgs
            return copied
        }
    }

    open var notificationInfo: CKSubscription.NotificationInfo?
    open private(set) var subscriptionType: CKSubscription.SubscriptionType
    open private(set) var subscriptionID: CKSubscription.ID

    public static var supportsSecureCoding: Bool { true }

    init(subscriptionType: CKSubscription.SubscriptionType, subscriptionID: CKSubscription.ID) {
        self.subscriptionType = subscriptionType
        self.subscriptionID = subscriptionID
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
        ck_copySubscription()
    }

    func ck_copySubscription() -> CKSubscription {
        if let query = self as? CKQuerySubscription {
            let copied = CKQuerySubscription(
                recordType: query.recordType ?? "",
                predicate: query.predicate,
                subscriptionID: query.subscriptionID,
                options: query.querySubscriptionOptions
            )
            copied.zoneID = query.zoneID
            copied.notificationInfo = query.notificationInfo?.copy() as? CKSubscription.NotificationInfo
            return copied
        }
        if let zone = self as? CKRecordZoneSubscription {
            let copied = CKRecordZoneSubscription(zoneID: zone.zoneID, subscriptionID: zone.subscriptionID)
            copied.recordType = zone.recordType
            copied.notificationInfo = zone.notificationInfo?.copy() as? CKSubscription.NotificationInfo
            return copied
        }
        if let database = self as? CKDatabaseSubscription {
            let copied = CKDatabaseSubscription(subscriptionID: database.subscriptionID)
            copied.recordType = database.recordType
            copied.notificationInfo = database.notificationInfo?.copy() as? CKSubscription.NotificationInfo
            return copied
        }
        return self
    }
}

open class CKQuerySubscription: CKSubscription, @unchecked Sendable {
    public struct Options: OptionSet, Sendable, Hashable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let firesOnRecordCreation = Options(rawValue: 1 << 0)
        public static let firesOnRecordUpdate = Options(rawValue: 1 << 1)
        public static let firesOnRecordDeletion = Options(rawValue: 1 << 2)
        public static let firesOnce = Options(rawValue: 1 << 3)
    }

    open private(set) var predicate: NSPredicate
    open private(set) var querySubscriptionOptions: Options
    open var zoneID: CKRecordZone.ID?
    open private(set) var recordType: CKRecord.RecordType?

    public convenience init(
        recordType: CKRecord.RecordType,
        predicate: NSPredicate,
        options querySubscriptionOptions: CKQuerySubscription.Options
    ) {
        self.init(
            recordType: recordType,
            predicate: predicate,
            subscriptionID: UUID().uuidString,
            options: querySubscriptionOptions
        )
    }

    public convenience init(
        recordType: CKRecord.RecordType,
        predicate: NSPredicate,
        subscriptionID: CKSubscription.ID,
        options querySubscriptionOptions: CKQuerySubscription.Options
    ) {
        self.init(
            _recordType: recordType,
            predicate: predicate,
            subscriptionID: subscriptionID,
            options: querySubscriptionOptions
        )
    }

    init(
        _recordType: CKRecord.RecordType,
        predicate: NSPredicate,
        subscriptionID: CKSubscription.ID,
        options: CKQuerySubscription.Options
    ) {
        self.predicate = predicate
        self.querySubscriptionOptions = options
        self.recordType = _recordType
        super.init(subscriptionType: .query, subscriptionID: subscriptionID)
    }

    public required init(coder aDecoder: NSCoder) {
        self.predicate = NSPredicate(value: false)
        self.querySubscriptionOptions = []
        super.init(subscriptionType: .query, subscriptionID: UUID().uuidString)
        _ = aDecoder
    }
}

open class CKDatabaseSubscription: CKSubscription, @unchecked Sendable {
    open var recordType: CKRecord.RecordType?

    public convenience init() {
        self.init(subscriptionID: UUID().uuidString)
    }

    public convenience init(subscriptionID: CKSubscription.ID) {
        self.init(_subscriptionID: subscriptionID)
    }

    init(_subscriptionID: CKSubscription.ID) {
        super.init(subscriptionType: .database, subscriptionID: _subscriptionID)
    }

    public required init(coder aDecoder: NSCoder) {
        super.init(subscriptionType: .database, subscriptionID: UUID().uuidString)
        _ = aDecoder
    }
}

open class CKRecordZoneSubscription: CKSubscription, @unchecked Sendable {
    open private(set) var zoneID: CKRecordZone.ID
    open var recordType: CKRecord.RecordType?

    public convenience init(zoneID: CKRecordZone.ID) {
        self.init(zoneID: zoneID, subscriptionID: UUID().uuidString)
    }

    public convenience init(zoneID: CKRecordZone.ID, subscriptionID: CKSubscription.ID) {
        self.init(_zoneID: zoneID, subscriptionID: subscriptionID)
    }

    init(_zoneID: CKRecordZone.ID, subscriptionID: CKSubscription.ID) {
        self.zoneID = _zoneID
        super.init(subscriptionType: .recordZone, subscriptionID: subscriptionID)
    }

    public required init(coder aDecoder: NSCoder) {
        self.zoneID = .default
        super.init(subscriptionType: .recordZone, subscriptionID: UUID().uuidString)
        _ = aDecoder
    }
}
