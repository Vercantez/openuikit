import Foundation
import SafetyKit

func testSAAuthorizationStatusRawValues() {
    precondition(SAAuthorizationStatus.notDetermined.rawValue == 0)
    precondition(SAAuthorizationStatus.denied.rawValue == 1)
    precondition(SAAuthorizationStatus.authorized.rawValue == 2)
    precondition(SAAuthorizationStatus(rawValue: 0) == .notDetermined)
    precondition(SAAuthorizationStatus(rawValue: 1) == .denied)
    precondition(SAAuthorizationStatus(rawValue: 2) == .authorized)
    precondition(SAAuthorizationStatus(rawValue: 3) == nil)
    precondition(SAAuthorizationStatus(rawValue: -1) == nil)
}

func testSAAuthorizationStatusInequality() {
    precondition(SAAuthorizationStatus.notDetermined != .denied)
    precondition(SAAuthorizationStatus.denied != .authorized)
    precondition(!(SAAuthorizationStatus.authorized != .authorized))
}

func testSAAuthorizationStatusHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    SAAuthorizationStatus.denied.hash(into: &hasherA)
    SAAuthorizationStatus.denied.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(SAAuthorizationStatus.notDetermined.hashValue != SAAuthorizationStatus.authorized.hashValue)

    var set: Set<SAAuthorizationStatus> = []
    set.insert(.notDetermined)
    set.insert(.denied)
    set.insert(.authorized)
    set.insert(.denied)
    precondition(set.count == 3)
}