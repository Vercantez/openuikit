import Foundation
import WeatherKit

func testWeatherMetadataCodable() {
    let metadata = weatherKitMetadata()
    precondition(metadata.date == weatherKitDate())
    precondition(metadata.expirationDate == weatherKitDate(3600))
    precondition(metadata.latitude == 37.3349)
    precondition(metadata.longitude == -122.009)
    precondition(metadata.altitude == 10)
    weatherKitRoundTrip(metadata)
    let other = WeatherMetadata(date: weatherKitDate(1), expirationDate: weatherKitDate(2))
    precondition(metadata != other)
}

func testCloudCoverByAltitude() {
    let cover = weatherKitCloudCover()
    precondition(cover.low == 0.1)
    precondition(cover.medium == 0.2)
    precondition(cover.high == 0.3)
    weatherKitRoundTrip(cover)
    precondition(cover != CloudCoverByAltitude(low: 1, medium: 1, high: 1))
}

func testPrecipitationAmountByType() {
    let amounts = weatherKitPrecipitationAmounts()
    precondition(amounts.precipitation.value == 5)
    precondition(amounts.rainfall.value == 4)
    precondition(amounts.snowfallAmount.amount.value == 2)
    precondition(amounts.hail.value == 0)
    precondition(amounts.mixed.value == 0)
    precondition(amounts.sleet.value == 0)
    weatherKitRoundTrip(amounts)
}

func testSnowfallAmount() {
    let snow = weatherKitSnowfall()
    precondition(snow.amount.value == 2)
    precondition(snow.amountLiquidEquivalent.value == 2)
    precondition(snow.maximum.value == 4)
    precondition(snow.maximumLiquidEquivalent.value == 4)
    precondition(snow.minimum.value == 1)
    precondition(snow.minimumLiquidEquivalent.value == 1)
    weatherKitRoundTrip(snow)
}

func testPercentiles() {
    let percentiles = Percentiles<UnitTemperature>(
        p10: weatherKitTemperature(8),
        p50: weatherKitTemperature(12),
        p90: weatherKitTemperature(16)
    )
    precondition(percentiles.p10.value == 8)
    precondition(percentiles.p50.value == 12)
    precondition(percentiles.p90.value == 16)
    weatherKitRoundTrip(percentiles)
}

func testTrendAndBaseline() {
    let baseline = TrendBaseline(
        kind: .mean,
        value: weatherKitTemperature(14),
        startDate: weatherKitDate(-86_400)
    )
    precondition(baseline.kind == .mean)
    precondition(baseline.value.value == 14)
    precondition(baseline.startDate == weatherKitDate(-86_400))
    let trend = Trend(
        currentValue: weatherKitTemperature(17),
        baseline: baseline,
        deviation: .higher
    )
    precondition(trend.currentValue.value == 17)
    precondition(trend.deviation == .higher)
    weatherKitRoundTrip(baseline)
    weatherKitRoundTrip(trend)
}

func testSunEvents() {
    let events = SunEvents(
        sunrise: weatherKitDate(6 * 3600),
        sunset: weatherKitDate(18 * 3600),
        civilDawn: weatherKitDate(5 * 3600),
        civilDusk: weatherKitDate(19 * 3600),
        nauticalDawn: weatherKitDate(4 * 3600),
        nauticalDusk: weatherKitDate(20 * 3600),
        astronomicalDawn: weatherKitDate(3 * 3600),
        astronomicalDusk: weatherKitDate(21 * 3600),
        solarNoon: weatherKitDate(12 * 3600),
        solarMidnight: weatherKitDate(0)
    )
    precondition(events.sunrise != nil)
    precondition(events.sunset != nil)
    precondition(events.civilDawn != nil)
    precondition(events.civilDusk != nil)
    precondition(events.nauticalDawn != nil)
    precondition(events.nauticalDusk != nil)
    precondition(events.astronomicalDawn != nil)
    precondition(events.astronomicalDusk != nil)
    precondition(events.solarNoon != nil)
    precondition(events.solarMidnight != nil)
    weatherKitRoundTrip(events)
    precondition(events != SunEvents())
}

