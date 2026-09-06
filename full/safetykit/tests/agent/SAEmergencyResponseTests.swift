import Foundation
import SafetyKit

private final class RecordingEmergencyDelegate: NSObject, SAEmergencyResponseDelegate {
    var statuses: [SAEmergencyResponseManager.VoiceCallStatus] = []

    func emergencyResponseManager(
        _ emergencyResponseManager: SAEmergencyResponseManager,
        didUpdateVoiceCallStatus voiceCallStatus: SAEmergencyResponseManager.VoiceCallStatus
    ) {
        _ = emergencyResponseManager
        statuses.append(voiceCallStatus)
    }
}

private final class EmptyEmergencyDelegate: NSObject, SAEmergencyResponseDelegate {}

func testSAEmergencyResponseVoiceCallStatusRawValues() {
    typealias Status = SAEmergencyResponseManager.VoiceCallStatus
    precondition(Status.dialing.rawValue == 0)
    precondition(Status.active.rawValue == 1)
    precondition(Status.disconnected.rawValue == 2)
    precondition(Status.failed.rawValue == 3)
    precondition(Status(rawValue: 0) == .dialing)
    precondition(Status(rawValue: 1) == .active)
    precondition(Status(rawValue: 2) == .disconnected)
    precondition(Status(rawValue: 3) == .failed)
    precondition(Status(rawValue: 4) == nil)
    precondition(Status(rawValue: -1) == nil)
}

func testSAEmergencyResponseVoiceCallStatusInequality() {
    precondition(SAEmergencyResponseManager.VoiceCallStatus.dialing != .active)
    precondition(SAEmergencyResponseManager.VoiceCallStatus.disconnected != .failed)
    precondition(!(SAEmergencyResponseManager.VoiceCallStatus.active != .active))
}

func testSAEmergencyResponseVoiceCallStatusHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    SAEmergencyResponseManager.VoiceCallStatus.failed.hash(into: &hasherA)
    SAEmergencyResponseManager.VoiceCallStatus.failed.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        SAEmergencyResponseManager.VoiceCallStatus.dialing.hashValue !=
            SAEmergencyResponseManager.VoiceCallStatus.failed.hashValue
    )

    var set: Set<SAEmergencyResponseManager.VoiceCallStatus> = []
    set.insert(.dialing)
    set.insert(.active)
    set.insert(.disconnected)
    set.insert(.failed)
    set.insert(.active)
    precondition(set.count == 4)
}

func testSAEmergencyResponseManagerConstructible() {
    let manager = SAEmergencyResponseManager()
    precondition(type(of: manager) == SAEmergencyResponseManager.self)
    let asObject: NSObject = manager
    precondition(asObject === manager)
}

func testSAEmergencyResponseManagerDialVoiceCallFailClosed() {
    let manager = SAEmergencyResponseManager()
    let delegate = RecordingEmergencyDelegate()
    manager.delegate = delegate

    var calls = 0
    var accepted = true
    var error: (any Error)?
    manager.dialVoiceCall(toPhoneNumber: "911") { requestAccepted, receivedError in
        calls += 1
        accepted = requestAccepted
        error = receivedError
    }
    precondition(calls == 1)
    precondition(accepted == false)
    let saError = error as? SAError
    precondition(saError?.code == .notAllowed)
    precondition(saError?.errorCode == 2)
    precondition(delegate.statuses.isEmpty)

    var emptyCalls = 0
    manager.dialVoiceCall(toPhoneNumber: "") { requestAccepted, receivedError in
        emptyCalls += 1
        precondition(requestAccepted == false)
        precondition((receivedError as? SAError)?.code == .notAllowed)
    }
    precondition(emptyCalls == 1)
}

func testSAEmergencyResponseManagerDelegateRoundTrip() {
    let manager = SAEmergencyResponseManager()
    precondition(manager.delegate == nil)
    let delegate = RecordingEmergencyDelegate()
    manager.delegate = delegate
    precondition(manager.delegate === delegate)
    manager.delegate = nil
    precondition(manager.delegate == nil)
}

func testSAEmergencyResponseDelegateConformance() {
    let empty: any SAEmergencyResponseDelegate = EmptyEmergencyDelegate()
    let recording: any SAEmergencyResponseDelegate = RecordingEmergencyDelegate()
    _ = (empty, recording)
}

func testSAEmergencyResponseDelegateDidUpdateVoiceCallStatus() {
    let manager = SAEmergencyResponseManager()
    let delegate = RecordingEmergencyDelegate()
    manager.delegate = delegate
    manager.dialVoiceCall(toPhoneNumber: "911") { _, _ in }
    precondition(delegate.statuses.isEmpty)
    manager.host_deliverVoiceCallStatus(.dialing)
    manager.host_deliverVoiceCallStatus(.failed)
    precondition(delegate.statuses == [.dialing, .failed])
}