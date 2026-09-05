import Foundation
import Messages

func testMessageErrorCodeRawValues() {
    precondition(MSMessageErrorCode.unknown.rawValue == -1)
    precondition(MSMessageErrorCode.fileNotFound.rawValue == 1)
    precondition(MSMessageErrorCode.fileUnreadable.rawValue == 2)
    precondition(MSMessageErrorCode.improperFileType.rawValue == 3)
    precondition(MSMessageErrorCode.improperFileURL.rawValue == 4)
    precondition(MSMessageErrorCode.stickerFileImproperFileAttributes.rawValue == 5)
    precondition(MSMessageErrorCode.stickerFileImproperFileSize.rawValue == 6)
    precondition(MSMessageErrorCode.stickerFileImproperFileFormat.rawValue == 7)
    precondition(MSMessageErrorCode.urlExceedsMaxSize.rawValue == 8)
    precondition(MSMessageErrorCode.sendWithoutRecentInteraction.rawValue == 9)
    precondition(MSMessageErrorCode.sendWhileNotVisible.rawValue == 10)
    precondition(MSMessageErrorCode.apiUnavailableInPresentationContext.rawValue == 11)
    precondition(MSMessageErrorCode(rawValue: -1) == .unknown)
    precondition(MSMessageErrorCode(rawValue: 0) == nil)
    precondition(MSMessageErrorCode(rawValue: 1) == .fileNotFound)
    precondition(MSMessageErrorCode(rawValue: 11) == .apiUnavailableInPresentationContext)
    precondition(MSMessageErrorCode(rawValue: 12) == nil)
    precondition(MSMessageErrorCode.unknown != .fileNotFound)
    precondition(MSMessageErrorCode.sendWhileNotVisible.hashValue == MSMessageErrorCode.sendWhileNotVisible.hashValue)
    var hasher = Hasher()
    MSMessageErrorCode.fileNotFound.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMessagesErrorDomain() {
    precondition(MSMessagesErrorDomain == "MSMessagesErrorDomain")
}

func testStickersErrorDomain() {
    precondition(MSStickersErrorDomain == "MSStickersErrorDomain")
    precondition(MSStickersErrorDomain != MSMessagesErrorDomain)
}
