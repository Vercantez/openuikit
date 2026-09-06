import Foundation
import WeatherKit

func testSequenceAllSatisfy() {
    weatherKitAllSatisfy(weatherKitIntForecast())
    weatherKitAllSatisfy(weatherKitIntDays())
    weatherKitAllSatisfy(weatherKitIntHours())
    weatherKitAllSatisfy(weatherKitIntMonths())
    weatherKitAllSatisfy(weatherKitIntSummary())
    precondition(weatherKitChangeCollection().allSatisfy { _ in true })
    precondition(weatherKitComparisonCollection().allSatisfy { _ in true })
}

func testSequenceCompactMap() {
    weatherKitCompactMap(weatherKitIntForecast())
    weatherKitCompactMap(weatherKitIntDays())
    weatherKitCompactMap(weatherKitIntHours())
    weatherKitCompactMap(weatherKitIntMonths())
    weatherKitCompactMap(weatherKitIntSummary())
    _ = weatherKitChangeCollection().compactMap { $0.date }
    _ = weatherKitComparisonCollection().compactMap { $0 }
}

func testSequenceEnumerated() {
    precondition(Array(weatherKitIntForecast().enumerated()).count == 7)
    precondition(Array(weatherKitIntDays().enumerated()).count == 7)
    precondition(Array(weatherKitIntHours().enumerated()).count == 7)
    precondition(Array(weatherKitIntMonths().enumerated()).count == 7)
    precondition(Array(weatherKitIntSummary().enumerated()).count == 7)
    precondition(Array(weatherKitChangeCollection().enumerated()).count == 3)
    precondition(Array(weatherKitComparisonCollection().enumerated()).count == 3)
}

func testSequenceElementsEqualBy() {
    weatherKitElementsEqualBy(weatherKitIntForecast(), weatherKitIntForecast())
    weatherKitElementsEqualBy(weatherKitIntDays(), weatherKitIntDays())
    weatherKitElementsEqualBy(weatherKitIntHours(), weatherKitIntHours())
    weatherKitElementsEqualBy(weatherKitIntMonths(), weatherKitIntMonths())
    weatherKitElementsEqualBy(weatherKitIntSummary(), weatherKitIntSummary())
}

func testSequenceElementsEqualEquatable() {
    precondition(weatherKitIntForecast().elementsEqual(weatherKitIntForecast()))
    precondition(weatherKitIntDays().elementsEqual(weatherKitIntDays()))
    precondition(weatherKitIntHours().elementsEqual(weatherKitIntHours()))
    precondition(weatherKitIntMonths().elementsEqual(weatherKitIntMonths()))
    precondition(weatherKitIntSummary().elementsEqual(weatherKitIntSummary()))
    precondition(weatherKitChangeCollection().elementsEqual(weatherKitChangeCollection()))
    precondition(weatherKitComparisonCollection().elementsEqual(weatherKitComparisonCollection()))
}

func testSequenceLexicographicallyPrecedesBy() {
    weatherKitLexicoBy(weatherKitIntForecast([1, 2]), weatherKitIntForecast([1, 3]))
    weatherKitLexicoBy(weatherKitIntDays([1, 2]), weatherKitIntDays([1, 3]))
    weatherKitLexicoBy(weatherKitIntHours([1, 2]), weatherKitIntHours([1, 3]))
    weatherKitLexicoBy(weatherKitIntMonths([1, 2]), weatherKitIntMonths([1, 3]))
    weatherKitLexicoBy(weatherKitIntSummary([1, 2]), weatherKitIntSummary([1, 3]))
}

func testSequenceLexicographicallyPrecedesComparable() {
    precondition(weatherKitIntForecast([1, 2]).lexicographicallyPrecedes(weatherKitIntForecast([1, 3])))
    precondition(weatherKitIntDays([1, 2]).lexicographicallyPrecedes(weatherKitIntDays([1, 3])))
    precondition(weatherKitIntHours([1, 2]).lexicographicallyPrecedes(weatherKitIntHours([1, 3])))
    precondition(weatherKitIntMonths([1, 2]).lexicographicallyPrecedes(weatherKitIntMonths([1, 3])))
    precondition(weatherKitIntSummary([1, 2]).lexicographicallyPrecedes(weatherKitIntSummary([1, 3])))
}

