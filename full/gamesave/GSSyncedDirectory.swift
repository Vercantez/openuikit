import Foundation

/// ObjC overlay of a version of a synced game-save directory.
///
/// Darwin subclasses `NSObject` and is constructed by the GameSave daemon.
/// Linux wraps `GameSaveSyncedDirectory.Version` and never talks to iCloud.
open class GSSyncedDirectoryVersion: NSObject {
    let version: GameSaveSyncedDirectory.Version

    /// `true` if the directory version is local; otherwise `false`.
    open var isLocal: Bool { version.isLocal }

    /// The localized name of the device that saved this version.
    open var localizedNameOfSavingComputer: String {
        version.localizedNameOfSavingComputer
    }

    /// The date that this version was last modified.
    open var modifiedDate: Date { version.modifiedDate }

    /// The URL of a directory where you read and write game-save data.
    open var url: URL { version.url }

    /// A textual representation of this instance.
    open override var description: String { version.description }

    init(version: GameSaveSyncedDirectory.Version) {
        self.version = version
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(hostVersion version: GameSaveSyncedDirectory.Version) {
        self.init(version: version)
    }
}

/// ObjC overlay of the current state of a synced game-save directory.
open class GSSyncedDirectoryState: NSObject {
    private let snapshot: GameSaveSyncedDirectory.State
    private let wrappedVersions: [GSSyncedDirectoryVersion]?

    /// The high-level sync state.
    open var state: GSSyncState { snapshot.gsSyncState }

    /// The local directory URL, if the state carries one.
    open var url: URL? { snapshot.url }

    /// Conflicting versions when `state` is `.conflicted`; otherwise `nil`.
    open var conflictedVersions: [GSSyncedDirectoryVersion]? { wrappedVersions }

    /// The error when `state` is `.error`; otherwise `nil`.
    open var error: (any Error)? { snapshot.error }

    init(snapshot: GameSaveSyncedDirectory.State) {
        self.snapshot = snapshot
        if let versions = snapshot.conflictedVersions {
            self.wrappedVersions = versions.map { GSSyncedDirectoryVersion(version: $0) }
        } else {
            self.wrappedVersions = nil
        }
        super.init()
    }
}

/// ObjC overlay of a cloud-synced game-save directory.
///
/// Darwin talks to iCloud Drive. Linux wraps `GameSaveSyncedDirectory` and
/// inherits that type's fail-closed local state machine. Methods that take
/// `UIWindow` are omitted: UIKit is not a GameSave dependency.
open class GSSyncedDirectory: NSObject {
    let directory: GameSaveSyncedDirectory

    /// The current directory state snapshot.
    open var directoryState: GSSyncedDirectoryState {
        GSSyncedDirectoryState(snapshot: directory.snapshot())
    }

    init(directory: GameSaveSyncedDirectory) {
        self.directory = directory
        super.init()
    }

    /// Requests an instance of the game-save directory for `containerIdentifier`.
    open class func open(forContainerIdentifier containerIdentifier: String?) -> GSSyncedDirectory {
        GSSyncedDirectory(
            directory: GameSaveSyncedDirectory.openDirectory(
                containerIdentifier: containerIdentifier
            )
        )
    }

    /// Closes the directory. Linux records `.closed` and does not resume iCloud sync.
    open func close() {
        directory.close()
    }

    /// Triggers an upload of pending directory changes.
    ///
    /// Linux has no iCloud upload queue. The completion is invoked synchronously
    /// with `false`.
    open func triggerPendingUpload(completionHandler completion: @escaping (Bool) -> Void) {
        completion(directory.triggerPendingUploadSynchronously())
    }

    /// Indicates that you resolved a conflict using `version`.
    open func resolveConflicts(with version: GSSyncedDirectoryVersion) {
        directory.resolveConflicts(with: version.version)
    }

    /// Waits for directory sync to complete without showing UI.
    ///
    /// Linux invokes `completion` synchronously after the same settle rules as
    /// `GameSaveSyncedDirectory.finishSyncing()`.
    open func finishSyncing(completionHandler completion: @escaping () -> Void) {
        directory.finishSyncingSynchronously()
        completion()
    }

    @_spi(OpenUIKitHost)
    public var hostSwiftDirectory: GameSaveSyncedDirectory { directory }
}
