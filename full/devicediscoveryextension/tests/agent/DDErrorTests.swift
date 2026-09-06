import DeviceDiscoveryExtension
import Foundation

func testDDErrorDomain() {
    ddExpect(DDErrorDomain == "DDErrorDomain", "DDErrorDomain token")
    ddExpect(DDError.errorDomain == DDErrorDomain, "CustomNSError.errorDomain")
    ddExpect(DDError._nsErrorDomain == DDErrorDomain, "_nsErrorDomain")
}

func testDDErrorCodeRawValues() {
    ddExpect(DDError.Code.success.rawValue == 0, "success")
    ddExpect(DDError.Code.unknown.rawValue == 350000, "unknown")
    ddExpect(DDError.Code.badParameter.rawValue == 350001, "badParameter")
    ddExpect(DDError.Code.unsupported.rawValue == 350002, "unsupported")
    ddExpect(DDError.Code.timeout.rawValue == 350003, "timeout")
    ddExpect(DDError.Code.internal.rawValue == 350004, "internal")
    ddExpect(DDError.Code.missingEntitlement.rawValue == 350005, "missingEntitlement")
    ddExpect(DDError.Code.permission.rawValue == 350006, "permission")
    ddExpect(DDError.Code.next.rawValue == 350007, "next sentinel")

    ddExpect(DDError.success == .success, "static success")
    ddExpect(DDError.unknown == .unknown, "static unknown")
    ddExpect(DDError.badParameter == .badParameter, "static badParameter")
    ddExpect(DDError.unsupported == .unsupported, "static unsupported")
    ddExpect(DDError.timeout == .timeout, "static timeout")
    ddExpect(DDError.internal == .internal, "static internal")
    ddExpect(DDError.missingEntitlement == .missingEntitlement, "static missingEntitlement")
    ddExpect(DDError.permission == .permission, "static permission")
    ddExpect(DDError.next == .next, "static next")
}

func testDDErrorCodeInitRawValue() {
    ddExpect(DDError.Code(rawValue: 0) == .success, "0")
    ddExpect(DDError.Code(rawValue: 350000) == .unknown, "350000")
    ddExpect(DDError.Code(rawValue: 350006) == .permission, "350006")
    ddExpect(DDError.Code(rawValue: 350007) == .next, "350007")
    ddExpect(DDError.Code(rawValue: 1) == nil, "gap 1")
    ddExpect(DDError.Code(rawValue: 349999) == nil, "below unknown")
}

func testDDErrorCodeHashable() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    DDError.Code.timeout.hash(into: &hasherA)
    DDError.Code.timeout.hash(into: &hasherB)
    ddExpect(hasherA.finalize() == hasherB.finalize(), "hash(into:) stable")
    ddExpect(DDError.Code.timeout.hashValue == DDError.Code.timeout.hashValue, "hashValue")
    ddExpect(DDError.Code.timeout.hashValue != DDError.Code.unknown.hashValue, "distinct codes")
}

func testDDErrorInitUserInfoAndCustomNSError() {
    let empty = DDError(.unsupported)
    ddExpect(empty.code == .unsupported, "code")
    ddExpect(empty.errorCode == 350002, "errorCode")
    ddExpect(empty.userInfo.isEmpty, "empty userInfo")
    ddExpect(empty.errorUserInfo.isEmpty, "empty errorUserInfo")
    ddExpect(!empty.localizedDescription.isEmpty, "localizedDescription")

    let sentinel = DDError(.missingEntitlement, userInfo: ["sentinel": "value"])
    ddExpect(sentinel.userInfo["sentinel"] as? String == "value", "userInfo")
    ddExpect(sentinel.errorUserInfo["sentinel"] as? String == "value", "errorUserInfo")
    ddExpect(sentinel.code == .missingEntitlement, "code from userInfo init")
    ddExpect(sentinel.errorCode == DDError.Code.missingEntitlement.rawValue, "errorCode match")
}

func testDDErrorEqualityAndHash() {
    let a = DDError(.permission)
    let b = DDError(.permission)
    let c = DDError(.timeout)
    ddExpect(a == b, "equal codes")
    ddExpect(!(a != b), "!= inverse")
    ddExpect(a != c, "distinct codes")
    ddExpect(!(a == c), "== inverse")

    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    ddExpect(hasherA.finalize() == hasherB.finalize(), "struct hash(into:)")
    ddExpect(a.hashValue == b.hashValue, "struct hashValue")
}

func testDDErrorCodePatternMatch() {
    let typed = DDError(.timeout)
    ddExpect(DDError.Code.timeout ~= typed, "typed match")
    let ns = typed as NSError
    ddExpect(ns.domain == DDErrorDomain, "NSError domain")
    ddExpect(ns.code == 350003, "NSError code")
    ddExpect(DDError.Code.timeout ~= ns, "NSError match")
    ddExpect(!(DDError.Code.unsupported ~= typed), "mismatch")
}
