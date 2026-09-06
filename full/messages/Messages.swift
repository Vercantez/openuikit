@_exported import Foundation

/// Portable Linux starting point for Apple's public `Messages` module.
///
/// Isolated host compilation imports Foundation only. UIKit is a declared
/// dependency and is imported by the dependency-identity probe for a later
/// clean EC2 build; this module does not publish public lookalikes of
/// `UIView`, `UIImage`, `UIColor`, or `UIEdgeInsets`.
///
/// Linux has no Messages app, iMessage extension host, or Critical
/// Messaging daemon. Value types, error codes, sticker file checks, and
/// in-process state machines are real. Insert/send/authorization paths
/// fail closed with documented error codes and never report success.

/// Apple's `NS_ERROR_ENUM` domain for `MSMessageErrorCode`. The string
/// matches the pinned `dotnet/macios` `[ErrorDomain ("MSMessagesErrorDomain")]`
/// annotation and the TBD export `_MSMessagesErrorDomain`.
public let MSMessagesErrorDomain = "MSMessagesErrorDomain"

/// Sticker-specific error domain exported as `_MSStickersErrorDomain`.
/// Which sticker failures use this domain versus `MSMessagesErrorDomain`
/// on Darwin is unobserved.
public let MSStickersErrorDomain = "MSStickersErrorDomain"

enum MessagesLinuxSupport {
    static func messageError(
        _ code: MSMessageErrorCode,
        userInfo: [String: Any] = [:]
    ) -> NSError {
        var info = userInfo
        if info[NSLocalizedDescriptionKey] == nil {
            info[NSLocalizedDescriptionKey] =
                "Linux has no Messages app or iMessage extension host (\(code))."
        }
        return NSError(
            domain: MSMessagesErrorDomain,
            code: code.rawValue,
            userInfo: info
        )
    }

    static let nullParticipant = UUID(
        uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    )
}
