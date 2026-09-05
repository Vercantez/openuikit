import Foundation

public struct Forecast<Element>: RandomAccessCollection, Equatable, Codable, Sendable
where Element: Decodable, Element: Encodable, Element: Equatable, Element: Sendable {
    public typealias Index = Int
    public typealias SubSequence = Slice<Forecast<Element>>
    public typealias Indices = Range<Index>
    public typealias Iterator = IndexingIterator<Forecast<Element>>

    public var forecast: [Element]
    public var metadata: WeatherMetadata

    public init(forecast: [Element], metadata: WeatherMetadata) {
        self.forecast = forecast
        self.metadata = metadata
    }

    public var summary: String { "\(forecast.count)-period forecast" }

    public var startIndex: Index { forecast.startIndex }
    public var endIndex: Index { forecast.endIndex }

    public subscript(position: Index) -> Element { forecast[position] }

    public func index(after i: Index) -> Index { forecast.index(after: i) }
    public func index(before i: Index) -> Index { forecast.index(before: i) }
}

public struct DailyWeatherStatistics<T>: RandomAccessCollection, Equatable, Codable, Sendable
where T: Decodable, T: Encodable, T: Equatable, T: Sendable {
    public typealias Index = Int
    public typealias Element = T
    public typealias SubSequence = Slice<DailyWeatherStatistics<T>>
    public typealias Indices = Range<Index>
    public typealias Iterator = IndexingIterator<DailyWeatherStatistics<T>>

    public var days: [T]
    public var baselineStartDate: Date
    public var metadata: WeatherMetadata

    public init(days: [T], baselineStartDate: Date, metadata: WeatherMetadata) {
        self.days = days
        self.baselineStartDate = baselineStartDate
        self.metadata = metadata
    }

    public var startIndex: Index { days.startIndex }
    public var endIndex: Index { days.endIndex }
    public subscript(position: Index) -> T { days[position] }
    public func index(after i: Index) -> Index { days.index(after: i) }
    public func index(before i: Index) -> Index { days.index(before: i) }
}

public struct HourlyWeatherStatistics<T>: RandomAccessCollection, Equatable, Codable, Sendable
where T: Decodable, T: Encodable, T: Equatable, T: Sendable {
    public typealias Index = Int
    public typealias Element = T
    public typealias SubSequence = Slice<HourlyWeatherStatistics<T>>
    public typealias Indices = Range<Index>
    public typealias Iterator = IndexingIterator<HourlyWeatherStatistics<T>>

    public var hours: [T]
    public var baselineStartDate: Date
    public var metadata: WeatherMetadata

    public init(hours: [T], baselineStartDate: Date, metadata: WeatherMetadata) {
        self.hours = hours
        self.baselineStartDate = baselineStartDate
        self.metadata = metadata
    }

    public var startIndex: Index { hours.startIndex }
    public var endIndex: Index { hours.endIndex }
    public subscript(position: Index) -> T { hours[position] }
    public func index(after i: Index) -> Index { hours.index(after: i) }
    public func index(before i: Index) -> Index { hours.index(before: i) }
}

public struct MonthlyWeatherStatistics<T>: RandomAccessCollection, Equatable, Codable, Sendable
where T: Decodable, T: Encodable, T: Equatable, T: Sendable {
    public typealias Index = Int
    public typealias Element = T
    public typealias SubSequence = Slice<MonthlyWeatherStatistics<T>>
    public typealias Indices = Range<Index>
    public typealias Iterator = IndexingIterator<MonthlyWeatherStatistics<T>>

    public var months: [T]
    public var baselineStartDate: Date
    public var metadata: WeatherMetadata

    public init(months: [T], baselineStartDate: Date, metadata: WeatherMetadata) {
        self.months = months
        self.baselineStartDate = baselineStartDate
        self.metadata = metadata
    }

    public var startIndex: Index { months.startIndex }
    public var endIndex: Index { months.endIndex }
    public subscript(position: Index) -> T { months[position] }
    public func index(after i: Index) -> Index { months.index(after: i) }
    public func index(before i: Index) -> Index { months.index(before: i) }
}