func testMoonEvents() {
    let events = MoonEvents(
        moonrise: weatherKitDate(20 * 3600),
        moonset: weatherKitDate(8 * 3600),
        phase: .waxingGibbous
    )
    precondition(events.phase == .waxingGibbous)
    precondition(events.moonrise != nil)
    precondition(events.moonset != nil)
    weatherKitRoundTrip(events)
}

func testCurrentWeatherRoundTrip() {
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
    precondition(current.isDaylight)
    precondition(current.condition == .mostlyClear)
    precondition(current.uvIndex.category == .moderate)
    weatherKitRoundTrip(current)
}

func testHourWeatherRoundTrip() {
    let hour = HourWeather(
        date: weatherKitDate(),
        cloudCover: 0.5,
        isDaylight: false,
        symbolName: "cloud.rain",
        visibility: Measurement(value: 8, unit: .kilometers),
        temperature: weatherKitTemperature(14),
        apparentTemperature: weatherKitTemperature(13),
        dewPoint: weatherKitTemperature(11),
        humidity: 0.7,
        pressure: Measurement(value: 1008, unit: .hectopascals),
        pressureTrend: .falling,
        precipitation: .rain,
        precipitationAmount: Measurement(value: 1, unit: .millimeters),
        precipitationChance: 0.6,
        snowfallAmount: weatherKitZeroLength(),
        wind: weatherKitWind(),
        uvIndex: UVIndex(value: 0),
        condition: .rain,
        cloudCoverByAltitude: weatherKitCloudCover()
    )
    precondition(hour.precipitation == .rain)
    precondition(!hour.isDaylight)
    weatherKitRoundTrip(hour)
}

func testDayWeatherRoundTrip() {
    let day = DayWeather(
        date: weatherKitDate(),
        symbolName: "cloud.sun.rain",
        highWindSpeed: Measurement(value: 12, unit: .metersPerSecond),
        precipitation: .rain,
        lowTemperature: weatherKitTemperature(9),
        highTemperature: weatherKitTemperature(17),
        rainfallAmount: Measurement(value: 6, unit: .millimeters),
        snowfallAmount: weatherKitZeroLength(),
        daytimeForecast: weatherKitDayPart(),
        overnightForecast: weatherKitDayPart(),
        restOfDayForecast: weatherKitDayPart(),
        maximumHumidity: 0.9,
        minimumHumidity: 0.4,
        maximumVisibility: 16,
        minimumVisibility: 4,
        lowTemperatureTime: weatherKitDate(6 * 3600),
        highTemperatureTime: weatherKitDate(15 * 3600),
        precipitationChance: 0.55,
        precipitationAmountByType: weatherKitPrecipitationAmounts(),
        sun: SunEvents(sunrise: weatherKitDate(6 * 3600), sunset: weatherKitDate(18 * 3600)),
        moon: MoonEvents(phase: .firstQuarter),
        wind: weatherKitWind(),
        uvIndex: UVIndex(value: 6),
        condition: .sunShowers
    )
    precondition(day.precipitationAmount.value == 5)
    precondition(day.restOfDayForecast != nil)
    precondition(day.daytimeForecast.condition == .rain)
    precondition(day.overnightForecast.precipitation == .rain)
    weatherKitRoundTrip(day)
}

func testMinuteWeatherRoundTrip() {
    let minute = MinuteWeather(
        date: weatherKitDate(),
        precipitation: .rain,
        precipitationChance: 0.8,
        precipitationIntensity: Measurement(value: 2, unit: .metersPerSecond)
    )
    precondition(minute.precipitationChance == 0.8)
    weatherKitRoundTrip(minute)
}

