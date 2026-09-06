import Foundation
import LiveCommunicationKit

func testHandleKindRawValues() {
    precondition(Handle.Kind.generic.rawValue == 0)
    precondition(Handle.Kind.phoneNumber.rawValue == 1)
    precondition(Handle.Kind.emailAddress.rawValue == 2)
    precondition(Handle.Kind(rawValue: 0) == .generic)
    precondition(Handle.Kind(rawValue: 1) == .phoneNumber)
    precondition(Handle.Kind(rawValue: 2) == .emailAddress)
    precondition(Handle.Kind(rawValue: 3) == nil)
    precondition(Handle.Kind.generic != .phoneNumber)
    precondition(Handle.Kind.phoneNumber != .emailAddress)
}

func testHandleKindRawValueTypealias() {
    let raw: Handle.Kind.RawValue = Handle.Kind.phoneNumber.rawValue
    precondition(raw == 1)
    precondition(type(of: raw) == Int.self)
}

func testHandleInitStoresTypeValueAndDisplayName() {
    let handle = Handle(type: .phoneNumber, value: "+15551212", displayName: "Ada")
    precondition(handle.type == .phoneNumber)
    precondition(handle.value == "+15551212")
    precondition(handle.displayName == "Ada")
}

func testHandleDisplayNameDefaultsToValue() {
    let handle = Handle(type: .emailAddress, value: "a@b.c")
    precondition(handle.displayName == "a@b.c")
    let explicitNil = Handle(type: .generic, value: "signal", displayName: nil)
    precondition(explicitNil.displayName == "signal")
}

func testHandleEqualityAndInequality() {
    let a = Handle(type: .generic, value: "x", displayName: "X")
    let b = Handle(type: .generic, value: "x", displayName: "X")
    let c = Handle(type: .generic, value: "y", displayName: "X")
    precondition(a == b)
    precondition(a != c)
    precondition(!(a != b))
}

func testHandleHashableConsistency() {
    let handle = Handle(type: .phoneNumber, value: "+1")
    var hasherA = Hasher()
    var hasherB = Hasher()
    handle.hash(into: &hasherA)
    handle.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(handle.hashValue == handle.hashValue)
    var set = Set<Handle>()
    set.insert(handle)
    set.insert(Handle(type: .phoneNumber, value: "+1"))
    precondition(set.count == 1)
}

func testHandleCodableRoundTrip() {
    let original = Handle(type: .emailAddress, value: "a@b.c", displayName: "Ada")
    let data = try! JSONEncoder().encode(original)
    let restored = try! JSONDecoder().decode(Handle.self, from: data)
    precondition(restored == original)
    precondition(restored.type == .emailAddress)
    precondition(restored.displayName == "Ada")
}

func testHandleKindCodableRoundTrip() {
    let data = try! JSONEncoder().encode(Handle.Kind.phoneNumber)
    let restored = try! JSONDecoder().decode(Handle.Kind.self, from: data)
    precondition(restored == .phoneNumber)
    let fromRaw = Handle.Kind(rawValue: restored.rawValue)
    precondition(fromRaw == .phoneNumber)
    var hasherA = Hasher()
    var hasherB = Hasher()
    Handle.Kind.emailAddress.hash(into: &hasherA)
    Handle.Kind.emailAddress.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(Handle.Kind.generic.hashValue == Handle.Kind.generic.hashValue)
}
