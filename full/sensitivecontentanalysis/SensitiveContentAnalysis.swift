@_exported import Foundation

/// Linux starting point for Apple's public `SensitiveContentAnalysis` module.
///
/// Communication Safety / Sensitive Content Warning, the on-device classifier,
/// and the analysis daemon are absent. Policy reads as `.disabled`. Analysis
/// APIs fail closed and never invent a sensitive or not-sensitive ML result.
///
/// `SCLinuxUnavailableError` is a Linux-only fail-closed overlay. It is not
/// one of the 38 public Apple identifiers; Darwin's thrown `NSError` domain
/// and code are unobserved.

/// Linux fail-closed error domain. Not an Apple CFString payload.
public let SCLinuxUnavailableErrorDomain = "SensitiveContentAnalysis.LinuxUnavailable"

/// Portable fail-closed error used when Apple analysis hardware, entitlements,
/// or services are required. Code `1` is this overlay's `platformNotSupported`
/// sentinel, not a documented Apple `NS_ERROR_ENUM` value.
public struct SCLinuxUnavailableError: Error, CustomNSError, Equatable, Hashable, Sendable {
    public static var errorDomain: String { SCLinuxUnavailableErrorDomain }
    public var errorCode: Int { 1 }
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: SCLinuxUnavailableError.localizedReason]
    }

    public static let localizedReason =
        "Sensitive Content Analysis has no Apple classifier, Communication Safety policy, or analysis daemon on this Linux host"

    public init() {}
}

func scLinuxUnavailable() -> SCLinuxUnavailableError {
    SCLinuxUnavailableError()
}

/// Communication Safety intervention policy. Raw values follow the pinned
/// `dotnet/macios` `SCSensitivityAnalysisPolicy` enumeration
/// (`disabled = 0`, `simpleInterventions = 1`, `descriptiveInterventions = 2`).
public enum SCSensitivityAnalysisPolicy: Int, Hashable, Sendable {
    case disabled = 0
    case simpleInterventions = 1
    case descriptiveInterventions = 2
}
