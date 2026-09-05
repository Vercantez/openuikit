@_spi(OpenUIKitHost) import SoundAnalysis
import Foundation

private func snExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testTimeDurationConstraintCases() {
    let times = [
        CMTime(value: 1, timescale: 2),
        CMTime(value: 3, timescale: 4),
    ]
    let enumerated = SNTimeDurationConstraint.enumeratedDurations(times)
    if case .enumeratedDurations(let stored) = enumerated {
        snExpect(stored == times, "enumeratedDurations payload")
    } else {
        preconditionFailure("expected enumeratedDurations")
    }
    let range = CMTimeRange(
        start: CMTime(value: 0, timescale: 1),
        duration: CMTime(value: 2, timescale: 1)
    )
    let ranged = SNTimeDurationConstraint.durationRange(range)
    if case .durationRange(let stored) = ranged {
        snExpect(stored == range, "durationRange payload")
    } else {
        preconditionFailure("expected durationRange")
    }
    snExpect(enumerated != ranged, "cases are distinct")
}
