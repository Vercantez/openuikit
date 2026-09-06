import Foundation
import Accessibility

func testFeatureOverrideErrorCodes() {
    precondition(AXFeatureOverrideSessionErrorDomain == "AXFeatureOverrideSessionErrorDomain")
    precondition(AXFeatureOverrideSessionError.errorDomain == AXFeatureOverrideSessionErrorDomain)
    precondition(AXFeatureOverrideSessionError._nsErrorDomain == AXFeatureOverrideSessionErrorDomain)
    precondition(AXFeatureOverrideSessionError.Code.undefined.rawValue == 0)
    precondition(AXFeatureOverrideSessionError.Code.appNotEntitled.rawValue == 1)
    precondition(AXFeatureOverrideSessionError.Code.overrideIsAlreadyActive.rawValue == 2)
    precondition(AXFeatureOverrideSessionError.Code.overrideNotFoundForUUID.rawValue == 3)
    precondition(AXFeatureOverrideSessionError.undefined == .undefined)
    precondition(AXFeatureOverrideSessionError.appNotEntitled == .appNotEntitled)
    precondition(AXFeatureOverrideSessionError.overrideIsAlreadyActive == .overrideIsAlreadyActive)
    precondition(AXFeatureOverrideSessionError.overrideNotFoundForUUID == .overrideNotFoundForUUID)
    precondition(AXFeatureOverrideSessionError.Code(rawValue: 0) == .undefined)
    precondition(AXFeatureOverrideSessionError.Code(rawValue: 3) == .overrideNotFoundForUUID)
    precondition(AXFeatureOverrideSessionError.Code(rawValue: 99) == nil)
    precondition(AXFeatureOverrideSessionError.Code.undefined != .appNotEntitled)
}

func testFeatureOverrideErrorConstruction() {
    let empty = AXFeatureOverrideSessionError(.undefined)
    precondition(empty.code == .undefined)
    precondition(empty.errorCode == 0)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.errorUserInfo.isEmpty || empty.userInfo[NSLocalizedDescriptionKey] != nil)

    let sentinel = AXFeatureOverrideSessionError(.appNotEntitled, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .appNotEntitled)
    precondition(sentinel.errorCode == AXFeatureOverrideSessionError.Code.appNotEntitled.rawValue)

    let a = AXFeatureOverrideSessionError(.overrideIsAlreadyActive)
    let b = AXFeatureOverrideSessionError(.overrideIsAlreadyActive)
    let c = AXFeatureOverrideSessionError(.overrideNotFoundForUUID)
    precondition(a == b)
    precondition(a != c)
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)

    precondition(AXFeatureOverrideSessionError.Code.overrideIsAlreadyActive ~= a)
    let ns = a as NSError
    precondition(ns.domain == AXFeatureOverrideSessionErrorDomain)
    precondition(ns.code == 2)
    precondition(AXFeatureOverrideSessionError.Code.overrideIsAlreadyActive ~= ns)
    precondition(!(AXFeatureOverrideSessionError.Code.appNotEntitled ~= a))

    var codeHasherA = Hasher()
    var codeHasherB = Hasher()
    AXFeatureOverrideSessionError.Code.overrideNotFoundForUUID.hash(into: &codeHasherA)
    AXFeatureOverrideSessionError.Code.overrideNotFoundForUUID.hash(into: &codeHasherB)
    precondition(codeHasherA.finalize() == codeHasherB.finalize())
    precondition(
        AXFeatureOverrideSessionError.Code.overrideNotFoundForUUID.hashValue
            == AXFeatureOverrideSessionError.Code.overrideNotFoundForUUID.hashValue
    )
}
