import Foundation
import WeatherKit

func testForecastCollectionAndCodable() {
    let hour = HourWeather(
        date: weatherKitDate(),
        cloudCover: 0.1,
        isDaylight: true,
        symbolName: "sun.max",
        visibility: Measurement(value: 10, unit: .kilometers),
        temperature: weatherKitTemperature(20),
        apparentTemperature: weatherKitTemperature(19),
        dewPoint: weatherKitTemperature(10),
        humidity: 0.4,
        pressure: Measurement(value: 1015, unit: .hectopascals),
        pressureTrend: .rising,
        precipitation: .none,
        precipitationAmount: weatherKitZeroLength(),
        precipitationChance: 0,
        snowfallAmount: weatherKitZeroLength(),
        wind: weatherKitWind(),
        uvIndex: UVIndex(value: 3),
        condition: .clear,
        cloudCoverByAltitude: weatherKitCloudCover()
    )
    let forecast = Forecast(forecast: [hour, hour], metadata: weatherKitMetadata())
    precondition(forecast.startIndex == 0)
    precondition(forecast.endIndex == 2)
    precondition(forecast.count == 2)
    precondition(!forecast.isEmpty)
    precondition(forecast.first != nil)
    precondition(forecast.last != nil)
    precondition(forecast[0].condition == .clear)
    precondition(forecast.summary == "2-period forecast")
    precondition(forecast.map(\.condition) == [.clear, .clear])
    precondition(forecast.contains(where: { $0.condition == .clear }))
    weatherKitRoundTrip(forecast)

    let day = DayWeather(
        date: weatherKitDate(),
        symbolName: "sun.max",
        highWindSpeed: nil,
        precipitation: .none,
        lowTemperature: weatherKitTemperature(10),
        highTemperature: weatherKitTemperature(20),
        rainfallAmount: weatherKitZeroLength(),
        snowfallAmount: weatherKitZeroLength(),
        daytimeForecast: weatherKitDayPart(),
        overnightForecast: weatherKitDayPart(),
        restOfDayForecast: nil,
        maximumHumidity: 0.6,
        minimumHumidity: 0.3,
        maximumVisibility: 16,
        minimumVisibility: 10,
        lowTemperatureTime: nil,
        highTemperatureTime: nil,
        precipitationChance: 0.1,
        precipitationAmountByType: weatherKitPrecipitationAmounts(),
        sun: SunEvents(),
        moon: MoonEvents(phase: .new),
        wind: weatherKitWind(),
        uvIndex: UVIndex(value: 4),
        condition: .mostlyClear
    )
    let daily = Forecast(forecast: [day], metadata: weatherKitMetadata())
    weatherKitRoundTrip(daily)

    let minute = MinuteWeather(
        date: weatherKitDate(),
        precipitation: .none,
        precipitationChance: 0,
        precipitationIntensity: weatherKitZeroSpeed()
    )
    let minutes = Forecast(forecast: [minute], metadata: weatherKitMetadata())
    weatherKitRoundTrip(minutes)
    precondition(minutes == minutes)
}

func testWeatherAggregate() {
    let current = CurrentWeather(
        date: weatherKitDate(),
        cloudCover: 0.2,
        isDaylight: true,
        symbolName: "sun.max",
        visibility: Measurement(value: 16, unit: .kilometers),
        temperature: weatherKitTemperature(21),
        apparentTemperature: weatherKitTemperature(20),
        dewPoint: weatherKitTemperature(12),
        humidity: 0.45,
        pressure: Measurement(value: 1013, unit: .hectopascals),
        pressureTrend: .steady,
        wind: weatherKitWind(),
        uvIndex: UVIndex(value: 5),
        condition: .mostlyClear,
        cloudCoverByAltitude: weatherKitCloudCover(),
        precipitationIntensity: weatherKitZeroSpeed(),
        metadata: weatherKitMetadata()
    )
    let weather = Weather(
        currentWeather: current,
        availability: WeatherAvailability(alertAvailability: .available, minuteAvailability: .available),
        dailyForecast: Forecast(forecast: [], metadata: weatherKitMetadata()),
        hourlyForecast: Forecast(forecast: [], metadata: weatherKitMetadata()),
        minuteForecast: nil,
        weatherAlerts: nil
    )
    precondition(weather.currentWeather.condition == .mostlyClear)
    precondition(weather.dailyForecast.isEmpty)
    precondition(weather.hourlyForecast.isEmpty)
    precondition(weather.minuteForecast == nil)
    precondition(weather.weatherAlerts == nil)
    weatherKitRoundTrip(weather)
}

