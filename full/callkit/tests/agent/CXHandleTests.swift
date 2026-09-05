import CallKit
import Foundation

private func roundTripHandle(_ handle: CXHandle) -> CXHandle {
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    handle.encode(with: archiver)
    let data = archiver.encodedData
    do {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        guard let restored = CXHandle(coder: unarchiver) else {
            preconditionFailure("CXHandle decode returned nil")
        }
        return restored
    } catch {
        preconditionFailure("CXHandle unarchive failed: \(error)")
    }
}

func testCXHandleInitTypeAndValue() {
    let handle = CXHandle(type: .phoneNumber, value: "+15551212")
    precondition(handle.type == .phoneNumber)
    precondition(handle.value == "+15551212")
    precondition(type(of: handle) == CXHandle.self)
}

func testCXHandleEqualityAndCopy() {
    let handle = CXHandle(type: .emailAddress, value: "a@b.c")
    let copy = handle.copy() as! CXHandle
    precondition(handle.isEqual(copy))
    precondition(handle.hash == copy.hash)
    precondition(!handle.isEqual(CXHandle(type: .generic, value: "a@b.c")))
    precondition(!handle.isEqual("not-a-handle"))
}

func testCXHandleNSCodingRoundTrip() {
    let original = CXHandle(type: .generic, value: "signal-id")
    let restored = roundTripHandle(original)
    precondition(restored.type == .generic)
    precondition(restored.value == "signal-id")
    precondition(original.isEqual(restored))
}

func testCXHandleNSCodingRejectsUnknownType() {
    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    archiver.encode(99, forKey: "type")
    archiver.encode("x" as NSString, forKey: "value")
    let data = archiver.encodedData
    do {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        precondition(CXHandle(coder: unarchiver) == nil)
    } catch {
        preconditionFailure("unexpected decode error \(error)")
    }
}

func testCXCallUpdateCopyAndProperties() {
    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .phoneNumber, value: "+1")
    update.localizedCallerName = "Ada"
    update.hasVideo = true
    update.supportsDTMF = false
    update.supportsGrouping = false
    update.supportsHolding = false
    update.supportsUngrouping = false
    let copy = update.copy() as! CXCallUpdate
    precondition(copy.localizedCallerName == "Ada")
    precondition(copy.hasVideo)
    precondition(copy.remoteHandle?.value == "+1")
    precondition(!copy.supportsDTMF)
    precondition(!copy.supportsGrouping)
    precondition(!copy.supportsHolding)
    precondition(!copy.supportsUngrouping)
    precondition(type(of: update) == CXCallUpdate.self)
}
