import Foundation
import PushToTalk

func testPTChannelErrorDomain() {
    precondition(PTChannelErrorDomain == "PTChannelErrorDomain")
    precondition(PTChannelError.errorDomain == PTChannelErrorDomain)
    precondition(PTChannelError._nsErrorDomain == PTChannelErrorDomain)
}

func testPTInstantiationErrorDomain() {
    precondition(PTInstantiationErrorDomain == "PTInstantiationErrorDomain")
    precondition(PTInstantiationError.errorDomain == PTInstantiationErrorDomain)
    precondition(PTInstantiationError._nsErrorDomain == PTInstantiationErrorDomain)
}

func testPTChannelErrorCodes() {
    precondition(PTChannelError.Code.unknown.rawValue == 0)
    precondition(PTChannelError.Code.channelNotFound.rawValue == 1)
    precondition(PTChannelError.Code.channelLimitReached.rawValue == 2)
    precondition(PTChannelError.Code.callActive.rawValue == 3)
    precondition(PTChannelError.Code.transmissionInProgress.rawValue == 4)
    precondition(PTChannelError.Code.transmissionNotFound.rawValue == 5)
    precondition(PTChannelError.Code.appNotForeground.rawValue == 6)
    precondition(PTChannelError.Code.deviceManagementRestriction.rawValue == 7)
    precondition(PTChannelError.Code.screenTimeRestriction.rawValue == 8)
    precondition(PTChannelError.Code.transmissionNotAllowed.rawValue == 9)

    precondition(PTChannelError.unknown == .unknown)
    precondition(PTChannelError.channelNotFound == .channelNotFound)
    precondition(PTChannelError.channelLimitReached == .channelLimitReached)
    precondition(PTChannelError.callActive == .callActive)
    precondition(PTChannelError.transmissionInProgress == .transmissionInProgress)
    precondition(PTChannelError.transmissionNotFound == .transmissionNotFound)
    precondition(PTChannelError.appNotForeground == .appNotForeground)
    precondition(PTChannelError.deviceManagementRestriction == .deviceManagementRestriction)
    precondition(PTChannelError.screenTimeRestriction == .screenTimeRestriction)
    precondition(PTChannelError.transmissionNotAllowed == .transmissionNotAllowed)

    precondition(PTChannelError.Code(rawValue: 0) == .unknown)
    precondition(PTChannelError.Code(rawValue: 9) == .transmissionNotAllowed)
    precondition(PTChannelError.Code(rawValue: 10) == nil)
    precondition(PTChannelError.Code.unknown != .channelNotFound)
}

func testPTInstantiationErrorCodes() {
    precondition(PTInstantiationError.Code.unknown.rawValue == 0)
    precondition(PTInstantiationError.Code.invalidPlatform.rawValue == 1)
    precondition(PTInstantiationError.Code.missingBackgroundMode.rawValue == 2)
    precondition(PTInstantiationError.Code.missingPushServerEnvironment.rawValue == 3)
    precondition(PTInstantiationError.Code.missingEntitlement.rawValue == 4)
    precondition(PTInstantiationError.Code.instantiationAlreadyInProgress.rawValue == 5)

    precondition(PTInstantiationError.unknown == .unknown)
    precondition(PTInstantiationError.invalidPlatform == .invalidPlatform)
    precondition(PTInstantiationError.missingBackgroundMode == .missingBackgroundMode)
    precondition(PTInstantiationError.missingPushServerEnvironment == .missingPushServerEnvironment)
    precondition(PTInstantiationError.missingEntitlement == .missingEntitlement)
    precondition(PTInstantiationError.instantiationAlreadyInProgress == .instantiationAlreadyInProgress)

    precondition(PTInstantiationError.Code(rawValue: 0) == .unknown)
    precondition(PTInstantiationError.Code(rawValue: 5) == .instantiationAlreadyInProgress)
    precondition(PTInstantiationError.Code(rawValue: 6) == nil)
    precondition(PTInstantiationError.Code.invalidPlatform != .missingEntitlement)
}

func testPTChannelErrorConstructionAndUserInfo() {
    let empty = PTChannelError(.callActive)
    precondition(empty.code == .callActive)
    precondition(empty.errorCode == 3)
    precondition(PTChannelError.errorDomain == PTChannelErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)

    let sentinel = PTChannelError(.appNotForeground, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .appNotForeground)
    precondition(sentinel.errorCode == PTChannelError.Code.appNotForeground.rawValue)
}

func testPTInstantiationErrorConstructionAndUserInfo() {
    let empty = PTInstantiationError(.invalidPlatform)
    precondition(empty.code == .invalidPlatform)
    precondition(empty.errorCode == 1)
    precondition(PTInstantiationError.errorDomain == PTInstantiationErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)

    let sentinel = PTInstantiationError(
        .missingEntitlement,
        userInfo: ["sentinel": "entitlement"]
    )
    precondition(sentinel.userInfo["sentinel"] as? String == "entitlement")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "entitlement")
    precondition(sentinel.code == .missingEntitlement)
    precondition(sentinel.errorCode == PTInstantiationError.Code.missingEntitlement.rawValue)
}

func testPTChannelErrorEqualityAndHash() {
    let a = PTChannelError(.channelNotFound)
    let b = PTChannelError(.channelNotFound)
    let c = PTChannelError(.channelLimitReached)
    precondition(a == b)
    precondition(a != c)

    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testPTInstantiationErrorEqualityAndHash() {
    let a = PTInstantiationError(.invalidPlatform)
    let b = PTInstantiationError(.invalidPlatform)
    let c = PTInstantiationError(.missingBackgroundMode)
    precondition(a == b)
    precondition(a != c)

    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testPTChannelErrorCodePatternMatch() {
    let typed = PTChannelError(.transmissionInProgress)
    precondition(PTChannelError.Code.transmissionInProgress ~= typed)

    let ns = typed as NSError
    precondition(ns.domain == PTChannelErrorDomain)
    precondition(ns.code == 4)
    precondition(PTChannelError.Code.transmissionInProgress ~= ns)
    precondition(!(PTChannelError.Code.channelNotFound ~= typed))
}

func testPTInstantiationErrorCodePatternMatch() {
    let typed = PTInstantiationError(.missingPushServerEnvironment)
    precondition(PTInstantiationError.Code.missingPushServerEnvironment ~= typed)

    let ns = typed as NSError
    precondition(ns.domain == PTInstantiationErrorDomain)
    precondition(ns.code == 3)
    precondition(PTInstantiationError.Code.missingPushServerEnvironment ~= ns)
    precondition(!(PTInstantiationError.Code.invalidPlatform ~= typed))
}

func testPTChannelErrorCodeHash() {
    let code = PTChannelError.Code.screenTimeRestriction
    var hasherA = Hasher()
    var hasherB = Hasher()
    code.hash(into: &hasherA)
    PTChannelError.Code.screenTimeRestriction.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(code.hashValue == PTChannelError.Code.screenTimeRestriction.hashValue)
    precondition(code != .deviceManagementRestriction)
}

func testPTInstantiationErrorCodeHash() {
    let code = PTInstantiationError.Code.instantiationAlreadyInProgress
    var hasherA = Hasher()
    var hasherB = Hasher()
    code.hash(into: &hasherA)
    PTInstantiationError.Code.instantiationAlreadyInProgress.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        code.hashValue == PTInstantiationError.Code.instantiationAlreadyInProgress.hashValue
    )
    precondition(code != .unknown)
}
