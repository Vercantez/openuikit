import Foundation
import WeatherKit

func testWeatherConditionRawValuesAndDescriptions() {
    let expected: [WeatherCondition] = [
        .blizzard, .blowingDust, .blowingSnow, .breezy, .clear, .cloudy, .drizzle,
        .flurries, .foggy, .freezingDrizzle, .freezingRain, .frigid, .hail, .haze,
        .heavyRain, .heavySnow, .hot, .hurricane, .isolatedThunderstorms, .mostlyClear,
        .mostlyCloudy, .partlyCloudy, .rain, .scatteredThunderstorms, .sleet, .smoky,
        .snow, .strongStorms, .sunFlurries, .sunShowers, .thunderstorms, .tropicalStorm,
        .windy, .wintryMix
    ]
    precondition(WeatherCondition.allCases == expected)
    for condition in WeatherCondition.allCases {
        precondition(WeatherCondition(rawValue: condition.rawValue) == condition)
        precondition(!condition.description.isEmpty)
        precondition(condition.accessibilityDescription == condition.description)
        precondition(WeatherCondition(rawValue: "not-a-condition") == nil)
    }
    precondition(WeatherCondition.sunShowers.rawValue == "sunShowers")
    precondition(WeatherCondition.sunShowers.description == "Sun Showers")
    precondition(WeatherCondition.clear != WeatherCondition.cloudy)
    weatherKitRoundTrip(WeatherCondition.partlyCloudy)
    var hasher = Hasher()
    WeatherCondition.rain.hash(into: &hasher)
    _ = hasher.finalize()
    _ = WeatherCondition.rain.hashValue
}

func testPrecipitationRawValuesAndDescriptions() {
    precondition(
        Precipitation.allCases == [.none, .hail, .mixed, .rain, .sleet, .snow]
    )
    precondition(Precipitation.none.rawValue == "none")
    precondition(Precipitation.rain.description == "Rain")
    precondition(Precipitation.snow.accessibilityDescription == "Snow")
    precondition(Precipitation(rawValue: "mixed") == .mixed)
    precondition(Precipitation(rawValue: "ice") == nil)
    precondition(Precipitation.hail != Precipitation.sleet)
    weatherKitRoundTrip(Precipitation.mixed)
    var hasher = Hasher()
    Precipitation.rain.hash(into: &hasher)
    _ = hasher.finalize()
    _ = Precipitation.rain.hashValue
}

func testPressureTrendRawValuesAndDescriptions() {
    precondition(PressureTrend.allCases == [.rising, .falling, .steady])
    precondition(PressureTrend.rising.rawValue == "rising")
    precondition(PressureTrend.falling.description == "Falling")
    precondition(PressureTrend.steady.accessibilityDescription == "Steady")
    precondition(PressureTrend(rawValue: "rising") == .rising)
    precondition(PressureTrend.rising != PressureTrend.falling)
    weatherKitRoundTrip(PressureTrend.steady)
    var hasher = Hasher()
    PressureTrend.rising.hash(into: &hasher)
    _ = hasher.finalize()
    _ = PressureTrend.rising.hashValue
}

func testWeatherSeverityRawValuesAndDescriptions() {
    precondition(
        WeatherSeverity.allCases == [.minor, .moderate, .severe, .extreme, .unknown]
    )
    precondition(WeatherSeverity.minor.rawValue == "minor")
    precondition(WeatherSeverity.severe.description == "Severe")
    precondition(WeatherSeverity.extreme.accessibilityDescription == "Extreme")
    precondition(WeatherSeverity(rawValue: "moderate") == .moderate)
    precondition(WeatherSeverity.minor != WeatherSeverity.unknown)
    weatherKitRoundTrip(WeatherSeverity.moderate)
    var hasher = Hasher()
    WeatherSeverity.severe.hash(into: &hasher)
    _ = hasher.finalize()
    _ = WeatherSeverity.severe.hashValue
}

