@_exported import Foundation

/// Public `NSError` domain for MultipeerConnectivity failures.
///
/// The pinned SDK bytes are absent, so this portable overlay uses the public
/// constant name as the domain string (same pattern as `kCLErrorDomain`).
/// The exact Apple runtime string remains an oracle question.
public let MCErrorDomain = "MCErrorDomain"

/// Minimum session size, including the local peer.
/// Documented by Apple as 2 (the local peer plus one remote peer).
public let kMCSessionMinimumNumberOfPeers: Int = 2

/// Maximum session size, including the local peer.
/// Documented by Apple as 8 peers total.
public let kMCSessionMaximumNumberOfPeers: Int = 8

/// Encryption preference for an `MCSession`.
/// Raw values follow the public `NS_ENUM` layout in the Xcode 26.1 overlay.
public enum MCEncryptionPreference: Int, Hashable, Sendable {
    case optional = 0
    case required = 1
    case none = 2
}

/// Delivery mode for `MCSession.send(_:toPeers:with:)`.
public enum MCSessionSendDataMode: Int, Hashable, Sendable {
    case reliable = 0
    case unreliable = 1
}

/// Connection state reported to `MCSessionDelegate`.
public enum MCSessionState: Int, Hashable, Sendable {
    case notConnected = 0
    case connecting = 1
    case connected = 2
}

/// Bonjour-style service type used by nearby advertiser/browser APIs.
///
/// Apple documents a 1...15 character ASCII string of lowercase letters,
/// numbers, and hyphens. This helper encodes that published constraint; the
/// exact hyphen-placement and discoveryInfo size rules remain oracle questions.
func mc_isValidServiceType(_ serviceType: String) -> Bool {
    let utf8Count = serviceType.utf8.count
    guard (1...15).contains(utf8Count) else { return false }
    return serviceType.utf8.allSatisfy { byte in
        (byte >= 97 && byte <= 122)
            || (byte >= 48 && byte <= 57)
            || byte == 45
    }
}

func mc_unavailableError() -> MCError {
    MCError(.unavailable)
}

func mc_invalidParameterError() -> MCError {
    MCError(.invalidParameter)
}

func mc_notConnectedError() -> MCError {
    MCError(.notConnected)
}
