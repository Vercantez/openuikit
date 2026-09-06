import Foundation
import WirelessInsights

func testServicePredictionConfidenceType() {
    let value: ServicePrediction.Confidence = .medium
    wiExpect(type(of: value) == ServicePrediction.Confidence.self, "Confidence metatype")
}

func testServicePredictionConfidenceLow() {
    let value = ServicePrediction.Confidence.low
    wiExpect(value == .low, "low case")
    wiExpect(value != .medium, "low is not medium")
    wiExpect(value != .high, "low is not high")
}

func testServicePredictionConfidenceMedium() {
    let value = ServicePrediction.Confidence.medium
    wiExpect(value == .medium, "medium case")
}

func testServicePredictionConfidenceHigh() {
    let value = ServicePrediction.Confidence.high
    wiExpect(value == .high, "high case")
}

func testServicePredictionConfidenceLessThan() {
    wiExpect(ServicePrediction.Confidence.low < .medium, "low < medium")
    wiExpect(ServicePrediction.Confidence.medium < .high, "medium < high")
    wiExpect(ServicePrediction.Confidence.low < .high, "low < high")
    wiExpect(!(ServicePrediction.Confidence.high < .low), "high is not < low")
    wiExpect(!(ServicePrediction.Confidence.low < .low), "not < self")
}

func testServicePredictionConfidenceGreaterThan() {
    wiExpect(ServicePrediction.Confidence.high > .medium, "high > medium")
    wiExpect(ServicePrediction.Confidence.medium > .low, "medium > low")
    wiExpect(!(ServicePrediction.Confidence.low > .high), "low is not > high")
}

func testServicePredictionConfidenceGreaterThanOrEqual() {
    wiExpect(ServicePrediction.Confidence.high >= .high, "high >= high")
    wiExpect(ServicePrediction.Confidence.high >= .medium, "high >= medium")
    wiExpect(!(ServicePrediction.Confidence.low >= .high), "low is not >= high")
}

func testServicePredictionConfidenceLessThanOrEqual() {
    wiExpect(ServicePrediction.Confidence.low <= .low, "low <= low")
    wiExpect(ServicePrediction.Confidence.low <= .high, "low <= high")
    wiExpect(!(ServicePrediction.Confidence.high <= .low), "high is not <= low")
}

func testServicePredictionConfidenceEquality() {
    wiExpect(ServicePrediction.Confidence.low == .low, "low == low")
    wiExpect(ServicePrediction.Confidence.==( .medium, .medium), "static ==")
    wiExpect(!(ServicePrediction.Confidence.low == .high), "low != high via ==")
}

func testServicePredictionConfidenceInequality() {
    wiExpect(ServicePrediction.Confidence.low != .high, "low != high")
    wiExpect(!(ServicePrediction.Confidence.medium != .medium), "medium == medium")
}

func testServicePredictionConfidenceHashValue() {
    wiExpect(
        ServicePrediction.Confidence.low.hashValue == ServicePrediction.Confidence.low.hashValue,
        "same case same hashValue"
    )
}

func testServicePredictionConfidenceHashInto() {
    var hasher = Hasher()
    ServicePrediction.Confidence.high.hash(into: &hasher)
    _ = hasher.finalize()
}

func testServicePredictionConfidenceEncode() {
    let data = try! JSONEncoder().encode(ServicePrediction.Confidence.medium)
    let text = String(data: data, encoding: .utf8)
    wiExpect(text == "\"medium\"", "Confidence encodes as case name")
}

func testServicePredictionConfidenceInitFromDecoder() {
    let decoded = try! JSONDecoder().decode(
        ServicePrediction.Confidence.self,
        from: Data("\"high\"".utf8)
    )
    wiExpect(decoded == .high, "decoded high")
}

func testServicePredictionConfidenceRange() {
    let range: Range<ServicePrediction.Confidence> = .low ..< .high
    wiExpect(range.contains(.low), "low in half-open range")
    wiExpect(range.contains(.medium), "medium in half-open range")
    wiExpect(!range.contains(.high), "high excluded from ..< high")
}

func testServicePredictionConfidencePartialRangeUpTo() {
    let range: PartialRangeUpTo<ServicePrediction.Confidence> = ..< .high
    wiExpect(range.contains(.low), "low")
    wiExpect(range.contains(.medium), "medium")
    wiExpect(!range.contains(.high), "high excluded")
}

func testServicePredictionConfidencePartialRangeFrom() {
    let range: PartialRangeFrom<ServicePrediction.Confidence> = .medium...
    wiExpect(!range.contains(.low), "low excluded")
    wiExpect(range.contains(.medium), "medium included")
    wiExpect(range.contains(.high), "high included")
}

func testServicePredictionConfidenceClosedRange() {
    let range: ClosedRange<ServicePrediction.Confidence> = .low ... .medium
    wiExpect(range.contains(.low), "low")
    wiExpect(range.contains(.medium), "medium")
    wiExpect(!range.contains(.high), "high excluded")
}

func testServicePredictionConfidencePartialRangeThrough() {
    let range: PartialRangeThrough<ServicePrediction.Confidence> = ... .medium
    wiExpect(range.contains(.low), "low")
    wiExpect(range.contains(.medium), "medium")
    wiExpect(!range.contains(.high), "high excluded")
}
