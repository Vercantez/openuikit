import CallKit
import Foundation

func testIncomingCallErrorCodeRawValues() {
    typealias Code = CXErrorCodeIncomingCallError.Code
    precondition(Code.unknown.rawValue == 0)
    precondition(Code.unentitled.rawValue == 1)
    precondition(Code.callUUIDAlreadyExists.rawValue == 2)
    precondition(Code.filteredByDoNotDisturb.rawValue == 3)
    precondition(Code.filteredByBlockList.rawValue == 4)
    precondition(Code.filteredDuringRestrictedSharingMode.rawValue == 5)
    precondition(Code.callIsProtected.rawValue == 6)
    precondition(Code.filteredBySensitiveParticipants.rawValue == 7)
    precondition(Code.unknown != .unentitled)
    var hasher = Hasher()
    Code.callUUIDAlreadyExists.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Code.callIsProtected.hashValue != Code.unknown.hashValue)
}

func testIncomingCallErrorCodeRawValueInit() {
    typealias Code = CXErrorCodeIncomingCallError.Code
    precondition(Code(rawValue: 0) == .unknown)
    precondition(Code(rawValue: 2) == .callUUIDAlreadyExists)
    precondition(Code(rawValue: 7) == .filteredBySensitiveParticipants)
    precondition(Code(rawValue: 8) == nil)
}

func testIncomingCallErrorStaticAliases() {
    precondition(CXErrorCodeIncomingCallError.unknown == .unknown)
    precondition(CXErrorCodeIncomingCallError.unentitled == .unentitled)
    precondition(CXErrorCodeIncomingCallError.callUUIDAlreadyExists == .callUUIDAlreadyExists)
    precondition(CXErrorCodeIncomingCallError.filteredByDoNotDisturb == .filteredByDoNotDisturb)
    precondition(CXErrorCodeIncomingCallError.filteredByBlockList == .filteredByBlockList)
    precondition(CXErrorCodeIncomingCallError.filteredDuringRestrictedSharingMode == .filteredDuringRestrictedSharingMode)
    precondition(CXErrorCodeIncomingCallError.callIsProtected == .callIsProtected)
    precondition(CXErrorCodeIncomingCallError.filteredBySensitiveParticipants == .filteredBySensitiveParticipants)
}

func testIncomingCallErrorInitUserInfoAndCustomNSError() {
    let error = CXErrorCodeIncomingCallError(.callUUIDAlreadyExists, userInfo: ["k": "v"])
    precondition(error.code == .callUUIDAlreadyExists)
    precondition(error.errorCode == 2)
    precondition(error.userInfo["k"] as? String == "v")
    precondition(error.errorUserInfo["k"] as? String == "v")
    precondition(CXErrorCodeIncomingCallError.errorDomain == CXErrorDomainIncomingCall)
    precondition(CXErrorDomainIncomingCall == "CXErrorDomainIncomingCall")
}

func testIncomingCallErrorEqualityAndHash() {
    let left = CXErrorCodeIncomingCallError(.filteredByDoNotDisturb)
    let right = CXErrorCodeIncomingCallError(.filteredByDoNotDisturb)
    precondition(left == right)
    precondition(!(left != right))
    precondition(left != CXErrorCodeIncomingCallError(.filteredByBlockList))
    precondition(left.hashValue == right.hashValue)
    var hasher = Hasher()
    left.hash(into: &hasher)
    _ = hasher.finalize()
}

func testIncomingCallErrorPatternMatchAndLocalizedDescription() {
    let typed: any Error = CXErrorCodeIncomingCallError(.callIsProtected)
    precondition(CXErrorCodeIncomingCallError.callIsProtected ~= typed)
    precondition(!(CXErrorCodeIncomingCallError.unknown ~= typed))
    precondition(!CXErrorCodeIncomingCallError(.unknown).localizedDescription.isEmpty)
    let ns = typed as NSError
    precondition(ns.domain == CXErrorDomainIncomingCall)
    precondition(ns.code == 6)
}

func testIncomingCallErrorStructIdentity() {
    let error = CXErrorCodeIncomingCallError(.unentitled)
    precondition(type(of: error) == CXErrorCodeIncomingCallError.self)
}
