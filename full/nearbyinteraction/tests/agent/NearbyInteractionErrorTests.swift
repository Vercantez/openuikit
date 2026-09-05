import Foundation
import NearbyInteraction

func testNIErrorDomain() {
    precondition(NIErrorDomain == "NIErrorDomain")
    precondition(NIError.errorDomain == NIErrorDomain)
    precondition(NIError._nsErrorDomain == NIErrorDomain)
}

func testNIErrorCodes() {
    precondition(NIError.Code.unsupportedPlatform.rawValue == -5889)
    precondition(NIError.Code.invalidConfiguration.rawValue == -5888)
    precondition(NIError.Code.sessionFailed.rawValue == -5887)
    precondition(NIError.Code.resourceUsageTimeout.rawValue == -5886)
    precondition(NIError.Code.activeSessionsLimitExceeded.rawValue == -5885)
    precondition(NIError.Code.userDidNotAllow.rawValue == -5884)
    precondition(NIError.Code.invalidARConfiguration.rawValue == -5883)
    precondition(NIError.Code.accessoryPeerDeviceUnavailable.rawValue == -5882)
    precondition(NIError.Code.incompatiblePeerDevice.rawValue == -5881)
    precondition(NIError.Code.activeExtendedDistanceSessionsLimitExceeded.rawValue == -5880)

    precondition(NIError.unsupportedPlatform == .unsupportedPlatform)
    precondition(NIError.invalidConfiguration == .invalidConfiguration)
    precondition(NIError.sessionFailed == .sessionFailed)
    precondition(NIError.resourceUsageTimeout == .resourceUsageTimeout)
    precondition(NIError.activeSessionsLimitExceeded == .activeSessionsLimitExceeded)
    precondition(NIError.userDidNotAllow == .userDidNotAllow)
    precondition(NIError.invalidARConfiguration == .invalidARConfiguration)
    precondition(NIError.accessoryPeerDeviceUnavailable == .accessoryPeerDeviceUnavailable)
    precondition(NIError.incompatiblePeerDevice == .incompatiblePeerDevice)
    precondition(
        NIError.activeExtendedDistanceSessionsLimitExceeded
            == .activeExtendedDistanceSessionsLimitExceeded
    )

    precondition(NIError.Code(rawValue: -5889) == .unsupportedPlatform)
    precondition(NIError.Code(rawValue: -5880) == .activeExtendedDistanceSessionsLimitExceeded)
    precondition(NIError.Code(rawValue: 0) == nil)
    precondition(NIError.Code.unsupportedPlatform != .invalidConfiguration)
}

func testNIErrorConstructionAndUserInfo() {
    let empty = NIError(.sessionFailed)
    precondition(empty.code == .sessionFailed)
    precondition(empty.errorCode == -5887)
    precondition(empty.errorDomain == NIErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)

    let sentinel = NIError(.userDidNotAllow, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .userDidNotAllow)
    precondition(sentinel.errorCode == NIError.Code.userDidNotAllow.rawValue)
}

func testNIErrorEqualityAndHash() {
    let a = NIError(.unsupportedPlatform)
    let b = NIError(.unsupportedPlatform)
    let c = NIError(.invalidConfiguration)
    precondition(a == b)
    precondition(a != c)

    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testNIErrorCodePatternMatch() {
    let typed = NIError(.resourceUsageTimeout)
    precondition(NIError.Code.resourceUsageTimeout ~= typed)

    let ns = typed as NSError
    precondition(ns.domain == NIErrorDomain)
    precondition(ns.code == -5886)
    precondition(NIError.Code.resourceUsageTimeout ~= ns)
    precondition(!(NIError.Code.sessionFailed ~= typed))
}

func testNIErrorCodeHash() {
    let code = NIError.Code.invalidARConfiguration
    var hasherA = Hasher()
    var hasherB = Hasher()
    code.hash(into: &hasherA)
    NIError.Code.invalidARConfiguration.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(code.hashValue == NIError.Code.invalidARConfiguration.hashValue)
    precondition(code != .incompatiblePeerDevice)
}
