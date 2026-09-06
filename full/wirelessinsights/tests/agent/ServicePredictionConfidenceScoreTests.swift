import Foundation
import WirelessInsights

func testServicePredictionConfidenceScoreType() {
    let score = wiSampleScore()
    wiExpect(
        type(of: score) == ServicePrediction.ConfidenceScore.self,
        "ConfidenceScore metatype"
    )
}

func testServicePredictionConfidenceScorePrediction() {
    let score = wiSampleScore(prediction: .low, startTime: .high, duration: .medium)
    wiExpect(score.prediction == .low, "stored prediction confidence")
}

func testServicePredictionConfidenceScoreStartTime() {
    let score = wiSampleScore(prediction: .high, startTime: .medium, duration: .low)
    wiExpect(score.startTime == .medium, "stored startTime confidence")
}

func testServicePredictionConfidenceScoreDuration() {
    let score = wiSampleScore(prediction: .high, startTime: .high, duration: .low)
    wiExpect(score.duration == .low, "stored duration confidence")
}

func testServicePredictionConfidenceScoreEquality() {
    let a = wiSampleScore(prediction: .high, startTime: .low, duration: .medium)
    let b = wiSampleScore(prediction: .high, startTime: .low, duration: .medium)
    wiExpect(a == b, "equal scores")
    wiExpect(!(a != b), "equal scores are not !=")
}

func testServicePredictionConfidenceScoreInequality() {
    let a = wiSampleScore(prediction: .low)
    let b = wiSampleScore(prediction: .high)
    wiExpect(a != b, "different prediction => !=")
}

func testServicePredictionConfidenceScoreHashValue() {
    let a = wiSampleScore(prediction: .medium, startTime: .medium, duration: .medium)
    let b = wiSampleScore(prediction: .medium, startTime: .medium, duration: .medium)
    wiExpect(a.hashValue == b.hashValue, "equal scores share hashValue")
}

func testServicePredictionConfidenceScoreHashInto() {
    var hasher = Hasher()
    wiSampleScore().hash(into: &hasher)
    _ = hasher.finalize()
}

func testServicePredictionConfidenceScoreEncode() {
    let score = wiSampleScore(prediction: .high, startTime: .medium, duration: .low)
    let data = try! JSONEncoder().encode(score)
    let object = try! JSONSerialization.jsonObject(with: data) as? [String: Any]
    let prediction = object?["prediction"] as? [String: Any]
    let startTime = object?["startTime"] as? [String: Any]
    let duration = object?["duration"] as? [String: Any]
    wiExpect(prediction?.keys.contains("high") == true, "prediction key")
    wiExpect(startTime?.keys.contains("medium") == true, "startTime key")
    wiExpect(duration?.keys.contains("low") == true, "duration key")
}

func testServicePredictionConfidenceScoreInitFromDecoder() {
    let json = """
    {"prediction":{"low":{}},"startTime":{"high":{}},"duration":{"medium":{}}}
    """
    let decoded = try! JSONDecoder().decode(
        ServicePrediction.ConfidenceScore.self,
        from: Data(json.utf8)
    )
    wiExpect(decoded.prediction == .low, "decoded prediction")
    wiExpect(decoded.startTime == .high, "decoded startTime")
    wiExpect(decoded.duration == .medium, "decoded duration")
}
