@_exported import Foundation

#if canImport(CoreLocation)
import CoreLocation
#endif

/// Linux host policy for Apple WeatherKit network and entitlement services.
/// There is no weather daemon, WeatherKit entitlement, or Apple weather
/// endpoint on this host. Service calls fail closed with `WeatherError.unknown`.
enum WeatherKitHost {
    static let unsupportedDescription =
        "WeatherKit Apple weather services are unavailable on this Linux host."

    static func unsupportedError() -> WeatherError {
        .unknown
    }

    static func fail<T>() throws -> T {
        throw unsupportedError()
    }
}

/// Query token selecting a WeatherKit data set.
///
/// Linux stores only the requested data-set identity and optional date
/// bounds. Fetching still requires `WeatherService`, which fails closed.
public struct WeatherQuery<T>: Sendable {
    enum Kind: Sendable, Equatable {
        case named(String)
        case dailyRange(Date, Date)
        case hourlyRange(Date, Date)
    }

    let kind: Kind

    public static func daily(startDate: Date, endDate: Date) -> WeatherQuery<T> {
        WeatherQuery<T>(kind: .dailyRange(startDate, endDate))
    }

    public static func hourly(startDate: Date, endDate: Date) -> WeatherQuery<T> {
        WeatherQuery<T>(kind: .hourlyRange(startDate, endDate))
    }
}

extension WeatherQuery where T == CurrentWeather {
    public static var current: WeatherQuery<CurrentWeather> {
        WeatherQuery<CurrentWeather>(kind: .named("current"))
    }
}

extension WeatherQuery where T == Forecast<DayWeather> {
    public static var daily: WeatherQuery<Forecast<DayWeather>> {
        WeatherQuery<Forecast<DayWeather>>(kind: .named("daily"))
    }
}

extension WeatherQuery where T == Forecast<HourWeather> {
    public static var hourly: WeatherQuery<Forecast<HourWeather>> {
        WeatherQuery<Forecast<HourWeather>>(kind: .named("hourly"))
    }
}

extension WeatherQuery where T == Forecast<MinuteWeather>? {
    public static var minute: WeatherQuery<Forecast<MinuteWeather>?> {
        WeatherQuery<Forecast<MinuteWeather>?>(kind: .named("minute"))
    }
}

extension WeatherQuery where T == [WeatherAlert]? {
    public static var alerts: WeatherQuery<[WeatherAlert]?> {
        WeatherQuery<[WeatherAlert]?>(kind: .named("alerts"))
    }
}

extension WeatherQuery where T == WeatherAvailability {
    public static var availability: WeatherQuery<WeatherAvailability> {
        WeatherQuery<WeatherAvailability>(kind: .named("availability"))
    }
}

extension WeatherQuery where T == WeatherChanges? {
    public static var changes: WeatherQuery<WeatherChanges?> {
        WeatherQuery<WeatherChanges?>(kind: .named("changes"))
    }
}

extension WeatherQuery where T == HistoricalComparisons? {
    public static var historicalComparisons: WeatherQuery<HistoricalComparisons?> {
        WeatherQuery<HistoricalComparisons?>(kind: .named("historicalComparisons"))
    }
}

public struct DailyWeatherSummaryQuery<T>: Sendable
where T: Decodable, T: Encodable, T: Equatable, T: Sendable {}

extension DailyWeatherSummaryQuery where T == DayTemperatureSummary {
    public static var temperature: DailyWeatherSummaryQuery<DayTemperatureSummary> {
        DailyWeatherSummaryQuery<DayTemperatureSummary>()
    }
}

extension DailyWeatherSummaryQuery where T == DayPrecipitationSummary {
    public static var precipitation: DailyWeatherSummaryQuery<DayPrecipitationSummary> {
        DailyWeatherSummaryQuery<DayPrecipitationSummary>()
    }
}

public struct DailyWeatherStatisticsQuery<T>: Sendable
where T: Decodable, T: Encodable, T: Equatable, T: Sendable {}

extension DailyWeatherStatisticsQuery where T == DayTemperatureStatistics {
    public static var temperature: DailyWeatherStatisticsQuery<DayTemperatureStatistics> {
        DailyWeatherStatisticsQuery<DayTemperatureStatistics>()
    }
}

extension DailyWeatherStatisticsQuery where T == DayPrecipitationStatistics {
    public static var precipitation: DailyWeatherStatisticsQuery<DayPrecipitationStatistics> {
        DailyWeatherStatisticsQuery<DayPrecipitationStatistics>()
    }
}

public struct HourlyWeatherStatisticsQuery<T>: Sendable
where T: Decodable, T: Encodable, T: Equatable, T: Sendable {}

extension HourlyWeatherStatisticsQuery where T == HourTemperatureStatistics {
    public static var temperature: HourlyWeatherStatisticsQuery<HourTemperatureStatistics> {
        HourlyWeatherStatisticsQuery<HourTemperatureStatistics>()
    }
}