func testDayPartForecast() {
    let part = weatherKitDayPart()
    precondition(part.cloudCover == 0.4)
    precondition(part.highWindSpeed.value == 8)
    precondition(part.maximumHumidity == 0.8)
    precondition(part.minimumHumidity == 0.4)
    weatherKitRoundTrip(part)
}

func testWeatherAlertAndAttribution() {
    let url = URL(string: "https://weatherkit.apple.com/legal")!
    let attribution = WeatherAttribution(
        legalAttributionText: "Weather data provided for testing.",
        serviceName: "WeatherKit",
        legalPageURL: url,
        squareMarkURL: url,
        combinedMarkDarkURL: url,
        combinedMarkLightURL: url
    )
    precondition(attribution.serviceName == "WeatherKit")
    precondition(attribution.legalAttributionText.contains("Weather"))
    weatherKitRoundTrip(attribution)
    let alert = WeatherAlert(
        detailsURL: url,
        region: "CA",
        source: "NWS",
        summary: "Wind advisory",
        metadata: weatherKitMetadata(),
        severity: .moderate
    )
    precondition(alert.region == "CA")
    precondition(alert.severity == .moderate)
    weatherKitRoundTrip(alert)
}

func testWeatherAvailability() {
    let availability = WeatherAvailability(
        alertAvailability: .available,
        minuteAvailability: .unsupported
    )
    precondition(availability.alertAvailability == .available)
    precondition(availability.minuteAvailability == .unsupported)
    weatherKitRoundTrip(availability)
}

func testDayTemperatureSummary() {
    let summary = DayTemperatureSummary(
        date: weatherKitDate(),
        lowTemperature: weatherKitTemperature(8),
        highTemperature: weatherKitTemperature(18)
    )
    weatherKitRoundTrip(summary)
}

func testDayPrecipitationSummary() {
    let summary = DayPrecipitationSummary(
        date: weatherKitDate(),
        snowfallAmount: weatherKitZeroLength(),
        precipitationAmount: Measurement(value: 3, unit: .millimeters)
    )
    weatherKitRoundTrip(summary)
}

func testDayTemperatureStatistics() {
    let stats = DayTemperatureStatistics(
        day: 100,
        averageLowTemperature: weatherKitTemperature(7),
        averageHighTemperature: weatherKitTemperature(16)
    )
    precondition(stats.day == 100)
    weatherKitRoundTrip(stats)
}

func testHourTemperatureStatistics() {
    let stats = HourTemperatureStatistics(
        hour: 15,
        percentiles: Percentiles(
            p10: weatherKitTemperature(10),
            p50: weatherKitTemperature(14),
            p90: weatherKitTemperature(18)
        )
    )
    precondition(stats.hour == 15)
    weatherKitRoundTrip(stats)
}

func testDayPrecipitationStatistics() {
    let stats = DayPrecipitationStatistics(
        day: 200,
        averagePrecipitationProbability: 0.22,
        averagePrecipitationAmount: Measurement(value: 2, unit: .millimeters),
        averageSnowfallAmount: weatherKitZeroLength()
    )
    precondition(stats.averagePrecipitationProbability == 0.22)
    weatherKitRoundTrip(stats)
}

func testMonthTemperatureStatistics() {
    let stats = MonthTemperatureStatistics(
        month: 9,
        averageLowTemperature: weatherKitTemperature(12),
        averageHighTemperature: weatherKitTemperature(22)
    )
    precondition(stats.month == 9)
    weatherKitRoundTrip(stats)
}

func testMonthPrecipitationStatistics() {
    let stats = MonthPrecipitationStatistics(
        month: 1,
        averagePrecipitationProbability: 0.4,
        averagePrecipitationAmount: Measurement(value: 80, unit: .millimeters),
        averageSnowfallAmount: Measurement(value: 10, unit: .centimeters)
    )
    precondition(stats.month == 1)
    weatherKitRoundTrip(stats)
}
