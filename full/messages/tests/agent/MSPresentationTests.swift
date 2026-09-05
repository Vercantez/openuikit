import Foundation
import Messages

func testPresentationStyleRawValues() {
    precondition(MSMessagesAppPresentationStyle.compact.rawValue == 0)
    precondition(MSMessagesAppPresentationStyle.expanded.rawValue == 1)
    precondition(MSMessagesAppPresentationStyle.transcript.rawValue == 2)
    precondition(MSMessagesAppPresentationStyle(rawValue: 0) == .compact)
    precondition(MSMessagesAppPresentationStyle(rawValue: 1) == .expanded)
    precondition(MSMessagesAppPresentationStyle(rawValue: 2) == .transcript)
    precondition(MSMessagesAppPresentationStyle(rawValue: 3) == nil)
    precondition(MSMessagesAppPresentationStyle.compact != .expanded)
    precondition(
        MSMessagesAppPresentationStyle.compact.hashValue
            == MSMessagesAppPresentationStyle.compact.hashValue
    )
    var hasher = Hasher()
    MSMessagesAppPresentationStyle.transcript.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPresentationContextRawValues() {
    precondition(MSMessagesAppPresentationContext.messages.rawValue == 0)
    precondition(MSMessagesAppPresentationContext.media.rawValue == 1)
    precondition(MSMessagesAppPresentationContext(rawValue: 0) == .messages)
    precondition(MSMessagesAppPresentationContext(rawValue: 1) == .media)
    precondition(MSMessagesAppPresentationContext(rawValue: 2) == nil)
    precondition(MSMessagesAppPresentationContext.messages != .media)
    precondition(
        MSMessagesAppPresentationContext.messages.hashValue
            == MSMessagesAppPresentationContext.messages.hashValue
    )
    var hasher = Hasher()
    MSMessagesAppPresentationContext.media.hash(into: &hasher)
    _ = hasher.finalize()
}

func testStickerSizeRawValues() {
    precondition(MSStickerSize.small.rawValue == 0)
    precondition(MSStickerSize.regular.rawValue == 1)
    precondition(MSStickerSize.large.rawValue == 2)
    precondition(MSStickerSize(rawValue: 0) == .small)
    precondition(MSStickerSize(rawValue: 1) == .regular)
    precondition(MSStickerSize(rawValue: 2) == .large)
    precondition(MSStickerSize(rawValue: 3) == nil)
    precondition(MSStickerSize.small != .large)
    precondition(MSStickerSize.regular.hashValue == MSStickerSize.regular.hashValue)
    var hasher = Hasher()
    MSStickerSize.large.hash(into: &hasher)
    _ = hasher.finalize()
}
