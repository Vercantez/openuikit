import Foundation
import WirelessInsights

func testServicePredictionImpactType() {
    let value: ServicePrediction.Impact = .medium
    wiExpect(type(of: value) == ServicePrediction.Impact.self, "Impact metatype")
}

func testServicePredictionImpactLow() {
    let value = ServicePrediction.Impact.low
    wiExpect(value == .low, "low case")
    wiExpect(value != .medium, "low is not medium")
}

func testServicePredictionImpactMedium() {
    let value = ServicePrediction.Impact.medium
    wiExpect(value == .medium, "medium case")
}

func testServicePredictionImpactHigh() {
    let value = ServicePrediction.Impact.high
    wiExpect(value == .high, "high case")
}

func testServicePredictionImpactLessThan() {
    wiExpect(ServicePrediction.Impact.low < .medium, "low < medium")
    wiExpect(ServicePrediction.Impact.medium < .high, "medium < high")
    wiExpect(ServicePrediction.Impact.low < .high, "low < high")
    wiExpect(!(ServicePrediction.Impact.high < .low), "high is not < low")
}

func testServicePredictionImpactGreaterThan() {
    wiExpect(ServicePrediction.Impact.high > .medium, "high > medium")
    wiExpect(ServicePrediction.Impact.medium > .low, "medium > low")
    wiExpect(!(ServicePrediction.Impact.low > .high), "low is not > high")
}

func testServicePredictionImpactGreaterThanOrEqual() {
    wiExpect(ServicePrediction.Impact.high >= .high, "high >= high")
    wiExpect(ServicePrediction.Impact.high >= .medium, "high >= medium")
    wiExpect(!(ServicePrediction.Impact.low >= .high), "low is not >= high")
}

func testServicePredictionImpactLessThanOrEqual() {
    wiExpect(ServicePrediction.Impact.low <= .low, "low <= low")
    wiExpect(ServicePrediction.Impact.low <= .high, "low <= high")
    wiExpect(!(ServicePrediction.Impact.high <= .low), "high is not <= low")
}

func testServicePredictionImpactEquality() {
    wiExpect(ServicePrediction.Impact.low == .low, "low == low")
    wiExpect(ServicePrediction.Impact.==( .high, .high), "static ==")
}

func testServicePredictionImpactInequality() {
    wiExpect(ServicePrediction.Impact.low != .high, "low != high")
    wiExpect(!(ServicePrediction.Impact.medium != .medium), "medium == medium")
}

func testServicePredictionImpactHashValue() {
    wiExpect(
        ServicePrediction.Impact.medium.hashValue == ServicePrediction.Impact.medium.hashValue,
        "same case same hashValue"
    )
}

func testServicePredictionImpactHashInto() {
    var hasher = Hasher()
    ServicePrediction.Impact.low.hash(into: &hasher)
    _ = hasher.finalize()
}

func testServicePredictionImpactEncode() {
    let data = try! JSONEncoder().encode(ServicePrediction.Impact.high)
    let text = String(data: data, encoding: .utf8)
    wiExpect(text == "\"high\"", "Impact encodes as case name")
}

func testServicePredictionImpactInitFromDecoder() {
    let decoded = try! JSONDecoder().decode(
        ServicePrediction.Impact.self,
        from: Data("\"low\"".utf8)
    )
    wiExpect(decoded == .low, "decoded low")
}

func testServicePredictionImpactRange() {
    let range: Range<ServicePrediction.Impact> = .low ..< .high
    wiExpect(range.contains(.low), "low in half-open range")
    wiExpect(range.contains(.medium), "medium in half-open range")
    wiExpect(!range.contains(.high), "high excluded from ..< high")
}

func testServicePredictionImpactPartialRangeUpTo() {
    let range: PartialRangeUpTo<ServicePrediction.Impact> = ..< .high
    wiExpect(range.contains(.low), "low")
    wiExpect(range.contains(.medium), "medium")
    wiExpect(!range.contains(.high), "high excluded")
}

func testServicePredictionImpactPartialRangeFrom() {
    let range: PartialRangeFrom<ServicePrediction.Impact> = .medium...
    wiExpect(!range.contains(.low), "low excluded")
    wiExpect(range.contains(.medium), "medium included")
    wiExpect(range.contains(.high), "high included")
}

func testServicePredictionImpactClosedRange() {
    let range: ClosedRange<ServicePrediction.Impact> = .low ... .medium
    wiExpect(range.contains(.low), "low")
    wiExpect(range.contains(.medium), "medium")
    wiExpect(!range.contains(.high), "high excluded")
}

func testServicePredictionImpactPartialRangeThrough() {
    let range: PartialRangeThrough<ServicePrediction.Impact> = ... .medium
    wiExpect(range.contains(.low), "low")
    wiExpect(range.contains(.medium), "medium")
    wiExpect(!range.contains(.high), "high excluded")
}
