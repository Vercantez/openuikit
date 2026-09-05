import CallKit
import Foundation

func testCallEndedReasonRawValues() {
    precondition(CXCallEndedReason.failed.rawValue == 1)
    precondition(CXCallEndedReason.remoteEnded.rawValue == 2)
    precondition(CXCallEndedReason.unanswered.rawValue == 3)
    precondition(CXCallEndedReason.answeredElsewhere.rawValue == 4)
    precondition(CXCallEndedReason.declinedElsewhere.rawValue == 5)
    precondition(CXCallEndedReason.failed != .unanswered)
    precondition(CXCallEndedReason(rawValue: 1) == .failed)
    precondition(CXCallEndedReason(rawValue: 5) == .declinedElsewhere)
    precondition(CXCallEndedReason(rawValue: 0) == nil)
    var hasher = Hasher()
    CXCallEndedReason.remoteEnded.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(CXCallEndedReason.failed.hashValue != CXCallEndedReason.unanswered.hashValue)
}

func testHandleTypeRawValues() {
    precondition(CXHandle.HandleType.generic.rawValue == 1)
    precondition(CXHandle.HandleType.phoneNumber.rawValue == 2)
    precondition(CXHandle.HandleType.emailAddress.rawValue == 3)
    precondition(CXHandle.HandleType.generic != .phoneNumber)
    precondition(CXHandle.HandleType(rawValue: 1) == .generic)
    precondition(CXHandle.HandleType(rawValue: 3) == .emailAddress)
    precondition(CXHandle.HandleType(rawValue: 0) == nil)
    var hasher = Hasher()
    CXHandle.HandleType.phoneNumber.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(CXHandle.HandleType.generic.hashValue != CXHandle.HandleType.emailAddress.hashValue)
}

func testPlayDTMFCallActionTypeRawValues() {
    precondition(CXPlayDTMFCallAction.ActionType.singleTone.rawValue == 1)
    precondition(CXPlayDTMFCallAction.ActionType.softPause.rawValue == 2)
    precondition(CXPlayDTMFCallAction.ActionType.hardPause.rawValue == 3)
    precondition(CXPlayDTMFCallAction.ActionType.singleTone != .hardPause)
    precondition(CXPlayDTMFCallAction.ActionType(rawValue: 2) == .softPause)
    precondition(CXPlayDTMFCallAction.ActionType(rawValue: 0) == nil)
    var hasher = Hasher()
    CXPlayDTMFCallAction.ActionType.softPause.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(
        CXPlayDTMFCallAction.ActionType.singleTone.hashValue
            != CXPlayDTMFCallAction.ActionType.hardPause.hashValue
    )
}

func testTranslationEngineRawValues() {
    precondition(CXTranslationEngine.default.rawValue == 0)
    precondition(CXTranslationEngine.custom.rawValue == 1)
    precondition(CXTranslationEngine.default != .custom)
    precondition(CXTranslationEngine(rawValue: 0) == .default)
    precondition(CXTranslationEngine(rawValue: 1) == .custom)
    precondition(CXTranslationEngine(rawValue: 2) == nil)
    var hasher = Hasher()
    CXTranslationEngine.custom.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(CXTranslationEngine.default.hashValue != CXTranslationEngine.custom.hashValue)
}

func testCallDirectoryEnabledStatusRawValues() {
    precondition(CXCallDirectoryManager.EnabledStatus.unknown.rawValue == 0)
    precondition(CXCallDirectoryManager.EnabledStatus.disabled.rawValue == 1)
    precondition(CXCallDirectoryManager.EnabledStatus.enabled.rawValue == 2)
    precondition(CXCallDirectoryManager.EnabledStatus.unknown != .enabled)
    precondition(CXCallDirectoryManager.EnabledStatus(rawValue: 1) == .disabled)
    precondition(CXCallDirectoryManager.EnabledStatus(rawValue: 3) == nil)
    var hasher = Hasher()
    CXCallDirectoryManager.EnabledStatus.enabled.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(
        CXCallDirectoryManager.EnabledStatus.disabled.hashValue
            != CXCallDirectoryManager.EnabledStatus.enabled.hashValue
    )
}

func testCallDirectoryPhoneNumberTypealias() {
    let number: CXCallDirectoryPhoneNumber = 1_555_1212
    precondition(number == 1_555_1212)
    precondition(CXCallDirectoryPhoneNumber.self == Int64.self)
}