public struct MonthlyWeatherStatisticsQuery<T>: Sendable
where T: Decodable, T: Encodable, T: Equatable, T: Sendable {}

extension MonthlyWeatherStatisticsQuery where T == MonthTemperatureStatistics {
    public static var temperature: MonthlyWeatherStatisticsQuery<MonthTemperatureStatistics> {
        MonthlyWeatherStatisticsQuery<MonthTemperatureStatistics>()
    }
}

extension MonthlyWeatherStatisticsQuery where T == MonthPrecipitationStatistics {
    public static var precipitation: MonthlyWeatherStatisticsQuery<MonthPrecipitationStatistics> {
        MonthlyWeatherStatisticsQuery<MonthPrecipitationStatistics>()
    }
}

/// Apple weather service client. Linux has no WeatherKit daemon or network
/// entitlement, so every fetch fails closed.
public final class WeatherService: @unchecked Sendable {
    public static let shared = WeatherService()

    public convenience init() {
        self.init(marker: ())
    }

    private init(marker: Void) {}

    public var attribution: WeatherAttribution {
        get async throws {
            throw WeatherKitHost.unsupportedError()
        }
    }

    #if canImport(CoreLocation)
    public func weather(for location: CLLocation) async throws -> Weather {
        _ = location
        return try WeatherKitHost.fail()
    }

    @preconcurrency
    public func weather<T: Sendable>(
        for location: CLLocation,
        including dataSet: WeatherQuery<T>
    ) async throws -> T {
        _ = (location, dataSet)
        return try WeatherKitHost.fail()
    }

    @preconcurrency
    public func weather<each T: Sendable>(
        for location: CLLocation,
        including dataSet: repeat WeatherQuery<each T>
    ) async throws -> (repeat each T) {
        _ = location
        repeat _ = each dataSet
        return try WeatherKitHost.fail()
    }

    @preconcurrency
    public func weather<T1: Sendable, T2: Sendable>(
        for location: CLLocation,
        including dataSet1: WeatherQuery<T1>,
        _ dataSet2: WeatherQuery<T2>
    ) async throws -> (T1, T2) {
        _ = (location, dataSet1, dataSet2)
        return try WeatherKitHost.fail()
    }

    @preconcurrency
    public func weather<T1: Sendable, T2: Sendable, T3: Sendable>(
        for location: CLLocation,
        including dataSet1: WeatherQuery<T1>,
        _ dataSet2: WeatherQuery<T2>,
        _ dataSet3: WeatherQuery<T3>
    ) async throws -> (T1, T2, T3) {
        _ = (location, dataSet1, dataSet2, dataSet3)
        return try WeatherKitHost.fail()
    }

    @preconcurrency
    public func weather<T1: Sendable, T2: Sendable, T3: Sendable, T4: Sendable>(
        for location: CLLocation,
        including dataSet1: WeatherQuery<T1>,
        _ dataSet2: WeatherQuery<T2>,
        _ dataSet3: WeatherQuery<T3>,
        _ dataSet4: WeatherQuery<T4>
    ) async throws -> (T1, T2, T3, T4) {
        _ = (location, dataSet1, dataSet2, dataSet3, dataSet4)
        return try WeatherKitHost.fail()
    }

    @preconcurrency
    public func weather<T1: Sendable, T2: Sendable, T3: Sendable, T4: Sendable, T5: Sendable>(
        for location: CLLocation,
        including dataSet1: WeatherQuery<T1>,
        _ dataSet2: WeatherQuery<T2>,
        _ dataSet3: WeatherQuery<T3>,
        _ dataSet4: WeatherQuery<T4>,
        _ dataSet5: WeatherQuery<T5>
    ) async throws -> (T1, T2, T3, T4, T5) {
        _ = (location, dataSet1, dataSet2, dataSet3, dataSet4, dataSet5)
        return try WeatherKitHost.fail()
    }

    @preconcurrency
    public func weather<T1: Sendable, T2: Sendable, T3: Sendable, T4: Sendable, T5: Sendable, T6: Sendable>(
        for location: CLLocation,
        including dataSet1: WeatherQuery<T1>,
        _ dataSet2: WeatherQuery<T2>,
        _ dataSet3: WeatherQuery<T3>,
        _ dataSet4: WeatherQuery<T4>,
        _ dataSet5: WeatherQuery<T5>,
        _ dataSet6: WeatherQuery<T6>
    ) async throws -> (T1, T2, T3, T4, T5, T6) {
        _ = (location, dataSet1, dataSet2, dataSet3, dataSet4, dataSet5, dataSet6)
        return try WeatherKitHost.fail()
    }

    public func dailySummary<each T>(
        for location: CLLocation,
        including dataSets: repeat DailyWeatherSummaryQuery<each T>
    ) async throws -> (repeat DailyWeatherSummary<each T>)
    where repeat each T: Decodable, repeat each T: Encodable, repeat each T: Equatable, repeat each T: Sendable {
        _ = location
        repeat _ = each dataSets
        return try WeatherKitHost.fail()
    }

