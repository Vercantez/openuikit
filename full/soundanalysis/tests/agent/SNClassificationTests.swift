@_spi(OpenUIKitHost) import SoundAnalysis
import Foundation

private func snExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testClassificationHostIdentity() {
    let classification = SNClassification(hostIdentifier: "laughter", confidence: 0.91)
    snExpect(classification.identifier == "laughter", "identifier")
    snExpect(classification.confidence == 0.91, "confidence")
}

func testClassificationResultLookup() {
    let laughter = SNClassification(hostIdentifier: "laughter", confidence: 0.8)
    let speech = SNClassification(hostIdentifier: "speech", confidence: 0.2)
    let result = SNClassificationResult(
        hostClassifications: [laughter, speech],
        timeRange: .zero
    )
    snExpect(result.classifications.count == 2, "classifications")
    snExpect(result.classification(forIdentifier: "speech") === speech, "lookup")
    snExpect(result.classification(forIdentifier: "missing") == nil, "missing")
}

func testClassificationResultTimeRange() {
    let range = CMTimeRange(
        start: CMTime(value: 5, timescale: 10),
        duration: CMTime(value: 15, timescale: 10)
    )
    let result = SNClassificationResult(hostClassifications: [], timeRange: range)
    snExpect(result.timeRange == range, "timeRange")
    snExpect(result.classifications.isEmpty, "empty snapshot")
}
