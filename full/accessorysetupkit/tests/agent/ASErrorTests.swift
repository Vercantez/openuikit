import AccessorySetupKit
import Foundation

func testASErrorDomain() {
    precondition(ASErrorDomain == "ASErrorDomain")
    precondition(ASError.errorDomain == ASErrorDomain)
    precondition(ASError._nsErrorDomain == ASErrorDomain)
}

func testASErrorCodeRawValues() {
    let cases: [(ASError.Code, Int)] = [
        (.success, 0),
        (.unknown, 1),
        (.activationFailed, 100),
        (.connectionFailed, 150),
        (.discoveryTimeout, 200),
        (.extensionNotFound, 300),
        (.invalidated, 400),
        (.invalidRequest, 450),
        (.pickerAlreadyActive, 500),
        (.pickerRestricted, 550),
        (.userCancelled, 700),
        (.userRestricted, 750),
    ]
    for (code, raw) in cases {
        precondition(code.rawValue == raw)
        precondition(ASError.Code(rawValue: raw) == code)
        _ = code.hashValue
        var hasher = Hasher()
        code.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(ASError.Code(rawValue: 99) == nil)
    precondition(ASError.Code.success != .unknown)
}

func testASErrorStaticCodeAliases() {
    precondition(ASError.success == .success)
    precondition(ASError.unknown == .unknown)
    precondition(ASError.activationFailed == .activationFailed)
    precondition(ASError.connectionFailed == .connectionFailed)
    precondition(ASError.discoveryTimeout == .discoveryTimeout)
    precondition(ASError.extensionNotFound == .extensionNotFound)
    precondition(ASError.invalidated == .invalidated)
    precondition(ASError.invalidRequest == .invalidRequest)
    precondition(ASError.pickerAlreadyActive == .pickerAlreadyActive)
    precondition(ASError.pickerRestricted == .pickerRestricted)
    precondition(ASError.userCancelled == .userCancelled)
    precondition(ASError.userRestricted == .userRestricted)
}

func testASErrorConstruction() {
    let empty = ASError(.pickerRestricted)
    precondition(empty.code == .pickerRestricted)
    precondition(empty.errorCode == 550)
    precondition(ASError.errorDomain == ASErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)

    let sentinel = ASError(.invalidRequest, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .invalidRequest)
    precondition(sentinel.errorCode == ASError.Code.invalidRequest.rawValue)
}

func testASErrorEquality() {
    let a = ASError(.discoveryTimeout)
    let b = ASError(.discoveryTimeout)
    let c = ASError(.connectionFailed)
    precondition(a == b)
    precondition(a != c)
    let withInfo = ASError(.discoveryTimeout, userInfo: ["k": "v"])
    precondition(a != withInfo)
}

func testASErrorHash() {
    let a = ASError(.userCancelled)
    let b = ASError(.userCancelled, userInfo: ["other": 1])
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testASErrorPatternMatch() {
    let typed = ASError(.activationFailed)
    precondition(ASError.Code.activationFailed ~= typed)
    let ns = typed as NSError
    precondition(ns.domain == ASErrorDomain)
    precondition(ns.code == 100)
    precondition(ASError.Code.activationFailed ~= ns)
    precondition(!(ASError.Code.success ~= typed))
}

func testASErrorNSErrorBridge() {
    let typed = ASError(.extensionNotFound, userInfo: ["reason": "missing"])
    let ns = typed as NSError
    precondition(ns.domain == ASError.errorDomain)
    precondition(ns.code == typed.errorCode)
    let roundTrip = ASError(_nsError: ns)
    precondition(roundTrip == typed)
    precondition(roundTrip.code == .extensionNotFound)
}
