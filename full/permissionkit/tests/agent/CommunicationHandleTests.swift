import Foundation
import PermissionKit

func testCommunicationHandleInitValueAndKind() {
    let handle = CommunicationHandle(value: "+15555550100", kind: .phoneNumber)
    precondition(handle.value == "+15555550100")
    precondition(handle.kind == .phoneNumber)
}

func testCommunicationHandleEquality() {
    let a = CommunicationHandle(value: "user@example.com", kind: .emailAddress)
    let b = CommunicationHandle(value: "user@example.com", kind: .emailAddress)
    precondition(a == b)
}

func testCommunicationHandleInequality() {
    let phone = CommunicationHandle(value: "1", kind: .phoneNumber)
    let email = CommunicationHandle(value: "1", kind: .emailAddress)
    precondition(phone != email)
    precondition(!(phone == email))
}

func testCommunicationHandleHashable() {
    let handle = CommunicationHandle(value: "game:alice", kind: .custom)
    var hasherA = Hasher()
    var hasherB = Hasher()
    handle.hash(into: &hasherA)
    handle.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(handle.hashValue == handle.hashValue)
}

func testCommunicationHandleCodableRoundTrip() {
    let handle = CommunicationHandle(value: "custom-id", kind: .custom)
    let encoded = try! JSONEncoder().encode(handle)
    let restored = try! JSONDecoder().decode(CommunicationHandle.self, from: encoded)
    precondition(restored == handle)
}

func testCommunicationHandleKindCases() {
    let kinds: [CommunicationHandle.Kind] = [.phoneNumber, .emailAddress, .custom]
    precondition(kinds.count == 3)
    precondition(CommunicationHandle.Kind.phoneNumber != .emailAddress)
    precondition(CommunicationHandle.Kind.emailAddress != .custom)
    precondition(CommunicationHandle.Kind.custom != .phoneNumber)
}

func testCommunicationHandleKindInequality() {
    precondition(CommunicationHandle.Kind.phoneNumber != .custom)
    precondition(CommunicationHandle.Kind.phoneNumber == .phoneNumber)
}

func testCommunicationHandleKindHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    CommunicationHandle.Kind.emailAddress.hash(into: &hasherA)
    CommunicationHandle.Kind.emailAddress.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(CommunicationHandle.Kind.custom.hashValue == CommunicationHandle.Kind.custom.hashValue)
}

func testCommunicationHandleKindCodableRoundTrip() {
    let encoded = try! JSONEncoder().encode(CommunicationHandle.Kind.phoneNumber)
    let restored = try! JSONDecoder().decode(CommunicationHandle.Kind.self, from: encoded)
    precondition(restored == .phoneNumber)
}

func testCommunicationHandleKindMutation() {
    var handle = CommunicationHandle(value: "x", kind: .custom)
    handle.kind = .emailAddress
    handle.value = "y@z.example"
    precondition(handle.kind == .emailAddress)
    precondition(handle.value == "y@z.example")
}
