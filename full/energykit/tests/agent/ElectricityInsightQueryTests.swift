import Foundation
import EnergyKit

func testInsightQueryType() {
    let query = energyKitSampleQuery()
    energyKitExpectEqual(query.granularity, .hourly)
}

func testInsightQueryOptionsProperty() {
    energyKitExpect(energyKitSampleQuery().options.contains(.cleanliness))
    energyKitExpect(energyKitSampleQuery().options.contains(.tariff))
}

func testInsightQueryRange() {
    energyKitExpectEqual(energyKitSampleQuery().range, energyKitSampleInterval())
}

func testInsightQueryGranularityProperty() {
    energyKitExpectEqual(
        ElectricityInsightQuery(
            options: [],
            range: energyKitSampleInterval(),
            granularity: .monthly,
            flowDirection: .exported
        ).granularity,
        .monthly
    )
}

func testInsightQueryFlowDirection() {
    energyKitExpectEqual(energyKitSampleQuery().flowDirection, .imported)
}

func testInsightQueryInit() {
    let query = ElectricityInsightQuery(
        options: .tariff,
        range: energyKitSampleInterval(),
        granularity: .yearly,
        flowDirection: .exported
    )
    energyKitExpectEqual(query.options, .tariff)
    energyKitExpectEqual(query.granularity, .yearly)
}

func testInsightQueryCodable() {
    let decoded = try! energyKitRoundTrip(energyKitSampleQuery())
    energyKitExpectEqual(decoded.granularity, .hourly)
    energyKitExpectEqual(decoded.flowDirection, .imported)
}

func testInsightQueryEncode() {
    let data = try! JSONEncoder().encode(energyKitSampleQuery())
    energyKitExpect(data.count > 0)
}

func testInsightQueryGranularityCases() {
    let cases: [ElectricityInsightQuery.Granularity] = [
        .hourly, .daily, .weekly, .monthly, .yearly
    ]
    energyKitExpectEqual(Set(cases).count, 5)
}

func testInsightQueryGranularityEquality() {
    energyKitExpectEqual(ElectricityInsightQuery.Granularity.hourly, .hourly)
    energyKitExpect(ElectricityInsightQuery.Granularity.daily != .weekly)
}

func testInsightQueryGranularityInequality() {
    energyKitExpect(ElectricityInsightQuery.Granularity.monthly != .yearly)
}

func testInsightQueryGranularityHash() {
    var hasher = Hasher()
    ElectricityInsightQuery.Granularity.weekly.hash(into: &hasher)
    energyKitExpectEqual(Set([ElectricityInsightQuery.Granularity.daily, .daily]).count, 1)
}

func testInsightQueryGranularityCodable() {
    energyKitExpectEqual(try! energyKitRoundTrip(ElectricityInsightQuery.Granularity.hourly), .hourly)
    energyKitExpectEqual(try! energyKitRoundTrip(ElectricityInsightQuery.Granularity.yearly), .yearly)
}

func testInsightQueryOptionsMembers() {
    energyKitExpectEqual(ElectricityInsightQuery.Options.cleanliness.rawValue, 1)
    energyKitExpectEqual(ElectricityInsightQuery.Options.tariff.rawValue, 2)
}

func testInsightQueryOptionsRawValueProperty() {
    energyKitExpectEqual(ElectricityInsightQuery.Options(rawValue: 3).rawValue, 3)
}

func testInsightQueryOptionsInitRawValue() {
    let options = ElectricityInsightQuery.Options(rawValue: 1)
    energyKitExpect(options.contains(.cleanliness))
    energyKitExpect(!options.contains(.tariff))
}

func testInsightQueryOptionsRawValueTypealias() {
    let raw: ElectricityInsightQuery.Options.RawValue = ElectricityInsightQuery.Options.tariff.rawValue
    energyKitExpectEqual(raw, 2)
}

func testInsightQueryOptionsElementTypealias() {
    let member: ElectricityInsightQuery.Options.Element = .cleanliness
    energyKitExpect(member.contains(.cleanliness))
}

func testInsightQueryOptionsArrayLiteralElementTypealias() {
    let member: ElectricityInsightQuery.Options.ArrayLiteralElement = .tariff
    energyKitExpectEqual(member, .tariff)
}

func testInsightQueryOptionsInequality() {
    energyKitExpect(ElectricityInsightQuery.Options.cleanliness != .tariff)
}

func testInsightQueryOptionsHashable() {
    var hasher = Hasher()
    ElectricityInsightQuery.Options.cleanliness.hash(into: &hasher)
    energyKitExpectEqual(
        Set([ElectricityInsightQuery.Options.cleanliness, .cleanliness]).count,
        1
    )
}

func testInsightQueryOptionsCodable() {
    let decoded = try! energyKitRoundTrip(ElectricityInsightQuery.Options.cleanliness.union(.tariff))
    energyKitExpect(decoded.contains(.cleanliness))
    energyKitExpect(decoded.contains(.tariff))
}

func testFlowDirectionCases() {
    let cases: [ElectricityFlowDirection] = [.imported, .exported]
    energyKitExpectEqual(Set(cases).count, 2)
}

func testFlowDirectionEquality() {
    energyKitExpectEqual(ElectricityFlowDirection.imported, .imported)
    energyKitExpect(ElectricityFlowDirection.imported != .exported)
}

func testFlowDirectionInequality() {
    energyKitExpect(ElectricityFlowDirection.exported != .imported)
}

func testFlowDirectionHash() {
    var hasher = Hasher()
    ElectricityFlowDirection.exported.hash(into: &hasher)
    energyKitExpectEqual(Set([ElectricityFlowDirection.imported, .imported]).count, 1)
}

func testFlowDirectionCodable() {
    energyKitExpectEqual(try! energyKitRoundTrip(ElectricityFlowDirection.imported), .imported)
    energyKitExpectEqual(try! energyKitRoundTrip(ElectricityFlowDirection.exported), .exported)
}