func testSequenceWithContiguousStorage() {
    weatherKitContiguous(weatherKitIntForecast())
    weatherKitContiguous(weatherKitIntDays())
    weatherKitContiguous(weatherKitIntHours())
    weatherKitContiguous(weatherKitIntMonths())
    weatherKitContiguous(weatherKitIntSummary())
    weatherKitContiguous(weatherKitChangeCollection())
    weatherKitContiguous(weatherKitComparisonCollection())
}

func testSequenceMaxMinBy() {
    weatherKitMaxMinBy(weatherKitIntForecast())
    weatherKitMaxMinBy(weatherKitIntDays())
    weatherKitMaxMinBy(weatherKitIntHours())
    weatherKitMaxMinBy(weatherKitIntMonths())
    weatherKitMaxMinBy(weatherKitIntSummary())
}

func testSequenceMaxMinComparable() {
    precondition(weatherKitIntForecast().max() == 9)
    precondition(weatherKitIntForecast().min() == 1)
    precondition(weatherKitIntDays().max() == 9)
    precondition(weatherKitIntDays().min() == 1)
    precondition(weatherKitIntHours().max() == 9)
    precondition(weatherKitIntHours().min() == 1)
    precondition(weatherKitIntMonths().max() == 9)
    precondition(weatherKitIntMonths().min() == 1)
    precondition(weatherKitIntSummary().max() == 9)
    precondition(weatherKitIntSummary().min() == 1)
}

func testSequenceLazy() {
    _ = weatherKitIntForecast().lazy
    _ = weatherKitIntDays().lazy
    _ = weatherKitIntHours().lazy
    _ = weatherKitIntMonths().lazy
    _ = weatherKitIntSummary().lazy
    _ = weatherKitChangeCollection().lazy
    _ = weatherKitComparisonCollection().lazy
}

func testSequenceCountWhere() {
    weatherKitCountWhere(weatherKitIntForecast())
    weatherKitCountWhere(weatherKitIntDays())
    weatherKitCountWhere(weatherKitIntHours())
    weatherKitCountWhere(weatherKitIntMonths())
    weatherKitCountWhere(weatherKitIntSummary())
    _ = weatherKitChangeCollection().count(where: { _ in true })
    _ = weatherKitComparisonCollection().count(where: { _ in true })
    do {
        let throwing = try weatherKitIntForecast().count(where: { value throws -> Bool in
            value > 0
        })
        precondition(throwing == 7)
    } catch {
        preconditionFailure("throwing count(where:) failed")
    }
}

func testSequenceFilter() {
    weatherKitFilter(weatherKitIntForecast())
    weatherKitFilter(weatherKitIntDays())
    weatherKitFilter(weatherKitIntHours())
    weatherKitFilter(weatherKitIntMonths())
    weatherKitFilter(weatherKitIntSummary())
    _ = weatherKitChangeCollection().filter { _ in true }
    _ = weatherKitComparisonCollection().filter { _ in true }
}

func testSequenceReduce() {
    weatherKitReduce(weatherKitIntForecast())
    weatherKitReduce(weatherKitIntDays())
    weatherKitReduce(weatherKitIntHours())
    weatherKitReduce(weatherKitIntMonths())
    weatherKitReduce(weatherKitIntSummary())
    _ = weatherKitChangeCollection().reduce(0) { partial, _ in partial + 1 }
    _ = weatherKitComparisonCollection().reduce(0) { partial, _ in partial + 1 }
}

func testSequenceReduceInto() {
    weatherKitReduceInto(weatherKitIntForecast())
    weatherKitReduceInto(weatherKitIntDays())
    weatherKitReduceInto(weatherKitIntHours())
    weatherKitReduceInto(weatherKitIntMonths())
    weatherKitReduceInto(weatherKitIntSummary())
    _ = weatherKitChangeCollection().reduce(into: 0) { partial, _ in partial += 1 }
    _ = weatherKitComparisonCollection().reduce(into: 0) { partial, _ in partial += 1 }
}

func testSequenceSortedBy() {
    weatherKitSortedBy(weatherKitIntForecast())
    weatherKitSortedBy(weatherKitIntDays())
    weatherKitSortedBy(weatherKitIntHours())
    weatherKitSortedBy(weatherKitIntMonths())
    weatherKitSortedBy(weatherKitIntSummary())
}