public struct DailyWeatherSummary<T>: RandomAccessCollection, Equatable, Codable, Sendable
where T: Decodable, T: Encodable, T: Equatable, T: Sendable {
    public typealias Index = Int
    public typealias Element = T
    public typealias SubSequence = Slice<DailyWeatherSummary<T>>
    public typealias Indices = Range<Index>
    public typealias Iterator = IndexingIterator<DailyWeatherSummary<T>>

    public var days: [T]
    public var metadata: WeatherMetadata

    public init(days: [T], metadata: WeatherMetadata) {
        self.days = days
        self.metadata = metadata
    }

    public var startIndex: Index { days.startIndex }
    public var endIndex: Index { days.endIndex }
    public subscript(position: Index) -> T { days[position] }
    public func index(after i: Index) -> Index { days.index(after: i) }
    public func index(before i: Index) -> Index { days.index(before: i) }
}

public struct WeatherChange: Equatable, Codable, Sendable {
    @frozen
    public enum Direction: Codable, Equatable, Hashable, Sendable {
        case increase
        case decrease
        case steady
    }

    public var date: Date
    public var lowTemperature: Direction
    public var highTemperature: Direction
    public var dayPrecipitationAmount: Direction
    public var nightPrecipitationAmount: Direction

    public init(
        date: Date,
        lowTemperature: Direction,
        highTemperature: Direction,
        dayPrecipitationAmount: Direction,
        nightPrecipitationAmount: Direction
    ) {
        self.date = date
        self.lowTemperature = lowTemperature
        self.highTemperature = highTemperature
        self.dayPrecipitationAmount = dayPrecipitationAmount
        self.nightPrecipitationAmount = nightPrecipitationAmount
    }
}

public struct WeatherChanges: RandomAccessCollection, Equatable, Codable, Sendable {
    public typealias Index = Int
    public typealias Element = WeatherChange
    public typealias SubSequence = Slice<WeatherChanges>
    public typealias Indices = Range<Index>
    public typealias Iterator = IndexingIterator<WeatherChanges>

    public var changes: [WeatherChange]
    public var metadata: WeatherMetadata

    public init(changes: [WeatherChange], metadata: WeatherMetadata) {
        self.changes = changes
        self.metadata = metadata
    }

    public var startIndex: Index { changes.startIndex }
    public var endIndex: Index { changes.endIndex }
    public subscript(position: Index) -> WeatherChange { changes[position] }
    public func index(after i: Index) -> Index { changes.index(after: i) }
    public func index(before i: Index) -> Index { changes.index(before: i) }
}

public enum HistoricalComparison: Equatable, Codable, Sendable {
    case highTemperature(Trend<UnitTemperature>)
    case lowTemperature(Trend<UnitTemperature>)
    case precipitationAmount(Trend<UnitLength>)
    case snowfallAmount(Trend<UnitLength>)
}

public struct HistoricalComparisons: RandomAccessCollection, Equatable, Codable, Sendable {
    public typealias Index = Int
    public typealias Element = HistoricalComparison
    public typealias SubSequence = Slice<HistoricalComparisons>
    public typealias Indices = Range<Index>
    public typealias Iterator = IndexingIterator<HistoricalComparisons>

    public var comparisons: [HistoricalComparison]
    public var metadata: WeatherMetadata

    public init(comparisons: [HistoricalComparison], metadata: WeatherMetadata) {
        self.comparisons = comparisons
        self.metadata = metadata
    }

    public var startIndex: Index { comparisons.startIndex }
    public var endIndex: Index { comparisons.endIndex }
    public subscript(position: Index) -> HistoricalComparison { comparisons[position] }
    public func index(after i: Index) -> Index { comparisons.index(after: i) }
    public func index(before i: Index) -> Index { comparisons.index(before: i) }
}

