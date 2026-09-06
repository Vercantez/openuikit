import Foundation
import WeatherKit

func testCollectionFormIndexAfter() {
    weatherKitFormIndexAfter(weatherKitIntForecast())
    weatherKitFormIndexAfter(weatherKitIntDays())
    weatherKitFormIndexAfter(weatherKitIntHours())
    weatherKitFormIndexAfter(weatherKitIntMonths())
    weatherKitFormIndexAfter(weatherKitIntSummary())
    weatherKitFormIndexAfter(weatherKitChangeCollection())
    weatherKitFormIndexAfter(weatherKitComparisonCollection())
}

func testCollectionFormIndexBefore() {
    weatherKitFormIndexBefore(weatherKitIntForecast())
    weatherKitFormIndexBefore(weatherKitIntDays())
    weatherKitFormIndexBefore(weatherKitIntHours())
    weatherKitFormIndexBefore(weatherKitIntMonths())
    weatherKitFormIndexBefore(weatherKitIntSummary())
    weatherKitFormIndexBefore(weatherKitChangeCollection())
    weatherKitFormIndexBefore(weatherKitComparisonCollection())
}

func testCollectionFormIndexOffsetBy() {
    weatherKitFormIndexOffset(weatherKitIntForecast())
    weatherKitFormIndexOffset(weatherKitIntDays())
    weatherKitFormIndexOffset(weatherKitIntHours())
    weatherKitFormIndexOffset(weatherKitIntMonths())
    weatherKitFormIndexOffset(weatherKitIntSummary())
    weatherKitFormIndexOffset(weatherKitChangeCollection())
    weatherKitFormIndexOffset(weatherKitComparisonCollection())
}

func testCollectionFormIndexOffsetByLimitedBy() {
    weatherKitFormIndexLimited(weatherKitIntForecast())
    weatherKitFormIndexLimited(weatherKitIntDays())
    weatherKitFormIndexLimited(weatherKitIntHours())
    weatherKitFormIndexLimited(weatherKitIntMonths())
    weatherKitFormIndexLimited(weatherKitIntSummary())
    weatherKitFormIndexLimited(weatherKitChangeCollection())
    weatherKitFormIndexLimited(weatherKitComparisonCollection())
}

func testCollectionIndexOffsetByLimitedBy() {
    weatherKitIndexLimited(weatherKitIntForecast())
    weatherKitIndexLimited(weatherKitIntDays())
    weatherKitIndexLimited(weatherKitIntHours())
    weatherKitIndexLimited(weatherKitIntMonths())
    weatherKitIndexLimited(weatherKitIntSummary())
    weatherKitIndexLimited(weatherKitChangeCollection())
    weatherKitIndexLimited(weatherKitComparisonCollection())
}

func testCollectionMakeIterator() {
    weatherKitMakeIterator(weatherKitIntForecast())
    weatherKitMakeIterator(weatherKitIntDays())
    weatherKitMakeIterator(weatherKitIntHours())
    weatherKitMakeIterator(weatherKitIntMonths())
    weatherKitMakeIterator(weatherKitIntSummary())
    weatherKitMakeIterator(weatherKitChangeCollection())
    weatherKitMakeIterator(weatherKitComparisonCollection())
}

func weatherKitFormIndexAfter<C: RandomAccessCollection>(_ collection: C) {
    var index = collection.startIndex
    collection.formIndex(after: &index)
    precondition(index != collection.startIndex || collection.isEmpty)
}

func weatherKitFormIndexBefore<C: BidirectionalCollection>(_ collection: C) {
    var index = collection.endIndex
    collection.formIndex(before: &index)
    precondition(index != collection.endIndex)
}

func weatherKitFormIndexOffset<C: RandomAccessCollection>(_ collection: C) {
    var index = collection.startIndex
    collection.formIndex(&index, offsetBy: 2)
    precondition(collection.distance(from: collection.startIndex, to: index) == 2)
}

func weatherKitFormIndexLimited<C: RandomAccessCollection>(_ collection: C) {
    var index = collection.startIndex
    let moved = collection.formIndex(&index, offsetBy: 2, limitedBy: collection.endIndex)
    precondition(moved)
    var overflow = collection.startIndex
    let blocked = collection.formIndex(&overflow, offsetBy: 50, limitedBy: collection.endIndex)
    precondition(!blocked)
}

func weatherKitIndexLimited<C: RandomAccessCollection>(_ collection: C) {
    let reached = collection.index(collection.startIndex, offsetBy: 2, limitedBy: collection.endIndex)
    precondition(reached != nil)
    let missing = collection.index(collection.startIndex, offsetBy: 50, limitedBy: collection.endIndex)
    precondition(missing == nil)
}

func weatherKitMakeIterator<C: Collection>(_ collection: C) {
    var iterator = collection.makeIterator()
    precondition(iterator.next() != nil)
}
