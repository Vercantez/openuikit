import Foundation
@_spi(OpenUIKitHost) import GameSave

func testGSSyncedDirectoryType() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "gs-type")
    let asObject: NSObject = directory
    precondition(asObject === directory)
    precondition(type(of: directory) == GSSyncedDirectory.self)
}

func testGSOpenForContainerIdentifier() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "gs-open")
    precondition(directory.directoryState.state == .local)
    let url = directory.directoryState.url
    precondition(url != nil)
    precondition(url?.isFileURL == true)
    precondition(FileManager.default.fileExists(atPath: url!.path))
    let nilContainer = GSSyncedDirectory.open(forContainerIdentifier: nil)
    precondition(nilContainer.hostSwiftDirectory.id == "GameSave.local")
}

func testGSClose() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "gs-close")
    precondition(directory.directoryState.state == .local)
    directory.close()
    precondition(directory.directoryState.state == .closed)
    precondition(directory.directoryState.url == nil)
}

func testGSFinishSyncingCompletionHandler() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "gs-finish")
    directory.hostSwiftDirectory.hostEnterSyncing()
    precondition(directory.directoryState.state == .syncing)
    var called = false
    directory.finishSyncing {
        called = true
    }
    precondition(called)
    precondition(directory.directoryState.state == .local)
    precondition(directory.directoryState.url == directory.hostSwiftDirectory.hostLocalURL)

    var second = false
    directory.finishSyncing {
        second = true
    }
    precondition(second)
    precondition(directory.directoryState.state == .local)
}

func testGSResolveConflicts() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "gs-resolve")
    let localURL = directory.hostSwiftDirectory.hostLocalURL
    let otherURL = URL(fileURLWithPath: "/tmp/gamesave-gs-conflict-other", isDirectory: true)
    let localVersion = GameSaveSyncedDirectory.Version(
        url: localURL,
        isLocal: true,
        localizedNameOfSavingComputer: "This Host",
        modifiedDate: Date(timeIntervalSince1970: 30)
    )
    let otherVersion = GameSaveSyncedDirectory.Version(
        url: otherURL,
        isLocal: false,
        localizedNameOfSavingComputer: "Other Host",
        modifiedDate: Date(timeIntervalSince1970: 31)
    )
    directory.hostSwiftDirectory.hostEnterConflicted(versions: [localVersion, otherVersion])
    precondition(directory.directoryState.state == .conflicted)
    directory.resolveConflicts(with: GSSyncedDirectoryVersion(hostVersion: otherVersion))
    precondition(directory.directoryState.state == .local)
    precondition(directory.directoryState.url == otherURL)
}

func testGSTriggerPendingUploadCompletionHandler() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "gs-upload")
    var observed: Bool?
    directory.triggerPendingUpload { pending in
        observed = pending
    }
    precondition(observed == false)
    precondition(directory.directoryState.state == .local)
}

func testGSDirectoryState() {
    let directory = GSSyncedDirectory.open(forContainerIdentifier: "gs-dir-state")
    let snapshot = directory.directoryState
    precondition(type(of: snapshot) == GSSyncedDirectoryState.self)
    precondition(snapshot.state == .local)
    precondition(snapshot.url == directory.hostSwiftDirectory.hostLocalURL)
    directory.hostSwiftDirectory.hostEnterSyncing()
    precondition(directory.directoryState.state == .syncing)
}
