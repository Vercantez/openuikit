import Foundation
import AutomaticAssessmentConfiguration

func aacExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("AutomaticAssessmentConfiguration test failed: \(message)")
    }
}

final class RecordingAssessmentDelegate: NSObject, AEAssessmentSessionDelegate {
    var didBeginCount = 0
    var failedToBegin: (any Error)?
    var interrupted: (any Error)?
    var didEndCount = 0
    var didUpdateCount = 0
    var failedToUpdateConfiguration: AEAssessmentConfiguration?
    var failedToUpdateError: (any Error)?

    func assessmentSessionDidBegin(_ session: AEAssessmentSession) {
        _ = session
        didBeginCount += 1
    }

    func assessmentSession(_ session: AEAssessmentSession, failedToBeginWithError error: any Error) {
        _ = session
        failedToBegin = error
    }

    func assessmentSession(_ session: AEAssessmentSession, wasInterruptedWithError error: any Error) {
        _ = session
        interrupted = error
    }

    func assessmentSessionDidEnd(_ session: AEAssessmentSession) {
        _ = session
        didEndCount += 1
    }

    func assessmentSessionDidUpdate(_ session: AEAssessmentSession) {
        _ = session
        didUpdateCount += 1
    }

    func assessmentSession(
        _ session: AEAssessmentSession,
        failedToUpdateTo configuration: AEAssessmentConfiguration,
        error: any Error
    ) {
        failedToUpdateConfiguration = configuration
        failedToUpdateError = error
    }
}

func testHarnessRecordingDelegateType() {
    let delegate = RecordingAssessmentDelegate()
    aacExpect(delegate.didBeginCount == 0, "fresh delegate")
}
