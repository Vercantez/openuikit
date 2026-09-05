import CallKit
import Foundation

func testCXErrorDomainConstants() {
    precondition(CXErrorDomain == "CXErrorDomain")
    precondition(CXError.errorDomain == CXErrorDomain)
    precondition(CXError.errorDomain == "CXErrorDomain")
}

func testCXErrorCodeRawValues() {
    typealias Code = CXError.Code
    precondition(Code.unknownError.rawValue == 0)
    precondition(Code.unentitled.rawValue == 1)
    precondition(Code.invalidArgument.rawValue == 2)
    precondition(Code.missingVoIPBackgroundMode.rawValue == 3)
    precondition(Code.unknownError != .unentitled)
    precondition(Code.invalidArgument != .missingVoIPBackgroundMode)
    var hasher = Hasher()
    Code.unknownError.hash(into: &hasher)
    Code.unentitled.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Code.invalidArgument.hashValue == Code.invalidArgument.hashValue)
    precondition(Code.invalidArgument.hashValue != Code.unentitled.hashValue)
}

func testCXErrorCodeRawValueInit() {
    precondition(CXError.Code(rawValue: 0) == .unknownError)
    precondition(CXError.Code(rawValue: 1) == .unentitled)
    precondition(CXError.Code(rawValue: 2) == .invalidArgument)
    precondition(CXError.Code(rawValue: 3) == .missingVoIPBackgroundMode)
    precondition(CXError.Code(rawValue: 4) == nil)
    precondition(CXError.Code(rawValue: -1) == nil)
}

func testCXErrorStaticCodeAliases() {
    precondition(CXError.unknownError == CXError.Code.unknownError)
    precondition(CXError.unentitled == CXError.Code.unentitled)
    precondition(CXError.invalidArgument == CXError.Code.invalidArgument)
    precondition(CXError.missingVoIPBackgroundMode == CXError.Code.missingVoIPBackgroundMode)
}

func testCXErrorInitUserInfoAndCustomNSError() {
    let empty = CXError(.invalidArgument)
    precondition(empty.code == .invalidArgument)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(empty.errorCode == 2)
    precondition(empty.errorCode == CXError.Code.invalidArgument.rawValue)

    let sentinel = CXError(.unentitled, userInfo: ["sentinel": "value"])
    precondition(sentinel.code == .unentitled)
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.userInfo.count == 1)
}

func testCXErrorEquality() {
    let left = CXError(.unentitled)
    let right = CXError(.unentitled)
    precondition(left == right)
    precondition(!(left != right))
    precondition(left != CXError(.invalidArgument))
    precondition(
        CXError(.unentitled, userInfo: ["k": "a"]) != CXError(.unentitled, userInfo: ["k": "b"])
    )
}

func testCXErrorHashable() {
    let empty = CXError(.unentitled)
    let sentinel = CXError(.unentitled, userInfo: ["sentinel": "value"])
    precondition(empty.hashValue == sentinel.hashValue)
    var hasherA = Hasher()
    var hasherB = Hasher()
    empty.hash(into: &hasherA)
    CXError(.unentitled).hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
}

func testCXErrorCodePatternMatch() {
    let typed: any Error = CXError(.invalidArgument)
    precondition(CXError.invalidArgument ~= typed)
    precondition(!(CXError.unentitled ~= typed))
    let ns = typed as NSError
    precondition(ns.domain == CXErrorDomain)
    precondition(ns.code == 2)
    precondition(CXError.invalidArgument ~= ns)
    let fresh = NSError(domain: CXErrorDomain, code: CXError.Code.unentitled.rawValue)
    precondition(CXError.unentitled ~= fresh)
    precondition((fresh as? CXError) == nil)
}

func testCXErrorLocalizedDescription() {
    let description = CXError(.unknownError).localizedDescription
    precondition(!description.isEmpty)
}

func testCXErrorStructIdentity() {
    let error = CXError(.missingVoIPBackgroundMode)
    precondition(type(of: error) == CXError.self)
    precondition(error.code == .missingVoIPBackgroundMode)
}
