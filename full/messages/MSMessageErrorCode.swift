import Foundation

/// Bridged `NS_ENUM` for Messages resource and send failures.
///
/// Raw values match the pinned `dotnet/macios` `[Native]` enumeration
/// (`Unknown = -1`, `FileNotFound = 1`, then sequential cases). There is
/// no case with raw value `0`.
public enum MSMessageErrorCode: Int, Hashable, Sendable {
    case unknown = -1
    case fileNotFound = 1
    case fileUnreadable = 2
    case improperFileType = 3
    case improperFileURL = 4
    case stickerFileImproperFileAttributes = 5
    case stickerFileImproperFileSize = 6
    case stickerFileImproperFileFormat = 7
    case urlExceedsMaxSize = 8
    case sendWithoutRecentInteraction = 9
    case sendWhileNotVisible = 10
    case apiUnavailableInPresentationContext = 11
}
