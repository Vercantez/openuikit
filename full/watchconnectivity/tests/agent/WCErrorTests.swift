import Foundation
import WatchConnectivity

func testWCErrorCodeRawValues() {
    let expected: [(WCError.Code, Int)] = [
        (.genericError, 7001),
        (.sessionNotSupported, 7002),
        (.sessionMissingDelegate, 7003),
        (.sessionNotActivated, 7004),
        (.deviceNotPaired, 7005),
        (.watchAppNotInstalled, 7006),
        (.notReachable, 7007),
        (.invalidParameter, 7008),
        (.payloadTooLarge, 7009),
        (.payloadUnsupportedTypes, 7010),
        (.messageReplyFailed, 7011),
        (.messageReplyTimedOut, 7012),
        (.fileAccessDenied, 7013),
        (.deliveryFailed, 7014),
        (.insufficientSpace, 7015),
        (.sessionInactive, 7016),
        (.transferTimedOut, 7017),
        (.companionAppNotInstalled, 7018),
        (.watchOnlyApp, 7019),
    ]
    for (code, raw) in expected {
        precondition(code.rawValue == raw)
        precondition(WCError.Code(rawValue: raw) == code)
    }
    precondition(WCError.Code(rawValue: 0) == nil)
    precondition(WCError.Code(rawValue: 7000) == nil)
    precondition(WCError.Code(rawValue: 7020) == nil)
}

func testWCErrorStaticCodeAliases() {
    precondition(WCError.genericError == WCError.Code.genericError)
    precondition(WCError.sessionNotSupported == WCError.Code.sessionNotSupported)
    precondition(WCError.sessionMissingDelegate == WCError.Code.sessionMissingDelegate)
    precondition(WCError.sessionNotActivated == WCError.Code.sessionNotActivated)
    precondition(WCError.deviceNotPaired == WCError.Code.deviceNotPaired)
    precondition(WCError.watchAppNotInstalled == WCError.Code.watchAppNotInstalled)
    precondition(WCError.notReachable == WCError.Code.notReachable)
    precondition(WCError.invalidParameter == WCError.Code.invalidParameter)
    precondition(WCError.payloadTooLarge == WCError.Code.payloadTooLarge)
    precondition(WCError.payloadUnsupportedTypes == WCError.Code.payloadUnsupportedTypes)
    precondition(WCError.messageReplyFailed == WCError.Code.messageReplyFailed)
    precondition(WCError.messageReplyTimedOut == WCError.Code.messageReplyTimedOut)
    precondition(WCError.fileAccessDenied == WCError.Code.fileAccessDenied)
    precondition(WCError.deliveryFailed == WCError.Code.deliveryFailed)
    precondition(WCError.insufficientSpace == WCError.Code.insufficientSpace)
    precondition(WCError.sessionInactive == WCError.Code.sessionInactive)
    precondition(WCError.transferTimedOut == WCError.Code.transferTimedOut)
    precondition(WCError.companionAppNotInstalled == WCError.Code.companionAppNotInstalled)
    precondition(WCError.watchOnlyApp == WCError.Code.watchOnlyApp)
}

func testWCErrorDomain() {
    precondition(WCErrorDomain == "WCErrorDomain")
    precondition(WCError.errorDomain == WCErrorDomain)
    let bridged = WCError(.sessionNotSupported) as NSError
    precondition(bridged.domain == WCErrorDomain)
    precondition(bridged.domain == WCError.errorDomain)
}

func testWCErrorInitUserInfoAndCustomNSError() {
    let empty = WCError(.sessionNotSupported)
    precondition(empty.code == .sessionNotSupported)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(empty.errorCode == 7002)
    precondition(!empty.userInfo.keys.contains(NSLocalizedDescriptionKey))
    precondition(!empty.errorUserInfo.keys.contains(NSLocalizedDescriptionKey))

    let sentinel = WCError(.invalidParameter, userInfo: ["sentinel": 7008])
    precondition(sentinel.code == .invalidParameter)
    precondition(sentinel.userInfo["sentinel"] as? Int == 7008)
    precondition(sentinel.errorUserInfo["sentinel"] as? Int == 7008)
    precondition(sentinel.userInfo.count == 1)
    precondition(sentinel.errorUserInfo.count == 1)
    precondition(sentinel.errorCode == WCError.Code.invalidParameter.rawValue)
    precondition(
        NSDictionary(dictionary: sentinel.errorUserInfo).isEqual(
            NSDictionary(dictionary: sentinel.userInfo)
        )
    )
}

func testWCErrorEquality() {
    let empty = WCError(.sessionNotSupported)
    precondition(empty == WCError(.sessionNotSupported))
    precondition(!(empty != WCError(.sessionNotSupported)))
    precondition(empty != WCError(.genericError))
    precondition(
        WCError(.sessionNotSupported, userInfo: ["k": 1]) !=
            WCError(.sessionNotSupported)
    )
    let intOne = WCError(.invalidParameter, userInfo: ["x": 1])
    let stringOne = WCError(.invalidParameter, userInfo: ["x": "1"])
    precondition(intOne != stringOne)
    precondition(
        WCError(.invalidParameter, userInfo: ["x": 1]) ==
            WCError(.invalidParameter, userInfo: ["x": 1])
    )
}

func testWCErrorHashable() {
    let empty = WCError(.fileAccessDenied)
    let sentinel = WCError(.fileAccessDenied, userInfo: ["k": true])
    precondition(empty.hashValue == sentinel.hashValue)

    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    WCError(.fileAccessDenied).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testWCErrorCodeHashable() {
    var hasher = Hasher()
    WCError.Code.sessionNotSupported.hash(into: &hasher)
    WCError.Code.notReachable.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(WCError.Code.genericError.hashValue == WCError.Code.genericError.hashValue)
    precondition(WCError.Code.genericError.hashValue != WCError.Code.watchOnlyApp.hashValue)

    var set: Set<WCError.Code> = []
    set.insert(.genericError)
    set.insert(.sessionNotSupported)
    set.insert(.genericError)
    precondition(set.count == 2)
    precondition(set.contains(.sessionNotSupported))
}

func testWCErrorCodePatternMatch() {
    let error: any Error = WCError(.sessionNotSupported)
    precondition(WCError.Code.sessionNotSupported ~= error)
    precondition(!(WCError.Code.notReachable ~= error))
    precondition(!(WCError.Code.sessionNotSupported ~= NSError(domain: "x", code: 7002)))
}

func testWCErrorLocalizedDescription() {
    let description = WCError(.sessionNotSupported).localizedDescription
    precondition(!description.isEmpty)
}
