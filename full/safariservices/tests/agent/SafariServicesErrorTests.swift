import Foundation
import SafariServices

func testErrorDomainConstants() {
    precondition(SFAuthenticationErrorDomain == "SFAuthenticationErrorDomain")
    precondition(SFContentBlockerErrorDomain == "SFContentBlockerErrorDomain")
    precondition(SFErrorDomain == "SFErrorDomain")
    precondition(SSReadingListErrorDomain == "SSReadingListErrorDomain")
    precondition(SFAuthenticationError.errorDomain == SFAuthenticationErrorDomain)
    precondition(SFAuthenticationError._nsErrorDomain == SFAuthenticationErrorDomain)
    precondition(SFError.errorDomain == SFErrorDomain)
    precondition(SFError._nsErrorDomain == SFErrorDomain)
    precondition(SSReadingListError.errorDomain == SSReadingListErrorDomain)
    precondition(SSReadingListError._nsErrorDomain == SSReadingListErrorDomain)
}

func testExtensionMessageKeys() {
    precondition(SFExtensionMessageKey == "SFExtensionMessageKey")
    precondition(SFExtensionProfileKey == "SFExtensionProfileKey")
}

func testSFAuthenticationErrorCodes() {
    precondition(SFAuthenticationError.Code.canceledLogin.rawValue == 1)
    precondition(SFAuthenticationError.canceledLogin == .canceledLogin)
    precondition(SFAuthenticationError.Code(rawValue: 1) == .canceledLogin)
    precondition(SFAuthenticationError.Code(rawValue: 0) == nil)
    precondition(SFAuthenticationError.Code.canceledLogin.hashValue ==
        SFAuthenticationError.Code.canceledLogin.hashValue)
    var hasher = Hasher()
    SFAuthenticationError.Code.canceledLogin.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSFErrorCodes() {
    precondition(SFError.Code.noExtensionFound.rawValue == 1)
    precondition(SFError.Code.noAttachmentFound.rawValue == 2)
    precondition(SFError.Code.loadingInterrupted.rawValue == 3)
    precondition(SFError.Code.internalError.rawValue == 4)
    precondition(SFError.Code.missingEntitlement.rawValue == 5)
    precondition(SFError.noExtensionFound == .noExtensionFound)
    precondition(SFError.noAttachmentFound == .noAttachmentFound)
    precondition(SFError.loadingInterrupted == .loadingInterrupted)
    precondition(SFError.internalError == .internalError)
    precondition(SFError.missingEntitlement == .missingEntitlement)
    precondition(SFError.Code(rawValue: 1) == .noExtensionFound)
    precondition(SFError.Code(rawValue: 5) == .missingEntitlement)
    precondition(SFError.Code(rawValue: 0) == nil)
    precondition(SFError.Code(rawValue: 6) == nil)
    precondition(SFError.Code.internalError != .missingEntitlement)
    precondition(!(SFError.Code.internalError != .internalError))
    precondition(SFError.Code.internalError.hashValue == SFError.Code.internalError.hashValue)
    var hasher = Hasher()
    SFError.Code.noAttachmentFound.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSFContentBlockerErrorCodes() {
    precondition(SFContentBlockerErrorCode.noExtensionFound.rawValue == 1)
    precondition(SFContentBlockerErrorCode.noAttachmentFound.rawValue == 2)
    precondition(SFContentBlockerErrorCode.loadingInterrupted.rawValue == 3)
    precondition(SFContentBlockerErrorCode(rawValue: 1) == .noExtensionFound)
    precondition(SFContentBlockerErrorCode(rawValue: 0) == nil)
    precondition(SFContentBlockerErrorCode.noExtensionFound != .loadingInterrupted)
    precondition(
        SFContentBlockerErrorCode.noAttachmentFound.hashValue ==
            SFContentBlockerErrorCode.noAttachmentFound.hashValue
    )
    var hasher = Hasher()
    SFContentBlockerErrorCode.loadingInterrupted.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSSReadingListErrorCodes() {
    precondition(SSReadingListError.Code.urlSchemeNotAllowed.rawValue == 1)
    precondition(SSReadingListError.urlSchemeNotAllowed == .urlSchemeNotAllowed)
    precondition(SSReadingListError.Code(rawValue: 1) == .urlSchemeNotAllowed)
    precondition(SSReadingListError.Code(rawValue: 2) == nil)
    precondition(SSReadingListError.Code.urlSchemeNotAllowed.hashValue ==
        SSReadingListError.Code.urlSchemeNotAllowed.hashValue)
    var hasher = Hasher()
    SSReadingListError.Code.urlSchemeNotAllowed.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSFErrorBridgedMembers() {
    let empty = SFError(.internalError)
    precondition(empty.code == .internalError)
    precondition(empty.errorCode == 4)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty == SFError(.internalError))
    precondition(empty != SFError(.missingEntitlement))

    let tagged = SFError(.noExtensionFound, userInfo: ["sentinel": "sf"])
    precondition(tagged.userInfo["sentinel"] as? String == "sf")
    precondition(tagged.errorUserInfo["sentinel"] as? String == "sf")
    precondition(tagged.errorCode == 1)
    precondition(empty.hashValue == SFError(.internalError).hashValue)
    var hasher = Hasher()
    empty.hash(into: &hasher)
    _ = hasher.finalize()

    let error: any Error = SFError(.loadingInterrupted)
    precondition(SFError.Code.loadingInterrupted ~= error)
    precondition(!(SFError.Code.internalError ~= error))
}

func testSFAuthenticationErrorBridgedMembers() {
    let error = SFAuthenticationError(.canceledLogin, userInfo: ["k": "v"])
    precondition(error.code == .canceledLogin)
    precondition(error.errorCode == 1)
    precondition(error.userInfo["k"] as? String == "v")
    precondition(error == SFAuthenticationError(.canceledLogin, userInfo: ["k": "v"]))
    precondition(error != SFAuthenticationError(.canceledLogin))
    precondition(SFAuthenticationError.Code.canceledLogin ~= error)
    precondition(!error.localizedDescription.isEmpty)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    _ = error.hashValue
}

func testSSReadingListErrorBridgedMembers() {
    let error = SSReadingListError(.urlSchemeNotAllowed)
    precondition(error.code == .urlSchemeNotAllowed)
    precondition(error.errorCode == 1)
    precondition(error.userInfo.isEmpty)
    precondition(error == SSReadingListError(.urlSchemeNotAllowed))
    precondition(SSReadingListError.Code.urlSchemeNotAllowed ~= error)
    precondition(!error.localizedDescription.isEmpty)
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    _ = error.hashValue
}