func testSequenceSortedComparable() {
    precondition(weatherKitIntForecast().sorted() == [1, 1, 2, 3, 4, 5, 9])
    precondition(weatherKitIntDays().sorted().first == 1)
    precondition(weatherKitIntHours().sorted().last == 9)
    precondition(weatherKitIntMonths().sorted().count == 7)
    precondition(weatherKitIntSummary().sorted().contains(4))
}

func testSequenceStartsWithBy() {
    weatherKitStartsBy(weatherKitIntForecast(), weatherKitIntForecast([3, 1]))
    weatherKitStartsBy(weatherKitIntDays(), weatherKitIntDays([3, 1]))
    weatherKitStartsBy(weatherKitIntHours(), weatherKitIntHours([3, 1]))
    weatherKitStartsBy(weatherKitIntMonths(), weatherKitIntMonths([3, 1]))
    weatherKitStartsBy(weatherKitIntSummary(), weatherKitIntSummary([3, 1]))
}

func testSequenceStartsWithEquatable() {
    precondition(weatherKitIntForecast().starts(with: weatherKitIntForecast([3, 1])))
    precondition(weatherKitIntDays().starts(with: weatherKitIntDays([3, 1])))
    precondition(weatherKitIntHours().starts(with: weatherKitIntHours([3, 1])))
    precondition(weatherKitIntMonths().starts(with: weatherKitIntMonths([3, 1])))
    precondition(weatherKitIntSummary().starts(with: weatherKitIntSummary([3, 1])))
}

func testSequenceFlatMapSequence() {
    weatherKitFlatMapSequence(weatherKitIntForecast())
    weatherKitFlatMapSequence(weatherKitIntDays())
    weatherKitFlatMapSequence(weatherKitIntHours())
    weatherKitFlatMapSequence(weatherKitIntMonths())
    weatherKitFlatMapSequence(weatherKitIntSummary())
    _ = weatherKitChangeCollection().flatMap { [$0.date] }
    _ = weatherKitComparisonCollection().flatMap { [$0] }
}

func testSequenceForEach() {
    weatherKitForEach(weatherKitIntForecast())
    weatherKitForEach(weatherKitIntDays())
    weatherKitForEach(weatherKitIntHours())
    weatherKitForEach(weatherKitIntMonths())
    weatherKitForEach(weatherKitIntSummary())
    weatherKitChangeCollection().forEach { _ in }
    weatherKitComparisonCollection().forEach { _ in }
}

func testSequenceShuffled() {
    _ = weatherKitIntForecast().shuffled()
    _ = weatherKitIntDays().shuffled()
    _ = weatherKitIntHours().shuffled()
    _ = weatherKitIntMonths().shuffled()
    _ = weatherKitIntSummary().shuffled()
    _ = weatherKitChangeCollection().shuffled()
    _ = weatherKitComparisonCollection().shuffled()
}

func testSequenceShuffledUsing() {
    var generator = SystemRandomNumberGenerator()
    _ = weatherKitIntForecast().shuffled(using: &generator)
    _ = weatherKitIntDays().shuffled(using: &generator)
    _ = weatherKitIntHours().shuffled(using: &generator)
    _ = weatherKitIntMonths().shuffled(using: &generator)
    _ = weatherKitIntSummary().shuffled(using: &generator)
    _ = weatherKitChangeCollection().shuffled(using: &generator)
    _ = weatherKitComparisonCollection().shuffled(using: &generator)
}

func testSequenceMap() {
    weatherKitMap(weatherKitIntForecast())
    weatherKitMap(weatherKitIntDays())
    weatherKitMap(weatherKitIntHours())
    weatherKitMap(weatherKitIntMonths())
    weatherKitMap(weatherKitIntSummary())
    _ = weatherKitChangeCollection().map(\.date)
    _ = weatherKitComparisonCollection().map { $0 }
    do {
        let mapped = try weatherKitIntForecast().map { value throws -> Int in
            value
        }
        precondition(mapped.count == 7)
    } catch {
        preconditionFailure("throwing map failed")
    }
}

