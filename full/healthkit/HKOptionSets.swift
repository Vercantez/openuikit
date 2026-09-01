import Foundation

/// Query date-interval matching flags from `HKQueryOptions`.
public struct HKQueryOptions: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let strictStartDate = HKQueryOptions(rawValue: 1 << 0)
    public static let strictEndDate = HKQueryOptions(rawValue: 1 << 1)
}

/// Statistics aggregation flags from `HKStatisticsOptions`.
public struct HKStatisticsOptions: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let separateBySource = HKStatisticsOptions(rawValue: 1 << 0)
    public static let discreteAverage = HKStatisticsOptions(rawValue: 1 << 1)
    public static let discreteMin = HKStatisticsOptions(rawValue: 1 << 2)
    public static let discreteMax = HKStatisticsOptions(rawValue: 1 << 3)
    public static let cumulativeSum = HKStatisticsOptions(rawValue: 1 << 4)
    public static let discreteMostRecent = HKStatisticsOptions(rawValue: 1 << 5)
    public static let mostRecent = HKStatisticsOptions(rawValue: 1 << 5)
    public static let duration = HKStatisticsOptions(rawValue: 1 << 6)
}

extension NSNotification.Name {
    public static let HKUserPreferencesDidChange = NSNotification.Name(
        "HKUserPreferencesDidChangeNotification"
    )
}
