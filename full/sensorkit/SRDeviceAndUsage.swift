import Foundation

public class SRDevice: NSObject {
    public private(set) var model: String
    public private(set) var name: String
    public private(set) var productType: String
    public private(set) var systemName: String
    public private(set) var systemVersion: String

    public class var current: SRDevice {
        let info = ProcessInfo.processInfo
        return SRDevice(
            name: info.hostName,
            model: "linux",
            productType: "linux",
            systemName: info.operatingSystemName,
            systemVersion: info.operatingSystemVersionString
        )
    }

    @_spi(OpenUIKitHost)
    public init(
        name: String,
        model: String,
        productType: String,
        systemName: String,
        systemVersion: String
    ) {
        self.name = name
        self.model = model
        self.productType = productType
        self.systemName = systemName
        self.systemVersion = systemVersion
        super.init()
    }
}

extension ProcessInfo {
    fileprivate var operatingSystemName: String {
        #if os(Linux)
        return "Linux"
        #else
        return "Unknown"
        #endif
    }
}

public class SRDeletionRecord: NSObject {
    public private(set) var startTime: SRAbsoluteTime
    public private(set) var endTime: SRAbsoluteTime
    public private(set) var reason: SRDeletionReason

    @_spi(OpenUIKitHost)
    public init(startTime: SRAbsoluteTime, endTime: SRAbsoluteTime, reason: SRDeletionReason) {
        self.startTime = startTime
        self.endTime = endTime
        self.reason = reason
        super.init()
    }
}

public class SRSupplementalCategory: NSObject {
    public private(set) var identifier: String

    @_spi(OpenUIKitHost)
    public init(identifier: String) {
        self.identifier = identifier
        super.init()
    }
}

public class SRTextInputSession: NSObject {
    public enum SessionType: Int, Hashable, Sendable {
        case keyboard = 1
        case thirdPartyKeyboard = 2
        case pencil = 3
        case dictation = 4
    }

    public private(set) var duration: TimeInterval
    public private(set) var sessionIdentifier: String
    public private(set) var sessionType: SessionType

    @_spi(OpenUIKitHost)
    public init(duration: TimeInterval, sessionIdentifier: String, sessionType: SessionType) {
        self.duration = duration
        self.sessionIdentifier = sessionIdentifier
        self.sessionType = sessionType
        super.init()
    }
}

public class SRDeviceUsageReport: NSObject {
    public struct CategoryKey: RawRepresentable, Hashable, Sendable {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let books = CategoryKey(rawValue: "SRDeviceUsageCategoryBooks")
        public static let business = CategoryKey(rawValue: "SRDeviceUsageCategoryBusiness")
        public static let catalogs = CategoryKey(rawValue: "SRDeviceUsageCategoryCatalogs")
        public static let developerTools = CategoryKey(rawValue: "SRDeviceUsageCategoryDeveloperTools")
        public static let education = CategoryKey(rawValue: "SRDeviceUsageCategoryEducation")
        public static let entertainment = CategoryKey(rawValue: "SRDeviceUsageCategoryEntertainment")
        public static let finance = CategoryKey(rawValue: "SRDeviceUsageCategoryFinance")
        public static let foodAndDrink = CategoryKey(rawValue: "SRDeviceUsageCategoryFoodAndDrink")
        public static let games = CategoryKey(rawValue: "SRDeviceUsageCategoryGames")
        public static let graphicsAndDesign = CategoryKey(rawValue: "SRDeviceUsageCategoryGraphicsAndDesign")
        public static let healthAndFitness = CategoryKey(rawValue: "SRDeviceUsageCategoryHealthAndFitness")
        public static let kids = CategoryKey(rawValue: "SRDeviceUsageCategoryKids")
        public static let lifestyle = CategoryKey(rawValue: "SRDeviceUsageCategoryLifestyle")
        public static let medical = CategoryKey(rawValue: "SRDeviceUsageCategoryMedical")
        public static let miscellaneous = CategoryKey(rawValue: "SRDeviceUsageCategoryMiscellaneous")
        public static let music = CategoryKey(rawValue: "SRDeviceUsageCategoryMusic")
        public static let navigation = CategoryKey(rawValue: "SRDeviceUsageCategoryNavigation")
        public static let news = CategoryKey(rawValue: "SRDeviceUsageCategoryNews")
        public static let newsstand = CategoryKey(rawValue: "SRDeviceUsageCategoryNewsstand")
        public static let photoAndVideo = CategoryKey(rawValue: "SRDeviceUsageCategoryPhotoAndVideo")
        public static let productivity = CategoryKey(rawValue: "SRDeviceUsageCategoryProductivity")
        public static let reference = CategoryKey(rawValue: "SRDeviceUsageCategoryReference")
        public static let shopping = CategoryKey(rawValue: "SRDeviceUsageCategoryShopping")
        public static let socialNetworking = CategoryKey(rawValue: "SRDeviceUsageCategorySocialNetworking")
        public static let sports = CategoryKey(rawValue: "SRDeviceUsageCategorySports")
        public static let stickers = CategoryKey(rawValue: "SRDeviceUsageCategoryStickers")
        public static let travel = CategoryKey(rawValue: "SRDeviceUsageCategoryTravel")
        public static let utilities = CategoryKey(rawValue: "SRDeviceUsageCategoryUtilities")
        public static let weather = CategoryKey(rawValue: "SRDeviceUsageCategoryWeather")
    }