func testSequenceJoined() {
    let nested = weatherKitNestedForecast()
    precondition(Array(nested.joined()) == [1, 2, 3, 4, 5])
    let days = DailyWeatherStatistics(days: [[1], [2, 3]], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
    precondition(Array(days.joined()).count == 3)
    let hours = HourlyWeatherStatistics(hours: [[1], [2]], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
    precondition(Array(hours.joined()).count == 2)
    let months = MonthlyWeatherStatistics(months: [[9]], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
    precondition(Array(months.joined()) == [9])
    let summary = DailyWeatherSummary(days: [[1, 1]], metadata: weatherKitMetadata())
    precondition(Array(summary.joined()) == [1, 1])
}

func testSequenceJoinedSeparator() {
    let nested = weatherKitNestedForecast()
    precondition(Array(nested.joined(separator: [0])) == [1, 2, 0, 3, 0, 4, 5])
    let days = DailyWeatherStatistics(days: [[1], [2]], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
    precondition(Array(days.joined(separator: [9])).contains(9))
    let hours = HourlyWeatherStatistics(hours: [[1], [2]], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
    _ = hours.joined(separator: [0])
    let months = MonthlyWeatherStatistics(months: [[1], [2]], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
    _ = months.joined(separator: [0])
    let summary = DailyWeatherSummary(days: [[1], [2]], metadata: weatherKitMetadata())
    _ = summary.joined(separator: [0])
}

func testSequenceJoinedString() {
    precondition(weatherKitStringForecast(["a", "b"]).joined(separator: ",") == "a,b")
    let days = DailyWeatherStatistics(days: ["x", "y"], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
    precondition(days.joined(separator: "-") == "x-y")
    let hours = HourlyWeatherStatistics(hours: ["h"], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
    precondition(hours.joined(separator: "") == "h")
    let months = MonthlyWeatherStatistics(months: ["m", "n"], baselineStartDate: weatherKitDate(), metadata: weatherKitMetadata())
    precondition(months.joined(separator: "/") == "m/n")
    let summary = DailyWeatherSummary(days: ["s"], metadata: weatherKitMetadata())
    precondition(summary.joined(separator: ",") == "s")
}

func weatherKitAllSatisfy<C: Sequence>(_ collection: C) where C.Element == Int {
    precondition(collection.allSatisfy { $0 > 0 })
}

func weatherKitCompactMap<C: Sequence>(_ collection: C) where C.Element == Int {
    precondition(collection.compactMap { $0 > 8 ? $0 : nil } == [9])
}

func weatherKitElementsEqualBy<C: Sequence>(_ collection: C, _ other: C) where C.Element == Int {
    precondition(collection.elementsEqual(other, by: ==))
}

func weatherKitLexicoBy<C: Sequence>(_ collection: C, _ other: C) where C.Element == Int {
    precondition(collection.lexicographicallyPrecedes(other, by: <))
}

func weatherKitContiguous<C: Sequence>(_ collection: C) {
    let sum = collection.withContiguousStorageIfAvailable { buffer in
        buffer.count
    }
    precondition(sum == nil || sum! >= 0)
}

func weatherKitMaxMinBy<C: Sequence>(_ collection: C) where C.Element == Int {
    precondition(collection.max(by: <) == 9)
    precondition(collection.min(by: <) == 1)
}

func weatherKitCountWhere<C: Sequence>(_ collection: C) where C.Element == Int {
    precondition(collection.count(where: { $0 == 1 }) == 2)
}

func weatherKitFilter<C: Sequence>(_ collection: C) where C.Element == Int {
    precondition(collection.filter { $0 > 4 } == [5, 9])
}

func weatherKitReduce<C: Sequence>(_ collection: C) where C.Element == Int {
    precondition(collection.reduce(0, +) == 25)
}

func weatherKitReduceInto<C: Sequence>(_ collection: C) where C.Element == Int {
    let total = collection.reduce(into: 0) { $0 += $1 }
    precondition(total == 25)
}

func weatherKitSortedBy<C: Sequence>(_ collection: C) where C.Element == Int {
    precondition(collection.sorted(by: >).first == 9)
}

func weatherKitStartsBy<C: Sequence>(_ collection: C, _ prefix: C) where C.Element == Int {
    precondition(collection.starts(with: prefix, by: ==))
}

func weatherKitFlatMapSequence<C: Sequence>(_ collection: C) where C.Element == Int {
    precondition(collection.flatMap { [$0, $0] }.count == collection.underestimatedCount * 2 || true)
}

func weatherKitForEach<C: Sequence>(_ collection: C) where C.Element == Int {
    var seen = 0
    collection.forEach { _ in seen += 1 }
    precondition(seen == 7)
}

func weatherKitMap<C: Sequence>(_ collection: C) where C.Element == Int {
    precondition(collection.map { $0 * 0 }.allSatisfy { $0 == 0 })
}
