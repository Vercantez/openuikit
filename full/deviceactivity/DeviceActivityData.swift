import Foundation

/// A snapshot of device-activity records for a user and device.
///
/// Linux never queries Screen Time usage. Host tests construct value types
/// directly; report queries yield empty `DeviceActivityResults`.
public struct DeviceActivityData: Equatable, Hashable, Sendable {
    public var lastUpdatedDate: Date
    public var segmentInterval: DeviceActivityFilter.SegmentInterval
    public var user: User
    public var device: Device
    let storedSegments: [ActivitySegment]
    let storedCategoryActivities: [CategoryActivity]

    public init(
        lastUpdatedDate: Date,
        segmentInterval: DeviceActivityFilter.SegmentInterval,
        user: User,
        device: Device,
        activitySegments: [ActivitySegment] = []
    ) {
        self.lastUpdatedDate = lastUpdatedDate
        self.segmentInterval = segmentInterval
        self.user = user
        self.device = device
        self.storedSegments = activitySegments
        self.storedCategoryActivities = activitySegments.flatMap(\.storedCategories)
    }

    public var activitySegments: DeviceActivityResults<ActivitySegment> {
        DeviceActivityResults(storedSegments)
    }

    public struct Device: Equatable, Hashable, Sendable {
        /// Device form-factor. Digester child order assigns raw values
        /// `iPhone = 0`, `iPod = 1`, `iPad = 2`, `mac = 3`.
        public enum Model: Int, Hashable, Sendable {
            case iPhone = 0
            case iPod = 1
            case iPad = 2
            case mac = 3
        }

        public var name: String?
        public var model: Model

        public init(name: String? = nil, model: Model) {
            self.name = name
            self.model = model
        }
    }

    public struct User: Equatable, Hashable, Sendable {
        /// Family role. Digester child order assigns `individual = 0`,
        /// `child = 1`.
        public enum FamilyRole: Int, Hashable, Sendable {
            case individual = 0
            case child = 1
        }

        public var nameComponents: PersonNameComponents?
        public var role: FamilyRole
        public var appleID: String?

        public init(
            nameComponents: PersonNameComponents? = nil,
            role: FamilyRole,
            appleID: String? = nil
        ) {
            self.nameComponents = nameComponents
            self.role = role
            self.appleID = appleID
        }
    }

    public struct ActivitySegment: Equatable, Hashable, Sendable {
        public var dateInterval: DateInterval
        public var totalActivityDuration: TimeInterval
        public var totalPickupsWithoutApplicationActivity: Int
        public var longestActivity: DateInterval?
        public var firstPickup: Date?
        let storedCategories: [CategoryActivity]

        public init(
            dateInterval: DateInterval,
            totalActivityDuration: TimeInterval,
            totalPickupsWithoutApplicationActivity: Int = 0,
            longestActivity: DateInterval? = nil,
            firstPickup: Date? = nil,
            categories: [CategoryActivity] = []
        ) {
            self.dateInterval = dateInterval
            self.totalActivityDuration = totalActivityDuration
            self.totalPickupsWithoutApplicationActivity =
                totalPickupsWithoutApplicationActivity
            self.longestActivity = longestActivity
            self.firstPickup = firstPickup
            self.storedCategories = categories
        }

        public var categories: DeviceActivityResults<CategoryActivity> {
            DeviceActivityResults(storedCategories)
        }
    }

    public struct ApplicationActivity: Equatable, Hashable, Sendable {
        public var totalActivityDuration: TimeInterval
        public var numberOfPickups: Int
        public var numberOfNotifications: Int
        let bundleIdentifier: String?

        public init(
            totalActivityDuration: TimeInterval,
            numberOfPickups: Int = 0,
            numberOfNotifications: Int = 0,
            bundleIdentifier: String? = nil
        ) {
            self.totalActivityDuration = totalActivityDuration
            self.numberOfPickups = numberOfPickups
            self.numberOfNotifications = numberOfNotifications
            self.bundleIdentifier = bundleIdentifier
        }
    }

    public struct CategoryActivity: Equatable, Hashable, Sendable {
        public var totalActivityDuration: TimeInterval
        let storedApplications: [ApplicationActivity]
        let storedWebDomains: [WebDomainActivity]

        public init(
            totalActivityDuration: TimeInterval,
            applications: [ApplicationActivity] = [],
            webDomains: [WebDomainActivity] = []
        ) {
            self.totalActivityDuration = totalActivityDuration
            self.storedApplications = applications
            self.storedWebDomains = webDomains
        }

        public var applications: DeviceActivityResults<ApplicationActivity> {
            DeviceActivityResults(storedApplications)
        }

        public var webDomains: DeviceActivityResults<WebDomainActivity> {
            DeviceActivityResults(storedWebDomains)
        }
    }

    public struct WebDomainActivity: Equatable, Hashable, Sendable {
        public var totalActivityDuration: TimeInterval
        let domain: String?

        public init(totalActivityDuration: TimeInterval, domain: String? = nil) {
            self.totalActivityDuration = totalActivityDuration
            self.domain = domain
        }
    }
}
