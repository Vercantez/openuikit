import Foundation

/// A cloud-synced directory for game-save data.
///
/// Darwin starts background iCloud sync from `openDirectory(containerIdentifier:)`.
/// Linux has no iCloud container entitlements or Drive daemon, so the object
/// opens in the documented local-only state (`.local`) with a real process-local
/// directory. It never reports `.ready` (fully synced) unless a host test injects
/// that state. `triggerPendingUpload()` is fail-closed (`false`).
public class GameSaveSyncedDirectory: Identifiable, Equatable, @unchecked Sendable {
    public typealias ID = String

    /// The state of the directory.
    public enum State: CustomStringConvertible {
        /// The directory is fully synced and ready to use.
        case ready(URL)
        /// The directory is available locally, but not fully synced because the device is offline.
        case offline(URL)
        /// The directory is local-only and not synced to iCloud.
        case local(URL)
        /// The directory is currently syncing and is not ready yet.
        case syncing
        /// The directory has conflicts with the cloud, which the game needs to resolve.
        case conflicted(versions: [Version])
        /// The directory is in error state and can't be used.
        case error(any Error)
        /// The directory is closed.
        case closed

        /// A textual representation of this instance.
        /// Exact Apple `description` strings are unobserved; Linux uses case names.
        public var description: String {
            switch self {
            case .ready(let url):
                return "ready(\(url.path))"
            case .offline(let url):
                return "offline(\(url.path))"
            case .local(let url):
                return "local(\(url.path))"
            case .syncing:
                return "syncing"
            case .conflicted(let versions):
                return "conflicted(count: \(versions.count))"
            case .error(let error):
                return "error(\(String(describing: error)))"
            case .closed:
                return "closed"
            }
        }

        var gsSyncState: GSSyncState {
            switch self {
            case .ready: return .ready
            case .offline: return .offline
            case .local: return .local
            case .syncing: return .syncing
            case .conflicted: return .conflicted
            case .error: return .error
            case .closed: return .closed
            }
        }

        var url: URL? {
            switch self {
            case .ready(let url), .offline(let url), .local(let url):
                return url
            case .syncing, .conflicted, .error, .closed:
                return nil
            }
        }

        var conflictedVersions: [Version]? {
            switch self {
            case .conflicted(let versions):
                return versions
            default:
                return nil
            }
        }

        var error: (any Error)? {
            switch self {
            case .error(let error):
                return error
            default:
                return nil
            }
        }
    }

    /// A representation of a version of the directory.
    public class Version: Identifiable, CustomStringConvertible, @unchecked Sendable {
        public typealias ID = URL

        private let lock = NSLock()
        private var storedModifiedDate: Date

        /// `true` if the directory version is local; otherwise `false`.
        public let isLocal: Bool

        /// The localized name of the device that saved this version.
        public let localizedNameOfSavingComputer: String

        /// The URL of a directory where you read and write game-save data.
        public let url: URL

        /// The stable identity of the entity associated with this instance.
        public var id: URL { url }

        /// The date that this version was last modified.
        public var modifiedDate: Date {
            get {
                lock.lock()
                defer { lock.unlock() }
                return storedModifiedDate
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                storedModifiedDate = newValue
            }
        }

        /// A textual representation of this instance.
        /// Exact Apple `description` strings are unobserved.
        public var description: String {
            "GameSaveSyncedDirectory.Version(isLocal: \(isLocal), url: \(url.absoluteString))"
        }

        @_spi(OpenUIKitHost)
        public init(
            url: URL,
            isLocal: Bool,
            localizedNameOfSavingComputer: String,
            modifiedDate: Date
        ) {
            self.url = url
            self.isLocal = isLocal
            self.localizedNameOfSavingComputer = localizedNameOfSavingComputer
            self.storedModifiedDate = modifiedDate
        }
    }

    private let lock = NSLock()
    private let containerIdentifier: String
    private let localURL: URL
    private var storedState: State

    /// The stable identity of the entity associated with this instance.
    public var id: String { containerIdentifier }

    /// The state that the game-save directory is in.
    public var state: State {
        lock.lock()
        defer { lock.unlock() }
        return storedState
    }

