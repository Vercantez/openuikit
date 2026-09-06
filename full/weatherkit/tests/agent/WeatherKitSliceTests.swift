import Foundation
import WeatherKit

func testCollectionSuffixCount() {
    weatherKitSuffix(weatherKitIntForecast())
    weatherKitSuffix(weatherKitIntDays())
    weatherKitSuffix(weatherKitIntHours())
    weatherKitSuffix(weatherKitIntMonths())
    weatherKitSuffix(weatherKitIntSummary())
    weatherKitSuffix(weatherKitChangeCollection())
    weatherKitSuffix(weatherKitComparisonCollection())
}

func testCollectionDropLast() {
    weatherKitDropLast(weatherKitIntForecast())
    weatherKitDropLast(weatherKitIntDays())
    weatherKitDropLast(weatherKitIntHours())
    weatherKitDropLast(weatherKitIntMonths())
    weatherKitDropLast(weatherKitIntSummary())
    weatherKitDropLast(weatherKitChangeCollection())
    weatherKitDropLast(weatherKitComparisonCollection())
}

func testCollectionDropFirst() {
    weatherKitDropFirst(weatherKitIntForecast())
    weatherKitDropFirst(weatherKitIntDays())
    weatherKitDropFirst(weatherKitIntHours())
    weatherKitDropFirst(weatherKitIntMonths())
    weatherKitDropFirst(weatherKitIntSummary())
    weatherKitDropFirst(weatherKitChangeCollection())
    weatherKitDropFirst(weatherKitComparisonCollection())
}

func testCollectionPrefixCount() {
    weatherKitPrefixCount(weatherKitIntForecast())
    weatherKitPrefixCount(weatherKitIntDays())
    weatherKitPrefixCount(weatherKitIntHours())
    weatherKitPrefixCount(weatherKitIntMonths())
    weatherKitPrefixCount(weatherKitIntSummary())
    weatherKitPrefixCount(weatherKitChangeCollection())
    weatherKitPrefixCount(weatherKitComparisonCollection())
}

func testCollectionPrefixWhile() {
    weatherKitPrefixWhile(weatherKitIntForecast())
    weatherKitPrefixWhile(weatherKitIntDays())
    weatherKitPrefixWhile(weatherKitIntHours())
    weatherKitPrefixWhile(weatherKitIntMonths())
    weatherKitPrefixWhile(weatherKitIntSummary())
    _ = weatherKitChangeCollection().prefix(while: { _ in true })
    _ = weatherKitComparisonCollection().prefix(while: { _ in true })
}

func testCollectionPrefixUpTo() {
    weatherKitPrefixUpTo(weatherKitIntForecast())
    weatherKitPrefixUpTo(weatherKitIntDays())
    weatherKitPrefixUpTo(weatherKitIntHours())
    weatherKitPrefixUpTo(weatherKitIntMonths())
    weatherKitPrefixUpTo(weatherKitIntSummary())
    weatherKitPrefixUpTo(weatherKitChangeCollection())
    weatherKitPrefixUpTo(weatherKitComparisonCollection())
}

func testCollectionPrefixThrough() {
    weatherKitPrefixThrough(weatherKitIntForecast())
    weatherKitPrefixThrough(weatherKitIntDays())
    weatherKitPrefixThrough(weatherKitIntHours())
    weatherKitPrefixThrough(weatherKitIntMonths())
    weatherKitPrefixThrough(weatherKitIntSummary())
    weatherKitPrefixThrough(weatherKitChangeCollection())
    weatherKitPrefixThrough(weatherKitComparisonCollection())
}

func testCollectionSuffixFrom() {
    weatherKitSuffixFrom(weatherKitIntForecast())
    weatherKitSuffixFrom(weatherKitIntDays())
    weatherKitSuffixFrom(weatherKitIntHours())
    weatherKitSuffixFrom(weatherKitIntMonths())
    weatherKitSuffixFrom(weatherKitIntSummary())
    weatherKitSuffixFrom(weatherKitChangeCollection())
    weatherKitSuffixFrom(weatherKitComparisonCollection())
}

func testCollectionDropWhile() {
    weatherKitDropWhile(weatherKitIntForecast())
    weatherKitDropWhile(weatherKitIntDays())
    weatherKitDropWhile(weatherKitIntHours())
    weatherKitDropWhile(weatherKitIntMonths())
    weatherKitDropWhile(weatherKitIntSummary())
    _ = weatherKitChangeCollection().drop(while: { _ in false })
    _ = weatherKitComparisonCollection().drop(while: { _ in false })
}

