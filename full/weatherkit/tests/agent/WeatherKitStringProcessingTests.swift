import Foundation
import WeatherKit

func testCollectionFirstRangeOf() {
    weatherKitFirstRange(weatherKitIntForecast(), [4, 1])
    weatherKitFirstRange(weatherKitIntDays(), [4, 1])
    weatherKitFirstRange(weatherKitIntHours(), [4, 1])
    weatherKitFirstRange(weatherKitIntMonths(), [4, 1])
    weatherKitFirstRange(weatherKitIntSummary(), [4, 1])
}

func testCollectionTrimmingPrefix() {
    weatherKitTrimPrefix(weatherKitIntForecast(), [3])
    weatherKitTrimPrefix(weatherKitIntDays(), [3])
    weatherKitTrimPrefix(weatherKitIntHours(), [3])
    weatherKitTrimPrefix(weatherKitIntMonths(), [3])
    weatherKitTrimPrefix(weatherKitIntSummary(), [3])
}

func testCollectionTrimmingPrefixWhile() {
    weatherKitTrimWhile(weatherKitIntForecast())
    weatherKitTrimWhile(weatherKitIntDays())
    weatherKitTrimWhile(weatherKitIntHours())
    weatherKitTrimWhile(weatherKitIntMonths())
    weatherKitTrimWhile(weatherKitIntSummary())
    _ = weatherKitChangeCollection().trimmingPrefix(while: { _ in false })
    _ = weatherKitComparisonCollection().trimmingPrefix(while: { _ in false })
}

func testCollectionRangesOf() {
    weatherKitRanges(weatherKitIntForecast(), [1])
    weatherKitRanges(weatherKitIntDays(), [1])
    weatherKitRanges(weatherKitIntHours(), [1])
    weatherKitRanges(weatherKitIntMonths(), [1])
    weatherKitRanges(weatherKitIntSummary(), [1])
}

func testBidirectionalFirstRangeOf() {
    weatherKitBidirectionalFirstRange(weatherKitIntForecast(), [5, 9])
    weatherKitBidirectionalFirstRange(weatherKitIntDays(), [5, 9])
    weatherKitBidirectionalFirstRange(weatherKitIntHours(), [5, 9])
    weatherKitBidirectionalFirstRange(weatherKitIntMonths(), [5, 9])
    weatherKitBidirectionalFirstRange(weatherKitIntSummary(), [5, 9])
}

func weatherKitFirstRange<C: Collection>(_ collection: C, _ pattern: [C.Element])
where C.Element: Equatable {
    precondition(collection.firstRange(of: pattern) != nil)
}

func weatherKitTrimPrefix<C: Collection>(_ collection: C, _ pattern: [C.Element])
where C.Element: Equatable {
    let trimmed = collection.trimmingPrefix(pattern)
    precondition(trimmed.count <= collection.count)
}

func weatherKitTrimWhile<C: Collection>(_ collection: C) where C.Element == Int {
    let trimmed = collection.trimmingPrefix(while: { $0 > 10 })
    precondition(trimmed.count == collection.count)
}

func weatherKitRanges<C: Collection>(_ collection: C, _ pattern: [C.Element])
where C.Element: Equatable {
    precondition(!collection.ranges(of: pattern).isEmpty)
}

func weatherKitBidirectionalFirstRange<C: BidirectionalCollection>(_ collection: C, _ pattern: [C.Element])
where C.Element: Comparable {
    precondition(collection.firstRange(of: pattern) != nil)
}
