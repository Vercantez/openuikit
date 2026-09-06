import Foundation
import WeatherKit

func testSequenceSortedUsingComparator() {
    weatherKitSortedUsing(weatherKitIntForecast())
    weatherKitSortedUsing(weatherKitIntDays())
    weatherKitSortedUsing(weatherKitIntHours())
    weatherKitSortedUsing(weatherKitIntMonths())
    weatherKitSortedUsing(weatherKitIntSummary())
}

func testSequenceSortedUsingComparators() {
    weatherKitSortedUsingMany(weatherKitIntForecast())
    weatherKitSortedUsingMany(weatherKitIntDays())
    weatherKitSortedUsingMany(weatherKitIntHours())
    weatherKitSortedUsingMany(weatherKitIntMonths())
    weatherKitSortedUsingMany(weatherKitIntSummary())
}

struct WeatherKitIntComparator: SortComparator, Codable, Sendable {
    typealias Compared = Int
    var order: SortOrder = .forward

    func compare(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        switch (lhs, rhs) {
        case _ where lhs < rhs: return .orderedAscending
        case _ where lhs > rhs: return .orderedDescending
        default: return .orderedSame
        }
    }
}

func testSequenceCompareUsingComparator() {
    let comparator = WeatherKitIntComparator()
    weatherKitCompare(Forecast(forecast: [comparator], metadata: weatherKitMetadata()))
    weatherKitCompare(DailyWeatherStatistics(days: [comparator], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata()))
    weatherKitCompare(HourlyWeatherStatistics(hours: [comparator], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata()))
    weatherKitCompare(MonthlyWeatherStatistics(months: [comparator], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata()))
    weatherKitCompare(DailyWeatherSummary(days: [comparator], metadata: weatherKitMetadata()))
}

func testSequenceFormattedStringElements() {
    let forecast = weatherKitStringForecast(["rain", "snow"])
    precondition(!forecast.formatted().isEmpty)
    let days = DailyWeatherStatistics(
        days: ["a", "b"],
        baselineStartDate: weatherKitDate(),
        metadata: weatherKitMetadata()
    )
    precondition(!days.formatted().isEmpty)
    let hours = HourlyWeatherStatistics(
        hours: ["h"],
        baselineStartDate: weatherKitDate(),
        metadata: weatherKitMetadata()
    )
    precondition(!hours.formatted().isEmpty)
    let months = MonthlyWeatherStatistics(
        months: ["m", "n"],
        baselineStartDate: weatherKitDate(),
        metadata: weatherKitMetadata()
    )
    precondition(!months.formatted().isEmpty)
    let summary = DailyWeatherSummary(days: ["s"], metadata: weatherKitMetadata())
    precondition(!summary.formatted().isEmpty)
}

func testSequenceFormattedStyle() {
    weatherKitFormattedStyle(weatherKitStringForecast())
    weatherKitFormattedStyle(DailyWeatherStatistics(days: ["rain", "snow"], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata()))
    weatherKitFormattedStyle(HourlyWeatherStatistics(hours: ["clear"], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata()))
    weatherKitFormattedStyle(MonthlyWeatherStatistics(months: ["hot", "cold"], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata()))
    weatherKitFormattedStyle(DailyWeatherSummary(days: ["fog"], metadata: weatherKitMetadata()))
}

func weatherKitSortedUsing<C: Sequence>(_ collection: C) where C.Element == Int {
    let sorted = collection.sorted(using: KeyPathComparator(\.self))
    precondition(sorted.first == 1)
}

func weatherKitSortedUsingMany<C: Sequence>(_ collection: C) where C.Element == Int {
    let sorted = collection.sorted(using: [KeyPathComparator(\.self)])
    precondition(sorted.last == 9)
}

func weatherKitCompare<C: Sequence>(_ collection: C) where C.Element == WeatherKitIntComparator {
    let result = collection.compare(1, 9)
    precondition(result == .orderedAscending || result == .orderedDescending || result == .orderedSame)
}

func weatherKitFormattedStyle<C: Sequence>(_ collection: C) where C.Element == String {
    let text = collection.formatted(.list(type: .and, width: .standard))
    precondition(!text.isEmpty)
}