    public class ApplicationUsage: NSObject {
        public private(set) var bundleIdentifier: String?
        public private(set) var relativeStartTime: TimeInterval
        public private(set) var reportApplicationIdentifier: String
        public private(set) var supplementalCategories: [SRSupplementalCategory]
        public private(set) var textInputSessions: [SRTextInputSession]
        public private(set) var usageTime: TimeInterval

        @_spi(OpenUIKitHost)
        public init(
            bundleIdentifier: String?,
            relativeStartTime: TimeInterval,
            reportApplicationIdentifier: String,
            supplementalCategories: [SRSupplementalCategory],
            textInputSessions: [SRTextInputSession],
            usageTime: TimeInterval
        ) {
            self.bundleIdentifier = bundleIdentifier
            self.relativeStartTime = relativeStartTime
            self.reportApplicationIdentifier = reportApplicationIdentifier
            self.supplementalCategories = supplementalCategories
            self.textInputSessions = textInputSessions
            self.usageTime = usageTime
            super.init()
        }
    }

    public class NotificationUsage: NSObject {
        public enum Event: Int, Hashable, Sendable {
            case unknown = 0
            case received = 1
            case defaultAction = 2
            case supplementaryAction = 3
            case clear = 4
            case notificationCenterClearAll = 5
            case removed = 6
            case hide = 7
            case longLook = 8
            case silence = 9
            case appLaunch = 10
            case expired = 11
            case bannerPulldown = 12
            case tapCoalesce = 13
            case deduped = 14
            case deviceActivated = 15
            case deviceUnlocked = 16
        }

        public private(set) var bundleIdentifier: String?
        public private(set) var event: Event

        @_spi(OpenUIKitHost)
        public init(bundleIdentifier: String?, event: Event) {
            self.bundleIdentifier = bundleIdentifier
            self.event = event
            super.init()
        }
    }

    public class WebUsage: NSObject {
        public private(set) var totalUsageTime: TimeInterval

        @_spi(OpenUIKitHost)
        public init(totalUsageTime: TimeInterval) {
            self.totalUsageTime = totalUsageTime
            super.init()
        }
    }

    public private(set) var applicationUsageByCategory: [CategoryKey: [ApplicationUsage]]
    public private(set) var duration: TimeInterval
    public private(set) var notificationUsageByCategory: [CategoryKey: [NotificationUsage]]
    public private(set) var totalScreenWakes: Int
    public private(set) var totalUnlockDuration: TimeInterval
    public private(set) var totalUnlocks: Int
    public private(set) var version: String
    public private(set) var webUsageByCategory: [CategoryKey: [WebUsage]]

