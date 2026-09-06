import Foundation
import WeatherKit

func testCollectionDifferenceBy() {
    weatherKitDifferenceBy(weatherKitIntForecast(), weatherKitIntForecast([3, 1, 4]))
    weatherKitDifferenceBy(weatherKitIntDays(), weatherKitIntDays([3, 1, 4]))
    weatherKitDifferenceBy(weatherKitIntHours(), weatherKitIntHours([3, 1, 4]))
    weatherKitDifferenceBy(weatherKitIntMonths(), weatherKitIntMonths([3, 1, 4]))
    weatherKitDifferenceBy(weatherKitIntSummary(), weatherKitIntSummary([3, 1, 4]))
}

func testCollectionDifferenceEquatable() {
    weatherKitDifference(weatherKitIntForecast(), weatherKitIntForecast([3, 1, 4]))
    weatherKitDifference(weatherKitIntDays(), weatherKitIntDays([3, 1, 4]))
    weatherKitDifference(weatherKitIntHours(), weatherKitIntHours([3, 1, 4]))
    weatherKitDifference(weatherKitIntMonths(), weatherKitIntMonths([3, 1, 4]))
    weatherKitDifference(weatherKitIntSummary(), weatherKitIntSummary([3, 1, 4]))
    _ = weatherKitChangeCollection().difference(from: WeatherChanges(changes: [], metadata: weatherKitMetadata()))
    _ = weatherKitComparisonCollection().difference(
        from: HistoricalComparisons(comparisons: [], metadata: weatherKitMetadata())
    )
}

func testCollectionSplitWhere() {
    weatherKitSplitWhere(weatherKitIntForecast())
    weatherKitSplitWhere(weatherKitIntDays())
    weatherKitSplitWhere(weatherKitIntHours())
    weatherKitSplitWhere(weatherKitIntMonths())
    weatherKitSplitWhere(weatherKitIntSummary())
}

func testCollectionSplitSeparator() {
    weatherKitSplitSeparator(weatherKitIntForecast(), 1)
    weatherKitSplitSeparator(weatherKitIntDays(), 1)
    weatherKitSplitSeparator(weatherKitIntHours(), 1)
    weatherKitSplitSeparator(weatherKitIntMonths(), 1)
    weatherKitSplitSeparator(weatherKitIntSummary(), 1)
}

func testCollectionIndicesWhere() {
    weatherKitIndicesWhere(weatherKitIntForecast())
    weatherKitIndicesWhere(weatherKitIntDays())
    weatherKitIndicesWhere(weatherKitIntHours())
    weatherKitIndicesWhere(weatherKitIntMonths())
    weatherKitIndicesWhere(weatherKitIntSummary())
    _ = weatherKitChangeCollection().indices(where: { _ in true })
    _ = weatherKitComparisonCollection().indices(where: { _ in true })
}

func testCollectionIndicesOf() {
    weatherKitIndicesOf(weatherKitIntForecast(), 1)
    weatherKitIndicesOf(weatherKitIntDays(), 1)
    weatherKitIndicesOf(weatherKitIntHours(), 1)
    weatherKitIndicesOf(weatherKitIntMonths(), 1)
    weatherKitIndicesOf(weatherKitIntSummary(), 1)
}

func testCollectionRemovingSubranges() {
    weatherKitRemoving(weatherKitIntForecast())
    weatherKitRemoving(weatherKitIntDays())
    weatherKitRemoving(weatherKitIntHours())
    weatherKitRemoving(weatherKitIntMonths())
    weatherKitRemoving(weatherKitIntSummary())
    _ = weatherKitChangeCollection().removingSubranges(weatherKitChangeCollection().indices(where: { _ in false }))
    _ = weatherKitComparisonCollection().removingSubranges(
        weatherKitComparisonCollection().indices(where: { _ in false })
    )
}

func weatherKitDifferenceBy<C: BidirectionalCollection>(_ collection: C, _ other: C)
where C.Element == Int {
    let diff = collection.difference(from: other, by: { $0 == $1 })
    precondition(!diff.insertions.isEmpty || !diff.removals.isEmpty || collection.elementsEqual(other))
}

func weatherKitDifference<C: BidirectionalCollection>(_ collection: C, _ other: C)
where C.Element: Equatable {
    _ = collection.difference(from: other)
}

func weatherKitSplitWhere<C: Collection>(_ collection: C) where C.Element == Int {
    let parts = collection.split(maxSplits: 2, omittingEmptySubsequences: true, whereSeparator: { $0 == 1 })
    precondition(!parts.isEmpty)
}

func weatherKitSplitSeparator<C: Collection>(_ collection: C, _ separator: C.Element)
where C.Element: Equatable {
    let parts = collection.split(separator: separator, maxSplits: 2, omittingEmptySubsequences: true)
    precondition(!parts.isEmpty)
}

func weatherKitIndicesWhere<C: Collection>(_ collection: C) where C.Element == Int {
    let set = collection.indices(where: { $0 == 1 })
    precondition(!set.isEmpty)
}

func weatherKitIndicesOf<C: Collection>(_ collection: C, _ value: C.Element)
where C.Element: Equatable {
    let set = collection.indices(of: value)
    precondition(!set.isEmpty)
}

func weatherKitRemoving<C: Collection>(_ collection: C) where C.Element == Int {
    let kept = collection.removingSubranges(collection.indices(where: { $0 == 1 }))
    precondition(Array(kept).allSatisfy { $0 != 1 })
}
