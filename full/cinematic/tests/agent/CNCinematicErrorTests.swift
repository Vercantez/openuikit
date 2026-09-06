import Foundation
import Cinematic

func testCNCinematicErrorDomain() {
    precondition(CNCinematicErrorDomain == "CNCinematicErrorDomain")
    precondition(CNCinematicError.errorDomain == "CNCinematicErrorDomain")
    precondition(CNCinematicError.errorDomain == CNCinematicErrorDomain)
}

func testCNCinematicErrorCodeRawValues() {
    typealias Code = CNCinematicError.Code
    precondition(Code.unknown.rawValue == 1)
    precondition(Code.unreadable.rawValue == 2)
    precondition(Code.incomplete.rawValue == 3)
    precondition(Code.malformed.rawValue == 4)
    precondition(Code.unsupported.rawValue == 5)
    precondition(Code.incompatible.rawValue == 6)
    precondition(Code.cancelled.rawValue == 7)
    precondition(Code(rawValue: 1) == .unknown)
    precondition(Code(rawValue: 2) == .unreadable)
    precondition(Code(rawValue: 3) == .incomplete)
    precondition(Code(rawValue: 4) == .malformed)
    precondition(Code(rawValue: 5) == .unsupported)
    precondition(Code(rawValue: 6) == .incompatible)
    precondition(Code(rawValue: 7) == .cancelled)
    precondition(Code(rawValue: 0) == nil)
    precondition(Code(rawValue: 8) == nil)
}

func testCNCinematicErrorStaticCodeAliases() {
    precondition(CNCinematicError.unknown == CNCinematicError.Code.unknown)
    precondition(CNCinematicError.unreadable == CNCinematicError.Code.unreadable)
    precondition(CNCinematicError.incomplete == CNCinematicError.Code.incomplete)
    precondition(CNCinematicError.malformed == CNCinematicError.Code.malformed)
    precondition(CNCinematicError.unsupported == CNCinematicError.Code.unsupported)
    precondition(CNCinematicError.incompatible == CNCinematicError.Code.incompatible)
    precondition(CNCinematicError.cancelled == CNCinematicError.Code.cancelled)
}

func testCNCinematicErrorInitUserInfoAndCustomNSError() {
    let empty = CNCinematicError(.unsupported)
    precondition(empty.code == .unsupported)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(empty.errorCode == 5)
    precondition(!empty.userInfo.keys.contains(NSLocalizedDescriptionKey))

    let sentinel = CNCinematicError(.malformed, userInfo: ["sentinel": "value"])
    precondition(sentinel.code == .malformed)
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorCode == 4)
}

func testCNCinematicErrorEquality() {
    let empty = CNCinematicError(.unsupported)
    precondition(empty == CNCinematicError(.unsupported))
    precondition(!(empty != CNCinematicError(.unsupported)))
    precondition(empty != CNCinematicError(.cancelled))
    precondition(
        CNCinematicError(.unsupported, userInfo: ["x": 1]) !=
            CNCinematicError(.unsupported)
    )
}

func testCNCinematicErrorHashable() {
    let empty = CNCinematicError(.unsupported)
    let sentinel = CNCinematicError(.unsupported, userInfo: ["sentinel": "value"])
    precondition(empty.hashValue == sentinel.hashValue)
    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    CNCinematicError(.unsupported).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testCNCinematicErrorCodeHashable() {
    var hasher = Hasher()
    CNCinematicError.Code.unsupported.hash(into: &hasher)
    CNCinematicError.Code.cancelled.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(CNCinematicError.Code.unknown.hashValue == CNCinematicError.Code.unknown.hashValue)
    precondition(CNCinematicError.Code.unknown.hashValue != CNCinematicError.Code.cancelled.hashValue)
}

func testCNCinematicErrorCodePatternMatch() {
    let error: any Error = CNCinematicError(.cancelled)
    precondition(CNCinematicError.Code.cancelled ~= error)
    precondition(!(CNCinematicError.Code.unsupported ~= error))
    precondition(!(CNCinematicError.Code.cancelled ~= NSError(domain: "x", code: 7)))
}

func testCNCinematicErrorLocalizedDescription() {
    let description = CNCinematicError(.unreadable).localizedDescription
    precondition(!description.isEmpty)
}