    @_spi(OpenUIKitHost)
    public init(
        applicationUsageByCategory: [CategoryKey: [ApplicationUsage]] = [:],
        duration: TimeInterval = 0,
        notificationUsageByCategory: [CategoryKey: [NotificationUsage]] = [:],
        totalScreenWakes: Int = 0,
        totalUnlockDuration: TimeInterval = 0,
        totalUnlocks: Int = 0,
        version: String = "linux",
        webUsageByCategory: [CategoryKey: [WebUsage]] = [:]
    ) {
        self.applicationUsageByCategory = applicationUsageByCategory
        self.duration = duration
        self.notificationUsageByCategory = notificationUsageByCategory
        self.totalScreenWakes = totalScreenWakes
        self.totalUnlockDuration = totalUnlockDuration
        self.totalUnlocks = totalUnlocks
        self.version = version
        self.webUsageByCategory = webUsageByCategory
        super.init()
    }
}

public class SRMessagesUsageReport: NSObject {
    public private(set) var duration: TimeInterval
    public private(set) var totalIncomingMessages: Int
    public private(set) var totalOutgoingMessages: Int
    public private(set) var totalUniqueContacts: Int

    @_spi(OpenUIKitHost)
    public init(
        duration: TimeInterval,
        totalIncomingMessages: Int,
        totalOutgoingMessages: Int,
        totalUniqueContacts: Int
    ) {
        self.duration = duration
        self.totalIncomingMessages = totalIncomingMessages
        self.totalOutgoingMessages = totalOutgoingMessages
        self.totalUniqueContacts = totalUniqueContacts
        super.init()
    }
}

public class SRPhoneUsageReport: NSObject {
    public private(set) var duration: TimeInterval
    public private(set) var totalIncomingCalls: Int
    public private(set) var totalOutgoingCalls: Int
    public private(set) var totalPhoneCallDuration: TimeInterval
    public private(set) var totalUniqueContacts: Int

    @_spi(OpenUIKitHost)
    public init(
        duration: TimeInterval,
        totalIncomingCalls: Int,
        totalOutgoingCalls: Int,
        totalPhoneCallDuration: TimeInterval,
        totalUniqueContacts: Int
    ) {
        self.duration = duration
        self.totalIncomingCalls = totalIncomingCalls
        self.totalOutgoingCalls = totalOutgoingCalls
        self.totalPhoneCallDuration = totalPhoneCallDuration
        self.totalUniqueContacts = totalUniqueContacts
        super.init()
    }
}

public class SRMediaEvent: NSObject {
    public private(set) var eventType: SRMediaEventType
    public private(set) var mediaIdentifier: String

    @_spi(OpenUIKitHost)
    public init(eventType: SRMediaEventType, mediaIdentifier: String) {
        self.eventType = eventType
        self.mediaIdentifier = mediaIdentifier
        super.init()
    }
}

public class SRVisit: NSObject {
    public enum LocationCategory: Int, Hashable, Sendable {
        case unknown = 0
        case home = 1
        case work = 2
        case school = 3
        case gym = 4
    }

    public private(set) var arrivalDateInterval: DateInterval
    public private(set) var departureDateInterval: DateInterval
    /// CoreLocation `CLLocationDistance` is a `Double` alias; Linux stores meters.
    public private(set) var distanceFromHome: Double
    public private(set) var identifier: UUID
    public private(set) var locationCategory: LocationCategory

    @_spi(OpenUIKitHost)
    public init(
        arrivalDateInterval: DateInterval,
        departureDateInterval: DateInterval,
        distanceFromHome: Double,
        identifier: UUID,
        locationCategory: LocationCategory
    ) {
        self.arrivalDateInterval = arrivalDateInterval
        self.departureDateInterval = departureDateInterval
        self.distanceFromHome = distanceFromHome
        self.identifier = identifier
        self.locationCategory = locationCategory
        super.init()
    }
}