    /// Returns a Boolean value indicating whether two values are equal.
    public static func == (lhs: GameSaveSyncedDirectory, rhs: GameSaveSyncedDirectory) -> Bool {
        lhs.id == rhs.id
    }

    /// Requests an instance of the game-save directory.
    ///
    /// Darwin starts iCloud sync in the background. Linux has no iCloud daemon,
    /// so this returns immediately in `.local` with a real local directory
    /// (or `.error` if the directory cannot be created). Passing `nil` uses
    /// Linux default `"GameSave.local"`; Apple's entitlement-array lookup is
    /// unobserved.
    public class func openDirectory(containerIdentifier: String? = nil) -> GameSaveSyncedDirectory {
        GameSaveSyncedDirectory(containerIdentifier: containerIdentifier)
    }

    private init(containerIdentifier: String?) {
        let resolved = GameSaveLocalStore.resolvedContainerIdentifier(containerIdentifier)
        self.containerIdentifier = resolved
        let url = GameSaveLocalStore.directoryURL(for: resolved)
        self.localURL = url
        if GameSaveLocalStore.ensureDirectoryExists(at: url) {
            self.storedState = .local(url)
        } else {
            self.storedState = .error(GameSaveLinuxCloudUnavailableError())
        }
    }

    /// Closes the directory. Darwin resumes cloud syncing; Linux has no daemon
    /// and only records `.closed`.
    public func close() {
        lock.lock()
        defer { lock.unlock() }
        storedState = .closed
    }

    /// Indicates that you resolved a conflict.
    ///
    /// Call this method only when the directory is in the
    /// ``State/conflicted(versions:)`` state. Linux accepts a version whose
    /// `url` matches a conflicted entry (or the same object) and settles on
    /// `.local(version.url)`. Other states no-op. Apple's post-resolve state
    /// is unobserved.
    public func resolveConflicts(with version: Version) {
        lock.lock()
        defer { lock.unlock() }
        guard case .conflicted(let versions) = storedState else { return }
        let accepted = versions.contains { candidate in
            candidate === version || candidate.url == version.url
        }
        guard accepted else { return }
        storedState = .local(version.url)
    }

    /// Waits for the directory sync to complete, without showing any user interface.
    ///
    /// Linux has nothing to wait for. If the host injected `.syncing`, this
    /// settles to `.local` (the documented unsigned-in iCloud fallback is local
    /// saving). Other states are unchanged. The sealed runner cannot await this
    /// method; the completion-handler ObjC overlay is the tested path.
    public func finishSyncing() async {
        finishSyncingSynchronously()
    }

    /// Triggers an upload of the directory for any changes that were pending.
    ///
    /// - Returns: `true` if there were pending uploads; otherwise `false`.
    ///   Linux has no iCloud upload queue and always returns `false`.
    public func triggerPendingUpload() async -> Bool {
        triggerPendingUploadSynchronously()
    }

    func finishSyncingSynchronously() {
        lock.lock()
        defer { lock.unlock() }
        if case .syncing = storedState {
            storedState = .local(localURL)
        }
    }

    func triggerPendingUploadSynchronously() -> Bool {
        false
    }

    func snapshot() -> State {
        state
    }
}

extension GameSaveSyncedDirectory {
    @_spi(OpenUIKitHost)
    public var hostLocalURL: URL { localURL }

    @_spi(OpenUIKitHost)
    public var hostContainerIdentifier: String { containerIdentifier }

    @_spi(OpenUIKitHost)
    public func hostEnterSyncing() {
        lock.lock()
        defer { lock.unlock() }
        storedState = .syncing
    }

    @_spi(OpenUIKitHost)
    public func hostEnterReady() {
        lock.lock()
        defer { lock.unlock() }
        storedState = .ready(localURL)
    }

    @_spi(OpenUIKitHost)
    public func hostEnterOffline() {
        lock.lock()
        defer { lock.unlock() }
        storedState = .offline(localURL)
    }

    @_spi(OpenUIKitHost)
    public func hostEnterConflicted(versions: [Version]) {
        lock.lock()
        defer { lock.unlock() }
        storedState = .conflicted(versions: versions)
    }

    @_spi(OpenUIKitHost)
    public func hostEnterError(_ error: any Error) {
        lock.lock()
        defer { lock.unlock() }
        storedState = .error(error)
    }
}
