import Foundation
import WeatherKit

func testUVIndexCategoryFromValue() {
    let samples: [(Int, UVIndex.ExposureCategory)] = [
        (0, .low), (2, .low), (3, .moderate), (5, .moderate),
        (6, .high), (7, .high), (8, .veryHigh), (10, .veryHigh),
        (11, .extreme), (15, .extreme)
    ]
    for (value, expected) in samples {
        let index = UVIndex(value: value)
        precondition(index.value == value)
        precondition(index.category == expected)
        precondition(expected.rangeValue.contains(value) || expected == .extreme)
    }
    precondition(UVIndex.ExposureCategory.low.rangeValue == 0...2)
    precondition(UVIndex.ExposureCategory.moderate.rangeValue == 3...5)
    precondition(UVIndex.ExposureCategory.high.rangeValue == 6...7)
    precondition(UVIndex.ExposureCategory.veryHigh.rangeValue == 8...10)
    precondition(UVIndex.ExposureCategory.extreme.rangeValue.lowerBound == 11)
    weatherKitRoundTrip(UVIndex(value: 4))
}

func testUVIndexExposureCategoryRawValuesRangesAndOrder() {
    precondition(
        UVIndex.ExposureCategory.allCases == [
            .low, .moderate, .high, .veryHigh, .extreme
        ]
    )
    precondition(UVIndex.ExposureCategory.low.rawValue == "low")
    precondition(UVIndex.ExposureCategory.veryHigh.description == "Very High")
    precondition(UVIndex.ExposureCategory.high.accessibilityDescription == "High")
    precondition(UVIndex.ExposureCategory.low < .moderate)
    precondition(UVIndex.ExposureCategory.moderate < .high)
    precondition(UVIndex.ExposureCategory.high < .veryHigh)
    precondition(UVIndex.ExposureCategory.veryHigh < .extreme)
    precondition(UVIndex.ExposureCategory.low <= .low)
    precondition(UVIndex.ExposureCategory.extreme >= .veryHigh)
    precondition(UVIndex.ExposureCategory.high > .moderate)
    let range: Range = UVIndex.ExposureCategory.low..<UVIndex.ExposureCategory.high
    precondition(range.contains(.moderate))
    let closed: ClosedRange = UVIndex.ExposureCategory.low...UVIndex.ExposureCategory.high
    precondition(closed.contains(.high))
    let partialFrom: PartialRangeFrom = UVIndex.ExposureCategory.high...
    precondition(partialFrom.contains(.extreme))
    let partialThrough: PartialRangeThrough = ...UVIndex.ExposureCategory.moderate
    precondition(partialThrough.contains(.low))
    let partialUpTo: PartialRangeUpTo = ..<UVIndex.ExposureCategory.high
    precondition(partialUpTo.contains(.moderate))
    precondition(UVIndex.ExposureCategory(rawValue: "extreme") == .extreme)
    weatherKitRoundTrip(UVIndex.ExposureCategory.moderate)
    var hasher = Hasher()
    UVIndex.ExposureCategory.high.hash(into: &hasher)
    _ = hasher.finalize()
    _ = UVIndex.ExposureCategory.high.hashValue
}

func testWindCompassDirectionFromDegrees() {
    let north = Wind.CompassDirection(degrees: 0)
    let east = Wind.CompassDirection(degrees: 90)
    let south = Wind.CompassDirection(degrees: 180)
    let west = Wind.CompassDirection(degrees: 270)
    let nne = Wind.CompassDirection(degrees: 22.5)
    precondition(north == .north)
    precondition(east == .east)
    precondition(south == .south)
    precondition(west == .west)
    precondition(nne == .northNortheast)
    let wrapped = Wind.CompassDirection(degrees: 360)
    precondition(wrapped == .north)
    let negative = Wind.CompassDirection(degrees: -90)
    precondition(negative == .west)
    let wind = Wind(
        direction: Measurement(value: 45, unit: .degrees),
        speed: Measurement(value: 4, unit: .metersPerSecond)
    )
    precondition(wind.compassDirection == .northeast)
    precondition(wind.gust == nil)
    weatherKitRoundTrip(windKitWithGust())
}

func windKitWithGust() -> Wind {
    Wind(
        direction: Measurement(value: 90, unit: .degrees),
        speed: Measurement(value: 6, unit: .metersPerSecond),
        gust: Measurement(value: 10, unit: .metersPerSecond)
    )
}

