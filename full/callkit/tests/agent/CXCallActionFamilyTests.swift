import CallKit
import Foundation

private func roundTrip<T: CXAction>(_ action: T) -> T {
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    action.encode(with: archiver)
    let data = archiver.encodedData
    do {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        guard let restored = T(coder: unarchiver) else {
            preconditionFailure("\(T.self) decode returned nil")
        }
        return restored
    } catch {
        preconditionFailure("\(T.self) unarchive failed: \(error)")
    }
}

func testCXStartCallActionInitAndProperties() {
    let uuid = UUID()
    let handle = CXHandle(type: .emailAddress, value: "a@b.c")
    let designated = CXStartCallAction(callUUID: uuid, handle: handle)
    designated.isVideo = true
    designated.contactIdentifier = "cid"
    let convenience = CXStartCallAction(call: uuid, handle: handle)
    precondition(designated.callUUID == uuid)
    precondition(designated.handle.value == "a@b.c")
    precondition(designated.isVideo)
    precondition(designated.contactIdentifier == "cid")
    precondition(convenience.callUUID == uuid)
    precondition(type(of: designated) == CXStartCallAction.self)
}

func testCXStartCallActionNSCodingRoundTrip() {
    let original = CXStartCallAction(
        callUUID: UUID(),
        handle: CXHandle(type: .phoneNumber, value: "+1555")
    )
    original.contactIdentifier = "person"
    original.isVideo = true
    let restored = roundTrip(original)
    precondition(restored.callUUID == original.callUUID)
    precondition(restored.handle.value == "+1555")
    precondition(restored.contactIdentifier == "person")
    precondition(restored.isVideo)
}

func testCXStartCallActionFulfillWithDateStarted() {
    let action = CXStartCallAction(
        callUUID: UUID(),
        handle: CXHandle(type: .generic, value: "x")
    )
    let started = Date(timeIntervalSince1970: 100)
    action.fulfill(withDateStarted: started)
    precondition(action.isComplete)
}

func testCXAnswerCallActionFulfillWithDateConnected() {
    let action = CXAnswerCallAction(callUUID: UUID())
    let connected = Date(timeIntervalSince1970: 200)
    action.fulfill(withDateConnected: connected)
    precondition(action.isComplete)
    precondition(type(of: action) == CXAnswerCallAction.self)
}

func testCXEndCallActionFulfillWithDateEnded() {
    let action = CXEndCallAction(callUUID: UUID())
    let ended = Date(timeIntervalSince1970: 300)
    action.fulfill(withDateEnded: ended)
    precondition(action.isComplete)
    precondition(type(of: action) == CXEndCallAction.self)
}

func testCXSetHeldCallActionInitAndNSCoding() {
    let uuid = UUID()
    let designated = CXSetHeldCallAction(callUUID: uuid, onHold: true)
    let convenience = CXSetHeldCallAction(call: uuid, onHold: false)
    precondition(designated.isOnHold)
    precondition(!convenience.isOnHold)
    let restored = roundTrip(designated)
    precondition(restored.callUUID == uuid)
    precondition(restored.isOnHold)
    precondition(type(of: designated) == CXSetHeldCallAction.self)
}

func testCXSetMutedCallActionInitAndNSCoding() {
    let uuid = UUID()
    let designated = CXSetMutedCallAction(callUUID: uuid, muted: true)
    let convenience = CXSetMutedCallAction(call: uuid, muted: false)
    precondition(designated.isMuted)
    precondition(!convenience.isMuted)
    let restored = roundTrip(designated)
    precondition(restored.callUUID == uuid)
    precondition(restored.isMuted)
    precondition(type(of: designated) == CXSetMutedCallAction.self)
}

func testCXSetGroupCallActionInitAndNSCoding() {
    let uuid = UUID()
    let other = UUID()
    let designated = CXSetGroupCallAction(callUUID: uuid, callUUIDToGroupWith: other)
    let convenience = CXSetGroupCallAction(call: uuid, callUUIDToGroupWith: nil)
    precondition(designated.callUUIDToGroupWith == other)
    precondition(convenience.callUUIDToGroupWith == nil)
    let restored = roundTrip(designated)
    precondition(restored.callUUIDToGroupWith == other)
    precondition(type(of: designated) == CXSetGroupCallAction.self)
}

func testCXPlayDTMFCallActionInitAndNSCoding() {
    let uuid = UUID()
    let designated = CXPlayDTMFCallAction(callUUID: uuid, digits: "9#", type: .singleTone)
    let convenience = CXPlayDTMFCallAction(call: uuid, digits: "*", type: .hardPause)
    precondition(designated.digits == "9#")
    precondition(designated.type == .singleTone)
    precondition(convenience.type == .hardPause)
    let restored = roundTrip(designated)
    precondition(restored.digits == "9#")
    precondition(restored.type == .singleTone)
    precondition(type(of: designated) == CXPlayDTMFCallAction.self)
}

func testCXSetTranslatingCallActionInitAndNSCoding() {
    let uuid = UUID()
    let designated = CXSetTranslatingCallAction(
        callUUID: uuid,
        isTranslating: true,
        localLanguage: "en",
        remoteLanguage: "es"
    )
    let convenience = CXSetTranslatingCallAction(
        call: uuid,
        isTranslating: false,
        localLanguage: "fr",
        remoteLanguage: "de"
    )
    precondition(designated.isTranslating)
    precondition(designated.localLanguage == "en")
    precondition(designated.remoteLanguage == "es")
    precondition(!convenience.isTranslating)
    let restored = roundTrip(designated)
    precondition(restored.isTranslating)
    precondition(restored.localLanguage == "en")
    precondition(restored.remoteLanguage == "es")
    designated.fulfill(using: .custom)
    precondition(designated.isComplete)
    precondition(type(of: designated) == CXSetTranslatingCallAction.self)
}
