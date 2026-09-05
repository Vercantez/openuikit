import CallKit
import Foundation

func testRequestTransactionErrorCodeRawValues() {
    typealias Code = CXErrorCodeRequestTransactionError.Code
    precondition(Code.unknown.rawValue == 0)
    precondition(Code.unentitled.rawValue == 1)
    precondition(Code.unknownCallProvider.rawValue == 2)
    precondition(Code.emptyTransaction.rawValue == 3)
    precondition(Code.unknownCallUUID.rawValue == 4)
    precondition(Code.callUUIDAlreadyExists.rawValue == 5)
    precondition(Code.invalidAction.rawValue == 6)
    precondition(Code.maximumCallGroupsReached.rawValue == 7)
    precondition(Code.callIsProtected.rawValue == 8)
    precondition(Code.emptyTransaction != .invalidAction)
    var hasher = Hasher()
    Code.unknownCallUUID.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Code.maximumCallGroupsReached.hashValue != Code.unknown.hashValue)
}

func testRequestTransactionErrorCodeRawValueInit() {
    typealias Code = CXErrorCodeRequestTransactionError.Code
    precondition(Code(rawValue: 3) == .emptyTransaction)
    precondition(Code(rawValue: 7) == .maximumCallGroupsReached)
    precondition(Code(rawValue: 9) == nil)
}

func testRequestTransactionErrorStaticAliases() {
    precondition(CXErrorCodeRequestTransactionError.unknown == .unknown)
    precondition(CXErrorCodeRequestTransactionError.unentitled == .unentitled)
    precondition(CXErrorCodeRequestTransactionError.unknownCallProvider == .unknownCallProvider)
    precondition(CXErrorCodeRequestTransactionError.emptyTransaction == .emptyTransaction)
    precondition(CXErrorCodeRequestTransactionError.unknownCallUUID == .unknownCallUUID)
    precondition(CXErrorCodeRequestTransactionError.callUUIDAlreadyExists == .callUUIDAlreadyExists)
    precondition(CXErrorCodeRequestTransactionError.invalidAction == .invalidAction)
    precondition(CXErrorCodeRequestTransactionError.maximumCallGroupsReached == .maximumCallGroupsReached)
    precondition(CXErrorCodeRequestTransactionError.callIsProtected == .callIsProtected)
}

func testRequestTransactionErrorInitUserInfoAndCustomNSError() {
    let error = CXErrorCodeRequestTransactionError(.emptyTransaction, userInfo: ["why": "empty"])
    precondition(error.code == .emptyTransaction)
    precondition(error.errorCode == 3)
    precondition(error.userInfo["why"] as? String == "empty")
    precondition(error.errorUserInfo["why"] as? String == "empty")
    precondition(CXErrorCodeRequestTransactionError.errorDomain == CXErrorDomainRequestTransaction)
    precondition(CXErrorDomainRequestTransaction == "CXErrorDomainRequestTransaction")
}

func testRequestTransactionErrorEqualityAndHash() {
    let left = CXErrorCodeRequestTransactionError(.unknownCallProvider)
    let right = CXErrorCodeRequestTransactionError(.unknownCallProvider)
    precondition(left == right)
    precondition(!(left != right))
    precondition(left != CXErrorCodeRequestTransactionError(.unknownCallUUID))
    precondition(left.hashValue == right.hashValue)
    var hasher = Hasher()
    left.hash(into: &hasher)
    _ = hasher.finalize()
}

func testRequestTransactionErrorPatternMatchAndLocalizedDescription() {
    let typed: any Error = CXErrorCodeRequestTransactionError(.invalidAction)
    precondition(CXErrorCodeRequestTransactionError.invalidAction ~= typed)
    precondition(!(CXErrorCodeRequestTransactionError.emptyTransaction ~= typed))
    precondition(!CXErrorCodeRequestTransactionError(.unknown).localizedDescription.isEmpty)
}

func testRequestTransactionErrorStructIdentity() {
    let error = CXErrorCodeRequestTransactionError(.callIsProtected)
    precondition(type(of: error) == CXErrorCodeRequestTransactionError.self)
}
