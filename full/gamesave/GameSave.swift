/// Portable Linux starting point for Apple's public `GameSave` module.
///
/// `GSSyncState` raw values, `GameSaveErrorDomain`, `GameSaveSyncedDirectory.State`,
/// and the local open/close/resolve state machine are real. Linux has no iCloud
/// Drive daemon, GameSave entitlements, or Apple conflict UI: `openDirectory`
/// settles on the documented local-only state, `triggerPendingUpload` reports no
/// pending cloud work, and UIKit/SwiftUI status surfaces stay deferred.
///
/// The isolated host gate compiles against toolchain Foundation only.

import Foundation

/// Apple's public GameSave error domain constant.
/// Identity follows the Swift census name; the live NSString payload is unobserved.
public let GameSaveErrorDomain: String = "GameSaveErrorDomain"

/// Bridged `NS_ENUM` `GSSyncState`.
///
/// Raw values follow the pinned `dotnet/macios` `[Native]` case order
/// (`Ready`, `Offline`, `Local`, `Syncing`, `Conflicted`, `Error`, `Closed`).
/// They are not taken from an Apple runtime observation.
public enum GSSyncState: Int, Equatable, Hashable, Sendable {
    case ready = 0
    case offline = 1
    case local = 2
    case syncing = 3
    case conflicted = 4
    case error = 5
    case closed = 6
}

/// Linux-local GameSave failure. Uses `GameSaveErrorDomain`. Apple error
/// codes for unsigned-in iCloud / daemon failure are unobserved.
@_spi(OpenUIKitHost)
public struct GameSaveLinuxCloudUnavailableError: Error, CustomNSError, Equatable, Sendable {
    public static var errorDomain: String { GameSaveErrorDomain }

    public var errorCode: Int { 1 }

    public var errorUserInfo: [String: Any] { [:] }

    public init() {}
}

enum GameSaveLocalStore {
    static let defaultContainerIdentifier = "GameSave.local"

    static func resolvedContainerIdentifier(_ containerIdentifier: String?) -> String {
        if let containerIdentifier, !containerIdentifier.isEmpty {
            return containerIdentifier
        }
        return defaultContainerIdentifier
    }

    static func directoryURL(for containerIdentifier: String) -> URL {
        let base: URL
        if let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first {
            base = support
        } else {
            base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        }
        return base
            .appendingPathComponent("GameSave", isDirectory: true)
            .appendingPathComponent(containerIdentifier, isDirectory: true)
    }

    static func ensureDirectoryExists(at url: URL) -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
            return true
        } catch {
            return false
        }
    }
}
