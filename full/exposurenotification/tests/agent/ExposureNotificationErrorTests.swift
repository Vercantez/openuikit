import Foundation
import ExposureNotification

func testENErrorDomain() {
    precondition(ENErrorDomain == "ENErrorDomain")
    precondition(ENError.errorDomain == ENErrorDomain)
    precondition(ENError._nsErrorDomain == ENErrorDomain)
}

func testENErrorCodeRawValues() {
    precondition(ENError.Code.unknown.rawValue == 1)
    precondition(ENError.Code.badParameter.rawValue == 2)
    precondition(ENError.Code.notEntitled.rawValue == 3)
    precondition(ENError.Code.notAuthorized.rawValue == 4)
    precondition(ENError.Code.unsupported.rawValue == 5)
    precondition(ENError.Code.invalidated.rawValue == 6)
    precondition(ENError.Code.bluetoothOff.rawValue == 7)
    precondition(ENError.Code.insufficientStorage.rawValue == 8)
    precondition(ENError.Code.notEnabled.rawValue == 9)
    precondition(ENError.Code.apiMisuse.rawValue == 10)
    precondition(ENError.Code.internal.rawValue == 11)
    precondition(ENError.Code.insufficientMemory.rawValue == 12)
    precondition(ENError.Code.rateLimited.rawValue == 13)
    precondition(ENError.Code.restricted.rawValue == 14)
    precondition(ENError.Code.badFormat.rawValue == 15)
    precondition(ENError.Code.dataInaccessible.rawValue == 16)
    precondition(ENError.Code.travelStatusNotAvailable.rawValue == 17)

    precondition(ENError.unknown == .unknown)
    precondition(ENError.badParameter == .badParameter)
    precondition(ENError.notEntitled == .notEntitled)
    precondition(ENError.notAuthorized == .notAuthorized)
    precondition(ENError.unsupported == .unsupported)
    precondition(ENError.invalidated == .invalidated)
    precondition(ENError.bluetoothOff == .bluetoothOff)
    precondition(ENError.insufficientStorage == .insufficientStorage)
    precondition(ENError.notEnabled == .notEnabled)
    precondition(ENError.apiMisuse == .apiMisuse)
    precondition(ENError.internal == .internal)
    precondition(ENError.insufficientMemory == .insufficientMemory)
    precondition(ENError.rateLimited == .rateLimited)
    precondition(ENError.restricted == .restricted)
    precondition(ENError.badFormat == .badFormat)
    precondition(ENError.dataInaccessible == .dataInaccessible)
    precondition(ENError.travelStatusNotAvailable == .travelStatusNotAvailable)

    precondition(ENError.Code(rawValue: 1) == .unknown)
    precondition(ENError.Code(rawValue: 17) == .travelStatusNotAvailable)
    precondition(ENError.Code(rawValue: 0) == nil)
    precondition(ENError.Code.unknown != .unsupported)
}

func testENErrorConstructionAndUserInfo() {
    let empty = ENError(.unsupported)
    precondition(empty.code == .unsupported)
    precondition(empty.errorCode == 5)
    precondition(ENError.errorDomain == ENErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo.isEmpty || empty.userInfo[NSLocalizedDescriptionKey] != nil)

    let sentinel = ENError(.notEntitled, userInfo: ["sentinel": "value"])
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .notEntitled)
    precondition(sentinel.errorCode == ENError.Code.notEntitled.rawValue)
}

func testENErrorEqualityAndHash() {
    let a = ENError(.unsupported)
    let b = ENError(.unsupported)
    let c = ENError(.notAuthorized)
    precondition(a == b)
    precondition(a != c)

    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testENErrorCodePatternMatch() {
    let typed = ENError(.travelStatusNotAvailable)
    precondition(ENError.Code.travelStatusNotAvailable ~= typed)

    let ns = typed as NSError
    precondition(ns.domain == ENErrorDomain)
    precondition(ns.code == 17)
    precondition(ENError.Code.travelStatusNotAvailable ~= ns)
    precondition(!(ENError.Code.unsupported ~= typed))
}

func testENErrorCodeHash() {
    let a = ENError.Code.unsupported
    let b = ENError.Code.unsupported
    precondition(a.hashValue == b.hashValue)
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(a != .invalidated)
}