func testCollectionReversed() {
    weatherKitReversed(weatherKitIntForecast())
    weatherKitReversed(weatherKitIntDays())
    weatherKitReversed(weatherKitIntHours())
    weatherKitReversed(weatherKitIntMonths())
    weatherKitReversed(weatherKitIntSummary())
    weatherKitReversed(weatherKitChangeCollection())
    weatherKitReversed(weatherKitComparisonCollection())
}

func testCollectionLastProperty() {
    precondition(weatherKitIntForecast().last == 2)
    precondition(weatherKitIntDays().last == 2)
    precondition(weatherKitIntHours().last == 2)
    precondition(weatherKitIntMonths().last == 2)
    precondition(weatherKitIntSummary().last == 2)
    precondition(weatherKitChangeCollection().last != nil)
    precondition(weatherKitComparisonCollection().last != nil)
}

func testCollectionFirstProperty() {
    precondition(weatherKitIntForecast().first == 3)
    precondition(weatherKitIntDays().first == 3)
    precondition(weatherKitIntHours().first == 3)
    precondition(weatherKitIntMonths().first == 3)
    precondition(weatherKitIntSummary().first == 3)
    precondition(weatherKitChangeCollection().first != nil)
    precondition(weatherKitComparisonCollection().first != nil)
}

func testCollectionIsEmptyAndCount() {
    precondition(!weatherKitIntForecast().isEmpty)
    precondition(weatherKitIntForecast().count == 7)
    precondition(!weatherKitIntDays().isEmpty)
    precondition(weatherKitIntDays().count == 7)
    precondition(!weatherKitIntHours().isEmpty)
    precondition(weatherKitIntHours().count == 7)
    precondition(!weatherKitIntMonths().isEmpty)
    precondition(weatherKitIntMonths().count == 7)
    precondition(!weatherKitIntSummary().isEmpty)
    precondition(weatherKitIntSummary().count == 7)
    precondition(!weatherKitChangeCollection().isEmpty)
    precondition(weatherKitChangeCollection().count == 3)
    precondition(!weatherKitComparisonCollection().isEmpty)
    precondition(weatherKitComparisonCollection().count == 3)
}

func testCollectionUnderestimatedCount() {
    precondition(weatherKitIntForecast().underestimatedCount >= 0)
    precondition(weatherKitIntDays().underestimatedCount >= 0)
    precondition(weatherKitIntHours().underestimatedCount >= 0)
    precondition(weatherKitIntMonths().underestimatedCount >= 0)
    precondition(weatherKitIntSummary().underestimatedCount >= 0)
    precondition(weatherKitChangeCollection().underestimatedCount >= 0)
    precondition(weatherKitComparisonCollection().underestimatedCount >= 0)
}

func weatherKitSuffix<C: BidirectionalCollection>(_ collection: C) {
    let slice = collection.suffix(2)
    precondition(slice.count == 2)
}

func weatherKitDropLast<C: BidirectionalCollection>(_ collection: C) {
    let slice = collection.dropLast(1)
    precondition(slice.count == collection.count - 1)
}

func weatherKitDropFirst<C: Collection>(_ collection: C) {
    let slice = collection.dropFirst(1)
    precondition(slice.count == collection.count - 1)
}

func weatherKitPrefixCount<C: Collection>(_ collection: C) {
    let slice = collection.prefix(2)
    precondition(slice.count == 2)
}

func weatherKitPrefixWhile<C: Collection>(_ collection: C) where C.Element == Int {
    let slice = collection.prefix(while: { $0 >= 3 })
    precondition(Array(slice).first == 3)
}

func weatherKitPrefixUpTo<C: Collection>(_ collection: C) {
    let slice = collection.prefix(upTo: collection.endIndex)
    precondition(slice.count == collection.count)
}

func weatherKitPrefixThrough<C: BidirectionalCollection>(_ collection: C) {
    let last = collection.index(before: collection.endIndex)
    let slice = collection.prefix(through: last)
    precondition(slice.count == collection.count)
}

func weatherKitSuffixFrom<C: Collection>(_ collection: C) {
    let slice = collection.suffix(from: collection.startIndex)
    precondition(slice.count == collection.count)
}

func weatherKitDropWhile<C: Collection>(_ collection: C) where C.Element == Int {
    let slice = collection.drop(while: { $0 > 10 })
    precondition(slice.count == collection.count)
}

func weatherKitReversed<C: BidirectionalCollection>(_ collection: C) {
    let reversed = collection.reversed()
    precondition(reversed.count == collection.count)
}
