/// Linux starting point for Apple's public `SecureElementCredential` module
/// (Xcode 26.1 / iPhoneOS 26.1 Swift surface).
///
/// The Secure Element, NFC card-emulation radio, Apple credential daemon,
/// Wallet entitlements (`com.apple.developer.secure-element-credential`),
/// GDPR/privacy UI, and presentment authorization are absent on this host.
/// Value types, enum cases, Codable round-trips, LocalizedError text, and
/// Equatable/Hashable witnesses are real. Session, wired, card-emulation,
/// provisioning, transceive, and presentment APIs fail closed with
/// `CredentialSession.ErrorCode.featureUnavailable`. Successful Apple-only
/// payment or credential behavior is never invented.
///
/// Overlay symbols that require `UIScene` / `UIWindowScene` / SwiftUI `View`
/// are omitted from this Foundation-only module (see coverage `unavailable`).

/// SwiftUI overlay alias for `CredentialSession.Credential`.
public typealias Credential = CredentialSession.Credential

/// SwiftUI overlay alias for `CredentialSession.CardEmulationOptions`.
public typealias CardEmulationOptions = CredentialSession.CardEmulationOptions

enum SecureElementCredentialHostBoundary {
    static func unavailable() -> CredentialSession.ErrorCode {
        .featureUnavailable
    }
}