func testWindCompassDirectionRawValuesAndAbbreviations() {
    precondition(
        Wind.CompassDirection.allCases == [
            .north, .northNortheast, .northeast, .eastNortheast, .east,
            .eastSoutheast, .southeast, .southSoutheast, .south, .southSouthwest,
            .southwest, .westSouthwest, .west, .westNorthwest, .northwest,
            .northNorthwest
        ]
    )
    precondition(Wind.CompassDirection.north.abbreviation == "N")
    precondition(Wind.CompassDirection.northNortheast.abbreviation == "NNE")
    precondition(Wind.CompassDirection.northeast.abbreviation == "NE")
    precondition(Wind.CompassDirection.eastNortheast.abbreviation == "ENE")
    precondition(Wind.CompassDirection.east.abbreviation == "E")
    precondition(Wind.CompassDirection.eastSoutheast.abbreviation == "ESE")
    precondition(Wind.CompassDirection.southeast.abbreviation == "SE")
    precondition(Wind.CompassDirection.southSoutheast.abbreviation == "SSE")
    precondition(Wind.CompassDirection.south.abbreviation == "S")
    precondition(Wind.CompassDirection.southSouthwest.abbreviation == "SSW")
    precondition(Wind.CompassDirection.southwest.abbreviation == "SW")
    precondition(Wind.CompassDirection.westSouthwest.abbreviation == "WSW")
    precondition(Wind.CompassDirection.west.abbreviation == "W")
    precondition(Wind.CompassDirection.westNorthwest.abbreviation == "WNW")
    precondition(Wind.CompassDirection.northwest.abbreviation == "NW")
    precondition(Wind.CompassDirection.northNorthwest.abbreviation == "NNW")
    precondition(Wind.CompassDirection.north.description == "North")
    precondition(Wind.CompassDirection.south.accessibilityDescription == "South")
    precondition(Wind.CompassDirection(rawValue: "east") == .east)
    weatherKitRoundTrip(Wind.CompassDirection.northwest)
    var hasher = Hasher()
    Wind.CompassDirection.east.hash(into: &hasher)
    _ = hasher.finalize()
    _ = Wind.CompassDirection.east.hashValue
}

func testWeatherErrorLocalizedAndHashable() {
    let denied = WeatherError.permissionDenied
    let unknown = WeatherError.unknown
    precondition(denied != unknown)
    precondition(denied.errorDescription == "This app is not permitted to use WeatherKit.")
    precondition(
        unknown.errorDescription
            == "WeatherKit Apple weather services are unavailable on this Linux host."
    )
    precondition(denied.failureReason != nil)
    precondition(unknown.failureReason != nil)
    precondition(denied.recoverySuggestion != nil)
    precondition(unknown.recoverySuggestion != nil)
    precondition(denied.helpAnchor == nil)
    precondition(unknown.helpAnchor == nil)
    precondition(denied.localizedDescription == denied.errorDescription)
    precondition(unknown.localizedDescription == unknown.errorDescription)
    let asError: Error = unknown
    precondition(asError.localizedDescription == unknown.errorDescription)
    var hasher = Hasher()
    denied.hash(into: &hasher)
    unknown.hash(into: &hasher)
    _ = hasher.finalize()
    _ = denied.hashValue
    do {
        throw WeatherError.unknown
    } catch let error as WeatherError {
        precondition(error == .unknown)
    } catch {
        preconditionFailure("expected WeatherError")
    }
}

func testWeatherQueryDataSetsAndDateRanges() {
    let current: WeatherQuery<CurrentWeather> = .current
    let daily: WeatherQuery<Forecast<DayWeather>> = .daily
    let hourly: WeatherQuery<Forecast<HourWeather>> = .hourly
    let minute: WeatherQuery<Forecast<MinuteWeather>?> = .minute
    let alerts: WeatherQuery<[WeatherAlert]?> = .alerts
    let availability: WeatherQuery<WeatherAvailability> = .availability
    let changes: WeatherQuery<WeatherChanges?> = .changes
    let historical: WeatherQuery<HistoricalComparisons?> = .historicalComparisons
    _ = (current, daily, hourly, minute, alerts, availability, changes, historical)
    let start = weatherKitDate()
    let end = weatherKitDate(86_400)
    let rangedDaily: WeatherQuery<Forecast<DayWeather>> =
        WeatherQuery<Forecast<DayWeather>>.daily(startDate: start, endDate: end)
    let rangedHourly: WeatherQuery<Forecast<HourWeather>> =
        WeatherQuery<Forecast<HourWeather>>.hourly(startDate: start, endDate: end)
    _ = (rangedDaily, rangedHourly)
    let temperatureSummary: DailyWeatherSummaryQuery<DayTemperatureSummary> = .temperature
    let precipitationSummary: DailyWeatherSummaryQuery<DayPrecipitationSummary> = .precipitation
    let dailyTempStats: DailyWeatherStatisticsQuery<DayTemperatureStatistics> = .temperature
    let dailyPrecipStats: DailyWeatherStatisticsQuery<DayPrecipitationStatistics> = .precipitation
    let hourlyTempStats: HourlyWeatherStatisticsQuery<HourTemperatureStatistics> = .temperature
    let monthlyTempStats: MonthlyWeatherStatisticsQuery<MonthTemperatureStatistics> = .temperature
    let monthlyPrecipStats: MonthlyWeatherStatisticsQuery<MonthPrecipitationStatistics> = .precipitation
    _ = (
        temperatureSummary, precipitationSummary, dailyTempStats, dailyPrecipStats,
        hourlyTempStats, monthlyTempStats, monthlyPrecipStats
    )
}

func testWeatherServiceSharedIdentity() {
    let shared = WeatherService.shared
    let constructed = WeatherService()
    precondition(shared !== constructed)
    _ = WeatherService.shared
}
