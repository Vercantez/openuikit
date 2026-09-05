@_exported import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Linux starting point for Apple's public `BackgroundAssets` module.
///
/// Value types, error codes, option-set arithmetic, and JSON manifest parsing
/// are real. Linux has no Apple Background Assets daemon, app-group container,
/// `ExtensionKit` host, or CDN: manager APIs that would talk to those services
/// fail closed with documented `BAErrorCode` / `ManagedBackgroundAssetsError`
/// values. `System.FilePath` is not importable on this Swift 6.2.4 Linux
/// toolchain; this module vends a portable `FilePath` / `FileDescriptor` used
/// by the overlay signatures.

// MARK: - Portable System stand-ins (not declared dependencies)

/// Portable path value used where Apple's overlay takes `System.FilePath`.
public struct FilePath: Hashable, Sendable, CustomStringConvertible {
    public var string: String

    public init(_ string: String) {
        self.string = string
    }

    public var description: String { string }
}

/// Portable descriptor used where Apple's overlay returns `System.FileDescriptor`.
public struct FileDescriptor: RawRepresentable, Hashable, Sendable {
    public var rawValue: Int32

    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}

// MARK: - Error domain and codes

/// Pinned `dotnet/macios` `[ErrorDomain ("BAErrorDomain")]`.
public let BAErrorDomain: String = "BAErrorDomain"

/// Pinned `dotnet/macios` `BAErrorCode` raw values.
public enum BAErrorCode: Int, Error, Hashable, Sendable, CustomNSError {
    case downloadInvalid = 0
    case callFromExtensionNotAllowed = 50
    case callFromInactiveProcessNotAllowed = 51
    case callerConnectionNotAccepted = 55
    case callerConnectionInvalid = 56
    case downloadAlreadyScheduled = 100
    case downloadNotScheduled = 101
    case downloadFailedToStart = 102
    case downloadAlreadyFailed = 103
    case downloadEssentialDownloadNotPermitted = 109
    case downloadBackgroundActivityProhibited = 111
    case downloadWouldExceedAllowance = 112
    case downloadDoesNotExist = 113
    case sessionDownloadDisallowedByDomain = 202
    case sessionDownloadDisallowedByAllowance = 203
    case sessionDownloadAllowanceExceeded = 204
    case sessionDownloadNotPermittedBeforeAppLaunch = 206

    public static var errorDomain: String { BAErrorDomain }

    public var errorCode: Int { rawValue }

    public var errorUserInfo: [String: Any] { [:] }
}

/// Pinned `dotnet/macios` `BAContentRequest`: `Install = 1`, then `Update`, `Periodic`.
public enum BAContentRequest: Int, Hashable, Sendable {
    case install = 1
    case update = 2
    case periodic = 3
}

/// Managed-pack errors. `BAManagedErrorCode` in macios is `AssetPackNotFound`,
/// `FileNotFound` with implicit C order starting at 0; the Swift overlay uses
/// associated values rather than that integer enum.
public enum ManagedBackgroundAssetsError: Error, LocalizedError, CustomStringConvertible, Sendable {
    case assetPackNotFound(withID: String)
    case fileNotFound(at: FilePath)

    public var description: String {
        switch self {
        case .assetPackNotFound(let id):
            return "assetPackNotFound(withID: \(id))"
        case .fileNotFound(let path):
            return "fileNotFound(at: \(path.string))"
        }
    }

    public var errorDescription: String? { description }

    public var failureReason: String? {
        switch self {
        case .assetPackNotFound:
            return "The asset pack is not present on this host."
        case .fileNotFound:
            return "The asset file is not present on this host."
        }
    }

    public var recoverySuggestion: String? {
        "Linux has no Apple Background Assets catalog or downloaded pack store."
    }

    public var helpAnchor: String? { nil }
}
