import Foundation

open class HKStatistics: NSObject, NSCopying, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }
    public let quantityType: HKQuantityType
    public let startDate: Date
    public let endDate: Date
    public let sources: [HKSource]?
    private let sum: HKQuantity?
    private let average: HKQuantity?
    private let minimum: HKQuantity?
    private let maximum: HKQuantity?
    private let mostRecent: HKQuantity?
    private let mostRecentInterval: DateInterval?
    private let durationQuantity: HKQuantity?
    private let bySource: [String: HKStatistics]

    public init(
        quantityType: HKQuantityType,
        startDate: Date,
        endDate: Date,
        sources: [HKSource]?,
        sum: HKQuantity?,
        average: HKQuantity?,
        minimum: HKQuantity?,
        maximum: HKQuantity?,
        mostRecent: HKQuantity?,
        mostRecentInterval: DateInterval?,
        duration: HKQuantity?,
        bySource: [String: HKStatistics] = [:]
    ) {
        self.quantityType = quantityType
        self.startDate = startDate
        self.endDate = endDate
        self.sources = sources
        self.sum = sum
        self.average = average
        self.minimum = minimum
        self.maximum = maximum
        self.mostRecent = mostRecent
        self.mostRecentInterval = mostRecentInterval
        self.durationQuantity = duration
        self.bySource = bySource
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.quantityType = HKQuantityType(identifier: "")
        self.startDate = Date()
        self.endDate = Date()
        self.sources = nil
        self.sum = nil
        self.average = nil
        self.minimum = nil
        self.maximum = nil
        self.mostRecent = nil
        self.mostRecentInterval = nil
        self.durationQuantity = nil
        self.bySource = [:]
        super.init()
    }

    public func encode(with coder: NSCoder) {}

    public func copy(with zone: NSZone? = nil) -> Any { self }

    public func sumQuantity() -> HKQuantity? { sum }
    public func sumQuantity(for source: HKSource) -> HKQuantity? { bySource[source.bundleIdentifier]?.sum }
    public func averageQuantity() -> HKQuantity? { average }
    public func averageQuantity(for source: HKSource) -> HKQuantity? { bySource[source.bundleIdentifier]?.average }
    public func minimumQuantity() -> HKQuantity? { minimum }
    public func minimumQuantity(for source: HKSource) -> HKQuantity? { bySource[source.bundleIdentifier]?.minimum }
    public func maximumQuantity() -> HKQuantity? { maximum }
    public func maximumQuantity(for source: HKSource) -> HKQuantity? { bySource[source.bundleIdentifier]?.maximum }
    public func mostRecentQuantity() -> HKQuantity? { mostRecent }
    public func mostRecentQuantity(for source: HKSource) -> HKQuantity? { bySource[source.bundleIdentifier]?.mostRecent }
    public func mostRecentQuantityDateInterval() -> DateInterval? { mostRecentInterval }
    public func mostRecentQuantityDateInterval(for source: HKSource) -> DateInterval? {
        bySource[source.bundleIdentifier]?.mostRecentInterval
    }
    public func duration() -> HKQuantity? { durationQuantity }
    public func duration(for source: HKSource) -> HKQuantity? { bySource[source.bundleIdentifier]?.durationQuantity }

    static func compute(
        quantityType: HKQuantityType,
        samples: [HKQuantitySample],
        options: HKStatisticsOptions,
        start: Date,
        end: Date
    ) -> HKStatistics {
        let unit = quantityType.canonicalUnit
        let compatible = samples.filter { $0.quantity.`is`(compatibleWith: unit) }
        let values = compatible.map { $0.quantity.doubleValue(for: unit) }
        let style = quantityType.aggregationStyle
        var sum: HKQuantity?
        var average: HKQuantity?
        var minimum: HKQuantity?
        var maximum: HKQuantity?
        var mostRecent: HKQuantity?
        var mostRecentInterval: DateInterval?
        if style == .cumulative, options.contains(.cumulativeSum) || options.isEmpty {
            sum = HKQuantity(unit: unit, doubleValue: values.reduce(0, +))
        } else if options.contains(.cumulativeSum), !values.isEmpty {
            // Cumulative option on a discrete type is ignored; Apple would error. Linux stores nil.
            sum = nil
        }
        if options.contains(.discreteAverage) || (options.isEmpty && style != .cumulative) {
            if !values.isEmpty {
                average = HKQuantity(unit: unit, doubleValue: values.reduce(0, +) / Double(values.count))
            }
        }
        if options.contains(.discreteMin), let minValue = values.min() {
            minimum = HKQuantity(unit: unit, doubleValue: minValue)
        }
        if options.contains(.discreteMax), let maxValue = values.max() {
            maximum = HKQuantity(unit: unit, doubleValue: maxValue)
        }
        if options.contains(.mostRecent) || options.contains(.discreteMostRecent), let last = compatible.max(by: { $0.endDate < $1.endDate }) {
            mostRecent = last.quantity
            mostRecentInterval = DateInterval(start: last.startDate, end: last.endDate)
        }
        var duration: HKQuantity?
        if options.contains(.duration) {
            let seconds = compatible.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            duration = HKQuantity(unit: .second(), doubleValue: seconds)
        }
        if options.isEmpty, style == .cumulative {
            sum = HKQuantity(unit: unit, doubleValue: values.reduce(0, +))
        }
        var grouped: [String: HKStatistics] = [:]
        if options.contains(.separateBySource) {
            let groups = Dictionary(grouping: compatible, by: { $0.sourceRevision.source.bundleIdentifier })
            for (key, group) in groups {
                grouped[key] = compute(
                    quantityType: quantityType,
                    samples: group,
                    options: options.subtracting(.separateBySource),
                    start: start,
                    end: end
                )
            }
        }
        return HKStatistics(
            quantityType: quantityType,
            startDate: start,
            endDate: end,
            sources: Array(Set(compatible.map { $0.sourceRevision.source })),
            sum: sum,
            average: average,
            minimum: minimum,
            maximum: maximum,
            mostRecent: mostRecent,
            mostRecentInterval: mostRecentInterval,
            duration: duration,
            bySource: grouped
        )
    }
}

