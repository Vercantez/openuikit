import Foundation
import EnergyKit

func testInsightQueryOptionsIsEmpty() {
    energyKitExpect(ElectricityInsightQuery.Options().isEmpty)
    energyKitExpect(!ElectricityInsightQuery.Options.cleanliness.isEmpty)
}

func testInsightQueryOptionsInitEmpty() {
    let options = ElectricityInsightQuery.Options()
    energyKitExpectEqual(options.rawValue, 0)
}

func testInsightQueryOptionsArrayLiteral() {
    let options: ElectricityInsightQuery.Options = [.cleanliness, .tariff]
    energyKitExpect(options.contains(.cleanliness))
    energyKitExpect(options.contains(.tariff))
}

func testInsightQueryOptionsSequenceInit() {
    let options = ElectricityInsightQuery.Options([.cleanliness, .tariff])
    energyKitExpectEqual(options.rawValue, 3)
}

func testInsightQueryOptionsContains() {
    energyKitExpect(ElectricityInsightQuery.Options.cleanliness.contains(.cleanliness))
    energyKitExpect(!ElectricityInsightQuery.Options.cleanliness.contains(.tariff))
}

func testInsightQueryOptionsInsert() {
    var options = ElectricityInsightQuery.Options()
    let result = options.insert(.tariff)
    energyKitExpect(result.inserted)
    energyKitExpect(options.contains(.tariff))
}

func testInsightQueryOptionsRemove() {
    var options: ElectricityInsightQuery.Options = [.cleanliness, .tariff]
    let removed = options.remove(.cleanliness)
    energyKitExpectEqual(removed, .cleanliness)
    energyKitExpect(!options.contains(.cleanliness))
}

func testInsightQueryOptionsUpdate() {
    var options = ElectricityInsightQuery.Options.cleanliness
    let previous = options.update(with: .tariff)
    energyKitExpect(previous == nil)
    energyKitExpect(options.contains(.tariff))
}

func testInsightQueryOptionsUnion() {
    let union = ElectricityInsightQuery.Options.cleanliness.union(.tariff)
    energyKitExpectEqual(union.rawValue, 3)
}

func testInsightQueryOptionsFormUnion() {
    var options = ElectricityInsightQuery.Options.cleanliness
    options.formUnion(.tariff)
    energyKitExpect(options.contains(.tariff))
}

func testInsightQueryOptionsIntersection() {
    let both: ElectricityInsightQuery.Options = [.cleanliness, .tariff]
    energyKitExpectEqual(both.intersection(.cleanliness), .cleanliness)
}

func testInsightQueryOptionsFormIntersection() {
    var options: ElectricityInsightQuery.Options = [.cleanliness, .tariff]
    options.formIntersection(.tariff)
    energyKitExpectEqual(options, .tariff)
}

func testInsightQueryOptionsSymmetricDifference() {
    let left: ElectricityInsightQuery.Options = [.cleanliness]
    let right: ElectricityInsightQuery.Options = [.cleanliness, .tariff]
    energyKitExpectEqual(left.symmetricDifference(right), .tariff)
}

func testInsightQueryOptionsFormSymmetricDifference() {
    var options = ElectricityInsightQuery.Options.cleanliness
    options.formSymmetricDifference(.tariff)
    energyKitExpectEqual(options.rawValue, 3)
}

func testInsightQueryOptionsSubtract() {
    var options: ElectricityInsightQuery.Options = [.cleanliness, .tariff]
    options.subtract(.tariff)
    energyKitExpectEqual(options, .cleanliness)
}

func testInsightQueryOptionsSubtracting() {
    let options: ElectricityInsightQuery.Options = [.cleanliness, .tariff]
    energyKitExpectEqual(options.subtracting(.cleanliness), .tariff)
}

func testInsightQueryOptionsIsSubset() {
    let both: ElectricityInsightQuery.Options = [.cleanliness, .tariff]
    energyKitExpect(ElectricityInsightQuery.Options.cleanliness.isSubset(of: both))
}

func testInsightQueryOptionsIsSuperset() {
    let both: ElectricityInsightQuery.Options = [.cleanliness, .tariff]
    energyKitExpect(both.isSuperset(of: .tariff))
}

func testInsightQueryOptionsIsStrictSubset() {
    let both: ElectricityInsightQuery.Options = [.cleanliness, .tariff]
    energyKitExpect(ElectricityInsightQuery.Options.cleanliness.isStrictSubset(of: both))
    energyKitExpect(!both.isStrictSubset(of: both))
}

func testInsightQueryOptionsIsStrictSuperset() {
    let both: ElectricityInsightQuery.Options = [.cleanliness, .tariff]
    energyKitExpect(both.isStrictSuperset(of: .cleanliness))
}

func testInsightQueryOptionsIsDisjoint() {
    energyKitExpect(ElectricityInsightQuery.Options.cleanliness.isDisjoint(with: .tariff))
    energyKitExpect(!ElectricityInsightQuery.Options.cleanliness.isDisjoint(with: .cleanliness))
}
