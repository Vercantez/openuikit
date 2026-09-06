import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testNumericPairStorage() {
    let pair = PHASENumericPair(firstValue: 2, secondValue: 8)
    expect(pair.first == 2, "first")
    expect(pair.second == 8, "second")
    pair.first = -1
    pair.second = 4
    expect(pair.first == -1 && pair.second == 4, "mutated")
}

func testEnvelopeSegmentStorage() {
    let segment = PHASEEnvelopeSegment(endPoint: simd_double2(1, 10), curveType: .linear)
    expect(segment.endPoint.x == 1 && segment.endPoint.y == 10, "endPoint")
    expect(segment.curveType == .linear, "curve")
    segment.curveType = .squared
    segment.endPoint = simd_double2(2, 20)
    expect(segment.curveType == .squared, "mutated curve")
    expect(segment.endPoint.y == 20, "mutated point")
}

func testEnvelopeLinearEvaluate() {
    let segment = PHASEEnvelopeSegment(endPoint: simd_double2(1, 10), curveType: .linear)
    guard let envelope = PHASEEnvelope(startPoint: simd_double2(0, 0), segments: [segment]) else {
        preconditionFailure("envelope")
    }
    expect(envelope.startPoint.x == 0, "start")
    expect(envelope.segments.count == 1, "segments")
    expect(envelope.evaluate(x: 0) == 0, "at start")
    expect(abs(envelope.evaluate(x: 0.5) - 5) < 1e-9, "mid")
    expect(abs(envelope.evaluate(x: 1) - 10) < 1e-9, "end")
    expect(envelope.evaluate(x: -1) == 0, "before")
    expect(envelope.evaluate(x: 2) == 10, "after")
}

func testEnvelopeDomainRange() {
    let segment = PHASEEnvelopeSegment(endPoint: simd_double2(4, -2), curveType: .linear)
    guard let envelope = PHASEEnvelope(startPoint: simd_double2(1, 3), segments: [segment]) else {
        preconditionFailure("envelope")
    }
    expect(envelope.domain.first == 1, "domain min")
    expect(envelope.domain.second == 4, "domain max")
    expect(envelope.range.first == -2, "range min")
    expect(envelope.range.second == 3, "range max")
}

func testEnvelopeSquaredEase() {
    let segment = PHASEEnvelopeSegment(endPoint: simd_double2(1, 1), curveType: .squared)
    guard let envelope = PHASEEnvelope(startPoint: simd_double2(0, 0), segments: [segment]) else {
        preconditionFailure("envelope")
    }
    expect(abs(envelope.evaluate(x: 0.5) - 0.25) < 1e-9, "t^2")
}

func testEnvelopeHoldAndJump() {
    let hold = PHASEEnvelopeSegment(endPoint: simd_double2(1, 10), curveType: .holdStartValue)
    let jump = PHASEEnvelopeSegment(endPoint: simd_double2(1, 10), curveType: .jumpToEndValue)
    guard let holdEnv = PHASEEnvelope(startPoint: simd_double2(0, 0), segments: [hold]) else {
        preconditionFailure("hold")
    }
    guard let jumpEnv = PHASEEnvelope(startPoint: simd_double2(0, 0), segments: [jump]) else {
        preconditionFailure("jump")
    }
    expect(holdEnv.evaluate(x: 0.5) == 0, "hold")
    expect(jumpEnv.evaluate(x: 0.5) == 10, "jump")
}
