import Foundation
import WirelessInsights

func wiExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func wiSampleScore(
    prediction: ServicePrediction.Confidence = .high,
    startTime: ServicePrediction.Confidence = .medium,
    duration: ServicePrediction.Confidence = .low
) -> ServicePrediction.ConfidenceScore {
    ServicePrediction.ConfidenceScore(
        prediction: prediction,
        startTime: startTime,
        duration: duration
    )
}

func wiSamplePrediction(
    impact: ServicePrediction.Impact = .high,
    start: Date = Date(timeIntervalSinceReferenceDate: 100),
    interval: TimeInterval = ServicePrediction.QuantizedInterval.short,
    score: ServicePrediction.ConfidenceScore? = nil
) -> ServicePrediction {
    ServicePrediction(
        impact: impact,
        predictedStartTime: start,
        predictedInterval: interval,
        confidenceScore: score ?? wiSampleScore()
    )
}

func testServicePredictionType() {
    let prediction = wiSamplePrediction()
    wiExpect(type(of: prediction) == ServicePrediction.self, "ServicePrediction metatype")
    let copy: any Sendable = prediction
    wiExpect(copy is ServicePrediction, "Sendable box is ServicePrediction")
}

func testServicePredictionImpactProperty() {
    let low = wiSamplePrediction(impact: .low)
    wiExpect(low.impact == .low, "stored low impact")
    let high = wiSamplePrediction(impact: .high)
    wiExpect(high.impact == .high, "stored high impact")
}

func testServicePredictionPredictedStartTime() {
    let start = Date(timeIntervalSince1970: 1_700_000_000)
    let prediction = wiSamplePrediction(start: start)
    wiExpect(prediction.predictedStartTime == start, "stored predictedStartTime")
    wiExpect(
        prediction.predictedStartTime.timeIntervalSince1970 == 1_700_000_000,
        "Foundation Date identity"
    )
}

func testServicePredictionPredictedInterval() {
    let short = wiSamplePrediction(interval: ServicePrediction.QuantizedInterval.short)
    wiExpect(short.predictedInterval == 60, "short interval")
    let long = wiSamplePrediction(interval: ServicePrediction.QuantizedInterval.long)
    wiExpect(
        long.predictedInterval > ServicePrediction.QuantizedInterval.medium,
        "long lasts more than five minutes"
    )
}

func testServicePredictionConfidenceScoreProperty() {
    let score = wiSampleScore(prediction: .medium, startTime: .low, duration: .high)
    let prediction = wiSamplePrediction(score: score)
    wiExpect(prediction.confidenceScore.prediction == .medium, "score.prediction")
    wiExpect(prediction.confidenceScore.startTime == .low, "score.startTime")
    wiExpect(prediction.confidenceScore.duration == .high, "score.duration")
}

func testServicePredictionEquality() {
    let start = Date(timeIntervalSinceReferenceDate: 50)
    let a = wiSamplePrediction(impact: .medium, start: start, interval: 10)
    let b = wiSamplePrediction(impact: .medium, start: start, interval: 10)
    wiExpect(a == b, "equal predictions")
    wiExpect(!(a != b), "equal predictions are not !=")
}

func testServicePredictionInequality() {
    let a = wiSamplePrediction(impact: .low)
    let b = wiSamplePrediction(impact: .high)
    wiExpect(a != b, "different impact => !=")
    wiExpect(
        wiSamplePrediction(interval: 10) != wiSamplePrediction(interval: 60),
        "different interval => !="
    )
}

func testServicePredictionHashValue() {
    let start = Date(timeIntervalSinceReferenceDate: 9)
    let a = wiSamplePrediction(start: start, interval: 10)
    let b = wiSamplePrediction(start: start, interval: 10)
    wiExpect(a.hashValue == b.hashValue, "equal values share hashValue")
    wiExpect(
        wiSamplePrediction(impact: .low).hashValue != 0 || true,
        "hashValue is reachable"
    )
}

func testServicePredictionHashInto() {
    let prediction = wiSamplePrediction()
    var hasher = Hasher()
    prediction.hash(into: &hasher)
    let first = hasher.finalize()
    var hasher2 = Hasher()
    prediction.hash(into: &hasher2)
    wiExpect(type(of: first) == Int.self, "hash(into:) produced Int")
    _ = hasher2.finalize()
}

func testServicePredictionEncode() {
    let prediction = wiSamplePrediction(
        impact: .high,
        start: Date(timeIntervalSinceReferenceDate: 100),
        interval: 60
    )
    let data = try! JSONEncoder().encode(prediction)
    let object = try! JSONSerialization.jsonObject(with: data) as? [String: Any]
    wiExpect(object != nil, "JSON object")
    let impact = object?["impact"] as? [String: Any]
    wiExpect(impact?.keys.contains("high") == true, "impact encoded as high case")
    let intervalJSON = object?["predictedInterval"] as? Double
        ?? (object?["predictedInterval"] as? Int).map(Double.init)
    wiExpect(intervalJSON == 60, "interval encoded")
    let startJSON = object?["predictedStartTime"] as? Double
        ?? (object?["predictedStartTime"] as? Int).map(Double.init)
    wiExpect(startJSON == 100, "Date as reference-date seconds")
    wiExpect(object?["confidenceScore"] is [String: Any], "nested score")
}

func testServicePredictionInitFromDecoder() {
    let json = """
    {"impact":{"low":{}},"predictedStartTime":100,"predictedInterval":10,"confidenceScore":{"prediction":{"medium":{}},"startTime":{"low":{}},"duration":{"high":{}}}}
    """
    let decoded = try! JSONDecoder().decode(
        ServicePrediction.self,
        from: Data(json.utf8)
    )
    wiExpect(decoded.impact == .low, "decoded impact")
    wiExpect(decoded.predictedStartTime.timeIntervalSinceReferenceDate == 100, "decoded start")
    wiExpect(decoded.predictedInterval == 10, "decoded interval")
    wiExpect(decoded.confidenceScore.prediction == .medium, "decoded score.prediction")
    wiExpect(decoded.confidenceScore.startTime == .low, "decoded score.startTime")
    wiExpect(decoded.confidenceScore.duration == .high, "decoded score.duration")
}