    public func dailySummary<each T>(
        for location: CLLocation,
        forDaysIn interval: DateInterval,
        including dataSets: repeat DailyWeatherSummaryQuery<each T>
    ) async throws -> (repeat DailyWeatherSummary<each T>)
    where repeat each T: Decodable, repeat each T: Encodable, repeat each T: Equatable, repeat each T: Sendable {
        _ = (location, interval)
        repeat _ = each dataSets
        return try WeatherKitHost.fail()
    }

    public func dailyStatistics<each T>(
        for location: CLLocation,
        including dataSets: repeat DailyWeatherStatisticsQuery<each T>
    ) async throws -> (repeat DailyWeatherStatistics<each T>)
    where repeat each T: Decodable, repeat each T: Encodable, repeat each T: Equatable, repeat each T: Sendable {
        _ = location
        repeat _ = each dataSets
        return try WeatherKitHost.fail()
    }

    public func dailyStatistics<each T>(
        for location: CLLocation,
        forDaysIn interval: DateInterval,
        including dataSets: repeat DailyWeatherStatisticsQuery<each T>
    ) async throws -> (repeat DailyWeatherStatistics<each T>)
    where repeat each T: Decodable, repeat each T: Encodable, repeat each T: Equatable, repeat each T: Sendable {
        _ = (location, interval)
        repeat _ = each dataSets
        return try WeatherKitHost.fail()
    }

    public func dailyStatistics<each T>(
        for location: CLLocation,
        startDay: Int,
        endDay: Int,
        including dataSets: repeat DailyWeatherStatisticsQuery<each T>
    ) async throws -> (repeat DailyWeatherStatistics<each T>)
    where repeat each T: Decodable, repeat each T: Encodable, repeat each T: Equatable, repeat each T: Sendable {
        _ = (location, startDay, endDay)
        repeat _ = each dataSets
        return try WeatherKitHost.fail()
    }

    public func hourlyStatistics<each T>(
        for location: CLLocation,
        including dataSets: repeat HourlyWeatherStatisticsQuery<each T>
    ) async throws -> (repeat HourlyWeatherStatistics<each T>)
    where repeat each T: Decodable, repeat each T: Encodable, repeat each T: Equatable, repeat each T: Sendable {
        _ = location
        repeat _ = each dataSets
        return try WeatherKitHost.fail()
    }

    public func hourlyStatistics<each T>(
        for location: CLLocation,
        forHoursIn interval: DateInterval,
        including dataSets: repeat HourlyWeatherStatisticsQuery<each T>
    ) async throws -> (repeat HourlyWeatherStatistics<each T>)
    where repeat each T: Decodable, repeat each T: Encodable, repeat each T: Equatable, repeat each T: Sendable {
        _ = (location, interval)
        repeat _ = each dataSets
        return try WeatherKitHost.fail()
    }

    public func hourlyStatistics<each T>(
        for location: CLLocation,
        startHour: Int,
        endHour: Int,
        including dataSets: repeat HourlyWeatherStatisticsQuery<each T>
    ) async throws -> (repeat HourlyWeatherStatistics<each T>)
    where repeat each T: Decodable, repeat each T: Encodable, repeat each T: Equatable, repeat each T: Sendable {
        _ = (location, startHour, endHour)
        repeat _ = each dataSets
        return try WeatherKitHost.fail()
    }

    public func monthlyStatistics<each T>(
        for location: CLLocation,
        including dataSets: repeat MonthlyWeatherStatisticsQuery<each T>
    ) async throws -> (repeat MonthlyWeatherStatistics<each T>)
    where repeat each T: Decodable, repeat each T: Encodable, repeat each T: Equatable, repeat each T: Sendable {
        _ = location
        repeat _ = each dataSets
        return try WeatherKitHost.fail()
    }

    public func monthlyStatistics<each T>(
        for location: CLLocation,
        forMonthsIn interval: DateInterval,
        including dataSets: repeat MonthlyWeatherStatisticsQuery<each T>
    ) async throws -> (repeat MonthlyWeatherStatistics<each T>)
    where repeat each T: Decodable, repeat each T: Encodable, repeat each T: Equatable, repeat each T: Sendable {
        _ = (location, interval)
        repeat _ = each dataSets
        return try WeatherKitHost.fail()
    }

    public func monthlyStatistics<each T>(
        for location: CLLocation,
        startMonth: Int,
        endMonth: Int,
        including dataSets: repeat MonthlyWeatherStatisticsQuery<each T>
    ) async throws -> (repeat MonthlyWeatherStatistics<each T>)
    where repeat each T: Decodable, repeat each T: Encodable, repeat each T: Equatable, repeat each T: Sendable {
        _ = (location, startMonth, endMonth)
        repeat _ = each dataSets
        return try WeatherKitHost.fail()
    }
    #endif
}