func testMoonPhaseRawValuesSymbolsAndDescriptions() {
    precondition(
        MoonPhase.allCases == [
            .new, .waxingCrescent, .firstQuarter, .waxingGibbous, .full,
            .waningGibbous, .lastQuarter, .waningCrescent
        ]
    )
    precondition(MoonPhase.new.rawValue == "new")
    precondition(MoonPhase.new.description == "New")
    precondition(MoonPhase.new.symbolName == "moonphase.new.moon")
    precondition(MoonPhase.full.symbolName == "moonphase.full.moon")
    precondition(MoonPhase.waxingCrescent.symbolName == "moonphase.waxing.crescent")
    precondition(MoonPhase.firstQuarter.symbolName == "moonphase.first.quarter")
    precondition(MoonPhase.waxingGibbous.symbolName == "moonphase.waxing.gibbous")
    precondition(MoonPhase.waningGibbous.symbolName == "moonphase.waning.gibbous")
    precondition(MoonPhase.lastQuarter.symbolName == "moonphase.last.quarter")
    precondition(MoonPhase.waningCrescent.symbolName == "moonphase.waning.crescent")
    precondition(MoonPhase.full.accessibilityDescription == "Full")
    precondition(MoonPhase(rawValue: "full") == .full)
    precondition(MoonPhase.new != MoonPhase.full)
    weatherKitRoundTrip(MoonPhase.waxingGibbous)
    var hasher = Hasher()
    MoonPhase.full.hash(into: &hasher)
    _ = hasher.finalize()
    _ = MoonPhase.full.hashValue
}

func testDeviationCases() {
    let cases: [Deviation] = [.muchHigher, .higher, .normal, .lower, .muchLower]
    for value in cases {
        precondition(value == value)
        weatherKitRoundTrip(value)
    }
    precondition(Deviation.higher != Deviation.lower)
    var hasher = Hasher()
    Deviation.normal.hash(into: &hasher)
    _ = hasher.finalize()
    _ = Deviation.normal.hashValue
}

func testWeatherChangeDirectionCases() {
    let cases: [WeatherChange.Direction] = [.increase, .decrease, .steady]
    for value in cases {
        precondition(value == value)
        weatherKitRoundTrip(value)
    }
    precondition(WeatherChange.Direction.increase != .decrease)
    var hasher = Hasher()
    WeatherChange.Direction.steady.hash(into: &hasher)
    _ = hasher.finalize()
    _ = WeatherChange.Direction.steady.hashValue
}

func testTrendBaselineKindMean() {
    precondition(TrendBaseline<UnitTemperature>.Kind.mean == .mean)
    weatherKitRoundTrip(TrendBaseline<UnitTemperature>.Kind.mean)
    var hasher = Hasher()
    TrendBaseline<UnitTemperature>.Kind.mean.hash(into: &hasher)
    _ = hasher.finalize()
    _ = TrendBaseline<UnitTemperature>.Kind.mean.hashValue
}

func testWeatherAvailabilityKindRawValues() {
    let kinds: [WeatherAvailability.AvailabilityKind] = [
        .available, .temporarilyUnavailable, .unsupported, .unknown
    ]
    for kind in kinds {
        precondition(WeatherAvailability.AvailabilityKind(rawValue: kind.rawValue) == kind)
        weatherKitRoundTrip(kind)
    }
    precondition(WeatherAvailability.AvailabilityKind.available.rawValue == "available")
    precondition(WeatherAvailability.AvailabilityKind.available != .unsupported)
    var hasher = Hasher()
    WeatherAvailability.AvailabilityKind.available.hash(into: &hasher)
    _ = hasher.finalize()
    _ = WeatherAvailability.AvailabilityKind.available.hashValue
}

func testHistoricalComparisonCases() {
    let baseline = TrendBaseline(
        kind: .mean,
        value: weatherKitTemperature(15),
        startDate: weatherKitDate(-86_400 * 30)
    )
    let trend = Trend(
        currentValue: weatherKitTemperature(18),
        baseline: baseline,
        deviation: .higher
    )
    let lengthTrend = Trend(
        currentValue: Measurement(value: 4, unit: UnitLength.millimeters),
        baseline: TrendBaseline(
            kind: .mean,
            value: Measurement(value: 3, unit: UnitLength.millimeters),
            startDate: weatherKitDate(-86_400 * 30)
        ),
        deviation: .normal
    )
    let high = HistoricalComparison.highTemperature(trend)
    let low = HistoricalComparison.lowTemperature(trend)
    let precip = HistoricalComparison.precipitationAmount(lengthTrend)
    let snow = HistoricalComparison.snowfallAmount(lengthTrend)
    precondition(high != low)
    precondition(precip != snow)
    weatherKitRoundTrip(high)
    weatherKitRoundTrip(low)
    weatherKitRoundTrip(precip)
    weatherKitRoundTrip(snow)
}
