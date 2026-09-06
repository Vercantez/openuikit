import Foundation
import SystemExtensions

func testOSSystemExtensionErrorType() {
    let error = OSSystemExtensionError(.unknown)
    precondition(type(of: error) == OSSystemExtensionError.self)
    let asError: any Error = error
    precondition(asError is OSSystemExtensionError)
}

func testOSSystemExtensionErrorInitUserInfo() {
    let empty = OSSystemExtensionError(.unknown)
    precondition(empty.code == .unknown)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(empty.errorCode == 1)
    precondition(!empty.userInfo.keys.contains(NSLocalizedDescriptionKey))
    precondition(!empty.errorUserInfo.keys.contains(NSLocalizedDescriptionKey))

    let sentinel = OSSystemExtensionError(
        .missingEntitlement,
        userInfo: ["sentinel": "value"]
    )
    precondition(sentinel.code == .missingEntitlement)
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.userInfo.count == 1)
    precondition(sentinel.errorUserInfo.count == 1)
    precondition(!sentinel.userInfo.keys.contains(NSLocalizedDescriptionKey))
    precondition(sentinel.errorCode == OSSystemExtensionError.Code.missingEntitlement.rawValue)
}

func testOSSystemExtensionErrorCustomNSErrorDomain() {
    precondition(OSSystemExtensionError.errorDomain == "OSSystemExtensionErrorDomain")
    precondition(OSSystemExtensionError.errorDomain == OSSystemExtensionErrorDomain)
    let ns = OSSystemExtensionError(.missingEntitlement) as NSError
    precondition(ns.domain == OSSystemExtensionError.errorDomain)
}

func testOSSystemExtensionErrorStructErrorDomain() {
    precondition(OSSystemExtensionError.errorDomain == OSSystemExtensionErrorDomain)
    precondition(OSSystemExtensionError.errorDomain == "OSSystemExtensionErrorDomain")
}

func testOSSystemExtensionErrorCustomNSErrorUserInfo() {
    let sentinel = OSSystemExtensionError(
        .codeSignatureInvalid,
        userInfo: ["sentinel": "value"]
    )
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition((sentinel as NSError).userInfo["sentinel"] as? String == "value")
}

func testOSSystemExtensionErrorCustomNSErrorCode() {
    let error = OSSystemExtensionError(.forbiddenBySystemPolicy)
    precondition(error.errorCode == 10)
    precondition(error.errorCode == OSSystemExtensionError.Code.forbiddenBySystemPolicy.rawValue)
    let ns = error as NSError
    precondition(ns.code == 10)
}

func testOSSystemExtensionErrorBridgedErrorUserInfo() {
    let sentinel = OSSystemExtensionError(
        .requestCanceled,
        userInfo: ["sentinel": "value"]
    )
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo.count == 1)
    precondition(!sentinel.errorUserInfo.keys.contains(NSLocalizedDescriptionKey))
}

func testOSSystemExtensionErrorUserInfo() {
    let sentinel = OSSystemExtensionError(
        .requestSuperseded,
        userInfo: ["k": 7]
    )
    precondition(sentinel.userInfo["k"] as? Int == 7)
    precondition(sentinel.userInfo.count == 1)
    let empty = OSSystemExtensionError(.unknown)
    precondition(empty.userInfo.isEmpty)
}

func testOSSystemExtensionErrorCodeProperty() {
    let error = OSSystemExtensionError(.extensionNotFound, userInfo: ["x": 1])
    precondition(error.code == .extensionNotFound)
    precondition(error.code.rawValue == 4)
}

func testOSSystemExtensionErrorBridgedErrorCode() {
    let error = OSSystemExtensionError(.authorizationRequired)
    precondition(error.errorCode == 13)
    precondition((error as NSError).code == OSSystemExtensionError.authorizationRequired.rawValue)
}

func testOSSystemExtensionErrorEquality() {
    let empty = OSSystemExtensionError(.unknown)
    let emptyAgain = OSSystemExtensionError(.unknown)
    precondition(empty == emptyAgain)
    precondition(!(empty != emptyAgain))

    let sentinel = OSSystemExtensionError(.unknown, userInfo: ["sentinel": "value"])
    precondition(sentinel != empty)
    precondition(!(sentinel == empty))
    precondition(empty != OSSystemExtensionError(.missingEntitlement))
    precondition(
        OSSystemExtensionError(.unknown, userInfo: ["sentinel": "a"]) !=
            OSSystemExtensionError(.unknown, userInfo: ["sentinel": "b"])
    )

    let intOne = OSSystemExtensionError(.validationFailed, userInfo: ["x": 1])
    let stringOne = OSSystemExtensionError(.validationFailed, userInfo: ["x": "1"])
    precondition(intOne != stringOne)
}

func testOSSystemExtensionErrorInequality() {
    precondition(OSSystemExtensionError(.unknown) != OSSystemExtensionError(.missingEntitlement))
    precondition(
        OSSystemExtensionError(.codeSignatureInvalid, userInfo: ["a": 1])
            != OSSystemExtensionError(.codeSignatureInvalid)
    )
    let same = OSSystemExtensionError(.requestCanceled)
    precondition(!(same != OSSystemExtensionError(.requestCanceled)))
}

func testOSSystemExtensionErrorHashInto() {
    let empty = OSSystemExtensionError(.forbiddenBySystemPolicy)
    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    OSSystemExtensionError(.forbiddenBySystemPolicy).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testOSSystemExtensionErrorHashValue() {
    let empty = OSSystemExtensionError(.unknown)
    let sentinel = OSSystemExtensionError(.unknown, userInfo: ["sentinel": "value"])
    precondition(empty.hashValue == sentinel.hashValue)

    let values = [
        OSSystemExtensionError(.extensionMissingIdentifier),
        OSSystemExtensionError(.extensionMissingIdentifier, userInfo: ["x": 1]),
        OSSystemExtensionError(.extensionMissingIdentifier, userInfo: ["x": "1"]),
    ]
    precondition(Set(values.map(\.hashValue)).count == 1)
    precondition(values[0] != values[1])
    precondition(values[1] != values[2])
}

func testOSSystemExtensionErrorLocalizedDescription() {
    let error = OSSystemExtensionError(.unknown)
    precondition(!error.localizedDescription.isEmpty)
    let ns = error as NSError
    precondition(!ns.localizedDescription.isEmpty)
}
