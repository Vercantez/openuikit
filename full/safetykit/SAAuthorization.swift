import Foundation

/// Crash Detection authorization state. Raw values follow the pinned
/// `dotnet/macios` `SAAuthorizationStatus` enumeration (`notDetermined = 0`).
public enum SAAuthorizationStatus: Int, Hashable, Sendable {
    case notDetermined = 0
    case denied = 1
    case authorized = 2
}