func testDailyWeatherStatisticsCollection() {
    let row = DayTemperatureStatistics(
        day: 1,
        averageLowTemperature: weatherKitTemperature(5),
        averageHighTemperature: weatherKitTemperature(15)
    )
    let stats = DailyWeatherStatistics(
        days: [row, row],
        baselineStartDate: weatherKitDate(),
        metadata: weatherKitMetadata()
    )
    precondition(stats.startIndex == 0)
    precondition(stats.endIndex == 2)
    precondition(stats[0].day == 1)
    precondition(stats.days.count == 2)
    weatherKitRoundTrip(stats)
}

func testHourlyWeatherStatisticsCollection() {
    let row = HourTemperatureStatistics(
        hour: 3,
        percentiles: Percentiles(
            p10: weatherKitTemperature(9),
            p50: weatherKitTemperature(11),
            p90: weatherKitTemperature(13)
        )
    )
    let stats = HourlyWeatherStatistics(
        hours: [row],
        baselineStartDate: weatherKitDate(),
        metadata: weatherKitMetadata()
    )
    precondition(stats.endIndex == 1)
    precondition(stats[0].hour == 3)
    weatherKitRoundTrip(stats)
}

func testMonthlyWeatherStatisticsCollection() {
    let row = MonthTemperatureStatistics(
        month: 6,
        averageLowTemperature: weatherKitTemperature(14),
        averageHighTemperature: weatherKitTemperature(24)
    )
    let stats = MonthlyWeatherStatistics(
        months: [row],
        baselineStartDate: weatherKitDate(),
        metadata: weatherKitMetadata()
    )
    precondition(stats[0].month == 6)
    weatherKitRoundTrip(stats)
}

func testDailyWeatherSummaryCollection() {
    let row = DayTemperatureSummary(
        date: weatherKitDate(),
        lowTemperature: weatherKitTemperature(8),
        highTemperature: weatherKitTemperature(18)
    )
    let summary = DailyWeatherSummary(days: [row], metadata: weatherKitMetadata())
    precondition(summary.days.count == 1)
    precondition(summary[0].highTemperature.value == 18)
    weatherKitRoundTrip(summary)
}

func testWeatherChangesCollection() {
    let change = WeatherChange(
        date: weatherKitDate(),
        lowTemperature: .increase,
        highTemperature: .steady,
        dayPrecipitationAmount: .decrease,
        nightPrecipitationAmount: .steady
    )
    let changes = WeatherChanges(changes: [change], metadata: weatherKitMetadata())
    precondition(changes[0].lowTemperature == .increase)
    precondition(changes.count == 1)
    weatherKitRoundTrip(changes)
}

func testHistoricalComparisonsCollection() {
    let baseline = TrendBaseline(
        kind: .mean,
        value: weatherKitTemperature(15),
        startDate: weatherKitDate()
    )
    let comparison = HistoricalComparison.highTemperature(
        Trend(currentValue: weatherKitTemperature(18), baseline: baseline, deviation: .higher)
    )
    let comparisons = HistoricalComparisons(
        comparisons: [comparison],
        metadata: weatherKitMetadata()
    )
    precondition(comparisons.count == 1)
    weatherKitRoundTrip(comparisons)
}
