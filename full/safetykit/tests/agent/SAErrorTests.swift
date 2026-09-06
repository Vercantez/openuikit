import Foundation
import SafetyKit

func testSAErrorDomain() {
    precondition(SAErrorDomain == "SAErrorDomain")
    precondition(SAError.errorDomain == "SAErrorDomain")
    precondition(SAError.errorDomain == SAErrorDomain)
}

func testSAErrorCodeRawValues() {
    typealias Code = SAError.Code
    precondition(Code.notAuthorized.rawValue == 1)
    precondition(Code.notAllowed.rawValue == 2)
    precondition(Code.invalidArgument.rawValue == 3)
    precondition(Code.operationFailed.rawValue == 4)
    precondition(Code(rawValue: 1) == .notAuthorized)
    precondition(Code(rawValue: 2) == .notAllowed)
    precondition(Code(rawValue: 3) == .invalidArgument)
    precondition(Code(rawValue: 4) == .operationFailed)
    precondition(Code(rawValue: 0) == nil)
    precondition(Code(rawValue: 5) == nil)
    precondition(Code(rawValue: -1) == nil)
}

func testSAErrorStaticCodeAliases() {
    precondition(SAError.notAuthorized == SAError.Code.notAuthorized)
    precondition(SAError.notAllowed == SAError.Code.notAllowed)
    precondition(SAError.invalidArgument == SAError.Code.invalidArgument)
    precondition(SAError.operationFailed == SAError.Code.operationFailed)
}

func testSAErrorInitUserInfoAndCustomNSError() {
    let empty = SAError(.notAllowed)
    precondition(empty.code == .notAllowed)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(empty.errorCode == 2)
    precondition(!empty.userInfo.keys.contains(NSLocalizedDescriptionKey))
    precondition(!empty.errorUserInfo.keys.contains(NSLocalizedDescriptionKey))

    let sentinel = SAError(
        .invalidArgument,
        userInfo: ["sentinel": "value"]
    )
    precondition(sentinel.code == .invalidArgument)
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.userInfo.count == 1)
    precondition(sentinel.errorUserInfo.count == 1)
    precondition(!sentinel.userInfo.keys.contains(NSLocalizedDescriptionKey))
    precondition(sentinel.errorCode == SAError.Code.invalidArgument.rawValue)
}

func testSAErrorErrorCodeMatchesRawValue() {
    precondition(SAError(.notAuthorized).errorCode == 1)
    precondition(SAError(.operationFailed).errorCode == SAError.Code.operationFailed.rawValue)
}

func testSAErrorEquality() {
    let empty = SAError(.notAllowed)
    let emptyAgain = SAError(.notAllowed)
    precondition(empty == emptyAgain)
    precondition(!(empty != emptyAgain))

    let sentinel = SAError(.notAllowed, userInfo: ["sentinel": "value"])
    precondition(sentinel != empty)
    precondition(!(sentinel == empty))
    precondition(empty != SAError(.invalidArgument))
    precondition(
        SAError(.notAllowed, userInfo: ["sentinel": "a"]) !=
            SAError(.notAllowed, userInfo: ["sentinel": "b"])
    )

    let intOne = SAError(.invalidArgument, userInfo: ["x": 1])
    let stringOne = SAError(.invalidArgument, userInfo: ["x": "1"])
    precondition(intOne != stringOne)
}

func testSAErrorHashable() {
    let empty = SAError(.notAllowed)
    let sentinel = SAError(.notAllowed, userInfo: ["sentinel": "value"])
    precondition(empty.hashValue == sentinel.hashValue)

    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    SAError(.notAllowed).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())

    let sameCode = [
        SAError(.invalidArgument),
        SAError(.invalidArgument, userInfo: ["x": 1]),
        SAError(.invalidArgument, userInfo: ["x": "1"]),
    ]
    precondition(Set(sameCode.map(\.hashValue)).count == 1)
    precondition(sameCode[0] != sameCode[1])
    precondition(sameCode[1] != sameCode[2])
}

func testSAErrorCodeHashable() {
    var hasher = Hasher()
    SAError.Code.notAllowed.hash(into: &hasher)
    SAError.Code.notAuthorized.hash(into: &hasher)
    _ = hasher.finalize()

    precondition(SAError.Code.invalidArgument.hashValue == SAError.Code.invalidArgument.hashValue)
    precondition(SAError.Code.invalidArgument.hashValue != SAError.Code.operationFailed.hashValue)

    var set: Set<SAError.Code> = []
    for code in [
        SAError.Code.notAuthorized,
        .notAllowed,
        .invalidArgument,
        .operationFailed,
    ] {
        set.insert(code)
    }
    precondition(set.count == 4)
    precondition(set.contains(.notAllowed))
}

func testSAErrorCodePatternMatch() {
    let notAllowed: any Error = SAError(.notAllowed)
    precondition(SAError.Code.notAllowed ~= notAllowed)
    precondition(!(SAError.Code.invalidArgument ~= notAllowed))
    precondition(!(SAError.Code.notAllowed ~= NSError(domain: "x", code: 2)))
}

func testSAErrorLocalizedDescription() {
    let error = SAError(.notAllowed)
    let description = error.localizedDescription
    precondition(!description.isEmpty)
}