@_exported import Foundation

/// Linux starting point for Apple's public `BrowserEngineKit` module
/// (iOS 17.4+ alternative browser engine process, text, accessibility, and
/// download APIs). Isolated-host success is not Apple web-content process,
/// XPC, GPU layer, or entitlement success.
///
/// Helper extension processes, `libxpc`, mach ports, GPU layer hierarchies,
/// Live Activity download monitoring, and `AVCaptureSession` sandbox grants
/// are absent on Linux. Those operations fail closed with
/// `BrowserEngineKitHostError`. Value types, documented enum/option-set
/// raw values, and in-process text/document models are real.

/// Linux-local fail-closed errors. Apple's BrowserEngineKit NSError domain
/// and codes are unobserved; these discriminators are not Darwin codes.
public enum BrowserEngineKitHostError: Error, Equatable, Hashable, Sendable {
    /// No web-content, networking, or rendering helper process exists.
    case processUnavailable
    /// `libxpc` / `NSXPCConnection` cannot be opened on Linux.
    case xpcUnavailable
    /// Mach-port layer hierarchy and CALayer hosting are unavailable.
    case layerHierarchyUnavailable
    /// Media playback/capture sandbox and `AVCaptureSession` are unavailable.
    case mediaSessionUnavailable
    /// Download-folder monitoring and Live Activity tokens are unavailable.
    case downloadMonitorUnavailable
}

extension BrowserEngineKitHostError: CustomNSError {
    public static var errorDomain: String { "BrowserEngineKit.Linux" }

    public var errorCode: Int {
        switch self {
        case .processUnavailable: return 1
        case .xpcUnavailable: return 2
        case .layerHierarchyUnavailable: return 3
        case .mediaSessionUnavailable: return 4
        case .downloadMonitorUnavailable: return 5
        }
    }
}

/// Static availability for Apple browser-engine services on this host.
public enum BrowserEngineKitLinuxBoundary {
    public static let helperProcessAvailable = false
    public static let layerHierarchyAvailable = false
    public static let mediaCaptureAvailable = false
    public static let downloadMonitorAvailable = false
}
