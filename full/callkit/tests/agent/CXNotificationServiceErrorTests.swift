import CallKit
import Foundation

func testNotificationServiceExtensionErrorCodeRawValues() {
    typealias Code = CXErrorCodeNotificationServiceExtensionError.Code
    precondition(Code.unknown.rawValue == 0)
    precondition(Code.invalidClientProcess.rawValue == 1)
    precondition(Code.missingNotificationFilteringEntitlement.rawValue == 2)
    precondition(Code.unknown != .invalidClientProcess)
    var hasher = Hasher()
    Code.missingNotificationFilteringEntitlement.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Code.invalidClientProcess.hashValue != Code.unknown.hashValue)
}

func testNotificationServiceExtensionErrorCodeRawValueInit() {
    typealias Code = CXErrorCodeNotificationServiceExtensionError.Code
    precondition(Code(rawValue: 0) == .unknown)
    precondition(Code(rawValue: 1) == .invalidClientProcess)
    precondition(Code(rawValue: 2) == .missingNotificationFilteringEntitlement)
    precondition(Code(rawValue: 3) == nil)
}

func testNotificationServiceExtensionErrorStaticAliases() {
    precondition(CXErrorCodeNotificationServiceExtensionError.unknown == .unknown)
    precondition(CXErrorCodeNotificationServiceExtensionError.invalidClientProcess == .invalidClientProcess)
    precondition(
        CXErrorCodeNotificationServiceExtensionError.missingNotificationFilteringEntitlement
            == .missingNotificationFilteringEntitlement
    )
}

func testNotificationServiceExtensionErrorInitUserInfoAndCustomNSError() {
    let error = CXErrorCodeNotificationServiceExtensionError(
        .invalidClientProcess,
        userInfo: ["proc": "cli"]
    )
    precondition(error.code == .invalidClientProcess)
    precondition(error.errorCode == 1)
    precondition(error.userInfo["proc"] as? String == "cli")
    precondition(error.errorUserInfo["proc"] as? String == "cli")
    precondition(
        CXErrorCodeNotificationServiceExtensionError.errorDomain == CXErrorDomainNotificationServiceExtension
    )
    precondition(CXErrorDomainNotificationServiceExtension == "CXErrorDomainNotificationServiceExtension")
}

func testNotificationServiceExtensionErrorEqualityAndHash() {
    let left = CXErrorCodeNotificationServiceExtensionError(.missingNotificationFilteringEntitlement)
    let right = CXErrorCodeNotificationServiceExtensionError(.missingNotificationFilteringEntitlement)
    precondition(left == right)
    precondition(!(left != right))
    precondition(left != CXErrorCodeNotificationServiceExtensionError(.unknown))
    precondition(left.hashValue == right.hashValue)
    var hasher = Hasher()
    left.hash(into: &hasher)
    _ = hasher.finalize()
}

func testNotificationServiceExtensionErrorPatternMatchAndLocalizedDescription() {
    let typed: any Error = CXErrorCodeNotificationServiceExtensionError(.invalidClientProcess)
    precondition(CXErrorCodeNotificationServiceExtensionError.invalidClientProcess ~= typed)
    precondition(!(CXErrorCodeNotificationServiceExtensionError.unknown ~= typed))
    precondition(!CXErrorCodeNotificationServiceExtensionError(.unknown).localizedDescription.isEmpty)
}

func testNotificationServiceExtensionErrorStructIdentity() {
    let error = CXErrorCodeNotificationServiceExtensionError(.unknown)
    precondition(type(of: error) == CXErrorCodeNotificationServiceExtensionError.self)
}
