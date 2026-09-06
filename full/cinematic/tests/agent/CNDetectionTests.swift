import Foundation
import Cinematic

func testCNDetectionInitStoresProperties() {
    let time = CMTime(seconds: 1.5, preferredTimescale: 600)
    let rect = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    let detection = CNDetection(
        time: time,
        detectionType: .humanFace,
        normalizedRect: rect,
        focusDisparity: 0.42
    )
    precondition(detection.time == time)
    precondition(detection.detectionType == .humanFace)
    precondition(detection.normalizedRect == rect)
    precondition(detection.focusDisparity == 0.42)
    precondition(detection.detectionID == nil)
    precondition(detection.detectionGroupID == nil)
}

func testCNDetectionTime() {
    let time = CMTime(value: 1200, timescale: 600)
    let detection = CNDetection(
        time: time,
        detectionType: .unknown,
        normalizedRect: .zero,
        focusDisparity: 0
    )
    precondition(detection.time.value == 1200)
    precondition(detection.time.timescale == 600)
}

func testCNDetectionTypeProperty() {
    let detection = CNDetection(
        time: .zero,
        detectionType: .catHead,
        normalizedRect: .zero,
        focusDisparity: 0
    )
    precondition(detection.detectionType == .catHead)
}

func testCNDetectionNormalizedRect() {
    let rect = CGRect(x: 0.25, y: 0.5, width: 0.1, height: 0.2)
    let detection = CNDetection(
        time: .zero,
        detectionType: .sportsBall,
        normalizedRect: rect,
        focusDisparity: 0.1
    )
    precondition(detection.normalizedRect.origin.x == 0.25)
    precondition(detection.normalizedRect.size.height == 0.2)
}

func testCNDetectionFocusDisparity() {
    let detection = CNDetection(
        time: .zero,
        detectionType: .autoFocus,
        normalizedRect: .zero,
        focusDisparity: 1.25
    )
    precondition(detection.focusDisparity == 1.25)
}

func testCNDetectionOptionalIdentifiersNilFromPublicInit() {
    let detection = CNDetection(
        time: .zero,
        detectionType: .custom,
        normalizedRect: .zero,
        focusDisparity: 0
    )
    precondition(detection.detectionID == nil)
    precondition(detection.detectionGroupID == nil)
}

func testCNDetectionAccessibilityLabel() {
    precondition(CNDetection.accessibilityLabel(for: .unknown) == "Unknown")
    precondition(CNDetection.accessibilityLabel(for: .humanFace) == "Person")
    precondition(CNDetection.accessibilityLabel(for: .humanHead) == "Head")
    precondition(CNDetection.accessibilityLabel(for: .humanTorso) == "Torso")
    precondition(CNDetection.accessibilityLabel(for: .catBody) == "Cat")
    precondition(CNDetection.accessibilityLabel(for: .dogBody) == "Dog")
    precondition(CNDetection.accessibilityLabel(for: .catHead) == "Cat")
    precondition(CNDetection.accessibilityLabel(for: .dogHead) == "Dog")
    precondition(CNDetection.accessibilityLabel(for: .sportsBall) == "Sports Ball")
    precondition(CNDetection.accessibilityLabel(for: .autoFocus) == "Auto Focus")
    precondition(CNDetection.accessibilityLabel(for: .fixedFocus) == "Fixed Focus")
    precondition(CNDetection.accessibilityLabel(for: .custom) == "Custom")
}

func testCNDetectionDisparityFailClosedUsesPrior() {
    let buffer = CVPixelBuffer(width: 8, height: 8, floatSamples: [0.9, 0.8])
    let withPrior = CNDetection.disparity(
        in: CGRect(x: 0, y: 0, width: 1, height: 1),
        sourceDisparity: buffer,
        detectionType: .humanFace,
        priorDisparity: 0.33
    )
    precondition(withPrior == 0.33)
    let withoutPrior = CNDetection.disparity(
        in: .zero,
        sourceDisparity: buffer,
        detectionType: .humanFace,
        priorDisparity: nil
    )
    precondition(withoutPrior == 0)
}

func testCNBoundsPredictionDefaultsAndMutation() {
    var prediction = CNBoundsPrediction()
    precondition(prediction.normalizedBounds == .zero)
    precondition(prediction.confidence == 0)
    prediction.normalizedBounds = CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5)
    prediction.confidence = 0.75
    precondition(prediction.normalizedBounds.origin.x == 0.2)
    precondition(prediction.confidence == 0.75)
}
