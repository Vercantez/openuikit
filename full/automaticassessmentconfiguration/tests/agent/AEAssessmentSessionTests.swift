import Foundation
import AutomaticAssessmentConfiguration

func testSessionType() {
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    aacExpect(type(of: session) == AEAssessmentSession.self, "type")
}

func testSessionInit() {
    let configuration = AEAssessmentConfiguration()
    configuration.allowsDictation = true
    let session = AEAssessmentSession(configuration: configuration)
    aacExpect(session.configuration.allowsDictation, "captured")
    configuration.allowsDictation = false
    aacExpect(session.configuration.allowsDictation, "snapshot at init")
}

func testSessionConfiguration() {
    let configuration = AEAssessmentConfiguration()
    configuration.allowsSpellCheck = true
    let session = AEAssessmentSession(configuration: configuration)
    let copy = session.configuration
    aacExpect(copy.allowsSpellCheck, "copy has flag")
    copy.allowsSpellCheck = false
    aacExpect(session.configuration.allowsSpellCheck, "getter is a snapshot")
}

func testSessionIsActive() {
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    aacExpect(!session.isActive, "never active before begin")
    session.begin()
    aacExpect(!session.isActive, "begin does not activate")
    session.end()
    aacExpect(!session.isActive, "end keeps inactive")
}

func testSessionDelegate() {
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    aacExpect(session.delegate == nil, "default nil")
    let delegate = RecordingAssessmentDelegate()
    session.delegate = delegate
    aacExpect(session.delegate === delegate, "set")
    session.delegate = nil
    aacExpect(session.delegate == nil, "cleared")
}

func testSupportsConfigurationUpdates() {
    aacExpect(!AEAssessmentSession.supportsConfigurationUpdates, "linux false")
}

func testSupportsMultipleParticipants() {
    aacExpect(!AEAssessmentSession.supportsMultipleParticipants, "linux false")
}

func testSessionBeginFailClosed() {
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    let delegate = RecordingAssessmentDelegate()
    session.delegate = delegate
    session.begin()
    aacExpect(!session.isActive, "not active")
    aacExpect(delegate.didBeginCount == 0, "didBegin never")
    aacExpect(delegate.didEndCount == 0, "didEnd never")
    guard let error = delegate.failedToBegin as? AEAssessmentError else {
        fatalError("AutomaticAssessmentConfiguration test failed: begin error type")
    }
    aacExpect(error.code == .unsupportedPlatform, "unsupportedPlatform")
    aacExpect(error.errorCode == 2, "raw 2")
}

func testSessionEndNoOp() {
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    let delegate = RecordingAssessmentDelegate()
    session.delegate = delegate
    session.end()
    aacExpect(delegate.didEndCount == 0, "end without begin is no-op")
    aacExpect(!session.isActive, "still inactive")
    session.begin()
    session.end()
    aacExpect(delegate.didEndCount == 0, "failed begin then end still no-op")
}

func testSessionUpdateFailClosed() {
    let original = AEAssessmentConfiguration()
    original.allowsDictation = false
    let session = AEAssessmentSession(configuration: original)
    let update = AEAssessmentConfiguration()
    update.allowsDictation = true
    let delegate = RecordingAssessmentDelegate()
    session.delegate = delegate
    session.update(to: update)
    aacExpect(!session.configuration.allowsDictation, "stored config unchanged")
    aacExpect(delegate.didUpdateCount == 0, "didUpdate never")
    aacExpect(delegate.failedToUpdateConfiguration === update, "same update object")
    guard let error = delegate.failedToUpdateError as? AEAssessmentError else {
        fatalError("AutomaticAssessmentConfiguration test failed: update error type")
    }
    aacExpect(error.code == .configurationUpdatesNotSupported, "updates not supported")
    aacExpect(error.errorCode == 4, "raw 4")
}

func testDelegateProtocol() {
    let delegate: any AEAssessmentSessionDelegate = RecordingAssessmentDelegate()
    aacExpect(delegate is NSObject, "NSObjectProtocol")
}

func testAssessmentSessionDidBegin() {
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    let delegate = RecordingAssessmentDelegate()
    session.delegate = delegate
    session.begin()
    aacExpect(delegate.didBeginCount == 0, "linux never begins")
}

func testAssessmentSessionFailedToBegin() {
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    let delegate = RecordingAssessmentDelegate()
    session.delegate = delegate
    session.begin()
    aacExpect(AEAssessmentError.Code.unsupportedPlatform ~= delegate.failedToBegin!, "pattern")
}

func testAssessmentSessionWasInterrupted() {
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    let delegate = RecordingAssessmentDelegate()
    session.delegate = delegate
    session.begin()
    session.end()
    aacExpect(delegate.interrupted == nil, "linux never interrupts")
}

func testAssessmentSessionDidEnd() {
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    let delegate = RecordingAssessmentDelegate()
    session.delegate = delegate
    delegate.assessmentSessionDidEnd(session)
    aacExpect(delegate.didEndCount == 1, "direct optional method")
}

func testAssessmentSessionDidUpdate() {
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    let delegate = RecordingAssessmentDelegate()
    session.delegate = delegate
    session.update(to: AEAssessmentConfiguration())
    aacExpect(delegate.didUpdateCount == 0, "linux never updates")
}

func testAssessmentSessionFailedToUpdate() {
    let session = AEAssessmentSession(configuration: AEAssessmentConfiguration())
    let delegate = RecordingAssessmentDelegate()
    session.delegate = delegate
    let next = AEAssessmentConfiguration()
    session.update(to: next)
    aacExpect(AEAssessmentError.Code.configurationUpdatesNotSupported ~= delegate.failedToUpdateError!, "pattern")
    aacExpect(delegate.failedToUpdateConfiguration === next, "config")
}