public struct DayTemperatureSummary: Equatable, Codable, Sendable {
    public var date: Date
    public var lowTemperature: Measurement<UnitTemperature>
    public var highTemperature: Measurement<UnitTemperature>

    public init(
        date: Date,
        lowTemperature: Measurement<UnitTemperature>,
        highTemperature: Measurement<UnitTemperature>
    ) {
        self.date = date
        self.lowTemperature = lowTemperature
        self.highTemperature = highTemperature
    }
}

public struct DayPrecipitationSummary: Equatable, Codable, Sendable {
    public var date: Date
    public var snowfallAmount: Measurement<UnitLength>
    public var precipitationAmount: Measurement<UnitLength>

    public init(
        date: Date,
        snowfallAmount: Measurement<UnitLength>,
        precipitationAmount: Measurement<UnitLength>
    ) {
        self.date = date
        self.snowfallAmount = snowfallAmount
        self.precipitationAmount = precipitationAmount
    }
}

public struct DayTemperatureStatistics: Equatable, Codable, Sendable {
    public var day: Int
    public var averageLowTemperature: Measurement<UnitTemperature>
    public var averageHighTemperature: Measurement<UnitTemperature>

    public init(
        day: Int,
        averageLowTemperature: Measurement<UnitTemperature>,
        averageHighTemperature: Measurement<UnitTemperature>
    ) {
        self.day = day
        self.averageLowTemperature = averageLowTemperature
        self.averageHighTemperature = averageHighTemperature
    }
}

public struct HourTemperatureStatistics: Equatable, Codable, Sendable {
    public var hour: Int
    public var percentiles: Percentiles<UnitTemperature>

    public init(hour: Int, percentiles: Percentiles<UnitTemperature>) {
        self.hour = hour
        self.percentiles = percentiles
    }
}

public struct DayPrecipitationStatistics: Equatable, Codable, Sendable {
    public var day: Int
    public var averagePrecipitationProbability: Double
    public var averagePrecipitationAmount: Measurement<UnitLength>
    public var averageSnowfallAmount: Measurement<UnitLength>

    public init(
        day: Int,
        averagePrecipitationProbability: Double,
        averagePrecipitationAmount: Measurement<UnitLength>,
        averageSnowfallAmount: Measurement<UnitLength>
    ) {
        self.day = day
        self.averagePrecipitationProbability = averagePrecipitationProbability
        self.averagePrecipitationAmount = averagePrecipitationAmount
        self.averageSnowfallAmount = averageSnowfallAmount
    }
}

public struct MonthTemperatureStatistics: Equatable, Codable, Sendable {
    public var month: Int
    public var averageLowTemperature: Measurement<UnitTemperature>
    public var averageHighTemperature: Measurement<UnitTemperature>

    public init(
        month: Int,
        averageLowTemperature: Measurement<UnitTemperature>,
        averageHighTemperature: Measurement<UnitTemperature>
    ) {
        self.month = month
        self.averageLowTemperature = averageLowTemperature
        self.averageHighTemperature = averageHighTemperature
    }
}

public struct MonthPrecipitationStatistics: Equatable, Codable, Sendable {
    public var month: Int
    public var averagePrecipitationProbability: Double
    public var averagePrecipitationAmount: Measurement<UnitLength>
    public var averageSnowfallAmount: Measurement<UnitLength>

    public init(
        month: Int,
        averagePrecipitationProbability: Double,
        averagePrecipitationAmount: Measurement<UnitLength>,
        averageSnowfallAmount: Measurement<UnitLength>
    ) {
        self.month = month
        self.averagePrecipitationProbability = averagePrecipitationProbability
        self.averagePrecipitationAmount = averagePrecipitationAmount
        self.averageSnowfallAmount = averageSnowfallAmount
    }
}
