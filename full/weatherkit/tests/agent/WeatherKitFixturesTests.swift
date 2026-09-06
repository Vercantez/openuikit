import Foundation
import WeatherKit

func weatherKitDate(_ offset: TimeInterval = 0) -> Date {
    Date(timeIntervalSince1970: 1_704_067_200 + offset)
}

func weatherKitMetadata() -> WeatherMetadata {
    WeatherMetadata(
        date: weatherKitDate(),
        expirationDate: weatherKitDate(3600),
        latitude: 37.3349,
        longitude: -122.009,
        altitude: 10
    )
}

func weatherKitZeroLength() -> Measurement<UnitLength> {
    Measurement(value: 0, unit: .millimeters)
}

func weatherKitZeroSpeed() -> Measurement<UnitSpeed> {
    Measurement(value: 0, unit: .metersPerSecond)
}

func weatherKitTemperature(_ value: Double) -> Measurement<UnitTemperature> {
    Measurement(value: value, unit: .celsius)
}

func weatherKitWind() -> Wind {
    Wind(
        direction: Measurement(value: 0, unit: .degrees),
        speed: Measurement(value: 3, unit: .metersPerSecond),
        gust: Measurement(value: 5, unit: .metersPerSecond)
    )
}

func weatherKitCloudCover() -> CloudCoverByAltitude {
    CloudCoverByAltitude(low: 0.1, medium: 0.2, high: 0.3)
}

func weatherKitSnowfall() -> SnowfallAmount {
    SnowfallAmount(
        amount: Measurement(value: 2, unit: .centimeters),
        amountLiquidEquivalent: Measurement(value: 2, unit: .millimeters),
        maximum: Measurement(value: 4, unit: .centimeters),
        maximumLiquidEquivalent: Measurement(value: 4, unit: .millimeters),
        minimum: Measurement(value: 1, unit: .centimeters),
        minimumLiquidEquivalent: Measurement(value: 1, unit: .millimeters)
    )
}

func weatherKitPrecipitationAmounts() -> PrecipitationAmountByType {
    PrecipitationAmountByType(
        precipitation: Measurement(value: 5, unit: .millimeters),
        rainfall: Measurement(value: 4, unit: .millimeters),
        snowfallAmount: weatherKitSnowfall(),
        hail: weatherKitZeroLength(),
        mixed: weatherKitZeroLength(),
        sleet: weatherKitZeroLength()
    )
}

func weatherKitDayPart() -> DayPartForecast {
    DayPartForecast(
        cloudCover: 0.4,
        highWindSpeed: Measurement(value: 8, unit: .metersPerSecond),
        precipitation: .rain,
        lowTemperature: weatherKitTemperature(10),
        highTemperature: weatherKitTemperature(18),
        maximumHumidity: 0.8,
        minimumHumidity: 0.4,
        maximumVisibility: Measurement(value: 16, unit: .kilometers),
        minimumVisibility: Measurement(value: 8, unit: .kilometers),
        precipitationChance: 0.3,
        cloudCoverByAltitude: weatherKitCloudCover(),
        precipitationAmountByType: weatherKitPrecipitationAmounts(),
        wind: weatherKitWind(),
        condition: .rain
    )
}

func weatherKitRoundTrip<T: Codable & Equatable>(_ value: T) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    do {
        let data = try encoder.encode(value)
        let decoded = try decoder.decode(T.self, from: data)
        precondition(decoded == value)
    } catch {
        preconditionFailure("codable round-trip failed: \(error)")
    }
}

func testWeatherKitFixtureHelpersExist() {
    precondition(weatherKitMetadata().latitude == 37.3349)
}

func weatherKitIntForecast(_ values: [Int] = [3, 1, 4, 1, 5, 9, 2]) -> Forecast<Int> {
    Forecast(forecast: values, metadata: weatherKitMetadata())
}

func weatherKitStringForecast(_ values: [String] = ["rain", "snow", "rain"]) -> Forecast<String> {
    Forecast(forecast: values, metadata: weatherKitMetadata())
}

func weatherKitNestedForecast() -> Forecast<[Int]> {
    Forecast(forecast: [[1, 2], [3], [4, 5]], metadata: weatherKitMetadata())
}

func weatherKitIntDays(_ values: [Int] = [3, 1, 4, 1, 5, 9, 2]) -> DailyWeatherStatistics<Int> {
    DailyWeatherStatistics(days: values, baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
}

func weatherKitIntHours(_ values: [Int] = [3, 1, 4, 1, 5, 9, 2]) -> HourlyWeatherStatistics<Int> {
    HourlyWeatherStatistics(hours: values, baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
}

func weatherKitIntMonths(_ values: [Int] = [3, 1, 4, 1, 5, 9, 2]) -> MonthlyWeatherStatistics<Int> {
    MonthlyWeatherStatistics(months: values, baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
}

func weatherKitIntSummary(_ values: [Int] = [3, 1, 4, 1, 5, 9, 2]) -> DailyWeatherSummary<Int> {
    DailyWeatherSummary(days: values, metadata: weatherKitMetadata())
}

func weatherKitSampleChange(_ temperature: WeatherChange.Direction = .increase) -> WeatherChange {
    WeatherChange(
        date: weatherKitDate(),
        lowTemperature: temperature,
        highTemperature: .steady,
        dayPrecipitationAmount: .decrease,
        nightPrecipitationAmount: .steady
    )
}

func weatherKitChangeCollection() -> WeatherChanges {
    WeatherChanges(
        changes: [weatherKitSampleChange(.increase), weatherKitSampleChange(.decrease), weatherKitSampleChange(.steady)],
        metadata: weatherKitMetadata()
    )
}

func weatherKitComparisonCollection() -> HistoricalComparisons {
    let baseline = TrendBaseline(
        kind: .mean,
        value: weatherKitTemperature(15),
        startDate: weatherKitDate()
    )
    let high = HistoricalComparison.highTemperature(
        Trend(currentValue: weatherKitTemperature(18), baseline: baseline, deviation: .higher)
    )
    let low = HistoricalComparison.lowTemperature(
        Trend(currentValue: weatherKitTemperature(10), baseline: baseline, deviation: .lower)
    )
    return HistoricalComparisons(comparisons: [high, low, high], metadata: weatherKitMetadata())
}

