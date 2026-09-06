import Foundation
import WeatherKit

func testCollectionLastWhere() {
    weatherKitLastWhere(weatherKitIntForecast())
    weatherKitLastWhere(weatherKitIntDays())
    weatherKitLastWhere(weatherKitIntHours())
    weatherKitLastWhere(weatherKitIntMonths())
    weatherKitLastWhere(weatherKitIntSummary())
    precondition(weatherKitChangeCollection().last(where: { _ in true }) != nil)
    precondition(weatherKitComparisonCollection().last(where: { _ in true }) != nil)
}

func testCollectionLastIndexWhere() {
    weatherKitLastIndexWhere(weatherKitIntForecast())
    weatherKitLastIndexWhere(weatherKitIntDays())
    weatherKitLastIndexWhere(weatherKitIntHours())
    weatherKitLastIndexWhere(weatherKitIntMonths())
    weatherKitLastIndexWhere(weatherKitIntSummary())
    weatherKitLastIndexWhereEquatable(weatherKitChangeCollection())
    weatherKitLastIndexWhereEquatable(weatherKitComparisonCollection())
}

func testCollectionLastIndexOf() {
    weatherKitLastIndexOf(weatherKitIntForecast(), 1)
    weatherKitLastIndexOf(weatherKitIntDays(), 1)
    weatherKitLastIndexOf(weatherKitIntHours(), 1)
    weatherKitLastIndexOf(weatherKitIntMonths(), 1)
    weatherKitLastIndexOf(weatherKitIntSummary(), 1)
}

func testCollectionFirstIndexWhere() {
    weatherKitFirstIndexWhere(weatherKitIntForecast())
    weatherKitFirstIndexWhere(weatherKitIntDays())
    weatherKitFirstIndexWhere(weatherKitIntHours())
    weatherKitFirstIndexWhere(weatherKitIntMonths())
    weatherKitFirstIndexWhere(weatherKitIntSummary())
    weatherKitFirstIndexWhereEquatable(weatherKitChangeCollection())
    weatherKitFirstIndexWhereEquatable(weatherKitComparisonCollection())
}

func testCollectionFirstIndexOf() {
    weatherKitFirstIndexOf(weatherKitIntForecast(), 4)
    weatherKitFirstIndexOf(weatherKitIntDays(), 4)
    weatherKitFirstIndexOf(weatherKitIntHours(), 4)
    weatherKitFirstIndexOf(weatherKitIntMonths(), 4)
    weatherKitFirstIndexOf(weatherKitIntSummary(), 4)
}

func testCollectionFirstWhere() {
    weatherKitFirstWhere(weatherKitIntForecast())
    weatherKitFirstWhere(weatherKitIntDays())
    weatherKitFirstWhere(weatherKitIntHours())
    weatherKitFirstWhere(weatherKitIntMonths())
    weatherKitFirstWhere(weatherKitIntSummary())
}

func testCollectionContainsWhere() {
    weatherKitContainsWhere(weatherKitIntForecast())
    weatherKitContainsWhere(weatherKitIntDays())
    weatherKitContainsWhere(weatherKitIntHours())
    weatherKitContainsWhere(weatherKitIntMonths())
    weatherKitContainsWhere(weatherKitIntSummary())
    weatherKitContainsWhereEquatable(weatherKitChangeCollection())
    weatherKitContainsWhereEquatable(weatherKitComparisonCollection())
}

func testCollectionContainsEquatable() {
    precondition(weatherKitIntForecast().contains(9))
    precondition(weatherKitIntDays().contains(9))
    precondition(weatherKitIntHours().contains(9))
    precondition(weatherKitIntMonths().contains(9))
    precondition(weatherKitIntSummary().contains(9))
    precondition(weatherKitChangeCollection().contains(weatherKitSampleChange(.increase)))
}

func testCollectionRandomElement() {
    precondition(weatherKitIntForecast().randomElement() != nil)
    precondition(weatherKitIntDays().randomElement() != nil)
    precondition(weatherKitIntHours().randomElement() != nil)
    precondition(weatherKitIntMonths().randomElement() != nil)
    precondition(weatherKitIntSummary().randomElement() != nil)
    precondition(weatherKitChangeCollection().randomElement() != nil)
    precondition(weatherKitComparisonCollection().randomElement() != nil)
}

func testCollectionRandomElementUsing() {
    var generator = SystemRandomNumberGenerator()
    precondition(weatherKitIntForecast().randomElement(using: &generator) != nil)
    precondition(weatherKitIntDays().randomElement(using: &generator) != nil)
    precondition(weatherKitIntHours().randomElement(using: &generator) != nil)
    precondition(weatherKitIntMonths().randomElement(using: &generator) != nil)
    precondition(weatherKitIntSummary().randomElement(using: &generator) != nil)
    precondition(weatherKitChangeCollection().randomElement(using: &generator) != nil)
    precondition(weatherKitComparisonCollection().randomElement(using: &generator) != nil)
}

func weatherKitLastWhere<C: BidirectionalCollection>(_ collection: C) where C.Element == Int {
    precondition(collection.last(where: { $0 == 1 }) == 1)
}

func weatherKitLastIndexWhere<C: BidirectionalCollection>(_ collection: C) where C.Element == Int {
    precondition(collection.lastIndex(where: { $0 == 1 }) != nil)
}

func weatherKitLastIndexWhereEquatable<C: BidirectionalCollection>(_ collection: C) {
    precondition(collection.lastIndex(where: { _ in true }) != nil)
}

func weatherKitLastIndexOf<C: BidirectionalCollection>(_ collection: C, _ value: C.Element)
where C.Element: Equatable {
    precondition(collection.lastIndex(of: value) != nil)
}

func weatherKitFirstIndexWhere<C: Collection>(_ collection: C) where C.Element == Int {
    precondition(collection.firstIndex(where: { $0 == 4 }) != nil)
}

func weatherKitFirstIndexWhereEquatable<C: Collection>(_ collection: C) {
    precondition(collection.firstIndex(where: { _ in true }) != nil)
}

func weatherKitFirstIndexOf<C: Collection>(_ collection: C, _ value: C.Element)
where C.Element: Equatable {
    precondition(collection.firstIndex(of: value) != nil)
}

func weatherKitFirstWhere<C: Sequence>(_ collection: C) where C.Element == Int {
    precondition(collection.first(where: { $0 > 4 }) == 5)
}

func weatherKitContainsWhere<C: Sequence>(_ collection: C) where C.Element == Int {
    precondition(collection.contains(where: { $0 == 9 }))
}

func weatherKitContainsWhereEquatable<C: Sequence>(_ collection: C) {
    precondition(collection.contains(where: { _ in true }))
}