open class HKStatisticsCollection: NSObject, @unchecked Sendable {
    public let statisticsByDate: [HKStatistics]
    public let anchorDate: Date
    public let intervalComponents: DateComponents

    public init(statistics: [HKStatistics], anchorDate: Date, intervalComponents: DateComponents) {
        self.statisticsByDate = statistics
        self.anchorDate = anchorDate
        self.intervalComponents = intervalComponents
        super.init()
    }

    public func statistics() -> [HKStatistics] { statisticsByDate }

    public func statistics(for date: Date) -> HKStatistics? {
        statisticsByDate.first { $0.startDate <= date && date < $0.endDate }
    }

    public func sources() -> Set<HKSource> {
        Set(statisticsByDate.flatMap { $0.sources ?? [] })
    }

    public func enumerateStatistics(from startDate: Date, to endDate: Date, with block: @escaping (HKStatistics, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop = ObjCBool(false)
        for stats in statisticsByDate where stats.startDate >= startDate && stats.startDate < endDate {
            block(stats, &stop)
            if stop.boolValue { break }
        }
    }

    static func build(
        quantityType: HKQuantityType,
        samples: [HKQuantitySample],
        options: HKStatisticsOptions,
        anchorDate: Date,
        intervalComponents: DateComponents
    ) -> HKStatisticsCollection {
        let calendar = Calendar.current
        guard !samples.isEmpty else {
            return HKStatisticsCollection(statistics: [], anchorDate: anchorDate, intervalComponents: intervalComponents)
        }
        let minDate = samples.map(\.startDate).min() ?? anchorDate
        let maxDate = samples.map(\.endDate).max() ?? anchorDate
        var buckets: [HKStatistics] = []
        var cursor = anchorDate
        // Walk backward so the first bucket includes minDate.
        while cursor > minDate {
            guard let previous = calendar.date(byAdding: intervalComponents, to: cursor, wrappingComponents: false) else { break }
            if previous >= cursor { break }
            cursor = previous
        }
        while cursor <= maxDate {
            guard let next = calendar.date(byAdding: intervalComponents, to: cursor, wrappingComponents: false), next > cursor else { break }
            let bucketSamples = samples.filter { $0.startDate >= cursor && $0.startDate < next }
            buckets.append(
                HKStatistics.compute(
                    quantityType: quantityType,
                    samples: bucketSamples,
                    options: options,
                    start: cursor,
                    end: next
                )
            )
            cursor = next
            if buckets.count > 10_000 { break }
        }
        return HKStatisticsCollection(statistics: buckets, anchorDate: anchorDate, intervalComponents: intervalComponents)
    }
}
